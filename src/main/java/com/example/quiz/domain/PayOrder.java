package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("pay_order")
public class PayOrder {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private String openid;
    private String outTradeNo;
    private String wxOrderId;     // 平台单号，幂等去重键
    private String productId;     // unlock_all / tip_milktea
    private Integer amountFen;    // 金额（分）
    private Integer status;       // 0 待支付 1 已发货 2 已退款
    private String attach;        // 透传数据（这里存 userId）
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
