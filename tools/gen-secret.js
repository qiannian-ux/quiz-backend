#!/usr/bin/env node
/**
 * 生成 session.encrypt-key 用的随机密钥串。
 * 32 字节随机 → 64 位十六进制（AesUtil 再用 SHA-256 归一化成 AES-256 的 32 字节密钥）。
 * 用 Node 内置 crypto，跨 Windows/macOS/Linux，无需 openssl。
 *
 * 用法：
 *   node tools/gen-secret.js
 */
const crypto = require('crypto');

const s = crypto.randomBytes(32).toString('hex');

console.log(s);
console.log('\n# 复制上面这串使用：');
console.log('#   dev : export SESSION_ENCRYPT_KEY=' + s);
console.log('#   prod: 在 application-prod.properties 加一行 → session.encrypt-key=' + s);
