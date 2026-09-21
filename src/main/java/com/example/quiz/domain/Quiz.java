package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 测评本体。对应 quiz 表。
 *
 * 这张表存在的意义是"通用"：
 *   MBTI 是一行，将来九型人格、色彩性格各插一行，
 *   Java 代码一行都不用改 —— 所有题目、选项、维度都通过 quiz_id 挂在这下面。
 */
@Data
@TableName("quiz")
public class Quiz {
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 业务编码，接口里用它查，如 mbti */
    private String code;

    private String name;
    private String subtitle;
    private String description;
    private String coverUrl;

    /** 卡片图标 emoji，首页网格展示用 */
    private String emoji;

    /** 分类标签：性格 / 职业 / 情感 / 能力 */
    private String tag;

    /** 首页展示顺序，越小越靠前 */
    private Integer sortOrder;

    /** 一次抽几题，0 表示全出 */
    private Integer questionCount;

    /** 解锁完整报告所需探币，0 表示免费 */
    private Integer priceCoin;

    /**
     * 算分模型（2026-09-20 新增列 quiz.scoring_model）：
     *   PAIR = 按 dimension.pair_code 分组对撞取大，拼出多字母码（MBTI 的 4 字母）
     *   MAX  = 各「类型维度」累加取最高分那个（DISC、九型人格、恋爱依恋）
     *   TOP3 = 累加取前三拼码（霍兰德 RIASEC 三码）
     * 后端算分必须按这个字段分流，不要写死 MBTI 的对撞逻辑。
     */
    private String scoringModel;

    /** 1 上线，0 下线 */
    private Integer status;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
