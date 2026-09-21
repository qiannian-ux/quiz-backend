<script>
import { initCloud } from '@/utils/cloud.js'
import { login } from '@/api/auth.js'

/**
 * 应用入口
 * ------------------------------------------------------------
 * App.vue 只能用 Options API（export default），不能用 <script setup>。
 * 因为 uni-app 需要在这里接住应用级生命周期：onLaunch / onShow / onHide。
 */
export default {
	onLaunch: function() {
		// 云开发初始化。
		// 关键点：不 await、不抛错 —— 云环境欠费或未开通时，
		// 这里必须静默失败，不能把整个启动流程带崩。
		initCloud()

		// 静默登录：拿 code 换 token，用户完全无感知。
		// 同样不 await —— 登录是异步的，不能挡住页面渲染。
		this.silentLogin()
	},

	methods: {
		/**
		 * 静默登录，失败也绝不影响主流程。
		 *
		 * 为什么允许失败？
		 *   题库有本地兜底（data/questions.js），游客照样能完整测评。
		 *   登录只是为了将来能存结果、攒探币、用虚拟支付——
		 *   它是"增强"，不是"前提"。
		 *
		 * 所以这里只记日志：不弹窗、不重试、不阻塞。
		 */
		async silentLogin() {
			try {
				await login()
			} catch (e) {
				console.warn('[auth] 静默登录失败，以游客身份继续', e)
			}
		}
	},

	onShow: function() {},
	onHide: function() {}
}
</script>

<style>
	/*
	 * ============================================================
	 * 探我趣测 · 设计令牌 v3「卡通动漫 · 贴纸风」
	 * ------------------------------------------------------------
	 * v2 走的是克制现代风（细描边 + 柔和投影 + 低饱和），
	 * 不是作者想要的方向。v3 转向卡通动漫，靠四件事立住：
	 *   1. 粗描边  —— 3rpx 墨色实线，卡通的"轮廓感"来源
	 *   2. 硬投影  —— 0 6rpx 0 无模糊，做出贴纸/立牌的立体感
	 *   3. 按下塌陷 —— translateY + 撤掉投影，模拟"按进纸面"
	 *   4. 高饱和  —— 马卡龙但提饱和，配暖奶油底
	 *
	 * 旧变量名全部保留为别名，页面不改也不会崩。
	 * ============================================================
	 */
	page {
		/* ---- 墨色：仅用于极少数需要深色强调处 ---- */
		--c-ink: #000000;
		--c-stroke: 1rpx;

		/*
		 * ---- 中性色：Apple 系统灰阶 ----
		 * #f2f2f7 = systemGroupedBackground（分组灰底），
		 * 这是 Apple 质感的地基：卡片不做描边、不靠重投影，
		 * 全靠"白卡片浮在灰底上"这一层关系来分层。
		 */
		--c-bg: #f2f2f7;
		--c-surface: #ffffff;
		--c-surface-2: #f2f2f7;
		--c-surface-3: #e5e5ea;
		--c-text: #000000;
		--c-text-2: #3c3c43;
		--c-sub: #6e6e73;
		--c-faint: #8e8e93;
		--c-sep: rgba(60, 60, 67, 0.12);
		--c-border: rgba(60, 60, 67, 0.1);
		--c-border-2: rgba(60, 60, 67, 0.18);

		/* ---- 品牌与语义色：Apple 系统色 ---- */
		--c-primary: #007aff;
		--c-primary-2: #0067d9;
		--c-primary-soft: #e8f2ff;
		--c-success: #34c759;
		--c-warning: #ff9f0a;
		--c-danger: #ff3b30;

		/* ---- 人格四大家族色：沿用 Apple 系统色的四个相 ---- */
		--c-nt: #5e5ce6;
		--c-nf: #34c759;
		--c-sj: #007aff;
		--c-sp: #ff9f0a;

		/* ---- 旧名兼容（逐步迁移后可删） ---- */
		--c-pink: #ff3b30;
		--c-purple: #5e5ce6;
		--c-mint: #34c759;
		--c-peach: #ff9f0a;
		--c-sun: #ff9f0a;
		--c-lilac: #5e5ce6;

		/* ---- 圆角：Apple 卡片约 14px(≈28rpx)，比卡通小一档，克制 ---- */
		--r-sm: 16rpx;
		--r-md: 20rpx;
		--r-lg: 24rpx;
		--r-card: 28rpx;
		--r-xl: 36rpx;
		--r-full: 999rpx;

		/* ---- 阴影：极克制 ----
		 * Apple 几乎不用投影做分层，层级靠"白卡片 + 灰底"的关系；
		 * 只有真正浮起的元素（弹层、主按钮）才给一点点。
		 */
		--sh-1: 0 2rpx 8rpx rgba(0, 0, 0, 0.04);
		--sh-2: 0 8rpx 24rpx rgba(0, 0, 0, 0.08);
		--sh-3: 0 16rpx 44rpx rgba(0, 0, 0, 0.14);
		--sh-card: var(--sh-1);
		--sh-float: var(--sh-2);
		--sh-btn: 0 6rpx 16rpx rgba(0, 122, 255, 0.24);

		/* ---- 间距：4 的倍数 ---- */
		--sp-xs: 8rpx;
		--sp-sm: 16rpx;
		--sp-md: 24rpx;
		--sp-lg: 32rpx;
		--sp-xl: 48rpx;

		/* ---- 字阶：6 档 ---- */
		--fs-display: 56rpx;
		--fs-t1: 40rpx;
		--fs-t2: 32rpx;
		--fs-body-l: 30rpx;
		--fs-body: 28rpx;
		--fs-cap: 24rpx;
		--fs-micro: 22rpx;

		/* ---- 动效 ---- */
		--ease-out: cubic-bezier(0.2, 0.8, 0.2, 1);
		--dur-fast: 120ms;
		--dur-base: 240ms;
		--dur-slow: 320ms;

		background-color: #f2f2f7;
	}

	/* 去掉小程序 button 默认边框，页面里统一用 view 画按钮 */
	button::after {
		border: none;
	}

	/* ============================================================
	 * 组件库
	 * ============================================================ */

	/*
	 * 卡片：纯白 + 小圆角 + 极淡投影，无描边。
	 * Apple 不做描边也不靠重投影分层 —— 层级来自"白卡片浮在 #f2f2f7 灰底上"
	 * 这一层明暗关系。描边一加就立刻变"安卓味/卡通风"。
	 */
	.u-card {
		background: var(--c-surface);
		border-radius: var(--r-card);
		box-shadow: var(--sh-1);
		border: none;
		overflow: hidden;
	}

	/*
	 * 分组列表：Apple 最标志性的模式。
	 * 一张白圆角卡里嵌若干行，行与行之间用「左侧内缩」的细分割线。
	 * 分割线内缩（跟文字左对齐）而不是通栏，是这个模式的辨识点。
	 */
	.u-group {
		background: var(--c-surface);
		border-radius: var(--r-card);
		overflow: hidden;
		box-shadow: var(--sh-1);
	}
	.u-row {
		display: flex;
		align-items: center;
		gap: 20rpx;
		padding: 26rpx 28rpx;
		min-height: 88rpx;
		background: var(--c-surface);
		width: 100%;
		box-sizing: border-box;
	}
	.u-row--hover { background: var(--c-surface-2); }
	.u-sep {
		height: 1rpx;
		background: var(--c-sep);
		margin-left: 28rpx;
	}

	/*
	 * 角色徽章：柔和圆形头像位（无描边）。
	 * 优先放作者的 MBTI IP 人物图（<image class="u-badge-img">），
	 * 没图时退化为 emoji/汉字兜底（<text class="u-badge-t">）。
	 */
	.u-badge {
		width: 96rpx;
		height: 96rpx;
		border-radius: 50%;
		background: var(--c-surface-2);
		border: none;
		display: flex;
		align-items: center;
		justify-content: center;
		overflow: hidden;
		flex: none;
	}
	.u-badge-img { width: 100%; height: 100%; }
	.u-badge-t { font-size: 40rpx; }

	/* 小标：tinted 胶囊，无描边 */
	.u-sticker {
		display: inline-block;
		font-size: 20rpx;
		font-weight: 500;
		color: var(--c-primary);
		background: var(--c-primary-soft);
		padding: 5rpx 16rpx;
		border-radius: var(--r-full);
	}

	/* 区块标题：标题 + 右侧说明 */
	.u-sec {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
		margin: var(--sp-lg) 6rpx var(--sp-sm);
	}
	.u-sec-t {
		font-size: var(--fs-t2);
		font-weight: 600;
		color: var(--c-text);
	}
	.u-sec-s {
		font-size: var(--fs-micro);
		color: var(--c-faint);
	}

	/* ---------- 按钮 ----------
	 * 高度 96rpx（≈48px，超过 44px 最小热区要求）。
	 * Apple 的按钮圆角约 12px(≈24rpx)，不是全圆胶囊 —— 全圆是卡通/安卓味。
	 * 按下态用"整体变淡"（HIG 的 dimmed），不是位移也不是缩放。
	 */
	.u-btn {
		height: 96rpx;
		padding: 0 40rpx;
		border-radius: var(--r-lg);
		border: none;
		background: var(--c-primary);
		display: flex;
		align-items: center;
		justify-content: center;
		transition: opacity var(--dur-fast) var(--ease-out);
	}
	.u-btn-t {
		font-size: var(--fs-body-l);
		font-weight: 500;
		color: #ffffff;
		letter-spacing: 0.5rpx;
	}
	.u-btn--primary { background: var(--c-primary); box-shadow: var(--sh-btn); }
	.u-btn--secondary { background: var(--c-surface-2); box-shadow: none; }
	.u-btn--secondary .u-btn-t { color: var(--c-primary); }
	.u-btn--ghost { background: transparent; box-shadow: none; }
	.u-btn--ghost .u-btn-t { color: var(--c-primary); }
	.u-btn--sm { height: 72rpx; padding: 0 30rpx; border-radius: var(--r-md); }
	.u-btn--sm .u-btn-t { font-size: 27rpx; }
	.u-btn--block { width: 100%; }
	.u-btn--disabled { opacity: 0.4; box-shadow: none; }
	.u-btn--hover { opacity: 0.72; }

	/* ---------- 标签 / 胶囊：tinted 底，无描边 ---------- */
	.u-chip {
		display: inline-block;
		font-size: var(--fs-micro);
		font-weight: 500;
		color: var(--c-sub);
		background: var(--c-surface-2);
		padding: 6rpx 18rpx;
		border-radius: var(--r-full);
		border: none;
	}
	.u-chip--primary {
		background: var(--c-primary-soft);
		color: var(--c-primary);
	}
	.u-chip--outline {
		background: transparent;
		border: 1rpx solid var(--c-border-2);
	}
	/* 旧名兼容 */
	.u-pill {
		display: inline-block;
		font-size: var(--fs-micro);
		font-weight: 500;
		color: var(--c-sub);
		background: var(--c-surface-2);
		padding: 6rpx 18rpx;
		border-radius: var(--r-full);
		border: none;
	}

	/* ---------- 遮罩 + 底部弹层 ----------
	 * 不用 inset 简写：部分小程序样式解析器不支持，
	 * 老老实实写四个方向最稳。
	 */
	.u-mask {
		position: fixed;
		top: 0;
		right: 0;
		bottom: 0;
		left: 0;
		background: rgba(31, 36, 48, 0.4);
		z-index: 99;
		display: flex;
		align-items: flex-end;
		justify-content: center;
	}
	.u-sheet {
		width: 100%;
		background: var(--c-surface);
		border-radius: var(--r-xl) var(--r-xl) 0 0;
		padding: var(--sp-lg) var(--sp-lg) var(--sp-xl);
		box-sizing: border-box;
		/* 弹层是真正"浮起"的元素，这里才给投影；不用描边切层次 */
		box-shadow: var(--sh-3);
		border-top: none;
		z-index: 100;
		animation: u-sheet-up 280ms var(--ease-out);
	}
	@keyframes u-sheet-up {
		from { transform: translateY(100%); }
		to { transform: translateY(0); }
	}
	/* 系统开启「减弱动态效果」时去掉位移，仅保留透明度 */
	@media (prefers-reduced-motion: reduce) {
		.u-sheet { animation: none; }
	}

	/* ---------- 空态 ----------
	 * 三件套：图形 + 说明 + 一个明确出口。
	 * 只放一个表情符号等于把用户丢在死胡同。
	 */
	.u-empty {
		text-align: center;
		padding: 120rpx 48rpx;
	}
	/*
	 * 空态图形：柔和圆角方形（Apple continuous corner 近似）+ 居中图标。
	 * 必须往里放 <text class="u-empty-ico">，否则就是一个空的灰方块，
	 * 看起来像图裂了 —— 这个坑踩过一次。
	 * 这里也是将来换插画 / 角色图的位置。
	 */
	.u-empty-icon {
		width: 132rpx;
		height: 132rpx;
		border-radius: var(--r-xl);
		background: var(--c-surface-3);
		border: none;
		margin: 0 auto var(--sp-md);
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.u-empty-ico {
		font-size: 56rpx;
		line-height: 1;
	}
	.u-empty-t {
		font-size: var(--fs-body-l);
		font-weight: 600;
		color: var(--c-text);
		display: block;
	}
	.u-empty-d {
		font-size: 26rpx;
		color: var(--c-faint);
		margin-top: 10rpx;
		display: block;
	}
</style>
