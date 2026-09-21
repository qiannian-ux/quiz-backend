package com.example.quiz.dto;

import lombok.Data;

import java.util.Map;

/**
 * 提交作答的返回。
 *
 * 2026-09-20 改：解析文案改为「云端下发」，前端不再自带文案。
 *   原因：文案要能随时改而不发版；且要做「初级解析 / 高级解析」两档，
 *   高级解析体量大，不适合塞进小程序包体。
 *   数据来源 quiz_result.basic_report / advanced_report。
 *
 * 前端仍需保留一份本地兜底（网络失败时给出最基础的结论），
 * 但正常路径必须是这里下发的文案。
 */
@Data
public class SubmitResponse {

    /** 结果类型码，如 INFP */
    private String type;

    /** 8 个维度各自的得分，如 {E: 18, I: 6, ...} */
    private Map<String, Integer> scores;

    /** 每组对撞谁胜出，如 {EI: "E", SN: "N", TF: "F", JP: "P"} */
    private Map<String, String> winner;

    /** 本次作答题数 */
    private Integer answerCount;

    /** 结果展示名，如 调停者（来自 quiz_result.name，前端不再硬编码） */
    private String resultName;

    /** 一句话总结，分享卡片 / 顶部标题用（来自 quiz_result.summary） */
    private String resultSummary;

    /**
     * 初级解析 JSON 字符串，免费、云端下发。
     * 结构：{one_liner, traits[], strengths[], weaknesses[], tip}
     */
    private String basicReport;

    /**
     * 高级解析 JSON 字符串，深度报告。
     * 结构：{chapters:[{title,content}], career[], famous}
     */
    private String advancedReport;
}
