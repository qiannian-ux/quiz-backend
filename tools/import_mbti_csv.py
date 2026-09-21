# -*- coding: utf-8 -*-
"""
把两个 MBTI 的 CSV 导入进 M5 的表结构：

  mbti_questions_rows.csv         -> question + question_option
  mbti_personality_types_rows.csv -> quiz_result

同时生成 quiz / dimension 两表的初始数据（8 个维度 + 4 组对撞关系）。

输出：docs/seed-mbti.sql，可重复执行（开头先清掉 quiz_id=1 的所有内容）。
"""
import csv
import io
import json
import collections

BASE = r'C:\Users\35156\Downloads'
OUT = r'C:\Users\35156\IdeaProjects\quiz-backend\docs\seed-mbti.sql'

Q_CSV = BASE + r'\mbti_questions_rows.csv'
T_CSV = BASE + r'\mbti_personality_types_rows.csv'

QUIZ_ID = 1

# 8 个维度，固定 ID。
# pair_code 把对撞的两个维度配成一对，算分时按 pair_code 分组比大小；
# pair_order 决定结果码里字母的先后 —— 必须显式指定，
# 因为按 pair_code 字母序排会得到 EJST，而 MBTI 的正确顺序是 ESTJ。
DIMENSIONS = [
    (1, 'E', '外向', 'EI', 1),
    (2, 'I', '内向', 'EI', 1),
    (3, 'S', '实感', 'SN', 2),
    (4, 'N', '直觉', 'SN', 2),
    (5, 'T', '思考', 'TF', 3),
    (6, 'F', '情感', 'TF', 3),
    (7, 'J', '判断', 'JP', 4),
    (8, 'P', '感知', 'JP', 4),
]
DIM_ID = {code: did for did, code, name, pair, order in DIMENSIONS}


def esc(v):
    """SQL 字符串转义：单引号翻倍。MySQL 里反斜杠不是默认转义符，别乱加。"""
    if v is None:
        return ''
    return str(v).replace("'", "''")


def cut_tz(v):
    """2026-03-28 19:54:03.784876+08 -> 2026-03-28 19:54:03"""
    if not v:
        return '2026-03-28 19:54:03'
    return v.split('+')[0].split('.')[0]


def read_csv(path):
    """utf-8-sig 能自动吃掉 Excel 导出的 BOM。"""
    with io.open(path, encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


questions = read_csv(Q_CSV)
types = read_csv(T_CSV)

out = []
w = out.append

w('-- =============================================================================')
w('-- 探我趣测 · MBTI 初始数据（由 tools/import_mbti_csv.py 从 CSV 生成）')
w('-- 可重复执行：开头会先清掉 quiz_id = 1 的全部内容')
w('-- =============================================================================')
w('')
w('SET NAMES utf8mb4;')
w('')
w('-- 先删子表再删父表，避免残留孤儿数据')
w('DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = %d);' % QUIZ_ID)
w('DELETE FROM `question`        WHERE `quiz_id` = %d;' % QUIZ_ID)
w('DELETE FROM `quiz_result`     WHERE `quiz_id` = %d;' % QUIZ_ID)
w('DELETE FROM `dimension`       WHERE `quiz_id` = %d;' % QUIZ_ID)
w('DELETE FROM `quiz`            WHERE `id`      = %d;' % QUIZ_ID)
w('')

# ---------- quiz ----------
w('-- 测评本体')
w("INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`question_count`,`price_coin`,`status`) VALUES")
w("(%d,'mbti','MBTI 性格类型测试','4 个维度，看清你的思维偏好','MBTI 通过外向/内向、实感/直觉、思考/情感、判断/感知四个维度，把人的认知偏好分成 16 种类型。它不是能力测试，没有好坏之分，只是描述你更倾向于如何获取信息、做决定。',0,0,1);" % QUIZ_ID)
w('')

# ---------- dimension ----------
w('-- 维度定义（8 个，4 组对撞）')
w("INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES")
w(',\n'.join(
    "(%d,%d,'%s','%s','%s',%d)" % (did, QUIZ_ID, code, name, pair, order)
    for did, code, name, pair, order in DIMENSIONS
) + ';')
w('')

# ---------- question + question_option ----------
w('-- 题目（%d 道）' % len(questions))
stat = collections.Counter()
bad = []

for row in questions:
    q_text = row['question_text'].strip()
    if not q_text:
        continue
    qid = int(row['id'])
    w("INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES "
      "(%d,%d,'%s',%s,%d);" % (
          qid, QUIZ_ID, esc(q_text),
          row['sort_order'] or 0,
          1 if str(row.get('is_active', 'true')).lower() == 'true' else 0))

    opts = []
    for side in ('a', 'b'):
        code = (row['option_%s_dimension' % side] or '').strip()
        text = (row['option_%s_text' % side] or '').strip()
        score = row['option_%s_score' % side] or '1'
        if code not in DIM_ID:
            bad.append((qid, side, code))
            continue
        stat[code] += 1
        opts.append("(%d,'%s',%d,%s,%d)" % (
            qid, esc(text), DIM_ID[code], int(score),
            0 if side == 'a' else 1))

    if opts:
        w("INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES")
        w(',\n'.join(opts) + ';')
w('')

# ---------- quiz_result ----------
w('-- 结果类型（%d 型）' % len(types))
for row in types:
    code = (row['type_code'] or '').strip()
    name = (row['type_name'] or '').strip()
    desc = (row['description'] or '').strip()

    # strengths / weaknesses / careers 三列本来就是 JSON 数组字符串，
    # 直接塞进 traits 这一个 JSON 字段，前端一次拿全。
    traits = {}
    for k in ('strengths', 'weaknesses', 'careers'):
        raw = (row.get(k) or '').strip()
        if raw:
            try:
                traits[k] = json.loads(raw)
            except json.JSONDecodeError:
                traits[k] = [x for x in raw.strip('[]').split(',')]
    traits_json = json.dumps(traits, ensure_ascii=False).replace("'", "''")

    w("INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES "
      "(%d,'%s','%s','%s','%s','','%s',%d);" % (
          QUIZ_ID, esc(code), esc(name), esc(desc), esc(desc),
          traits_json, int(row['id'])))
w('')

io.open(OUT, 'w', encoding='utf-8').write('\n'.join(out))

print('输出:', OUT)
print('题目数:', len(questions), ' 结果类型数:', len(types))
print('选项维度分布:', dict(sorted(stat.items())))
print('维度配对检查:')
pair_of = {code: pair for _, code, _, pair, _ in DIMENSIONS}
for pair in ('EI', 'SN', 'TF', 'JP'):
    cs = [c for c in stat if pair_of.get(c) == pair]
    print('   %s: %s' % (pair, {c: stat[c] for c in cs}))
if bad:
    print('!! 无法识别的维度:', bad[:10])
