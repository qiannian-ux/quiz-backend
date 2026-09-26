package com.example.quiz.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.time.LocalDate;

/**
 * 天气服务（天气卡用）
 * ------------------------------------------------------------
 * 为什么在服务端代理，而不是小程序直接请求和风？
 *   1. API Key 放前端 = 明文躺在小程序包里，反编译即泄露，还得Key 随时能吊销；
 *   2. 小程序"request 合法域名"要逐个加第三方域名，多一个域名就多一次审核；
 *   3. 服务端可以缓存，同一个用户反复进首页不会打爆免费额度。
 *
 * 数据源：和风天气 Web API（免费开发版，1000 次/天，够用）
 *   第一步 geoapi   /v2/city       城市名 -> location id
 *   第二步 devapi   /v7/weather/now location id -> 实况
 *
 * 设计取舍：
 *   - 上游任何异常都不向上抛。首页一张卡挂了不该让接口 500，
 *     这里统一收敛成 ok:false 的软失败，前端走「获取失败」降级展示。
 *   - 缓存放内存 Map。单机部署够用；将来多实例再说 Redis（不必现在上）。
 */
@Service
public class WeatherService {

private static final org.slf4j.Logger log =
        org.slf4j.LoggerFactory.getLogger(WeatherService.class);

    /** 一个天气结果的缓存条目：数据 + 入缓存的时刻 */
    private record CacheEntry(long at, WeatherResponse data) {
    }

    /** 上游返回了非 2xx，或调用被拒绝。消息里不含 URL，不会把 key 漏出去 */
    private static class UpstreamException extends RuntimeException {
        final int status;

        UpstreamException(int status, String message) {
            super(message);
            this.status = status;
        }
    }

    /** 天气码 -> 中文描述（和风官方文档代码表，只列常用段） */
    private static final Map<Integer, String> TEXT_MAP = new HashMap<>();

    static {
        TEXT_MAP.put(100, "晴");
        TEXT_MAP.put(101, "多云");
        TEXT_MAP.put(102, "少云");
        TEXT_MAP.put(103, "晴间多云");
        TEXT_MAP.put(104, "阴");
        // 200-299 雷阵雨类
        for (int c = 200; c <= 208; c++) TEXT_MAP.put(c, c <= 202 ? "短暂阵雨" : c <= 204 ? "雷阵雨" : "阵雪");
        // 300-399 雨
        for (int c = 300; c <= 312; c++) {
            TEXT_MAP.put(c, c <= 305 ? "小雨" : c <= 309 ? "中雨" : "大雨");
        }
        // 400-499 雪
        for (int c = 400; c <= 406; c++) {
            TEXT_MAP.put(c, c <= 402 ? "小雪" : c <= 404 ? "中雪" : "大雪");
        }
        // 500-599 云雾
        for (int c = 500; c <= 504; c++) TEXT_MAP.put(c, c <= 502 ? "雾" : "冻雾");
        TEXT_MAP.put(507, "霾");
        TEXT_MAP.put(508, "强霾");
    }

    /** 公共域名；填了 weather.api-host 就改用专属域名（新凭据只能用专属域名） */
    private static final String GEO_PUBLIC = "https://geoapi.qweather.com";
    private static final String NOW_PUBLIC = "https://devapi.qweather.com";
    private static final String GEO_PATH = "/geo/v2/city/lookup";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(3))
            .build();

    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

    /**
     * 城市名 -> location id 的缓存。
     * ------------------------------------------------------------
     * 这个映射几乎不会变（"成都"永远是同一个 id），但原来每查一次天气
     * 都要重新问一次 GeoAPI —— 一次天气 = 2 次上游调用，额度就这么烧掉一半。
     * 缓存起来之后，同一个城市只有第一次是 2 次，之后每次只要 1 次。
     * 进程内缓存，不设过期：城市 id 不会变，重启重新查一次的成本可以忽略。
     */
    private final Map<String, String> geoCache = new ConcurrentHashMap<>();

    private final AtomicInteger usedToday=new AtomicInteger();
    private final int dailyQuota;
    private String todayKey  =LocalDate.now().toString();
    private final String key;
    private final long cacheMillis;
    /** 为空则用公共域名；和风新版控制台会给每个项目一个专属 API Host */
    private final String apiHost;

    public WeatherService(@Value("${weather.key:}") String key,
                          @Value("${weather.cache-minutes:10}") long cacheMinutes,
                          // 和风免费版 1000 次/天。这里按"上游调用次数"计（见 getJson），
                          // 留两成余量设 800，免得闸还没触发、和风那边已经先限流了。
                          @Value("${weather.daily-quota:800}") int dailyQuota,
                          @Value("${weather.api-host:}") String apiHost) {
        this.key = key;
        this.cacheMillis = Math.max(1, cacheMinutes) * 60_000L;
        this.dailyQuota=dailyQuota;
        // 填 'https://x.re.qweatherapi.com' 或 'x.re.qweatherapi.com' 都认
        this.apiHost = apiHost==null?null:apiHost.trim().replaceAll("^https?://","").replaceAll("/+$","");
    }

    private String geoUrl(String city) {
        String c = URLEncoder.encode(city, StandardCharsets.UTF_8);
        // 和风 GeoAPI 的真实路径是 /geo/v2/city/lookup（少一段就是 404），
        // 用专属 Host 时打到自己的域名，没配 Host 才退回公共域名
        return (apiHost==null?GEO_PUBLIC:"https://"+apiHost) + GEO_PATH + "?location=" + c + "&key=" + key;
    }

    private String nowUrl(String locationId) {
        return (apiHost==null?NOW_PUBLIC:"https://"+apiHost) + "/v7/weather/now?location=" + locationId + "&key=" + key;
    }

    /**
     * 取某城市实况。
     *
     * @param city 中文城市名
     * @return 永远返回 200 的软失败也用 ok:false 表达，前端据此降级
     */
    public WeatherResponse now(String city) {
        if (!StringUtils.hasText(key)) {
            return new WeatherResponse(false, city, null, null, null, null, "天气服务未配置");
        }
        if (!StringUtils.hasText(city)) {
            return new WeatherResponse(false, city, null, null, null, null, "缺少城市参数");
        }
        // 和风 2024 后 GeoAPI 不再服务公共域名，没配专属 Host 一定是 404。
        // 与其让用户对着"404"猜，不如直接说清楚该怎么配
        if (!StringUtils.hasText(apiHost)) {
            return new WeatherResponse(false, city, null, null, null, null,
                    "未配置天气 API Host（和风需填控制台「项目」页的专属域名）");
        }

        final String name = city.trim();
        final boolean coord = isCoord(name);

        // 1. 缓存命中直接返回（天气变化慢，10 分钟足够）
        long now = System.currentTimeMillis();
        CacheEntry hit = cache.get(name);
        if (hit != null && now - hit.at() < cacheMillis) {
            return hit.data();
        }

        // 2. 配额闸在 getJson() 里按"上游调用次数"扣（见那里），这里不再预检一次，
        //    否则一次查询只计 1 次、实际消耗 2 次，配额就对不上了。

        try {
            String locationId;
            String displayName;
            if (coord) {
                // 微信定位传来的经纬度：GeoAPI 按坐标反查最近地点（区/县），
                // 直接拿它的名字做展示，天气精度到区。
                JsonNode loc = firstLocation(name);
                if (loc == null) {
                    return new WeatherResponse(false, name, null, null, null, null,
                            "定位失败：附近没有可识别的城市");
                }
                locationId = text(loc, "id");
                displayName = locationLabel(loc);
            } else {
                // 3. 城市名 -> location id
                locationId = locationId(name);
                if (locationId == null) {
                    return new WeatherResponse(false, name, null, null, null, null, "城市不存在");
                }
                displayName = name;
            }
            // 4. 实况
            WeatherResponse resp = fetchNow(locationId, displayName);
            cache.put(name, new CacheEntry(now, resp));
            return resp;
        } catch (UpstreamException e) {
            // 上游明确给了拒绝原因（403/429/上游业务码），直接透出，排错不用猜
            log.warn("天气上游拒绝 city={}: {}", name, e.getMessage());
            return new WeatherResponse(false, name, null, null, null, null, e.getMessage());
        } catch (IllegalStateException e) {
            // 我们自己抛的连接失败 / 上游非 2xx，消息里不带 URL，可以放心透出
            log.warn("天气上游连接/状态码异常 city={}: {}", name, e.getMessage());
            return new WeatherResponse(false, name, null, null, null, null, e.getMessage());
        } catch (Exception e) {
            // 剩下的是解析失败等意外，仍收敛成软失败，不打 500 吓前端。
            // 但必须打日志：否则排错时只能看到笼统的"暂不可用"，无从下手
            log.warn("天气服务意外失败 city={}", name, e);
            // ★ 不要把 e.getMessage() 回给前端：异常里可能带完整 URL，URL 里有 key，会泄露
            return new WeatherResponse(false, name, null, null, null, null, "天气服务暂不可用");
        }
    }
        /**
         * 当日配额检查：跨天自动清零，不依赖定时任务。
         * ⚠️ 计的是「上游调用次数」不是「查询次数」——一次查询要打两次上游
         *    （GeoAPI 换 id + 实况），按查询计会让实际消耗翻倍，闸形同虚设。
         *    和风免费版 1000 次/天，默认留两成余量设 800。
         * 配额是按 key 全局算的（不是每 IP），所以能挡住脚本连点。
         */
        private boolean quotaOk() {
            String today = LocalDate.now().toString();
            if (!today.equals(todayKey)) {
                todayKey = today;
                usedToday.set(0);
            }
            return usedToday.incrementAndGet() <= dailyQuota;

    }

    /** 是否「经度,纬度」坐标串（微信 getLocation 产出），用来和城市名区分开 */
    private static boolean isCoord(String s) {
        return s != null && s.matches("^-?\\d{1,3}(\\.\\d+)?\\s*,\\s*-?\\d{1,3}(\\.\\d+)?$");
    }

    /** 第一步（坐标 / 城市通用）：反查最近地点，取返回数组第一项 */
    private JsonNode firstLocation(String query) throws Exception {
        JsonNode root = getJson(geoUrl(query));
        if (!"200".equals(text(root, "code"))) {
            throw new UpstreamException(0, "天气服务拒绝访问（上游码 " + text(root, "code") + "）");
        }
        JsonNode first = root.path("location").path(0);
        return first.isMissingNode() ? null : first;
    }

    /** 反查到的地点展示名：区与上级不同名时拼成「成都武侯区」，否则用本名 */
    private static String locationLabel(JsonNode loc) {
        String name = text(loc, "name");
        String adm2 = text(loc, "adm2");
        if (adm2 != null && name != null && !adm2.equals(name)) {
            return adm2 + name;
        }
        return name;
    }

    /** 第一步：城市名换 location id */
    private String locationId(String city) throws Exception {
        // 命中就直接返回，一次上游调用都不打
        String cached = geoCache.get(city);
        if (cached != null) {
            return cached;
        }

        JsonNode root = getJson(geoUrl(city));
        String code = text(root, "code");
        // 401/402 等：多半是 key 错了或 API 没启用，别让用户以为是自己城市名写错
        if (!"200".equals(code)) {
            throw new UpstreamException(0, "天气服务拒绝访问（上游码 " + code + "）");
        }
        JsonNode first = root.path("location").path(0);
        if (first.isMissingNode()) {
            return null;
        }
        String id = text(first, "id");
        // 存起来，下次同一个城市就不用再问一次 GeoAPI 了
        if (StringUtils.hasText(id)) {
            geoCache.put(city, id);
        }
        return id;
    }

    /** 第二步：location id 换实况 */
    private WeatherResponse fetchNow(String locationId, String city) throws Exception {
        JsonNode root = getJson(nowUrl(locationId));
        if (!"200".equals(text(root, "code"))) {
            throw new UpstreamException(0, "天气服务拒绝访问（上游码 " + text(root, "code") + "）");
        }
        JsonNode now = root.path("now");
        if (now.isMissingNode() || now.isNull()) {
            return new WeatherResponse(false, city, null, null, null, null, "天气服务返回异常");
        }

        String rawText = text(now, "text");
        int code = intOf(now, "code");
        if (code == -1) {
            // 上游偶尔不给天气码，用中文描述反查（TEXT_MAP 是 code->text），
            // 免得前端拿到的 code 恒为 -1、按 code 分支的逻辑全部失效
            code = codeOfText(rawText);
        }
        String text = rawText == null ? TEXT_MAP.getOrDefault(code, "未知") : rawText;
        String temp = text(now, "temp");
        return new WeatherResponse(
                true,
                city,
                code,
                text,
                temp == null ? null : Double.valueOf(temp),
                emojiOf(code, text),
                null
        );
    }

    /**
     * 所有上游调用的唯一出口 —— 配额也在这里扣。
     * 放在这里而不是放在 now() 开头，是因为"一次天气查询"要打两次上游
     * （GeoAPI 换 id + 实况），按查询计数会让实际调用量翻倍而不自知。
     */
    private JsonNode getJson(String url) throws Exception {
        if (!quotaOk()) {
            throw new UpstreamException(0, "今日天气额度已用尽，明天再来");
        }

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(5))
                .header("Accept", "application/json")
                // 声明不压缩，但上游可能无视，所以下面仍要手动解压
                .header("Accept-Encoding", "identity")
                .GET()
                .build();
        HttpResponse<byte[]> res;
        try {
            res = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
        } catch (IOException e) {
            // 连不上 / 超时。catch 里别拼 URL——URL 带 key，会泄进日志和接口返回
            throw new IllegalStateException("无法连接天气服务");
        }
        String body = decodeBody(res.body());

        // 403 = key 不对或 API 没启用；429 = 配额用尽
        if (res.statusCode() < 200 || res.statusCode() >= 300) {
            // 错误响应解压后是 problem+json，把原因透出来，排错不用盲猜。
            // 消息里不含 URL，不会把 key 泄出去
            String reason = firstText(body);
            throw new UpstreamException(res.statusCode(),
                    "天气服务返回 " + res.statusCode() + (reason == null ? "" : "：" + reason));
        }
        return objectMapper.readTree(body);
    }

    /**
     * 和风的错误（乃至成功）响应都可能带 Content-Encoding: gzip，
     * 而 java.net.http.HttpClient 不会自动解压——不解压的话 Jackson 会拿到
     * 控制字符，抛 "Illegal character ((CTRL-CHAR, code 31))" 这种毫无信息量的错。
     * 这里按 gzip 魔数(1F 8B)识别并解压，两条路径都安全。
     */
    private static String decodeBody(byte[] raw) throws java.io.IOException {
        if (raw.length >= 2 && (raw[0] & 0xFF) == 0x1F && (raw[1] & 0xFF) == 0x8B) {
            try (java.util.zip.GZIPInputStream in =
                         new java.util.zip.GZIPInputStream(new java.io.ByteArrayInputStream(raw))) {
                return new String(in.readAllBytes(), StandardCharsets.UTF_8);
            }
        }
        return new String(raw, StandardCharsets.UTF_8);
    }

    /**
     * 从和风错误响应里挑一句能看的话。
     * 它的结构是 {"error":{"status":403,"title":"Invalid Host","detail":"..."}}，
     * 顶层也可能直接有 message/detail，所以两层都找一遍，取第一个有值的。
     */
    private String firstText(String body) {
        JsonNode root;
        try {
            root = objectMapper.readTree(body);
        } catch (Exception e) {
            return null;                        // 不是 JSON 就放弃，别让取原因反过来挡住主流程
        }
        if (root == null || root.isMissingNode()) return null;
        JsonNode[] candidates = {root, root.path("error")};
        String[] fields = {"detail", "title", "message", "error"};
        for (JsonNode node : candidates) {
            if (node == null || node.isMissingNode()) continue;
            for (String f : fields) {
                JsonNode v = node.get(f);
                if (v != null && v.isTextual() && !v.asText().isBlank()) return v.asText();
            }
        }
        return null;
    }

    private static String text(JsonNode node, String field) {
        JsonNode v = node.get(field);
        return v == null || v.isNull() ? null : v.asText();
    }

    private static int intOf(JsonNode node, String field) {
        JsonNode v = node.get(field);
        if (v == null || v.isNull()) return -1;
        try {
            return Integer.parseInt(v.asText());
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    /** emoji 由后端给，省得前端再维护一份天气码映射表 */
    /** TEXT_MAP（code -> 中文）反向查，找不到返回 -1 */
    private static int codeOfText(String t) {
        if (t == null || t.isBlank()) return -1;
        for (java.util.Map.Entry<Integer, String> e : TEXT_MAP.entrySet()) {
            if (t.equals(e.getValue())) return e.getKey();
        }
        return -1;
    }

    private static String emojiOf(int code, String text) {
        if (code == 100 || "晴".equals(text)) return "☀️";
        if (code == 101 || code == 102 || code == 103) return "⛅";
        if (code == 104 || "阴".equals(text)) return "☁️";
        if (code >= 200 && code <= 299) return "⛈️";
        if (code >= 300 && code <= 399) return "🌧️";
        if (code >= 400 && code <= 499) return "🌨️";
        if (code >= 500 && code <= 599) return "🌫️";
        return "🌤️";
    }

    /**
     * 返回给前端的天气。字段名与 api/weather.js 里 getWeather 的约定一一对应。
     * temp 直接用原始字符串转的 double（允许小数），前端自己四舍五入。
     */
    public record WeatherResponse(
            boolean ok,
            String city,
            Integer code,
            String text,
            Double temp,
            String emoji,
            String msg
    ) {
    }
}
