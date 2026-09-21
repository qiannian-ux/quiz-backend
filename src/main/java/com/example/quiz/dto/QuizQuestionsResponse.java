package com.example.quiz.dto;

import lombok.Data;

import java.util.List;

/**
 * 出题接口的返回结构。
 *
 * 字段刻意跟前端 data/questions.js 里的本地题保持一致
 * （content / options[].content / dimensionCode / score），
 * 这样前端的 normalizeRemoteQuestion 不用改，
 * 本地题和后端题在页面里长得一模一样。
 */
@Data
public class QuizQuestionsResponse {

    /** 测评编码，如 mbti */
    private String code;

    private String name;

    private List<QuestionItem> questions;

    @Data
    public static class QuestionItem {
        private Long id;
        private String content;
        private List<OptionItem> options;
    }

    @Data
    public static class OptionItem {
        private Long id;
        private String content;
        /** 维度码，如 E。前端算分兜底时会用到 */
        private String dimensionCode;
        private Integer score;
    }
}
