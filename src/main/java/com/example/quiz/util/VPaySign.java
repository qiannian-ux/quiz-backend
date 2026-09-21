package com.example.quiz.util;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;

public class VPaySign {

    /** HMAC-SHA256 → 十六进制小写（微信要求） */
    public static String hmacSha256(String key, String msg) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] raw = mac.doFinal(msg.getBytes(StandardCharsets.UTF_8));
        return HexFormat.of().formatHex(raw);
    }

    /** 支付签名 paySig：C 端 uri 固定 requestVirtualPayment */
    public static String calcPaySig(String signData, String appKey) throws Exception {
        return hmacSha256(appKey, "requestVirtualPayment&" + signData);
    }

    /** 用户态签名 signature：msg 不带 uri 前缀，只有 signData 本身 */
    public static String calcSignature(String signData, String sessionKey) throws Exception {
        return hmacSha256(sessionKey, signData);
    }

    /** 查单签名 pay_sig：B 端 uri = /xpay/query_order */
    public static String calcQuerySig(String bodyJson, String appKey) throws Exception {
        return hmacSha256(appKey, "/xpay/query_order&" + bodyJson);
    }

    /**
     * ⚠️ 致命坑：signData 的 JSON 键顺序必须固定，禁止 Gson/Jackson 默认序列化（会按字母序重排）。
     * 这里手动拼，顺序照抄官方。
     */
    public static String buildSignData(String offerId, int buyQuantity, int env,
                                       String currencyType, String productId,
                                       int goodsPrice, String outTradeNo, String attach) {
        return "{\"offerId\":\"" + offerId + "\","
                + "\"buyQuantity\":" + buyQuantity + ","
                + "\"env\":" + env + ","
                + "\"currencyType\":\"" + currencyType + "\","
                + "\"productId\":\"" + productId + "\","
                + "\"goodsPrice\":" + goodsPrice + ","
                + "\"outTradeNo\":\"" + outTradeNo + "\","
                + "\"attach\":\"" + attach + "\"}";
    }
}