/**
 * 测评相关接口
 * ------------------------------------------------------------
 * 关键变化（动态测评重构）：
 *   - 新增 getQuizList()：首页网格完全由后端返回的动态列表驱动，
 *     不再在前端写死任何测评。加 / 删测评 = 操作 quiz 表，前端零改动。
 *   - getQuizQuestions(code) 接收 code 参数（不再用写死的 QUIZ_CODE）。
 *   - QUIZ_CODE 仅作"本地兜底默认"，正常流程不依赖它。
 */

import { get, post } from '@/utils/request.js'

/** 本地兜底默认测评（后端不可达时首页只给这一张） */
export const QUIZ_CODE = 'mbti'

/**
 * 首页测评列表。返回上线测评的展示信息（code/name/emoji/tag/...）。
 * 游客可访问。失败由调用方回退到本地 MBTI 卡，故默认不弹错误 toast
 * （showError:false）——有兜底的请求弹「服务异常」纯属噪音。
 */
export function getQuizList(opts = {}) {
  return get('/api/quiz/list', {}, opts)
}

/** 按 code 出题。code 默认 mbti（兜底用）。
 * 失败由 useQuiz 走本地题库兜底，故默认不弹错误 toast（showError:false）。 */
export function getQuizQuestions(code = QUIZ_CODE, opts = {}) {
  return get(`/api/quiz/${code}`, {}, opts)
}

/** 提交作答（后端算分，可选；当前前端走本地 calcResult 兜底）。 */
export function submitAnswers(payload) {
  return post('/api/quiz/submit', payload)
}
