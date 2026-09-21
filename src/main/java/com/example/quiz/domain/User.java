package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
@Data
@TableName("user")
public class User {
    @TableId(type= IdType.AUTO)
    private Long id;
    private Long coinBalance;
    private LocalDateTime createdAt;
}
