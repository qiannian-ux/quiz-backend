package com.example.quiz.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

/**
 * 登录天数返回体。
 * ------------------------------------------------------------
 * 两个天数都以**服务端**为准 —— 前端只展示，不参与计算。
 *
 * ⚠️ 不含任何"应该发多少币"的字段：代币折算本次不实现，
 *    等真要做时由服务端按 user_login_day 重算，绝不信前端传上来的数。
 */
@Data
public class CheckinResponse {

    /** 累计登录天数。只增不减 */
    private Integer totalLoginDays;

    /** 连续登录天数。断签归 1（查询接口里若已断签则给 0） */
    private Integer consecutiveLoginDays;

    /**
     * 这次是不是"今天第一次登录"。
     * 字段名不带 is 前缀，但对外 JSON 要叫 isNewDay ——
     * Lombok 对 boolean newDay 生成的 getter 是 isNewDay()，
     * Jackson 默认会把它序列化成 "newDay"，跟前端约定对不上，
     * 所以这里显式指定一次。
     */
    @JsonProperty("isNewDay")
    private boolean newDay;
}
