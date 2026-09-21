package com.example.quiz.dto;

/**
 * 首页测评列表项。
 *
 * 只暴露首页卡片需要的展示字段，不携带题目/选项等重内容。
 * 由 Quiz 实体映射而来，前端据此动态渲染，不写死任何测评。
 */
public class QuizListItem {

    /** 业务编码，前端点卡片时带回，如 mbti */
    private String code;

    /** 展示名，如 MBTI 性格类型测试 */
    private String name;

    /** 副标题 / 一句话钩子 */
    private String subtitle;

    /** 卡片图标 emoji */
    private String emoji;

    /** 分类标签：性格 / 职业 / 情感 / 能力 */
    private String tag;

    /** 封面图（有则用，无则前端退 emoji） */
    private String coverUrl;

    /** 一次抽几题 */
    private Integer questionCount;

    /** 解锁完整报告所需探币，0 表示免费 */
    private Integer priceCoin;

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getSubtitle() { return subtitle; }
    public void setSubtitle(String subtitle) { this.subtitle = subtitle; }

    public String getEmoji() { return emoji; }
    public void setEmoji(String emoji) { this.emoji = emoji; }

    public String getTag() { return tag; }
    public void setTag(String tag) { this.tag = tag; }

    public String getCoverUrl() { return coverUrl; }
    public void setCoverUrl(String coverUrl) { this.coverUrl = coverUrl; }

    public Integer getQuestionCount() { return questionCount; }
    public void setQuestionCount(Integer questionCount) { this.questionCount = questionCount; }

    public Integer getPriceCoin() { return priceCoin; }
    public void setPriceCoin(Integer priceCoin) { this.priceCoin = priceCoin; }
}
