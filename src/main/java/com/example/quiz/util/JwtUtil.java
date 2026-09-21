package com.example.quiz.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtUtil {
    private final SecretKey key;
    private final long expireMillis;

    public JwtUtil(@Value("${jwt.secret}") String secret,      // 读 application.properties 的 jwt.secret
                   @Value("${jwt.expire-days}") long expireDays) {  // 读 jwt.expire-days
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expireMillis=expireDays*24*60*60*1000L;
    }

    public String generate(Long userId,String platform){
        Date now =new Date();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("platform",platform)
                .issuedAt(now)
                .expiration(new Date(now.getTime()+expireMillis))
                .signWith(key)
                .compact();
    }

    public Jws<Claims>parse(String token){
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token);
    }

    public Long getUserId(String token){
        return Long.valueOf(parse(token).getPayload().getSubject());
    }
}
