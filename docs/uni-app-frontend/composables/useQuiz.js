import { ref, computed } from 'vue'
import { LOCAL_QUESTIONS, normalizeRemoteQuestion, DIMENSION_PAIRS } from '@/data/questions.js'
import { getQuizQuestions, submitAnswers } from '@/api/quiz.js'
import { calcResult } from '@/utils/scoring.js'
import { buildCloudReport, buildLocalReport } from '@/utils/report.js'
import { QUESTION_COUNT } from '@/config/env.js'

/**
 * 答题流程状态管理
 * ------------------------------------------------------------
 * 多测评改造（2026-09-20）：
 *   1. 不再假设「所有题都是两个极端的 5 档量表」。题目形态由数据决定：
 *        bipolar 两个选项且指向不同维度  -> 双极 5 档（左锚 … 右锚）
 *        likert  多个选项但全部指向同一维度 -> 同意度 5 档（量表题）
 *        single  多个选项指向不同维度      -> 竖排单选（如 DISC 四选一）
 *      判据是选项的维度码，不加任何"这套题叫什么名字"的硬编码，
 *      将来加第十套测评只要数据规范，前端零改动。
 *   2. 作答统一记录 optionIndex：后端 submit 只认 {questionId, optionIndex}，
 *      分值和维度由后端查库决定（前端传什么都不影响算分，杜绝篡改）。
 *   3. 题量：MBTI 93 题太长，抽样 QUESTION_COUNT 道（分层保证四组均衡）；
 *      其余测评本来就是 20~36 道，直接全量出题，不抽样——
 *      抽样会让"每型 4 题"变成"某型 1 题"，结果失去意义。
 *
 * 用法：
 *   const quiz = useQuiz('mbti')
 *   quiz.loadQuestions()
 */

/**
 * 从后端拉整套题。失败返回空数组，由调用方走本地兜底。
 * showError:false —— 本地题库能兜底，失败时弹「服务异常」纯属噪音。
 */
async function fetchRemoteQuestions(code) {
  try {
    const data = await getQuizQuestions(code, { showError: false })
    if (!data || !data.questions) return []
    return data.questions.map(normalizeRemoteQuestion).filter(Boolean)
  } catch (e) {
    return []
  }
}

/** 按 id 去重 */
function dedupe(list) {
  const seen = {}
  return list.filter((q) => {
    if (seen[q.id]) return false
    seen[q.id] = true
    return true
  })
}

/**
 * 判断题目的输入形态（关键：只看选项的维度码，不看测评名）。
 * @returns {'bipolar'|'likert'|'single'}
 */
function inputModeOf(q) {
  const opts = q.options || []
  if (opts.length === 2) return 'bipolar'
  if (opts.length >= 4) {
    const first = opts[0] && opts[0].type
    // 量表题：所有选项都指向同一个维度（只是分值 1~5 不同）
    if (first && opts.every((o) => o.type === first)) return 'likert'
  }
  return 'single'
}

/** 这道题属于哪一组对撞维度（MBTI 专用；其余测评会统统落到第一组） */
function pairOf(question) {
  const t = question.options && question.options[0] && question.options[0].type
  for (let i = 0; i < DIMENSION_PAIRS.length; i++) {
    const p = DIMENSION_PAIRS[i]
    if (p.left === t || p.right === t) return p.key
  }
  return DIMENSION_PAIRS[0].key
}

/**
 * 分层抽样：先按维度对分组，每组各取相同的题数，最后再打乱顺序。
 * 保证四个维度对的样本量一致，结果才稳定（不会 J/P 只靠 2 题定生死）。
 */
function pickBalanced(list, count) {
  const groups = {}
  list.forEach((q) => {
    const key = pairOf(q)
    if (!groups[key]) groups[key] = []
    groups[key].push(q)
  })
  const keys = Object.keys(groups)
  const perGroup = Math.max(1, Math.floor(count / keys.length))

  const picked = []
  keys.forEach((k) => {
    picked.push.apply(picked, shuffle(groups[k]).slice(0, perGroup))
  })

  if (picked.length < count) {
    const rest = shuffle(list.filter((q) => picked.indexOf(q) < 0))
    picked.push.apply(picked, rest.slice(0, count - picked.length))
  }
  return shuffle(picked).slice(0, count)
}

/** Fisher-Yates 洗牌，返回新数组（不改动原数组） */
function shuffle(arr) {
  const a = arr.slice()
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    const t = a[i]
    a[i] = a[j]
    a[j] = t
  }
  return a
}

export function useQuiz(quizCode = 'mbti', questionCount = QUESTION_COUNT) {
  const questions = ref([])
  const currentIndex = ref(0)
  const answers = ref([])
  const selectedValue = ref(0) // bipolar / likert：1..n
  const selectedIndex = ref(-1) // single：选项下标
  const loading = ref(false)
  const error = ref('')
  const finished = ref(false)
  const code = ref(quizCode)

  const currentQuestion = computed(() => questions.value[currentIndex.value] || null)
  const total = computed(() => questions.value.length)
  const isLast = computed(() => currentIndex.value >= total.value - 1)
  const progress = computed(() =>
    total.value === 0 ? 0 : Math.round(((currentIndex.value + 1) / total.value) * 100)
  )
  /** 本地算分结果（仅 MBTI 有意义；云端结果走 fetchReport） */
  const result = computed(() => (finished.value ? calcResult(answers.value) : null))

  /**
   * 组卷：后端优先，本地补齐。
   * - MBTI：题多，抽样 questionCount 道（分层均衡）
   * - 其他测评：题目本来就是全套，全量出题不抽样
   * - 后端挂了：只有 MBTI 有本地题库兜底，其余保持空（页面给重试入口）
   */
  async function loadQuestions() {
    loading.value = true
    error.value = ''
    try {
      const remote = dedupe(await fetchRemoteQuestions(code.value))
      const isMbti = code.value === 'mbti'
      let pool = remote
      if (isMbti && remote.length < questionCount) pool = remote.concat(LOCAL_QUESTIONS)

      // 只有 MBTI 抽样（93 题太长，只出 questionCount 道）。
      // 坑（2026-09-20）：这里原本判据是「能否分出多组对撞维度」，想做到"不加硬编码"，
      //   但 pairOf 是按字母匹配 MBTI 对撞组的，DISC 的 D/I/S/C 里的 I 会撞上 EI 组、
      //   S 会撞上 SN 组，于是 20 题的 DISC 被判定为"可抽样"、只出 12 题，结果失真。
      //   判据改为 explict：题量确实超出才抽，且只对 mbti 抽。
      const list = isMbti && pool.length > questionCount
        ? pickBalanced(pool, questionCount)
        : shuffle(pool)

      questions.value = list.map((q) => Object.assign({}, q, { mode: inputModeOf(q) }))
      currentIndex.value = 0
      answers.value = []
      selectedValue.value = 0
      selectedIndex.value = -1
      finished.value = false
    } catch (e) {
      questions.value = code.value === 'mbti'
        ? pickBalanced(LOCAL_QUESTIONS, questionCount).map((q) => Object.assign({}, q, { mode: inputModeOf(q) }))
        : []
      error.value = ''
    } finally {
      loading.value = false
    }
  }

  /**
   * 提交作答交给后端算分（可选）。
   * 当前结果页走 fetchReport（云端优先），这里保留裸提交入口。
   */
  async function submitQuiz() {
    return submitAnswers(buildPayload(answers.value))
  }

  /** 作答 → 后端要的 { quizCode, answers:[{questionId, optionIndex}] } */
  function buildPayload(list) {
    return {
      quizCode: code.value,
      answers: (list || [])
        .filter((a) => a && a.optionIndex != null && a.optionIndex >= 0)
        .map((a) => ({ questionId: a.questionId, optionIndex: a.optionIndex }))
    }
  }

  /**
   * 解析结果获取：云端优先，本地兜底。
   * ------------------------------------------------------------
   * 这是「提交 → 出解析」的唯一入口，结果页只调它。
   *   1. POST /api/quiz/submit 拿云端双档解析 -> source='cloud'
   *   2. 云端挂了/超时 -> 本地算分降级（仅 MBTI 有本地数据）-> source='local'
   *   3. 非 MBTI 且云端也失败 -> source='error'，report=null，页面提示重试
   *
   * @param {Array} [answersParam] 作答数组。结果页是独立 composable 实例，
   *   自己的 answers 是空的，必须由调用方把会话里的 answers 传进来。
   */
  async function fetchReport(answersParam) {
    const list = answersParam || answers.value
    try {
      const res = await submitAnswers(buildPayload(list))
      if (res && (res.basicReport || res.advancedReport || res.resultName)) {
        const report = buildCloudReport(res)
        if (report) return { report, source: 'cloud' }
      }
      throw new Error('cloud returned empty result')
    } catch (e) {
      try {
        const local = calcResult(list)
        const report = buildLocalReport(local)
        if (report) return { report, source: 'local' }
      } catch (e2) {
        // 本地兜底也失败（多半是作答结构不对），落到 error
      }
      return { report: null, source: 'error', message: '解析获取失败，请检查网络后重试' }
    }
  }

  /** 量表类（bipolar / likert）选档：1..n */
  function selectScale(value) {
    selectedValue.value = value
  }

  /** 单选类选第 i 个选项 */
  function select(index) {
    selectedIndex.value = index
  }

  /** 当前题是否已作答（模板用来放开「下一题」按钮） */
  function hasChoice() {
    const q = currentQuestion.value
    if (!q) return false
    return q.mode === 'single' ? selectedIndex.value >= 0 : selectedValue.value >= 1
  }

  /** 进入下一题，最后一题则结束 */
  function next() {
    const q = currentQuestion.value
    if (!q) return false
    const mode = q.mode || 'single'
    const opts = q.options || []
    let rec = { questionId: q.id, mode }

    if (mode === 'bipolar') {
      if (selectedValue.value < 1) return false
      const left = opts[0]
      const right = opts[1]
      const v = selectedValue.value
      rec.leftType = left ? left.type : null
      rec.rightType = right ? right.type : null
      rec.value = v
      // 1/2 -> 左极，4/5 -> 右极，3 = 中立：不下发后端（中立对算分没有信息量），
      // 但本地兜底仍用 value 算净偏向。
      rec.optionIndex = v <= 2 ? 0 : v >= 4 ? 1 : -1
    } else if (mode === 'likert') {
      if (selectedValue.value < 1) return false
      const idx = Math.min(opts.length, selectedValue.value) - 1
      const opt = opts[idx]
      rec.optionIndex = idx
      rec.type = opt ? opt.type : null
      rec.score = opt && opt.score != null ? opt.score : selectedValue.value
    } else {
      if (selectedIndex.value < 0) return false
      const opt = opts[selectedIndex.value]
      rec.optionIndex = selectedIndex.value
      rec.type = opt ? opt.type : null
      rec.score = opt && opt.score != null ? opt.score : 1
    }

    answers.value.push(rec)
    if (isLast.value) {
      finished.value = true
    } else {
      currentIndex.value += 1
      selectedValue.value = 0
      selectedIndex.value = -1
    }
    return true
  }

  function restart() {
    loadQuestions()
  }

  return {
    questions,
    currentIndex,
    currentQuestion,
    total,
    isLast,
    progress,
    answers,
    selectedValue,
    selectedIndex,
    loading,
    error,
    finished,
    code,
    result,
    loadQuestions,
    submitQuiz,
    fetchReport,
    selectScale,
    select,
    hasChoice,
    next,
    restart
  }
}
