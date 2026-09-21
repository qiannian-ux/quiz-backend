/**
 * 校验「后端下发的题目 → 前端题面形态」判据是否成立
 * ------------------------------------------------------------
 * 前端 composables/useQuiz.js 的 inputModeOf 只看选项的维度码决定题面：
 *   bipolar 2 个选项且指向不同维度 -> 双极 5 档
 *   likert  >=4 个选项但全指同一维度 -> 同意度量表
 *   single  多个选项指向不同维度    -> 竖排单选
 * 只要后端数据不规范（比如维度码缺失、量表题的维度码不一致），
 * 题面就会选错，用户看到的 UI 直接跑偏。这个脚本在加新测评时用来验收。
 *
 * 用法（后端先跑起来）：
 *   node tools/check-question-modes.mjs [baseUrl]
 */
const base = (process.argv[2] || 'http://127.0.0.1:8099').replace(/\/$/, '')
const CODES = ['mbti', 'disc', 'enneagram', 'holland', 'attachment']

/** 与前端 useQuiz.js 的 inputModeOf 完全一致 */
function inputModeOf(q) {
  const opts = q.options || []
  if (opts.length === 2) return 'bipolar'
  if (opts.length >= 4) {
    const first = opts[0] && opts[0].type
    if (first && opts.every((o) => o.type === first)) return 'likert'
  }
  return 'single'
}

/** 期望的题面：加新测评时在这里补一条，跑不通就说明数据不规范 */
const EXPECT = {
  mbti: 'bipolar',
  disc: 'single',
  enneagram: 'likert',
  holland: 'likert',
  attachment: 'likert'
}

let bad = 0

for (const code of CODES) {
  const res = await fetch(`${base}/api/quiz/${code}`)
  if (!res.ok) { console.log(`${code.padEnd(11)} FAIL  接口 ${res.status}`); bad++; continue }
  const data = await res.json()
  const qs = data.questions || []

  const stat = {}
  let missingCode = 0
  qs.forEach((q) => {
    const opts = (q.options || []).map((o) => ({
      type: o.dimensionCode,
      score: o.score != null ? o.score : 1
    }))
    if (opts.some((o) => !o.type)) missingCode++
    const m = inputModeOf({ options: opts })
    stat[m] = (stat[m] || 0) + 1
  })

  const modes = Object.keys(stat)
  const only = modes.length === 1 ? modes[0] : 'mixed'
  const ok = only === EXPECT[code] && missingCode === 0
  if (!ok) bad++
  console.log(
    `${code.padEnd(11)} ${ok ? 'PASS' : 'FAIL'}  ${qs.length} 题  题面=${only}` +
    `  明细=${JSON.stringify(stat)}` +
    (missingCode ? `  缺维度码=${missingCode}` : '') +
    (only === EXPECT[code] ? '' : `  期望=${EXPECT[code]}`)
  )
}

console.log(bad === 0 ? '\n题面判据全部正确 ✅' : `\n${bad} 个测评的题面判据不对 ❌`)
process.exit(bad ? 1 : 0)
