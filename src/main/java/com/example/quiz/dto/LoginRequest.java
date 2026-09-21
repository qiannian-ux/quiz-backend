package com.example.quiz.dto;

import lombok.Data;

@Data
public class LoginRequest {
    private String code;
    private String platform;
}
