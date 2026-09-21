/**
 * 解析结果归一化层
 * ------------------------------------------------------------
 * 解析有两条来源：
 *   1. 云端：POST /api/quiz/submit 下发的 basicReport / advancedReport（JSON 字符串）
 *      —— 权威来源，改文案不用发版，也是「初级解析 + 高级解析」两档的唯一出处。
 *   2. 本地：utils/scoring.js 的 calcResult + data/questions.js 的 16 型数据
 *      —— 只在云端不可达时兜底，且只有 MBTI 有本地数据。
 *
 * 两条来源结构完全不同，这里统一成 result.vue 直接渲染的 report 形状，
 * 页面不关心结果是云端来的还是本地兜底的（零分支渲染）。
 *
 * 统一结构 report：
 * {
 *   source:   'cloud' | 'local' | 'error'，
 *   code:     结果码（如 INTJ / RIA / secure），
 *   name:     展示名（如 建筑师 / 现实型 × 研究型 × 艺术型），
 *   emoji:    卡片图标，
 *   color:    主题色（卡片 / 条形图），
 *   subtitle: 副标题（如 分析家 · INTJ），
 *   summary:  一句话总结（分享卡片用），
 *   basic:    { one_liner, traits[], strengths[], weaknesses[], tip }   // 初级解析
 *   advanced: { chapters[{title,content}], career[], famous }           // 高级解析
 *   winner:   { EI:'I', ... }   // 仅 PAIR 模型（MBTI）有 4 组
 *   percent:  { EI:70, ... }    // 维度占比，仅 PAIR 模型
 *   hasBars:  Boolean           // 是否展示维度占比条
 * }
 */

import { PERSONALITY_TYPES, DIMENSION_PAIRS } from '@/data/questions.js'

/**
 * 主题色板：云端未下发 emoji/color 时（非 MBTI 测评）按编码哈希取色，
 * 保证每个结果都有稳定且好看的主题色，不依赖后端额外字段。
 */
const THEME_PALETTE = [
  '#7F77DD', '#FF9DB4', '#5BC0BE', '#FFB26B',
  '#6C8EEF', '#E27DA0', '#3FB6A8', '#F2A65A'
]

function hashCode(str) {
  let h = 0
  for (let i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) >>> 0
  return h
}

/**
 * 取结果的展示信息（emoji / color / name / subtitle）。
 * MBTI 优先复用本地品牌色（与产品视觉一致），其余按哈希取色板。
 * TOP3（霍兰德 RIA）在 MBTI 表里查不到，会走到哈希分支——这是设计好的。
 */
function themeFor(code) {
  const t = PERSONALITY_TYPES[code]
  if (t) {
    return {
      emoji: t.emoji,
      color: t.color,
      name: t.name,
      subtitle: (t.groupLabel ? t.groupLabel + ' · ' : '') + code
    }
  }
  const h = hashCode(code || '')
  return {
    emoji: '🧩',
    color: THEME_PALETTE[h % THEME_PALETTE.length],
    name: code,
    subtitle: code
  }
}

function safeJson(str, fallback) {
  if (!str) return fallback
  try {
    return JSON.parse(str)
  } catch (e) {
    return fallback
  }
}

/** 由各维度分数算每组占比（左侧占该组百分比），用于条形图 */
function computePercent(scores) {
  const p = {}
  DIMENSION_PAIRS.forEach((pair) => {
    const l = scores[pair.left] || 0
    const r = scores[pair.right] || 0
    const sum = l + r
    p[pair.key] = sum === 0 ? 50 : Math.round((l / sum) * 100)
  })
  return p
}

/**
 * 云端结果 → 统一 report。
 * 容错：云端字段缺失时不崩，basic/advanced 用最小可用结构顶上。
 */
export function buildCloudReport(res) {
  if (!res) return null
  const code = res.type || res.resultName || ''
  const theme = themeFor(code)
  const basic = safeJson(res.basicReport, null)
  const adv = safeJson(res.advancedReport, null)
  const winner = res.winner || {}
  const percent = res.scores ? computePercent(res.scores) : {}

  return {
    source: 'cloud',
    code,
    name: res.resultName || theme.name,
    emoji: theme.emoji,
    color: theme.color,
    subtitle: res.subtitle || theme.subtitle,
    summary: res.resultSummary || (basic && basic.one_liner) || '',
    basic:
      basic || {
        one_liner: res.resultSummary || '',
        traits: [],
        strengths: [],
        weaknesses: [],
        tip: ''
      },
    advanced:
      adv || {
        chapters: [],
        career: [],
        famous: ''
      },
    winner,
    percent,
    // 前端靠「winner 恰好 4 组」判断要不要画维度条形图：
    // MAX / TOP3 模型后端只回 {TYPE: 'D'/'RIA'} 一个键 -> 自动隐藏。
    hasBars:
      Object.keys(percent).length === DIMENSION_PAIRS.length &&
      Object.keys(winner).length === DIMENSION_PAIRS.length
  }
}

/**
 * 本地算分结果（MBTI）→ 统一 report。
 * 仅 MBTI 有本地数据；非 MBTI 返回 null，由调用方走错误兜底。
 *
 * 本地兜底没有 5 章深度报告，用现有字段拼出可读版本，
 * 让断网用户也能拿到完整结论——但明确是「降级版」，联网后拿更完整的云端版。
 */
export function buildLocalReport(local) {
  if (!local || !local.type) return null
  const code = local.type
  const p = PERSONALITY_TYPES[code]
  if (!p || !p.code) return null // 本地无此类型，无法兜底

  const strengths = p.strengths || []
  const weaknesses = p.weaknesses || []
  const careers = p.careers || []
  const theme = themeFor(code)

  const chapters = [
    { title: '类型概述', content: p.desc || p.summary || '' },
    { title: '核心优势', content: strengths.slice(0, 3).join('、') },
    { title: '成长空间', content: weaknesses.slice(0, 3).join('、') },
    { title: '适合的方向', content: careers.slice(0, 4).join('、') },
    {
      title: '给你的话',
      content: '你不必成为别人期待的样子，接纳自己的节奏，慢慢长成想成为的自己。'
    }
  ]

  return {
    source: 'local',
    code,
    name: p.name || code,
    emoji: theme.emoji,
    color: theme.color,
    subtitle: (p.groupLabel ? p.groupLabel + ' · ' : '') + code,
    summary: p.summary || '',
    basic: {
      one_liner: p.summary || '',
      traits: strengths.slice(0, 2).concat(weaknesses.slice(0, 2)),
      strengths: strengths.slice(0, 3),
      weaknesses: weaknesses.slice(0, 3),
      tip: '你的关键词：' + strengths.slice(0, 3).join(' · ')
    },
    advanced: {
      chapters,
      career: careers.slice(0, 4),
      famous: ''
    },
    winner: local.winner || {},
    percent: local.percent || {},
    hasBars: true
  }
}
