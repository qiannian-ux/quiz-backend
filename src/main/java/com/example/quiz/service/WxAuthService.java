package com.example.quiz.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.ObjectMapper;

import java.util.Map;

@Service
public class WxAuthService {
    private final String wxAppid;
    private final String wxSecret;
    private final String ttAppid;
    private final String ttSecret;
    private final RestClient restClient = RestClient.create();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public WxAuthService(@Value("${wx.appid}") String wxAppid,
                         @Value("${wx.secret}") String wxSecret,
                         @Value("${toutiao.appid:}") String ttAppid,
                         @Value("${toutiao.secret:}") String ttSecret){
        this.wxAppid = wxAppid;
        this.wxSecret = wxSecret;
        this.ttAppid = ttAppid;
        this.ttSecret = ttSecret;
    }
    public record SessionResult(String openid,String sessionKey){}

    /**
     * 用前端传来的 login code 换 openid + session_key。
     * platform: "weixin" 走微信 jscode2session；"toutiao" 走抖音 v2 jscode2session。
     * 两个平台接口差异很大（URL / 请求方式 / 响应结构都不同），必须分支处理。
     */
    public SessionResult code2Session(String code, String platform){
        if ("toutiao".equals(platform)) {
            return ttCode2Session(code);
        }
        return wxCode2Session(code);
    }

    // 微信：GET，参数放 query string，成功响应直接是 {openid, session_key}
    private SessionResult wxCode2Session(String code){
        String url="https://api.weixin.qq.com/sns/jscode2session"
                +"?appid="+wxAppid
                +"&secret="+wxSecret
                +"&js_code="+code
                +"&grant_type=authorization_code";

        // 微信出错时常把响应标成 text/plain 而非 application/json，
        // RestClient 默认转换器无法把 text/plain 反序列化成 Map → 抛 UnknownContentTypeException。
        // 改为先按 String 读原文（String 转换器能吃任意 content-type），再用 Jackson 手动解析。
        String respStr = restClient.get()
                .uri(url)
                .retrieve()
                .body(String.class);
        Map<?, ?> resp = parseJson(respStr);
        // 微信成功响应里没有 errcode；有 errcode 即失败
        if (resp == null || resp.containsKey("errcode")) {
            Object errcode = resp == null ? "null" : resp.get("errcode");
            Object errmsg = resp == null ? "响应为空" : resp.get("errmsg");
            throw new IllegalStateException("微信code2Session失败, errcode=" + errcode + ", errmsg=" + errmsg);
        }
        return new SessionResult((String) resp.get("openid"), (String) resp.get("session_key"));
    }

    // 抖音：POST，JSON body，成功响应结构是 {err_no:0, err_tips:"", data:{openid, session_key}}
    private SessionResult ttCode2Session(String code){
        if (ttAppid.isEmpty() || ttSecret.isEmpty()) {
            throw new IllegalStateException("抖音登录未配置：请在配置里设置 toutiao.appid / toutiao.secret");
        }
        String url="https://developer.toutiao.com/api/apps/v2/jscode2session";
        String body = "{\"appid\":\"" + ttAppid + "\",\"secret\":\"" + ttSecret + "\",\"code\":\"" + code + "\"}";

        String respStr = restClient.post()
                .uri(url)
                .header("Content-Type", "application/json")
                .body(body)
                .retrieve()
                .body(String.class);
        Map<?, ?> resp = parseJson(respStr);
        // 抖音成功响应：err_no == 0 且存在 data 节点
        // 注意：Jackson 可能把数字解析成 Integer 或 Long，用 Number.intValue() 统一比较，避免类型不匹配误判失败
        Object errNoObj = resp == null ? null : resp.get("err_no");
        boolean success = errNoObj instanceof Number && ((Number) errNoObj).intValue() == 0;
        if (resp == null || !success || !resp.containsKey("data")) {
            Object errNo = resp == null ? "null" : errNoObj;
            Object errTips = resp == null ? "响应为空" : resp.get("err_tips");
            throw new IllegalStateException("抖音code2Session失败, err_no=" + errNo + ", err_tips=" + errTips);
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) resp.get("data");
        return new SessionResult((String) data.get("openid"), (String) data.get("session_key"));
    }

    private Map<?, ?> parseJson(String respStr){
        try {
            return objectMapper.readValue(respStr, Map.class);
        } catch (Exception e) {
            throw new IllegalStateException("code2Session 响应无法解析为 JSON: " + respStr, e);
        }
    }
}
