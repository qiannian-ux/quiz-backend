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
