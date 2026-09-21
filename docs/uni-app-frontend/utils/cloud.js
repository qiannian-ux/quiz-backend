/**
 * 微信云开发能力适配层
 * ------------------------------------------------------------
 * 这个文件的唯一目的：让"云开发"这件事对业务代码透明。
 *
 * 核心手法 —— 平台适配 + 空实现兜底：
 *   - 微信端：真实实现，受 FEATURES.wxCloud 开关控制
 *   - 抖音端 / H5：导出【同名】的空实现，返回 null / true / false
 *
 * 于是页面可以直接 import 使用，完全不用写条件编译：
 *
 *   const poster = await generatePoster(params)
 *   if (!poster) {
 *     // 降级：用 canvas 本地画，再保存相册
 *   }
 *
 * 半年后云开发到期，后台把开关改成 false，业务代码一行不动。
 */

import { FEATURES } from '@/config/env.js'

// 云开发环境 ID，在微信开发者工具「云开发」控制台里拿
const CLOUD_ENV = 'your-env-id'

// #ifdef MP-WEIXIN

let cloudReady = false

/**
 * 初始化云开发，在 App.vue 的 onLaunch 里调用。
 * 必须 try/catch：云环境欠费或被释放后 init 会抛错，
 * 不能让它把整个启动流程带崩。
 */
export function initCloud() {
  try {
    // 注意：微信云开发是 wx.cloud，不是 uni-app 自带的 uniCloud（那是 DCloud 另一套）
    if (typeof wx === 'undefined' || !wx.cloud) return false
    wx.cloud.init({ env: CLOUD_ENV, traceUser: true })
    cloudReady = true
  } catch (e) {
    cloudReady = false
  }
  return cloudReady
}

/** 云能力是否可用（环境正常 + 开关打开） */
export function isCloudEnabled() {
  return cloudReady && FEATURES.wxCloud
}

/**
 * 生成分享海报
 * @returns {Promise<String|null>} 归档后的图片 URL；null 表示不可用，调用方走本地降级
 */
export async function generatePoster(params) {
  if (!isCloudEnabled()) return null
  try {
    const res = await wx.cloud.callFunction({ name: 'poster', data: params })
    return (res && res.result && res.result.url) || null
  } catch (e) {
    return null
  }
}

/**
 * 文本内容安全检测
 * @returns {Promise<Boolean>} true = 通过。云能力不可用时放行，由后端兜底
 */
export async function checkText(content) {
  if (!isCloudEnabled()) return true
  try {
    const res = await wx.cloud.callFunction({
      name: 'secCheck',
      data: { type: 'text', content }
    })
    return !res || res.result === undefined || res.result.pass !== false
  } catch (e) {
    return true
  }
}

/**
 * 发送订阅消息
 * @returns {Promise<Boolean>} 是否发送成功
 */
export async function sendSubscribeMessage(tplId, data) {
  if (!isCloudEnabled()) return false
  try {
    await wx.cloud.callFunction({ name: 'subscribe', data: { tplId, data } })
    return true
  } catch (e) {
    return false
  }
}

// #endif

// #ifndef MP-WEIXIN

/**
 * 非微信端（抖音 / H5）没有云开发，这里提供同名的空实现。
 * 返回值语义和微信端一致：不可用返回 null / false，校验类返回 true（放行）。
 * 有了这一层，页面代码就不需要任何条件编译。
 */
export function initCloud() {
  return false
}

export function isCloudEnabled() {
  return false
}

export function generatePoster() {
  return Promise.resolve(null)
}

export function checkText() {
  return Promise.resolve(true)
}

export function sendSubscribeMessage() {
  return Promise.resolve(false)
}

// #endif

/**
 * TODO（M4 之后再做）：从后端拉取运行期配置覆盖 FEATURES
 * 后端加 GET /api/config 返回 { wxCloud: true } 之后：
 *
 * import { get } from '@/utils/request.js'
 *
 * export async function syncFeatures() {
 *   try {
 *     const cfg = await get('/api/config')
 *     FEATURES.wxCloud = !!cfg.wxCloud
 *     uni.setStorageSync('features', FEATURES)   // 离线时兜底
 *   } catch (e) {
 *     Object.assign(FEATURES, uni.getStorageSync('features') || {})
 *   }
 * }
 *
 * 在 App.vue 的 onLaunch 里先 syncFeatures() 再 initCloud()。
 */
