<template>
  <view class="page">
    <view class="nav"><text class="nav-t">我的</text></view>

    <!-- ============ 资料卡：头像/昵称可编辑，三项统计全部实时算 ============ -->
    <view class="u-card profile">
      <view class="pf-top">
        <view class="avatar-wrap" @click="showAvatar = true">
          <view class="avatar-ring"><text class="avatar-emoji">{{ profile.avatar }}</text></view>
          <view class="avatar-badge"><text class="ab-t">换</text></view>
        </view>

        <view class="pf-mid">
          <input
            v-if="editing"
            class="nick-input"
            v-model="nickInput"
            :focus="true"
            maxlength="12"
            placeholder="给自己起个名字"
            placeholder-class="nick-ph"
          />
          <text v-else class="nick">{{ profile.nickname }}</text>
          <text class="pf-sub">{{ joinText }}</text>
        </view>

        <view v-if="editing" class="pf-ops">
          <text class="pf-save" @click="saveNick">保存</text>
          <text class="pf-cancel" @click="editing = false">取消</text>
        </view>
        <text v-else class="pf-edit" @click="startEdit">改名</text>
      </view>

      <view class="stats">
        <view class="stat"><text class="sn">{{ cardCount }}</text><text class="sl">卡牌</text></view>
        <view class="sdiv"></view>
        <view class="stat"><text class="sn">{{ testCount }}</text><text class="sl">测过</text></view>
        <view class="sdiv"></view>
        <view class="stat"><text class="sn">{{ streak }}</text><text class="sl">连续天数</text></view>
      </view>
    </view>

    <!-- ============ 主导类型：有记录才出现，没有就整块不渲染 ============ -->
    <view v-if="topType" class="u-card top-card" :style="{ background: topBg }">
      <view class="tc-left">
        <text class="tc-lab">测得最多的类型</text>
        <text class="tc-code">{{ topType.code }}</text>
        <text class="tc-name">{{ topType.name }} · {{ topType.count }} 次</text>
      </view>
      <text class="tc-emoji">{{ topType.emoji }}</text>
    </view>

    <!-- ============ 卡册：16 格全展示，已得高亮、未得灰色 ============ -->
    <view class="u-sec">
      <text class="u-sec-t">我的卡册</text>
      <text class="u-sec-s">已收集 {{ cardCount }} / {{ slots.length }}</text>
    </view>

    <view class="u-card album-card">
      <view class="album">
        <view
          v-for="s in slots"
          :key="s.code"
          class="slot"
          :class="{ 'slot--got': s.got }"
          :style="{ background: s.got ? slotBg(s.color) : 'rgba(160,170,200,0.13)' }"
          @click="openCard(s)"
        >
          <text class="slot-code" :style="{ color: s.got ? '#ffffff' : '#c3cad6' }">{{ s.got ? s.code : '?' }}</text>
          <view class="slot-art">
            <image v-if="s.got && s.art" class="slot-art-img" :src="s.art" mode="aspectFit" />
            <text v-else class="slot-emoji">{{ s.got ? s.emoji : '🔒' }}</text>
          </view>
          <text class="slot-name" :style="{ color: s.got ? '#ffffff' : '#c3cad6' }">{{ s.got ? s.name : '未解锁' }}</text>
        </view>
      </view>
      <view class="album-foot">
        <text class="af-t">集齐 16 张卡，看看你最像哪一种人格</text>
        <text class="af-go" @click="goHome">去测一测 ›</text>
      </view>
    </view>

    <!-- ============ 功能菜单：每一项都真的能点，没有占位 ============ -->
    <!-- Apple 分组列表：白卡片内嵌行 + 左侧内缩的细分割线 -->
    <view class="u-sec"><text class="u-sec-t">我的数据</text></view>
    <view class="u-group">
      <view class="u-row" hover-class="u-row--hover" @click="goHistory">
        <text class="ic ic--blue">📊</text>
        <view class="rm"><text class="mt">我的记录</text><text class="rd">共 {{ testCount }} 次</text></view>
        <text class="arrow">›</text>
      </view>
      <view class="u-sep"></view>
      <view class="u-row" hover-class="u-row--hover" @click="clearData">
        <text class="ic ic--grey">🗑</text>
        <view class="rm"><text class="mt">清空本地数据</text><text class="rd">删除记录与卡册</text></view>
        <text class="arrow">›</text>
      </view>
    </view>

    <view class="u-sec"><text class="u-sec-t">关于</text></view>
    <view class="u-group">
      <view class="u-row" hover-class="u-row--hover" @click="showPrivacy = true">
        <text class="ic ic--mint">🔒</text>
        <view class="rm"><text class="mt">隐私说明</text><text class="rd">结果只在本地，不上传</text></view>
        <text class="arrow">›</text>
      </view>
      <view class="u-sep"></view>
      <!-- 分享必须用 button open-type="share"，用 view 点不出来 -->
      <button class="u-row u-row--btn" open-type="share" hover-class="u-row--hover">
        <text class="ic ic--sun">📤</text>
        <view class="rm"><text class="mt">分享给好友</text><text class="rd">把好玩的测评传出去</text></view>
        <text class="arrow">›</text>
      </button>
    </view>

    <!-- 仅微信：抖音无支付能力、无激励视频 API，整组不编译 -->
    <!-- #ifdef MP-WEIXIN -->
    <view class="u-sec"><text class="u-sec-t">支持作者</text></view>
    <view class="u-group">
      <view class="u-row" hover-class="u-row--hover" @click="rewardAuthor">
        <text class="ic ic--pink">🥤</text>
        <view class="rm"><text class="mt">请作者喝奶茶</text><text class="rd">个人主体道具直购</text></view>
        <text class="arrow">›</text>
      </view>
      <view class="u-sep"></view>
      <view class="u-row" hover-class="u-row--hover" @click="rewardByAd">
        <text class="ic ic--purple">📺</text>
        <view class="rm"><text class="mt">看广告 · 激励作者</text><text class="rd">看完即算鼓励</text></view>
        <text class="arrow">›</text>
      </view>
    </view>
    <!-- #endif -->

    <text class="foot">探我趣测 · 数据在本人手机上，卸载即清除</text>

    <!-- ============ 弹层：头像选择 / 卡牌详情 / 隐私说明 ============ -->
    <view v-if="showAvatar || showPrivacy || detailCard" class="u-mask" @click="closeAll">
      <view class="u-sheet" @click.stop="noop">
        <!-- 头像 -->
        <template v-if="showAvatar">
          <text class="sh-t">选一个头像</text>
          <view class="emoji-grid">
            <view
              v-for="e in AVATARS"
              :key="e"
              class="emoji-cell"
              :class="{ 'emoji-cell--on': profile.avatar === e }"
              @click="chooseAvatar(e)"
            ><text class="ec-t">{{ e }}</text></view>
          </view>
          <view class="u-btn u-btn--primary u-btn--block sh-btn" hover-class="u-btn--hover" @click="showAvatar = false"><text class="u-btn-t">完成</text></view>
        </template>

        <!-- 卡牌详情 -->
        <template v-else-if="detailCard">
          <view class="dc-head" :style="{ background: slotBg(detailCard.color) }">
            <text class="dc-code">{{ detailCard.code }}</text>
            <image v-if="detailCard.art" class="dc-art" :src="detailCard.art" mode="aspectFit" />
            <text v-else class="dc-emoji">{{ detailCard.emoji }}</text>
          </view>
          <text class="dc-name">{{ detailCard.name }}</text>
          <text class="dc-group">{{ detailCard.groupLabel }} · 收集于 {{ detailCard.gotAt }}</text>
          <text class="dc-desc">{{ detailCard.desc }}</text>
          <view class="dc-tags">
            <text v-for="(w, i) in detailCard.strengths" :key="i" class="dc-tag">{{ w }}</text>
          </view>
          <view class="u-btn u-btn--primary u-btn--block sh-btn" hover-class="u-btn--hover" @click="detailCard = null"><text class="u-btn-t">知道啦</text></view>
        </template>

        <!-- 隐私说明 -->
        <template v-else>
          <text class="sh-t">隐私说明</text>
          <text class="pv-p">1. 答题与算分全部在你的手机上完成，不上传服务器。</text>
          <text class="pv-p">2. 记录与卡册只存在本机存储，卸载小程序即清除。</text>
          <text class="pv-p">3. 不索取手机号、通讯录、位置等任何敏感权限。</text>
          <text class="pv-p">4. 「清空本地数据」可随时一键抹除全部记录。</text>
          <view class="u-btn u-btn--primary u-btn--block sh-btn" hover-class="u-btn--hover" @click="showPrivacy = false"><text class="u-btn-t">明白了</text></view>
        </template>
      </view>
    </view>
  </view>
</template>

<script setup>
/**
 * 我的
 * ------------------------------------------------------------
 * 本次改造重点（之前这页问题最大）：
 *   1. 删掉所有"点了没反应"的死菜单（我的报告 / 已解锁内容 / 消息通知 / 设置），
 *      换成每一项都真能用的功能。
 *   2. 静态假数据全部改成实时计算：
 *        连续天数 5  -> computeStreak()（从记录的真实日期往回数）
 *        测过 N 次   -> quiz_history.length
 *        加入 X 天   -> daysSince(最早一条记录)
 *        主导类型     -> mostFrequent() 统计出现最多的类型码
 *   3. 卡册从"有几张显示几张"改成 16 格全铺开，未收集显示锁，有收集目标感。
 *   4. 昵称 / 头像可编辑并持久化到 storage（之前写死"探我小用户"）。
 */
import { ref, reactive, computed } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { onShareAppMessage } from '@dcloudio/uni-app'
import { PERSONALITY_TYPES } from '@/data/questions.js'
import { computeStreak, daysSince, mostFrequent, timeAgo } from '@/utils/format.js'
import { typeArt } from '@/config/typeArt.js'

// #ifdef MP-WEIXIN
import { buyProduct, checkIosVersion } from '@/utils/payment.js'
import { showRewarded } from '@/utils/ads.js'
// #endif

const AVATARS = ['🐱', '🐶', '🐰', '🐼', '🦊', '🐻', '🐨', '🦁', '🐯', '🐮', '🐷', '🐸',
  '🐵', '🐧', '🐙', '🦄', '🦋', '🌸', '🌙', '⭐', '🍑', '🍓', '🌵', '🍀']

const DEFAULT_NICK = '探我小用户'
const KEY_PROFILE = 'quiz_profile'

const album = ref([])
const history = ref([])
const profile = reactive({ nickname: DEFAULT_NICK, avatar: '🐱', createdAt: 0 })

const editing = ref(false)
const nickInput = ref('')
const showAvatar = ref(false)
const showPrivacy = ref(false)
const detailCard = ref(null)

onShow(() => {
  album.value = uni.getStorageSync('quiz_album') || []
  history.value = uni.getStorageSync('quiz_history') || []
  const p = uni.getStorageSync(KEY_PROFILE) || {}
  profile.nickname = p.nickname || DEFAULT_NICK
  profile.avatar = p.avatar || '🐱'
  profile.createdAt = p.createdAt || 0
})

function saveProfile() {
  uni.setStorageSync(KEY_PROFILE, {
    nickname: profile.nickname,
    avatar: profile.avatar,
    createdAt: profile.createdAt || Date.now()
  })
}

/* ---------------- 统计（全部实时算） ---------------- */
const cardCount = computed(() => album.value.length)
const testCount = computed(() => history.value.length)
const streak = computed(() => computeStreak(history.value))

const firstAt = computed(() => {
  let min = 0
  history.value.forEach((h) => {
    const d = Number(h && h.date) || 0
    if (d && (!min || d < min)) min = d
  })
  return min
})

const lastAt = computed(() => {
  let max = 0
  history.value.forEach((h) => {
    const d = Number(h && h.date) || 0
    if (d > max) max = d
  })
  return max
})

const joinText = computed(() => {
  if (!firstAt.value) return '还没开始探索，去首页试试吧'
  return `加入第 ${daysSince(firstAt.value)} 天 · 最近 ${timeAgo(lastAt.value)}`
})

const topType = computed(() => {
  const top = mostFrequent(history.value)
  if (!top) return null
  const p = PERSONALITY_TYPES[top.code] || {}
  return {
    code: top.code,
    count: top.count,
    name: p.name || top.code,
    emoji: p.emoji || '🧩',
    color: p.color || '#8FB8FF',
    groupLabel: p.groupLabel || ''
  }
})

const topBg = computed(() => {
  const c = (topType.value && topType.value.color) || '#8FB8FF'
  return `linear-gradient(135deg, ${hexToRgba(c, 0.95)}, ${hexToRgba(c, 0.68)})`
})

/* ---------------- 卡册 16 格 ---------------- */
const slots = computed(() => {
  const owned = {}
  album.value.forEach((c) => { if (c && c.type) owned[c.type] = c })
  return Object.keys(PERSONALITY_TYPES).map((code) => {
    const p = PERSONALITY_TYPES[code] || {}
    const got = owned[code]
    return {
      code,
      name: p.name || code,
      emoji: p.emoji || '🧩',
      color: p.color || '#8FB8FF',
      groupLabel: p.groupLabel || '',
      desc: p.desc || p.summary || '',
      strengths: (p.strengths || []).slice(0, 3),
      art: typeArt(code),
      got: !!got,
      gotAt: got ? timeAgo(got.date) : ''
    }
  })
})

function hexToRgba(hex, a) {
  const h = String(hex || '').replace('#', '')
  if (h.length !== 6) return `rgba(168,200,255,${a})`
  const r = parseInt(h.slice(0, 2), 16)
  const g = parseInt(h.slice(2, 4), 16)
  const b = parseInt(h.slice(4, 6), 16)
  return `rgba(${r},${g},${b},${a})`
}

function slotBg(color) {
  return `linear-gradient(150deg, ${hexToRgba(color, 0.96)}, ${hexToRgba(color, 0.72)})`
}

/* ---------------- 交互 ---------------- */
function startEdit() {
  nickInput.value = profile.nickname
  editing.value = true
}

function saveNick() {
  const v = String(nickInput.value || '').trim()
  profile.nickname = v || DEFAULT_NICK
  if (!profile.createdAt) profile.createdAt = Date.now()
  saveProfile()
  editing.value = false
  uni.showToast({ title: '昵称已更新', icon: 'none' })
}

function chooseAvatar(e) {
  profile.avatar = e
  if (!profile.createdAt) profile.createdAt = Date.now()
  saveProfile()
}

function openCard(s) {
  if (!s.got) {
    uni.showToast({ title: '去测一测就能解锁这张卡', icon: 'none' })
    return
  }
  detailCard.value = s
}

/** 弹层内部点击用它吃掉冒泡，避免点面板本身就把弹层关掉 */
function noop() {}

function closeAll() {
  showAvatar.value = false
  showPrivacy.value = false
  detailCard.value = null
}

function goHome() {
  uni.switchTab({ url: '/pages/index/index' })
}

function goHistory() {
  uni.switchTab({ url: '/pages/history/history' })
}

function clearData() {
  if (!testCount.value && !cardCount.value) {
    uni.showToast({ title: '本来就是空的', icon: 'none' })
    return
  }
  uni.showModal({
    title: '清空本地数据',
    content: `将删除 ${testCount.value} 条记录和 ${cardCount.value} 张卡牌，且无法恢复。`,
    confirmText: '清空',
    confirmColor: '#ff6b8a',
    cancelText: '再想想',
    success: (res) => {
      if (!res.confirm) return
      uni.removeStorageSync('quiz_history')
      uni.removeStorageSync('quiz_album')
      album.value = []
      history.value = []
      uni.showToast({ title: '已清空', icon: 'none' })
    }
  })
}

// #ifdef MP-WEIXIN
async function rewardAuthor() {
  if (!checkIosVersion()) return
  try {
    const ok = await buyProduct('tip_milktea')
    if (ok) uni.showToast({ title: '谢谢你的奶茶', icon: 'none' })
  } catch (e) {
    console.warn('[reward]', e)
  }
}

async function rewardByAd() {
  const done = await showRewarded()
  uni.showToast({ title: done ? '感谢你的激励 ❤' : '看完广告才能激励作者哦', icon: 'none' })
}
// #endif

onShareAppMessage(() => ({
  title: '探我趣测 · 测测你是什么类型',
  path: '/pages/index/index'
}))
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 24rpx 32rpx 60rpx;
  box-sizing: border-box;
  background: var(--c-bg);
}
.nav { margin: 12rpx 6rpx 24rpx; }
.nav-t { font-size: 44rpx; font-weight: 800; color: var(--c-text); }

/* ---------- 资料卡 ---------- */
.profile { padding: 36rpx 32rpx 28rpx; }
.pf-top { display: flex; align-items: center; }
.avatar-wrap { position: relative; width: 120rpx; height: 120rpx; flex: none; }
.avatar-ring {
  width: 120rpx; height: 120rpx; border-radius: 50%;
  background: linear-gradient(135deg, #007aff, #5ac8fa);
  display: flex; align-items: center; justify-content: center;
}
.avatar-emoji { font-size: 56rpx; }
.avatar-badge {
  position: absolute; right: -4rpx; bottom: -4rpx;
  width: 42rpx; height: 42rpx; border-radius: 50%;
  background: #fff; border: 2rpx solid rgba(255, 157, 180, 0.5);
  display: flex; align-items: center; justify-content: center;
}
.ab-t { font-size: 20rpx; color: var(--c-primary); font-weight: 600; }

.pf-mid { flex: 1; margin-left: 24rpx; overflow: hidden; }
.nick { font-size: 34rpx; font-weight: 800; color: var(--c-text); display: block; }
.nick-input {
  font-size: 32rpx; font-weight: 800; color: var(--c-text);
  background: rgba(160, 170, 200, 0.12);
  border-radius: 14rpx; padding: 8rpx 16rpx; display: block;
}
.nick-ph { color: var(--c-faint); font-weight: 400; }
.pf-sub { font-size: 23rpx; color: var(--c-sub); margin-top: 8rpx; display: block; }

.pf-ops { display: flex; flex-direction: column; align-items: flex-end; flex: none; }
.pf-save { font-size: 25rpx; font-weight: 500; color: #fff; background: var(--c-primary); padding: 10rpx 28rpx; border-radius: var(--r-full); }
.pf-cancel { font-size: 23rpx; color: var(--c-faint); margin-top: 10rpx; }
.pf-edit { font-size: 23rpx; color: var(--c-faint); flex: none; }

.stats {
  display: flex; align-items: center; margin-top: 30rpx;
  padding-top: 26rpx; border-top: 1rpx solid rgba(160, 170, 200, 0.16);
}
.stat { flex: 1; display: flex; flex-direction: column; align-items: center; }
.sn { font-size: 38rpx; font-weight: 800; color: var(--c-text); }
.sl { font-size: 22rpx; color: var(--c-sub); margin-top: 6rpx; }
.sdiv { width: 1rpx; height: 44rpx; background: rgba(160, 170, 200, 0.18); }

/* ---------- 主导类型 ---------- */
.top-card {
  margin-top: 28rpx; padding: 32rpx; color: #fff;
  display: flex; align-items: center; justify-content: space-between;
  box-shadow: 0 18rpx 40rpx rgba(150, 160, 210, 0.28);
}
.tc-left { flex: 1; min-width: 0; }
.tc-lab { font-size: 22rpx; opacity: 0.88; display: block; }
.tc-code { font-size: 52rpx; font-weight: 800; display: block; margin: 6rpx 0 4rpx; letter-spacing: 2rpx; }
.tc-name { font-size: 24rpx; opacity: 0.92; display: block; }
.tc-emoji { font-size: 76rpx; }

/* ---------- 卡册 ---------- */
.album-card { padding: 28rpx 24rpx 20rpx; }
.album { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16rpx; }
.slot {
  aspect-ratio: 3 / 4; border-radius: 20rpx;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  overflow: hidden;
}
.slot--got { box-shadow: 0 10rpx 24rpx rgba(150, 160, 210, 0.22); }
/* 未解锁的灰字走内联 :style 判断，不用 :not() —— 小程序 wxss 对
   :not() 支持不一致，写了可能整条规则失效导致灰底白字看不见 */
.slot-code { font-size: 24rpx; font-weight: 800; letter-spacing: 1rpx; }
.slot-art { width: 100%; height: 60rpx; display: flex; align-items: center; justify-content: center; margin: 4rpx 0; }
.slot-art-img { width: 56rpx; height: 56rpx; }
.slot-emoji { font-size: 40rpx; margin: 6rpx 0 4rpx; }
.slot-name { font-size: 20rpx; font-weight: 700; }

.album-foot {
  margin-top: 22rpx; padding-top: 18rpx;
  border-top: 1rpx solid rgba(160, 170, 200, 0.14);
  display: flex; align-items: center; justify-content: space-between;
}
.af-t { font-size: 22rpx; color: var(--c-faint); flex: 1; }
.af-go { font-size: 24rpx; font-weight: 600; color: var(--c-primary); flex: none; }

/* ---------- 菜单 ---------- */
/* button 版的行（分享用）需要抹掉小程序 button 的默认样式 */
.u-row--btn {
  font-size: 30rpx; line-height: normal; border-radius: 0;
  margin: 0; text-align: left;
}

/* Apple 列表图标：小尺寸 + 圆角 + tinted 底（系统色的低透明度版本） */
.ic {
  width: 60rpx; height: 60rpx; border-radius: var(--r-md); flex: none;
  font-size: 30rpx; display: flex; align-items: center; justify-content: center;
}
.ic--blue { background: rgba(0, 122, 255, 0.12); }
.ic--grey { background: rgba(60, 60, 67, 0.08); }
.ic--mint { background: rgba(52, 199, 89, 0.14); }
.ic--sun { background: rgba(255, 159, 10, 0.16); }
.ic--pink { background: rgba(255, 59, 48, 0.12); }
.ic--purple { background: rgba(94, 92, 230, 0.14); }

.rm { flex: 1; display: flex; flex-direction: column; }
.mt { font-size: 29rpx; font-weight: 500; color: var(--c-text); }
.rd { font-size: 22rpx; color: var(--c-faint); margin-top: 4rpx; }
.arrow { color: var(--c-faint); font-size: 32rpx; flex: none; }

.foot {
  display: block; text-align: center; margin-top: 44rpx;
  font-size: 21rpx; color: var(--c-faint);
}

/* ---------- 弹层 ----------
 * 遮罩与面板本身已由全局 .u-mask / .u-sheet 提供（含入场动画），
 * 这里只留页面特有的间距，不再重复写一份。
 */
.sh-btn { margin-top: var(--sp-lg); }

.sh-t { font-size: 32rpx; font-weight: 800; color: var(--c-text); display: block; margin-bottom: 28rpx; }
.emoji-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 16rpx; }
.emoji-cell {
  aspect-ratio: 1; border-radius: 20rpx; background: rgba(160, 170, 200, 0.1);
  display: flex; align-items: center; justify-content: center;
}
.emoji-cell--on { background: var(--c-primary-soft); }
.ec-t { font-size: 40rpx; }

.dc-head {
  height: 200rpx; border-radius: 28rpx; margin-bottom: 24rpx;
  display: flex; flex-direction: column; align-items: center; justify-content: center; color: #fff;
}
.dc-code { font-size: 44rpx; font-weight: 800; letter-spacing: 4rpx; }
.dc-art { width: 120rpx; height: 120rpx; margin-top: 8rpx; }
.dc-emoji { font-size: 60rpx; margin-top: 8rpx; }
.dc-name { font-size: 34rpx; font-weight: 800; color: var(--c-text); display: block; }
.dc-group { font-size: 23rpx; color: var(--c-sub); margin-top: 8rpx; display: block; }
.dc-desc { font-size: 27rpx; color: var(--c-text-2); line-height: 1.8; margin-top: 18rpx; display: block; }
.dc-tags { display: flex; flex-wrap: wrap; gap: 12rpx; margin-top: 20rpx; }
.dc-tag { font-size: 22rpx; color: var(--c-sub); background: var(--c-surface-2); padding: 6rpx 18rpx; border-radius: var(--r-full); }

.pv-p { font-size: 27rpx; color: var(--c-text-2); line-height: 1.85; display: block; margin-bottom: 14rpx; }

</style>
