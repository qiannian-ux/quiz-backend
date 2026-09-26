package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 用户登录日期明细：每个用户每天最多一行。
 * ------------------------------------------------------------
 * 累计登录天数 = COUNT(*)，连续登录天数从这里回推。
 *
 * 为什么要有明细表，而不只在 user 上存两个计数？
 *   1. UNIQUE(user_id, login_date) 让"同一天只算一次"由数据库保证，
 *      应用侧不用先查再判断，也不怕并发下重复插入；
 *   2. 以后按天数折算代币，必须能查账 —— 计数只能给出结果，明细能说清
 *      "这 12 天分别是哪 12 天"。
 *
 * ⚠️ login_date 一律由服务端生成（LoginDayService 里的 LocalDate.now(上海时区)），
 *    绝不接受前端传日期参数。
 */
@Data
@TableName("user_login_day")
public class UserLoginDay {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 关联 user.id */
    private Long userId;

    /** 登录日期（Asia/Shanghai 时区的"今天"） */
    private LocalDate loginDate;

    private LocalDateTime createdAt;
}
