/**
 * 展示层小工具：时间格式化 / 连续天数
 * ------------------------------------------------------------
 * 为什么单独抽：这些是纯函数（只吃时间戳、只吐字符串），
 * 不碰 uni、不读 storage，"我的"页和历史页都要用，抽出来避免两处各写一遍。
 *
 * 存在的意义：页面上的数字必须是真的从本地记录算出来的，
 * 不能像之前那样写死一个「连续 5 天」。
 */

/** 时间戳 -> 'YYYY-MM-DD'（按本地时区，用于按天去重） */
export function dayKey(ts) {
  const d = new Date(ts)
  if (isNaN(d.getTime())) return ''
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${m}-${day}`
}

/** 时间戳 -> 「刚刚 / 3 小时前 / 2 天前 / 2026-09-19」 */
export function timeAgo(ts) {
  if (!ts) return '未知时间'
  const diff = Date.now() - Number(ts)
  if (isNaN(diff)) return '未知时间'
  if (diff < 0) return '刚刚'

  const MIN = 60 * 1000
  const HOUR = 60 * MIN
  const DAY = 24 * HOUR

  if (diff < MIN) return '刚刚'
  if (diff < HOUR) return Math.floor(diff / MIN) + ' 分钟前'
  if (diff < DAY) return Math.floor(diff / HOUR) + ' 小时前'
  if (diff < 7 * DAY) return Math.floor(diff / DAY) + ' 天前'
  return dayKey(ts)
}

/**
 * 连续打卡天数：从今天（或昨天）往回数，连续有记录的天数。
 * 今天没测过就从昨天开始算 —— 否则一到 0 点连续数就断，体感很差。
 * @param {Array} list 记录数组，元素需带 date 时间戳
 */
export function computeStreak(list) {
  const days = new Set()
  ;(list || []).forEach((h) => {
    if (h && h.date) {
      const k = dayKey(h.date)
      if (k) days.add(k)
    }
  })
  if (!days.size) return 0

  const now = new Date()
  const cur = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  if (!days.has(dayKey(cur.getTime()))) cur.setDate(cur.getDate() - 1)

  let n = 0
  while (days.has(dayKey(cur.getTime()))) {
    n++
    cur.setDate(cur.getDate() - 1)
  }
  return n
}

/** 距今几天（用于「加入 X 天」），至少返回 1 */
export function daysSince(ts) {
  if (!ts) return 0
  const diff = Date.now() - Number(ts)
  if (isNaN(diff) || diff < 0) return 1
  return Math.floor(diff / (24 * 60 * 60 * 1000)) + 1
}

/** 从记录里算出「测得最多的类型」，没有记录返回 null */
export function mostFrequent(list) {
  const map = {}
  ;(list || []).forEach((h) => {
    if (h && h.type) map[h.type] = (map[h.type] || 0) + 1
  })
  let best = null
  let n = 0
  Object.keys(map).forEach((k) => {
    if (map[k] > n) {
      n = map[k]
      best = k
    }
  })
  return best ? { code: best, count: n } : null
}
