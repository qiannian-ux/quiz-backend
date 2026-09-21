# session_key 落地加密设计文档

> 关联：微信虚拟支付（`PayService` / `VPaySign`）、登录（`AuthService` / `WxAuthService`）
> 状态：已落地（2026-09-20）

## 1. 目的与背景
`session_key` 是微信/抖音在 `code2Session` 时下发给服务端的「用户登录凭证」，等同用户密码。它用于计算虚拟支付的**用户态签名 `signature`**，向微信证明「这笔支付是用户 X 本人授权的」。

此前 `session_key` **明文**存于 `user_platform.session_key`。一旦数据库被拖（SQL 注入、备份文件泄露、云桶误配公网、内鬼），攻击者可拿任意用户的 `session_key` 冒充其签支付、解锁付费内容。

本设计对 `session_key` 做**落地加密（at-rest encryption）**：库里只存密文，密钥只在服务端，把「只丢库」与「全盘崩溃」隔开。

## 2. 威胁模型
- **防御目标**：数据库层泄露（最常见、最该防的泄露途径）。
- **不防御**：服务器被 RCE、或密钥与库一同泄露。它只是纵深防御的一层，不是银弹。
- **不解决**：前端 `storage.premium` 客户端判定可被 patch 绕过——那是客户端闸门的固有局限，与本加密正交（entitlement 后续应由后端下发）。

## 3. 方案概述
- **算法**：AES-256-CBC。
- **密钥**：专用配置 `session.encrypt-key`，**必须显式配置，不回退 `jwt.secret`**（与 `jwt.secret` 配置方式一致：dev 环境变量、prod 写 gitignored 文件）。
- **密钥归一化**：无论配置串多长，均经 SHA-256 哈希成固定 32 字节 → AES-256。
- **格式**：随机 16 字节 IV 前置 + 密文，整体 base64，再加 `v1:` 前缀标记版本。
- **落点**：仅 at-rest。内存中、调微信/下发前端时仍用明文；`session_key` 绝不返前端、不进 JWT。

## 4. 加密格式
```
存储值 = "v1:" + base64( IV(16字节) || AES-256-CBC( UTF8(session_key) ) )
```
- **IV**：每次加密用 `SecureRandom` 随机生成，无需保密，随密文一起存储；保证相同明文+不同 IV = 不同密文（防模式分析）。
- **填充**：PKCS5Padding，把明文补齐到 16 字节块整数倍。
- **`v1:` 前缀**：`decrypt` 据此区分「密文」与「历史明文」，实现存量兼容。

## 5. 密钥管理
- **dev**：`application.properties` 中 `session.encrypt-key=${SESSION_ENCRYPT_KEY}`（无默认值 → 未设则 Spring 启动即失败，强制配置）。
- **prod**：在 `application-prod.properties`（已被 `.gitignore` 排除，不入库）设 `session.encrypt-key=<随机串>`。
- **生成**：`node tools/gen-secret.js` 或 `openssl rand -hex 32`（32 字节随机 → 64 位十六进制）。
- **轮换**：更换密钥后，旧密文无法解密；存量用户重新登录（静默登录）即用新密钥重写 `session_key`。**上线前定好密钥，避免运行中切换**。

## 6. 数据流
- **登录存库**（`AuthService.login`）：新用户 `insert` 与老用户 `update` 两处均改为
  `up.setSessionKey(aesUtil.encrypt(session.sessionKey()))`。
- **支付读取**（`PayService.createOrder`）：
  `String sk = aesUtil.decrypt(up.getSessionKey());` 再用 `sk` 计算
  `VPaySign.calcSignature(signData, sk)`。
- **历史明文兼容**：`decrypt` 遇到无 `v1:` 前缀的值直接原样返回，老数据在下次静默登录时自动改写为密文，**无需数据迁移**。

## 7. 数据库变更
- `user_platform.session_key` 列宽 `VARCHAR(128)` → `VARCHAR(512)`（密文含前缀 + base64(IV+密文) 后更长，留足余量）。
- 变更位置：
  - `docs/schema-full.sql`（建表 DDL）
  - `docs/migrate-schema-fix.sql`（对「已存在」列加 `ALTER TABLE user_platform MODIFY COLUMN session_key VARCHAR(512) ...` 幂等语句；对缺列场景的 `__add_col` 也改为 512）
- 同步产物：`docs/db-full.sql` 由 `tools/build-db-full.js` 重新生成。

## 8. 涉及文件
| 类型 | 文件 |
|---|---|
| 新增 | `src/main/java/com/example/quiz/util/AesUtil.java` |
| 改 | `AuthService.java`（注入 AesUtil + 两处 encrypt） |
| 改 | `PayService.java`（注入 AesUtil + decrypt 后签名） |
| 改 | `src/main/resources/application.properties`（`session.encrypt-key`） |
| 改 | `docs/schema-full.sql`、`docs/migrate-schema-fix.sql`、`docs/db-full.sql` |
| 新增工具 | `tools/gen-secret.js`（生成密钥串） |

## 9. 验证建议
- **单元**：同 `session.encrypt-key` 加密→解密应还原；换密钥解密应失败（触发回退/报错）。
- **集成**：本地设 `SESSION_ENCRYPT_KEY` 启动 → 真机登录→下单，确认支付签名链路正常；查库确认 `user_platform.session_key` 为 `v1:...` 密文。
- **缺失配置**：未设 `SESSION_ENCRYPT_KEY` 后端应直接启动失败并给出清晰报错（fail-fast）。
