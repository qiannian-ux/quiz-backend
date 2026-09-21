/**
 * 请求封装
 * ------------------------------------------------------------
 * 为什么不用 axios？
 * 小程序运行环境没有 XMLHttpRequest，axios 跑不起来。
 * uni-app 的 uni.request 底层在微信端转 wx.request、抖音端转 tt.request，
 * 这一层差异 uni-app 已经抹平，我们不用自己写条件编译。
 *
 * 为什么还要再包一层？
 *   1. 少写 BASE_URL 和 header
 *   2. 统一超时、loading、错误提示 —— 否则每个页面都要写一遍 try/catch
 *   3. 统一鉴权：token 只在这里注入一次
 *   4. 调用方拿到的直接是业务数据，不用层层 res.data.data
 *   5. 将来后端统一成 {code, data, msg} 响应体，只改 unwrap() 一处
 */

import { BASE_URL, TIMEOUT, PLATFORM } from '@/config/env.js'
import { getToken } from '@/utils/auth.js'

/**
 * @param {Object} options
 * @param {String} options.url          接口路径，以 / 开头
 * @param {String} options.method       默认 GET
 * @param {Object} options.data         请求参数
 * @param {Object} options.header       额外请求头
 * @param {Boolean} options.showLoading 是否显示全屏 loading
 * @param {Boolean} options.showError   失败是否自动 toast
 * @returns {Promise} 成功 resolve 业务数据，失败 reject
 */
export default function request(options = {}) {
  const {
    url,
    method = 'GET',
    data = {},
    header = {},
    showLoading = false,
    showError = true
  } = options

  if (showLoading) {
    uni.showLoading({ title: '加载中', mask: true })
  }

  return new Promise((resolve, reject) => {
    uni.request({
      url: BASE_URL + url,
      method,
      data,
      timeout: TIMEOUT,
      header: {
        'content-type': 'application/json',
        'X-Client-Platform': PLATFORM,
        ...buildAuthHeader(),
        ...header
      },

      // success 只代表"网络请求完成"，404 / 500 也会进这里，要靠 statusCode 判断
      success: (res) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(unwrap(res.data))
        } else if (res.statusCode === 401) {
          // M4 接入 JWT 后，这里做 token 过期 -> 重新登录 -> 重放请求
          handleError('登录已过期', showError)
          reject({ code: 401, message: 'unauthorized' })
        } else {
          handleError(`服务异常（${res.statusCode}）`, showError)
          reject({ code: res.statusCode, message: res.data })
        }
      },

      // fail 只有网络层失败才走：超时、断网、域名不在白名单
      fail: (err) => {
        let msg = '网络请求失败'
        if (err && err.errMsg) {
          if (err.errMsg.indexOf('timeout') !== -1) msg = '请求超时，请检查网络'
          // 真机上最常见的坑：域名没配进平台白名单
          if (err.errMsg.indexOf('url not in domain list') !== -1) {
            msg = '域名未加入小程序合法域名白名单'
          }
        }
        handleError(msg, showError)
        reject(err)
      },

      complete: () => {
        if (showLoading) uni.hideLoading()
      }
    })
  })
}

/**
 * 拆包装：兼容"裸数据"和"统一响应体"两种后端风格。
 * 现在后端 QuizController 直接 return 实体对象，所以原样返回。
 * 等后端统一成 {code, data, msg} 后改成：
 *   if (raw && typeof raw === 'object' && 'code' in raw) {
 *     if (raw.code !== 0) { handleError(raw.msg); return Promise.reject(raw) }
 *     return raw.data
 *   }
 */
function unwrap(raw) {
  return raw
}

function buildAuthHeader() {
  const token = getToken()
  return token ? { Authorization: 'Bearer ' + token } : {}
}

function handleError(message, showError) {
  if (!showError) return
  uni.showToast({ title: message, icon: 'none', duration: 2000 })
}

export const get = (url, data = {}, opts = {}) =>
  request({ url, method: 'GET', data, ...opts })

export const post = (url, data = {}, opts = {}) =>
  request({ url, method: 'POST', data, ...opts })
