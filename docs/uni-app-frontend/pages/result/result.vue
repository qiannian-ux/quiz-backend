<template>
  <view class="page">
    <!-- 解析生成中：云端算分 + 取双档解析，通常 1 秒内 -->
    <view v-if="pending" class="u-empty">
      <view class="loading-dot"></view>
      <text class="u-empty-t">正在生成你的解析…</text>
      <text class="u-empty-d">云端算分中，稍等一下</text>
    </view>

    <!-- 拿不到解析（没作答 / 非 MBTI 且云端不可达） -->
    <view v-else-if="!report" class="u-empty">
      <view class="u-empty-icon"><text class="u-empty-ico">🎴</text></view>
      <text class="u-empty-t">{{ errMsg || '还没有测试结果' }}</text>
      <text class="u-empty-d">完成一次测评，就能领到你的专属角色卡</text>
      <view class="u-btn u-btn--primary empty-btn" hover-class="u-btn--hover" @click="goHome">
        <text class="u-btn-t">去测一测</text>
      </view>
      <view v-if="canRetry" class="u-btn u-btn--secondary empty-btn" hover-class="u-btn--hover" @click="load">
        <text class="u-btn-t">重新获取解析</text>
      </view>
    </view>

    <view v-else class="body">
      <!-- 来源徽标：解析是云端下发的，断网才走本地降级版 -->
      <view class="src" :class="{ 'src--local': report.source === 'local' }">
        <text class="src-t">{{ report.source === 'cloud' ? '✓ 解析已联网获取' : '⚠ 本地兜底（降级版）' }}</text>
      </view>

      <!-- 角色卡：翻牌抽卡 -->
      <view class="draw-stage">
        <view class="flip-card" :class="{ flipped }" @click="flip">
          <view class="flip-inner">
            <view class="face back">
              <view class="shine"></view>
              <view class="seal">🎴</view>
              <text class="bt">探我趣测</text>
              <text class="bs">轻触卡面 · 揭晓你的角色</text>
            </view>
            <view class="face front">
              <view class="fr-deco"></view>
              <view class="fr-top">
                <text class="fr-code">{{ report.code }}</text>
                <text class="fr-rk">{{ report.subtitle }}</text>
              </view>
              <!-- 角色位：登记了 IP 图就用图，没有就退回 emoji 兜底 -->
              <view class="fr-art">
                <image v-if="artUrl" class="fr-art-img" :src="artUrl" mode="aspectFit" />
                <text v-else class="fr-emoji">{{ report.emoji }}</text>
              </view>
              <text class="fr-name">{{ report.name }}</text>
              <text class="fr-sub">{{ report.summary }}</text>
              <view class="fr-tags">
                <text v-for="(w, i) in traitTags" :key="i" class="ft">{{ w }}</text>
              </view>
            </view>
          </view>
        </view>
      </view>
      <text class="draw-tip" v-if="!flipped">👆 轻触卡面翻牌</text>

      <!-- 详情（翻牌后淡入） -->
      <view class="detail" :class="{ show: flipped }">
        <!-- 初级解析 -->
        <view class="u-card desc-card">
          <text class="sec-t">一句话看懂你</text>
          <text class="desc-text">{{ report.basic.one_liner || report.summary }}</text>
          <view v-if="report.basic.traits.length" class="chips">
            <text v-for="(t, i) in report.basic.traits" :key="'t' + i" class="chip chip--trait">{{ t }}</text>
          </view>
        </view>

        <view v-if="report.basic.strengths.length || report.basic.weaknesses.length" class="u-card sw-card">
          <view v-if="report.basic.strengths.length" class="sw-col">
            <text class="sw-t sw-t--up">你的优势</text>
            <text v-for="(s, i) in report.basic.strengths" :key="'s' + i" class="sw-i">· {{ s }}</text>
          </view>
          <view v-if="report.basic.weaknesses.length" class="sw-col">
            <text class="sw-t sw-t--down">容易踩的坑</text>
            <text v-for="(w, i) in report.basic.weaknesses" :key="'w' + i" class="sw-i">· {{ w }}</text>
          </view>
        </view>

        <!-- 维度占比（仅 PAIR 模型，如 MBTI） -->
        <view v-if="report.hasBars" class="u-card bars-card">
          <text class="bars-title">你的维度构成</text>
          <view v-for="bar in bars" :key="bar.key" class="bar-row">
            <text class="bar-label">{{ bar.label }}</text>
            <view class="bar-track">
              <view
                class="bar-fill"
                :class="{ 'bar-fill--main': bar.main }"
                :style="{ width: ready ? bar.percent + '%' : '0%', background: bar.color }"
              ></view>
            </view>
            <text class="bar-value">{{ bar.percent }}%</text>
          </view>
        </view>

        <view v-if="report.basic.tip" class="u-card tip-card">
          <text class="tip-title">想说一句</text>
          <text class="tip-text">{{ report.basic.tip }}</text>
        </view>

        <!-- 深度报告：免费全给，不设广告 / 付费墙 -->
        <view v-if="report.advanced.chapters.length" class="u-card deep-card">
          <text class="deep-title">深度报告</text>
          <view v-for="(c, i) in report.advanced.chapters" :key="'c' + i" class="chapter">
            <text class="ch-t">{{ c.title }}</text>
            <text class="ch-c">{{ c.content }}</text>
          </view>
          <view v-if="report.advanced.career.length" class="career">
            <text class="career-t">适合的方向</text>
            <view class="chips">
              <text v-for="(c, i) in report.advanced.career" :key="'ca' + i" class="chip chip--career">{{ c }}</text>
            </view>
          </view>
          <text v-if="report.advanced.famous" class="famous">典型形象：{{ report.advanced.famous }}</text>
        </view>

        <!-- 打赏（仅微信）：自愿，不是解锁入口 -->
        <!-- #ifdef MP-WEIXIN -->
        <view class="u-card reward-card">
          <text class="reward-title">觉得测得还准？</text>
          <text class="reward-text">报告已经全给你了。想鼓励一下作者，可以请杯奶茶</text>
          <view class="u-btn u-btn--primary u-btn--block reward-btn" hover-class="u-btn--hover" @click="rewardAuthor">
            <text class="u-btn-t">请作者喝奶茶</text>
          </view>
          <text class="reward-note">个人主体「道具直购」，仅跑通支付流程</text>
        </view>
        <!-- #endif -->

        <!-- 操作 -->
        <view class="actions">
          <view class="u-btn u-btn--primary u-btn--block" hover-class="u-btn--hover" @click="collectCard">
            <text class="u-btn-t">收入卡册</text>
          </view>
          <view class="u-btn u-btn--secondary u-btn--block act-sep" hover-class="u-btn--hover" @click="restart">
            <text class="u-btn-t">再测一次</text>
          </view>
          <view class="u-btn u-btn--ghost u-btn--block act-sep" hover-class="u-btn--hover" @click="goHome">
            <text class="u-btn-t">回到首页</text>
          </view>
        </view>

        <text class="privacy">解析来自云端，作答仅用于本次算分</text>
      </view>
    </view>
  </view>
</template>

<script setup>
/**
 * 结果页（卡牌化 + 云端双档解析）
 * ------------------------------------------------------------
 * 2026-09-20 改造（对齐后端「双档解析云端下发」）：
 *   1. 解析唯一入口是 useQuiz().fetchReport()：先 POST /api/quiz/submit 拿云端
 *      basicReport / advancedReport，失败才退回本地 MBTI 兜底。
 *      页面渲染的是归一化后的 report（见 utils/report.js），不关心来源。
 *   2. 两档解析**全部免费**，移除原来的「看广告解锁深度解读」付费墙——
 *      用户已明确：不做付费墙，只保留自愿打赏按钮。
 *   3. code 来自 URL / quizSession，非 MBTI 测评也能正常渲染（云端的名字/文案）。
 *   4. 保留：翻牌抽卡、卡通 IP 图、收入卡册、自动记历史、分享、打赏。
 */
import { ref, computed, onMounted } from 'vue'
import { onLoad, onShareAppMessage, onUnload } from '@dcloudio/uni-app'
import { useQuiz } from '@/composables/useQuiz.js'
import { DIMENSIONS, DIMENSION_KEYS } from '@/utils/scoring.js'
import { quizSession } from '@/stores/quizSession.js'
import { typeArt } from '@/config/typeArt.js'

// #ifdef MP-WEIXIN
import { showBanner, hideBanner } from '@/utils/ads.js'
import { buyProduct, checkIosVersion } from '@/utils/payment.js'
// #endif

const report = ref(null)
const ready = ref(false)
const flipped = ref(false)
const pending = ref(true)
const errMsg = ref('')
const canRetry = ref(false)

/**
 * 当前测评 code：URL 参数优先，其次会话单例，最后才是 mbti 兜底。
 * ------------------------------------------------------------
 * 为什么不能直接读 quizSession.quizCode：
 *   页面冷启动（从历史页/分享进来、或小程序被回收后重进）时单例是空的，
 *   只认单例会把 DISC 的结果当 MBTI 去取解析。URL 上本来就带了 code，
 *   它是唯一"跟着这次跳转走"的可靠来源。
 */
const urlCode = ref('')
const activeCode = computed(() => urlCode.value || quizSession.quizCode || 'mbti')

onLoad((options) => {
  if (options && options.code) urlCode.value = options.code
})

/** 该类型的卡通角色图；没登记返回空串，模板自动退回 emoji 兜底 */
const artUrl = computed(() => (report.value ? typeArt(report.value.code) : ''))

/** 卡面上的关键词：取初级解析前 4 条特质 */
const traitTags = computed(() => {
  const r = report.value
  if (!r) return []
  return (r.basic.traits || []).slice(0, 4)
})

/** 维度占比条（仅 PAIR 模型；winner 恰好 4 组时才有） */
const bars = computed(() => {
  const r = report.value
  if (!r || !r.hasBars) return []
  return DIMENSION_KEYS.map((k) => {
    const d = DIMENSIONS[k]
    const win = r.winner[k]
    const isLeft = win === d.left
    return {
      key: k,
      label: isLeft ? d.leftName + ' ' + d.left : d.rightName + ' ' + d.right,
      color: d.color,
      main: true,
      percent: isLeft ? (r.percent[k] || 50) : 100 - (r.percent[k] || 50)
    }
  })
})

const answers = computed(() => {
  // 优先用会话单例（答题页写入），其次兼容旧 storage
  if (quizSession.answers && quizSession.answers.length) return quizSession.answers
  return uni.getStorageSync('quiz_answers') || []
})

async function load() {
  pending.value = true
  errMsg.value = ''
  try {
    if (!answers.value.length) {
      report.value = null
      errMsg.value = '还没有测试结果'
      canRetry.value = false
      return
    }
    // 结果页是独立页面实例：把会话里的作答显式传进去
    const { fetchReport } = useQuiz(activeCode.value)
    const { report: r, source, message } = await fetchReport(answers.value)
    if (!r) {
      report.value = null
      errMsg.value = message || '解析获取失败'
      canRetry.value = true
      return
    }
    report.value = r
    quizSession.setResult(r)
    // 来源统一写回，便于后续排查（本地兜底 vs 云端）
    report.value.source = source
    recordHistory()
    setTimeout(() => { ready.value = true }, 120)
    // #ifdef MP-WEIXIN
    showBanner()
    // #endif
  } finally {
    pending.value = false
  }
}

onMounted(load)

// 是否已在本次会话写过历史（重试可能重入，防止重复记一条）
let recorded = false

/**
 * 每测一次就记一条历史，不再依赖用户点「收入卡册」。
 * 历史记录的是"我测过"，卡册记录的才是"我收藏了"。
 */
function recordHistory() {
  if (recorded || !report.value) return
  recorded = true
  const item = {
    quizCode: activeCode.value,
    quizName: quizSession.quizName || report.value.name,
    type: report.value.code,
    name: report.value.name,
    emoji: report.value.emoji,
    date: Date.now()
  }
  const history = uni.getStorageSync('quiz_history') || []
  history.unshift(item)
  uni.setStorageSync('quiz_history', history.slice(0, 100))
}

onUnload(() => {
  // #ifdef MP-WEIXIN
  hideBanner()
  // #endif
})

function flip() {
  if (flipped.value) return
  flipped.value = true
}

/** 收入卡册：只写 album（history 已在 recordHistory 里自动记过），按 code 去重 */
function collectCard() {
  if (!report.value) return
  const card = {
    quizCode: activeCode.value,
    type: report.value.code,
    name: report.value.name,
    emoji: report.value.emoji,
    date: Date.now()
  }
  const album = uni.getStorageSync('quiz_album') || []
  if (!album.find((c) => c.quizCode === card.quizCode && c.type === card.type)) {
    album.unshift(card)
    uni.setStorageSync('quiz_album', album)
    uni.showToast({ title: '已收入卡册 ✦', icon: 'none' })
  } else {
    uni.showToast({ title: '这张卡已经在册子里啦', icon: 'none' })
  }
}

// 打赏：自愿，与解锁无关
async function rewardAuthor() {
  // #ifdef MP-WEIXIN
  if (!checkIosVersion()) return
  try {
    const ok = await buyProduct('tip_milktea')
    if (ok) uni.showToast({ title: '谢谢你的奶茶', icon: 'none' })
  } catch (e) {
    console.warn('[reward]', e)
  }
  // #endif
}

/**
 * 再测一次：先把 code / 名字取出来再清会话。
 * ------------------------------------------------------------
 * 坑（2026-09-20 修）：原来先 clear() 再读 quizSession.quizCode，
 * 清完必然是空串，于是"再测一次"永远跳回 MBTI —— 测 DISC 点一下就变 MBTI。
 */
function restart() {
  const c = activeCode.value
  const n = quizSession.quizName || report.value?.name || ''
  const e = quizSession.emoji || report.value?.emoji || ''
  quizSession.clear()
  uni.removeStorageSync('quiz_answers')
  uni.redirectTo({
    url: `/pages/quiz/quiz?code=${c}&name=${encodeURIComponent(n)}&emoji=${encodeURIComponent(e)}`
  })
}

function goHome() {
  quizSession.clear()
  uni.removeStorageSync('quiz_answers')
  uni.switchTab({ url: '/pages/index/index' })
}

// #ifdef MP-WEIXIN
onShareAppMessage(() => ({
  title: report.value ? `我是「${report.value.name}」，你呢？` : '测一测你的隐藏属性',
  path: '/pages/index/index'
}))
// #endif
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 40rpx 40rpx 80rpx;
  box-sizing: border-box;
  background: var(--c-bg);
}
/* 空态结构与图标由全局 .u-empty 提供，这里只处理按钮：自适应宽度并居中 */
.empty-btn {
  margin-top: var(--sp-lg);
  display: inline-flex;
  width: auto;
  padding: 0 44rpx;
}
.loading-dot {
  width: 48rpx;
  height: 48rpx;
  border-radius: 50%;
  background: var(--c-primary);
  animation: pulse 1.1s ease-in-out infinite;
  margin-bottom: 24rpx;
}
@keyframes pulse {
  0%, 100% { transform: scale(0.85); opacity: 0.6; }
  50% { transform: scale(1.15); opacity: 1; }
}

.body { animation: riseIn 0.5s cubic-bezier(0.22, 1, 0.36, 1); }
@keyframes riseIn { from { opacity: 0; transform: translateY(40rpx); } to { opacity: 1; transform: translateY(0); } }

/* ---------- 来源徽标 ---------- */
.src { display: flex; justify-content: center; margin-bottom: 12rpx; }
.src-t {
  font-size: 21rpx; color: var(--c-primary);
  background: var(--c-primary-soft);
  padding: 8rpx 22rpx; border-radius: var(--r-full);
}
.src--local .src-t { color: #a06a00; background: rgba(255, 183, 77, 0.18); }

/* ---------- 翻牌卡 ---------- */
.draw-stage { perspective: 1200rpx; display: flex; justify-content: center; margin: 8rpx 0 4rpx; }
.flip-card { width: 440rpx; height: 600rpx; }
.flip-inner { position: relative; width: 100%; height: 100%; transition: transform 0.7s cubic-bezier(0.22, 1, 0.36, 1); transform-style: preserve-3d; }
.flip-card.flipped .flip-inner { transform: rotateY(180deg); }
/* 抽卡是整个 app 的情绪高点，这里允许大面积铺色（品牌紫侧渐变） */
.face { position: absolute; top: 0; right: 0; bottom: 0; left: 0; backface-visibility: hidden; border-radius: var(--r-xl); overflow: hidden; box-shadow: var(--sh-3); display: flex; flex-direction: column; }
.face.back { background: linear-gradient(150deg, #007aff, #5ac8fa); align-items: center; justify-content: center; color: #fff; text-align: center; padding: 40rpx; }
.face.back .seal { width: 160rpx; height: 160rpx; border-radius: 50%; border: 6rpx solid rgba(255, 255, 255, 0.7); display: flex; align-items: center; justify-content: center; font-size: 80rpx; margin-bottom: 28rpx; }
.face.back .bt { font-size: 36rpx; font-weight: 600; letter-spacing: 4rpx; }
.face.back .bs { font-size: 24rpx; opacity: 0.9; margin-top: 16rpx; }
.face.back .shine { position: absolute; top: -40%; left: -30%; width: 60%; height: 180%; background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.35), transparent); transform: rotate(20deg); animation: shine 3s infinite; }
@keyframes shine { 0% { left: -40%; } 60%, 100% { left: 130%; } }
.face.front { transform: rotateY(180deg); background: var(--c-surface); padding: 32rpx 28rpx; align-items: stretch; }
.face.front .fr-top { display: flex; justify-content: space-between; align-items: center; }
.face.front .fr-code { font-size: 40rpx; font-weight: 600; color: var(--c-text); }
.face.front .fr-rk { font-size: 20rpx; font-weight: 500; padding: 6rpx 18rpx; border-radius: var(--r-full); background: var(--c-surface-2); color: var(--c-sub); max-width: 220rpx; }
.face.front .fr-art { display: flex; align-items: center; justify-content: center; margin: 12rpx 0 6rpx; height: 160rpx; }
.face.front .fr-art-img { width: 160rpx; height: 160rpx; }
.face.front .fr-emoji { font-size: 130rpx; text-align: center; margin: 12rpx 0 6rpx; }
.face.front .fr-name { text-align: center; font-size: 36rpx; font-weight: 600; color: var(--c-text); }
.face.front .fr-sub { text-align: center; font-size: 23rpx; color: var(--c-faint); margin-top: 8rpx; line-height: 1.6; }
.face.front .fr-tags { display: flex; flex-wrap: wrap; gap: 12rpx; justify-content: center; margin-top: 20rpx; }
.face.front .ft { font-size: 22rpx; background: var(--c-surface-2); color: var(--c-sub); padding: 6rpx 18rpx; border-radius: var(--r-full); }
.face.front .fr-deco { position: absolute; bottom: 0; left: 0; right: 0; height: 110rpx; background: linear-gradient(135deg, rgba(0, 122, 255, 0.08), rgba(90, 200, 250, 0.08)); }
.draw-tip { text-align: center; font-size: 24rpx; color: var(--c-faint); margin: 12rpx 0 4rpx; }

/* ---------- 详情淡入 ---------- */
.detail { opacity: 0; transform: translateY(20rpx); transition: all 0.4s ease; margin-top: 8rpx; }
.detail.show { opacity: 1; transform: none; }

/* ---------- 通用小标题 / chips ---------- */
.sec-t { font-size: 27rpx; font-weight: 600; color: var(--c-text); display: block; margin-bottom: 16rpx; }
.chips { display: flex; flex-wrap: wrap; gap: 12rpx; margin-top: 20rpx; }
.chip { font-size: 22rpx; padding: 8rpx 20rpx; border-radius: var(--r-full); background: var(--c-surface-2); color: var(--c-sub); }
.chip--trait { background: var(--c-primary-soft); color: var(--c-primary); }
.chip--career { background: rgba(52, 199, 89, 0.14); color: #2a9d4a; }

/* ---------- 初级解析 ---------- */
.desc-card { margin-top: var(--sp-md); padding: 36rpx 34rpx; }
.desc-text { font-size: 29rpx; color: var(--c-text-2); line-height: 1.85; }

.sw-card { margin-top: var(--sp-md); padding: 34rpx; display: flex; flex-direction: row; gap: 24rpx; }
.sw-col { flex: 1; }
.sw-t { font-size: 24rpx; font-weight: 600; display: block; margin-bottom: 12rpx; }
.sw-t--up { color: #2a9d4a; }
.sw-t--down { color: #d1731f; }
.sw-i { font-size: 25rpx; color: var(--c-text-2); line-height: 1.9; display: block; }

/* ---------- 占比条 ---------- */
.bars-card { margin-top: var(--sp-md); padding: 40rpx 36rpx; }
.bars-title { font-size: 27rpx; color: var(--c-text); font-weight: 600; margin-bottom: var(--sp-lg); display: block; }
.bar-row { display: flex; flex-direction: row; align-items: center; margin-bottom: 26rpx; }
.bar-label { width: 170rpx; font-size: 24rpx; color: var(--c-text-2); }
.bar-track { flex: 1; height: 22rpx; border-radius: 11rpx; background: var(--c-surface-3); overflow: hidden; }
.bar-fill { height: 100%; border-radius: 11rpx; opacity: 0.38; transition: width 0.9s var(--ease-out); }
.bar-fill--main { opacity: 1; box-shadow: 0 4rpx 12rpx rgba(150, 160, 210, 0.24); }
.bar-value { width: 80rpx; text-align: right; font-size: 23rpx; color: var(--c-faint); }

/* ---------- 小贴士 ---------- */
.tip-card { margin-top: var(--sp-md); padding: 36rpx; border-left: 10rpx solid var(--c-sp); }
.tip-title { font-size: 24rpx; color: var(--c-sp); font-weight: 600; margin-bottom: 14rpx; display: block; }
.tip-text { font-size: 27rpx; color: var(--c-text-2); line-height: 1.8; }

/* ---------- 深度报告（免费全量） ---------- */
.deep-card {
  margin-top: var(--sp-md); padding: 36rpx 34rpx;
  border-radius: var(--r-card);
  background: var(--c-primary-soft);
  border: 1rpx solid rgba(0, 122, 255, 0.2);
}
.deep-title { font-size: 27rpx; color: var(--c-primary); font-weight: 600; margin-bottom: 20rpx; display: block; }
.chapter { margin-bottom: 26rpx; }
.ch-t { font-size: 26rpx; font-weight: 600; color: var(--c-text); display: block; margin-bottom: 10rpx; }
.ch-c { font-size: 27rpx; color: var(--c-text-2); line-height: 1.85; }
.career { margin-top: 8rpx; }
.career-t { font-size: 24rpx; color: var(--c-sub); font-weight: 600; display: block; }
.famous { font-size: 24rpx; color: var(--c-faint); margin-top: 20rpx; display: block; }

/* ---------- 打赏 ---------- */
.reward-card { margin-top: var(--sp-md); padding: 40rpx 36rpx; display: flex; flex-direction: column; align-items: center; }
.reward-title { font-size: 28rpx; color: var(--c-text); font-weight: 600; }
.reward-text { margin-top: 14rpx; font-size: 25rpx; color: var(--c-sub); line-height: 1.7; text-align: center; }
.reward-btn { margin-top: var(--sp-md); }
.reward-note { display: block; margin-top: var(--sp-sm); font-size: 21rpx; color: var(--c-faint); text-align: center; }

/* ---------- 操作 ---------- */
.actions { margin-top: var(--sp-lg); }
.act-sep { margin-top: var(--sp-sm); }
.privacy { display: block; margin-top: var(--sp-lg); text-align: center; font-size: 22rpx; color: var(--c-faint); }
</style>
