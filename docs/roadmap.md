# quiz-backend 学习路线（求职作品集项目）

> 协作方式：我（AI）给任务、讲原理、审你写的代码；你动手写、跑起来、卡住再来问。
> 原则：先自己想/试，再问；每段代码你要能讲清"为什么这么写"。

## 这个项目是什么

用 Spring Boot 写一个**微信 + 抖音双端趣味测评小程序的后端**，作为你找工作的作品集。

- 前端：uni-app（一套代码出微信小程序 + 抖音小程序）
- 后端：本仓库 Spring Boot（双端统一核心）
- 微信云开发：仅做微信端的可解耦外挂（登录 / 存储 / 推送 / 审核），以后可整体拔除

## 里程碑总览

| 阶段 | 主题 | 产出 |
|------|------|------|
| M1 ✅ | 跑通启动与请求链路 | 项目启动成功 |
| M2 | 第一个 RESTful API | 能返回 JSON 的接口 |
| M3 | 分层架构 + MySQL | 数据落地、Controller/Service/Mapper 分层 |
| M4 | 微信/抖音双端登录 | 统一用户表 + JWT |
| M5 | 测评领域模型 | 出题/作答/算分/结果闭环 |
| M6 | 安全与部署 | HTTPS/域名/鉴权/内容审核 |
| M7 | 测试 + 简历包装 | 单测 + 一页项目讲解稿 |

---

## M1 跑通启动与请求链路 ✅（已完成）

- **学到**：Spring Boot 怎么启动、内嵌 Tomcat、IoC 容器、8080 端口
- **你要能讲**：访问一个网址 → 代码被调用，中间发生了什么
- **已踩坑**：IDE 运行配置主类指错（包名 `com.example.quiz` vs `com.example.quizbackend`）→ 已修 `.idea/workspace.xml`
- **仍待办**：把测试类包名统一为 `com.example.quiz`（消除隐患，可选）

---

## M2 第一个 RESTful API（下一步）

**目标**：写一个接口，浏览器/小程序能调，返回 JSON。

**核心概念**
- `@RestController` 是什么，和普通 `@Controller` 区别
- `@GetMapping` / `@PostMapping` / `@RequestMapping`
- HTTP 方法 GET / POST 的语义
- 请求参数：`@RequestParam`（查询参数）、`@PathVariable`（路径参数）、`@RequestBody`（请求体）
- JSON 怎么自动序列化（Jackson，Spring Boot 自带）

**你要做**
1. 建 `controller` 包，写 `HelloController`，返回 `"hello"`
2. 写 `QuizController`，提供 `GET /api/quiz/random` 返回一道题（先用假数据/内存 List）
3. 用浏览器 / Postman / curl 验证

**验证**：访问 `http://localhost:8080/api/quiz/random` 能看到 JSON
**简历写法**："实现 RESTful 风格题库查询接口，统一 JSON 响应"

---

## M3 分层架构 + MySQL

**目标**：把数据存进数据库，理解后端分层；改用 MyBatis-Plus（国内更常用）。

**核心概念**
- 分层：Controller（接请求）/ Service（业务逻辑）/ Mapper（数据访问）
- MyBatis-Plus：`@TableName` `@TableId` 实体、`BaseMapper` 白送 CRUD、自定义 SQL 写 XML
- 手写 `CREATE TABLE` SQL（MyBatis 不自动建表）
- `application.properties` 配数据源（`spring.datasource.*`）和 `mybatis-plus.mapper-locations`
- Lombok `@Data` 省 getter/setter

**依赖**
```xml
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot4-starter</artifactId>
    <version>3.5.17</version>
</dependency>
```

**表结构**
```sql
CREATE TABLE question (
    id    BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL
);
CREATE TABLE question_option (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    question_id BIGINT NOT NULL,
    content     VARCHAR(255) NOT NULL
);
```

**你要做**
1. `pom.xml` 加 `mybatis-plus-spring-boot4-starter`
2. 在 MySQL 建 `question` / `question_option` 表
3. 建 `domain.Question` / `domain.QuestionOption` 实体
4. 建 `mapper.QuestionMapper extends BaseMapper<Question>` + XML 写 `selectRandomWithOptions`（一对多 `<collection>`）
5. 建 `service.QuizService` 调 Mapper
6. Controller 调 Service

**验证**：访问 `/api/quiz/random` 返回数据库里的随机题（含 options 数组）
**简历写法**："基于 MyBatis-Plus 实现数据持久化，采用 Controller-Service-Mapper 分层；手写 SQL 与 resultMap 完成一对多关联查询"

---

## M4 微信/抖音双端登录与统一用户

**目标**：两个小程序都能登录，且识别为同一个人。

**核心概念**
- 微信 `wx.login` → code → 微信 `code2Session` 换 openid
- 抖音 `tt.login` → code → 抖音开放接口换 openid
- 统一用户表：一个 user 行存 `wx_openid` + `dy_openid`
- Token（JWT）保持登录态

**你要做**
1. `User` 实体（含两个 openid 字段）
2. `/api/auth/login` 接口，带 `platform` 参数分流两平台
3. 用 JWT 签发 token 返回前端

**边界纪律（重要）**：云开发拿到的 openid 必须同步回本表；云开发不存权威数据
**简历写法**："设计双平台统一登录方案，兼容微信/抖音 openid 映射，基于 JWT 维护会话"

---

## M5 测评领域模型（核心业务）

**目标**：测评完整链路——出题、作答、算分、出结果。

**核心概念**
- 领域建模：`Quiz` / `Question` / `Option` / `UserAnswer` / `Result`
- 算分逻辑放在 Service 层
- 结果怎么存、怎么返回

**你要做**
1. 设计题库与作答的表结构
2. 作答接口：收答案 → 算分 → 存结果 → 返回
3. 结果查询接口

**简历写法**："实现测评领域模型与算分引擎，支持作答-评分-结果回写闭环"

---

## M6 安全与部署

**目标**：能真上线，经得起面试官问"你部署过吗"。

**核心概念**
- JWT 校验（拦截器 / 过滤器）
- HTTPS + 域名（小程序只认白名单 https 域名，localhost:8080 不行）
- 内容安全审核（微信 msgSecCheck / 抖音）
- 基础防护：参数校验、限流（Redis）

**你要做**
1. 加登录拦截
2. 部署到轻量服务器 + 域名 + SSL
3. 接内容审核

**简历写法**："完成 HTTPS 域名部署与登录鉴权，集成内容安全审核保障合规"

---

## M7 测试 + 简历包装

**目标**：项目经得起问。

**核心概念**
- 单元测试 JUnit / Mockito
- 接口测试
- 怎么讲项目：背景、你做了什么、难点、怎么解决的

**你要做**
1. 给核心 Service 写单测
2. 整理一页"项目讲解"：技术栈、架构图、亮点、踩坑

---

## 双后端边界（时刻记住）

- **Spring Boot = 核心**：权威数据在 MySQL，双端都走
- **微信云开发 = 外挂**：仅微信端（登录 openid 同步 / 结果图存储 / 订阅消息 / 内容审核）
- **解耦前提**：
  1. 云开发不持有任何权威业务数据
  2. openid 必须同步回 Spring Boot 用户表（云开发 openid 与 code2Session 一致，迁移无碍）
  3. 一次请求只打一个后端，不跨后端做事务
  4. 云开发调用在 uni-app 用 `#ifdef MP-WEIXIN` + 独立模块隔离，便于整体拔除

## 学习建议

- 每步先自己查官方文档 / 搜索，再带具体问题来问
- 代码提交用 git，写清楚 commit message
- 遇到报错，先把完整报错贴给我，别只说"跑不起来"
- 简历项目最怕"代做感"：每个功能都要你自己写、自己讲
