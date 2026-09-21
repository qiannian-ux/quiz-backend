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
