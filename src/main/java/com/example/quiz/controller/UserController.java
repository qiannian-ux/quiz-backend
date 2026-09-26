package com.example.quiz.controller;                      // controller 包

import com.example.quiz.domain.User;                      // user 表实体
import com.example.quiz.dto.CheckinResponse;              // 登录天数返回体
import com.example.quiz.dto.LoginResponse;                // 返回用的 DTO
import com.example.quiz.mapper.UserMapper;                // 数据库操作
import com.example.quiz.service.LoginDayService;          // 登录天数（权威在后端）
import com.example.quiz.util.UserContext;                 // ★ 当前用户从这里取
import org.springframework.web.bind.annotation.GetMapping;         // 处理 GET 请求
import org.springframework.web.bind.annotation.PostMapping;        // 处理 POST 请求
import org.springframework.web.bind.annotation.RequestMapping;     // 类级别的路径前缀
import org.springframework.web.bind.annotation.RestController;     // 接口类 + 自动转 JSON

@RestController                                           // = @Controller + @ResponseBody，返回值自动变 JSON
@RequestMapping("/api/user")                              // 这个类下所有接口的公共前缀
public class UserController {

    private final UserMapper userMapper;                  // 数据库操作
    private final LoginDayService loginDayService;        // 登录天数

    public UserController(UserMapper userMapper, LoginDayService loginDayService) {
        this.userMapper = userMapper;
        this.loginDayService = loginDayService;
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

    /**
     * 登录打点：记一次今天的登录，返回累计 / 连续天数。
     * ------------------------------------------------------------
     * ★ 这个接口**没有放进 JWT 白名单**（白名单只有 auth/login、quiz/**、weather），
     *   所以游客调用会被拦成 401 —— 这是有意的：没登录就没有 user_id，
     *   记不了账。前端拿到 401 会静默降级为本地估算并标注"未同步"。
     *
     * ★ 可以随便重复调用：服务端用 INSERT IGNORE + UNIQUE(user_id, login_date)，
     *   同一天无论调多少次都只会有一行。前端每次进前台调一次即可，
     *   不用自己做去重。
     *
     * ★ 不接受任何日期参数：日期由服务端按 Asia/Shanghai 生成，
     *   前端传什么都不认，杜绝改手机时间刷天数。
     */
    @PostMapping("/checkin")
    public CheckinResponse checkin() {
        Long userId = UserContext.getUserId();             // 从 JWT 来，不是请求参数
        return loginDayService.checkin(userId);
    }

    /**
     * 只读查询登录天数，不打点。
     * 页面想刷新数字又不需要上报时用。
     */
    @GetMapping("/checkin-stats")
    public CheckinResponse checkinStats() {
        Long userId = UserContext.getUserId();
        return loginDayService.stats(userId);
    }
}
