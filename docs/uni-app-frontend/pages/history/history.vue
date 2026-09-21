<template>
  <view class="page">
    <view class="hero">
      <view class="hero-l">
        <text class="h">我的记录</text>
        <text class="p">每一次探索，都值得被记住</text>
      </view>
      <view class="hero-r">
        <text class="hr-n">{{ records.length }}</text>
        <text class="hr-t">次测评</text>
      </view>
    </view>

    <!-- 空态：图形 + 说明 + 一个明确出口，缺一不可 -->
    <view v-if="records.length === 0" class="u-empty">
      <view class="u-empty-icon"><text class="u-empty-ico">📭</text></view>
      <text class="u-empty-t">还没有测过哦</text>
      <text class="u-empty-d">去首页挑一个，两分钟就能出结果</text>
      <view class="u-btn u-btn--primary u-btn--sm empty-btn" hover-class="u-btn--hover" @click="goHome">
        <text class="u-btn-t">去首页看看</text>
      </view>
    </view>

    <view v-else>
      <view
        v-for="(r, i) in records"
        :key="i"
        class="item u-card"
        hover-class="item--hover"
        @click="again(r)"
      >
        <view class="badge" :style="{ background: badgeBg(r.type) }">
          <text class="bt">{{ r.type || '?' }}</text>
        </view>
        <view class="main">
          <text class="name">{{ r.name || r.type || '测评' }}</text>
          <text class="meta">{{ r.quizName || 'MBTI 性格' }} · {{ timeText(r.date) }}</text>
        </view>
        <view class="again"><text class="ag">再看</text></view>
      </view>
    </view>

    <text v-if="records.length" class="foot">只保留最近 {{ records.length }} 条（上限 100）</text>
  </view>
</template>

<script setup>
/**
 * 我的记录
 * ------------------------------------------------------------
 * 本次改造：
 *   1. 时间之前是写死的 '刚刚'（result 页存死字符串），现在改成
 *      从 date 时间戳实时算 —— 刚刚 / 3 小时前 / 2 天前 / 具体日期。
 *   2. 列表项从"灰底圆角条"改成带类型配色的卡片：左侧色块是 16 型各自的
 *      主题色，扫一眼就能分辨类型。
 *   3. 补了顶部总次数和空态按钮（空态之前只有一个表情，没有出口）。
 */
import { ref } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { QUIZ_CODE } from '@/api/quiz.js'
import { PERSONALITY_TYPES } from '@/data/questions.js'
import { timeAgo } from '@/utils/format.js'

const records = ref([])

onShow(() => {
  records.value = uni.getStorageSync('quiz_history') || []
})

function badgeBg(type) {
  const p = PERSONALITY_TYPES[type]
  const c = (p && p.color) || '#8FB8FF'
  return `linear-gradient(140deg, ${hexToRgba(c, 0.98)}, ${hexToRgba(c, 0.72)})`
}

function hexToRgba(hex, a) {
  const h = String(hex || '').replace('#', '')
  if (h.length !== 6) return `rgba(168,200,255,${a})`
  const r = parseInt(h.slice(0, 2), 16)
  const g = parseInt(h.slice(2, 4), 16)
  const b = parseInt(h.slice(4, 6), 16)
  return `rgba(${r},${g},${b},${a})`
}

/** 兼容旧数据：老记录没有 date 字段就退回 '未知时间' */
function timeText(date) {
  return timeAgo(date)
}

function again(r) {
  uni.navigateTo({
    url: `/pages/quiz/quiz?code=${r.quizCode || QUIZ_CODE}&name=${encodeURIComponent(r.quizName || '')}`
  })
}

function goHome() {
  uni.switchTab({ url: '/pages/index/index' })
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 24rpx 32rpx 40rpx;
  box-sizing: border-box;
  background: var(--c-bg);
}

.hero { display: flex; align-items: center; justify-content: space-between; margin: 12rpx 6rpx 28rpx; }
.hero-l { flex: 1; }
.hero-l .h { font-size: 44rpx; font-weight: 800; color: var(--c-text); display: block; }
.hero-l .p { font-size: 25rpx; color: var(--c-sub); margin-top: 10rpx; display: block; }
.hero-r {
  flex: none; min-width: 130rpx; padding: 16rpx 24rpx; border-radius: 24rpx;
  background: rgba(255, 255, 255, 0.72); border: 1rpx solid rgba(255, 255, 255, 0.8);
  box-shadow: 0 10rpx 26rpx rgba(150, 160, 210, 0.14);
  display: flex; flex-direction: column; align-items: center;
}
.hr-n { font-size: 36rpx; font-weight: 800; color: var(--c-text); }
.hr-t { font-size: 20rpx; color: var(--c-faint); margin-top: 2rpx; }

/* ---------- 空态 ----------
 * 容器与图形由全局 .u-empty 提供，这里只留按钮间距。
 */
/* 空态按钮自适应宽度并居中 —— 通栏大按钮在空态里太抢戏 */
.empty-btn {
  margin-top: var(--sp-lg);
  display: inline-flex;
  width: auto;
  padding: 0 44rpx;
}

/* ---------- 列表 ---------- */
.item {
  display: flex; align-items: center; gap: 22rpx;
  padding: 26rpx 26rpx; margin-bottom: 22rpx;
}
.item--hover { background: rgba(255, 255, 255, 1); }

.badge {
  width: 96rpx; height: 96rpx; border-radius: 26rpx; flex: none;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 10rpx 24rpx rgba(150, 160, 210, 0.2);
}
.bt { font-size: 26rpx; font-weight: 800; color: #fff; letter-spacing: 1rpx; }

.main { flex: 1; overflow: hidden; }
.name { font-size: 30rpx; font-weight: 800; color: var(--c-text); display: block; }
.meta { font-size: 23rpx; color: var(--c-sub); margin-top: 8rpx; display: block; }

.again {
  flex: none; padding: 12rpx 26rpx; border-radius: var(--r-full);
  background: var(--c-surface-2);
}
.ag { font-size: 23rpx; font-weight: 500; color: var(--c-sub); }

.foot { display: block; text-align: center; margin-top: var(--sp-sm); font-size: 21rpx; color: var(--c-faint); }
</style>
