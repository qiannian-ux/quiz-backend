package com.example.quiz.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.quiz.domain.PayOrder;
import com.example.quiz.domain.UserPlatform;
import com.example.quiz.mapper.PayOrderMapper;
import com.example.quiz.mapper.UserPlatformMapper;
import com.example.quiz.util.UserContext;
import com.example.quiz.util.VPaySign;
import com.example.quiz.util.AesUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import tools.jackson.databind.ObjectMapper;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 微信虚拟支付（个人主体 · 道具直购）核心逻辑。
 * 三个能力：① 下单签名 ② 消息推送（GET 握手 + POST 发货，兼容明文/安全模式）③ 兜底查单。
 * 不改动任何已有类：session_key 从 user_platform 取，权益以 pay_order 表记录为准。
 */
@Service
public class PayService {

    @Value("${wx.vpay.offer-id:}") private String offerId;
    @Value("${wx.vpay.app-key:}")  private String appKey;
    @Value("${wx.vpay.env:0}")      private int env;
    @Value("${wx.vpay.push-token:}") private String pushToken; // 消息推送 Token（GET 验签 / msg_signature）
    @Value("${wx.vpay.aes-key:}")    private String aesKey;     // 消息推送 EncodingAESKey（43 位，安全模式解密）
    @Value("${wx.appid:}")           private String appId;      // 小程序 appid（AES 解密校验，可选）

    private final PayOrderMapper orderMapper;
    private final UserPlatformMapper userPlatformMapper;
    private final AesUtil aesUtil;
    private final RestClient rest = RestClient.create();
    private final ObjectMapper json = new ObjectMapper();
    private final SecureRandom random = new SecureRandom();

    public PayService(PayOrderMapper orderMapper, UserPlatformMapper userPlatformMapper,
                      AesUtil aesUtil) {
        this.orderMapper = orderMapper;
        this.userPlatformMapper = userPlatformMapper;
        this.aesUtil = aesUtil;
    }

    /** 道具价目（分），必须与微信后台【道具管理】严格一致 */
    private int priceOf(String productId) {
        if ("unlock_all".equals(productId)) return 590;   // ¥5.9
        if ("tip_milktea".equals(productId)) return 600;  // ¥6.0
        throw new IllegalArgumentException("未知道具: " + productId);
    }

    // ================= ① 下单 =================
    public Map<String, Object> createOrder(String productId, String attach) {
        Long userId = UserContext.getUserId();
        if (userId == null) throw new IllegalStateException("请先登录");

        UserPlatform up = userPlatformMapper.selectOne(
                new LambdaQueryWrapper<UserPlatform>()
                        .eq(UserPlatform::getUserId, userId)
                        .eq(UserPlatform::getPlatform, "weixin"));
        if (up == null || up.getSessionKey() == null)
            throw new IllegalStateException("会话已失效，请重新登录后再购买");

        int goodsPrice = priceOf(productId);
        // outTradeNo：T + 毫秒时间戳(13) + 4 位随机 = 18 位，T 开头，全局唯一，不下划线开头
        String outTradeNo = "T" + System.currentTimeMillis()
                + String.format("%04d", random.nextInt(10000));

        String realAttach = (attach == null || attach.isBlank()) ? String.valueOf(userId) : attach;
        String signData = VPaySign.buildSignData(offerId, 1, env, "CNY", productId,
                goodsPrice, outTradeNo, realAttach);
        String paySig;
        String signature;
        String sk = aesUtil.decrypt(up.getSessionKey());   // 落地密文 → 明文 session_key
        try {
            paySig = VPaySign.calcPaySig(signData, appKey);
            signature = VPaySign.calcSignature(signData, sk);
        } catch (Exception e) {
            throw new IllegalStateException("签名失败: " + e.getMessage(), e);
        }

        PayOrder o = new PayOrder();
        o.setUserId(userId);
        o.setOpenid(up.getOpenid());
        o.setOutTradeNo(outTradeNo);
        o.setProductId(productId);
        o.setAmountFen(goodsPrice);
        o.setStatus(0);
        o.setAttach(realAttach);
        orderMapper.insert(o);

        // 返回给前端，前端原样透传给 wx.requestVirtualPayment（前端不重算签名）
        Map<String, Object> payData = new LinkedHashMap<>();
        payData.put("offerId", offerId);
        payData.put("signData", signData);
        payData.put("paySig", paySig);
        payData.put("signature", signature);
        payData.put("env", env);
        payData.put("outTradeNo", outTradeNo);
        payData.put("mode", "short_series_goods");
        return payData;
    }

    // ================= ② 消息推送：GET 握手验签（保存配置时微信调用） =================
    public String verifyEcho(String signature, String timestamp, String nonce, String echostr) {
        if (pushToken == null || pushToken.isEmpty()) return "fail";
        if (!sha1(pushToken, timestamp, nonce).equalsIgnoreCase(signature)) return "fail";
        // 安全模式：echostr 可能是 AES 密文，解密后返回；明文/兼容模式原样返回
        if (aesKey != null && !aesKey.isEmpty()) {
            try {
                return decryptMsg(echostr);
            } catch (Exception ignored) { /* 明文模式，回原文 */ }
        }
        return echostr;
    }

    // ================= ③ 消息推送：POST 发货推送（兼容明文/安全模式，XML/JSON 双格式） =================
    // 微信【消息推送】可配 数据格式=XML 或 JSON、加密方式=明文/兼容/安全。
    // 本方法对四种组合（明文XML / 明文JSON / 加密XML包 / 加密JSON包）均兼容，并按请求格式回包。
    public String handleNotify(String body, String msgSignature, String timestamp, String nonce) {
        // 响应格式跟随「外层请求」格式：加密包看 <Encrypt>/\"Encrypt\"，明文看开头
        boolean reqXml;
        if (body == null) reqXml = true;
        else if (body.contains("<Encrypt>")) reqXml = true;
        else if (body.contains("\"Encrypt\"")) reqXml = false;
        else reqXml = body.trim().startsWith("<");

        try {
            String inner;
            if (body != null && (body.contains("<Encrypt>") || body.contains("\"Encrypt\""))) {
                // 安全模式：外层 <xml><Encrypt>BASE64</Encrypt></xml> 或 {"Encrypt":"BASE64"}
                String encrypt;
                if (body.contains("<Encrypt>")) {
                    encrypt = parseXml(body).get("Encrypt");
                } else {
                    encrypt = asString(json.readValue(body, Map.class).get("Encrypt"));
                }
                if (encrypt == null || encrypt.isBlank()) return err("缺少 Encrypt", reqXml);
                if (msgSignature != null && !msgSignature.isEmpty()
                        && pushToken != null && !pushToken.isEmpty()) {
                    if (!sha1(pushToken, timestamp, nonce, encrypt).equalsIgnoreCase(msgSignature))
                        return err("msg_signature 校验失败", reqXml);
                }
                inner = decryptMsg(encrypt);
            } else {
                inner = body; // 明文 / 兼容模式
            }

            // 内层明文：与【消息推送】数据格式一致，可能是 XML 或 JSON
            Map<String, String> m;
            if (inner != null && inner.trim().startsWith("{")) {
                m = flattenJson(json.readValue(inner, Map.class));
            } else {
                m = parseXml(inner);
            }

            String event = m.get("Event");
            if (event == null) return err("缺少 Event", reqXml);
            if (!"xpay_goods_deliver_notify".equals(event)) {
                // 其它事件（用户消息 / 订阅等）忽略并 ack，避免微信无限重试
                return ok(reqXml);
            }

            String outTradeNo = m.get("OutTradeNo");
            String wxOrderId = m.get("MchOrderNo"); // 位于 WeChatPayInfo 内，嵌套也能取到

            if (outTradeNo == null || outTradeNo.isBlank()) return err("缺少业务单号", reqXml);

            // 幂等①：同一平台单号（微信侧）已发货 → 直接成功
            if (wxOrderId != null && !wxOrderId.isBlank()) {
                PayOrder byWx = orderMapper.selectByWxOrderId(wxOrderId);
                if (byWx != null && byWx.getStatus() == 1) return ok(reqXml);
            }

            PayOrder order = orderMapper.selectByOutTradeNo(outTradeNo);
            if (order == null) return err("订单不存在", reqXml);
            // 幂等②：本地下单号已发货 → 直接成功
            if (order.getStatus() == 1) return ok(reqXml);

            // 发货：unlock_all / tip_milktea 均只标记 pay_order.status=1
            // （unlock_all 前端支付成功已写 storage.premium；不改动 user 表）
            order.setWxOrderId(wxOrderId != null ? wxOrderId : order.getWxOrderId());
            order.setStatus(1);
            orderMapper.updateById(order);
            return ok(reqXml);
        } catch (Exception e) {
            return err(e.getMessage(), reqXml);
        }
    }

    private static String asString(Object o) { return o == null ? null : String.valueOf(o); }

    // JSON 扁平化一层：WeChatPayInfo.MchOrderNo / GoodsInfo.ProductId 等嵌套叶子 → 取叶子键名
    private Map<String, String> flattenJson(Map<?, ?> map) {
        Map<String, String> out = new LinkedHashMap<>();
        for (Map.Entry<?, ?> e : map.entrySet()) {
            Object v = e.getValue();
            if (v instanceof Map) {
                for (Map.Entry<?, ?> inner : ((Map<?, ?>) v).entrySet()) {
                    Object iv = inner.getValue();
                    if (!(iv instanceof Map) && iv != null)
                        out.put(String.valueOf(inner.getKey()), String.valueOf(iv));
                }
            } else if (v != null) {
                out.put(String.valueOf(e.getKey()), String.valueOf(v));
            }
        }
        return out;
    }

    // ================= ④ 兜底查单 =================
    public Map<String, Object> queryOrder(String outTradeNo) {
        PayOrder order = orderMapper.selectByOutTradeNo(outTradeNo);
        if (order == null) throw new IllegalStateException("订单不存在");
        String openid = order.getOpenid();

        // 业务参数（不含 pay_sig）用于签名
        String body = "{\"openid\":\"" + (openid == null ? "" : openid) + "\",\"env\":" + env
                + ",\"order_id\":\"" + outTradeNo + "\"}";
        String paySig;
        try {
            paySig = VPaySign.calcQuerySig(body, appKey);
        } catch (Exception e) {
            throw new IllegalStateException("查单签名失败: " + e.getMessage(), e);
        }

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("openid", openid);
        req.put("env", env);
        req.put("order_id", outTradeNo);
        req.put("pay_sig", paySig);

        String raw;
        try {
            raw = rest.post()
                    .uri("https://api.weixin.qq.com/xpay/query_order")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(req)
                    .retrieve()
                    .body(String.class);
        } catch (Exception e) {
            throw new IllegalStateException("查单失败: " + e.getMessage());
        }

        // 若已支付但本地未发货 → 复用发货逻辑（按 wx_order_id 幂等）
        try {
            Map<?, ?> resp = json.readValue(raw, Map.class);
            Object orderObj = resp.get("order");
            if (orderObj instanceof Map) {
                Map<?, ?> wxOrder = (Map<?, ?>) orderObj;
                Object status = wxOrder.get("status");
                Object wxOrderId = wxOrder.get("wx_order_id");
                // 微信订单 status：2 = 已支付（以官方文档为准）
                if (status != null && "2".equals(String.valueOf(status)) && wxOrderId != null) {
                    if (order.getStatus() != 1) {
                        order.setWxOrderId(String.valueOf(wxOrderId));
                        order.setStatus(1);
                        orderMapper.updateById(order);
                    }
                }
            }
        } catch (Exception ignored) {
            // 解析失败不影响返回原始结果，前端/运维可看 raw
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("raw", raw);
        return result;
    }

    // -------- XML 解析（JDK 内置，禁用 DOCTYPE 防 XXE） --------
    private Map<String, String> parseXml(String xml) throws Exception {
        Map<String, String> map = new LinkedHashMap<>();
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        Document doc = dbf.newDocumentBuilder()
                .parse(new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8)));
        NodeList list = doc.getElementsByTagName("*");
        for (int i = 0; i < list.getLength(); i++) {
            Element e = (Element) list.item(i);
            if (e.getChildNodes().getLength() == 1) {
                map.put(e.getTagName(), e.getTextContent());
            }
        }
        return map;
    }

    // -------- SHA1 验签（参数按字典序拼接） --------
    private String sha1(String... parts) {
        String[] arr = parts.clone();
        Arrays.sort(arr);
        String joined = String.join("", arr);
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-1");
            byte[] hash = md.digest(joined.getBytes(StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            throw new IllegalStateException("SHA1 失败: " + e.getMessage(), e);
        }
    }

    // -------- AES-256-CBC 解密（微信消息加密，EncodingAESKey 43 位） --------
    private String decryptMsg(String encrypt) throws Exception {
        byte[] key = Base64.getDecoder().decode(aesKey + "="); // 43 -> 44 字符 -> 32 字节
        byte[] iv = Arrays.copyOfRange(key, 0, 16);
        byte[] data = Base64.getDecoder().decode(encrypt);
        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, "AES"), new IvParameterSpec(iv));
        byte[] dec = cipher.doFinal(data);
        // 结构：random(16B) + msg_len(4B 大端) + msg + appid
        int len = ((dec[16] & 0xFF) << 24) | ((dec[17] & 0xFF) << 16)
                | ((dec[18] & 0xFF) << 8) | (dec[19] & 0xFF);
        return new String(dec, 20, len, StandardCharsets.UTF_8);
    }

    // 回包格式必须跟随请求格式（XML / JSON），否则微信可能不认；"success"/空也可被接受
    private String ok(boolean xml) {
        return xml
                ? "<xml><ErrCode>0</ErrCode><ErrMsg><![CDATA[success]]></ErrMsg></xml>"
                : "{\"ErrCode\":0,\"ErrMsg\":\"success\"}";
    }
    private String err(String msg, boolean xml) {
        String safe = (msg == null) ? "error" : msg.replace("\"", "'");
        return xml
                ? "<xml><ErrCode>1</ErrCode><ErrMsg><![CDATA[" + safe + "]]></ErrMsg></xml>"
                : "{\"ErrCode\":1,\"ErrMsg\":\"" + safe + "\"}";
    }
}
