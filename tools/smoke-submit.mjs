/**
 * submit 接口端到端自测（5 套测评 × 3 种算分模型）
 * ------------------------------------------------------------
 * 用法：后端已启动跑着本地库的前提下
 *   node tools/smoke-submit.mjs [baseUrl]
 *   node tools/smoke-submit.mjs https://wangwang2.asia
 *
 * 做什么：
 *   1. GET /api/quiz/{code}       —— 顺带把出题接口也测了（拿真实题目 id）
 *   2. POST /api/quiz/submit      —— 每题选第 0 个选项（结果确定，可断言）
 *   3. 按 docs/backend-dual-report-steps.md 的验收表逐条断言，打印 PASS/FAIL
 *
 * 为什么每题都选第 0 项：分值全部存在库里，全选 0 的结果是唯一确定的，
 * 平票也变得可预期（见下），适合当回归测试。随机作答无法断言。
 *
 * 期望值来源（查过 seed 数据才写的，不是拍脑袋）：
 *   mbti       每组左侧维度都排在选项 0 → ESTJ；winner 4 组
 *   disc       每题选项 0 恒指支配型    → D
 *   enneagram  九型全平票 4 分          → 序号取小 → 1（完美型）
 *   holland    六型全平票 5 分          → 序号前三 → RIA；chapters 5+1=6
 *   attachment 四型全平票 6 分          → 序号取小 → secure
 */
const base = (process.argv[2] || 'http://localhost:8080').replace(/\/$/, '')

const cases = [
  {
    code: 'mbti',
    expectType: 'ESTJ',
    expectWinnerKeys: 4,
    expectBars: true,
    chaptersOk: true,       // 单主型：章数 >= 5 即可
    minChapters: 5,
  },
  { code: 'disc', expectType: 'D', expectWinnerKeys: 1, expectBars: false, minChapters: 5 },
  { code: 'enneagram', expectType: '1', expectWinnerKeys: 1, expectBars: false, minChapters: 5 },
  { code: 'holland', expectType: 'RIA', expectWinnerKeys: 1, expectBars: false, minChapters: 6 },
  { code: 'attachment', expectType: 'secure', expectWinnerKeys: 1, expectBars: false, minChapters: 5 },
]

let failed = 0

function check(label, ok, actual) {
  console.log(`   ${ok ? 'PASS' : 'FAIL'}  ${label}${actual === undefined ? '' : ` = ${actual}`}`)
  if (!ok) failed++
}

/** JSON 列可能因为数据损坏拿不到，解析失败要降级而不是让脚本炸 */
function safeJson(s) {
  if (!s) return null
  try { return JSON.parse(s) } catch (e) { return null }
}

async function run(c) {
  console.log(`\n=== ${c.code} ===`)
  const qRes = await fetch(`${base}/api/quiz/${c.code}`)
  if (!qRes.ok) {
    check(`GET /api/quiz/${c.code}`, false, `HTTP ${qRes.status}`)
    return
  }
  const quiz = await qRes.json()
  const questions = quiz.questions || []
  check(`出题 ${questions.length} 道`, questions.length > 0, questions.length)

  const payload = {
    quizCode: c.code,
    answers: questions.map((q) => ({ questionId: q.id, optionIndex: 0 })),
  }
  const sRes = await fetch(`${base}/api/quiz/submit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
  if (!sRes.ok) {
    check('submit 返回 2xx', false, `HTTP ${sRes.status} ${await sRes.text().catch(() => '')}`)
    return
  }
  const r = await sRes.json()

  check('type', r.type === c.expectType, r.type)
  check('winner 键数（前端据此显不显示维度条）', Object.keys(r.winner || {}).length === c.expectWinnerKeys,
    JSON.stringify(r.winner))
  check('resultName 非空', !!r.resultName, r.resultName)
  check('resultSummary 非空', !!r.resultSummary, r.resultSummary)

  const basic = safeJson(r.basicReport)
  check('basicReport 可解析 + 含 one_liner', !!basic && !!basic.one_liner,
    basic ? JSON.stringify(basic).slice(0, 80) + '...' : r.basicReport)
  check('basic.traits >= 4 条', !!basic && (basic.traits || []).length >= 4,
    basic ? (basic.traits || []).length : '-')
  check('basic.strengths >= 3 条', !!basic && (basic.strengths || []).length >= 3,
    basic ? (basic.strengths || []).length : '-')

  const adv = safeJson(r.advancedReport)
  const chapters = adv && adv.chapters ? adv.chapters.length : 0
  check(`advanced.chapters >= ${c.minChapters}（TOP3 会多一章副型）`, chapters >= c.minChapters, chapters)
  check('advanced.career 非空', !!adv && (adv.career || []).length > 0, adv ? (adv.career || []).length : '-')

  // 和前端 utils/report.js 同款判定：winner 恰好 4 组才画维度条
  const hasBars = Object.keys(r.winner || {}).length === 4
  check('hasBars 与预期一致', hasBars === c.expectBars, hasBars)
}

async function main() {
  console.log(`submit 端到端自测 -> ${base}`)
  for (const c of cases) {
    try {
      await run(c)
    } catch (e) {
      console.log(`\n=== ${c.code} ===\n   FAIL  请求异常：${e.message}`)
      failed++
    }
  }
  console.log(`\n${failed === 0 ? '全部通过 ✅' : `失败 ${failed} 项 ❌`}`)
  process.exit(failed === 0 ? 0 : 1)
}

main()
