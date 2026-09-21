-- 本地/线上库体检（只读，随便跑）
-- 用法：
--   java -cp <mysql-connector-j.jar> tools/SqlRun.java \
--        "jdbc:mysql://127.0.0.1:3306/guiz?serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&useSSL=false" guiz 123456 tools/sql/inspect-local.sql

SELECT id, `code`, `name`, scoring_model, `status`, question_count FROM `quiz` ORDER BY id;

SELECT 'question' AS tbl, quiz_id, COUNT(*) AS cnt FROM question GROUP BY quiz_id
UNION ALL SELECT 'quiz_result', quiz_id, COUNT(*) FROM quiz_result GROUP BY quiz_id
UNION ALL SELECT 'dimension', quiz_id, COUNT(*) FROM dimension GROUP BY quiz_id;

SELECT COLUMN_NAME, COLUMN_TYPE FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'quiz_result'
ORDER BY ORDINAL_POSITION;
