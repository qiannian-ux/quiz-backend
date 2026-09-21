/**
 * 环境配置
 * ------------------------------------------------------------
 * 小程序里没有 process.env，环境切换只能手改常量或用条件编译。
 * 集中在一个文件里，上线/联调只改这一处。
 */

// 生产/联调统一走已部署的 HTTPS 域名
// 注意：必须在微信公众平台 + 抖音开放平台加入 request 合法域名白名单
export const BASE_URL = 'https://wangwang2.asia'

// 本地后端（开发调试用）。
// 为什么不用 localhost？—— 真机调试时 localhost 指的是「手机自己」，
// 手机没开 8080，就会报 ERR_CONNECTION_REFUSED。
// 换成电脑在局域网里的真实 IP（192.168.1.8 = WLAN 网卡），
// 只要手机和电脑连同一个 WiFi，模拟器和真机都能通。
// 电脑换了 WiFi / 重启后 IP 可能变，用 ipconfig 查「无线局域网适配器 WLAN」的 IPv4。
// 注意：真机跨网段 / 非同 WiFi 时此地址不可达，会卡到 TIMEOUT(10s) 才本地兜底——演示务必切上面 wangwang2.asia。
// export const BASE_URL = 'http://192.168.1.8:8080'

// localhost 只适合纯模拟器调试（微信开发者工具 PC 端）
// export const BASE_URL = 'http://localhost:8080'

export const TIMEOUT = 10000

/**
 * 一次测评的题量。
 * MBTI 完整题库 93 题，全做完要 8 分钟以上，小程序场景必然流失。
 * 取 24 题（四组对撞维度各 6 题），约 2 分钟完成，
 * 精度足够、体验可接受。抽样是分层的，见 composables/useQuiz.js。
 */
export const QUESTION_COUNT = 24

/**
 * 能力开关。硬编码值只是启动前的默认值，
 * 运行期应被后端下发的配置覆盖（见 utils/cloud.js 末尾的 TODO）。
 * 不能只靠前端写死：云开发到期那天改前端要发版 + 审核 1-3 天，
 * 而后端改一个值当秒生效。
 */
export const FEATURES = {
  wxCloud: true
}

/**
 * 当前运行平台标识，作为 X-Client-Platform 请求头发给后端。
 * 条件编译：代码只在对应平台被打进包里，另一端的包里根本不存在这行。
 */
export const PLATFORM = (() => {
  // #ifdef MP-WEIXIN
  return 'mp-weixin'
  // #endif
  // #ifdef MP-TOUTIAO
  return 'mp-toutiao'
  // #endif
  // #ifdef H5
  return 'h5'
  // #endif
  return 'unknown'
})()

/** 平台中文名，页面里直接展示 */
export const PLATFORM_TEXT = {
  'mp-weixin': '微信小程序',
  'mp-toutiao': '抖音小程序',
  h5: 'H5 调试',
  unknown: '未知环境'
}[PLATFORM]
