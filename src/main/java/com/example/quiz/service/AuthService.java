package com.example.quiz.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;  // MyBatis-Plus 的条件构造器
import com.example.quiz.domain.User;                 // user 表实体
import com.example.quiz.domain.UserPlatform;         // user_platform 表实体
import com.example.quiz.dto.LoginResponse;           // 返回给前端的 DTO
import com.example.quiz.mapper.UserMapper;           // user 表操作
import com.example.quiz.mapper.UserPlatformMapper;   // user_platform 表操作
import com.example.quiz.util.JwtUtil;
import com.example.quiz.util.AesUtil;                // JWT 工具
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;  // 事务注解

import java.time.LocalDateTime;

@Service
public class AuthService {
    // 四个依赖，全部 final，通过构造器注入（Spring 自动传进来）
    private final UserMapper userMapper;
    private final UserPlatformMapper userPlatformMapper;
    private final WxAuthService wxAuthService;
    private final JwtUtil jwtUtil;
    private final AesUtil aesUtil;          // session_key 加密（落地）

    public AuthService(UserMapper userMapper,
                       UserPlatformMapper userPlatformMapper,
                       WxAuthService wxAuthService,
                       JwtUtil jwtUtil,
                       AesUtil aesUtil) {
        this.userMapper = userMapper;
        this.userPlatformMapper = userPlatformMapper;
        this.wxAuthService = wxAuthService;
        this.jwtUtil = jwtUtil;
        this.aesUtil = aesUtil;
        // Spring 看到构造器需要什么，就自动从容器里找对应的 Bean 传进来，不用自己 new
    }

    @Transactional   // ★ 事务：方法里所有数据库操作要么全成功，要么全回滚
    public LoginResponse login(String code, String platform) {

        // ① 拿前端传来的 code，按平台去换 openid 和 session_key
        //    platform = "weixin" 走微信；platform = "toutiao" 走抖音（见 WxAuthService 内分支）
        WxAuthService.SessionResult session = wxAuthService.code2Session(code, platform);
        //    session.openid()     → 用户在你小程序的唯一 ID
        //    session.sessionKey() → 会话密钥（虚拟支付签名要用，必须存）

        // ② 查这个平台上，这个 openid 是不是已经注册过
        UserPlatform up = userPlatformMapper.selectOne(          // selectOne = 查一条
                new LambdaQueryWrapper<UserPlatform>()           // 条件构造器
                        .eq(UserPlatform::getPlatform, platform) // WHERE platform = ?
                        .eq(UserPlatform::getOpenid, session.openid())  // AND openid = ?
        );
        // ★ UserPlatform::getPlatform 是"方法引用"
        //   MyBatis-Plus 靠它反推出字段名：getPlatform → platform → 数据库列名 platform
        //   好处：写错字段名编译期就报错，不像手写字符串 "platform" 那样运行时才炸

        if (up == null) {
            // ③ 新用户：先建主账号
            User u = new User();
            u.setCoinBalance(0L);        // 新用户初始探币 0
            userMapper.insert(u);        // insert 后，MyBatis-Plus 会把自增 ID 回填进 u.getId()
            //   ↑ 这一步很关键：插入后 u.getId() 才有值，因为要靠它关联身份表

            // 再绑平台身份
            up = new UserPlatform();
            up.setUserId(u.getId());                 // 关联到刚建的主账号
            up.setPlatform(platform);                // 微信还是抖音
            up.setOpenid(session.openid());          // 平台给的唯一 ID
            up.setSessionKey(aesUtil.encrypt(session.sessionKey()));  // ★ 会话密钥加密后存库（虚拟支付要用）
            up.setUpdatedAt(LocalDateTime.now());
            userPlatformMapper.insert(up);

            // ★ 如果这里失败，因为 @Transactional，上面建的主账号也会回滚
            //   不会留下"有用户但没身份"的脏数据

        } else {
            // ④ 老用户：只更新 session_key
            up.setSessionKey(aesUtil.encrypt(session.sessionKey()));  // ★ 加密后更新！wx.login 每次都会刷新它
            up.setUpdatedAt(LocalDateTime.now());
            userPlatformMapper.updateById(up);       // 按主键更新
        }

        // ⑤ 组装返回值
        LoginResponse resp = new LoginResponse();
        resp.setUserId(up.getUserId());                          // 用户 ID
        resp.setToken(jwtUtil.generate(up.getUserId(), platform)); // 签发 JWT
        resp.setCoinBalance(userMapper.selectById(up.getUserId()).getCoinBalance()); // 查当前探币
        return resp;
        // ★ 注意：resp 里**没有** sessionKey —— DTO 白名单设计，物理上不可能泄露
    }
}
