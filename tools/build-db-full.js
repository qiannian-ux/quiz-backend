#!/usr/bin/env node
/**
 * 把分散的 MySQL 文件合并成一个权威 db-full.sql。
 *
 * 合并顺序（结构先于数据，幂等优先）：
 *   1. schema-full.sql      —— 9 张表的全量 DDL（IF NOT EXISTS；question/question_option 会 DROP 重建）
 *   2. migrate-schema-fix.sql —— 列不存在才 ADD 的幂等补齐（修线上 incomplete schema，覆盖 user/user_platform）
 *   3. pay_order.sql        —— 微信虚拟支付订单表
 *   4. seed-mbti.sql        —— MBTI 题库 + 16 型结果（可重复执行，开头清 quiz_id=1 再重插）
 *
 * 不纳入（已过时/备份，避免污染权威库）：
 *   - migrate-to-9tables.sql    破坏性 DROP+重建（逻辑已被 schema-full 覆盖）
 *   - quiz-list-columns.sql     旧版 quiz 列补齐（被 migrate-schema-fix 覆盖）
 *   - mbti_questions_mysql.sql  旧版 flat 结构 mbti_questions（当前代码不用）
 *   - backup-m3-questions-20260909.sql  M3 备份，非建库脚本
 *
 * 用法：node tools/build-db-full.js
 * 产物：docs/db-full.sql
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DOCS = path.join(ROOT, 'docs');

const SEGMENTS = [
  { file: 'schema-full.sql',       title: '一、全量表结构（9 张表）', note: '本地和线上首次建库跑这一个；全部 IF NOT EXISTS。question/question_option 先 DROP 再建（M3 旧结构清理）。' },
  { file: 'migrate-schema-fix.sql', title: '二、生产库结构修正（幂等补齐缺失列）', note: '线上库若是用不完整早期 schema 建的，这里把 quiz/dimension/.../user/user_platform 补齐到规范形态；已有列跳过，保留数据。' },
  { file: 'migrate-reports.sql',    title: '三、双档解析 + 多测评算分模型（结构升级）', note: '补 quiz.scoring_model（PAIR/MAX/TOP3）与 quiz_result.basic_report/advanced_report（初级解析 + 高级解析）。幂等，已有列跳过。' },
  { file: 'pay_order.sql',          title: '四、微信虚拟支付订单表', note: '打赏 / 解锁全站付费流水。' },
  { file: 'seed-mbti.sql',          title: '五、MBTI 初始数据（题库 + 16 型结果）', note: '开头清 quiz_id=1 再重插，可重复执行。改 CSV 后重跑本文件即可刷新题库。' },
  { file: 'seed-result-reports.sql', title: '六、MBTI 16 型「初级解析 + 高级解析」双档文案', note: 'UPDATE 补齐 basic_report / advanced_report，顺手把 summary 换成更适合分享卡片的一句话。由 tools/gen_reports.py 生成。' },
  { file: 'seed-disc.sql',          title: '七、DISC 行为风格测评（全套数据）', note: 'quiz_id=2：测评定义 + 4 个类型维度 + 20 道四选一 + 4 型结果（含双档解析）。scoring_model=MAX。由 tools/gen_reports.py 生成。' },
  { file: 'seed-enneagram.sql',     title: '八、九型人格测评（全套数据）', note: 'quiz_id=3：测评定义 + 9 个类型维度 + 36 道李克特五点量表题（每型 4 题）+ 9 型结果（含双档解析）。scoring_model=MAX。由 tools/gen_reports.py 生成。' },
  { file: 'seed-holland.sql',       title: '九、霍兰德职业兴趣测评（全套数据）', note: 'quiz_id=4：测评定义 + 6 个类型维度 + 30 道李克特题（每型 5 题）+ 6 型结果（含双档解析）。scoring_model=TOP3，取前三拼码（如 RIA/SEC）。由 tools/gen_reports.py 生成。' },
  { file: 'seed-attachment.sql',    title: '十、恋爱依恋类型测评（全套数据）', note: 'quiz_id=5：测评定义 + 4 个类型维度 + 24 道李克特题（每型 6 题）+ 4 型结果（含双档解析）。scoring_model=MAX。由 tools/gen_reports.py 生成。' },
  { file: 'migrate-login-days.sql', title: '十二、累计 / 连续登录天数（权威在后端）', note: '建 user_login_day 明细表（UNIQUE(user_id,login_date) 保证同一天只记一次）；user 表幂等加 total_login_days / consecutive_login_days / last_login_date 三个冗余列；并按 user_quiz_record 的日期为老用户补历史登录明细，避免积累归零。' },
  { file: 'fix-question-count.sql', title: '十一、回填 quiz 表展示字段（question_count / emoji / tag）', note: '①seed 插 quiz 行时题库还没插，question_count 写的是 0，不回填首页会显示「0 题」，这里按 question 表真实题数 UPDATE；②MBTI 行由 CSV 生成没带 emoji/tag，按 code 补上。幂等。' },
];

const banner = (title, note) =>
  `-- =============================================================================\n` +
  `-- ${title}\n` +
  `-- -----------------------------------------------------------------------------\n` +
  `-- ${note}\n` +
  `-- =============================================================================\n`;

function main() {
  const parts = [];
  parts.push(
    `-- =============================================================================\n` +
    `-- 探我趣测 · 数据库全集（db-full.sql）\n` +
    `-- -----------------------------------------------------------------------------\n` +
    `-- 由 tools/build-db-full.js 自动合并生成，源文件保持独立可单跑。\n` +
    `-- 用法（开 SSH 隧道 3307 或登服务器直接跑）：\n` +
    `--   mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/db-full.sql\n` +
    `--\n` +
    `-- ⚠️ 说明：\n` +
    `--   1) 本文件对「结构」幂等（IF NOT EXISTS / 列不存在才 ADD），可重复执行。\n` +
    `--   2) 第一节会 DROP 重建 question/question_option；第五、七节分别清 quiz_id=1(MBTI)\n` +
    `--      和 quiz_id=2(DISC) 再重插——这两个测评的题库每次跑都会重置为种子值。\n` +
    `--      若库里已有【其他测评】的题目/作答，先备份再执行。\n` +
    `--   3) 算分模型见 quiz.scoring_model：PAIR=对撞取大(MBTI)、MAX=累加取最高(DISC)、\n` +
    `--      TOP3=取前三拼码(霍兰德)。双档解析在 quiz_result.basic_report/advanced_report。\n` +
    `--   4) 改完任一源文件后，重跑 node tools/build-db-full.js 重新生成本文件即可。\n` +
    `-- =============================================================================\n`
  );

  for (const seg of SEGMENTS) {
    const src = path.join(DOCS, seg.file);
    if (!fs.existsSync(src)) {
      throw new Error(`源文件缺失：${src}`);
    }
    const body = fs.readFileSync(src, 'utf8').replace(/\r\n/g, '\n').trimEnd();
    parts.push('\n\n' + banner(seg.title, seg.note) + '\n' + body);
  }

  parts.push('\n\n-- =============================================================================\n' +
    '-- 合并完成：guiz 库结构 + MBTI 数据应已就绪。\n' +
    '-- =============================================================================\n');

  const out = path.join(DOCS, 'db-full.sql');
  fs.writeFileSync(out, parts.join('\n') + '\n', 'utf8');
  console.log('已生成 ' + out);
  const lines = fs.readFileSync(out, 'utf8').split('\n').length;
  console.log('总行数：' + lines);
}

main();
