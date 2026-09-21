package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;
@Data
@TableName("user_platform")
public class UserPlatform {
    @TableId(type= IdType.AUTO)
    private Long id;
    private Long userId;
    private String platform;
    private String openid;
    //    服务端使用，禁止返回给前端
    private String sessionKey;
    private LocalDateTime updatedAt;
}
