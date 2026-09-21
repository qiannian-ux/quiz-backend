-- =============================================================================
-- 动态测评：给 quiz 表补首页卡片展示字段
-- 适用：已存在 quiz 表、但还没有 emoji/tag/sort_order 列的库
-- 用法：mysql -h127.0.0.1 -uguiz -p123456 guiz < docs/quiz-list-columns.sql
-- 可重复执行（用 information_schema 判断，避免 MySQL8 不支持 ADD COLUMN IF NOT EXISTS）
-- =============================================================================

DROP PROCEDURE IF EXISTS `add_quiz_cols`;
DELIMITER $$
CREATE PROCEDURE `add_quiz_cols`()
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA='guiz' AND TABLE_NAME='quiz' AND COLUMN_NAME='emoji') THEN
    ALTER TABLE `quiz` ADD COLUMN `emoji` VARCHAR(16) NOT NULL DEFAULT '' COMMENT '卡片图标 emoji' AFTER `cover_url`;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA='guiz' AND TABLE_NAME='quiz' AND COLUMN_NAME='tag') THEN
    ALTER TABLE `quiz` ADD COLUMN `tag` VARCHAR(16) NOT NULL DEFAULT '' COMMENT '分类标签：性格/职业/情感/能力' AFTER `emoji`;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA='guiz' AND TABLE_NAME='quiz' AND COLUMN_NAME='sort_order') THEN
    ALTER TABLE `quiz` ADD COLUMN `sort_order` INT NOT NULL DEFAULT 0 COMMENT '首页展示顺序，越小越靠前' AFTER `tag`;
  END IF;
END$$
DELIMITER ;
CALL `add_quiz_cols`();
DROP PROCEDURE IF EXISTS `add_quiz_cols`;

-- 初始化 MBTI 行的展示字段（若为空）。新增测评同理，改 code/值即可。
UPDATE `quiz`
SET `emoji` = '🧠', `tag` = '性格', `sort_order` = 1
WHERE `code` = 'mbti' AND (`emoji` = '' OR `emoji` IS NULL);

-- 验证
-- SELECT code, name, emoji, tag, sort_order, status FROM quiz ORDER BY sort_order;
