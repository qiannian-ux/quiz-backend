package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 题目。对应 question 表。
 *
 * 注意：M3 练手版这里有个 List<String> options 字段（@TableField(exist=false)），
 * 现在删掉了 —— 因为选项不再只是字符串，还带维度码和分值，
 * 必须走 question_option 表。选项的组装交给 Service 层做，
 * 好处是能一次查完所有选项再内存分组（2 条 SQL），
 * 而不是每题查一次（N+1 条 SQL）。
 */
@Data
@TableName("question")
public class Question {
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 属于哪个测评，关联 quiz.id */
    private Long quizId;

    /** 题干 */
    private String content;

    /** 排序，越大越靠后 */
    private Integer sortOrder;

    /** 1 启用，0 停用 */
    private Integer status;

    private LocalDateTime createdAt;
}
