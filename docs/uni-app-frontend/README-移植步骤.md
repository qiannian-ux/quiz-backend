# uni-app 前端（完整参考实现）

> 状态：本目录是 `quiz-miniapp` 前端工程的**源码副本**，已生成一份可直接运行的项目。
> 工程位置：`D:/Users/35156/Documents/HBuilderProjects/quiz-miniapp`
> 技术栈：Vue3 + `<script setup>` + rpx，基于 HBuilderX 默认模板。

## 工程结构

```
config/env.js           环境配置（域名、超时、平台标识、能力开关、题量）
utils/request.js        uni.request 封装（核心：统一 URL/token/错误/超时）
utils/auth.js           token 存取（M4 双端登录再启用）
utils/cloud.js          微信云开发适配层（可摘除，抖音端自动走空实现）
utils/scoring.js        算分纯函数（不依赖框架，可单独单测）
api/quiz.js             接口聚合（页面不直接写 URL）
data/questions.js       本地题库（后端只有 1 道种子题时的离线兜底）
composables/useQuiz.js  答题流程状态（页面只管渲染）
pages/index/index.vue   欢迎页
pages/quiz/quiz.vue     答题页
pages/result/result.vue 结果页
```

> HBuilderX 工程**没有 src 目录**，文件直接放工程根。下面章节的运行、打包、双端配置对当前工程都适用，可对照查看。

## 一、本目录的定位

这份代码已生成并跑通在 HBuilderX 工程 `quiz-miniapp` 里；本目录是它的源码副本，
作用是随后端仓库一起提交、跨机器同步。原"拷文件"步骤已不需要——工程本身就是完整的。

后续章节是工程的关键配置说明与双端注意事项。
api/quiz.js          接口聚合
pages/index/index.vue 首页（可跑）
```

## 二、pages.json

官方模板会生成默认页面，把 `pages` 数组改成（只留首页，其余页面等你自己加）：

```json
{
  "pages": [
    {
      "path": "pages/index/index",
      "style": {
        "navigationBarTitleText": "趣味测评",
        "navigationBarBackgroundColor": "#FFEEF6"
      }
    }
  ],
  "globalStyle": {
    "navigationBarTextStyle": "black",
    "backgroundColor": "#F6F8FC"
  }
}
```

> 抖音端导航栏配色不支持 `navigationBarBackgroundColor` 的部分取值，
> 如果发现抖音端顶栏颜色不对，改用 `"navigationStyle": "custom"` 自己画。

## 三、manifest.json

在 HBuilderX 里用**可视化界面**改，别手改 JSON（容易被覆盖）。要点：

| 位置 | 填什么 |
| --- | --- |
| 微信小程序配置 → AppID | 微信公众平台拿到的 AppID |
| 抖音小程序配置 → AppID | 抖音开放平台拿到的 AppID |
| 基础配置 → 应用名称 | 趣味测评 |

勾选「微信小程序」「抖音小程序」两个平台，Vue 版本选 **Vue3**。

## 四、两个平台后台都要加合法域名（最容易踩的坑）

不加白名单，真机/预览一律报 `url not in domain list`（开发者工具里勾了"不校验合法域名"能跑，真机必挂）。

- **微信**：微信公众平台 → 开发 → 开发管理 → 开发设置 → 服务器域名 → request 合法域名，加 `https://wangwang2.asia`
- **抖音**：抖音开放平台 → 对应小程序 → 开发设置 → 服务器域名白名单，加 `https://wangwang2.asia`

域名需已备案 + 证书有效，`wangwang2.asia` 已满足。

## 五、如果用 H5 方式调试（跨域）

小程序网络请求**不走浏览器 CORS 策略**，真机上没问题；
但 `npm run dev:h5` 在浏览器里调试会被同源策略拦住。两个解法：

1. 推荐：直接用微信开发者工具调试，绕开跨域。
2. 需要 H5 联调：在宝塔 Nginx 的站点配置里加响应头（**这是后端侧的活儿，前端改不了**）：

```nginx
add_header Access-Control-Allow-Origin * always;
add_header Access-Control-Allow-Methods 'GET,POST,OPTIONS' always;
add_header Access-Control-Allow-Headers 'Content-Type,Authorization,X-Client-Platform' always;
if ($request_method = 'OPTIONS') { return 204; }
```

## 五之二、云开发接入（可选，随时可摘）

架构约定见 `docs/双后端架构约定.md`。核心：**云开发只做无状态增强，不存核心数据**。

要用云开发时，在 `App.vue` 里初始化（**不要 await，失败也不能阻塞进页面**）：

```js
import { initCloud, syncFeatures } from '@/utils/cloud.js'

onLaunch(() => {
  initCloud()
})
```

云能力不可用时 `generatePoster()` 返回 `null`，页面走本地 canvas 降级即可。
抖音端 `utils/cloud.js` 自动编译成空实现，页面代码不用写条件编译。

## 六、跑起来（开发态）

**HBuilderX**（本项目的用法）：

1. 顶部菜单「运行 → 运行到小程序模拟器 → 微信开发者工具」
2. 首次会让你填微信开发者工具的安装路径，填一次就记住了
3. **前置条件**：微信开发者工具里必须开启「设置 → 安全 → 服务端口」，否则 HBuilderX 连不上、点了没反应
4. 抖音端同理：装抖音开发者工具，选「运行到小程序模拟器 → 抖音开发者工具」

**CLI 工程**（如果你将来改用命令行）：
`npm run dev:mp-weixin` / `npm run dev:mp-toutiao`，产物在 `dist/dev/`，用对应开发者工具打开那个目录。

开发态支持热更新——改代码保存后模拟器自动刷新，不用重新运行。

## 七、打包发行（上传审核前必做）

「运行」和「发行」是两回事，别搞混：

| | 运行（dev） | 发行（build） |
| --- | --- | --- |
| 用途 | 开发调试 | 上传审核 |
| 产物目录 | `unpackage/dist/dev/` | `unpackage/dist/build/` |
| 代码 | 未压缩、含调试信息 | 压缩、去掉调试代码 |
| 体积 | 大 | 小 |

**上传审核必须用 build 产物**，用 dev 包会被平台以"包含调试代码"为由打回。

**操作步骤：**

1. 先确认 `manifest.json` 里填好了对应平台的 AppID（微信和抖音是两套 AppID，各填各的）
2. 顶部菜单「发行 → 小程序-微信」或「发行 → 小程序-抖音」
3. 编译完自动打开 `unpackage/dist/build/mp-weixin`（或 mp-toutiao）
4. **uni-app 只产出小程序源码，不能一步上线**。还需要在开发者工具里点「上传」→ 填版本号和备注
5. 去微信公众平台 / 抖音开放平台后台 → 版本管理 → 提交审核

一次发行可以同时勾多个平台，会依次编译出各自的产物。

## 八、三个打包时注意的坑

1. **微信开发者工具必须开服务端口**（设置 → 安全 → 服务端口）。这是"点运行没反应"的头号原因。
2. **图片别往 `static/` 里塞。** 两个平台都有主包体积限制，图片全打进包里很快就会超。正确做法：图片放后端或 CDN，前端只存 URL。
3. **`unpackage/` 是编译产物，别提交到 git。** 默认模板的 `.gitignore` 已经忽略了，别手贱删那行。

> `static/` 目录有个特殊规则：这里的**文件不经过编译**，原样拷贝进产物。
> 所以它只能放图片、字体这类静态资源，**不能放 js**（放进去不会被 babel 处理，也不会被引入）。

## 九、给你的三个练习（自己写，写完发我审）

## 七、给你的三个练习（自己写，写完发我审）

按难度递增：

1. **多题流程**：把单题拉一次改成连拉 5 题，答完一题自动进下一题。
   提示：状态放 `ref([])`，用下标 `currentIndex` 控制当前渲染哪一题。
2. **本地算分**：后端还没有算分接口，先在前端算。
   提示：给每个选项一个分值，权重规则抽成纯函数（不依赖 uni / Vue），方便单独测。
3. **结果页 `pages/result/result.vue`**：展示结果 + 重新开始 + 分享图。
   提示：页面间别传大对象，用 `uni.setStorageSync` 或 URL 参数传 id。

> 面试能讲的点：多题状态建议抽成 `composables/useQuiz.js`，
> 算分规则抽成纯函数 —— 页面只管渲染，逻辑可单测，这叫"视图与逻辑分离"。

## 八、后端侧的对应待办（M5）

前端这边先本地算分，等后端这些接口出来再替换：

- `POST /api/quiz/submit` 提交答案 → 返回结果
- 统一响应体 `{code, data, msg}`（现在 `QuizController` 直接返回裸对象）
  改完后把 `utils/request.js` 里的 `unwrap()` 按注释打开即可，页面零改动。
