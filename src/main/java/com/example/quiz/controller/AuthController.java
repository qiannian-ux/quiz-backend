package com.example.quiz.controller;

import com.example.quiz.dto.LoginRequest;    // 接收请求体的 DTO
import com.example.quiz.dto.LoginResponse;   // 返回响应体的 DTO
import com.example.quiz.service.AuthService;
import org.springframework.web.bind.annotation.*;   // * 通配导入所有注解
@RestController
@RequestMapping("api/auth")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }
    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest req) {
        // @RequestBody：把请求体里的 JSON 自动转成 LoginRequest 对象
        // 前端传 { "code": "xxx", "platform": "weixin" }
        // 就自动变成 req.getCode() / req.getPlatform()
        return authService.login(req.getCode(), req.getPlatform());
        // 返回的 LoginResponse 会被 Spring 自动转成 JSON 给前端
    }
}
