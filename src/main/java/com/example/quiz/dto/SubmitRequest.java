package com.example.quiz.dto;

import lombok.Data;

import java.util.List;

/**
 * 提交作答的请求。
 *
 * 为什么只传 questionId + optionIndex，而不让前端直接传维度码和分值？
 *   前端传什么都是不可信的 —— 小程序包能被反编译，请求能被篡改。
 *   如果前端说"我选了 E 加 10 分"，后端照单全收，结果就完全可伪造了。
 *   只传"第几题的第几个选项"，维度和分值由后端查库决定，
 *   前端就没有任何造假空间。这是接口设计的基本安全意识。
 */
@Data
public class SubmitRequest {

    /** 测评编码，如 mbti */
    private String quizCode;

    private List<AnswerItem> answers;

    @Data
    public static class AnswerItem {
        private Long questionId;
        /** 选了第几个选项，从 0 开始 */
        private Integer optionIndex;
    }
}
