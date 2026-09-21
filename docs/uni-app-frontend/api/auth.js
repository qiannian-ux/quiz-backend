/**
 * 登录相关接口（M4）
 * ------------------------------------------------------------
 * 安全底线：前端只拿 code，绝不涉及 appSecret。
 * 换 openid、存 session_key、签发 JWT 全在后端做。
 *
 * 为什么这么分？
 *   小程序包可以被反编译，任何写在前端的密钥都等于公开。
 *   code 是一次性门票（5 分钟有效），即使被截获也换不到东西——
 *   因为换取时必须同时出示只有后端才知道的 appSecret。
 */

import { post } from '@/utils/request.js'
import { setToken, removeToken, getToken } from '@/utils/auth.js'
import { PLATFORM } from '@/config/env.js'

/**
 * 后端使用的平台标识。
 * env.js 里 PLATFORM 是 uni-app 的写法（mp-weixin / mp-toutiao / h5），
 * 去掉前缀后更直观，存进数据库的 user_platform.platform 就是 weixin / toutiao。
 */
const SERVER_PLATFORM = PLATFORM.replace('mp-', '')

/**
 * 静默登录 —— 用户完全无感知，不弹窗、不转圈、不授权。
 *
 * 流程：
 *   ① uni.login() 拿一次性 code
 *   ② code 发给自家后端 → 后端找微信换 openid + session_key → 建/更新用户 → 返回 JWT
 *   ③ token 存本地，之后 request.js 自动给每个请求带上 Authorization
 *
 * 注意：这个函数**允许失败**。登录挂了用户照样能测评（题库有本地兜底），
 * 所以调用方一定要 catch，不能让它把启动流程带崩。
 */
export async function login() {
  // ① 调起平台登录拿 code（uni-app 已抹平 wx.login / tt.login 的差异）
  const loginRes = await uni.login()

  // ② 用 code 换 token
  //    showLoading / showError 都关掉：静默登录不该有任何视觉打扰
  const data = await post(
    '/api/auth/login',
    {
      code: loginRes.code,
      platform: SERVER_PLATFORM
    },
    {
      showLoading: false,
      showError: false
    }
  )

  // ③ 存 token —— 存完这一步，后续所有请求自动带上
  if (data && data.token) {
    setToken(data.token)
  }

  return data
}

/**
 * 是否"看起来"已登录（本地有 token 即算）。
 * 注意这**不校验 token 是否真的有效** —— 有效性由后端判断，
 * 前端只用来决定"要不要再走一次登录"。
 */
export function isLoggedIn() {
  return !!getToken()
}

/**
 * 退出登录：清掉本地 token。
 * 真正的"作废"由后端控制（token 过期即失效），前端只是不再带它。
 */
export function logout() {
  removeToken()
}
