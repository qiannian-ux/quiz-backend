<template>
  <view class="page">
    <!-- 问候语按时段变化；右侧显示真实测评数 -->
    <view class="hero">
      <view class="hero-l">
        <text class="h">{{ greet }}</text>
        <text class="p">{{ heroSub }}</text>
      </view>
      <view class="hero-r">
        <text class="hr-n">{{ historyCount }}</text>
        <text class="hr-t">已测</text>
      </view>
    </view>

    <!-- 今日卡：已抽 / 未抽 两种真实状态，不再永远是"去抽卡" -->
    <view class="today" :class="{ 'today--done': todayDraw }" @click="drawToday">
      <view class="td-deco"></view>
      <view class="td-body">
        <view class="td-top">
          <text class="td-lab">今日卡 · 每日一抽</text>
          <text v-if="todayDraw" class="td-done-tag">已抽</text>
        </view>

        <template v-if="todayDraw">
          <view class="td-got">
            <text class="td-emoji">{{ todayDraw.emoji || '🎴' }}</text>
            <view class="td-got-r">
              <text class="td-code">{{ todayDraw.type }}</text>
              <text class="td-name">{{ todayDraw.name }}</text>
            </view>
          </view>
          <text class="td-sub">今天已经抽过了，明天再来会有新的一张</text>
        </template>
        <template v-else>
          <text class="td-title">翻开今天的专属卡</text>
          <text class="td-sub">每天一张，看看今天的你是什么样</text>
          <view class="td-btn"><text class="td-bt">抽今日卡</text></view>
        </template>
      </view>
    </view>

    <view class="u-sec">
      <text class="u-sec-t">热门测评</text>
      <text class="u-sec-s">共 {{ quizzes.length }} 个</text>
    </view>

    <view class="grid">
      <view
        v-for="(q, i) in quizzes"
        :key="q.code"
        class="u-card qcard"
        hover-class="qcard--hover"
        @click="goQuiz(q)"
      >
        <view class="qc-icon" :style="{ background: iconBg(i) }"><text class="qci">{{ q.emoji || '🧩' }}</text></view>
        <text class="qc-name">{{ q.name }}</text>
        <view class="qc-meta">
          <text class="u-chip">{{ q.tag || '性格' }}</text>
          <text class="qc-count">{{ q.questionCount || 24 }} 题 · 约 {{ estMin(q) }} 分钟</text>
        </view>
        <view class="qc-go"><text class="qcg">开始 ›</text></view>
      </view>
    </view>

    <view v-if="loading" class="tip">加载中…</view>
    <text v-else-if="!quizzes.length" class="tip tip--empty">暂无测评</text>
    <view style="height:20rpx"></view>
  </view>
</template>

<script setup>
/**
 * 首页
 * ------------------------------------------------------------
 * 本次改造：
 *   1. 卡片从"白底 + 扁平色块"换成整块渐变卡（按序号轮换配色），
 *      加装饰圆、毛玻璃图标底，层级和质感都上一个台阶。
 *   2. 「今日卡」之前永远是同一个样子（点了也只是跳第一套题），
 *      现在从本地历史里读今天是否已经测过：
 *        - 没测过 -> 展示"抽今日卡" CTA
 *        - 测过了 -> 展示今天真实抽到的类型/名字，状态是算出来的不是写死的
 *   3. 问候语按当前时段变化，右侧「已测 N」取真实历史条数。
 *   4. 去掉点了没反应的「查看全部 ›」，换成真实数量。
 */
import { ref, computed } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { getQuizList, QUIZ_CODE } from '@/api/quiz.js'
import { dayKey } from '@/utils/format.js'

const quizzes = ref([])
const loading = ref(false)
const history = ref([])

// 列表缓存：后端不可达时避免每次切回首页都白打一次网络 / 转 10s 圈。
// listCache 命中即直接用；listFailAt 用于失败退避（60s 内不再打网络，直接兜底）。
let listCache = null
let listFailAt = 0
const LIST_FAIL_COOLDOWN = 60000

/**
 * 家族色只给「图标底」这一小块着色，卡片本身保持中性白。
 * 这是 v2 与 v1 最本质的区别：v1 让每张卡铺满不同渐变，
 * 结果四处高饱和互相抢注意力，扫列表时眼睛没有落点。
 */
/* Apple 系统色：indigo / green / blue / orange / red */
const FAMILY = ['#5e5ce6', '#34c759', '#007aff', '#ff9f0a', '#ff3b30', '#30b0c7']

onShow(() => {
  history.value = uni.getStorageSync('quiz_history') || []
  loadList()
})

const historyCount = computed(() => history.value.length)

/** 今天已经测过吗？直接从历史里按日期比对，不额外存状态 */
const todayDraw = computed(() => {
  const today = dayKey(Date.now())
  return history.value.find((h) => h && h.date && dayKey(h.date) === today) || null
})

/** 问候语按时段走，比一句固定的"你好呀"有生气 */
const greet = computed(() => {
  const h = new Date().getHours()
  if (h < 6) return '夜深了 🌙'
  if (h < 11) return '早上好 ☀️'
  if (h < 14) return '中午好 🍚'
  if (h < 18) return '下午好 🍵'
  return '晚上好 🌛'
})

const heroSub = computed(() => {
  if (!historyCount.value) return '还没测过，挑一个开始吧'
  const last = history.value[0]
  return last && last.name ? `上次测出「${last.name}」` : '今天想多了解自己一点吗？'
})

async function loadList() {
  const now = Date.now()
  // 有缓存 或 处于失败退避期：直接用缓存/兜底，不碰网络
  if (listCache) { quizzes.value = listCache; return }
  if (listFailAt && now - listFailAt < LIST_FAIL_COOLDOWN) {
    quizzes.value = fallbackList()
    return
  }
  loading.value = true
  try {
    // showError:false —— 首页自带本地兜底，失败不该弹「服务异常」吓用户
    const list = await getQuizList({ showError: false })
    if (list && list.length) {
      listCache = list
      quizzes.value = list
    } else {
      quizzes.value = fallbackList()
      listFailAt = now
    }
  } catch (e) {
    // 后端不可达（404/断网/域名未配白名单等）-> 只给 MBTI 一张本地卡
    quizzes.value = fallbackList()
    listFailAt = now
  } finally {
    loading.value = false
  }
}

function fallbackList() {
  return [{ code: QUIZ_CODE, name: 'MBTI 性格', emoji: '🧠', tag: '性格', questionCount: 24 }]
}

function iconBg(i) {
  return hexToRgba(FAMILY[i % FAMILY.length], 0.16)
}

function hexToRgba(hex, a) {
  const h = String(hex || '').replace('#', '')
  if (h.length !== 6) return `rgba(124,107,245,${a})`
  const r = parseInt(h.slice(0, 2), 16)
  const g = parseInt(h.slice(2, 4), 16)
  const b = parseInt(h.slice(4, 6), 16)
  return `rgba(${r},${g},${b},${a})`
}

/** 一题约 5 秒，向上取整到分钟，至少 1 分钟 */
function estMin(q) {
  const n = Number(q.questionCount) || 24
  return Math.max(1, Math.round((n * 5) / 60))
}

function goQuiz(q) {
  uni.navigateTo({
    url: `/pages/quiz/quiz?code=${q.code}&name=${encodeURIComponent(q.name)}&emoji=${encodeURIComponent(q.emoji || '')}`
  })
}

/** 今日卡：没抽过就去测；抽过了就再测一次（换一套体验） */
function drawToday() {
  if (todayDraw.value) {
    uni.showToast({ title: '今天已经抽过啦，明天再来', icon: 'none' })
    return
  }
  const q = quizzes.value[0] || fallbackList()[0]
  goQuiz(q)
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 24rpx 32rpx 40rpx;
  box-sizing: border-box;
  background: var(--c-bg);
}

/* ---------- 顶部 ---------- */
.hero { display: flex; align-items: center; justify-content: space-between; margin: 12rpx 6rpx 28rpx; }
.hero-l { flex: 1; }
.hero-l .h { font-size: 44rpx; font-weight: 800; color: var(--c-text); display: block; }
.hero-l .p { font-size: 25rpx; color: var(--c-sub); margin-top: 10rpx; display: block; }
.hero-r {
  flex: none; min-width: 120rpx; padding: 16rpx 24rpx; border-radius: 24rpx;
  background: rgba(255, 255, 255, 0.72); border: 1rpx solid rgba(255, 255, 255, 0.8);
  box-shadow: 0 10rpx 26rpx rgba(150, 160, 210, 0.14);
  display: flex; flex-direction: column; align-items: center;
}
.hr-n { font-size: 36rpx; font-weight: 800; color: var(--c-text); }
.hr-t { font-size: 20rpx; color: var(--c-faint); margin-top: 2rpx; }

/* ---------- 今日卡 ---------- */
/* Hero 区：全页唯一允许大面积铺色的地方。
   未抽 = 品牌紫（行动召唤）；已抽 = 完成绿（状态语义） */
.today {
  position: relative; border-radius: var(--r-card); overflow: hidden; margin-bottom: 8rpx;
  background: linear-gradient(135deg, #007aff 0%, #4da3ff 100%);
  box-shadow: 0 16rpx 36rpx rgba(0, 122, 255, 0.24);
  color: #fff;
}
.today--done {
  background: linear-gradient(135deg, #34c759 0%, #66d97f 100%);
  box-shadow: 0 16rpx 36rpx rgba(52, 199, 89, 0.22);
}
.td-deco {
  position: absolute; right: -60rpx; top: -70rpx;
  width: 260rpx; height: 260rpx; border-radius: 50%;
  background: rgba(255, 255, 255, 0.16);
}
.td-body { position: relative; padding: 32rpx 32rpx 34rpx; }
.td-top { display: flex; align-items: center; justify-content: space-between; }
.td-lab { font-size: 22rpx; opacity: 0.9; letter-spacing: 2rpx; }
.td-done-tag {
  font-size: 20rpx; font-weight: 800; padding: 4rpx 16rpx; border-radius: 16rpx;
  background: rgba(255, 255, 255, 0.28);
}
.td-title { font-size: 38rpx; font-weight: 800; display: block; margin: 14rpx 0 10rpx; }
.td-sub { font-size: 23rpx; opacity: 0.92; display: block; }
.td-btn {
  display: inline-block; margin-top: 24rpx; background: #fff;
  padding: 16rpx 40rpx; border-radius: 36rpx;
  box-shadow: 0 8rpx 20rpx rgba(0, 0, 0, 0.08);
}
.td-bt { font-size: 27rpx; font-weight: 500; color: var(--c-primary); }

.td-got { display: flex; align-items: center; margin: 18rpx 0 12rpx; }
.td-emoji { font-size: 64rpx; margin-right: 22rpx; }
.td-got-r { display: flex; flex-direction: column; }
.td-code { font-size: 40rpx; font-weight: 800; letter-spacing: 2rpx; }
.td-name { font-size: 25rpx; opacity: 0.94; margin-top: 4rpx; }

/* ---------- 测评卡片 ---------- */
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: var(--sp-md); }
.qcard { padding: 28rpx 26rpx 24rpx; }
.qcard--hover { background: var(--c-surface-2); }

.qc-icon {
  width: 88rpx; height: 88rpx; border-radius: var(--r-md);
  display: flex; align-items: center; justify-content: center;
  margin-bottom: var(--sp-sm);
}
.qci { font-size: 44rpx; }
.qc-name { font-size: 31rpx; font-weight: 600; color: var(--c-text); display: block; }
.qc-meta { margin-top: 14rpx; display: flex; flex-direction: column; align-items: flex-start; gap: 10rpx; }
.qc-count { font-size: var(--fs-micro); color: var(--c-faint); }
.qc-go { margin-top: 18rpx; }
.qcg { font-size: 23rpx; font-weight: 500; color: var(--c-primary); }

.tip { display: block; text-align: center; color: var(--c-sub); font-size: 24rpx; margin: 28rpx 0; }
.tip--empty { color: var(--c-faint); }
</style>
