package com.example.quiz.controller;

import com.example.quiz.dto.QuizListItem;
import com.example.quiz.dto.QuizQuestionsResponse;
import java.util.List;
import com.example.quiz.dto.SubmitRequest;
import com.example.quiz.dto.SubmitResponse;
import com.example.quiz.service.QuizService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 测评接口。
 *
 * 两个接口就把整条链路跑通了：
 *   GET  /api/quiz/{code}   出题
 *   POST /api/quiz/submit   提交作答，返回类型码
 *
 * 都用 code（如 mbti）而不是数字 id 作为入参：
 *   id 是数据库自增的，本地库和线上库很可能不一样；
 *   code 是业务编码，两边永远一致。
 *   接口里暴露自增 id 还会让外部猜到你的数据量，能避就避。
 */
@RestController
@RequestMapping("/api/quiz")
public class QuizController {

    private final QuizService quizService;

    public QuizController(QuizService quizService) {
        this.quizService = quizService;
    }

    /**
     * 出题。游客也能调（未登录用户照样能测完），
     * 所以这个路径在 WebMvcConfig 里被排除在 JWT 拦截之外。
     */
    @GetMapping("/{code}")
    public QuizQuestionsResponse questions(@PathVariable String code) {
        return quizService.getQuestions(code);
    }

    /**
     * 首页测评列表。游客可访问（/api/quiz/** 已在 JWT 白名单）。
     * 返回所有上线测评的展示信息，前端据此动态渲染首页网格，
     * 不写死任何测评——加 / 删测评只需操作 quiz 表。
     */
    @GetMapping("/list")
    public List<QuizListItem> list() {
        return quizService.listEnabled();
    }

    /**
     * 提交作答并算分。
     * 入参只认 questionId + optionIndex，维度与分值一律由后端查库决定。
     */
    @PostMapping("/submit")
    public SubmitResponse submit(@RequestBody SubmitRequest request) {
        if (request == null || request.getAnswers() == null || request.getAnswers().isEmpty()) {
            throw new IllegalArgumentException("作答内容为空");
        }
        return quizService.submit(request);
    }
}
