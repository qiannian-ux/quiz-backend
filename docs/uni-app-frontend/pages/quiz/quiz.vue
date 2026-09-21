<template>
  <view class="page">
    <!-- 顶部进度区 -->
    <view class="header">
      <view class="progress-track">
        <view class="progress-fill" :style="{ width: progress + '%' }"></view>
      </view>
      <view class="header-row">
        <text class="step">第 {{ currentIndex + 1 }} / {{ total }} 题</text>
        <text class="platform">{{ platformText }}</text>
      </view>
    </view>

    <!-- 加载态 -->
    <view v-if="loading" class="center">
      <view class="loading-dot"></view>
      <text class="loading-text">正在出题…</text>
    </view>

    <!-- 出错 / 无题（理论上不会，本地题库会兜底）——错误态必须给可点的重试 -->
    <view v-else-if="!currentQuestion" class="u-empty">
      <view class="u-empty-icon"><text class="u-empty-ico">📡</text></view>
      <text class="u-empty-t">题目加载失败</text>
      <text class="u-empty-d">检查一下网络，或者再来一次</text>
      <view class="u-btn u-btn--secondary u-btn--sm retry-btn" hover-class="u-btn--hover" @click="loadQuestions">
        <text class="u-btn-t">重新加载</text>
      </view>
    </view>

    <!-- 答题主体：三种题面形态由数据决定（见 composables/useQuiz.js 的 inputModeOf） -->
    <view v-else class="body" :key="currentIndex">
      <view class="u-card question-card">
        <text class="q-index">Q{{ currentIndex + 1 }}</text>
        <text class="question-title">{{ currentQuestion.title }}</text>
      </view>

      <!-- ① 双极 5 档：左锚=options[0]，右锚=options[1]，1=更偏左，5=更偏右（MBTI） -->
      <view v-if="mode === 'bipolar'" class="u-card scale">
        <view class="scale-anchors">
          <text class="scale-anchor scale-anchor--left">{{ currentQuestion.options[0].text }}</text>
          <text class="scale-anchor scale-anchor--right">{{ currentQuestion.options[1].text }}</text>
        </view>
        <view class="scale-track">
          <view
            v-for="v in 5"
            :key="v"
            class="scale-dot"
            :class="{ 'scale-dot--active': selectedValue === v }"
            hover-class="scale-dot--hover"
            @click="selectScale(v)"
          >
            <text class="scale-dot-num">{{ v }}</text>
          </view>
        </view>
        <view class="scale-hint">1 = 更偏向左侧 · 5 = 更偏向右侧</view>
      </view>

      <!-- ② 同意度量表：选项全部指向同一维度，只是分值 1~5（九型 / 霍兰德 / 依恋） -->
      <view v-else-if="mode === 'likert'" class="u-card scale">
        <view class="scale-anchors">
          <text class="scale-anchor scale-anchor--left">{{ likertLeft }}</text>
          <text class="scale-anchor scale-anchor--right">{{ likertRight }}</text>
        </view>
        <view class="scale-track">
          <view
            v-for="v in likertMax"
            :key="v"
            class="scale-dot scale-dot--sm"
            :class="{ 'scale-dot--active': selectedValue === v }"
            hover-class="scale-dot--hover"
            @click="selectScale(v)"
          >
            <text class="scale-dot-num">{{ v }}</text>
          </view>
        </view>
        <view class="scale-hint">{{ likertLeft }} ← → {{ likertRight }}</view>
      </view>

      <!-- ③ 竖排单选：多个选项指向不同维度（DISC 四选一 等） -->
      <view v-else class="opts">
        <view
          v-for="(o, i) in currentQuestion.options"
          :key="i"
          class="u-card opt"
          :class="{ 'opt--on': selectedIndex === i }"
          hover-class="opt--hover"
          @click="select(i)"
        >
          <view class="opt-dot" :class="{ 'opt-dot--on': selectedIndex === i }">
            <text v-if="selectedIndex === i" class="opt-dot-t">✓</text>
          </view>
          <text class="opt-text">{{ o.text }}</text>
        </view>
      </view>
    </view>

    <!-- 底部按钮 -->
    <view v-if="!loading && currentQuestion" class="footer">
      <view
        class="u-btn u-btn--primary u-btn--block"
        :class="{ 'u-btn--disabled': !hasChoice() }"
        hover-class="u-btn--hover"
        @click="onNext"
      >
        <text class="u-btn-t">{{ isLast ? '看看结果' : '下一题' }}</text>
      </view>
    </view>
  </view>
</template>

<script setup>
/**
 * 答题页
 * ------------------------------------------------------------
 * 这一页只负责渲染和把点击交给 useQuiz，
 * "第几题 / 答了什么 / 要不要结束"这些状态全在 composables/useQuiz.js 里。
 *
 * 重构点（动态测评）：code 来自首页列表 / URL 参数，onLoad 时传入 useQuiz(code)，
 * 不再写死 mbti。答完把会话写入 quizSession（替代旧的 storage 拼大对象）。
 */
import { computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { useQuiz } from '@/composables/useQuiz.js'
import { quizSession } from '@/stores/quizSession.js'
import { PLATFORM_TEXT, QUESTION_COUNT } from '@/config/env.js'

// #ifdef MP-WEIXIN
import { showInterstitial, canShowInterstitial } from '@/utils/ads.js'
// #endif

const platformText = PLATFORM_TEXT

// 从 URL 参数拿测评 identity（首页卡片跳转时带入）
const meta = { code: 'mbti', name: 'MBTI 性格', emoji: '🧠' }

const {
  currentIndex,
  currentQuestion,
  total,
  isLast,
  progress,
  selectedValue,
  selectedIndex,
  answers,
  finished,
  loading,
  code,
  loadQuestions,
  submitQuiz,
  selectScale,
  select,
  hasChoice,
  next
} = useQuiz(meta.code, QUESTION_COUNT)

/**
 * 当前题的输入形态。题面长什么样由数据决定，不写死：
 *   bipolar 双极 5 档 / likert 同意度 5 档 / single 竖排单选
 */
const mode = computed(() => (currentQuestion.value && currentQuestion.value.mode) || 'single')

/** 量表题的两端锚点文案（第一个选项 / 最后一个选项） */
const likertMax = computed(() => {
  const q = currentQuestion.value
  return q ? Math.min(5, (q.options || []).length) : 5
})
const likertLeft = computed(() => {
  const q = currentQuestion.value
  return q && q.options && q.options[0] ? q.options[0].text : '不同意'
})
const likertRight = computed(() => {
  const q = currentQuestion.value
  if (!q || !q.options || !q.options.length) return '同意'
  return q.options[q.options.length - 1].text
})

function onNext() {
  if (!hasChoice()) {
    uni.showToast({ title: mode.value === 'single' ? '先选一个答案' : '先选一档吧', icon: 'none' })
    return
  }
  // next() 内部会推进题号，或在最后一题时把 finished 置为 true
  const ok = next()
  if (ok && finished.value) {
    // 把本次会话写入单例（替代旧的 uni.setStorageSync('quiz_answers') 拼大对象）
    quizSession.set(meta.code, meta.name, meta.emoji, answers.value)
    // 答题完成跳结果前弹插屏（微信服务端限频；客户端再加 5 分钟冷却）
    // #ifdef MP-WEIXIN
    if (canShowInterstitial()) {
      showInterstitial().finally(() => toResult())
    } else {
      toResult()
    }
    // #endif
    // #ifndef MP-WEIXIN
    toResult()
    // #endif
  }
}

function toResult() {
  uni.redirectTo({ url: `/pages/result/result?code=${meta.code}` })
}

onLoad((options) => {
  if (options && options.code) {
    meta.code = options.code
    meta.name = decodeURIComponent(options.name || meta.name)
    meta.emoji = decodeURIComponent(options.emoji || meta.emoji)
    code.value = options.code
  }
  loadQuestions()
})
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 40rpx 40rpx 200rpx;
  box-sizing: border-box;
  background: var(--c-bg);
}

/* ---------- 进度 ---------- */
.header {
  padding-top: 20rpx;
}

.progress-track {
  height: 12rpx;
  border-radius: var(--r-full);
  background: var(--c-surface-3);
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  border-radius: var(--r-full);
  background: var(--c-primary);
  transition: width 0.35s var(--ease-out);
}

.header-row {
  margin-top: 18rpx;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
}

.step {
  font-size: 26rpx;
  color: var(--c-text-2);
  font-weight: 500;
}

.platform {
  font-size: 22rpx;
  color: var(--c-faint);
}

/* ---------- 加载 / 空态 ---------- */
.center {
  margin-top: 300rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
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
  0%,
  100% {
    transform: scale(0.85);
    opacity: 0.6;
  }
  50% {
    transform: scale(1.15);
    opacity: 1;
  }
}

.loading-text {
  font-size: 28rpx;
  color: var(--c-faint);
}

/* 按钮本体由全局 .u-btn 提供，这里只处理间距与自适应宽度 */
.retry-btn {
  margin-top: var(--sp-lg);
  display: inline-flex;
  width: auto;
}

/* ---------- 题目 ---------- */
.body {
  margin-top: 60rpx;
  animation: slideIn 0.35s cubic-bezier(0.22, 1, 0.36, 1);
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(40rpx);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.question-card {
  padding: 44rpx 40rpx 48rpx;
  margin-bottom: 40rpx;
  position: relative;
}

.q-index {
  display: inline-block;
  font-size: 22rpx;
  font-weight: 600;
  color: var(--c-primary);
  background: var(--c-primary-soft);
  padding: 6rpx 18rpx;
  border-radius: var(--r-full);
  margin-bottom: 22rpx;
}

.question-title {
  font-size: 40rpx;
  font-weight: 600;
  color: var(--c-text);
  line-height: 1.55;
}

/* ---------- 双极 5 档量表 ---------- */
.scale {
  margin-top: 8rpx;
  padding: 36rpx 32rpx 40rpx;
}

.scale-anchors {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 28rpx;
}

.scale-anchor {
  flex: 1;
  font-size: 28rpx;
  font-weight: 500;
  color: var(--c-text);
  line-height: 1.45;
}

.scale-anchor--left {
  text-align: left;
  padding-right: 20rpx;
}

.scale-anchor--right {
  text-align: right;
  padding-left: 20rpx;
}

.scale-track {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  margin: 8rpx 4rpx 20rpx;
}

.scale-dot {
  width: 92rpx;
  height: 92rpx;
  border-radius: 50%;
  background: var(--c-surface-3);
  border: 3rpx solid transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all var(--dur-fast) var(--ease-out);
}

.scale-dot--hover {
  transform: scale(0.94);
}

.scale-dot--active {
  background: var(--c-primary);
  border-color: rgba(255, 255, 255, 0.7);
  box-shadow: 0 12rpx 28rpx rgba(124, 107, 245, 0.32);
  transform: scale(1.1);
}

.scale-dot-num {
  font-size: 30rpx;
  font-weight: 500;
  color: var(--c-text-2);
}

.scale-dot--active .scale-dot-num {
  color: #ffffff;
}

.scale-hint {
  text-align: center;
  font-size: 22rpx;
  color: var(--c-faint);
  letter-spacing: 1rpx;
}

/* ---------- 竖排单选（多选项 / 不同维度） ---------- */
.opts { margin-top: 8rpx; }
.opt {
  padding: 30rpx 28rpx;
  margin-bottom: var(--sp-sm);
  display: flex;
  flex-direction: row;
  align-items: center;
  border: 3rpx solid transparent;
  transition: all var(--dur-fast) var(--ease-out);
}
.opt--hover { background: var(--c-surface-2); }
.opt--on { border-color: var(--c-primary); background: var(--c-primary-soft); }
.opt-dot {
  flex: none;
  width: 44rpx; height: 44rpx; border-radius: 50%;
  margin-right: 22rpx;
  background: var(--c-surface-3);
  border: 2rpx solid transparent;
  display: flex; align-items: center; justify-content: center;
}
.opt-dot--on { background: var(--c-primary); border-color: rgba(255, 255, 255, 0.7); }
.opt-dot-t { font-size: 26rpx; color: #fff; font-weight: 700; }
.opt-text { flex: 1; font-size: 29rpx; line-height: 1.6; color: var(--c-text-2); }
.opt--on .opt-text { color: var(--c-text); font-weight: 500; }

/* 量表题档位更密（最多 5 档），比双极的 92rpx 小一点 */
.scale-dot--sm { width: 84rpx; height: 84rpx; }

/* ---------- 底部 ----------
 * 吸底操作区：底部留白已含 iPhone Home 指示条的安全区。
 * 按钮本体由全局 .u-btn 提供。
 */
.footer {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  padding: var(--sp-lg) var(--sp-xl) 56rpx;
  background: linear-gradient(to top, rgba(251, 249, 255, 0.98), rgba(251, 249, 255, 0));
  display: flex;
  justify-content: center;
}
</style>
