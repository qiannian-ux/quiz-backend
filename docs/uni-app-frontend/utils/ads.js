/**
 * 广告管理（仅微信小程序）
 * ------------------------------------------------------------
 * 把三种广告的创建/展示收敛到这一处，页面只调 showBanner / showInterstitial / showRewarded。
 * 广告对象做成模块级单例，避免每次展示都新建（微信会限频）。
 *
 * 抖音端见底部 TODO（穿山甲 API 不同，需另接）。
 */

// #ifdef MP-WEIXIN
import { AD_UNIT } from '@/config/ad.js'

let _banner = null
let _interstitial = null
let _rewarded = null

/** 底部条幅：结果页 onMounted 调 showBanner()，onUnload 调 hideBanner() */
export function showBanner() {
  if (!_banner) {
    const info = wx.getWindowInfo ? wx.getWindowInfo() : wx.getSystemInfoSync()
    _banner = wx.createBannerAd({
      adUnitId: AD_UNIT.banner,
      style: { left: 0, top: info.windowHeight - 100, width: info.windowWidth }
    })
    _banner.onError((e) => console.warn('[ads][banner]', e))
  }
  _banner.show().catch(() => {})
}

export function hideBanner() {
  if (_banner) _banner.hide()
}

/**
 * 插屏：返回 Promise<boolean>。
 * 微信服务端有频次限制（同一用户约 5 分钟一次、每天有上限），
 * 超限时 show() 会 reject，这里统一 resolve(false)，调用方照常继续跳转即可。
 */
export function showInterstitial() {
  return new Promise((resolve) => {
    if (!_interstitial) {
      _interstitial = wx.createInterstitialAd({ adUnitId: AD_UNIT.interstitial })
      _interstitial.onError(() => resolve(false))
      _interstitial.onClose(() => resolve(true))
    }
    _interstitial.show().catch(() => resolve(false))
  })
}

/**
 * 激励视频：返回 Promise<boolean>，true=用户完整看完。
 * 只有关掉时 res.isEnded === true 才发奖励，中途退出不发。
 */
export function showRewarded() {
  return new Promise((resolve) => {
    if (!_rewarded) {
      _rewarded = wx.createRewardedVideoAd({ adUnitId: AD_UNIT.rewarded })
      _rewarded.onError((e) => {
        console.warn('[ads][rewarded]', e)
        resolve(false)
      })
      _rewarded.onClose((res) => resolve(!!(res && res.isEnded)))
    }
    _rewarded.load().then(() => _rewarded.show()).catch(() => resolve(false))
  })
}

/** 客户端冷却：避免 5 分钟内重复弹插屏（配合微信服务端限频，体验更顺） */
export function canShowInterstitial(gapMin = 5) {
  const last = uni.getStorageSync('ad_interstitial_ts') || 0
  const ok = Date.now() - last > gapMin * 60 * 1000
  if (ok) uni.setStorageSync('ad_interstitial_ts', Date.now())
  return ok
}
// #endif

// #ifdef MP-TOUTIAO
// TODO 抖音端：穿山甲广告，API 不同。
//   激励视频：tt.createRewardedVideoAd({ adUnitId })
//   插屏：tt.createInterstitialAd(...)
//   Banner：tt.createBannerAd(...)
// 抖音广告位 ID 在【抖音开放平台 → 变现 → 广告位】创建，与微信不通用。
// #endif
