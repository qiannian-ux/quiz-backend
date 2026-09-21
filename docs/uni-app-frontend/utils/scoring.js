/**
 * 算分逻辑（MBTI 版）
 * ------------------------------------------------------------
 * 为什么单独抽成一个文件？
 * 这是纯函数——不 import uni、不碰 Vue、不读 storage。
 * 好处有三个：
 *   1. 单独就能测（扔给 node 跑，不用起小程序）
 *   2. 页面只管渲染，规则变了不用翻 vue 文件
 *   3. 后端接算分接口时，这段逻辑直接搬到 Java，行为一致
 *
 * 面试能讲的点：业务逻辑与框架解耦，就是从这个小文件开始的。
 *
 * ------------------------------------------------------------
 * MBTI 的算分不是"哪个维度分最高"，而是"四组两两对撞"：
 *   E vs I、S vs N、T vs F、J vs P，每组取高分那个字母，拼成 4 个字母。
 *   所以结果是 INFP 这种类型码，而不是单一维度。
 * 顺序固定按 E/I → S/N → T/F → J/P，
 * 不能按字母序排，否则会拼成 EJST（错）而不是 ESTJ。
 */

import { PERSONALITY_TYPES, DIMENSION_PAIRS } from '@/data/questions.js'

/** 8 个维度码 */
export const DIMENSION_CODES = ['E', 'I', 'S', 'N', 'T', 'F', 'J', 'P']

/** 4 组对撞维度的 key，顺序即结果码的字母顺序 */
export const DIMENSION_KEYS = DIMENSION_PAIRS.map((p) => p.key)

/**
 * 维度对元信息。结果页条形图直接读 label / color，
 * 所以这两个字段必须保留，改名会让页面报错。
 */
export const DIMENSIONS = {}
DIMENSION_PAIRS.forEach((p) => {
  DIMENSIONS[p.key] = {
    key: p.key,
    label: p.label,
    color: p.color,
    left: p.left,
    right: p.right,
    leftName: p.leftName,
    rightName: p.rightName
  }
})

/**
 * 统计 8 个维度各自的得分
 * @param {Array} answers [{ questionId, type, score }]
 * @returns {Object} { E: 18, I: 6, S: 12, N: 12, ... }
 */
export function countScores(answers) {
  const scores = {}
  DIMENSION_CODES.forEach((k) => (scores[k] = 0))
  answers.forEach((a) => {
    if (!a) return
    // 双极 5 档：每题给两端带符号分（value: 1=强左, 3=中立, 5=强右）
    // 例：value=1 → 左极 +2、右极 -2；value=5 → 左极 -2、右极 +2
    if (a.leftType && a.rightType && a.value != null) {
      const v = Number(a.value)
      scores[a.leftType] = (scores[a.leftType] || 0) + (3 - v)
      scores[a.rightType] = (scores[a.rightType] || 0) + (v - 3)
      return
    }
    // 兼容旧式单极：type + score
    if (!a.type || scores[a.type] == null) return
    scores[a.type] += a.score != null ? a.score : 1
  })
  return scores
}

/** 每对维度各有几道题（从作答推导），用于把双极净偏向归一到 0-100 */
function pairQuestionCount(answers) {
  const map = {}
  ;(answers || []).forEach((a) => {
    if (!a || !a.leftType || !a.rightType) return
    const key = pairKeyOf(a.leftType, a.rightType)
    if (key) map[key] = (map[key] || 0) + 1
  })
  return map
}

function pairKeyOf(left, right) {
  for (const p of DIMENSION_PAIRS) {
    if ((p.left === left && p.right === right) || (p.left === right && p.right === left)) return p.key
  }
  return null
}

/**
 * 四组对撞，每组取高分字母。
 * 平票时取左侧（E/S/T/J），保证同样的答案永远得到同样的结果——
 * 可预测才可测试。
 * @returns {Object} { EI: 'E', SN: 'S', TF: 'F', JP: 'P' }
 */
export function resolveWinner(scores) {
  const winner = {}
  DIMENSION_PAIRS.forEach((p) => {
    winner[p.key] = scores[p.left] >= scores[p.right] ? p.left : p.right
  })
  return winner
}

/**
 * @returns {String} 如 'INFP'
 */
export function resolveType(scores) {
  return DIMENSION_PAIRS.map((p) =>
    scores[p.left] >= scores[p.right] ? p.left : p.right
  ).join('')
}

/**
 * 组装最终结果。
 * 本地算分和后端算分都走这里，保证两条路径返回的结构完全一致，
 * 结果页不用关心结果是哪儿来的。
 */
function buildResult(type, scores, winner, total, answers) {
  const p = PERSONALITY_TYPES[type] || {}

  // 每组条形图的百分比：
  //  - 旧单极格式：左极占该组总分(l+r)的比例
  //  - 双极 5 档：每题 l+r 恒为 0，改用净偏向 l 归一到 0-100
  //      l = 2n(全偏左) → 0%，l = 0(中立) → 50%，l = -2n(全偏右) → 100%
  const countMap = pairQuestionCount(answers)
  const percent = {}
  DIMENSION_PAIRS.forEach((pair) => {
    const l = scores[pair.left] || 0
    const r = scores[pair.right] || 0
    const sum = l + r
    let pct
    if (sum !== 0) {
      // 旧单极格式：左极占该组总分的比例
      pct = Math.round((l / sum) * 100)
    } else {
      // 双极 5 档：l+r 恒为 0，改用净偏向 l 归一到 0-100
      const n = countMap[pair.key] || 1
      pct = Math.round(((l / (2 * n)) + 0.5) * 100)
    }
    percent[pair.key] = Math.min(100, Math.max(0, pct))
  })

  // 16 型文案里没有 tip 字段，用优势关键词顶上，
  // 结果页那块区域不至于空着。
  const tip = p.strengths && p.strengths.length
    ? '你的关键词：' + p.strengths.slice(0, 3).join(' · ')
    : ''

  return {
    type,
    winner,
    info: {
      key: type,
      label: p.name || type,
      emoji: p.emoji || type[0],
      color: p.color || '#8FB8FF',
      subtitle: p.groupLabel ? p.groupLabel + ' · ' + type : type,
      desc: p.desc || '',
      tip,
      strengths: p.strengths || [],
      weaknesses: p.weaknesses || [],
      careers: p.careers || []
    },
    scores,
    percent,
    total: total || 0
  }
}

/**
 * 本地算分。后端不可用时的兜底路径。
 * @param {Array} answers [{ questionId, type, score }]
 */
export function calcResult(answers) {
  const list = answers || []
  const scores = countScores(list)
  return buildResult(resolveType(scores), scores, resolveWinner(scores), list.length, list)
}

/**
 * 直接用后端算好的结果。
 * 后端只返回类型码和各维度分数，文案从本地 16 型数据里取，
 * 这样后端不用建结果表、不用传一大段文案，接口很轻。
 * @param {Object} res 后端返回 { type, scores, winner }
 * @param {Array} answers 本地作答，只用来取题数
 */
export function fromServerResult(res, answers) {
  const list = answers || []
  return buildResult(res.type, res.scores || {}, res.winner || {}, list.length, list)
}
