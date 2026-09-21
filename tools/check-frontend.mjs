/**
 * 前端全量语法体检：逐个文件做「只解析不执行」的语法检查
 * ------------------------------------------------------------
 * 为什么需要它：
 *   改完 uni-app 工程没有构建环节兜底（HBuilderX 里点运行才知道报错）。
 *   这个脚本能在提交前一次性把所有 .js / .vue 的 <script> 块过一遍语法，
 *   避免把手误（少个括号、模板字符串没闭合）留到真机调试阶段才发现。
 *
 * 做法：
 *   - .js 直接 node --check
 *   - .vue 抽出 <script> 块（含 setup）写成临时 .mjs 再 node --check
 *   - 只解析不执行，所以 import 的模块不存在也不会报错
 *
 * 用法：
 *   node tools/check-frontend.mjs
 */
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import { execFileSync } from 'node:child_process'

const SRC = process.argv[2] || 'D:/Users/35156/Documents/HBuilderProjects/quiz-miniapp'
const NODE = process.execPath
const SKIP_DIRS = new Set(['node_modules', 'unpackage', '.git', '.hbuilderx', 'dist'])

function walk(dir, base, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const abs = path.join(dir, name)
    const rel = path.join(base, name).replace(/\\/g, '/')
    const st = fs.statSync(abs)
    if (st.isDirectory()) {
      if (SKIP_DIRS.has(name)) continue
      walk(abs, rel, out)
    } else if (/\.(js|vue)$/.test(name)) {
      out.push(rel)
    }
  }
  return out
}

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'vue-check-'))
let ok = 0
const bad = []

for (const rel of walk(SRC, '')) {
  const abs = path.join(SRC, rel)
  let code = fs.readFileSync(abs, 'utf8')
  let target = abs

  if (rel.endsWith('.vue')) {
    const m = code.match(/<script[^>]*>([\s\S]*?)<\/script>/)
    if (!m) continue // 纯模板页面，没有脚本块
    code = m[1]
    target = path.join(tmp, rel.replace(/[\\/]/g, '_') + '.mjs')
    fs.writeFileSync(target, code)
  }

  try {
    execFileSync(NODE, ['--check', target], { stdio: 'pipe' })
    ok++
  } catch (e) {
    const msg = (e.stderr || '').toString().split('\n').slice(0, 3).join(' | ')
    bad.push(`${rel}\n    ${msg}`)
  }
}

fs.rmSync(tmp, { recursive: true, force: true })

console.log(`语法检查：通过 ${ok} 个${bad.length ? `，失败 ${bad.length} 个` : ''}`)
bad.forEach((b) => console.log('  ❌ ' + b))
console.log(bad.length ? '\n有语法错误 ❌' : '\n全部通过 ✅')
process.exit(bad.length ? 1 : 0)
