# 后端管理员面板 · 设计规格（网页由 AI 交付，接口/鉴权由你写）

> 配套：`docs/动态测评-后端可配置增删-重构思路.md` §3 B4 / §6 方式 B（免 SQL 增删测评）
> 关键澄清（2026-09-14 用户指正）：**不是在小程序前端做管理页**（uni-app 无此能力），而是**在 Spring Boot 后端本身挂一个网页**，管理员用浏览器打开即可可视化配置后端数据。
> 分工：
> - **网页管理台 `src/main/resources/static/admin.html`（已交付，AI 写）**——纯静态 HTML/CSS/JS，后端默认以 `/admin.html` 直接托管，无需额外前端工程。
> - **后端 .java 接口 / 鉴权 / `admin` 表 / `WebMvcConfig` 白名单（你自写）**——本文给精确契约与代码骨架。
> 目标：把"加 / 删 / 改一套测评"从"手敲 SQL"升级为"浏览器点几下"，且后端仍零代码改动。

---

## 1. 定位：它解决什么

`动态测评` 文档 §6 给了两种配置方式：
- **A（现在就在用）**：直接 SQL 操作 `quiz` 表（INSERT / `UPDATE status=0` 软删）。
- **B（本面板）**：管理接口 + 后端托管网页，免 SQL。

本面板 = 方式 B 的服务端部分：**一组受管控的管理接口 + 一个后端自带的网页 UI**。管理员打开 `https://wangwang2.asia/admin.html` 即可增删改查，不必碰生产库。
注意：即便有了面板，**方式 A 的 SQL 仍要保留**作为应急 / 批量灌库手段（你已在用 CSV→SQL 灌 MBTI 题库）。

---

## 1.5 网页管理台 `admin.html`（已交付，可直接用）

| 项 | 说明 |
|----|------|
| 文件 | `src/main/resources/static/admin.html`（已写入项目） |
| 访问 | Spring Boot 默认托管 `static/**` → 部署后浏览器开 `https://<域名>/admin.html` 即可；本地 `http://localhost:8080/admin.html` |
| 美化访问 | 想用 `/admin`（不带 .html）可在 `WebMvcConfig` 加一个 `ViewController`：`registry.addViewController("/admin").setViewName("forward:/admin.html")` |
| 能力 | 登录（调 `/api/admin/login`）→ 测评列表（含下线）→ 新建 / 编辑（表单）→ 上线 / 下线；token 存 sessionStorage，401 自动回登录 |
| 依赖 | 纯原生 JS，**无任何 CDN / 框架**，断网也能跑；只调下面 §3 的 6 个接口 |
| 负责人 | **AI 已交付**；你只需把后端接口按契约实现，网页即连通 |

> 网页调用的接口契约（后端必须对齐）：
> - `POST /api/admin/login` 入参 `{username,password}`，成功返回 `{token:"..."}`（网页兼容 `{data:{token}}` 等形态）。
> - `GET  /api/admin/quiz` 返回**全部**测评（含 `status=0`），数组；网页按 `sortOrder` 排序展示，并区分上线/下线徽标。
> - `POST /api/admin/quiz`、`PUT /api/admin/quiz/{code}`、`POST /api/admin/quiz/{code}/off`、`POST /api/admin/quiz/{code}/on` 见 §3。
> 字段名与 `Quiz` 实体一致（`code/name/subtitle/emoji/tag/sortOrder/questionCount/priceCoin/coverUrl/description/status`），网页对缺字段有容错。

---

## 2. 鉴权方案（二选一，推荐 B）

管理接口绝不能被游客访问。现有 `JwtInterceptor` 只校验"普通用户 JWT"，**不能复用**给管理员——管理员需要更强的权限标识。

### 方案 A · 简单 Header Token（MVP，10 分钟）
- 后端读环境变量 `ADMIN_TOKEN`（部署时配，别进 Git）。
- 新增 `AdminInterceptor`，拦截 `/api/admin/**`，校验请求头 `X-Admin-Token: <ADMIN_TOKEN>`。
- 不存管理员表，无登录态。适合自用 / 演示。

```java
// interceptor/AdminInterceptor.java（骨架）
@Component
public class AdminInterceptor implements HandlerInterceptor {
    @Value("${app.admin-token:}")
    private String adminToken;

    public boolean preHandle(HttpServletRequest req, HttpServletResponse resp, Object h) throws Exception {
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;
        String t = req.getHeader("X-Admin-Token");
        if (t == null || !t.equals(adminToken)) { write401(resp, "无管理员权限"); return false; }
        return true;
    }
    private void write401(HttpServletResponse resp, String msg) throws IOException { /* 同 JwtInterceptor 写法 */ }
}
```

### 方案 B · 管理员登录 + 角色 JWT（推荐，简历好看）
- 新增 `admin` 表（`id / username / password_hash / created_at`）。
- `POST /api/admin/login` 校验账号密码 → 签发带 `role=ADMIN` 的 JWT（复用现有 `JwtUtil`，claim 里加 `role`）。
- `AdminInterceptor` 同样拦 `/api/admin/**`，但改为解 JWT 并校验 `role == ADMIN`。
- 普通用户 JWT 没有 `role=ADMIN` → 调管理接口会被拦。权限模型更"真"。

```java
// interceptor/AdminInterceptor.java（骨架，方案 B）
@Component
public class AdminInterceptor implements HandlerInterceptor {
    private final JwtUtil jwtUtil;
    public boolean preHandle(...) throws Exception {
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;
        String auth = req.getHeader("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) { write401(resp,"未登录"); return false; }
        try {
            Claims c = jwtUtil.parse(auth.substring(7));
            if (!"ADMIN".equals(c.get("role"))) { write401(resp,"非管理员"); return false; }
            return true;
        } catch (Exception e) { write401(resp,"登录已失效"); return false; }
    }
}
```

> ⚠️ **注册拦截器 + 白名单**（方案 B 最易踩的坑）：
> 1. `WebMvcConfig` 给 `AdminInterceptor` 挂 `addPathPatterns("/api/admin/**")`，并 **`excludePathPatterns("/api/admin/login")`**（登录接口不能要求已登录）。
> 2. 现有的 `JwtInterceptor` 匹配 `/api/**`，**必须把它白名单补上 `/api/admin/login`**，否则管理员调登录也会被普通用户 JWT 拦截器拦掉（报 401 未登录）。最终白名单 = `/api/auth/login`、`/api/quiz/**`、`/api/admin/login`。
> 3. 拦截器顺序：`JwtInterceptor`（放行 login）在前，`AdminInterceptor`（校验 role=ADMIN）在后。除 login 外所有 `/api/admin/**` 都过 `AdminInterceptor`。
<arg_key:6124c78e>replace_all</arg_key:6124c78e>
<arg_value:6124c78e>false

---

## 3. 接口清单（按 scope 分级）

| Scope | 方法 | 路径 | 说明 | 是否必做 |
|-------|------|------|------|----------|
| 测评本体 | POST | `/api/admin/login` | 管理员登录，签 admin JWT | 必做（鉴权入口） |
| 测评本体 | GET | `/api/admin/quiz` | 列出**全部**测评（含下线），网页用 | 必做 |
| 测评本体 | POST | `/api/admin/quiz` | 新建测评（写 `quiz` 一行） | 必做 |
| 测评本体 | PUT | `/api/admin/quiz/{code}` | 改名称/副标题/emoji/tag/sort_order/price_coin | 必做 |
| 测评本体 | POST | `/api/admin/quiz/{code}/off` | 软删 `status=0` | 必做 |
| 测评本体 | POST | `/api/admin/quiz/{code}/on` | 重新上线 `status=1` | 必做 |
| 内容层 | POST | `/api/admin/quiz/{code}/dimension` | 加维度（pair_code/pair_order/name） | 选做 |
| 内容层 | POST | `/api/admin/quiz/{code}/question` | 加题目（含 options 批量） | 选做（重头） |
| 内容层 | POST | `/api/admin/quiz/{code}/result` | 加结果映射（如 16 型） | 选做 |
| 功能开关 | POST | `/api/admin/config` | 切换 feature flag（对应 R4 `GET /api/config`） | 选做 |

> **必做 4 个** = "免 SQL 上下线 / 改展示信息"，已覆盖日常运营 80% 场景。
> **内容层 CRUD** 才是"真正免 SQL 配一套新测评"——但它要把 `动态测评` 文档里"CSV 灌库"那套逻辑搬成接口，工作量最大，**建议放第二阶段**。MBTI 已经用 SQL 灌好了，不必回退。

---

## 4. 数据库变更

- **方案 A**：无需新表，只在部署环境配 `ADMIN_TOKEN` 环境变量。
- **方案 B**：新增 `admin` 表（幂等建表，复用你之前的 `information_schema` 写法）：

```sql
-- docs/admin-table.sql（幂等，可重复执行；方案 B 才需要）
CREATE TABLE IF NOT EXISTS `admin` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(32) NOT NULL UNIQUE COMMENT '登录账号',
  `password_hash` VARCHAR(128) NOT NULL COMMENT 'bcrypt/MD5 加盐，别存明文',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 首次插入一个管理员（密码用你本地哈希后的值，别写明文）
-- INSERT INTO admin(username, password_hash) VALUES ('kaqiu', '<bcrypt-hash>');
```

内容层表（`dimension` / `question` / `question_option` / `quiz_result`）**已经存在**，面板只是往里写数据，不用新建。

---

## 5. 后端代码骨架（你实现）

```java
// dto/QuizCreateReq.java
@Data
public class QuizCreateReq {
    private String code;       // 唯一业务编码，如 enneagram
    private String name;
    private String subtitle;
    private String description;
    private String coverUrl;
    private String emoji;      // 🃏
    private String tag;        // 性格/职业/情感/能力
    private Integer sortOrder; // 越小越靠前
    private Integer questionCount;
    private Integer priceCoin; // 0=免费
    // status 新建默认 1
}

// controller/AdminQuizController.java
@RestController
@RequestMapping("/api/admin")
public class AdminQuizController {
    private final QuizService quizService;
    // POST /quiz            -> quizService.create(req)
    // PUT  /quiz/{code}     -> quizService.update(code, req)
    // POST /quiz/{code}/off -> quizService.setStatus(code, 0)
    // POST /quiz/{code}/on  -> quizService.setStatus(code, 1)
}

// service/QuizService.java 新增
public Long create(QuizCreateReq req) { /* 校验 code 不重复 → insert → 返回 id */ }
public void update(String code, QuizCreateReq req) { /* 按 code 查 id 再 update */ }
public void setStatus(String code, int status) { /* UPDATE quiz SET status=? WHERE code=? */ }
```

> 复用现有 `QuizMapper`（MyBatis-Plus `LambdaUpdateWrapper` 即可，`setStatus` 一行搞定）。`create` 注意 `code` 唯一约束冲突要抛友好错误。

---

## 6. 安全红线（务必遵守）

- [ ] `/api/admin/**` **绝不**出现在 JWT `excludePathPatterns` 里（现在白名单只有 `auth/login` 和 `quiz/**`，本就安全，但加拦截器时别手滑放行）。
- [ ] `ADMIN_TOKEN` / 管理员密码**只进环境变量或密钥管理，不进 Git、不进前端**。
- [ ] 管理接口不返回 `session_key` / `AppSecret` 等任何密钥。
- [ ] `password_hash` 必须加盐哈希，接口不回显明文。
- [ ] 写操作建议加一行操作日志（谁、什么时间、改了哪个 code），方便排查——`user_quiz_record` 之外可加 `admin_log` 表（选做）。

---

## 7. 与现有进度的关系

- 已落地：`GET /api/quiz/list`（游客公开）、`quiz` 表 `emoji/tag/sort_order` 字段、前端首页数据驱动。
- 本面板是在"已有列表能力"之上，**加一层受管控的写入口**。读接口不变，写接口新增。
- 前端若要配套"管理页"，那是前端活（归我）；但**先有后端接口，前端页才有得调**。建议后端面板先以 Postman/curl 验证，前端管理页作为下一阶段。

---

## 8. 验收清单（你自测）

- [ ] `/api/admin/quiz` 无 token / 错 token 返回 401，正确 token 才能写。
- [ ] 新建一个 `code=test_demo` 的测评（status=1）→ 首页 `GET /api/quiz/list` 立即出现。
- [ ] `POST /quiz/test_demo/off` → 列表消失，但 `user_quiz_record` 里若有人测过仍保留（软删验证）。
- [ ] `POST /quiz/test_demo/on` → 重新出现。
- [ ] `PUT /quiz/test_demo` 改 `emoji`/`sortOrder` → 列表顺序/图标同步变。
- [ ] （选做）内容层接口能免 SQL 插入一套新测评的题目与结果，且前端 `calcResult` 能算（非 MBTI 需后端给结果映射）。
- [ ] 部署环境 `ADMIN_TOKEN` 已配，本地代码不含明文。

---

## 9. 本次确认范围（2026-09-14）

用户拍板，落地以本節为准：

| 项 | 决定 |
|----|------|
| 鉴权 | **方案 B**：`admin` 表 + `POST /api/admin/login` 签发带 `role=ADMIN` 的 JWT；`AdminInterceptor` 校验 role |
| 接口范围 | **仅测评本体 CRUD 4 个**：建 / 改 / 软删下线 / 重新上线。**内容层 CRUD 与功能开关本期不做** |
| 前端管理页 | **先不做**；后端接口以 Postman / curl 验证，前端管理页留待下一阶段（归 AI 写） |

### 9.1 你实现时的两件关键活（已在 §2、§4/§5 体现，这里再点一遍）

1. **`JwtUtil` 要支持 role claim**：现有 `JwtUtil` 只存 `userId`。需新增 `generateAdminToken(username)` 或在 `generate` 里加 `role` 声明；`AdminInterceptor` 用 `claims.get("role")` 校验。普通用户 JWT 不带 `role` → 调 `/api/admin/**` 被拦。
2. **`WebMvcConfig` 白名单补 `/api/admin/login`**（见 §2 三步走），否则管理员登录被 `JwtInterceptor` 卡 401。

### 9.2 最终接口表（锁定）

| 方法 | 路径 | 入参 | 行为 | 网页是否调用 |
|------|------|------|------|--------------|
| POST | `/api/admin/login` | `{username, password}` | 校验 `admin` 表 → 返回 admin JWT（**免用户 JWT**，已在白名单） | ✅ 登录 |
| GET | `/api/admin/quiz` | — | 返回**全部**测评（含 `status=0`），数组 | ✅ 列表 |
| POST | `/api/admin/quiz` | `QuizCreateReq` | 校验 `code` 唯一 → `INSERT quiz(status=1)` → 返回 id | ✅ 新建 |
| PUT | `/api/admin/quiz/{code}` | `QuizCreateReq`（部分字段） | 按 `code` 查 id → `UPDATE` 展示字段 | ✅ 编辑 |
| POST | `/api/admin/quiz/{code}/off` | — | `UPDATE quiz SET status=0 WHERE code=?`（软删） | ✅ 下线 |
| POST | `/api/admin/quiz/{code}/on` | — | `UPDATE quiz SET status=1 WHERE code=?` | ✅ 上线 |

> 除 `login` 外，其余 5 个都要先过 `AdminInterceptor`（role=ADMIN）。
> 新增测评后**内容层**（dimension/question/option/result）本期仍用你已有的 CSV→SQL 灌库脚本补，不在面板里做。
> **网页 `admin.html` 已交付**：把它随后端一起打包部署，访问 `/admin.html` 即连上面 6 个接口。

---

## 10. 安全部署建议（2026-09-14 补充 · 零公网暴露）

> 用户关切：公开登录口有被爆破风险。结论：**面板可以只跑在本地/私网，生产公网不暴露入口**，兼顾方便与安全。

**核心思路：用 Spring Profile 把 admin 隔离，生产不激活**

1. `AdminLoginController` / `AdminQuizController` / `AdminInterceptor` 的注册全部加 `@Profile("admin")`。
   - 公网 production 用默认 profile 启动 → `/api/admin/**` 根本不注册。即便 `admin.html` 静态文件在 jar 里，调接口全 404，登录框是摆设，**无有效攻击面**。
   - 本地/私网启动时加 `-Dspring.profiles.active=admin` → admin 接口与拦截器生效。
2. 网页 `admin.html` 留在 `static/`（无害，没接口就是个空壳），无需按 profile 拆分。

**两种零暴露运行方式（任选）**

| 方式 | 做法 | 暴露面 |
|------|------|--------|
| A 纯本地 | 笔记本起 Spring Boot（`admin` profile），连**本地 MySQL** 或 **SSH 隧道 3307 连生产库**；浏览器开 `http://localhost:8080/admin.html` 配置 | 仅本机，外网不可达 |
| B 服务器私网 | 生产服务器上用 `localhost` 访问；用 `ssh -L 8080:localhost:8080 user@host` 把服务器 8080 映射到本机，admin 不绑公网 IP | 仅私网/隧道，外网扫不到 |

两种方式都**写同一库** → 改完生产实例即刻读到，和"线上直接配"效果一样，但没有公开登录口。

**即便只本地跑，也建议的好习惯**（成本低、防手滑）
- 管理员密码 bcrypt 加盐哈希，接口不回显明文
- 登录加频率限制 / 失败锁
- admin JWT 短过期（如 2h）

### 10.1 阿里云 ECS 实操（公网 IP / 私网 IP 分清）

一台阿里云 ECS 同时有几种"地址"，先分清：
- **公网 IP**：`wangwang2.asia` 解析到的那个 → 互联网任何人能访问（小程序用户走它）。
- **私网 IP**：形如 `172.16.x.x` / `10.x.x.x` → 只在阿里云内网互通，外网摸不到。
- **localhost（127.0.0.1）**：只有这台机器自己能访问。

> "私网/本地配置"的本质 = **管理入口不绑公网 IP**，不是非要在服务器私网 IP 上跑。

**对你最省心（本地跑 + 隧道连库，推荐）**
1. 生产（阿里云）：默认 profile 启动 → admin 接口不注册，公网只服务小程序。✅ 已无 admin 入口。
2. 你电脑：另起一个后端进程，`-Dspring.profiles.active=admin`，连阿里云 MySQL 走你已在用的 **SSH 隧道**（本机 3307 → 服务器 3306）。
3. 浏览器开 `http://localhost:8080/admin.html` 配置。写的是同一库，生产即时生效；**公网无任何 admin 入口**。

隧道命令示意（联调同理）：
```bash
ssh -N -L 3307:localhost:3306 你的阿里云用户@wangwang2.asia
# 后端 datasource 配 jdbc:mysql://127.0.0.1:3307/guiz
```

**若坚持在阿里云服务器本机开 admin**（避坑：别和生产 8080 抢端口）
- admin profile 另设 `server.port=8081` 且绑 `127.0.0.1`（或私网 IP），安全组**不要**对公网开 8081。
- 再用 SSH 隧道把服务器本地 8081 映射到你电脑：
```bash
ssh -N -L 8081:localhost:8081 你的阿里云用户@wangwang2.asia
# 电脑浏览器开 http://localhost:8081/admin.html
```
- 流量走加密隧道，公网不可达；生产 8080 照常公开服务小程序。

> 不这么做（直接把 admin 挂公网 + 弱密码 + 无限制）才是真危险；按本节方式则风险可控，且爆炸半径本就只限 `quiz` 配置表（不碰用户答案/支付）。

> 除 `login` 外，其余 4 个都要先过 `AdminInterceptor`（role=ADMIN）。
> 新增测评后**内容层**（dimension/question/option/result）本期仍用你已有的 CSV→SQL 灌库脚本补，不在面板里做。
