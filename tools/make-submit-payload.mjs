/**
 * 生成 /api/quiz/submit 的测试 payload
 * ------------------------------------------------------------
 * 用法：
 *   node tools/make-submit-payload.mjs <quizCode> [baseUrl] [strategy]
 *
 *   quizCode   mbti | disc | enneagram | holland | attachment（默认 mbti）
 *   baseUrl    后端地址（默认 http://localhost:8080）
 *   strategy   zero = 每题都选第 0 个选项（结果确定，适合验收）
 *              random = 每题随机选（默认 zero）
 *
 * 原理：先 GET /api/quiz/{code} 拿到真实题目 id，
 * 再拼出 { quizCode, answers: [{questionId, optionIndex}] } 打到 stdout。
 * 题目 id 从后端来而不是从 seed SQL 里抠——顺便把「出题接口」也测了。
 *
 * 典型用法（配合 curl 验收算分接口）：
 *   node tools/make-submit-payload.mjs holland > payload.json
 *   curl -s -X POST http://localhost:8080/api/quiz/submit \
 *        -H "Content-Type: application/json" -d @payload.json
 */

const code = process.argv[2] || 'mbti'
const base = (process.argv[3] || 'http://localhost:8080').replace(/\/$/, '')
const strategy = process.argv[4] || 'zero'

async function main() {
  const res = await fetch(`${base}/api/quiz/${code}`)
  if (!res.ok) {
    console.error(`出题接口失败：GET /api/quiz/${code} -> HTTP ${res.status}`)
    console.error('先确认后端已启动、库里有这个测评（跑过 docs/db-full.sql）。')
    process.exit(1)
  }
  const quiz = await res.json()
  const questions = quiz.questions || []
  if (!questions.length) {
    console.error('出题接口返回 0 道题，检查 seed 是否灌过。')
    process.exit(1)
  }

  const answers = questions.map((q) => {
    const count = (q.options || []).length
    const idx = strategy === 'random' ? Math.floor(Math.random() * count) : 0
    return { questionId: q.id, optionIndex: idx }
  })

  const payload = { quizCode: code, answers }
  process.stdout.write(JSON.stringify(payload))

  // 进度信息走 stderr，不污染 stdout（stdout 要重定向进文件）
  console.error(`OK：${quiz.name}，${answers.length} 题，策略=${strategy}`)
}

main().catch((e) => {
  console.error('请求失败：' + (e && e.message ? e.message : e))
  process.exit(1)
})
