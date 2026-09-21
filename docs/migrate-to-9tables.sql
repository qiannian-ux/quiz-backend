-- =============================================================================
-- 探我趣测 · 历史迁移（一次性）
-- 目标：把 M3 练手版的两张旧表 question(id,title) / question_option(id,question_id,content)
--       升级成 M5 新结构（多列 + 维度/分值），让运行库拥有完整 9 表。
-- 适用：仅当你执行 `SHOW TABLES;` 后，question / question_option 仍是上面的旧列结构时。
-- ⚠️ 危险：本文件会 DROP 这两张表再重建，旧表里的数据会丢失。
--   若 question 已是新结构（含 quiz_id/content/sort_order/status），不要跑本文件，
--   直接跑 src/main/resources/schema.sql 即可。
-- 执行前先确认：
--   USE guiz;
--   DESCRIBE question;   -- 若只有 id / title 两列 → 需要本迁移
-- =============================================================================

DROP TABLE IF EXISTS `question_option`;
DROP TABLE IF EXISTS `question`;

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
