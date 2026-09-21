-- =============================================================================
-- 探我趣测 · 全量表结构（M4 用户体系 + M5 测评领域模型）
-- 数据库：MySQL 8.0      字符集：utf8mb4
-- 用法：本文件是「权威 schema」，全部 IF NOT EXISTS，可重复执行、不丢数据。
--       Spring Boot 启动默认不会自动跑本文件（生产库由运维手动管理）。
-- 生成日期：2026-09-19（由 docs/schema-full.sql 对齐而来，去掉了一次性 DROP）
-- =============================================================================
-- 设计主轴：内容层（quiz / dimension / question / question_option / quiz_result）
--          与数据层（user_quiz_record / user_quiz_answer）彻底分离。
--          加新测评 = 往内容层插数据，不改代码、不发版。
-- =============================================================================
-- ⚠️ 历史迁移：若你的库里还是 M3 练手版的 question(id,title) / question_option(id,question_id,content)
--   两张旧表（列结构不对），请先跑 docs/migrate-to-9tables.sql 做一次 DROP+重建，再回来跑本文件。
--   本文件用 IF NOT EXISTS，遇到已存在的旧表不会重建，会留下字段不匹配的隐患。
-- =============================================================================


-- =============================================================================
-- 一、用户体系（M4）
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
  `session_key` VARCHAR(128) NOT NULL DEFAULT ''     COMMENT '微信会话密钥，虚拟支付签名必需；严禁下发给前端',
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
  `basic_report`    JSON NULL COMMENT '初级解析（免费、云端下发）：{one_liner,traits[],strengths[],weaknesses[],tip}',
  `advanced_report` JSON NULL COMMENT '高级解析（深度报告）：{chapters:[{title,content}],career[],famous}',
  `sort_order` INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_quiz_type` (`quiz_id`, `type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='测评结果类型表';

-- 题目表（重建版，含 quiz_id / content / sort_order / status）
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

-- 选项表（重建版，选项指向维度 + 分值，兼容李克特量表）
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
-- 三、数据层：用户作答
-- =============================================================================

-- 一次测评的记录。user_id 允许为空 = 游客也能测。
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

-- 每题的作答明细。存在这张表，用户就能回看「我上次选了什么」。
CREATE TABLE IF NOT EXISTS `user_quiz_answer` (
  `id`          BIGINT   NOT NULL AUTO_INCREMENT,
  `record_id`   BIGINT   NOT NULL                COMMENT '关联 user_quiz_record.id',
  `question_id` BIGINT   NOT NULL,
  `option_id`   BIGINT   NOT NULL                COMMENT '用户实际选的选项',
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_record` (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户作答明细表';
