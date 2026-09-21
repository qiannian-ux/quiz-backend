package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 测评结果类型。对应 quiz_result 表。
 *
 * MBTI 是 16 行（INFP、ENTJ…），DISC 4 行，九型 9 行，霍兰德 6 行（单字母），
 * 依恋 4 行。加新测评 = 插行，不是建表。
 *
 * 注意 TOP3（霍兰德）：结果码 RIA 是运行时拼出来的，表里没有这一行——
 * 表里只有 R/I/A/S/E/C 六行，所以服务层要「取三行合并」（见第 5 步）。
 */
@Data
@TableName("quiz_result")
public class QuizResult {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long quizId;

    /** 结果码，如 INFP；TOP3 测评是单字母 R/I/A… */
    private String typeCode;

    /** 结果名，如 调停者 / 现实型 */
    private String name;

    /** 一句话总结，分享卡片用 */
    private String summary;

    /** 详细解读（旧字段，新数据已迁到双档 JSON） */
    private String detail;

    private String imageUrl;

    /**
     * 三个 JSON 列一律声明成 String 直接透传：
     * MySQL JSON 列经 JDBC 读出来本来就是字符串，
     * MyBatis-Plus 驼峰映射 basic_report -> basicReport 自动完成，
     * 不需要 TypeHandler。后端不解析、不重组、原样发给前端（TOP3 合并除外）。
     */
    private String traits;
    private String basicReport;
    private String advancedReport;

    private Integer sortOrder;
}
