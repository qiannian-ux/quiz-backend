/**
 * token 存取（M4 双端登录做完后再启用）
 * ------------------------------------------------------------
 * 现在后端还没有登录接口，所以这个文件暂时是"空壳"。
 * 先写出来是为了让 request.js 不用改结构，等 M4 做完直接打开即可。
 *
 * 小程序本地存储 API 两端不同（wx.setStorageSync / tt.setStorageSync），
 * uni-app 统一成 uni.setStorageSync，我们不用自己判断平台。
 */

const TOKEN_KEY = 'quiz_token'

export function getToken() {
  try {
    return uni.getStorageSync(TOKEN_KEY) || ''
  } catch (e) {
    return ''
  }
}

export function setToken(token) {
  uni.setStorageSync(TOKEN_KEY, token)
}

export function removeToken() {
  uni.removeStorageSync(TOKEN_KEY)
}

/**
 * M4 要写的登录逻辑示意（先别实现，留着看思路）：
 *
 * export function login() {
 *   return new Promise((resolve, reject) => {
 *     // #ifdef MP-WEIXIN
 *     wx.login({ success: res => resolve(res.code) })
 *     // #endif
 *     // #ifdef MP-TOUTIAO
 *     tt.login({ force: true, success: res => resolve(res.code) })
 *     // #endif
 *   }).then(code => post('/api/auth/login', { code }))
 *     .then(data => { setToken(data.token); return data })
 * }
 *
 * 关键点：两端都只拿 code，openid 换取和 JWT 签发全在后端做。
 * 前端绝不接触 appSecret —— 这是安全底线。
 */
