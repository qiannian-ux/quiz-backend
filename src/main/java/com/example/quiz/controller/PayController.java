package com.example.quiz.controller;

import com.example.quiz.service.PayService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
public class PayController {

    private final PayService payService;

    public PayController(PayService payService) {
        this.payService = payService;
    }

    /** ① 前端下单拿签名（需登录，走 JWT：/api/** 被拦截器保护） */
    @PostMapping("/api/pay/order")
    public Map<String, Object> order(@RequestBody OrderReq req) {
        return payService.createOrder(req.getProductId(), req.getAttach());
    }

    /** ③ 兜底查单（需登录，推送丢失时手动/定时触发） */
    @PostMapping("/api/pay/query")
    public Map<String, Object> query(@RequestBody QueryReq req) {
        return payService.queryOrder(req.getOutTradeNo());
    }

    /**
     * ② 微信消息推送（GET 握手 + POST 发货）。
     * /pay/notify 不在 /api 下，WebMvcConfig 的拦截器只拦 /api/**，天然放行（免登录，符合支付回调范式）。
     * GET：保存配置时微信验证签名，原样返回 echostr。
     * POST：发货推送 xpay_goods_deliver_notify，验签 + 解密 + 幂等 + 发货。
     */
    @GetMapping(value = "/pay/notify", produces = "text/plain;charset=UTF-8")
    public String verify(@RequestParam String signature,
                         @RequestParam String timestamp,
                         @RequestParam String nonce,
                         @RequestParam String echostr) {
        return payService.verifyEcho(signature, timestamp, nonce, echostr);
    }

    @PostMapping(value = "/pay/notify", produces = "text/plain;charset=UTF-8")
    public String notify(@RequestParam(value = "msg_signature", required = false) String msgSignature,
                         @RequestParam(value = "timestamp", required = false) String timestamp,
                         @RequestParam(value = "nonce", required = false) String nonce,
                         @RequestBody String body) {
        return payService.handleNotify(body, msgSignature, timestamp, nonce);
    }

    // ---- DTO ----
    public static class OrderReq {
        private String productId;
        private String attach;
        public String getProductId() { return productId; }
        public void setProductId(String productId) { this.productId = productId; }
        public String getAttach() { return attach; }
        public void setAttach(String attach) { this.attach = attach; }
    }

    public static class QueryReq {
        private String outTradeNo;
        public String getOutTradeNo() { return outTradeNo; }
        public void setOutTradeNo(String outTradeNo) { this.outTradeNo = outTradeNo; }
    }
}
