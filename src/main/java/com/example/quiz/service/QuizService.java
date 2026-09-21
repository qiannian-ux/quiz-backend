package com.example.quiz.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.quiz.domain.*;
import com.example.quiz.dto.QuizListItem;
import com.example.quiz.dto.QuizQuestionsResponse;
import com.example.quiz.dto.SubmitRequest;
import com.example.quiz.dto.SubmitResponse;
import com.example.quiz.mapper.DimensionMapper;
import com.example.quiz.mapper.QuestionMapper;
import com.example.quiz.mapper.QuestionOptionMapper;
import com.example.quiz.mapper.QuizMapper;
import com.example.quiz.mapper.QuizResultMapper;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.ArrayNode;
import tools.jackson.databind.node.ObjectNode;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.Objects;

@Service
public class QuizService {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final QuizMapper quizMapper;
    private final QuestionMapper questionMapper;
    private final QuestionOptionMapper optionMapper;
    private final DimensionMapper dimensionMapper;
    private final QuizResultMapper resultMapper;

    /**
     * 算分中间结果。
     *   type     —— 发给前端的结果码（MBTI 是 INFP，霍兰德是 RIA）
     *   winner   —— 每组对撞谁胜出；非 MBTI 只有一个 TYPE 键（前端据此不显示维度条形图）
     *   topCodes —— 去 quiz_result 查解析行的类型码列表。
     *               单元素 = 直接取那一行；TOP3 是三个单字母 = 取三行再合并。
     */
    private record ScoreResult(String type, Map<String, String> winner, List<String> topCodes) {}

    public QuizService(QuizMapper quizMapper,
                       QuestionMapper questionMapper,
                       QuestionOptionMapper optionMapper,
                       DimensionMapper dimensionMapper,
                       QuizResultMapper resultMapper) {
        this.quizMapper = quizMapper;
        this.questionMapper = questionMapper;
        this.optionMapper = optionMapper;
        this.dimensionMapper = dimensionMapper;
        this.resultMapper = resultMapper;
    }

    /**
     * 按编码取测评，取不到就抛异常。
     * 抽出来是因为出题和算分都要用，避免两处各写一遍。
     */
    private Quiz requireQuiz(String code) {
        Quiz quiz = quizMapper.selectOne(
            new LambdaQueryWrapper<Quiz>().eq(Quiz::getCode, code)
        );
        if (quiz == null) {
            throw new IllegalArgumentException("测评不存在: " + code);
        }
        return quiz;
    }

    /**
     * 首页测评列表：返回所有上线(status=1)的测评，按 sortOrder 升序。
     *
     * 这是"动态测评"的命脉——前端首页完全由这个接口驱动，
     * 加 / 删一套测评 = 操作 quiz 表（INSERT / UPDATE status=0），无需改代码发版。
     * 游客可访问（WebMvcConfig 已把 /api/quiz/** 放进 JWT 白名单）。
     */
    public List<QuizListItem> listEnabled() {
        List<Quiz> quizzes = quizMapper.selectList(
            new LambdaQueryWrapper<Quiz>()
                .eq(Quiz::getStatus, 1)
                .orderByAsc(Quiz::getSortOrder)
        );
        List<QuizListItem> items = new ArrayList<>();
        for (Quiz q : quizzes) {
            QuizListItem item = new QuizListItem();
            item.setCode(q.getCode());
            item.setName(q.getName());
            item.setSubtitle(q.getSubtitle());
            item.setEmoji(q.getEmoji());
            item.setTag(q.getTag());
            item.setCoverUrl(q.getCoverUrl());
            item.setQuestionCount(q.getQuestionCount());
            item.setPriceCoin(q.getPriceCoin());
            items.add(item);
        }
        return items;
    }

    /**
     * 出题：返回一个测评下的全部题目和选项。
     *
     * 这里刻意只发 3 条 SQL（测评、题目、选项），
     * 然后在内存里把选项挂到对应题目上。
     * 如果写成「查完题目，循环每题查一次选项」，
     * 100 道题就是 101 条 SQL —— 这就是典型的 N+1 问题，
     * 数据量一大接口直接卡死。
     */
    public QuizQuestionsResponse getQuestions(String code) {
        Quiz quiz = requireQuiz(code);

        List<Question> questions = questionMapper.selectList(
            new LambdaQueryWrapper<Question>()
                .eq(Question::getQuizId, quiz.getId())
                .eq(Question::getStatus, 1)
                .orderByAsc(Question::getSortOrder)
        );
        if (questions.isEmpty()) {
            return null;
        }

        List<Long> questionIds = questions.stream().map(Question::getId).toList();

        List<QuestionOption> options = optionMapper.selectList(
            new LambdaQueryWrapper<QuestionOption>()
                .in(QuestionOption::getQuestionId, questionIds)
                .orderByAsc(QuestionOption::getQuestionId)
                .orderByAsc(QuestionOption::getSortOrder)
        );

        // dimensionId -> 维度码，选项里只存了 id，要映射成前端要的 code
        Map<Long, String> dimCode = dimensionMapper.selectList(
            new LambdaQueryWrapper<Dimension>().eq(Dimension::getQuizId, quiz.getId())
        ).stream().collect(Collectors.toMap(Dimension::getId, Dimension::getCode));

        Map<Long, List<QuestionOption>> optionsByQuestion =
            options.stream().collect(Collectors.groupingBy(QuestionOption::getQuestionId));

        List<QuizQuestionsResponse.QuestionItem> items = new ArrayList<>();
        for (Question q : questions) {
            QuizQuestionsResponse.QuestionItem item = new QuizQuestionsResponse.QuestionItem();
            item.setId(q.getId());
            item.setContent(q.getContent());

            List<QuizQuestionsResponse.OptionItem> optItems = new ArrayList<>();
            for (QuestionOption o : optionsByQuestion.getOrDefault(q.getId(), List.of())) {
                QuizQuestionsResponse.OptionItem oi = new QuizQuestionsResponse.OptionItem();
                oi.setId(o.getId());
                oi.setContent(o.getContent());
                oi.setDimensionCode(dimCode.get(o.getDimensionId()));
                oi.setScore(o.getScore());
                optItems.add(oi);
            }
            item.setOptions(optItems);
            items.add(item);
        }

        QuizQuestionsResponse resp = new QuizQuestionsResponse();
        resp.setCode(quiz.getCode());
        resp.setName(quiz.getName());
        resp.setQuestions(items);
        return resp;
    }

    /**
     * 算分。
     *
     * 流程：把作答还原成选项 -> 按维度累加分数 -> 每组对撞取高分 -> 拼类型码。
     *
     * 关键：维度码和分值**全部来自数据库**，
     * 前端只告诉后端"第几题选了第几个"，没有任何造假空间。
     */
    public SubmitResponse submit(SubmitRequest req) {
        Quiz quiz = requireQuiz(req.getQuizCode());

        List<Dimension> dims = dimensionMapper.selectList(
            new LambdaQueryWrapper<Dimension>().eq(Dimension::getQuizId, quiz.getId()).orderByAsc(Dimension::getPairOrder)
        );
        Map<Long, Dimension> dimById = dims.stream()
            .collect(Collectors.toMap(Dimension::getId, d -> d));

        List<Long> questionIds = req.getAnswers().stream()
            .map(SubmitRequest.AnswerItem::getQuestionId)
            .distinct()
            .toList();

        // 一次查出所有相关选项，按题目分组、组内按 sortOrder 排好，
        // 这样 optionIndex 就是分组后的下标
        Map<Long, List<QuestionOption>> optionsByQuestion = optionMapper.selectList(
            new LambdaQueryWrapper<QuestionOption>()
                .in(QuestionOption::getQuestionId, questionIds)
                .orderByAsc(QuestionOption::getQuestionId)
                .orderByAsc(QuestionOption::getSortOrder)
        ).stream().collect(Collectors.groupingBy(QuestionOption::getQuestionId));

        // 按维度 id 累加
        Map<Long, Integer> scoreByDimId = new HashMap<>();
        for (SubmitRequest.AnswerItem a : req.getAnswers()) {
            List<QuestionOption> opts = optionsByQuestion.get(a.getQuestionId());
            if (opts == null || opts.isEmpty()) continue;
            int idx = a.getOptionIndex() == null ? 0 : a.getOptionIndex();
            if (idx < 0 || idx >= opts.size()) continue;   // 越界直接跳过，不让它炸整个接口
            QuestionOption picked = opts.get(idx);
            int s = picked.getScore() == null ? 1 : picked.getScore();
            scoreByDimId.merge(picked.getDimensionId(), s, Integer::sum);
        }

        // 换算成 维度码 -> 分数
        Map<String, Integer> scores = new LinkedHashMap<>();
        dims.forEach(d -> scores.put(d.getCode(), 0));
        scoreByDimId.forEach((dimId, s) -> {
            Dimension d = dimById.get(dimId);
            if (d != null) scores.put(d.getCode(), s);
        });

        // 按 quiz.scoring_model 分流算分：
        // PAIR=MBTI 对撞拼码，MAX=DISC/九型/依恋取最高，TOP3=霍兰德取前三拼码。
        // 模型写在库里而不是写死在代码里：加新测评只需插数据，Java 一行不改。
        String model = quiz.getScoringModel() == null || quiz.getScoringModel().isEmpty()
            ? "PAIR" : quiz.getScoringModel();
        ScoreResult scored = switch (model) {
            case "MAX"  -> resolveMax(dims, scores);
            case "TOP3" -> resolveTop3(dims, scores);
            default     -> resolvePair(dims, scores);   // PAIR 是默认，未知值也兜到这
        };

        SubmitResponse resp = new SubmitResponse();
        resp.setType(scored.type());
        resp.setScores(scores);
        resp.setWinner(scored.winner());
        resp.setAnswerCount(req.getAnswers() == null ? 0 : req.getAnswers().size());

        // 解析文案云端下发：从 quiz_result 取初级/高级两档解析
        fillReports(quiz, scored, resp);
        return resp;
    }

    /**
     * PAIR（MBTI）：四组两两对撞，每组取高分字母拼成 4 字母。
     * E/I、S/N、T/F、J/P —— 结果像 ESTJ，而不是单一维度。
     * 这段就是原来写在 submit() 里的那堆代码，原样搬过来，只是最后返回值换了。
     */
    private ScoreResult resolvePair(List<Dimension> dims, Map<String, Integer> scores) {
        // 按对撞组归拢。同一组的 pairOrder 相同，取组里任意一个即可
        Map<String, List<Dimension>> byPair =
            dims.stream().collect(Collectors.groupingBy(Dimension::getPairCode));

        // 必须按 pairOrder 排序：字母序是 EI/JP/SN/TF，会拼出 EJST（错），
        // MBTI 正确顺序是 EI/SN/TF/JP，拼出来才是 ESTJ
        List<String> orderedPairs = byPair.values().stream()
            .map(list -> list.get(0))
            .sorted(Comparator.comparing(Dimension::getPairOrder))
            .map(Dimension::getPairCode)
            .toList();

        Map<String, String> winner = new LinkedHashMap<>();
        StringBuilder type = new StringBuilder();
        for (String pair : orderedPairs) {
            List<Dimension> members = byPair.get(pair);
            Dimension best = members.get(0);
            for (Dimension d : members) {
                // 平票时保持先遇到的那个（E/S/T/J），保证结果可预测
                if (scores.get(d.getCode()) > scores.get(best.getCode())) {
                    best = d;
                }
            }
            winner.put(pair, best.getCode());
            type.append(best.getCode());
        }
        return new ScoreResult(type.toString(), winner, List.of(type.toString()));
    }

    /**
     * MAX：各「类型维度」累加，取最高分的那个类型。
     * DISC / 九型 / 依恋用。平票按 pairOrder（类型序号）小者胜——
     * dims 已按 pairOrder 升序，严格大于才替换，先出现的自然保持胜者。
     */
    private ScoreResult resolveMax(List<Dimension> dims, Map<String, Integer> scores) {
        Dimension best = null;
        for (Dimension d : dims) {
            if (best == null
                    || scores.getOrDefault(d.getCode(), 0) > scores.getOrDefault(best.getCode(), 0)) {
                best = d;   // 平票（相等）不替换：序号小的赢，结果可复现
            }
        }
        Map<String, String> winner = new LinkedHashMap<>();
        winner.put("TYPE", best.getCode());
        return new ScoreResult(best.getCode(), winner, List.of(best.getCode()));
    }
    /**
     * TOP3：按得分取前三个类型拼成三字母码（如 RIA），平票按 pairOrder。
     * quiz_result 没有组合码的行，topCodes 保留三个单字母给 fillReports 合并用。
     */
    private ScoreResult resolveTop3(List<Dimension> dims, Map<String, Integer> scores) {
        List<Dimension> ranked = dims.stream()
                .sorted(Comparator
                        .comparing((Dimension d) -> scores.getOrDefault(d.getCode(), 0)).reversed()
                        .thenComparing(Dimension::getPairOrder))
                .toList();
        List<Dimension> top = ranked.subList(0, Math.min(3, ranked.size()));

        String type = top.stream().map(Dimension::getCode).collect(Collectors.joining());
        Map<String, String> winner = new LinkedHashMap<>();
        winner.put("TYPE", type);
        return new ScoreResult(type, winner, top.stream().map(Dimension::getCode).toList());
    }
    /**
     * 从 quiz_result 取双档解析填进响应。
     * topCodes 单元素 -> 直取那一行；多元素（TOP3）-> 合并（第 5 步）。
     * 库里查不到行时降级：名字用结果码顶上，报告留空——前端对空报告有兜底，
     * 但正常数据不该走到这，走到说明 seed 没灌全。
     */
    private void fillReports(Quiz quiz, ScoreResult s, SubmitResponse resp) {
        List<QuizResult> rows = resultMapper.selectList(
                new LambdaQueryWrapper<QuizResult>()
                        .eq(QuizResult::getQuizId, quiz.getId())
                        .in(QuizResult::getTypeCode, s.topCodes()));

        Map<String, QuizResult> byCode = rows.stream()
                .collect(Collectors.toMap(QuizResult::getTypeCode, r -> r, (a, b) -> a));

        List<QuizResult> ordered = s.topCodes().stream()
                .map(byCode::get)
                .filter(Objects::nonNull)
                .toList();

        if (ordered.isEmpty()) {
            resp.setResultName(s.type());
            return;
        }
        if (ordered.size() == 1) {
            QuizResult r = ordered.get(0);
            resp.setResultName(r.getName());
            resp.setResultSummary(r.getSummary());
            resp.setBasicReport(r.getBasicReport());
            resp.setAdvancedReport(r.getAdvancedReport());
            return;
        }
        mergeTop3Reports(ordered, resp);
    }

    /**
     * 第 5 步：把 TOP3 的三份解析合并成一份。
     *
     * 为什么非合并不可：quiz_result 只有 R/I/A/S/E/C 六行，运行时拼出的 RIA
     * 没有对应行，但前端一次只接一份 basicReport / advancedReport。
     *
     * 策略：主型（得分第一）的报告做骨架，副型（第二、第三）各补一点料。
     *   结果名   现实型 × 研究型 × 艺术型
     *   初级解析 主型的 one_liner / tip / weaknesses + 副型各补 1 条 traits、strengths
     *   深度报告 主型 5 章 + 追加 1 章「你的副型：X 与 Y」+ 副型的职业方向
     *
     * Jackson 是 spring-boot-starter-webmvc 自带的，不用加依赖。
     */
    private void mergeTop3Reports(List<QuizResult> ordered, SubmitResponse resp) {
        QuizResult primary = ordered.get(0);
        List<QuizResult> secondary = ordered.subList(1, ordered.size());
        try {
            // ---- 初级解析：以主型为底，副型各补 1 条 ----
            ObjectNode basic = (ObjectNode) MAPPER.readTree(
                primary.getBasicReport() == null ? "{}" : primary.getBasicReport());
            for (QuizResult r : secondary) {
                JsonNode b = MAPPER.readTree(r.getBasicReport() == null ? "{}" : r.getBasicReport());
                appendFirst(withArray(basic, "traits"), b.path("traits"), 1);
                appendFirst(withArray(basic, "strengths"), b.path("strengths"), 1);
            }
            cap(withArray(basic, "traits"), 6);
            cap(withArray(basic, "strengths"), 5);
            resp.setBasicReport(MAPPER.writeValueAsString(basic));

            // ---- 高级解析：主型 5 章 + 追加 1 章副型速览 ----
            ObjectNode adv = (ObjectNode) MAPPER.readTree(
                primary.getAdvancedReport() == null ? "{}" : primary.getAdvancedReport());

            ObjectNode extra = MAPPER.createObjectNode();
            extra.put("title", "你的副型：" + secondary.stream()
                .map(QuizResult::getName).collect(Collectors.joining(" 与 ")));
            StringBuilder sb = new StringBuilder();
            for (QuizResult r : secondary) {
                JsonNode b = MAPPER.readTree(r.getBasicReport() == null ? "{}" : r.getBasicReport());
                sb.append(r.getName()).append("：").append(b.path("one_liner").asText("")).append("。");
            }
            extra.put("content", sb.toString());
            withArray(adv, "chapters").add(extra);

            for (QuizResult r : secondary) {
                JsonNode a = MAPPER.readTree(r.getAdvancedReport() == null ? "{}" : r.getAdvancedReport());
                appendFirst(withArray(adv, "career"), a.path("career"), 2);
            }
            cap(withArray(adv, "career"), 6);
            resp.setAdvancedReport(MAPPER.writeValueAsString(adv));
        } catch (Exception e) {
            // JSON 坏了不让整个接口 500：降级为主型原文
            resp.setBasicReport(primary.getBasicReport());
            resp.setAdvancedReport(primary.getAdvancedReport());
        }
        resp.setResultName(ordered.stream().map(QuizResult::getName)
            .collect(Collectors.joining(" × ")));
        resp.setResultSummary(primary.getSummary());
    }

    /** 取 JSON 对象里的数组字段；不存在或不是数组就建个空数组放进去 */
    private static ArrayNode withArray(ObjectNode parent, String field) {
        JsonNode n = parent.get(field);
        if (n instanceof ArrayNode a) return a;
        ArrayNode arr = MAPPER.createArrayNode();
        parent.set(field, arr);
        return arr;
    }

    /** 从 source 数组取前 n 个追加到 target */
    private static void appendFirst(ArrayNode target, JsonNode source, int n) {
        if (source instanceof ArrayNode a) {
            for (int i = 0; i < Math.min(n, a.size()); i++) {
                target.add(a.get(i).deepCopy());
            }
        }
    }

    /** 数组封顶，超出部分从尾部删 */
    private static void cap(ArrayNode arr, int max) {
        while (arr.size() > max) arr.remove(arr.size() - 1);
    }
}
