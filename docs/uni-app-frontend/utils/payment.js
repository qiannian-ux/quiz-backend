/**
 * 微信虚拟支付（前端只负责拉起，签名必须后端做）
 * ------------------------------------------------------------
 * 个人主体仅支持「道具直购」short_series_goods，不支持代币充值余额。
 *
 * 流程：
 *   ① 前端带着 productId 请求自家后端 POST /api/pay/order
 *   ② 后端用 OfferID + 现网 AppKey 算好 signData / paySig / signature，返回给前端
 *   ③ 前端把后端给的 payData 原样传给 wx.requestVirtualPayment 拉起支付
 *
 * ⚠️ AppKey / 签名逻辑绝不能进前端（包可被反编译 = 公开）。
 *    后端接口需要你来实现（见本文件末尾注释的字段清单）。
 */

// #ifdef MP-WEIXIN
import { post } from '@/utils/request.js'

/**
 * 购买一个道具（如「¥5.9 解锁全站测评」「请作者喝奶茶」）
 * @param {string} productId 微信后台【虚拟支付 → 道具管理】里的道具 ID
 * @returns {Promise<boolean>} true = 用户支付成功
 */
export async function buyProduct(productId) {
  // ① 后端下单 + 拿签名
  const payData = await post(
    '/api/pay/order',
    { productId },
    { showLoading: true, showError: true }
  )
  if (!payData) throw new Error('下单失败')

  // ③ 拉起支付（payData 由后端签名，前端不重算）
  return new Promise((resolve, reject) => {
    wx.requestVirtualPayment({
      ...payData,
      mode: 'short_series_goods',
      success: () => resolve(true),
      fail: (e) => reject(e)
    })
  })
}

/**
 * iOS 端拉起虚拟支付需微信客户端 ≥ 8.0.68（官方 5.3）。
 * 不满足时弹窗提示升级，返回 false 阻断支付。非 iOS 直接放行。
 */
export function checkIosVersion() {
  const sys = wx.getSystemInfoSync()
  if (sys.platform !== 'ios') return true
  const cur = (sys.version || '').split('.').map(Number)
  const base = [8, 0, 68]
  for (let i = 0; i < 3; i++) {
    if ((cur[i] || 0) > base[i]) return true
    if ((cur[i] || 0) < base[i]) break
  }
  uni.showModal({
    title: '提示',
    content: '请将微信更新至最新版后再进行支付',
    showCancel: false
  })
  return false
}

/*
 * ============ 后端 /api/pay/order 需要返回的 payData 字段 ============
 * 这些全部由后端用 AppKey 签名生成，前端只透传：
 *   offerId       虚拟支付 OfferID（MP 后台【虚拟支付 → 基本配置】）
 *   signData      JSON 字符串：{ offerId, buyQuantity, env:0, currencyType:'CNY',
 *                   productId, goodsPrice(分), outTradeNo, attach(透传 userId) }
 *   paySig        用 AppKey 对 "requestVirtualPayment&" + signData 做 HMAC-SHA256 的十六进制
 *   signature     用用户 session_key 对 signData 做 HMAC-SHA256 的十六进制
 *   env           0（现网，固定）
 *   outTradeNo    业务订单号（8-32 位，每次唯一，不能下划线开头）
 *
 * 发货以微信「发货推送」为准（不是前端 success），服务端收到推送后给用户开权益。
 * iOS 端开发者不能主动退款，客服话术别承诺"我帮你退"。
 */
// #endif
