-- =============================================================================
-- 累计登录天数 / 连续登录天数（权威数据在后端）
-- -----------------------------------------------------------------------------
-- 为什么必须放后端？
--   这个字段未来要按天数折算代币。前端本地存储能被清、被改、换设备还不同步，
--   拿它当结算依据等于白送。所以：
--     · 日期一律由服务端生成（CURDATE()），前端不许传日期
--     · 同一天只记一次，靠数据库 UNIQUE 约束保证，不靠应用逻辑判断
--     · 前端只负责展示，拿不到后端数据时才用本地估算兜底（并标注未同步）
--
-- 设计：
--   1. user_login_day 明细表 —— 每用户每天一行，UNIQUE(user_id, login_date)。
--      累计天数 = COUNT(*)，连续天数从这张表回推，可审计、可对账。
--   2. user 表三个冗余列 —— 纯为读取快。它们始终可以由明细表重算出来，
--      一旦对不上，以明细表为准（写个重算脚本就能修）。
--
-- 用法：mysql ... < docs/migrate-login-days.sql（幂等，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- ⚠️ 时区必须和 Java 侧一致（LoginDayService 里写死 Asia/Shanghai）。
--    服务器/MySQL 默认时区常常是 UTC，那会差 8 小时：
--    用户北京时间早上 8 点前打开，会被算成"前一天"。
--    这里按会话设一次，保证 CURDATE() 与服务端打点用的是同一个"今天"。
SET time_zone = '+08:00';

-- -----------------------------------------------------------------------------
-- 一、登录日期明细表
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_login_day` (
  `id`         BIGINT   NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT   NOT NULL                COMMENT '关联 user.id',
  `login_date` DATE     NOT NULL                COMMENT '登录日期，由服务端 CURDATE() 生成，前端不可传',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- 这条约束就是"同一天只算一次"的全部实现：重复插入走 INSERT IGNORE 即可，
  -- 不需要在应用里先查一次再决定插不插（还避免并发下重复插入）
  UNIQUE KEY `uk_user_date` (`user_id`, `login_date`),
  KEY `idx_date` (`login_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户登录日期明细：累计与连续天数都从这张表算';

-- -----------------------------------------------------------------------------
-- 二、user 表冗余列（幂等：列已存在则跳过）
--    MySQL 8 不支持 ADD COLUMN IF NOT EXISTS，所以用 information_schema 判断 + 动态 SQL
-- -----------------------------------------------------------------------------
SET @db := DATABASE();

-- total_login_days：累计登录天数（只增）
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'user'
                  AND COLUMN_NAME = 'total_login_days');
SET @sql := IF(@exists = 0,
  'ALTER TABLE `user` ADD COLUMN `total_login_days` INT NOT NULL DEFAULT 0 COMMENT ''累计登录天数，冗余，以 user_login_day 为准''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- consecutive_login_days：连续登录天数（断签归 1）
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'user'
                  AND COLUMN_NAME = 'consecutive_login_days');
SET @sql := IF(@exists = 0,
  'ALTER TABLE `user` ADD COLUMN `consecutive_login_days` INT NOT NULL DEFAULT 0 COMMENT ''连续登录天数，断签即归 1''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- last_login_date：最近一次登录日期，用来判断是否连续
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'user'
                  AND COLUMN_NAME = 'last_login_date');
SET @sql := IF(@exists = 0,
  'ALTER TABLE `user` ADD COLUMN `last_login_date` DATE NULL COMMENT ''最近一次登录日期，判断是否连续''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- 三、老用户迁移
--    判据：那天留下过测评记录，就说明那天登录过（user_quiz_record 带 created_at）。
--    这样老用户的历史积累不会凭空归零，比"统一从 1 开始"公平得多。
-- -----------------------------------------------------------------------------

-- 3.1 按已有测评记录补登录明细
INSERT IGNORE INTO `user_login_day` (`user_id`, `login_date`)
SELECT DISTINCT `user_id`, DATE(`created_at`)
FROM `user_quiz_record`
WHERE `user_id` IS NOT NULL;

-- 3.2 补上今天：保证每个用户至少有一条，且连续天数从今天起算
INSERT IGNORE INTO `user_login_day` (`user_id`, `login_date`)
SELECT `id`, CURDATE() FROM `user`;

-- 3.3 回填累计天数与最后登录日
UPDATE `user` u SET
  `total_login_days` = (SELECT COUNT(*) FROM `user_login_day` d WHERE d.`user_id` = u.`id`),
  `last_login_date`  = (SELECT MAX(d.`login_date`) FROM `user_login_day` d WHERE d.`user_id` = u.`id`);

-- 3.4 连续天数
--     SQL 里算"连续"可读性很差，这里给一个保守值：
--     有历史记录的一律先给 1，用户下次登录时由代码按真实连续性刷新。
--     （若要精确回填：写一次性任务按 login_date 倒序回推，遇断档即停）
UPDATE `user` SET `consecutive_login_days` = 1 WHERE `total_login_days` > 0;

-- -----------------------------------------------------------------------------
-- 四、校验（手工跑一下，确认迁移没跑歪）
-- -----------------------------------------------------------------------------
-- SELECT u.id, u.total_login_days, u.consecutive_login_days, u.last_login_date,
--        (SELECT COUNT(*) FROM user_login_day d WHERE d.user_id = u.id) AS detail_count
-- FROM `user` u ORDER BY u.id LIMIT 20;
