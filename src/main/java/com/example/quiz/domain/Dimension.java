package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 维度定义。对应 dimension 表。MBTI 有 8 个：E/I/S/N/T/F/J/P。
 *
 * 两个关键字段，缺一个都算不对结果：
 *
 * pairCode —— 把互相对撞的两个维度配成一对（E 和 I 的 pairCode 都是 'EI'）。
 *   算分时按它分组比大小，谁分高取谁。没有它，程序不知道 E 该跟谁比。
 *
 * pairOrder —— 决定结果码里字母的先后顺序（MBTI：1=EI 2=SN 3=TF 4=JP）。
 *   不能按 pairCode 字母序排，字母序是 EI/JP/SN/TF，会拼出 EJST（错），
 *   正确顺序应是 ESTJ。这是真实踩过的坑。
 */
@Data
@TableName("dimension")
public class Dimension {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long quizId;

    /** 维度码，如 E */
    private String code;

    /** 维度名，如 外向 */
    private String name;

    /** 对撞组编码，如 EI */
    private String pairCode;

    /** 该组在结果码中的位置，从 1 开始 */
    private Integer pairOrder;

    private LocalDateTime createdAt;
}
