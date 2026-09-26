package com.example.quiz.controller;

import com.example.quiz.service.WeatherService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 天气接口（首页天气卡）
 * ------------------------------------------------------------
 *   GET /api/weather?city=成都
 *
 * 为什么不需要登录？天气是公开数据，且天气卡在游客态就要显示。
 * 已在 WebMvcConfig 的 JWT 白名单里加了一行 excludePathPatterns，
 * 不然这里会被拦截器挡成 401。
 *
 * 返回体由 WeatherService.WeatherResponse 决定：
 *   ok=true  -> 前端正常渲染
 *   ok=false -> 前端走降级（显示「获取失败 / 点一下重试」）
 * 两种情况都是 HTTP 200，失败原因放在 msg 里，方便你自己排查。
 */
@RestController
@RequestMapping("/api/weather")
public class WeatherController {

    private final WeatherService weatherService;

    public WeatherController(WeatherService weatherService) {
        this.weatherService = weatherService;
    }

    @GetMapping
    public WeatherService.WeatherResponse now(@RequestParam String city) {
        return weatherService.now(city);
    }
}
