package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
@Data
@TableName("user")
public class User {
    @TableId(type= IdType.AUTO)
    private Long id;
    private Long coinBalance;
    private LocalDateTime createdAt;

    /**
     * 累计登录天数。
     * ------------------------------------------------------------
     * ⚠️ 这是冗余列，真实数据在 user_login_day 明细表里（COUNT(*)）。
     *    冗余只为了读得快；两边一旦对不上，**以明细表为准**。
     *
     * 为什么必须存后端？这个字段以后要按天数折算代币，
     * 前端本地存储能被清、被改、换设备不同步，拿它结算等于白送。
     */
    private Integer totalLoginDays;

    /** 连续登录天数。断签归 1，同一天多次登录不加 */
    private Integer consecutiveLoginDays;

    /** 最近一次登录的日期。判断"是否连续"就靠它和今天比 */
    private LocalDate lastLoginDate;
}
