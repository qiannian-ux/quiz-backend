package com.example.quiz.interceptor;

import com.example.quiz.util.JwtUtil;
import com.example.quiz.util.UserContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
@Component
public class JwtInterceptor implements HandlerInterceptor {
    private final JwtUtil jwtUtil;

    public JwtInterceptor(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }
    /**
     * preHandle：在请求进入 Controller 之前执行
     * 返回 true  = 放行，继续走 Controller
     * 返回 false = 拦截，直接结束，Controller 不会被执行
     */

    public boolean preHandle(HttpServletRequest request,      // 能拿到请求头、参数等
                             HttpServletResponse response,    // 能写响应状态码和内容
                             Object handler) throws Exception {  // handler = 即将执行的 Controller 方法

        // 跨域预检请求（浏览器发正式请求前先发的 OPTIONS 探测）不带 token，
        // 必须放行，否则前端跨域调用会全部失败
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;                                  // 放行
        }
        String auth = request.getHeader("Authorization");
        if (auth==null||!auth.startsWith("Bearer ")){
            write401(response,"未登录");
            return false;
        }
        String token=auth.substring(7);
        try{
            Long userId = jwtUtil.getUserId(token);
            UserContext.setUserId(userId);
            return true;
        }catch (Exception e){
            write401(response,"登录已失效");
            return false;
        }
    }
    /**
     * afterCompletion：整个请求彻底结束后执行（★ 无论成功还是抛异常都会走这里）
     * 清理必须放这个方法，不能放 postHandle —— 因为 postHandle 在 Controller 抛异常时不会执行
     */
    @Override
    public void afterCompletion(HttpServletRequest request,
                                HttpServletResponse response,
                                Object handler, Exception ex) {  // ex = 处理过程中抛的异常（没有就是 null）
        UserContext.clear();                              // ★★ 清理 ThreadLocal，防串号
    }
    private void write401(HttpServletResponse response,String msg)throws Exception{
        response.setStatus(401);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"code\":401,\"msg\":\"" + msg + "\"}");
    }
}
