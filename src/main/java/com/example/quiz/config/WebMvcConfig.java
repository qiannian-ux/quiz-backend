package com.example.quiz.config;                          // 新建的 config 包

import com.example.quiz.interceptor.JwtInterceptor;       // 要注册的拦截器
import org.springframework.context.annotation.Configuration;  // 标记为"配置类"
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;   // 拦截器注册器
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;      // MVC 配置扩展接口

@Configuration                                            // Spring 启动时会读取这个类里的配置
public class WebMvcConfig implements WebMvcConfigurer {   // 实现接口才能改 MVC 的行为

    private final JwtInterceptor jwtInterceptor;          // 注入拦截器

    public WebMvcConfig(JwtInterceptor jwtInterceptor) {
        this.jwtInterceptor = jwtInterceptor;
    }

    // 重写这个方法 = 自定义拦截器规则
    @Override
    public void addInterceptors(InterceptorRegistry registry) {

        registry.addInterceptor(jwtInterceptor)           // 注册我们的拦截器
                .addPathPatterns("/api/**")               // 拦截范围：/api 下所有接口（** 表示任意层级）
                .excludePathPatterns(                     // 例外：这些路径不拦截
                        "/api/auth/login",                // 登录接口必须放行，不然用户没法登录
                        "/api/quiz/**"                    // 出题与提交：游客也要能完整测完，所以放行
                                                          // 用 ** 是因为出题路径带变量 /api/quiz/{code}
                                                          // 等以后做"登录用户才能解锁完整报告"，再把提交接口收回来
                );
    }
}
