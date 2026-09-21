package com.example.quiz.dto;

import lombok.Data;

@Data
public class LoginResponse {
    private String token;
    private Long userId;
    private Long coinBalance;
}
