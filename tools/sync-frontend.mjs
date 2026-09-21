/**
 * 把真工程（HBuilderX）的源码单向同步回仓库副本 docs/uni-app-frontend
 * ------------------------------------------------------------
 * 为什么需要它：
 *   真工程在 D:\Users\35156\Documents\HBuilderProjects\quiz-miniapp，
 *   仓库里存了一份 docs/uni-app-frontend 用于 Git 版本管理。
 *   两份一旦分叉，仓库副本会变成过期快照（2026-09 已踩过一次）。
 *   所以每次改完前端都跑一次它。
 *
 * 设计原则：
 *   - **单向覆盖**：真工程 -> 仓库，只写不删（仓库里独有的 README 之类不会被清掉）
 *   - **跳过噪音**：node_modules / unpackage / .git 等构建产物与依赖
 *   - **跳过临时脚本**：下划线开头的 _xxx.mjs（一次性校验脚本，不入库）
 *   - **内容比对**：文件相同就跳过，只报真正变动的文件
 *
 * 用法：
 *   node tools/sync-frontend.mjs            # 同步
 *   node tools/sync-frontend.mjs --dry      # 只看差异不写盘
 */
import fs from 'node:fs'
import path from 'node:path'

const SRC = 'D:/Users/35156/Documents/HBuilderProjects/quiz-miniapp'
const DST = 'C:/Users/35156/IdeaProjects/quiz-backend/docs/uni-app-frontend'

/** 跳过的目录（构建产物 / 依赖 / 编辑器配置） */
const SKIP_DIRS = new Set([
  'node_modules', 'unpackage', '.git', '.hbuilderx', '.idea', '.vscode', 'dist'
])
/** 跳过的文件名（临时校验脚本、本机私有配置） */
const SKIP_FILES = new Set(['.DS_Store', 'thumbs.db'])

const dry = process.argv.includes('--dry')

function walk(dir, base, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const abs = path.join(dir, name)
    const rel = path.join(base, name).replace(/\\/g, '/')
    const st = fs.statSync(abs)
    if (st.isDirectory()) {
      if (SKIP_DIRS.has(name)) continue
      walk(abs, rel, out)
    } else {
      // 下划线开头 = 一次性脚本，不入库
      if (name.startsWith('_')) continue
      if (SKIP_FILES.has(name)) continue
      out.push(rel)
    }
  }
  return out
}

if (!fs.existsSync(SRC)) {
  console.error(`真工程目录不存在：${SRC}`)
  process.exit(1)
}

const files = walk(SRC, '')
let changed = 0
let same = 0
const changeList = []

for (const rel of files) {
  const from = path.join(SRC, rel)
  const to = path.join(DST, rel)
  const buf = fs.readFileSync(from)
  let need = true
  if (fs.existsSync(to)) {
    need = !fs.readFileSync(to).equals(buf)
  }
  if (!need) { same++; continue }
  changeList.push(`${fs.existsSync(to) ? 'M' : '+'} ${rel}`)
  if (!dry) {
    fs.mkdirSync(path.dirname(to), { recursive: true })
    fs.writeFileSync(to, buf)
  }
  changed++
}

console.log(`扫描 ${files.length} 个文件：变动 ${changed}，未变 ${same}${dry ? '（--dry 未写盘）' : ''}`)
changeList.forEach((l) => console.log('  ' + l))
console.log(dry ? '\n这是预演，加参数去掉 --dry 才会真同步' : '\n同步完成 ✅')
