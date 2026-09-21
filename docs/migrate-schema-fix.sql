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
