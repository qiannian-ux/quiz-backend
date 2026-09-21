package com.example.quiz.controller;                      // controller 包

import com.example.quiz.domain.User;                      // user 表实体
import com.example.quiz.dto.LoginResponse;                // 返回用的 DTO
import com.example.quiz.mapper.UserMapper;                // 数据库操作
import com.example.quiz.util.UserContext;                 // ★ 当前用户从这里取
import org.springframework.web.bind.annotation.GetMapping;         // 处理 GET 请求
import org.springframework.web.bind.annotation.RequestMapping;     // 类级别的路径前缀
import org.springframework.web.bind.annotation.RestController;     // 接口类 + 自动转 JSON

@RestController                                           // = @Controller + @ResponseBody，返回值自动变 JSON
@RequestMapping("/api/user")                              // 这个类下所有接口的公共前缀
public class UserController {

    private final UserMapper userMapper;                  // 数据库操作

    public UserController(UserMapper userMapper) {
        this.userMapper = userMapper;
    }

    // 完整路径 = /api/user/me，只接受 GET
    @GetMapping("/me")
    public LoginResponse me() {                           // ★ 注意：没有任何入参！

        // 从 ThreadLocal 拿 userId —— 它是拦截器验完 token 后放进去的
        // 不是从请求参数拿的，所以前端伪造不了
        Long userId = UserContext.getUserId();

        // 按主键查用户
        User u = userMapper.selectById(userId);

        // 组装返回值
        LoginResponse resp = new LoginResponse();
        resp.setUserId(u.getId());                        // 用户 ID
        resp.setCoinBalance(u.getCoinBalance());          // 当前探币余额
        // 注意：没有 setSessionKey —— 敏感字段根本不在返回结构里

        return resp;                                      // Spring 自动转成 JSON 返回
    }
}
