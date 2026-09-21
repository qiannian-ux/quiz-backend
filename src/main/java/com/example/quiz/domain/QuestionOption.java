package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 题目选项。对应 question_option 表。
 *
 * 为什么单独成表，而不是在 question 里写死 option_a / option_b 两列：
 *   写死就只能支持两个选项。独立成表后，
 *   未来上李克特量表（非常不同意→非常同意，五档）直接插五行就行，
 *   Java 代码一行都不用改。
 */
@Data
@TableName("question_option")
public class QuestionOption {
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 属于哪道题，关联 question.id */
    private Long questionId;

    /** 选项文案 */
    private String content;

    /** 选它给哪个维度加分，关联 dimension.id */
    private Long dimensionId;

    /** 加分值，默认 1 */
    private Integer score;

    private Integer sortOrder;
}
