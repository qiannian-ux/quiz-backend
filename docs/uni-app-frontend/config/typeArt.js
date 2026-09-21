/**
 * 16 型卡通角色图（作者自有 MBTI IP）
 * ------------------------------------------------------------
 * 用法：
 *   1. 把角色图放进 `static/types/`（例：static/types/INFP.png）
 *   2. 在下面的 TYPE_ART 里加一行： INFP: 'INFP.png',
 *   3. 没列出的类型会自动退回「圆形徽章 + 文字」兜底，不会开天窗
 *
 * 为什么不在页面里直接拼路径？
 *   拼路径的话，缺哪张图只有运行到那一页才发现，而且缺图会显示成
 *   空白方块。集中在这里登记，缺图就是明确的"没登记"，走兜底。
 *
 * ⚠️ 包体积硬约束（微信/抖音小程序主包 2MB）
 *   16 张动漫人物图很容易把包撑爆。建议：
 *   - 单张压到 30KB 以内（webp 优先，或 png 压缩）
 *   - 16 张合计控制在 500KB 以内
 *   - 实在压不下去就走 CDN（需在两端后台加 downloadFile 合法域名），
 *     或放进分包。别硬塞主包，否则上传直接失败。
 *   - 注意：static/ 下的文件不参与编译，但会计入包体积。
 */
export const TYPE_ART_DIR = '/static/types/'

/**
 * 已接入的角色图。键是类型码，值是 static/types/ 下的文件名。
 * 目前为空 —— 全部走兜底。登记后自动生效，页面无需改动。
 */
export const TYPE_ART = {
  // INFP: 'INFP.png',
  // ENFJ: 'ENFJ.png',
  // 其余 14 型照此补充
}

/**
 * 取某个类型的角色图完整路径；没登记返回空串，由调用方走兜底。
 * @param {String} code 类型码，如 'INFP'
 */
export function typeArt(code) {
  if (!code) return ''
  const file = TYPE_ART[code]
  return file ? TYPE_ART_DIR + file : ''
}
