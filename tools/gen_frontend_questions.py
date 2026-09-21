# -*- coding: utf-8 -*-
"""
从两个 MBTI 的 CSV 生成前端本地题库 data/questions.js。

输出的三个导出：
  LOCAL_QUESTIONS   93 道题，每题两个选项，选项带维度 code 和分值
  PERSONALITY_TYPES 16 型人格的文案与配色
  DIMENSION_PAIRS   4 组对撞维度的元信息（结果页条形图用）

为什么用 JSON.stringify 生成而不是拼字符串：
  JS 对象字面量和 JSON 基本兼容，交给标准库转义，
  不会出现题目里有个单引号就把整个文件搞崩的情况。
"""
import csv
import io
import json

BASE = r'C:\Users\35156\Downloads'
OUT = r'D:\Users\35156\Documents\HBuilderProjects\quiz-miniapp\data\questions.js'

Q_CSV = BASE + r'\mbti_questions_rows.csv'
T_CSV = BASE + r'\mbti_personality_types_rows.csv'

# MBTI 传统的四色分组：同组人格底色一致，视觉上一眼能分辨气质类型
GROUP = {
    'NT': {'label': '分析家', 'color': '#7F77DD'},
    'NF': {'label': '外交家', 'color': '#1D9E75'},
    'SJ': {'label': '守卫者', 'color': '#378ADD'},
    'SP': {'label': '探索者', 'color': '#EF9F27'},
}


def group_of(code):
    """
    MBTI 的 Keirsey 四色气质分组。注意不是简单取中间两位：
      第 2 位是 S 时，看第 4 位 -> SJ 守卫者 / SP 探索者
      第 2 位是 N 时，看第 3 位 -> NF 外交家 / NT 分析家
    例：ISTJ->SJ，INFP->NF，ENTP->NT，ESFP->SP
    """
    return ('S' + code[3]) if code[1] == 'S' else ('N' + code[2])


def read_csv(path):
    with io.open(path, encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


questions = read_csv(Q_CSV)
types = read_csv(T_CSV)

# ---------- 题目 ----------
local_questions = []
for row in questions:
    title = (row['question_text'] or '').strip()
    if not title:
        continue
    opts = []
    for side, order in (('a', 0), ('b', 1)):
        code = (row['option_%s_dimension' % side] or '').strip()
        text = (row['option_%s_text' % side] or '').strip()
        if not code or not text:
            continue
        opts.append({
            'text': text,
            'type': code,
            'score': int(row['option_%s_score' % side] or 1),
            'order': order,
        })
    if len(opts) < 2:
        continue
    local_questions.append({
        'id': int(row['id']),
        'title': title,
        'sortOrder': int(row['sort_order'] or 0),
        'options': opts,
    })

# ---------- 16 型人格 ----------
personality = {}
for row in types:
    code = (row['type_code'] or '').strip()
    name = (row['type_name'] or '').strip()
    desc = (row['description'] or '').strip()
    g = group_of(code)

    def parse(key):
        raw = (row.get(key) or '').strip()
        if not raw:
            return []
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return [x.strip().strip('"') for x in raw.strip('[]').split(',') if x.strip()]

    personality[code] = {
        'code': code,
        'name': name,
        # 结果页大圆里放的单字，取名字第一个字，16 个互不重复
        'emoji': name[0] if name else code[0],
        'group': g,
        'groupLabel': GROUP[g]['label'],
        'color': GROUP[g]['color'],
        'summary': desc,
        'desc': desc,
        'strengths': parse('strengths'),
        'weaknesses': parse('weaknesses'),
        'careers': parse('careers'),
    }

# ---------- 4 组对撞维度 ----------
pairs = [
    {'key': 'EI', 'left': 'E', 'right': 'I', 'label': '精力来源',
     'leftName': '外向', 'rightName': '内向', 'color': '#FF9DB4'},
    {'key': 'SN', 'left': 'S', 'right': 'N', 'label': '信息获取',
     'leftName': '实感', 'rightName': '直觉', 'color': '#8FB8FF'},
    {'key': 'TF', 'left': 'T', 'right': 'F', 'label': '决策方式',
     'leftName': '思考', 'rightName': '情感', 'color': '#8FD6C2'},
    {'key': 'JP', 'left': 'J', 'right': 'P', 'label': '生活态度',
     'leftName': '判断', 'rightName': '感知', 'color': '#FFC46B'},
]

HEADER = """/**
 * 本地题库（MBTI 93 题 + 16 型人格）
 * ------------------------------------------------------------
 * 本文件由 tools/gen_frontend_questions.py 从 CSV 自动生成，
 * 改数据请改 CSV 后重跑脚本，不要手改这里。
 *
 * 为什么还要本地题库？
 *   接口优先 + 本地兜底：弱网 / 后端挂了，用户照样能完整测完，
 *   不至于白屏。真实项目里这叫离线兜底。
 *
 * 数据模型（与后端 question / question_option / dimension 三表一一对应）：
 *   question.id            -> id
 *   question.content       -> title
 *   question_option        -> options[]，每个带 type（维度码）与 score
 *   dimension.pair_code    -> DIMENSION_PAIRS[].key，用于对撞算分
 */

"""

body = []
body.append('export const LOCAL_QUESTIONS = ' + json.dumps(local_questions, ensure_ascii=False, indent=2) + '\n')
body.append('export const PERSONALITY_TYPES = ' + json.dumps(personality, ensure_ascii=False, indent=2) + '\n')
body.append('export const DIMENSION_PAIRS = ' + json.dumps(pairs, ensure_ascii=False, indent=2) + '\n')

FOOTER = """/**
 * 把后端返回的题目转换成前端统一格式。
 * 后端返回 { id, content, options: [{ id, content, dimensionCode, score }] }，
 * 这里统一拍平成 { id, title, options: [{ text, type, score }] }，
 * 让本地题和后端题在页面里长得一模一样，算分逻辑不用分两套。
 */
export function normalizeRemoteQuestion(raw) {
  if (!raw || !raw.content) return null
  const options = (raw.options || []).map((o) => ({
    text: o.content,
    type: o.dimensionCode,
    score: o.score != null ? o.score : 1,
    optionId: o.id
  }))
  if (options.length < 2) return null
  return {
    id: raw.id,
    title: raw.content,
    options,
    fromServer: true
  }
}
"""

with io.open(OUT, 'w', encoding='utf-8') as f:
    f.write(HEADER + '\n'.join(body) + FOOTER)

print('输出:', OUT)
print('题目:', len(local_questions), ' 人格类型:', len(personality))
print('四色分组:', {k: sum(1 for c in personality if group_of(c) == k) for k in GROUP})
