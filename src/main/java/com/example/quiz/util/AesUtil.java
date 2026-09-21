package com.example.quiz.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * session_key 落地加密（at-rest encryption）。
 * -----------------------------------------------------------------------------
 * 为什么：session_key 是微信下发的"用户登录凭证"，等同用户密码。明文存库 = 一旦 DB 被拖，
 * 攻击者可拿它冒充该用户签虚拟支付。加密后密钥在服务端、库里只有密文，把"只丢库"和
 * "全盘崩溃"隔开（纵深防御的一层）。
 *
 * 算法：AES-256-CBC。密钥 = SHA-256(专用密钥 session.encrypt-key)，固定 32 字节 → AES-256。
 * session.encrypt-key 必须显式配置（dev 环境变量 SESSION_ENCRYPT_KEY / prod application-prod.properties），不回退其他密钥。
 * 每次随机 16 字节 IV 拼在密文前，整体 base64，前缀 "v1:" 标记版本。
 *
 * 兼容：历史明文行（无 "v1:" 前缀）decrypt 直接原样返回，等用户下次静默登录自动改写为密文。
 */
@Component
public class AesUtil {

    private static final String MARK = "v1:";
    private final SecretKeySpec key;
    private final SecureRandom random = new SecureRandom();

    public AesUtil(@Value("${session.encrypt-key}") String encryptKey) {
        // 必须显式配置，不回退到其他密钥（与 jwt.secret 同样强制）
        if (encryptKey == null || encryptKey.isBlank()) {
            throw new IllegalStateException(
                "session.encrypt-key 未配置：session_key 落地加密密钥必须显式设置"
                + "（dev 设环境变量 SESSION_ENCRYPT_KEY；prod 在 application-prod.properties 设 session.encrypt-key）");
        }
        this.key = new SecretKeySpec(sha256(encryptKey), "AES");
    }

    /** 明文 → "v1:" + base64(IV + 密文) */
    public String encrypt(String plain) {
        if (plain == null) return null;
        try {
            byte[] iv = new byte[16];
            random.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new IvParameterSpec(iv));
            byte[] ct = cipher.doFinal(plain.getBytes(StandardCharsets.UTF_8));
            byte[] out = new byte[16 + ct.length];
            System.arraycopy(iv, 0, out, 0, 16);
            System.arraycopy(ct, 0, out, 16, ct.length);
            return MARK + Base64.getEncoder().encodeToString(out);
        } catch (Exception e) {
            throw new IllegalStateException("session_key 加密失败: " + e.getMessage(), e);
        }
    }

    /** "v1:" + base64(...) → 明文；非本格式（历史明文）原样返回 */
    public String decrypt(String cipherText) {
        if (cipherText == null || !cipherText.startsWith(MARK)) return cipherText;
        try {
            byte[] data = Base64.getDecoder().decode(cipherText.substring(MARK.length()));
            if (data.length <= 16) return cipherText;
            byte[] iv = new byte[16];
            System.arraycopy(data, 0, iv, 0, 16);
            byte[] ct = new byte[data.length - 16];
            System.arraycopy(data, 16, ct, 0, ct.length);
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.DECRYPT_MODE, key, new IvParameterSpec(iv));
            return new String(cipher.doFinal(ct), StandardCharsets.UTF_8);
        } catch (Exception e) {
            return cipherText; // 解密失败兜底（理论不会触发）
        }
    }

    private static byte[] sha256(String s) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 失败", e);
        }
    }
}
