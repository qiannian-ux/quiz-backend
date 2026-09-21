/**
 * 模拟「前端真实作答」打 submit，验证前端 → 后端的作答映射是对的
 * ------------------------------------------------------------
 * 为什么需要它：
 *   前端答题页有三种题面（双极 5 档 / 同意度量表 / 竖排单选），
 *   最终都收敛成 { questionId, optionIndex } 发给后端。
 *   只测「每题都选 0」不足以证明前端那套映射真能跑通——
 *   比如 MBTI 的 5 档里 3（中立）是不下发的、量表题 5 档要落成 index 4。
 *   这个脚本按前端同样的规则造作答，再打真接口，端到端验证映射。
 *
 * 用法（后端先跑起来）：
 *   node tools/simulate-frontend-submit.mjs [baseUrl]
 *
 * 覆盖：
 *   mbti      抽样 24 题 + 随机 1~5 档（中性档跳过，不下发）
 *   disc      竖排单选：每题随机选一个选项
 *   holland   同意度量表：随机 1~5 档 -> optionIndex 0~4
 *   enneagram 同意度量表：同上
 *   attachment 同意度量表：同上（结果码变长，用合法码集合校验）
 */
const base = (process.argv[2] || 'http://127.0.0.1:8099').replace(/\/$/, '')

/** 前端同款：双极 5 档 -> optionIndex（1/2 左，4/5 右，3 中立不下发） */
function bipolarIndex(v) {
  return v <= 2 ? 0 : v >= 4 ? 1 : -1
}

/** 前端同款：量表 5 档 -> optionIndex（1..5 -> 0..4，选项不足则封顶） */
function likertIndex(v, optCount) {
  return Math.min(optCount, v) - 1
}

const rand = (n) => 1 + Math.floor(Math.random() * n)

/**
 * 结果码校验：传数字=校验长度，传数组=校验是否在合法码集合内。
 * 依恋这类 MAX 测评的结果是 secure/anxious/avoidant/fearful，长度不固定，
 * 不能用长度断言（曾误判为失败）。
 */
function typeOk(type, check) {
  if (Array.isArray(check)) return check.includes(type)
  return (type || '').length === check
}

async function getQuiz(code) {
  const res = await fetch(`${base}/api/quiz/${code}`)
  if (!res.ok) throw new Error(`GET /api/quiz/${code} -> ${res.status}`)
  return res.json()
}

async function submit(payload) {
  const res = await fetch(`${base}/api/quiz/submit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  })
  if (!res.ok) throw new Error(`submit -> ${res.status} ${await res.text()}`)
  return res.json()
}

async function runMbti() {
  const quiz = await getQuiz('mbti')
  // 前端同款抽样：只取前 24 题（真实实现是分层抽样，这里只验证映射，不验证抽样）
  const qs = (quiz.questions || []).slice(0, 24)
  const answers = []
  let skipped = 0
  qs.forEach((q) => {
    const v = rand(5)
    const idx = bipolarIndex(v)
    if (idx < 0) { skipped++; return }
    answers.push({ questionId: q.id, optionIndex: idx })
  })
  const r = await submit({ quizCode: 'mbti', answers })
  const ok = /^[EI][SN][TF][JP]$/.test(r.type || '')
  console.log(`mbti      ${ok ? 'PASS' : 'FAIL'}  type=${r.type} 下发 ${answers.length} 题（中立跳过 ${skipped}）name=${r.resultName}`)
  return ok
}

async function runSingle(code, expectLen) {
  const quiz = await getQuiz(code)
  const qs = quiz.questions || []
  const answers = qs.map((q) => ({
    questionId: q.id,
    optionIndex: Math.floor(Math.random() * (q.options || []).length)
  }))
  const r = await submit({ quizCode: code, answers })
  const ok = typeOk(r.type, expectLen) && !!r.resultName && !!r.basicReport
  console.log(`${code.padEnd(9)} ${ok ? 'PASS' : 'FAIL'}  type=${r.type} 共 ${answers.length} 题 name=${r.resultName}`)
  return ok
}

async function runLikert(code, expectLen) {
  const quiz = await getQuiz(code)
  const qs = quiz.questions || []
  const answers = qs.map((q) => ({
    questionId: q.id,
    optionIndex: likertIndex(rand(5), (q.options || []).length)
  }))
  const r = await submit({ quizCode: code, answers })
  const ok = typeOk(r.type, expectLen) && !!r.resultName && !!r.advancedReport
  console.log(`${code.padEnd(9)} ${ok ? 'PASS' : 'FAIL'}  type=${r.type} 共 ${answers.length} 题 name=${r.resultName}`)
  return ok
}

async function main() {
  const results = []
  try { results.push(await runMbti()) } catch (e) { console.log('mbti      FAIL ' + e.message); results.push(false) }
  try { results.push(await runSingle('disc', 1)) } catch (e) { console.log('disc      FAIL ' + e.message); results.push(false) }
  try { results.push(await runLikert('enneagram', 1)) } catch (e) { console.log('enneagram FAIL ' + e.message); results.push(false) }
  try { results.push(await runLikert('holland', 3)) } catch (e) { console.log('holland   FAIL ' + e.message); results.push(false) }
  try { results.push(await runLikert('attachment', ['secure', 'anxious', 'avoidant', 'fearful'])) } catch (e) { console.log('attachment FAIL ' + e.message); results.push(false) }

  const bad = results.filter((r) => !r).length
  console.log(`\n${bad === 0 ? '前端作答映射全部通过 ✅' : `失败 ${bad} 项 ❌`}`)
  process.exit(bad === 0 ? 0 : 1)
}

main()
