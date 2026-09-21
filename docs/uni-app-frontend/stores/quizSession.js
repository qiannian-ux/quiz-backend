/**
 * 测评会话（跨页面传递）
 * ------------------------------------------------------------
 * 重构点（R7）：答题 → 结果 的流转，不再依赖
 * uni.setStorageSync('quiz_answers') 拼大对象（无契约、易串数据）。
 * 改用模块级 reactive 单例：quiz 页写入、result 页读取，
 * 两个页面同属一个 JS 运行时，单例跨页面保留。
 *
 * 注意：单例只在当前小程序会话内有效（关掉重进清空，符合"一次测评"语义）。
 * 若需要"跨会话回看"，再落 user_quiz_record（后端）/ 本地历史（见 history 页）。
 */
import { reactive } from 'vue'

export const quizSession = reactive({
  quizCode: '',      // 当前测评 code，如 mbti
  quizName: '',      // 展示名
  emoji: '',         // 卡片图标
  answers: [],       // 作答明细
  result: null,      // calcResult 算出的结果对象

  /** 答题页在结束时调用：写入本次会话 */
  set(quizCode, quizName, emoji, answers) {
    this.quizCode = quizCode
    this.quizName = quizName
    this.emoji = emoji
    this.answers = answers
    this.result = null
  },

  /** 结果页调用：写入算分结果 */
  setResult(result) {
    this.result = result
  },

  /** 清掉当前会话（再测一次 / 离开） */
  clear() {
    this.quizCode = ''
    this.quizName = ''
    this.emoji = ''
    this.answers = []
    this.result = null
  }
})
