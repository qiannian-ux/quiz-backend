-- =============================================================================
-- 探我趣测 · 数据库全集（db-full.sql）
-- -----------------------------------------------------------------------------
-- 由 tools/build-db-full.js 自动合并生成，源文件保持独立可单跑。
-- 用法（开 SSH 隧道 3307 或登服务器直接跑）：
--   mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/db-full.sql
--
-- ⚠️ 说明：
--   1) 本文件对「结构」幂等（IF NOT EXISTS / 列不存在才 ADD），可重复执行。
--   2) 第一节会 DROP 重建 question/question_option；第五、七节分别清 quiz_id=1(MBTI)
--      和 quiz_id=2(DISC) 再重插——这两个测评的题库每次跑都会重置为种子值。
--      若库里已有【其他测评】的题目/作答，先备份再执行。
--   3) 算分模型见 quiz.scoring_model：PAIR=对撞取大(MBTI)、MAX=累加取最高(DISC)、
--      TOP3=取前三拼码(霍兰德)。双档解析在 quiz_result.basic_report/advanced_report。
--   4) 改完任一源文件后，重跑 node tools/build-db-full.js 重新生成本文件即可。
-- =============================================================================



-- =============================================================================
-- 一、全量表结构（9 张表）
-- -----------------------------------------------------------------------------
-- 本地和线上首次建库跑这一个；全部 IF NOT EXISTS。question/question_option 先 DROP 再建（M3 旧结构清理）。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · 全量表结构（M4 用户体系 + M5 测评领域模型）
-- 数据库：MySQL 8.0      字符集：utf8mb4
-- 用法：本地和服务器都跑这一个文件，可重复执行（全部 IF NOT EXISTS）
-- 生成日期：2026-09-09
-- =============================================================================
-- 设计主轴：内容层（quiz / dimension / question / question_option / quiz_result）
--          与数据层（user_quiz_record / user_quiz_answer）彻底分离。
--          加新测评 = 往内容层插数据，不改代码、不发版。
-- =============================================================================

SET NAMES utf8mb4;


-- =============================================================================
-- 一、用户体系（M4 已有，本文件补齐，否则线上部署会缺表）
-- =============================================================================

-- 用户主表：业务身份。一个真人在这里只有一行，不管他从微信还是抖音进来。
CREATE TABLE IF NOT EXISTS `user` (
  `id`           BIGINT      NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `coin_balance` BIGINT      NOT NULL DEFAULT 0      COMMENT '探币余额（广告得币 + 充值共用）',
  `created_at`   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户主表';

-- 平台身份表：同一个人在微信和抖音有各自独立的 openid，无法互通，
-- 所以「一个人」= user 一行 + user_platform 一到两行。
CREATE TABLE IF NOT EXISTS `user_platform` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT       NOT NULL                COMMENT '关联 user.id',
  `platform`    VARCHAR(16)  NOT NULL                COMMENT 'weixin / toutiao',
  `openid`      VARCHAR(64)  NOT NULL                COMMENT '该平台下的唯一标识',
  `session_key` VARCHAR(512) NOT NULL DEFAULT ''     COMMENT '微信会话密钥，虚拟支付签名必需；严禁下发给前端',
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_platform_openid` (`platform`, `openid`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='平台身份表';


-- =============================================================================
-- 二、内容层：测评本体
-- =============================================================================

-- 测评定义。MBTI 是一行，将来九型人格、色彩性格各插一行即可。
CREATE TABLE IF NOT EXISTS `quiz` (
  `id`             BIGINT       NOT NULL AUTO_INCREMENT,
  `code`           VARCHAR(32)  NOT NULL                COMMENT '业务编码，代码里用它查，如 mbti',
  `name`           VARCHAR(64)  NOT NULL                COMMENT '展示名，如 MBTI 性格类型测试',
  `subtitle`       VARCHAR(128) NOT NULL DEFAULT ''     COMMENT '副标题 / 一句话钩子',
  `description`    TEXT                                 COMMENT '详情页介绍',
  `cover_url`      VARCHAR(255) NOT NULL DEFAULT ''     COMMENT '封面图',
  `emoji`         VARCHAR(16)  NOT NULL DEFAULT ''     COMMENT '卡片图标 emoji',
  `tag`           VARCHAR(16)  NOT NULL DEFAULT ''     COMMENT '分类标签：性格/职业/情感/能力',
  `sort_order`    INT          NOT NULL DEFAULT 0      COMMENT '首页展示顺序，越小越靠前',
  `question_count` INT          NOT NULL DEFAULT 0      COMMENT '一次抽几题，0 表示全出',
  `price_coin`     INT          NOT NULL DEFAULT 0      COMMENT '解锁完整报告所需探币，0 表示免费',
  `scoring_model`  VARCHAR(16)  NOT NULL DEFAULT 'PAIR' COMMENT '算分模型：PAIR=按 pair_code 分组对撞取大，拼出多字母码（MBTI）；MAX=各类型维度累加取最高分（DISC/九型/依恋）；TOP3=累加取前三拼码（霍兰德 RIASEC）',
  `status`         TINYINT      NOT NULL DEFAULT 1      COMMENT '1 上线，0 下线',
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='测评定义表';

-- 维度定义。MBTI 有 8 个：E/I/S/N/T/F/J/P。
-- pair_code 是关键：它把互相对撞的两个维度配成一对（E 和 I 都是 'EI'），
-- 算分时按 pair_code 分组比大小，谁分高取谁。没有这个字段就不知道 E 该跟谁比。
CREATE TABLE IF NOT EXISTS `dimension` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT,
  `quiz_id`    BIGINT      NOT NULL                COMMENT '关联 quiz.id',
  `code`       VARCHAR(16) NOT NULL                COMMENT '维度码，如 E',
  `name`       VARCHAR(32) NOT NULL DEFAULT ''     COMMENT '维度名，如 外向',
  `pair_code`  VARCHAR(16) NOT NULL                COMMENT '维度对编码，如 EI —— 用于结果对撞',
  `pair_order` INT         NOT NULL DEFAULT 0      COMMENT '维度对序号，决定结果码里字母的位置。MBTI：1=EI 2=SN 3=TF 4=JP。不能靠 pair_code 字母序排，否则会拼成 EJST 而不是 ESTJ',
  `created_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_quiz_code` (`quiz_id`, `code`),
  KEY `idx_pair` (`quiz_id`, `pair_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='维度定义表';

-- 【题目表 question 和选项表 question_option 放在下面的第四节】
-- 原因：M3 练手版留下的同名表字段不对（只有 id + title），必须先 DROP 再重建，
-- 所以不能在这里用 IF NOT EXISTS 直接建，否则建完立刻被删。

-- 结果类型。MBTI 是 16 行（INFP、ENTJ …）。
-- 放数据库而不是写死在前端：文案想改随时改，不用重新发版审核。
CREATE TABLE IF NOT EXISTS `quiz_result` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `quiz_id`    BIGINT       NOT NULL                COMMENT '关联 quiz.id',
  `type_code`  VARCHAR(16)  NOT NULL                COMMENT '结果码，如 INFP',
  `name`       VARCHAR(32)  NOT NULL DEFAULT ''     COMMENT '结果名，如 调停者',
  `summary`    VARCHAR(255) NOT NULL DEFAULT ''     COMMENT '一句话总结，分享卡片用',
  `detail`     TEXT                                 COMMENT '详细解读',
  `image_url`  VARCHAR(255) NOT NULL DEFAULT ''     COMMENT '结果图，建议命名与 type_code 一致',
  `traits`     JSON                                 COMMENT '扩展：优势 / 短板 / 适合方向',
  `basic_report`    JSON                         COMMENT '初级解析：{one_liner,traits[],strengths[],weaknesses[],tip}',
  `advanced_report` JSON                         COMMENT '高级解析：{chapters:[{title,content}],career[],famous}',
  `sort_order` INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_quiz_type` (`quiz_id`, `type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='测评结果类型表';


-- =============================================================================
-- 三、数据层：用户作答
-- =============================================================================

-- 一次测评的记录。user_id 允许为空 = 游客也能测。
-- 为什么允许游客：你现在的登录是静默的，失败就降级成游客，
-- 这时不能把人拦在门外，否则一进小程序白屏 = 直接流失。
CREATE TABLE IF NOT EXISTS `user_quiz_record` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT      NULL                 COMMENT '关联 user.id，游客为 NULL',
  `quiz_id`     BIGINT      NOT NULL,
  `result_code` VARCHAR(16) NOT NULL DEFAULT ''  COMMENT '算出的结果码，如 INFP',
  `score_json`  JSON                             COMMENT '各维度得分明细，如 {"E":18,"I":5,...}',
  `duration_ms` INT         NOT NULL DEFAULT 0   COMMENT '用时，运营分析用',
  `created_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_time` (`user_id`, `created_at`),
  KEY `idx_quiz_time` (`quiz_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户测评记录表';

-- 每题的作答明细。存在这张表，用户就能回看「我上次选了什么」——
-- 这是分享率最高的功能之一，也是作品集里能拿出来说的亮点。
CREATE TABLE IF NOT EXISTS `user_quiz_answer` (
  `id`          BIGINT   NOT NULL AUTO_INCREMENT,
  `record_id`   BIGINT   NOT NULL                COMMENT '关联 user_quiz_record.id',
  `question_id` BIGINT   NOT NULL,
  `option_id`   BIGINT   NOT NULL                COMMENT '用户实际选的选项',
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_record` (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户作答明细表';


-- =============================================================================
-- 四、清理 M3 练手版的两张表
-- -----------------------------------------------------------------------------
-- 警告：下面两条会删除数据。目前 question / question_option 里只有 M3 的测试数据，
-- 删掉没有损失。如果你线上已经存了真实题目，先备份再执行。
-- =============================================================================
DROP TABLE IF EXISTS `question_option`;
DROP TABLE IF EXISTS `question`;


-- 【以下为重建语句，配合上面的 DROP 使用】
-- 选项做成独立表而不是在 question 里写死 option_a / option_b，
-- 是为了兼容未来可能出现的李克特量表（非常不同意 → 非常同意，五档）。
-- MBTI 每题插两行即可。
CREATE TABLE IF NOT EXISTS `question` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `quiz_id`    BIGINT       NOT NULL                COMMENT '关联 quiz.id',
  `content`    VARCHAR(500) NOT NULL                COMMENT '题干',
  `sort_order` INT          NOT NULL DEFAULT 0      COMMENT '排序，越大越靠后',
  `status`     TINYINT      NOT NULL DEFAULT 1      COMMENT '1 启用，0 停用',
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_quiz_sort` (`quiz_id`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='题目表';

CREATE TABLE IF NOT EXISTS `question_option` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT,
  `question_id`  BIGINT       NOT NULL                COMMENT '关联 question.id',
  `content`      VARCHAR(255) NOT NULL                COMMENT '选项文案',
  `dimension_id` BIGINT       NOT NULL                COMMENT '选它给哪个维度加分，关联 dimension.id',
  `score`        INT          NOT NULL DEFAULT 1      COMMENT '该选项给维度的加分值',
  `sort_order`   INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_question` (`question_id`),
  KEY `idx_dimension` (`dimension_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='题目选项表';


-- =============================================================================
-- 二、生产库结构修正（幂等补齐缺失列）
-- -----------------------------------------------------------------------------
-- 线上库若是用不完整早期 schema 建的，这里把 quiz/dimension/.../user/user_platform 补齐到规范形态；已有列跳过，保留数据。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · 生产库结构修正（2026-09-20）
-- -----------------------------------------------------------------------------
-- 问题：线上 quiz 表缺列（如 emoji），代码实体期望 14 个字段，报错
--   "Unknown column 'emoji' in 'field list'"（所有 DB 接口一起 500）。
-- 根因：生产库是用一份不完整的早期 schema 建的，与当前代码实体对不上。
--
-- 本文件把所有表补齐到 schema-full.sql 的规范形态：
--   * quiz / dimension / quiz_result / user_quiz_record / user_quiz_answer
--     用「列不存在才 ADD」的方式补齐缺失列（幂等，已有列跳过，保留数据）。
--   * question / question_option：若仍是 M3 旧结构（有 title 列、无 content 列）
--     才 DROP+重建为规范结构；已是规范结构则不动。
--
-- 用法（需先开 SSH 隧道 3307，或登服务器直接跑）：
--   mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/migrate-schema-fix.sql
--   mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/seed-mbti.sql
-- 注意：改的是表结构，运行中的 jar 无需重启（下次查询即用新结构）。
-- =============================================================================
SET NAMES utf8mb4;

-- 通用工具：列不存在才 ADD（MySQL 没有 ADD COLUMN IF NOT EXISTS 语法）
DROP PROCEDURE IF EXISTS __add_col;
DELIMITER $$
CREATE PROCEDURE __add_col(
  IN p_table VARCHAR(64), IN p_col VARCHAR(64), IN p_def VARCHAR(512)
)
BEGIN
  -- 表存在且列不存在才 ADD（表本身不存在则跳过，避免 ALTER 报 "表不存在"）
  IF (SELECT COUNT(*) FROM information_schema.tables
      WHERE table_schema = DATABASE() AND table_name = p_table) > 0
     AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = p_table AND column_name = p_col
  ) THEN
    SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_col, '` ', p_def);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;

-- ---------- quiz：补齐可能缺失的列（新增列统一 nullable，避免对存量行要求 DEFAULT）----------
CALL __add_col('quiz', 'code',          'VARCHAR(32)');
CALL __add_col('quiz', 'name',          'VARCHAR(64)');
CALL __add_col('quiz', 'subtitle',      'VARCHAR(128)');
CALL __add_col('quiz', 'description',   'TEXT');
CALL __add_col('quiz', 'cover_url',     'VARCHAR(255)');
CALL __add_col('quiz', 'emoji',         'VARCHAR(16)');
CALL __add_col('quiz', 'tag',           'VARCHAR(16)');
CALL __add_col('quiz', 'sort_order',    'INT');
CALL __add_col('quiz', 'question_count', 'INT');
CALL __add_col('quiz', 'price_coin',    'INT');
CALL __add_col('quiz', 'status',        'TINYINT');
CALL __add_col('quiz', 'created_at',    'DATETIME');
CALL __add_col('quiz', 'updated_at',    'DATETIME');

-- ---------- dimension ----------
CALL __add_col('dimension', 'quiz_id',   'BIGINT');
CALL __add_col('dimension', 'code',      'VARCHAR(16)');
CALL __add_col('dimension', 'name',      'VARCHAR(32)');
CALL __add_col('dimension', 'pair_code', 'VARCHAR(16)');
CALL __add_col('dimension', 'pair_order','INT');
CALL __add_col('dimension', 'created_at','DATETIME');

-- ---------- quiz_result ----------
CALL __add_col('quiz_result', 'quiz_id',   'BIGINT');
CALL __add_col('quiz_result', 'type_code', 'VARCHAR(16)');
CALL __add_col('quiz_result', 'name',      'VARCHAR(32)');
CALL __add_col('quiz_result', 'summary',   'VARCHAR(255)');
CALL __add_col('quiz_result', 'detail',    'TEXT');
CALL __add_col('quiz_result', 'image_url', 'VARCHAR(255)');
CALL __add_col('quiz_result', 'traits',    'JSON');
CALL __add_col('quiz_result', 'sort_order','INT');

-- ---------- user_quiz_record ----------
CALL __add_col('user_quiz_record', 'user_id',     'BIGINT');
CALL __add_col('user_quiz_record', 'quiz_id',     'BIGINT');
CALL __add_col('user_quiz_record', 'result_code', 'VARCHAR(16)');
CALL __add_col('user_quiz_record', 'score_json',  'JSON');
CALL __add_col('user_quiz_record', 'duration_ms', 'INT');
CALL __add_col('user_quiz_record', 'created_at',  'DATETIME');

-- ---------- user_quiz_answer ----------
CALL __add_col('user_quiz_answer', 'record_id',  'BIGINT');
CALL __add_col('user_quiz_answer', 'question_id','BIGINT');
CALL __add_col('user_quiz_answer', 'option_id',  'BIGINT');
CALL __add_col('user_quiz_answer', 'created_at', 'DATETIME');

-- ---------- user / user_platform（登录链路，migrate 之前没覆盖，补齐以防早期 schema 缺列）----------
CALL __add_col('user',          'coin_balance', 'BIGINT');
CALL __add_col('user',          'created_at',   'DATETIME');
CALL __add_col('user_platform', 'user_id',     'BIGINT');
CALL __add_col('user_platform', 'platform',    'VARCHAR(16)');
CALL __add_col('user_platform', 'openid',      'VARCHAR(64)');
CALL __add_col('user_platform', 'session_key', 'VARCHAR(512)');
CALL __add_col('user_platform', 'updated_at',  'DATETIME');

-- session_key 改为落地加密后密文更长（"v1:" 前缀 + base64(IV+密文)），放大列宽避免截断；
-- 上面 __add_col 只在缺列时建 512，这里对"已存在"的列也 MODIFY 成 512（幂等，同定义重复执行无害）
ALTER TABLE `user_platform` MODIFY COLUMN `session_key` VARCHAR(512) NOT NULL DEFAULT '';

-- ---------- question / question_option：仅当仍是 M3 旧结构（有 title 列）才重建 ----------
DROP PROCEDURE IF EXISTS __fix_q_tables;
DELIMITER $$
CREATE PROCEDURE __fix_q_tables()
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'question' AND column_name = 'title'
  ) THEN
    DROP TABLE IF EXISTS `question_option`;
    DROP TABLE IF EXISTS `question`;
    CREATE TABLE `question` (
      `id`         BIGINT       NOT NULL AUTO_INCREMENT,
      `quiz_id`    BIGINT       NOT NULL,
      `content`    VARCHAR(500) NOT NULL,
      `sort_order` INT          NOT NULL DEFAULT 0,
      `status`     TINYINT      NOT NULL DEFAULT 1,
      `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `idx_quiz_sort` (`quiz_id`, `sort_order`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    CREATE TABLE `question_option` (
      `id`           BIGINT   NOT NULL AUTO_INCREMENT,
      `question_id`  BIGINT   NOT NULL,
      `content`      VARCHAR(255) NOT NULL,
      `dimension_id` BIGINT   NOT NULL,
      `score`        INT      NOT NULL DEFAULT 1,
      `sort_order`   INT      NOT NULL DEFAULT 0,
      PRIMARY KEY (`id`),
      KEY `idx_question` (`question_id`),
      KEY `idx_dimension` (`dimension_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  END IF;
END$$
DELIMITER ;
CALL __fix_q_tables();
DROP PROCEDURE IF EXISTS __fix_q_tables;

-- 清理工具过程
DROP PROCEDURE IF EXISTS __add_col;

-- 校验：打印 quiz 表现在的所有列，确认 emoji 等已补齐
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'quiz'
ORDER BY ORDINAL_POSITION;


-- =============================================================================
-- 三、双档解析 + 多测评算分模型（结构升级）
-- -----------------------------------------------------------------------------
-- 补 quiz.scoring_model（PAIR/MAX/TOP3）与 quiz_result.basic_report/advanced_report（初级解析 + 高级解析）。幂等，已有列跳过。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · 双档解析 + 多测评算分模型（结构升级，2026-09-20）
-- -----------------------------------------------------------------------------
-- 背景：
--   1) 旧 quiz_result 只有 summary/detail（两者内容还重复），traits 仅存
--      strengths/weaknesses/careers —— 太水，撑不起「初级解析 + 高级解析」两档。
--   2) 新增 DISC 等测评后，算分不再是 MBTI 那套「维度对撞」，
--      需要一个字段告诉后端用哪种模型算分。
--
-- 本文件补齐三个列（幂等：列已存在则跳过，保留数据）：
--   quiz.scoring_model         —— PAIR（默认，MBTI）/ MAX（DISC、九型、依恋）/ TOP3（霍兰德）
--   quiz_result.basic_report   —— 初级解析 JSON
--   quiz_result.advanced_report—— 高级解析 JSON
--
-- 用法（开 SSH 隧道 3307，或登服务器直接跑）：
--   mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/migrate-reports.sql
--   mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/seed-result-reports.sql   -- MBTI 双档解析
--   mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/seed-disc.sql             -- DISC 全套
-- 注意：只加列不动数据，运行中的 jar 无需重启。
-- =============================================================================
SET NAMES utf8mb4;

-- 通用工具：列不存在才 ADD（MySQL 没有 ADD COLUMN IF NOT EXISTS 语法）
DROP PROCEDURE IF EXISTS __add_col;
DELIMITER $$
CREATE PROCEDURE __add_col(
  IN p_table VARCHAR(64), IN p_col VARCHAR(64), IN p_def VARCHAR(512)
)
BEGIN
  IF (SELECT COUNT(*) FROM information_schema.tables
      WHERE table_schema = DATABASE() AND table_name = p_table) > 0
     AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = p_table AND column_name = p_col
  ) THEN
    SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_col, '` ', p_def);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;

-- ---------- quiz：算分模型 ----------
-- 存量 MBTI 行的默认值就是 PAIR，加完立刻正确，不需要再回填。
CALL __add_col('quiz', 'scoring_model',
  "VARCHAR(16) NOT NULL DEFAULT 'PAIR' COMMENT '算分模型：PAIR=对撞取大(MBTI)；MAX=累加取最高(DISC/九型)；TOP3=取前三拼码(霍兰德)'");

-- ---------- quiz_result：双档解析 ----------
CALL __add_col('quiz_result', 'basic_report',
  "JSON NULL COMMENT '初级解析：{one_liner,traits[],strengths[],weaknesses[],tip}'");
CALL __add_col('quiz_result', 'advanced_report',
  "JSON NULL COMMENT '高级解析：{chapters:[{title,content}],career[],famous}'");

-- 清理工具过程
DROP PROCEDURE IF EXISTS __add_col;

-- 校验：确认三列已就位
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, COLUMN_DEFAULT
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND COLUMN_NAME IN ('scoring_model', 'basic_report', 'advanced_report')
ORDER BY TABLE_NAME, COLUMN_NAME;


-- =============================================================================
-- 四、微信虚拟支付订单表
-- -----------------------------------------------------------------------------
-- 打赏 / 解锁全站付费流水。
-- =============================================================================

-- 支付订单表（微信虚拟支付：打赏 / 解锁全站）
-- 在 guiz 库执行，IF NOT EXISTS 可重复执行。
CREATE TABLE IF NOT EXISTS pay_order (
  id           BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id      BIGINT NULL,
  openid       VARCHAR(64),
  out_trade_no VARCHAR(32) NOT NULL,
  wx_order_id  VARCHAR(64),
  product_id   VARCHAR(32),
  amount_fen   INT,
  status       TINYINT NOT NULL DEFAULT 0,   -- 0 待支付 1 已发货 2 已退款
  attach       VARCHAR(255),
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_out_trade_no (out_trade_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =============================================================================
-- 五、MBTI 初始数据（题库 + 16 型结果）
-- -----------------------------------------------------------------------------
-- 开头清 quiz_id=1 再重插，可重复执行。改 CSV 后重跑本文件即可刷新题库。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · MBTI 初始数据（由 tools/import_mbti_csv.py 从 CSV 生成）
-- 可重复执行：开头会先清掉 quiz_id = 1 的全部内容
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 1);
DELETE FROM `question`        WHERE `quiz_id` = 1;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 1;
DELETE FROM `dimension`       WHERE `quiz_id` = 1;
DELETE FROM `quiz`            WHERE `id`      = 1;

-- 测评本体
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`question_count`,`price_coin`,`status`) VALUES
(1,'mbti','MBTI 性格类型测试','4 个维度，看清你的思维偏好','MBTI 通过外向/内向、实感/直觉、思考/情感、判断/感知四个维度，把人的认知偏好分成 16 种类型。它不是能力测试，没有好坏之分，只是描述你更倾向于如何获取信息、做决定。',0,0,1);

-- 维度定义（8 个，4 组对撞）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(1,1,'E','外向','EI',1),
(2,1,'I','内向','EI',1),
(3,1,'S','实感','SN',2),
(4,1,'N','直觉','SN',2),
(5,1,'T','思考','TF',3),
(6,1,'F','情感','TF',3),
(7,1,'J','判断','JP',4),
(8,1,'P','感知','JP',4);

-- 题目（93 道）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (2,1,'在社交聚会中，你通常会：',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(2,'主动与多人交谈，享受热闹氛围',1,1,0),
(2,'与少数几个人深入交流，或独自观察',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (3,1,'当你需要休息恢复精力时，你更倾向于：',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(3,'与朋友外出活动或聚会',1,1,0),
(3,'独自在家放松或做自己喜欢的事',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (4,1,'在团队讨论中，你通常：',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(4,'喜欢发表意见并参与热烈讨论',1,1,0),
(4,'更愿意倾听思考后再发言',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (5,1,'你更喜欢的周末是：',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(5,'参加聚会、活动或与朋友出游',1,1,0),
(5,'在家阅读、看电影或独自放松',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (6,1,'在陌生人面前，你通常会：',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(6,'感到自在，能很快融入交流',1,1,0),
(6,'感到有些拘谨，需要时间适应',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (7,1,'你认为自己是一个：',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(7,'外向、善于社交的人',1,1,0),
(7,'内向、喜欢独处的人',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (8,1,'在电话交谈中，你通常：',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(8,'乐于长时间聊天',1,1,0),
(8,'倾向于简短交流，喜欢面对面或文字',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (9,1,'当你有想法时，你倾向于：',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(9,'立即说出来与人讨论',1,1,0),
(9,'先在内心反复思考成熟后再表达',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (10,1,'在人群中，你通常会感到：',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(10,'精力充沛，充满活力',1,1,0),
(10,'精力消耗，需要独处恢复',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (11,1,'你更喜欢的工作环境是：',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(11,'开放式办公室，经常与同事交流',1,1,0),
(11,'安静独立的空间，专注工作',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (12,1,'参加活动后，你通常会：',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(12,'感到兴奋，想继续下一个活动',1,1,0),
(12,'感到疲惫，需要时间独处恢复',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (13,1,'你的朋友圈通常是：',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(13,'广泛，认识很多人',1,1,0),
(13,'精简，只有几个深交的朋友',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (14,1,'在解决问题时，你更倾向于：',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(14,'与他人讨论，集思广益',1,1,0),
(14,'独自思考，独立解决',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (15,1,'你更喜欢的沟通方式是：',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(15,'面对面交流或电话',1,1,0),
(15,'邮件、消息或书面沟通',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (16,1,'在聚会中，你更常扮演的角色是：',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(16,'活跃气氛的组织者',1,1,0),
(16,'安静倾听的参与者',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (17,1,'当你独处太久时，你会：',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(17,'感到无聊，想找人交流',1,1,0),
(17,'感到舒适，享受独处时光',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (18,1,'在新环境中，你通常会：',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(18,'主动认识新朋友',1,1,0),
(18,'等待他人接近或保持观察',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (19,1,'你认为自己是：',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(19,'一个表达者，喜欢分享想法',1,1,0),
(19,'一个思考者，喜欢深入思考',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (20,1,'在做决定前，你倾向于：',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(20,'与他人讨论听取意见',1,1,0),
(20,'自己独立思考分析',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (21,1,'你更喜欢：',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(21,'热闹繁忙的生活节奏',1,1,0),
(21,'安静平和的生活方式',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (22,1,'在会议中，你更倾向于：',21,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(22,'积极发言表达观点',1,1,0),
(22,'认真倾听，必要时才发言',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (23,1,'当你获得好成绩或成就时，你更想：',22,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(23,'与他人分享喜悦',1,1,0),
(23,'私下庆祝或默默满足',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (24,1,'你更喜欢的学习方式是：',23,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(24,'小组讨论或互动学习',1,1,0),
(24,'独立阅读或自学',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (25,1,'在社交场合，你更容易：',24,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(25,'开启话题，打破沉默',1,1,0),
(25,'等待他人主动交谈',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (26,1,'你更容易注意到：',25,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(26,'周围环境中的具体细节和实际信息',3,1,0),
(26,'事物的整体印象和隐藏的可能性',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (27,1,'在阅读时，你更偏好：',26,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(27,'具体的事实描述和实用信息',3,1,0),
(27,'抽象的概念探讨和理论分析',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (28,1,'在解决问题时，你倾向于：',27,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(28,'运用已验证的方法和经验',3,1,0),
(28,'尝试新的思路和创新方法',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (29,1,'你更信任：',28,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(29,'自己的亲身经验和实际观察',3,1,0),
(29,'直觉、灵感和第六感',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (30,1,'你认为作家应该：',29,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(30,'准确描述现实世界的细节',3,1,0),
(30,'发挥想象力创造新颖的世界',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (31,1,'在做计划时，你更关注：',30,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(31,'具体的步骤和实际操作',3,1,0),
(31,'整体的愿景和长远目标',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (32,1,'你更感兴趣的是：',31,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(32,'现实中正在发生的事情',3,1,0),
(32,'未来可能发生的变化',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (33,1,'在学习新技能时，你更倾向于：',32,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(33,'按部就班，先掌握基础',3,1,0),
(33,'跳跃式学习，先看整体',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (34,1,'你更喜欢的工作是：',33,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(34,'有明确流程和规范的工作',3,1,0),
(34,'需要创意和想象力的工作',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (35,1,'当你描述一件事时，你通常会：',34,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(35,'详细描述具体细节',3,1,0),
(35,'概括要点，描绘整体印象',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (36,1,'你更欣赏：',35,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(36,'实用性强、能解决问题的想法',3,1,0),
(36,'新颖独特、富有创意的想法',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (37,1,'面对新任务，你更倾向于：',36,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(37,'参照以往的成功经验',3,1,0),
(37,'寻找全新的解决方案',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (38,1,'你认为更重要的是：',37,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(38,'关注当下的实际情况',3,1,0),
(38,'思考未来的发展可能',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (39,1,'你更喜欢哪种类型的小说：',38,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(39,'真实背景的现实主义小说',3,1,0),
(39,'充满想象的科幻或奇幻小说',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (40,1,'在交流中，你更倾向于：',39,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(40,'使用具体的例子和事实',3,1,0),
(40,'使用比喻和抽象概念',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (41,1,'你更擅长：',40,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(41,'处理具体实际的事务',3,1,0),
(41,'发现潜在的机会和联系',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (42,1,'当别人说话太抽象时，你会：',41,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(42,'希望对方给出具体例子',3,1,0),
(42,'感到有趣，想继续探讨',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (43,1,'你更看重：',42,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(43,'事实和数据的准确性',3,1,0),
(43,'概念和理论的创新性',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (44,1,'在旅行时，你更倾向于：',43,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(44,'按照攻略参观著名景点',3,1,0),
(44,'探索未知，发现新奇体验',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (45,1,'你更容易被什么打动：',44,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(45,'真实感人的真实故事',3,1,0),
(45,'富有想象力的创意作品',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (46,1,'在观察事物时，你更容易：',45,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(46,'注意到细节和组成部分',3,1,0),
(46,'看到整体和内在联系',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (47,1,'你更喜欢的指导方式是：',46,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(47,'具体详细的操作步骤',3,1,0),
(47,'概括性的原则和方向',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (48,1,'你更相信：',47,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(48,'眼见为实的经验',3,1,0),
(48,'超越表象的洞察',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (49,1,'你更喜欢：',48,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(49,'按常规方式做事',3,1,0),
(49,'尝试新的方法',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (50,1,'在做决定时，你更看重：',49,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(50,'逻辑分析和客观标准',5,1,0),
(50,'他人感受和和谐关系',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (51,1,'当别人向你倾诉问题时，你会：',50,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(51,'提供解决方案和建议',5,1,0),
(51,'表达理解和情感支持',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (52,1,'你认为更好的领导方式是：',51,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(52,'公正客观，奖罚分明',5,1,0),
(52,'关心下属，注重人情',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (53,1,'在批评他人时，你倾向于：',52,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(53,'直接指出问题，对事不对人',5,1,0),
(53,'委婉表达，避免伤害感情',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (54,1,'你认为更重要的是：',53,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(54,'公平公正，一视同仁',5,1,0),
(54,'同情理解，因人而异',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (55,1,'在讨论问题时，你更倾向于：',54,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(55,'坚持自己的逻辑观点',5,1,0),
(55,'考虑他人的立场感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (56,1,'你更容易被什么说服：',55,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(56,'有逻辑的数据和事实',5,1,0),
(56,'真挚的情感和个人故事',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (57,1,'面对冲突时，你更倾向于：',56,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(57,'客观分析对错',5,1,0),
(57,'维护关系和谐',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (58,1,'你认为好的决定应该：',57,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(58,'基于理性的分析',5,1,0),
(58,'考虑到人的感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (59,1,'当朋友犯错时，你会：',58,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(59,'指出错误并分析原因',5,1,0),
(59,'先安慰再委婉提醒',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (60,1,'你更看重：',59,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(60,'效率和结果',5,1,0),
(60,'过程和体验',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (61,1,'在评价一件事时，你更关注：',60,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(61,'是否合理有效',5,1,0),
(61,'是否让人满意',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (62,1,'你更擅长：',61,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(62,'客观分析问题',5,1,0),
(62,'理解他人情感',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (63,1,'在做选择时，你更倾向于：',62,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(63,'权衡利弊得失',5,1,0),
(63,'听从内心的感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (64,1,'你认为团队管理应该：',63,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(64,'制定明确的规则标准',5,1,0),
(64,'营造和谐的氛围',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (65,1,'当别人情绪低落时，你会：',64,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(65,'帮助他们分析问题原因',5,1,0),
(65,'陪伴安慰，给予情感支持',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (66,1,'你更欣赏：',65,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(66,'理性冷静的人',5,1,0),
(66,'善良温暖的人',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (67,1,'在辩论中，你更注重：',66,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(67,'论点的逻辑正确性',5,1,0),
(67,'辩论的方式和态度',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (68,1,'你认为奖励应该基于：',67,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(68,'客观的业绩表现',5,1,0),
(68,'付出的努力和态度',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (69,1,'面对两难选择，你更倾向于：',68,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(69,'分析利弊，做出最优选择',5,1,0),
(69,'考虑对各方的影响',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (70,1,'你认为诚实和友善哪个更重要：',69,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(70,'诚实，说出真实想法',5,1,0),
(70,'友善，照顾他人感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (71,1,'在解决问题时，你更倾向于：',70,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(71,'用头脑分析',5,1,0),
(71,'用心感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (72,1,'你更不喜欢的场景是：',71,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(72,'逻辑混乱、毫无章法',5,1,0),
(72,'冷漠无情、缺乏关怀',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (73,1,'你更喜欢的工作方式是：',72,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(73,'制定详细计划并按计划执行',7,1,0),
(73,'保持灵活性，随机应变',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (74,1,'对于任务，你倾向于：',73,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(74,'提前完成，避免最后时刻的紧张',7,1,0),
(74,'在截止日期前完成，享受紧迫感',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (75,1,'你的书桌或房间通常是：',74,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(75,'整洁有序，物品摆放有规律',7,1,0),
(75,'相对随意，使用方便即可',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (76,1,'在旅行时，你更喜欢：',75,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(76,'提前规划行程和预订',7,1,0),
(76,'随性而为，到时再决定',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (77,1,'面对新任务，你倾向于：',76,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(77,'立即开始行动',7,1,0),
(77,'收集更多信息后再开始',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (78,1,'你更喜欢的日常生活是：',77,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(78,'按部就班，保持规律',7,1,0),
(78,'追求新鲜，尝试变化',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (79,1,'在完成项目时，你更倾向于：',78,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(79,'提前规划，按时完成',7,1,0),
(79,'在压力下工作效率更高',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (80,1,'你更看重：',79,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(80,'计划和确定性',7,1,0),
(80,'灵活和可能性',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (81,1,'当计划被打乱时，你会：',80,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(81,'感到不适，想尽快调整',7,1,0),
(81,'坦然接受，灵活应对',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (82,1,'你更倾向于：',81,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(82,'把事情安排得井井有条',7,1,0),
(82,'顺其自然，见机行事',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (83,1,'在会议中，你更希望：',82,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(83,'有明确的议程和时间安排',7,1,0),
(83,'开放式讨论，自由发挥',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (84,1,'你认为自己是一个：',83,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(84,'有计划、有条理的人',7,1,0),
(84,'随性、灵活的人',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (85,1,'对待截止日期，你更倾向于：',84,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(85,'提前很久完成',7,1,0),
(85,'在截止前一刻完成',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (86,1,'你更不喜欢的场景是：',85,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(86,'计划被打乱、充满变数',7,1,0),
(86,'过于死板、缺乏灵活性',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (87,1,'在做决定时，你更倾向于：',86,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(87,'尽快做出决定',7,1,0),
(87,'保留更多选择，暂不决定',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (88,1,'你更喜欢的周末安排是：',87,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(88,'提前计划好的活动',7,1,0),
(88,'看心情决定做什么',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (89,1,'对于规则，你更倾向于：',88,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(89,'遵守规则，按规章办事',7,1,0),
(89,'根据情况灵活处理',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (90,1,'你更擅长：',89,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(90,'制定计划并执行',7,1,0),
(90,'应对变化和突发情况',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (91,1,'你更欣赏：',90,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(91,'有始有终、善始善终的人',7,1,0),
(91,'思维活跃、创意不断的人',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (92,1,'在处理多件事情时，你更倾向于：',91,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(92,'一件一件按顺序完成',7,1,0),
(92,'同时处理，灵活切换',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (93,1,'你更看重的结果是：',92,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(93,'按计划达成目标',7,1,0),
(93,'享受过程中的发现',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (94,1,'对于未来，你更倾向于：',93,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(94,'有明确的规划和目标',7,1,0),
(94,'保持开放，顺其自然',8,1,1);

-- 结果类型（16 型）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'INTJ','建筑师','富有想象力和战略性的思想家，一切皆在计划之中。','富有想象力和战略性的思想家，一切皆在计划之中。','','{"strengths": ["战略思维", "独立思考", "意志坚定", "追求卓越", "善于规划"], "weaknesses": ["过于完美", "不善社交", "容易固执", "情感表达少", "过于挑剔"], "careers": ["科学家", "工程师", "系统分析师", "战略顾问", "投资分析师"]}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'INTP','逻辑学家','富有创造力的发明家，对知识有着永不满足的渴望。','富有创造力的发明家，对知识有着永不满足的渴望。','','{"strengths": ["逻辑分析", "创新思维", "客观公正", "求知欲强", "善于解决复杂问题"], "weaknesses": ["脱离现实", "不善表达", "拖延倾向", "过于理论化", "缺乏耐心"], "careers": ["哲学家", "科学家", "程序员", "数学家", "研究员"]}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ENTJ','指挥官','大胆、富有想象力的领导者，总能找到解决问题的方法。','大胆、富有想象力的领导者，总能找到解决问题的方法。','','{"strengths": ["领导才能", "决策果断", "自信坚定", "效率至上", "善于激励他人"], "weaknesses": ["控制欲强", "缺乏耐心", "忽视情感", "过于强势", "不善妥协"], "careers": ["企业高管", "律师", "项目经理", "创业者", "管理咨询顾问"]}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ENTP','辩论家','聪明好奇的思想家，无法抗拒智力上的挑战。','聪明好奇的思想家，无法抗拒智力上的挑战。','','{"strengths": ["思维敏捷", "善于辩论", "创新能力强", "适应力好", "多才多艺"], "weaknesses": ["喜欢争论", "缺乏耐心", "难以专注", "忽视细节", "容易厌倦"], "careers": ["律师", "记者", "创业者", "营销专家", "产品经理"]}',4);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'INFJ','提倡者','安静而有影响力，具有理想主义色彩，致力于帮助他人。','安静而有影响力，具有理想主义色彩，致力于帮助他人。','','{"strengths": ["洞察力强", "富有同情心", "追求意义", "理想主义", "善于理解他人"], "weaknesses": ["过于完美", "容易倦怠", "不善拒绝", "敏感脆弱", "难以释怀"], "careers": ["心理咨询师", "作家", "教育工作者", "社会工作者", "非营利组织管理者"]}',5);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'INFP','调解员','诗意、善良的利他主义者，总是渴望帮助良善之事。','诗意、善良的利他主义者，总是渴望帮助良善之事。','','{"strengths": ["创意丰富", "富有同理心", "价值观坚定", "善于倾听", "追求和谐"], "weaknesses": ["过于理想化", "不善实际", "敏感易伤", "拖延倾向", "难以承受批评"], "careers": ["作家", "艺术家", "心理咨询师", "设计师", "社会工作者"]}',6);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ENFJ','主人公','富有魅力的激励者，能够引领听众走向美好明天。','富有魅力的激励者，能够引领听众走向美好明天。','','{"strengths": ["领导才能", "善于沟通", "富有同理心", "鼓舞他人", "有魅力"], "weaknesses": ["过于理想化", "忽视自己", "敏感脆弱", "控制欲强", "难以接受批评"], "careers": ["教师", "咨询师", "公关专家", "人力资源经理", "培训师"]}',7);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ENFP','竞选者','热情、富有创造力的社交达人，总能找到理由微笑。','热情、富有创造力的社交达人，总能找到理由微笑。','','{"strengths": ["热情洋溢", "创意无限", "善于交际", "乐观积极", "适应力强"], "weaknesses": ["注意力分散", "容易厌倦", "过度理想化", "情绪化", "缺乏坚持"], "careers": ["记者", "演员", "营销专员", "创意总监", "创业者"]}',8);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ISTJ','物流师','务实、专注于事实的个体，其可靠性不容置疑。','务实、专注于事实的个体，其可靠性不容置疑。','','{"strengths": ["责任心强", "细致认真", "值得信赖", "有条不紊", "注重细节"], "weaknesses": ["固执己见", "不善变通", "情感表达少", "过于保守", "不喜欢变化"], "careers": ["会计师", "审计师", "行政人员", "法官", "项目经理"]}',9);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ISFJ','守卫者','非常专注和温暖的守护者，时刻准备保护所爱之人。','非常专注和温暖的守护者，时刻准备保护所爱之人。','','{"strengths": ["忠诚可靠", "细心体贴", "记忆力强", "勤勉尽责", "善于照顾他人"], "weaknesses": ["过于谦虚", "不善拒绝", "回避冲突", "压抑情感", "过度付出"], "careers": ["护士", "教师", "行政助理", "社会工作者", "人力资源专员"]}',10);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ESTJ','总经理','出色的管理者，在管理事务和人员方面无与伦比。','出色的管理者，在管理事务和人员方面无与伦比。','','{"strengths": ["组织能力强", "执行力高", "责任心重", "值得信赖", "善于管理"], "weaknesses": ["固执己见", "缺乏耐心", "不善倾听", "过于强势", "缺乏灵活性"], "careers": ["企业经理", "法官", "财务主管", "军官", "项目总监"]}',11);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ESFJ','执政官','极具同情心、爱交际的人，总是热心帮助他人。','极具同情心、爱交际的人，总是热心帮助他人。','','{"strengths": ["善于社交", "乐于助人", "忠诚可靠", "组织能力强", "关心他人"], "weaknesses": ["过于在意他人看法", "不善接受批评", "自我牺牲", "缺乏灵活性", "容易受伤"], "careers": ["护士", "教师", "销售代表", "活动策划师", "客服经理"]}',12);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ISTP','鉴赏家','大胆而实际的实验家，善于使用各种工具。','大胆而实际的实验家，善于使用各种工具。','','{"strengths": ["动手能力强", "冷静理性", "适应力好", "解决问题能力强", "善于分析"], "weaknesses": ["情感表达少", "容易厌倦", "不善承诺", "过于独立", "缺乏耐心"], "careers": ["工程师", "技师", "飞行员", "运动员", "技术专家"]}',13);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ISFP','探险家','灵活而有魅力的艺术家，时刻准备探索和体验新事物。','灵活而有魅力的艺术家，时刻准备探索和体验新事物。','','{"strengths": ["艺术天赋", "适应力强", "温和友善", "观察力敏锐", "审美能力强"], "weaknesses": ["竞争心弱", "计划性差", "过于敏感", "不善表达", "容易逃避冲突"], "careers": ["艺术家", "设计师", "厨师", "摄影师", "音乐家"]}',14);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ESTP','企业家','聪明、精力充沛、善于感知的人，真正享受生活边缘。','聪明、精力充沛、善于感知的人，真正享受生活边缘。','','{"strengths": ["行动力强", "适应力好", "善于社交", "危机处理能力强", "观察力敏锐"], "weaknesses": ["缺乏耐心", "不善规划", "冒险倾向", "忽视情感", "容易厌倦"], "careers": ["销售代表", "运动员", "急救人员", "企业家", "投资交易员"]}',15);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ESFP','表演者','自发的、精力充沛的艺人，生活永远不会无聊。','自发的、精力充沛的艺人，生活永远不会无聊。','','{"strengths": ["热情洋溢", "善于交际", "适应力强", "乐观积极", "善于娱乐他人"], "weaknesses": ["缺乏计划", "逃避困难", "注意力分散", "过于冲动", "不善长期规划"], "careers": ["演员", "主持人", "销售代表", "活动策划师", "旅游顾问"]}',16);


-- =============================================================================
-- 六、MBTI 16 型「初级解析 + 高级解析」双档文案
-- -----------------------------------------------------------------------------
-- UPDATE 补齐 basic_report / advanced_report，顺手把 summary 换成更适合分享卡片的一句话。由 tools/gen_reports.py 生成。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · MBTI 16 型「初级解析 + 高级解析」双档文案
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 旧数据问题：quiz_result 只有 summary/detail（两者内容重复），
--             traits 仅存 strengths/weaknesses/careers，撑不起两档解析。
-- 本文件补上：
--   basic_report    —— 初级解析（免费、云端下发）：一句话 + 4 特质 + 3 优势 + 3 短板 + 1 建议
--   advanced_report —— 高级解析（深度报告）：5 个章节 + 职业方向 + 典型形象
--   summary         —— 顺手换成更适合分享卡片的一句话
-- 用法：mysql ... < docs/seed-result-reports.sql（幂等，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 1. INTJ 建筑师
UPDATE `quiz_result` SET
  `name` = '建筑师',
  `summary` = '先想清楚终局，再倒推每一步',
  `basic_report` = '{"one_liner": "先想清楚终局，再倒推每一步", "traits": ["极度独立", "系统思维，爱搭框架", "标准很高", "不擅长也不想寒暄"], "strengths": ["长期规划能力", "拆解复杂问题", "抗干扰，不随大流"], "weaknesses": ["容易显得傲慢", "忽视他人的情绪成本", "过度追求最优解而错过窗口"], "tip": "给方案留 20% 的够用就好空间，会比追求完美更快落地"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你活在自己搭建的系统里，做任何事都先问目标是什么、路径是什么，对无效社交容忍度极低。"}, {"title": "思维与决策", "content": "决策独立于外界评价，重逻辑轻情绪，因此常被贴上「冷」的标签。"}, {"title": "职场与做事", "content": "适合需要长期战略和独立判断的岗位；厌恶朝令夕改和微观管理。"}, {"title": "关系与情感", "content": "关系少而深，表达关心靠行动而非语言，需要主动说明，以免被误解为不在乎。"}, {"title": "压力与成长", "content": "压力下更封闭、更苛刻。成长是接受人不是系统，情绪本身也有信息量。"}], "career": ["战略规划", "研发架构", "数据分析", "产品负责人"], "famous": "开会不怎么说话、一开口就把方案推翻重做的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'INTJ';

-- 2. INTP 逻辑学家
UPDATE `quiz_result` SET
  `name` = '逻辑学家',
  `summary` = '对「为什么」的兴趣远大于「怎么做」',
  `basic_report` = '{"one_liner": "对「为什么」的兴趣远大于「怎么做」", "traits": ["好奇心旺盛", "爱拆解原理", "随和但骨子里固执", "拖延严重"], "strengths": ["抽象建模能力", "能一眼看出逻辑漏洞", "客观，不感情用事"], "weaknesses": ["启动困难", "忽视细节执行", "社交被动"], "tip": "把想法写下来发出去，比在脑内打磨一百遍更有用"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你享受思考本身，一个问题没想透会一直挂在后台运行，对既定答案天然怀疑。"}, {"title": "思维与决策", "content": "重逻辑一致，厌恶情绪绑架决策，也因此常被说想太多。"}, {"title": "职场与做事", "content": "适合研究、架构、需要深度思考的岗位；流程性事务是你的能量黑洞。"}, {"title": "关系与情感", "content": "随和不黏人，但解释欲强。亲密关系里要记得，对方有时只需要一句我在。"}, {"title": "压力与成长", "content": "压力下陷入分析瘫痪。成长是给思考设时限，先产出粗糙版本。"}], "career": ["研发工程", "算法", "学术研究", "系统设计"], "famous": "能把一个概念给你推演三个小时的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'INTP';

-- 3. ENTJ 指挥官
UPDATE `quiz_result` SET
  `name` = '指挥官',
  `summary` = '看到低效就想改，看到目标就想拿下',
  `basic_report` = '{"one_liner": "看到低效就想改，看到目标就想拿下", "traits": ["目标导向", "果断，不拖泥带水", "天然想主导", "说话很直"], "strengths": ["推动力极强", "组织和调配资源", "压力下依然能决策"], "weaknesses": ["强势，容易压过别人", "忽略情绪成本", "耐心偏低"], "tip": "在要求别人之前，先说清为什么要做，效率会翻倍"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "天然的组织者和推进器，对混乱和低效几乎是生理性不适，愿意也敢于承担责任。"}, {"title": "思维与决策", "content": "决策快、偏理性、以结果为唯一标准，情绪因素常被排在最后。"}, {"title": "职场与做事", "content": "适合带团队、拓业务、打硬仗；在被微观管控的环境里会窒息。"}, {"title": "关系与情感", "content": "直接、忠诚，但容易把关系也当项目管理，需要练习倾听而不是给方案。"}, {"title": "压力与成长", "content": "压力下更具压迫感。成长是学会把人当人，速度会慢一点，但走得更远。"}], "career": ["团队管理", "创业", "销售负责人", "项目管理"], "famous": "发一句话就能把分工排完的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ENTJ';

-- 4. ENTP 辩论家
UPDATE `quiz_result` SET
  `name` = '辩论家',
  `summary` = '享受把共识拆开看看，哪怕最后自己也不站那边',
  `basic_report` = '{"one_liner": "享受把共识拆开看看，哪怕最后自己也不站那边", "traits": ["反应极快", "爱挑战既定结论", "点子密度高", "不喜欢被约束"], "strengths": ["临场应变", "善于发现问题", "跨界联想"], "weaknesses": ["三分钟热度", "嘴快容易伤人", "讨厌收尾工作"], "tip": "每次开口前先问自己：我是想赢，还是想弄清楚"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你的乐趣在于拆解和重构，规则和共识在你眼里都是待验证的假设。"}, {"title": "思维与决策", "content": "思维跳跃，善于反向论证，决策偏直觉，容易为了辩论而辩论。"}, {"title": "职场与做事", "content": "适合开创、谈判、需要脑洞的事；最怕重复性执行和冗长流程。"}, {"title": "关系与情感", "content": "有趣但难稳定，容易被认为不够认真。需要学会在重要时刻停止玩笑。"}, {"title": "压力与成长", "content": "压力下更爱抬杠，或突然放弃。成长是选一件事坚持到看到结果。"}], "career": ["创业", "商务拓展", "产品创新", "咨询"], "famous": "饭桌上永远在拆别人观点的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ENTP';

-- 5. INFJ 提倡者
UPDATE `quiz_result` SET
  `name` = '提倡者',
  `summary` = '看得比别人远，也因此更容易孤独',
  `basic_report` = '{"one_liner": "看得比别人远，也因此更容易孤独", "traits": ["洞察力深，能读出别人的言外之意", "有强烈的使命感", "外热内冷，社交是消耗", "一旦承诺就会做到底"], "strengths": ["看人极准", "能把想法沉淀成体系", "长期主义，不追短期热闹"], "weaknesses": ["过度承担他人的期待", "完美主义导致迟迟不交付", "情绪攒够了会突然断联式抽离"], "tip": "允许自己只帮到「能做到」的程度，不是所有事都该你扛"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "表面温和好相处，内在有很强的价值使命感和秩序感，常觉得自己和周围不在一个频道。"}, {"title": "思维与决策", "content": "长期推演型，会在脑内模拟多种后果后才行动，所以显得慢，但准。"}, {"title": "职场与做事", "content": "需要有意义、能帮到具体人的工作；纯逐利的环境会让你迅速失去动力。"}, {"title": "关系与情感", "content": "择友极严，深度关系里极度忠诚。危险在于为维持和谐长期压抑自己，最后一刀切断。"}, {"title": "压力与成长", "content": "压力下会突然关门、切断联系。成长是学会早点说出不满，而不是攒到爆发。"}], "career": ["咨询顾问", "教育培训", "心理咨询", "内容策划"], "famous": "不声不响却在背后把大家拢起来的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'INFJ';

-- 6. INFP 调停者
UPDATE `quiz_result` SET
  `name` = '调停者',
  `summary` = '心里装着一整个世界，温柔但有绝不退让的底线',
  `basic_report` = '{"one_liner": "心里装着一整个世界，温柔但有绝不退让的底线", "traits": ["理想主义，做事讲意义不讲划算", "共情力强，别人的情绪会真实影响你", "内向充电，独处时最有创造力", "表面随和，内心有一套很硬的价值排序"], "strengths": ["能看见别人看不见的可能性", "真诚，不擅长也不愿意演", "文字、审美、共情类表达天生占优"], "weaknesses": ["容易内耗，把别人的问题背到自己身上", "启动慢，完美主义拖死执行", "冲突面前习惯回避，事后反复复盘"], "tip": "把「我想做」拆成「我今天做 15 分钟」，你缺的不是能力是启动"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你不是软弱，是把感受当真。外在随和，内在有一套不肯妥协的价值排序，一旦被踩线会比谁都决绝。"}, {"title": "思维与决策", "content": "先感受后逻辑。决策时先问「这对我有没有意义」，而不是划不划算，所以常被误判为不理性。"}, {"title": "职场与做事", "content": "在被理解、有自主权的环境里爆发；在机械重复和纯 KPI 压榨下迅速枯萎。适合能自己定义节奏的岗位。"}, {"title": "关系与情感", "content": "深度导向，朋友不多但极真。容易把伴侣的情绪当成自己的责任，需要学会区分共情和背负。"}, {"title": "压力与成长", "content": "压力下陷入自我怀疑的循环。成长关键是降低启动成本，接受完成比完美更接近理想。"}], "career": ["内容创作", "心理咨询", "编辑出版", "视觉设计"], "famous": "那种平时不说话、一开口就说到人心里的创作者"}'
WHERE `quiz_id` = 1 AND `type_code` = 'INFP';

-- 7. ENFJ 主人公
UPDATE `quiz_result` SET
  `name` = '主人公',
  `summary` = '天生想把人聚起来，也常被这份责任压垮',
  `basic_report` = '{"one_liner": "天生想把人聚起来，也常被这份责任压垮", "traits": ["感染力极强", "习惯性照顾身边的人", "爱安排、爱张罗", "在意他人评价"], "strengths": ["动员团队的能力", "能看见他人的潜力", "沟通与说服"], "weaknesses": ["边界感弱", "太在意别人怎么看你", "为别人耗尽自己的能量"], "tip": "每周留一段谁都不帮的时间，那不是自私，是续航"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你是天然的召集人和鼓励者，能敏锐察觉谁掉队并把他拉回来，但也因此容易把团队情绪背在身上。"}, {"title": "思维与决策", "content": "决策时会充分考虑对人的影响，有时为了照顾感受牺牲效率。"}, {"title": "职场与做事", "content": "适合带人、对外、需要影响力的事；独处填表类工作会迅速消耗你。"}, {"title": "关系与情感", "content": "付出型，容易吸引索取型伴侣。需要学会筛选，而不是拯救。"}, {"title": "压力与成长", "content": "压力下变成控制狂或过度讨好。成长是建立边界：帮人是选择，不是义务。"}], "career": ["教育培训", "人力资源", "公关传播", "社群运营"], "famous": "群里那个永远在张罗、也永远最累的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ENFJ';

-- 8. ENFP 竞选者
UPDATE `quiz_result` SET
  `name` = '竞选者',
  `summary` = '对世界永远好奇，热情来得快，也容易烧完',
  `basic_report` = '{"one_liner": "对世界永远好奇，热情来得快，也容易烧完", "traits": ["点子多，脑子里同时开着好几个项目", "情绪外放，能迅速和陌生人熟起来", "容易被新鲜事点燃", "极度厌恶重复和流程"], "strengths": ["破冰和连接人的能力", "创意爆发力强", "适应变化比大多数人快"], "weaknesses": ["虎头蛇尾，开局猛收尾难", "容易被无聊逼疯", "承诺给得太快，事后为难自己"], "tip": "给自己立一条硬规则：先做完一件，再开新坑"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你是人群里的火花塞，能迅速让别人放松并愿意跟你合作。热情是天赋也是消耗品，需要刻意管理。"}, {"title": "思维与决策", "content": "靠直觉和可能性驱动，选项越多越兴奋也越难选。重大决定建议给自己设死线，别无限收集信息。"}, {"title": "职场与做事", "content": "适合开创期、需要创意和人脉的事；恐惧的是流程化执行和长期填表。"}, {"title": "关系与情感", "content": "前期极有吸引力，后期容易让对方觉得抓不住。稳定关系的关键是主动报备和兑现小承诺。"}, {"title": "压力与成长", "content": "压力下要么过度承诺，要么突然抽离。成长是学会做完，而不是学会开始。"}], "career": ["市场营销", "品牌策划", "活动运营", "新媒体"], "famous": "朋友圈里永远在折腾新项目的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ENFP';

-- 9. ISTJ 物流师
UPDATE `quiz_result` SET
  `name` = '物流师',
  `summary` = '答应的事一定做到，做不到的事不答应',
  `basic_report` = '{"one_liner": "答应的事一定做到，做不到的事不答应", "traits": ["严谨", "守序", "务实", "低调"], "strengths": ["执行可靠", "细节把控", "责任心"], "weaknesses": ["抗拒变化", "表达偏僵硬", "灵活性不足"], "tip": "允许计划有 10% 的临时调整区，你会轻松很多"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你是秩序和可靠的化身，相信把每一步做对结果就不会错，讨厌无准备的冒险。"}, {"title": "思维与决策", "content": "依据事实、流程和历史经验决策，对未经验证的新方法保持怀疑。"}, {"title": "职场与做事", "content": "适合需要精确、规范、可追溯的工作；混乱环境让你极度不适。"}, {"title": "关系与情感", "content": "忠诚踏实，但情感表达偏笨拙，常用把事做好代替我爱你。"}, {"title": "压力与成长", "content": "压力下更固执。成长是接受没有完美流程，够用即可。"}], "career": ["财务审计", "行政管理", "质量管理", "法务合规"], "famous": "交给他的事你从不催第二遍的那个人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ISTJ';

-- 10. ISFJ 守卫者
UPDATE `quiz_result` SET
  `name` = '守卫者',
  `summary` = '默默把该做的事做完，就是最大的可靠',
  `basic_report` = '{"one_liner": "默默把该做的事做完，就是最大的可靠", "traits": ["细心", "责任感极强", "记性好", "害怕冲突"], "strengths": ["稳定可靠", "照顾细节", "能长期坚持"], "weaknesses": ["有需求说不出口", "过度自我牺牲", "抗拒变化"], "tip": "每周练习一次「这个我不太方便」，边界是练出来的"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你是团队里最稳定的底盘，记得别人的偏好和需求，习惯把事扛下来而不是说出来。"}, {"title": "思维与决策", "content": "重经验和具体事实，决策谨慎，厌恶风险和突变。"}, {"title": "职场与做事", "content": "适合需要细致、耐心、服务意识的岗位；混乱和朝令夕改最伤你。"}, {"title": "关系与情感", "content": "付出型，容易累积委屈直到爆发。需要学会提前、平静地表达需求。"}, {"title": "压力与成长", "content": "压力下过度自我牺牲。成长是把被需要和我愿意分开。"}], "career": ["行政后勤", "护理健康", "教务支持", "财务会计"], "famous": "那个永远记得大家忌口的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ISFJ';

-- 11. ESTJ 总经理
UPDATE `quiz_result` SET
  `name` = '总经理',
  `summary` = '把混乱变成流程，然后把流程跑起来',
  `basic_report` = '{"one_liner": "把混乱变成流程，然后把流程跑起来", "traits": ["组织力极强", "直接", "重责任", "讲规矩"], "strengths": ["推动执行", "建立秩序", "敢拍板"], "weaknesses": ["强势", "缺乏弹性", "容易忽略个体感受"], "tip": "在指出问题前先肯定一句，指令会被执行得更彻底"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你天然承担组织者角色，相信明确的分工、规则和时间表，对拖沓零容忍。"}, {"title": "思维与决策", "content": "重效率和既定标准，决策果断，倾向沿用被验证过的方法。"}, {"title": "职场与做事", "content": "适合管理、运营、执行推动类岗位；缺乏授权的混乱环境让你难受。"}, {"title": "关系与情感", "content": "可靠直接，但容易把家庭也当团队管理，需要注意语气和温度。"}, {"title": "压力与成长", "content": "压力下更专断。成长是学会授权，容忍不同的节奏。"}], "career": ["团队管理", "运营管理", "项目管理", "销售管理"], "famous": "发分工表、到点就来收结果的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ESTJ';

-- 12. ESFJ 执政官
UPDATE `quiz_result` SET
  `name` = '执政官',
  `summary` = '把人照顾好、把事办周全，是本能',
  `basic_report` = '{"one_liner": "把人照顾好、把事办周全，是本能", "traits": ["热心", "重礼节与分寸", "爱组织", "在意他人评价"], "strengths": ["组织协调", "维护关系", "落地执行"], "weaknesses": ["太在意评价", "爱操心", "难以说不"], "tip": "别人的情绪不是你的责任，先照顾好自己的，再照顾世界"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你对人际和谐有天然责任感，擅长把人聚起来并把细节安排妥当，被认可是重要能量来源。"}, {"title": "思维与决策", "content": "重他人感受和既有规范，决策时倾向维持共识。"}, {"title": "职场与做事", "content": "适合服务、协调、社群类工作；冷冰冰的纯指标环境会让你失去动力。"}, {"title": "关系与情感", "content": "热情付出，但容易因对方没回应而失落。需要降低对等回报的期待。"}, {"title": "压力与成长", "content": "压力下变得控制或讨好。成长是接受不是所有人都会喜欢我。"}], "career": ["人力资源", "客户服务", "社群运营", "教育培训"], "famous": "组织聚餐、统计人数、订餐厅一条龙的那个人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ESFJ';

-- 13. ISTP 鉴赏家
UPDATE `quiz_result` SET
  `name` = '鉴赏家',
  `summary` = '少说话，把东西拆开弄明白再装回去',
  `basic_report` = '{"one_liner": "少说话，把东西拆开弄明白再装回去", "traits": ["冷静", "动手能力极强", "重视独立", "效率优先"], "strengths": ["故障排查", "临场冷静", "善用工具和资源"], "weaknesses": ["表达太少", "对长期承诺有恐惧", "情绪察觉偏迟钝"], "tip": "你在意的人需要听到你说出来，不只是看到你做到"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你通过亲手操作理解世界，对理论和空谈兴趣缺缺，喜欢保留随时抽身的自由。"}, {"title": "思维与决策", "content": "极度务实，只看现在什么有效，逻辑清晰但不爱解释。"}, {"title": "职场与做事", "content": "适合技术、实操、应急类岗位；长会议和繁文缛节是酷刑。"}, {"title": "关系与情感", "content": "用行动表达在乎，不擅长语言安抚。伴侣需要你偶尔明确说出来。"}, {"title": "压力与成长", "content": "压力下更沉默，或突然爆发。成长是练习提前沟通，而不是事后消失。"}], "career": ["工程技术", "运维支持", "运动训练", "手工制作"], "famous": "东西坏了大家第一个想到的那个人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ISTP';

-- 14. ISFP 探险家
UPDATE `quiz_result` SET
  `name` = '探险家',
  `summary` = '不说大道理，用行动和审美表达自己',
  `basic_report` = '{"one_liner": "不说大道理，用行动和审美表达自己", "traits": ["感官敏锐", "随性，不爱被安排", "重体验胜过重分析", "不爱争辩"], "strengths": ["审美判断", "动手能力", "能专注在当下"], "weaknesses": ["回避冲突", "长期规划偏弱", "容易受环境影响"], "tip": "给自己设一个三个月后的小目标，自由才不会变成漂浮"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你活在具体的、可感知的当下，对美和质感有天然判断，不擅长也不喜欢抽象争论。"}, {"title": "思维与决策", "content": "凭感受和价值做决定，逻辑说服对你效果有限，亲身体验才有效。"}, {"title": "职场与做事", "content": "适合有实操、有审美空间的工作；纯理论或高压销售会消耗你。"}, {"title": "关系与情感", "content": "用行动示爱，不常说但做得多。冲突时会沉默退开，需要练习表达底线。"}, {"title": "压力与成长", "content": "压力下逃避或冲动消费。成长是给自由加一点点结构。"}], "career": ["视觉设计", "摄影", "手作工艺", "护理健康"], "famous": "朋友圈照片永远最有质感的那个人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ISFP';

-- 15. ESTP 企业家
UPDATE `quiz_result` SET
  `name` = '企业家',
  `summary` = '先干，问题在干的过程中解决',
  `basic_report` = '{"one_liner": "先干，问题在干的过程中解决", "traits": ["行动派", "爱冒险", "极度现实", "反应快"], "strengths": ["抓住机会", "现场应变", "抗压能力强"], "weaknesses": ["容易冲动", "忽视长远后果", "规则意识偏弱"], "tip": "做决定前多停 10 秒，问一句三个月后我怎么看"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你对机会极其敏感，享受在不确定中快速博弈，坐办公室复盘对你是一种消耗。"}, {"title": "思维与决策", "content": "重事实和即时反馈，直觉很准，但对长期后果估算不足。"}, {"title": "职场与做事", "content": "适合业务开拓、谈判、现场类工作；流程和文书会让你抓狂。"}, {"title": "关系与情感", "content": "有趣刺激，但承诺来去都快。长期关系需要你主动给稳定性。"}, {"title": "压力与成长", "content": "压力下更冒险或更暴躁。成长是引入一个慢半拍的自我检查机制。"}], "career": ["销售", "创业", "商务谈判", "市场开拓"], "famous": "别人还在讨论，他已经把事跑完一轮的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ESTP';

-- 16. ESFP 表演者
UPDATE `quiz_result` SET
  `name` = '表演者',
  `summary` = '把此刻活得尽兴，就是最大的意义',
  `basic_report` = '{"one_liner": "把此刻活得尽兴，就是最大的意义", "traits": ["热情外放", "爱互动", "当下导向", "怕闷"], "strengths": ["带动气氛", "现场感染力", "真实不做作"], "weaknesses": ["偏短视", "难以坚持长期事项", "回避沉重话题"], "tip": "每月强制存一笔、看一次长期账，你会感谢现在的自己"}',
  `advanced_report` = '{"chapters": [{"title": "深度画像", "content": "你是现场的燃料，人群因你而活跃，你也从互动里充电，独处久了会明显掉电。"}, {"title": "思维与决策", "content": "决策快，凭感觉和现实反馈，对抽象的长远推演兴趣不大。"}, {"title": "职场与做事", "content": "适合需要表现、互动、即时反馈的工作；后台填表类会让你枯萎。"}, {"title": "关系与情感", "content": "慷慨热烈，是很好的陪伴者，但面对沉重情绪容易转移话题。"}, {"title": "压力与成长", "content": "压力下冲动消费或逃避。成长是学会延迟满足，给未来留一点。"}], "career": ["活动主持", "销售", "直播", "服务体验"], "famous": "聚会上最后一个还在嗨的人"}'
WHERE `quiz_id` = 1 AND `type_code` = 'ESFP';


-- =============================================================================
-- 七、DISC 行为风格测评（全套数据）
-- -----------------------------------------------------------------------------
-- quiz_id=2：测评定义 + 4 个类型维度 + 20 道四选一 + 4 型结果（含双档解析）。scoring_model=MAX。由 tools/gen_reports.py 生成。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · DISC 行为风格测评（全套数据）
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 算分模型：scoring_model = MAX —— 四个类型维度各自累加，取总分最高的那个。
--          （区别于 MBTI 的 PAIR：按 pair_code 对撞取大，拼出 4 字母码）
-- 题目：20 道四选一，每个选项给对应类型维度 +1 分。
-- 用法：mysql ... < docs/seed-disc.sql（开头清 quiz_id=2 再重插，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 2);
DELETE FROM `question`        WHERE `quiz_id` = 2;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 2;
DELETE FROM `dimension`       WHERE `quiz_id` = 2;
DELETE FROM `quiz`            WHERE `id`      = 2;

-- 测评本体（scoring_model = MAX：累加取最高分类型）
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`emoji`,`tag`,`sort_order`,`question_count`,`price_coin`,`scoring_model`,`status`) VALUES
(2,'disc','DISC 行为风格测试','2 分钟看清你做事的风格','DISC 把人的行事风格分成支配、影响、稳健、谨慎四种倾向。它不测能力高低，只描述你在压力和目标面前更习惯怎么行动——这也是同事最容易误解你的地方。','🔥','性格',2,0,0,'MAX',1);

-- 类型维度（4 个，MAX 模型下 dimension 一行 = 一个结果类型，pair_code 统一 TYPE）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(9,2,'D','支配型','TYPE',1),
(10,2,'I','影响型','TYPE',2),
(11,2,'S','稳健型','TYPE',3),
(12,2,'C','谨慎型','TYPE',4);

-- 题目（20 道，四选一）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (200,2,'面对一个突发任务，你的第一反应是：',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(200,'立刻定目标，分配谁做什么',9,1,0),
(200,'先拉人聊聊，把气氛搞起来',10,1,1),
(200,'先确认细节，别出错',11,1,2),
(200,'先查清规则和历史数据',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (201,2,'团队讨论陷入僵局时，你会：',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(201,'直接拍板，责任我来担',9,1,0),
(201,'讲个笑话缓和，再引导大家说',10,1,1),
(201,'安静听着，等别人先表态',11,1,2),
(201,'把分歧点列出来逐条分析',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (202,2,'你理想的工作节奏是：',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(202,'快、有挑战、能说了算',9,1,0),
(202,'热闹、能认识人、不枯燥',10,1,1),
(202,'稳定、可预期、少变动',11,1,2),
(202,'有标准、能钻研、不被催',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (203,2,'方案被人当面否定，你会：',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(203,'当场据理力争',9,1,0),
(203,'表面笑笑，心里有点受伤',10,1,1),
(203,'不太舒服，但先不回应',11,1,2),
(203,'追问依据，用数据回敬',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (204,2,'做决定时你更依赖：',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(204,'我想要的结果',9,1,0),
(204,'大家的感受',10,1,1),
(204,'过去的经验',11,1,2),
(204,'事实和数据',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (205,2,'周末你更愿意：',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(205,'搞点有成就感的事',9,1,0),
(205,'约朋友出去玩',10,1,1),
(205,'在家陪家人或休息',11,1,2),
(205,'研究点感兴趣的东西',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (206,2,'你最受不了别人：',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(206,'磨叽、不推进',9,1,0),
(206,'冷淡、不给反馈',10,1,1),
(206,'突然变卦、制造冲突',11,1,2),
(206,'含糊、不讲逻辑',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (207,2,'带团队时你更在意：',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(207,'目标有没有达成',9,1,0),
(207,'团队氛围好不好',10,1,1),
(207,'成员状态稳不稳',11,1,2),
(207,'流程是否规范',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (208,2,'新项目启动会上，你通常：',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(208,'追问 deadline 和责任人',9,1,0),
(208,'主动暖场、活跃气氛',10,1,1),
(208,'记下分工，默默配合',11,1,2),
(208,'问清楚验收标准',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (209,2,'面对规则，你觉得：',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(209,'规则是用来突破的',9,1,0),
(209,'差不多就行，别太死板',10,1,1),
(209,'按规矩来最省心',11,1,2),
(209,'规则必须严谨执行',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (210,2,'你发消息的习惯是：',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(210,'短、直接、说重点',9,1,0),
(210,'语音多、表情多、爱分享',10,1,1),
(210,'斟酌一下再发，怕伤人',11,1,2),
(210,'会检查错别字和数据',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (211,2,'被临时加塞一个活，你会：',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(211,'评估值不值，不值就推掉',9,1,0),
(211,'先答应，边做边想',10,1,1),
(211,'接下来说，哪怕自己加班',11,1,2),
(211,'先问优先级，排进计划',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (212,2,'你更希望别人怎么评价你：',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(212,'有魄力',9,1,0),
(212,'有感染力',10,1,1),
(212,'靠谱',11,1,2),
(212,'专业',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (213,2,'处理冲突时你倾向：',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(213,'正面沟通，快刀斩乱麻',9,1,0),
(213,'打圆场，先把情绪顺过来',10,1,1),
(213,'回避，等它自己过去',11,1,2),
(213,'讲道理，分清对错',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (214,2,'学习一项新技能，你喜欢：',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(214,'直接上手，边错边学',9,1,0),
(214,'找人一起学，互相聊',10,1,1),
(214,'按部就班跟着教程',11,1,2),
(214,'先把原理吃透',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (215,2,'你桌面的状态通常是：',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(215,'乱，但我知道东西在哪',9,1,0),
(215,'贴满便签和照片',10,1,1),
(215,'整洁，按习惯摆放',11,1,2),
(215,'分类清晰，有标签',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (216,2,'别人常觉得你说话：',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(216,'太冲',9,1,0),
(216,'太多',10,1,1),
(216,'太少',11,1,2),
(216,'太较真',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (217,2,'面对风险，你：',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(217,'敢赌，输了再来',9,1,0),
(217,'看感觉，乐观居多',10,1,1),
(217,'能避就避',11,1,2),
(217,'先算概率再决定',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (218,2,'完成一件大事后，你的第一想法是：',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(218,'下一个目标是什么',9,1,0),
(218,'赶紧跟人分享',10,1,1),
(218,'终于可以喘口气',11,1,2),
(218,'复盘哪里还能优化',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (219,2,'你最看重的工作回报是：',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(219,'话语权和上升空间',9,1,0),
(219,'被认可和人际关系',10,1,1),
(219,'稳定和被需要',11,1,2),
(219,'专业成长和准确性',12,1,3);

-- 结果类型（4 型，含初级 + 高级双档解析）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(2,'D','支配型','目标在手，其余皆可让路','目标在手，其余皆可让路','','{"strengths": ["推进力极强", "危机中敢决策", "敢于承担责任"], "weaknesses": ["显得强势", "耐心偏低", "容易忽略他人感受"], "careers": ["团队管理", "业务拓展", "创业", "项目攻坚"]}','{"one_liner": "目标在手，其余皆可让路", "traits": ["结果导向", "果断，不拖泥带水", "天然想主导", "抗压能力强"], "strengths": ["推进力极强", "危机中敢决策", "敢于承担责任"], "weaknesses": ["显得强势", "耐心偏低", "容易忽略他人感受"], "tip": "发指令前补一句为什么要做，团队配合度立刻不一样"}','{"chapters": [{"title": "深度画像", "content": "你对结果有近乎本能的渴望，喜欢掌控节奏，遇到阻碍第一反应是绕过去而不是等待。"}, {"title": "思维与决策", "content": "决策快，以目标为唯一准绳，情绪和过程细节常被排在后面。"}, {"title": "职场与做事", "content": "在开拓、攻坚、需要拍板的场景里最强；流程和文书工作会消耗你。"}, {"title": "关系与情感", "content": "直接且忠诚，但容易把关系也当任务推进，需要练习先听后说。"}, {"title": "压力与成长", "content": "压力下更具压迫感甚至专断。成长是学会授权，并解释自己的动机。"}], "career": ["团队管理", "业务拓展", "创业", "项目攻坚"], "famous": "会议里第一个问什么时候交付的人"}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(2,'I','影响型','把人聚起来，事情就成了一半','把人聚起来，事情就成了一半','','{"strengths": ["感染他人", "破冰和连接", "现场活跃气氛"], "weaknesses": ["细节把控弱", "容易分心", "过于在意评价"], "careers": ["市场营销", "品牌公关", "培训讲师", "活动策划"]}','{"one_liner": "把人聚起来，事情就成了一半", "traits": ["外向热情", "善于表达", "乐观", "渴望被认可"], "strengths": ["感染他人", "破冰和连接", "现场活跃气氛"], "weaknesses": ["细节把控弱", "容易分心", "过于在意评价"], "tip": "把承诺写进清单，热情才不会变成烂尾"}','{"chapters": [{"title": "深度画像", "content": "你从人际互动中获取能量，擅长让气氛变好、让人愿意参与，也享受被关注。"}, {"title": "思维与决策", "content": "凭直觉和感受决策，重大家怎么看，对枯燥数据耐心有限。"}, {"title": "职场与做事", "content": "适合对外、创意、需要影响力的岗位；长期独立填表类会让你枯萎。"}, {"title": "关系与情感", "content": "慷慨有趣，是很好的陪伴者，但面对沉重情绪容易转移话题。"}, {"title": "压力与成长", "content": "压力下冲动或过度表达。成长是建立清单和复盘习惯。"}], "career": ["市场营销", "品牌公关", "培训讲师", "活动策划"], "famous": "群里永远在暖场、也最能张罗的人"}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(2,'S','稳健型','慢一点没关系，稳稳走到就行','慢一点没关系，稳稳走到就行','','{"strengths": ["稳定执行", "善于倾听", "能长期坚持"], "weaknesses": ["抗拒变化", "难以拒绝别人", "表达被动"], "careers": ["客户服务", "行政后勤", "护理健康", "技术支持"]}','{"one_liner": "慢一点没关系，稳稳走到就行", "traits": ["温和", "耐心", "可靠", "回避冲突"], "strengths": ["稳定执行", "善于倾听", "能长期坚持"], "weaknesses": ["抗拒变化", "难以拒绝别人", "表达被动"], "tip": "练习把需求说出口，别人没你那么会读空气"}','{"chapters": [{"title": "深度画像", "content": "你偏好可预期的节奏，是团队里最稳定的支撑，厌恶突发状况和当面冲突。"}, {"title": "思维与决策", "content": "谨慎，重经验与他人感受，决策慢，但一旦决定就不易动摇。"}, {"title": "职场与做事", "content": "适合需要耐心、细致、服务意识的岗位；频繁变动最伤你。"}, {"title": "关系与情感", "content": "忠诚体贴，但委屈会累积，需要学会提前、平静地表达。"}, {"title": "压力与成长", "content": "压力下退缩沉默。成长是给自己设表达底线，每周练一次拒绝。"}], "career": ["客户服务", "行政后勤", "护理健康", "技术支持"], "famous": "那个不抢话但永远靠得住的人"}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(2,'C','谨慎型','先把规则和数据弄清楚，再动手','先把规则和数据弄清楚，再动手','','{"strengths": ["分析准确", "流程规范", "质量把控"], "weaknesses": ["过度纠结细节", "决策偏慢", "容易显得苛刻"], "careers": ["财务审计", "数据分析", "质量管理", "研发工程"]}','{"one_liner": "先把规则和数据弄清楚，再动手", "traits": ["严谨", "重逻辑", "追求准确", "低调"], "strengths": ["分析准确", "流程规范", "质量把控"], "weaknesses": ["过度纠结细节", "决策偏慢", "容易显得苛刻"], "tip": "给任务设一个足够好的标准，完美主义也是拖延的一种"}','{"chapters": [{"title": "深度画像", "content": "你相信凡事都有标准，对含糊和错误容忍度极低，习惯用事实和数据说话。"}, {"title": "思维与决策", "content": "重证据与逻辑，决策前会充分验证，厌恶拍脑袋。"}, {"title": "职场与做事", "content": "适合专业、分析、质量类岗位；混乱和拍脑袋决策让你痛苦。"}, {"title": "关系与情感", "content": "认真可靠，但容易用挑错来表达关心，需要练习先肯定再补充。"}, {"title": "压力与成长", "content": "压力下更较真、更退缩。成长是接受完成优于完美。"}], "career": ["财务审计", "数据分析", "质量管理", "研发工程"], "famous": "能一眼看出报表里错了一位的人"}',4);


-- =============================================================================
-- 八、九型人格测评（全套数据）
-- -----------------------------------------------------------------------------
-- quiz_id=3：测评定义 + 9 个类型维度 + 36 道李克特五点量表题（每型 4 题）+ 9 型结果（含双档解析）。scoring_model=MAX。由 tools/gen_reports.py 生成。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · 九型人格测评（全套数据）
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 算分模型：scoring_model = MAX —— 九个类型维度各自累加，取总分最高的那个。
-- 题型：李克特五点量表，36 道陈述题（每型 4 题），
--       选项 非常不同意(1 分) → 非常同意(5 分)，全部指向同一个类型维度。
--       （question_option 做成独立表就是为了兼容这种量表，而不只是二选一）
-- 用法：mysql ... < docs/seed-enneagram.sql（开头清 quiz_id=3 再重插，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 3);
DELETE FROM `question`        WHERE `quiz_id` = 3;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 3;
DELETE FROM `dimension`       WHERE `quiz_id` = 3;
DELETE FROM `quiz`            WHERE `id`      = 3;

-- 测评本体（scoring_model = MAX：累加取最高分类型）
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`emoji`,`tag`,`sort_order`,`question_count`,`price_coin`,`scoring_model`,`status`) VALUES
(3,'enneagram','九型人格测试','看清你行为背后的真实动机','MBTI 描述你怎么思考，九型追问你为什么这么做。它把人分成九种核心动机，并指出每种类型在压力和安全状态下的变化方向——这也是为什么同一个人在不同阶段会显得判若两人。','🔮','性格',3,0,0,'MAX',1);

-- 类型维度（9 个，MAX 模型下 dimension 一行 = 一个结果类型，pair_code 统一 TYPE）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(13,3,'1','完美型','TYPE',1),
(14,3,'2','助人型','TYPE',2),
(15,3,'3','成就型','TYPE',3),
(16,3,'4','浪漫型','TYPE',4),
(17,3,'5','观察型','TYPE',5),
(18,3,'6','忠诚型','TYPE',6),
(19,3,'7','享乐型','TYPE',7),
(20,3,'8','领袖型','TYPE',8),
(21,3,'9','和平型','TYPE',9);

-- 题目（36 道，李克特五点量表）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (300,3,'看到事情做得不标准，我会忍不住想纠正',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(300,'非常不同意',13,1,0),
(300,'不太同意',13,2,1),
(300,'一般',13,3,2),
(300,'比较同意',13,4,3),
(300,'非常同意',13,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (301,3,'我很难容忍自己和别人敷衍了事',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(301,'非常不同意',13,1,0),
(301,'不太同意',13,2,1),
(301,'一般',13,3,2),
(301,'比较同意',13,4,3),
(301,'非常同意',13,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (302,3,'做决定前我会反复检查有没有遗漏',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(302,'非常不同意',13,1,0),
(302,'不太同意',13,2,1),
(302,'一般',13,3,2),
(302,'比较同意',13,4,3),
(302,'非常同意',13,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (303,3,'别人说我太较真，但我觉得那是对事不对人',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(303,'非常不同意',13,1,0),
(303,'不太同意',13,2,1),
(303,'一般',13,3,2),
(303,'比较同意',13,4,3),
(303,'非常同意',13,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (304,3,'察觉到别人需要帮忙，我会主动凑上去',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(304,'非常不同意',14,1,0),
(304,'不太同意',14,2,1),
(304,'一般',14,3,2),
(304,'比较同意',14,4,3),
(304,'非常同意',14,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (305,3,'我很容易把别人的事排在自己前面',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(305,'非常不同意',14,1,0),
(305,'不太同意',14,2,1),
(305,'一般',14,3,2),
(305,'比较同意',14,4,3),
(305,'非常同意',14,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (306,3,'被需要的时候，我才觉得自己有价值',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(306,'非常不同意',14,1,0),
(306,'不太同意',14,2,1),
(306,'一般',14,3,2),
(306,'比较同意',14,4,3),
(306,'非常同意',14,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (307,3,'付出后如果没得到回应，我会有点失落',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(307,'非常不同意',14,1,0),
(307,'不太同意',14,2,1),
(307,'一般',14,3,2),
(307,'比较同意',14,4,3),
(307,'非常同意',14,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (308,3,'我习惯先把目标定下来，再倒推怎么做',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(308,'非常不同意',15,1,0),
(308,'不太同意',15,2,1),
(308,'一般',15,3,2),
(308,'比较同意',15,4,3),
(308,'非常同意',15,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (309,3,'效率低、没进展会让我烦躁',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(309,'非常不同意',15,1,0),
(309,'不太同意',15,2,1),
(309,'一般',15,3,2),
(309,'比较同意',15,4,3),
(309,'非常同意',15,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (310,3,'我很在意别人眼里我是不是成功',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(310,'非常不同意',15,1,0),
(310,'不太同意',15,2,1),
(310,'一般',15,3,2),
(310,'比较同意',15,4,3),
(310,'非常同意',15,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (311,3,'为了推进事情，我可以暂时放下情绪',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(311,'非常不同意',15,1,0),
(311,'不太同意',15,2,1),
(311,'一般',15,3,2),
(311,'比较同意',15,4,3),
(311,'非常同意',15,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (312,3,'我常觉得自己和别人有种说不清的不同',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(312,'非常不同意',16,1,0),
(312,'不太同意',16,2,1),
(312,'一般',16,3,2),
(312,'比较同意',16,4,3),
(312,'非常同意',16,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (313,3,'情绪起伏是我理解自己和创作的来源',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(313,'非常不同意',16,1,0),
(313,'不太同意',16,2,1),
(313,'一般',16,3,2),
(313,'比较同意',16,4,3),
(313,'非常同意',16,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (314,3,'平淡的日子会让我觉得缺了点什么',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(314,'非常不同意',16,1,0),
(314,'不太同意',16,2,1),
(314,'一般',16,3,2),
(314,'比较同意',16,4,3),
(314,'非常同意',16,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (315,3,'我很在意什么东西是真正属于我的风格',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(315,'非常不同意',16,1,0),
(315,'不太同意',16,2,1),
(315,'一般',16,3,2),
(315,'比较同意',16,4,3),
(315,'非常同意',16,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (316,3,'遇到不懂的事，我会先自己查清楚再问人',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(316,'非常不同意',17,1,0),
(316,'不太同意',17,2,1),
(316,'一般',17,3,2),
(316,'比较同意',17,4,3),
(316,'非常同意',17,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (317,3,'我需要大量独处时间来恢复和思考',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(317,'非常不同意',17,1,0),
(317,'不太同意',17,2,1),
(317,'一般',17,3,2),
(317,'比较同意',17,4,3),
(317,'非常同意',17,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (318,3,'比起参与，我更愿意先旁观把结构看明白',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(318,'非常不同意',17,1,0),
(318,'不太同意',17,2,1),
(318,'一般',17,3,2),
(318,'比较同意',17,4,3),
(318,'非常同意',17,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (319,3,'被人过度打扰会让我很不舒服',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(319,'非常不同意',17,1,0),
(319,'不太同意',17,2,1),
(319,'一般',17,3,2),
(319,'比较同意',17,4,3),
(319,'非常同意',17,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (320,3,'做重要决定前我会把最坏情况想一遍',21,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(320,'非常不同意',18,1,0),
(320,'不太同意',18,2,1),
(320,'一般',18,3,2),
(320,'比较同意',18,4,3),
(320,'非常同意',18,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (321,3,'我倾向于找可靠的人或规矩来依靠',22,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(321,'非常不同意',18,1,0),
(321,'不太同意',18,2,1),
(321,'一般',18,3,2),
(321,'比较同意',18,4,3),
(321,'非常同意',18,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (322,3,'环境突然变化时我会很不安',23,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(322,'非常不同意',18,1,0),
(322,'不太同意',18,2,1),
(322,'一般',18,3,2),
(322,'比较同意',18,4,3),
(322,'非常同意',18,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (323,3,'我容易怀疑，但一旦信任就会很忠诚',24,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(323,'非常不同意',18,1,0),
(323,'不太同意',18,2,1),
(323,'一般',18,3,2),
(323,'比较同意',18,4,3),
(323,'非常同意',18,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (324,3,'我脑子里同时装着好几个想做的事',25,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(324,'非常不同意',19,1,0),
(324,'不太同意',19,2,1),
(324,'一般',19,3,2),
(324,'比较同意',19,4,3),
(324,'非常同意',19,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (325,3,'无聊和受限是我最难受的状态',26,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(325,'非常不同意',19,1,0),
(325,'不太同意',19,2,1),
(325,'一般',19,3,2),
(325,'比较同意',19,4,3),
(325,'非常同意',19,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (326,3,'遇到不愉快，我倾向于换个事情转移注意力',27,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(326,'非常不同意',19,1,0),
(326,'不太同意',19,2,1),
(326,'一般',19,3,2),
(326,'比较同意',19,4,3),
(326,'非常同意',19,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (327,3,'我喜欢把计划留有余地，随时可以改',28,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(327,'非常不同意',19,1,0),
(327,'不太同意',19,2,1),
(327,'一般',19,3,2),
(327,'比较同意',19,4,3),
(327,'非常同意',19,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (328,3,'遇到不公或被压制，我会直接顶回去',29,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(328,'非常不同意',20,1,0),
(328,'不太同意',20,2,1),
(328,'一般',20,3,2),
(328,'比较同意',20,4,3),
(328,'非常同意',20,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (329,3,'我习惯掌控局面，不喜欢被人牵着走',30,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(329,'非常不同意',20,1,0),
(329,'不太同意',20,2,1),
(329,'一般',20,3,2),
(329,'比较同意',20,4,3),
(329,'非常同意',20,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (330,3,'保护自己在乎的人是我的本能',31,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(330,'非常不同意',20,1,0),
(330,'不太同意',20,2,1),
(330,'一般',20,3,2),
(330,'比较同意',20,4,3),
(330,'非常同意',20,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (331,3,'软弱和犹豫会让我不耐烦',32,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(331,'非常不同意',20,1,0),
(331,'不太同意',20,2,1),
(331,'一般',20,3,2),
(331,'比较同意',20,4,3),
(331,'非常同意',20,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (332,3,'我尽量避免冲突，能顺就顺',33,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(332,'非常不同意',21,1,0),
(332,'不太同意',21,2,1),
(332,'一般',21,3,2),
(332,'比较同意',21,4,3),
(332,'非常同意',21,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (333,3,'别人争起来时我常当和事佬',34,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(333,'非常不同意',21,1,0),
(333,'不太同意',21,2,1),
(333,'一般',21,3,2),
(333,'比较同意',21,4,3),
(333,'非常同意',21,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (334,3,'我容易顺着别人的意见，忽略自己真正想要什么',35,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(334,'非常不同意',21,1,0),
(334,'不太同意',21,2,1),
(334,'一般',21,3,2),
(334,'比较同意',21,4,3),
(334,'非常同意',21,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (335,3,'稳定和舒服的节奏对我来说很重要',36,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(335,'非常不同意',21,1,0),
(335,'不太同意',21,2,1),
(335,'一般',21,3,2),
(335,'比较同意',21,4,3),
(335,'非常同意',21,5,4);

-- 结果类型（9 型，含初级 + 高级双档解析）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'1','完美型','心里有一把尺，量别人之前先量自己','心里有一把尺，量别人之前先量自己','','{"strengths": ["能把事做到位", "原则感强，可靠", "善于发现问题和改进点"], "weaknesses": ["容易挑剔和苛责", "完美主义拖慢进度", "情绪上容易积压不满"], "careers": ["质量管理", "财务审计", "法务合规", "工程技术"]}','{"one_liner": "心里有一把尺，量别人之前先量自己", "traits": ["标准高，眼里揉不进沙子", "责任感强，答应的事一定做到", "习惯自我批评", "对「对不对」比对「开不开心」更敏感"], "strengths": ["能把事做到位", "原则感强，可靠", "善于发现问题和改进点"], "weaknesses": ["容易挑剔和苛责", "完美主义拖慢进度", "情绪上容易积压不满"], "tip": "试着把「必须做对」换成「先做完再改」，你的标准已经够高了"}','{"chapters": [{"title": "深度画像", "content": "你内心有一套清晰的是非标准，相信按标准做事才安心，对自己的要求往往比对别人更严。"}, {"title": "思维与决策", "content": "决策前反复权衡对错，倾向选择更正确的选项，而不是更舒服的那个。"}, {"title": "职场与做事", "content": "适合需要严谨、规范和质量的岗位；混乱和敷衍会让你极度不适。"}, {"title": "关系与情感", "content": "爱之深责之切，关心常以指出问题的形式出现，容易让对方觉得被挑剔。"}, {"title": "压力与成长", "content": "压力下更苛责、更紧绷。成长是允许「够好」存在，也允许自己不完美。"}], "career": ["质量管理", "财务审计", "法务合规", "工程技术"], "famous": "团队里把方案挑到最后一版的人"}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'2','助人型','把别人照顾好，是我表达在乎的方式','把别人照顾好，是我表达在乎的方式','','{"strengths": ["共情和照顾人", "擅长维护关系", "愿意付出"], "weaknesses": ["边界感弱，容易透支", "付出后期待回报", "难以表达自己的需求"], "careers": ["客户服务", "人力资源", "护理健康", "社群运营"]}','{"one_liner": "把别人照顾好，是我表达在乎的方式", "traits": ["敏感，能迅速察觉别人的需要", "习惯主动帮忙", "渴望被需要", "很难拒绝人"], "strengths": ["共情和照顾人", "擅长维护关系", "愿意付出"], "weaknesses": ["边界感弱，容易透支", "付出后期待回报", "难以表达自己的需求"], "tip": "每周留一段只给自己的时间，那不是自私，是续航"}','{"chapters": [{"title": "深度画像", "content": "你对他人的情绪极其敏感，习惯通过帮忙来建立连接，被需要时最有存在感。"}, {"title": "思维与决策", "content": "决策常围绕对方会怎么想，容易为了关系牺牲自己的真实想法。"}, {"title": "职场与做事", "content": "适合服务、协调、支持类工作；纯竞争和冷冰冰的环境会消耗你。"}, {"title": "关系与情感", "content": "付出型，容易吸引索取型的人。需要学会筛选，而不是拯救。"}, {"title": "压力与成长", "content": "压力下更讨好、更委屈。成长是学会直接说出我也需要。"}], "career": ["客户服务", "人力资源", "护理健康", "社群运营"], "famous": "谁有麻烦第一个想到的那个人"}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'3','成就型','目标感拉满，停下来反而会慌','目标感拉满，停下来反而会慌','','{"strengths": ["执行力强", "能快速调整策略", "抗压，能打硬仗"], "weaknesses": ["容易把自我价值等同于成绩", "忽略情绪和关系", "为了效率牺牲深度"], "careers": ["销售", "项目管理", "创业", "市场运营"]}','{"one_liner": "目标感拉满，停下来反而会慌", "traits": ["效率优先", "适应力强", "在意形象和成果", "不喜欢没有进展"], "strengths": ["执行力强", "能快速调整策略", "抗压，能打硬仗"], "weaknesses": ["容易把自我价值等同于成绩", "忽略情绪和关系", "为了效率牺牲深度"], "tip": "给自己设一段不产出也没关系的时间，人不是 KPI"}','{"chapters": [{"title": "深度画像", "content": "你习惯用成果定义自己，擅长把目标拆成动作并迅速推进，停下来会有空虚感。"}, {"title": "思维与决策", "content": "决策以效率和结果为导向，能快速切换方案，对情绪成本耐心有限。"}, {"title": "职场与做事", "content": "适合有明确目标、能看见回报的岗位；长期没有反馈的事会让你失去动力。"}, {"title": "关系与情感", "content": "可靠能干，但容易把关系也当项目经营，需要练习不带目的地陪伴。"}, {"title": "压力与成长", "content": "压力下更急躁、更工作狂。成长是允许自己不做也可以。"}], "career": ["销售", "项目管理", "创业", "市场运营"], "famous": "群里永远在报进度、也最怕掉队的人"}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'4','浪漫型','渴望被真正看见，也不想和谁一样','渴望被真正看见，也不想和谁一样','','{"strengths": ["感受力和创造力", "能表达别人说不出的东西", "对美和真诚敏感"], "weaknesses": ["容易陷入情绪反刍", "羡慕别人所拥有的", "平淡时会觉得缺失"], "careers": ["内容创作", "视觉设计", "心理咨询", "艺术相关"]}','{"one_liner": "渴望被真正看见，也不想和谁一样", "traits": ["情绪细腻", "审美和自我表达欲强", "容易觉得自己与他人不同", "追求真实"], "strengths": ["感受力和创造力", "能表达别人说不出的东西", "对美和真诚敏感"], "weaknesses": ["容易陷入情绪反刍", "羡慕别人所拥有的", "平淡时会觉得缺失"], "tip": "把「缺的那块」写下来具体化，它往往没那么不可得"}','{"chapters": [{"title": "深度画像", "content": "你对真实和独特有强需求，渴望被完整地看见，也常被一种少了点什么的感觉驱动。"}, {"title": "思维与决策", "content": "决策重感受和真实，宁可吃亏也不愿假，因此有时显得不够务实。"}, {"title": "职场与做事", "content": "适合有表达、创作、审美空间的工作；机械重复会让你迅速枯萎。"}, {"title": "关系与情感", "content": "投入深，也容易因对方不够懂你而失望。需要学会直接表达需求，而不是等对方猜。"}, {"title": "压力与成长", "content": "压力下更沉溺情绪。成长是把感受转成作品，而不是转成内耗。"}], "career": ["内容创作", "视觉设计", "心理咨询", "艺术相关"], "famous": "朋友圈文案最有个人味道的那个人"}',4);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'5','观察型','先把世界看明白，再决定要不要参与','先把世界看明白，再决定要不要参与','','{"strengths": ["深度思考和钻研", "客观理性", "能独立解决复杂问题"], "weaknesses": ["回避社交和求助", "过度准备而不行动", "显得疏离"], "careers": ["研发工程", "数据分析", "学术研究", "系统设计"]}','{"one_liner": "先把世界看明白，再决定要不要参与", "traits": ["求知欲强", "需要大量独处", "克制，不轻易暴露情绪", "重视独立"], "strengths": ["深度思考和钻研", "客观理性", "能独立解决复杂问题"], "weaknesses": ["回避社交和求助", "过度准备而不行动", "显得疏离"], "tip": "给研究设一个截止点，先做出一版，再迭代"}','{"chapters": [{"title": "深度画像", "content": "你靠理解世界获得安全感，习惯退后一步观察，把精力留给真正感兴趣的事。"}, {"title": "思维与决策", "content": "决策前充分收集信息，重逻辑轻情绪，对未知领域先学再动。"}, {"title": "职场与做事", "content": "适合研究、分析、技术类岗位；频繁会议和社交是主要消耗。"}, {"title": "关系与情感", "content": "忠诚但不黏人，情感表达偏克制。亲密关系需要你主动分享内心。"}, {"title": "压力与成长", "content": "压力下更退缩、更隔离。成长是允许自己在没完全准备好时也能参与。"}], "career": ["研发工程", "数据分析", "学术研究", "系统设计"], "famous": "不怎么出现、一开口信息量最大的人"}',5);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'6','忠诚型','先想清楚最坏情况，我才敢往前走','先想清楚最坏情况，我才敢往前走','','{"strengths": ["预判风险", "尽责可靠", "危机中稳定"], "weaknesses": ["过度担忧，迟迟不敢行动", "容易怀疑他人", "压力下摇摆"], "careers": ["风控合规", "运维支持", "质量管理", "行政后勤"]}','{"one_liner": "先想清楚最坏情况，我才敢往前走", "traits": ["风险意识强", "重视承诺和忠诚", "容易焦虑", "依赖可靠的人或规则"], "strengths": ["预判风险", "尽责可靠", "危机中稳定"], "weaknesses": ["过度担忧，迟迟不敢行动", "容易怀疑他人", "压力下摇摆"], "tip": "把担心写下来并标上概率，你会发现大多数都不会发生"}','{"chapters": [{"title": "深度画像", "content": "你对安全感和确定性需求很高，习惯先设想最坏情况并准备预案，忠诚一旦给出很难收回。"}, {"title": "思维与决策", "content": "决策谨慎，需要可信的依据或可依靠的人，对突变适应较慢。"}, {"title": "职场与做事", "content": "适合需要严谨、风险把控、执行到位的岗位；朝令夕改最伤你。"}, {"title": "关系与情感", "content": "忠诚体贴，但需要反复确认对方的态度。稳定回应比惊喜更能安抚你。"}, {"title": "压力与成长", "content": "压力下更焦虑或更依赖权威。成长是给担心设时限，然后行动。"}], "career": ["风控合规", "运维支持", "质量管理", "行政后勤"], "famous": "出发前一定要把预案做全的那个人"}',6);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'7','享乐型','把日子过得有意思，比什么都重要','把日子过得有意思，比什么都重要','','{"strengths": ["创意和联想", "带动气氛", "适应变化快"], "weaknesses": ["三分钟热度", "回避沉重话题", "承诺恐惧"], "careers": ["市场策划", "产品创新", "活动运营", "内容创意"]}','{"one_liner": "把日子过得有意思，比什么都重要", "traits": ["乐观，点子多", "讨厌受限和无聊", "兴趣广泛", "回避痛苦情绪"], "strengths": ["创意和联想", "带动气氛", "适应变化快"], "weaknesses": ["三分钟热度", "回避沉重话题", "承诺恐惧"], "tip": "允许自己无聊十分钟，很多情绪需要被看见而不是被绕开"}','{"chapters": [{"title": "深度画像", "content": "你追求新鲜和可能性，擅长把局面变得有趣，也习惯用下一个来消化不愉快。"}, {"title": "思维与决策", "content": "决策乐观且快速，倾向保留选项，对长期约束本能抗拒。"}, {"title": "职场与做事", "content": "适合创意、开拓、需要脑洞的岗位；流程化执行和长期填表会消耗你。"}, {"title": "关系与情感", "content": "有趣慷慨，但面对沉重情绪容易转移话题，需要练习留下来倾听。"}, {"title": "压力与成长", "content": "压力下更浮躁或更逃避。成长是选一件事坚持到看到结果。"}], "career": ["市场策划", "产品创新", "活动运营", "内容创意"], "famous": "永远在计划下一次旅行的人"}',7);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'8','领袖型','我的地盘我做主，谁也别想欺负我在乎的人','我的地盘我做主，谁也别想欺负我在乎的人','','{"strengths": ["敢拍板敢担责", "危机中冲在前面", "护短，讲义气"], "weaknesses": ["强势，容易压过别人", "耐心偏低", "不擅长示弱"], "careers": ["团队管理", "创业", "商务谈判", "项目攻坚"]}','{"one_liner": "我的地盘我做主，谁也别想欺负我在乎的人", "traits": ["直接果断", "掌控欲强", "保护欲强", "不怕冲突"], "strengths": ["敢拍板敢担责", "危机中冲在前面", "护短，讲义气"], "weaknesses": ["强势，容易压过别人", "耐心偏低", "不擅长示弱"], "tip": "在表达立场前先问一句对方的想法，你会发现阻力小很多"}','{"chapters": [{"title": "深度画像", "content": "你对控制权和公平极度敏感，习惯站在前面扛事，对软弱和欺压零容忍。"}, {"title": "思维与决策", "content": "决策快且果断，凭直觉和力量感推进，对冗长讨论缺乏耐心。"}, {"title": "职场与做事", "content": "适合攻坚、管理、需要拍板的场景；被微观管控会让你窒息。"}, {"title": "关系与情感", "content": "直接忠诚、护短，但容易用强硬掩盖脆弱。亲密关系里需要练习示弱。"}, {"title": "压力与成长", "content": "压力下更具攻击性。成长是学会授权，也给别人发挥的空间。"}], "career": ["团队管理", "创业", "商务谈判", "项目攻坚"], "famous": "有人受委屈时第一个站出来的那个人"}',8);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'9','和平型','和和气气的，比争个对错重要','和和气气的，比争个对错重要','','{"strengths": ["包容，能调和矛盾", "稳定可靠", "善于倾听"], "weaknesses": ["难以表达自己的需求", "拖延，回避重要决定", "容易随波逐流"], "careers": ["行政后勤", "客服支持", "教务", "技术支持"]}','{"one_liner": "和和气气的，比争个对错重要", "traits": ["温和好相处", "回避冲突", "容易顺着别人", "追求安稳"], "strengths": ["包容，能调和矛盾", "稳定可靠", "善于倾听"], "weaknesses": ["难以表达自己的需求", "拖延，回避重要决定", "容易随波逐流"], "tip": "每天练习说一次自己的真实想法，哪怕只是选一顿饭"}','{"chapters": [{"title": "深度画像", "content": "你本能地维护和谐与平稳，习惯把别人的需求放在前面，也因此常忽略自己真正想要什么。"}, {"title": "思维与决策", "content": "决策偏保守，倾向维持现状，遇到冲突选择延后或回避。"}, {"title": "职场与做事", "content": "适合稳定、协作、服务类岗位；高频对抗和急剧变动会消耗你。"}, {"title": "关系与情感", "content": "包容体贴，但委屈会累积成被动抵抗。需要学会提前、平静地表达。"}, {"title": "压力与成长", "content": "压力下更拖延、更麻木。成长是意识到不选择本身也是一种选择。"}], "career": ["行政后勤", "客服支持", "教务", "技术支持"], "famous": "从不站队、但谁都愿意跟他聊的那个人"}',9);


-- =============================================================================
-- 九、霍兰德职业兴趣测评（全套数据）
-- -----------------------------------------------------------------------------
-- quiz_id=4：测评定义 + 6 个类型维度 + 30 道李克特题（每型 5 题）+ 6 型结果（含双档解析）。scoring_model=TOP3，取前三拼码（如 RIA/SEC）。由 tools/gen_reports.py 生成。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · 霍兰德职业兴趣测试（全套数据）
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 算分模型：scoring_model = TOP3 —— 累加取前三拼码。
--   结果不是预存的单行，而是按得分取前三的类型码拼成三字母（如 RIA/SEC）；
--   本文件 quiz_result 仍按 6 个类型维度各存一行（含双档解析），
--   后端取前三维后，把对应三行的报告组合返回即可。
-- 题型：李克特五点量表，30 道陈述题，
--       选项 非常不同意(1 分) → 非常同意(5 分)，全部指向同一个类型维度。
-- 用法：mysql ... < docs/seed-holland.sql（开头清 quiz_id=4 再重插，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 4);
DELETE FROM `question`        WHERE `quiz_id` = 4;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 4;
DELETE FROM `dimension`       WHERE `quiz_id` = 4;
DELETE FROM `quiz`            WHERE `id`      = 4;

-- 测评本体（scoring_model = TOP3）
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`emoji`,`tag`,`sort_order`,`question_count`,`price_coin`,`scoring_model`,`status`) VALUES
(4,'holland','霍兰德职业兴趣测试','测测你天生适合什么工作','霍兰德把职业兴趣分成现实、研究、艺术、社会、企业、常规六种，绝大多数人不是单一类型，而是以某几个为主。结果取你最靠前的三个类型拼成代码（如 RIA、SEC），它描述的是你和环境相处的方式，帮你少走几年弯路，而不是限定你只能做什么。','🧭','职业',4,0,0,'TOP3',1);

-- 类型维度（MAX/TOP3 模型下 dimension 一行 = 一个结果类型，pair_code 统一 TYPE）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(22,4,'R','现实型','TYPE',1),
(23,4,'I','研究型','TYPE',2),
(24,4,'A','艺术型','TYPE',3),
(25,4,'S','社会型','TYPE',4),
(26,4,'E','企业型','TYPE',5),
(27,4,'C','常规型','TYPE',6);

-- 题目（30 道，李克特五点量表）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (400,4,'我更喜欢动手操作、摆弄具体的东西而不是空想',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(400,'非常不同意',22,1,0),
(400,'不太同意',22,2,1),
(400,'一般',22,3,2),
(400,'比较同意',22,4,3),
(400,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (401,4,'摆弄工具、器械、设备让我觉得踏实',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(401,'非常不同意',22,1,0),
(401,'不太同意',22,2,1),
(401,'一般',22,3,2),
(401,'比较同意',22,4,3),
(401,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (402,4,'比起开会讨论，我更愿意去现场把事做出来',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(402,'非常不同意',22,1,0),
(402,'不太同意',22,2,1),
(402,'一般',22,3,2),
(402,'比较同意',22,4,3),
(402,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (403,4,'修理、组装、运动这类需要手巧的事我做着顺手',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(403,'非常不同意',22,1,0),
(403,'不太同意',22,2,1),
(403,'一般',22,3,2),
(403,'比较同意',22,4,3),
(403,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (404,4,'看得见摸得着的结果让我更有安全感',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(404,'非常不同意',22,1,0),
(404,'不太同意',22,2,1),
(404,'一般',22,3,2),
(404,'比较同意',22,4,3),
(404,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (405,4,'遇到不懂的现象，我会想搞清楚背后的原理',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(405,'非常不同意',23,1,0),
(405,'不太同意',23,2,1),
(405,'一般',23,3,2),
(405,'比较同意',23,4,3),
(405,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (406,4,'我喜欢独立钻研、自己找答案',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(406,'非常不同意',23,1,0),
(406,'不太同意',23,2,1),
(406,'一般',23,3,2),
(406,'比较同意',23,4,3),
(406,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (407,4,'抽象问题和逻辑推导对我很有吸引力',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(407,'非常不同意',23,1,0),
(407,'不太同意',23,2,1),
(407,'一般',23,3,2),
(407,'比较同意',23,4,3),
(407,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (408,4,'比起热闹社交，我更愿意待在实验室或书堆里',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(408,'非常不同意',23,1,0),
(408,'不太同意',23,2,1),
(408,'一般',23,3,2),
(408,'比较同意',23,4,3),
(408,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (409,4,'做决定前我希望数据或证据先说话',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(409,'非常不同意',23,1,0),
(409,'不太同意',23,2,1),
(409,'一般',23,3,2),
(409,'比较同意',23,4,3),
(409,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (410,4,'表达自我、创造独特的东西让我有成就感',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(410,'非常不同意',24,1,0),
(410,'不太同意',24,2,1),
(410,'一般',24,3,2),
(410,'比较同意',24,4,3),
(410,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (411,4,'我对美、氛围、情绪的感知很敏感',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(411,'非常不同意',24,1,0),
(411,'不太同意',24,2,1),
(411,'一般',24,3,2),
(411,'比较同意',24,4,3),
(411,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (412,4,'我不喜欢被固定流程和条条框框束缚',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(412,'非常不同意',24,1,0),
(412,'不太同意',24,2,1),
(412,'一般',24,3,2),
(412,'比较同意',24,4,3),
(412,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (413,4,'写东西、画画、做音乐这类事能让我沉浸',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(413,'非常不同意',24,1,0),
(413,'不太同意',24,2,1),
(413,'一般',24,3,2),
(413,'比较同意',24,4,3),
(413,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (414,4,'我常被有创意、不按常理出牌的人吸引',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(414,'非常不同意',24,1,0),
(414,'不太同意',24,2,1),
(414,'一般',24,3,2),
(414,'比较同意',24,4,3),
(414,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (415,4,'和人打交道、帮别人解决问题让我有动力',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(415,'非常不同意',25,1,0),
(415,'不太同意',25,2,1),
(415,'一般',25,3,2),
(415,'比较同意',25,4,3),
(415,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (416,4,'我擅长察觉别人的情绪并给予支持',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(416,'非常不同意',25,1,0),
(416,'不太同意',25,2,1),
(416,'一般',25,3,2),
(416,'比较同意',25,4,3),
(416,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (417,4,'比起独自钻研，我更喜欢团队和协作',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(417,'非常不同意',25,1,0),
(417,'不太同意',25,2,1),
(417,'一般',25,3,2),
(417,'比较同意',25,4,3),
(417,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (418,4,'教书、咨询、照护这类与人相关的事我做得来',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(418,'非常不同意',25,1,0),
(418,'不太同意',25,2,1),
(418,'一般',25,3,2),
(418,'比较同意',25,4,3),
(418,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (419,4,'被人信任、当成依靠让我有价值感',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(419,'非常不同意',25,1,0),
(419,'不太同意',25,2,1),
(419,'一般',25,3,2),
(419,'比较同意',25,4,3),
(419,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (420,4,'我乐于说服别人、推动事情往前走',21,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(420,'非常不同意',26,1,0),
(420,'不太同意',26,2,1),
(420,'一般',26,3,2),
(420,'比较同意',26,4,3),
(420,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (421,4,'我喜欢有目标、有竞争、能看到成果的事',22,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(421,'非常不同意',26,1,0),
(421,'不太同意',26,2,1),
(421,'一般',26,3,2),
(421,'比较同意',26,4,3),
(421,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (422,4,'带动一群人去实现一个想法让我兴奋',23,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(422,'非常不同意',26,1,0),
(422,'不太同意',26,2,1),
(422,'一般',26,3,2),
(422,'比较同意',26,4,3),
(422,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (423,4,'我不太怕承担风险和责任',24,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(423,'非常不同意',26,1,0),
(423,'不太同意',26,2,1),
(423,'一般',26,3,2),
(423,'比较同意',26,4,3),
(423,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (424,4,'我享受在众人面前表达、用影响力换反馈',25,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(424,'非常不同意',26,1,0),
(424,'不太同意',26,2,1),
(424,'一般',26,3,2),
(424,'比较同意',26,4,3),
(424,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (425,4,'按流程、规则、清单有条理地做事让我安心',26,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(425,'非常不同意',27,1,0),
(425,'不太同意',27,2,1),
(425,'一般',27,3,2),
(425,'比较同意',27,4,3),
(425,'非常同意',27,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (426,4,'我对数字、记录、细节的准确很在意',27,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(426,'非常不同意',27,1,0),
(426,'不太同意',27,2,1),
(426,'一般',27,3,2),
(426,'比较同意',27,4,3),
(426,'非常同意',27,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (427,4,'稳定的节奏和结构化的环境最舒服',28,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(427,'非常不同意',27,1,0),
(427,'不太同意',27,2,1),
(427,'一般',27,3,2),
(427,'比较同意',27,4,3),
(427,'非常同意',27,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (428,4,'我不喜欢混乱和随时变动',29,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(428,'非常不同意',27,1,0),
(428,'不太同意',27,2,1),
(428,'一般',27,3,2),
(428,'比较同意',27,4,3),
(428,'非常同意',27,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (429,4,'把繁杂的事务整理得井井有条让我有成就感',30,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(429,'非常不同意',27,1,0),
(429,'不太同意',27,2,1),
(429,'一般',27,3,2),
(429,'比较同意',27,4,3),
(429,'非常同意',27,5,4);

-- 结果类型（含初级 + 高级双档解析）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'R','现实型','动手比空谈更让我踏实','动手比空谈更让我踏实','','{"strengths": ["能落地执行", "不怕脏累和重复", "空间与机械感好"], "weaknesses": ["不太喜欢抽象讨论", "对人际政治耐心低", "文字表达偏弱"], "careers": ["工程技术", "机械维修", "农林园艺", "建筑施工"]}','{"one_liner": "动手比空谈更让我踏实", "traits": ["偏好具体操作", "务实，重视实际结果", "动手能力强", "喜欢可感知的成果"], "strengths": ["能落地执行", "不怕脏累和重复", "空间与机械感好"], "weaknesses": ["不太喜欢抽象讨论", "对人际政治耐心低", "文字表达偏弱"], "tip": "把大目标拆成可操作的步骤，你的价值在动手那一环最突出"}','{"chapters": [{"title": "深度画像", "content": "你是典型行动派，靠把东西实实在在做出来获得成就感，对空泛讨论天然无感。"}, {"title": "思维与决策", "content": "决策重可行和结果，倾向先试再想，对纸上谈兵容忍度低。"}, {"title": "职场与做事", "content": "适合需要实操、技术、现场的工作；纯文案和人际周旋会消耗你。"}, {"title": "关系与情感", "content": "实在、不绕弯，但容易被误会为不够浪漫或细腻。"}, {"title": "压力与成长", "content": "压力下更固执或逃避沟通。成长是补一点表达，让成果被看见。"}], "career": ["工程技术", "机械维修", "农林园艺", "建筑施工"], "famous": "东西坏了第一个动手修的人"}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'I','研究型','先弄懂原理，再决定怎么动','先弄懂原理，再决定怎么动','','{"strengths": ["深度思考", "客观理性", "能啃复杂问题"], "weaknesses": ["容易过度分析", "推动落地偏弱", "不擅长推销自己"], "careers": ["科研", "数据分析", "算法工程", "医药研发"]}','{"one_liner": "先弄懂原理，再决定怎么动", "traits": ["求知欲强", "偏好独立钻研", "重证据和逻辑", "不爱社交消耗"], "strengths": ["深度思考", "客观理性", "能啃复杂问题"], "weaknesses": ["容易过度分析", "推动落地偏弱", "不擅长推销自己"], "tip": "给研究设一个交付节点，先出一版再迭代，别等想透才动手"}','{"chapters": [{"title": "深度画像", "content": "你靠理解世界获得安全感，习惯先搞清原理再行动，对未知领域会自己查到底。"}, {"title": "思维与决策", "content": "决策前大量收集信息，重逻辑轻情绪，对拍脑袋反感。"}, {"title": "职场与做事", "content": "适合研究、分析、技术类岗位；频繁会议和强社交是主要消耗。"}, {"title": "关系与情感", "content": "忠诚但不黏人，表达克制，亲密关系需要你主动分享。"}, {"title": "压力与成长", "content": "压力下更封闭。成长是允许自己在没准备好时也参与。"}], "career": ["科研", "数据分析", "算法工程", "医药研发"], "famous": "不怎么出现、一开口信息量最大的人"}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'A','艺术型','不表达、不创造，我就空了','不表达、不创造，我就空了','','{"strengths": ["创造力和想象力", "能打动人", "对美敏感"], "weaknesses": ["不喜欢条框和重复", "情绪起伏大", "落地容易虎头蛇尾"], "careers": ["设计", "内容创作", "音乐艺术", "广告创意"]}','{"one_liner": "不表达、不创造，我就空了", "traits": ["审美和情绪感知强", "追求独特", "讨厌被框死", "表达欲强"], "strengths": ["创造力和想象力", "能打动人", "对美敏感"], "weaknesses": ["不喜欢条框和重复", "情绪起伏大", "落地容易虎头蛇尾"], "tip": "给灵感配一个最小交付节奏，创作也需要一点点纪律"}','{"chapters": [{"title": "深度画像", "content": "你对真实和独特有强需求，靠表达和创造确认自己的存在，反感千篇一律。"}, {"title": "思维与决策", "content": "决策重感受和美感，宁可绕路也要保住表达空间。"}, {"title": "职场与做事", "content": "适合有创作、审美、表达空间的工作；机械重复会让你枯萎。"}, {"title": "关系与情感", "content": "投入深，也容易被误解为情绪化。直接表达需求比等对方猜更有效。"}, {"title": "压力与成长", "content": "压力下更情绪化或自我怀疑。成长是把感受落成作品。"}], "career": ["设计", "内容创作", "音乐艺术", "广告创意"], "famous": "朋友圈审美最在线、文案最有个人味的人"}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'S','社会型','帮到人，我才觉得值','帮到人，我才觉得值','','{"strengths": ["共情和照顾", "沟通和协调", "让人安心"], "weaknesses": ["边界感弱", "容易透支", "回避冲突"], "careers": ["教师", "心理咨询", "医护", "社工"]}','{"one_liner": "帮到人，我才觉得值", "traits": ["善解人意", "偏好协作", "重视关系", "愿意付出"], "strengths": ["共情和照顾", "沟通和协调", "让人安心"], "weaknesses": ["边界感弱", "容易透支", "回避冲突"], "tip": "每周留一段只给自己的时间，照顾别人之前先稳住自己"}','{"chapters": [{"title": "深度画像", "content": "你从人与人的连接里获得意义，习惯通过支持他人来建立价值，被需要时最踏实。"}, {"title": "思维与决策", "content": "决策常围绕人的感受，容易为了关系牺牲自己的真实想法。"}, {"title": "职场与做事", "content": "适合教育、咨询、照护、协作类工作；纯竞争环境会消耗你。"}, {"title": "关系与情感", "content": "付出型，容易吸引索取型。需要学会筛选而非拯救。"}, {"title": "压力与成长", "content": "压力下更讨好。成长是直接说出我也需要。"}], "career": ["教师", "心理咨询", "医护", "社工"], "famous": "谁有麻烦第一个想到的那个人"}',4);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'E','企业型','把想法推成现实，比什么都带劲','把想法推成现实，比什么都带劲','','{"strengths": ["推动和执行", "说服与动员", "抗压"], "weaknesses": ["强势", "耐心低", "容易忽略细节"], "careers": ["销售管理", "创业", "项目管理", "商务"]}','{"one_liner": "把想法推成现实，比什么都带劲", "traits": ["目标导向", "爱影响人", "敢担责", "不怕竞争"], "strengths": ["推动和执行", "说服与动员", "抗压"], "weaknesses": ["强势", "耐心低", "容易忽略细节"], "tip": "在要求别人前先说清为什么，配合度会高一截"}','{"chapters": [{"title": "深度画像", "content": "你天然想主导和推动，靠把目标变成结果获得能量，对停滞不耐烦。"}, {"title": "思维与决策", "content": "决策快、重结果，能迅速调配资源，对情绪成本耐心有限。"}, {"title": "职场与做事", "content": "适合管理、销售、创业、需要影响力的岗位；被微观管控会窒息。"}, {"title": "关系与情感", "content": "直接忠诚，但容易把关系当项目推进，需要练习先听后说。"}, {"title": "压力与成长", "content": "压力下更具压迫感。成长是学会授权和解释动机。"}], "career": ["销售管理", "创业", "项目管理", "商务"], "famous": "发一句话就能把分工排完的人"}',5);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'C','常规型','有条理，我心里才不慌','有条理，我心里才不慌','','{"strengths": ["可靠", "细节把控", "流程化能力"], "weaknesses": ["抗拒变化", "灵活性不足", "显得刻板"], "careers": ["财务", "行政", "质检", "数据录入"]}','{"one_liner": "有条理，我心里才不慌", "traits": ["重视规则和流程", "细心", "追求准确", "偏好稳定"], "strengths": ["可靠", "细节把控", "流程化能力"], "weaknesses": ["抗拒变化", "灵活性不足", "显得刻板"], "tip": "允许计划有 10% 的临时调整区，你会轻松很多"}','{"chapters": [{"title": "深度画像", "content": "你靠秩序和确定性获得安全感，相信把每一步做对结果就不会错。"}, {"title": "思维与决策", "content": "依规则、流程、历史经验决策，对未经验证的新方法保持怀疑。"}, {"title": "职场与做事", "content": "适合财务、行政、运营、质量类需要精确的工作；混乱让你不适。"}, {"title": "关系与情感", "content": "踏实可靠，表达偏笨拙，常用把事做好代替说爱。"}, {"title": "压力与成长", "content": "压力下更固执。成长是接受没有完美流程。"}], "career": ["财务", "行政", "质检", "数据录入"], "famous": "交给他的事你从不催第二遍的人"}',6);


-- =============================================================================
-- 十、恋爱依恋类型测评（全套数据）
-- -----------------------------------------------------------------------------
-- quiz_id=5：测评定义 + 4 个类型维度 + 24 道李克特题（每型 6 题）+ 4 型结果（含双档解析）。scoring_model=MAX。由 tools/gen_reports.py 生成。
-- =============================================================================

-- =============================================================================
-- 探我趣测 · 恋爱依恋类型测试（全套数据）
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 算分模型：scoring_model = MAX —— 累加取最高分类型。
-- 题型：李克特五点量表，24 道陈述题，
--       选项 非常不同意(1 分) → 非常同意(5 分)，全部指向同一个类型维度。
-- 用法：mysql ... < docs/seed-attachment.sql（开头清 quiz_id=5 再重插，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 5);
DELETE FROM `question`        WHERE `quiz_id` = 5;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 5;
DELETE FROM `dimension`       WHERE `quiz_id` = 5;
DELETE FROM `quiz`            WHERE `id`      = 5;

-- 测评本体（scoring_model = MAX）
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`emoji`,`tag`,`sort_order`,`question_count`,`price_coin`,`scoring_model`,`status`) VALUES
(5,'attachment','恋爱依恋类型测试','你为什么会这样爱一个人','依恋类型来自童年和主要照顾者的互动模式，成年后体现在亲密关系里：你是能安心靠近，还是总在担心被弃，又或者一靠近就想逃。它不是标签，而是你理解自己恋爱模式的起点——看清了，才有得选。','💞','情感',5,0,0,'MAX',1);

-- 类型维度（MAX/TOP3 模型下 dimension 一行 = 一个结果类型，pair_code 统一 TYPE）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(28,5,'secure','安全型','TYPE',1),
(29,5,'anxious','焦虑型','TYPE',2),
(30,5,'avoidant','回避型','TYPE',3),
(31,5,'fearful','恐惧型','TYPE',4);

-- 题目（24 道，李克特五点量表）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (500,5,'我在亲密关系里既能靠近，也能保有自己',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(500,'非常不同意',28,1,0),
(500,'不太同意',28,2,1),
(500,'一般',28,3,2),
(500,'比较同意',28,4,3),
(500,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (501,5,'对方需要空间时，我不会立刻觉得是被抛弃',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(501,'非常不同意',28,1,0),
(501,'不太同意',28,2,1),
(501,'一般',28,3,2),
(501,'比较同意',28,4,3),
(501,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (502,5,'有矛盾我倾向于直接沟通，而不是冷战或逃跑',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(502,'非常不同意',28,1,0),
(502,'不太同意',28,2,1),
(502,'一般',28,3,2),
(502,'比较同意',28,4,3),
(502,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (503,5,'我对关系的基本信任比较稳定',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(503,'非常不同意',28,1,0),
(503,'不太同意',28,2,1),
(503,'一般',28,3,2),
(503,'比较同意',28,4,3),
(503,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (504,5,'被爱和被需要我都能安稳接受',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(504,'非常不同意',28,1,0),
(504,'不太同意',28,2,1),
(504,'一般',28,3,2),
(504,'比较同意',28,4,3),
(504,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (505,5,'我不太担心对方会突然离开',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(505,'非常不同意',28,1,0),
(505,'不太同意',28,2,1),
(505,'一般',28,3,2),
(505,'比较同意',28,4,3),
(505,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (506,5,'对方回消息慢一点，我就会胡思乱想',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(506,'非常不同意',29,1,0),
(506,'不太同意',29,2,1),
(506,'一般',29,3,2),
(506,'比较同意',29,4,3),
(506,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (507,5,'我常需要反复确认对方还爱不爱我',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(507,'非常不同意',29,1,0),
(507,'不太同意',29,2,1),
(507,'一般',29,3,2),
(507,'比较同意',29,4,3),
(507,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (508,5,'亲密关系里我很容易患得患失',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(508,'非常不同意',29,1,0),
(508,'不太同意',29,2,1),
(508,'一般',29,3,2),
(508,'比较同意',29,4,3),
(508,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (509,5,'为了不分开，我有时会委屈自己迁就对方',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(509,'非常不同意',29,1,0),
(509,'不太同意',29,2,1),
(509,'一般',29,3,2),
(509,'比较同意',29,4,3),
(509,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (510,5,'独处时我会格外想念对方，甚至坐立不安',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(510,'非常不同意',29,1,0),
(510,'不太同意',29,2,1),
(510,'一般',29,3,2),
(510,'比较同意',29,4,3),
(510,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (511,5,'我很怕被冷落、被忽略',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(511,'非常不同意',29,1,0),
(511,'不太同意',29,2,1),
(511,'一般',29,3,2),
(511,'比较同意',29,4,3),
(511,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (512,5,'太亲密会让我想往后退一步喘口气',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(512,'非常不同意',30,1,0),
(512,'不太同意',30,2,1),
(512,'一般',30,3,2),
(512,'比较同意',30,4,3),
(512,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (513,5,'我不喜欢把脆弱和情绪摊开给人看',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(513,'非常不同意',30,1,0),
(513,'不太同意',30,2,1),
(513,'一般',30,3,2),
(513,'比较同意',30,4,3),
(513,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (514,5,'依赖别人会让我不自在，我更相信自己',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(514,'非常不同意',30,1,0),
(514,'不太同意',30,2,1),
(514,'一般',30,3,2),
(514,'比较同意',30,4,3),
(514,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (515,5,'对方靠太近时，我会不自觉地疏远',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(515,'非常不同意',30,1,0),
(515,'不太同意',30,2,1),
(515,'一般',30,3,2),
(515,'比较同意',30,4,3),
(515,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (516,5,'感情里我更看重独立和空间',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(516,'非常不同意',30,1,0),
(516,'不太同意',30,2,1),
(516,'一般',30,3,2),
(516,'比较同意',30,4,3),
(516,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (517,5,'表达「我需要你」对我来说很难',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(517,'非常不同意',30,1,0),
(517,'不太同意',30,2,1),
(517,'一般',30,3,2),
(517,'比较同意',30,4,3),
(517,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (518,5,'我既渴望亲密，又害怕靠太近会受伤害',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(518,'非常不同意',31,1,0),
(518,'不太同意',31,2,1),
(518,'一般',31,3,2),
(518,'比较同意',31,4,3),
(518,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (519,5,'对方越靠近，我越想推开，又怕真被推开',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(519,'非常不同意',31,1,0),
(519,'不太同意',31,2,1),
(519,'一般',31,3,2),
(519,'比较同意',31,4,3),
(519,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (520,5,'信任别人对我来说很难，总在等被辜负',21,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(520,'非常不同意',31,1,0),
(520,'不太同意',31,2,1),
(520,'一般',31,3,2),
(520,'比较同意',31,4,3),
(520,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (521,5,'亲密关系里我常在前冲和逃避之间来回',22,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(521,'非常不同意',31,1,0),
(521,'不太同意',31,2,1),
(521,'一般',31,3,2),
(521,'比较同意',31,4,3),
(521,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (522,5,'我容易把小事解读成对方要离开的信号',23,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(522,'非常不同意',31,1,0),
(522,'不太同意',31,2,1),
(522,'一般',31,3,2),
(522,'比较同意',31,4,3),
(522,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (523,5,'越在乎一个人，我越表现得不在乎',24,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(523,'非常不同意',31,1,0),
(523,'不太同意',31,2,1),
(523,'一般',31,3,2),
(523,'比较同意',31,4,3),
(523,'非常同意',31,5,4);

-- 结果类型（含初级 + 高级双档解析）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(5,'secure','安全型','靠近你，也不会弄丢自己','靠近你，也不会弄丢自己','','{"strengths": ["关系韧性好", "沟通直接", "给人安全感"], "weaknesses": ["偶尔显得不够热烈", "对戏剧化冲突耐受低"], "careers": ["需要协作的岗位", "团队协调", "咨询照护"]}','{"one_liner": "靠近你，也不会弄丢自己", "traits": ["能亲密也能独立", "信任稳定", "冲突时愿意沟通", "情绪较稳"], "strengths": ["关系韧性好", "沟通直接", "给人安全感"], "weaknesses": ["偶尔显得不够热烈", "对戏剧化冲突耐受低"], "tip": "你的稳定是稀缺资源，别因为它不轰烈就怀疑它的价值"}','{"chapters": [{"title": "深度画像", "content": "你在亲密关系里能既靠近又独立，对「被爱」有基本信任，不把关系当成自我证明。"}, {"title": "思维与决策", "content": "冲突时倾向直面沟通，而不是冷战或讨好，能区分对方的情绪和自己的责任。"}, {"title": "职场与做事", "content": "协作类天然占优，是团队里可靠的缓冲带。"}, {"title": "关系与情感", "content": "你能稳定地给也稳定地接，伴侣通常觉得被托住而非被消耗。"}, {"title": "压力与成长", "content": "压力下仍较稳定，但别替对方过度承担。成长是允许自己偶尔示弱。"}], "career": ["需要协作的岗位", "团队协调", "咨询照护"], "famous": "关系里那个让对方不用猜的人"}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(5,'anxious','焦虑型','越在乎，越怕抓不住','越在乎，越怕抓不住','','{"strengths": ["投入深", "情感丰富", "愿意经营关系"], "weaknesses": ["患得患失", "容易自我怀疑", "用讨好保关系"], "careers": ["服务", "教育", "创意", "需要人际的岗位"]}','{"one_liner": "越在乎，越怕抓不住", "traits": ["重视亲密", "敏感于被忽视", "需要反复确认", "怕被抛弃"], "strengths": ["投入深", "情感丰富", "愿意经营关系"], "weaknesses": ["患得患失", "容易自我怀疑", "用讨好保关系"], "tip": "把「他回慢了=不爱了」写下来，你会发现中间还差十个推理步骤"}','{"chapters": [{"title": "深度画像", "content": "你对亲密有强需求，也常因不确定对方还在不在而内耗，爱得用力。"}, {"title": "思维与决策", "content": "对方一点冷淡都会被放大成要失去的信号，容易先发制人地讨或闹。"}, {"title": "职场与做事", "content": "在乎评价，协作中容易过度迁就，需练习表达边界。"}, {"title": "关系与情感", "content": "热情、黏，但对方被压得喘不过气时会反推。需要学会自我安抚。"}, {"title": "压力与成长", "content": "压力下更黏人或更自我攻击。成长是建立我是安全的自我对话。"}], "career": ["服务", "教育", "创意", "需要人际的岗位"], "famous": "那个恋爱里会反复问你爱不爱我的人"}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(5,'avoidant','回避型','靠近可以，别贴上来','靠近可以，别贴上来','','{"strengths": ["情绪自给", "不黏人", "理性"], "weaknesses": ["回避深度沟通", "用疏远应对冲突", "显得冷淡"], "careers": ["技术", "研究", "独立作业", "分析"]}','{"one_liner": "靠近可以，别贴上来", "traits": ["重视独立", "不轻易暴露脆弱", "需要空间", "怕被依赖"], "strengths": ["情绪自给", "不黏人", "理性"], "weaknesses": ["回避深度沟通", "用疏远应对冲突", "显得冷淡"], "tip": "试着每月说一次我其实需要在你身边，亲密不是失去自由"}','{"chapters": [{"title": "深度画像", "content": "你对亲密有本能防备，靠独立和空间获得安全感，靠近太猛会想退。"}, {"title": "思维与决策", "content": "冲突时倾向沉默、回避，而不是摊开谈，怕被情绪淹没。"}, {"title": "职场与做事", "content": "独立作业强，但深度协作需要练习主动同步。"}, {"title": "关系与情感", "content": "靠谱但克制，伴侣常觉得够不到你。需要练习把感受说出来。"}, {"title": "压力与成长", "content": "压力下更封闭。成长是允许自己在关系里偶尔不理性。"}], "career": ["技术", "研究", "独立作业", "分析"], "famous": "那个再亲密也留一扇门的人"}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(5,'fearful','恐惧型','想靠近，又怕靠太近会疼','想靠近，又怕靠太近会疼','','{"strengths": ["感受力强", "能共情", "一旦信任很投入"], "weaknesses": ["反复拉扯", "把小事读成被弃信号", "用不在乎保护自己"], "careers": ["需要支持但有边界的岗位", "创作", "咨询"]}','{"one_liner": "想靠近，又怕靠太近会疼", "traits": ["渴望亲密又怕受伤", "在靠近和推开间摇摆", "难信任", "容易自我防御"], "strengths": ["感受力强", "能共情", "一旦信任很投入"], "weaknesses": ["反复拉扯", "把小事读成被弃信号", "用不在乎保护自己"], "tip": "你推开对方的那一下，往往正是你最想被留住的时候——试着说出来"}','{"chapters": [{"title": "深度画像", "content": "你是焦虑与回避的混合，既渴望亲密又害怕靠太近受伤，于是反复靠近又逃开。"}, {"title": "思维与决策", "content": "越在乎越表现得不在乎，用疏离防御可能的被辜负，常把小事放大成危机。"}, {"title": "职场与做事", "content": "协作里忽冷忽热，需要稳定的反馈机制让自己安心。"}, {"title": "关系与情感", "content": "情深但难稳，伴侣容易在你推拉间疲惫。需要先把「我需要你」说出口。"}, {"title": "压力与成长", "content": "压力下更自我封闭或突然爆发。成长是识别防御动作，给关系一点耐心。"}], "career": ["需要支持但有边界的岗位", "创作", "咨询"], "famous": "那个嘴上说随便、心里在意很久的人"}',4);


-- =============================================================================
-- 十一、回填 quiz 表展示字段（question_count / emoji / tag）
-- -----------------------------------------------------------------------------
-- ①seed 插 quiz 行时题库还没插，question_count 写的是 0，不回填首页会显示「0 题」，这里按 question 表真实题数 UPDATE；②MBTI 行由 CSV 生成没带 emoji/tag，按 code 补上。幂等。
-- =============================================================================

-- =============================================================================
-- 回填 quiz 表的展示字段：question_count / emoji / tag（幂等，随便跑几次都一样）
-- -----------------------------------------------------------------------------
-- 为什么要回填这三列：
--   1) question_count：seed 插 quiz 行时题库还没插，一律写成 0，跑完没人回填，
--      于是首页 GET /api/quiz/list 拿到的 question_count 全是 0，前端显示「0 题」。
--      按 question 表真实题数 UPDATE 永远是对的（题库可能被重导、题目会被下架 status=0），
--      写死在 seed 里反而会对不上。
--   2) emoji / tag：MBTI 那行是从 CSV 生成的（tools/import_mbti_csv.py 只输题库），
--      没写 emoji/tag，结果首页唯独 MBTI 没图标(tag 也是 null)。
--      这里按 code 补上；只对 NULL/空值生效，手改过的不会被覆盖。
-- =============================================================================

UPDATE `quiz` q
SET question_count = (
    SELECT COUNT(*) FROM `question` WHERE quiz_id = q.id AND `status` = 1
)
WHERE EXISTS (SELECT 1 FROM `question` WHERE quiz_id = q.id);

UPDATE `quiz`
SET emoji = '🧠', tag = '性格'
WHERE `code` = 'mbti' AND (emoji IS NULL OR emoji = '');

-- 校验：应该看到 93 / 20 / 36 / 30 / 24，且 mbti 有 emoji
SELECT id, `code`, `name`, emoji, tag, question_count FROM `quiz` ORDER BY sort_order;


-- =============================================================================
-- 合并完成：guiz 库结构 + MBTI 数据应已就绪。
-- =============================================================================

