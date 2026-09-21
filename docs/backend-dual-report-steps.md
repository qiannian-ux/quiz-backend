# 后端详细步骤：通用算分（PAIR / MAX / TOP3）+ 双档解析下发

> 目标：`POST /api/quiz/submit` 对 5 个测评都能算分，并把 `quiz_result` 里的
> 初级/高级解析填进 `SubmitResponse` 云端下发。按「照着敲就能跑通」的粒度写。
>
> 分工提醒：代码你敲，卡壳随时贴报错来评审。

---

## 0. 全景：动哪些文件

| 文件 | 动作 | 说明 |
|---|---|---|
| `domain/QuizResult.java` | **新建** | `quiz_result` 表的实体（表从 M5 就有，代码一直没读过它） |
| `mapper/QuizResultMapper.java` | **新建** | 3 行，照 `QuizMapper` 抄 |
| `service/QuizService.java` | **改** | `submit()` 按 `scoringModel` 分流 + 填 4 个新字段 |
| Controller / SubmitRequest / SubmitResponse | 不动 | 已经就位 |
| 数据库 | 跑一遍 `db-full.sql` | 本轮已重新生成（2008 行，补了 schema 段漏掉的两列） |

### 现状与差距（为什么必须改）

- `SubmitResponse` 的 `resultName / resultSummary / basicReport / advancedReport` 四个字段已定义，但 **没有任何代码填它们**。
- `submit()` 只实现了 PAIR（对撞）。两个坑：
  - **MAX 是「碰巧能算对」**：DISC 等的维度 `pair_code` 全是 `'TYPE'`，全部分进一组、组内取最高——语义上正好等于 MAX，但平票时谁先谁后取决于 MySQL 返回顺序，**结果不确定**。
  - **TOP3 会算错**：同样只出一组，霍兰德只能出 1 个字母而不是 3 个（如 RIA）。
- 修复记录（2026-09-20 我已做）：`docs/schema-full.sql` 的 `quiz_result` 建表漏了
  `basic_report`/`advanced_report` 两列，已补上并重新生成 `db-full.sql`。

---

## 第 0 步：数据库先就位（不做，后面全是空指针）

本地库（或生产隧道 3307）跑一遍：

```bash
mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/db-full.sql
```

跑完用这两条验收：

```sql
-- 5 行，scoring_model 各归各位
SELECT id, code, name, scoring_model, status FROM quiz;

-- 39 行全部 JSON 合法（返回 1）
SELECT type_code, JSON_VALID(basic_report) AS basic_ok,
       JSON_VALID(advanced_report) AS adv_ok
FROM quiz_result WHERE quiz_id = 4;
```

五个测评对照表（后端要全部跑通）：

| id | code | 测评 | scoring_model | 结果形态 | 题数 |
|---|---|---|---|---|---|
| 1 | `mbti` | MBTI | PAIR | 4 字母（INFP） | 93 |
| 2 | `disc` | DISC | MAX | 单字母（D/I/S/C） | 20 |
| 3 | `enneagram` | 九型人格 | MAX | 数字码（1~9） | 36 |
| 4 | `holland` | 霍兰德 | **TOP3** | 3 字母（RIA） | 30 |
| 5 | `attachment` | 恋爱依恋 | MAX | 英文码（secure…） | 24 |

---

## 第 1 步：建 `domain/QuizResult.java`

```java
package com.example.quiz.domain;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 测评结果类型。对应 quiz_result 表。
 *
 * MBTI 是 16 行（INFP、ENTJ…），DISC 4 行，九型 9 行，霍兰德 6 行（单字母），
 * 依恋 4 行。加新测评 = 插行，不是建表。
 *
 * 注意 TOP3（霍兰德）：结果码 RIA 是运行时拼出来的，表里没有这一行——
 * 表里只有 R/I/A/S/E/C 六行，所以服务层要「取三行合并」（见第 5 步）。
 */
@Data
@TableName("quiz_result")
public class QuizResult {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long quizId;

    /** 结果码，如 INFP；TOP3 测评是单字母 R/I/A… */
    private String typeCode;

    /** 结果名，如 调停者 / 现实型 */
    private String name;

    /** 一句话总结，分享卡片用 */
    private String summary;

    /** 详细解读（旧字段，新数据已迁到双档 JSON） */
    private String detail;

    private String imageUrl;

    /**
     * 三个 JSON 列一律声明成 String 直接透传：
     * MySQL JSON 列经 JDBC 读出来本来就是字符串，
     * MyBatis-Plus 驼峰映射 basic_report -> basicReport 自动完成，
     * 不需要 TypeHandler。后端不解析、不重组、原样发给前端（TOP3 合并除外）。
     */
    private String traits;
    private String basicReport;
    private String advancedReport;

    private Integer sortOrder;
}
```

**为什么透传不解析**：解析再序列化容易丢键、改键名，而且后端根本不需要知道
`one_liner` 里写了什么——那是内容，不是逻辑。只有 TOP3 合并（第 5 步）例外，
因为要「拼三份」。

## 第 2 步：建 `mapper/QuizResultMapper.java`

```java
package com.example.quiz.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.quiz.domain.QuizResult;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface QuizResultMapper extends BaseMapper<QuizResult> {
}
```

## 第 3 步：`submit()` 按 scoring_model 分流

### 3.1 先修一个隐患

现在查维度的那条 SQL **没有 ORDER BY**：

```java
List<Dimension> dims = dimensionMapper.selectList(
    new LambdaQueryWrapper<Dimension>().eq(Dimension::getQuizId, quiz.getId())
);
```

加上排序，一处改动修两个问题：

```java
List<Dimension> dims = dimensionMapper.selectList(
    new LambdaQueryWrapper<Dimension>()
        .eq(Dimension::getQuizId, quiz.getId())
        .orderByAsc(Dimension::getPairOrder)
);
```

- PAIR：`orderedPairs` 现在靠 stream 排序，但**组内平票**取「先遇到者」，顺序不定 → 排序后确定。
- MAX/TOP3：平票按 `pair_order`（类型序号 1..N）决胜，**同样输入永远同样输出**。

### 3.2 方法结构

`submit()` 里**选项查询、scoreByDimId 累加、scores 换码这三段原样不动**（它们与算分模型无关），
只把「对撞拼码」那段换成三分支：

```java
// 文件顶部加 import java.util.Objects;（第 4 步会用到）

/** 算分中间结果：type 给前端，topCodes 用于查 quiz_result */
private record ScoreResult(String type, Map<String, String> winner, List<String> topCodes) {}

// submit() 内，scores 换算完成后：
String model = quiz.getScoringModel() == null ? "PAIR" : quiz.getScoringModel();
ScoreResult s = switch (model) {
    case "MAX"  -> resolveMax(dims, scores);
    case "TOP3" -> resolveTop3(dims, scores);
    default     -> resolvePair(dims, scores);   // PAIR 是默认，未知值也兜到这
};

SubmitResponse resp = new SubmitResponse();
resp.setType(s.type());
resp.setScores(scores);
resp.setWinner(s.winner());
resp.setAnswerCount(req.getAnswers().size());

fillReports(quiz, s, resp);   // 第 4 步
return resp;
```

### 3.3 `resolvePair` —— 现有逻辑平移进方法

把现在 `submit()` 里从 `Map<String, List<Dimension>> byPair = ...` 到 `type.append(...)` 的整段剪切过来，末尾改成：

```java
private ScoreResult resolvePair(List<Dimension> dims, Map<String, Integer> scores) {
    // ……（原对撞逻辑：groupingBy(pairCode) -> 按 pairOrder 排组 -> 组内取高分）……
    // 平票保持先遇到的那个：dims 已按 pairOrder 排序，组内 [left, right] 顺序稳定
    return new ScoreResult(type.toString(), winner, List.of(type.toString()));
}
```

注意 `pair_order` 不能换成字母序——字母序会拼出 EJST（历史踩过的坑，注释里已写）。

### 3.4 `resolveMax` —— 取最高分类型

```java
/**
 * MAX：各「类型维度」累加，取最高分的那个类型。
 * DISC / 九型 / 依恋用。平票按 pairOrder（类型序号）小者胜——
 * dims 已按 pairOrder 升序，严格大于才替换，先出现的自然保持胜者。
 */
private ScoreResult resolveMax(List<Dimension> dims, Map<String, Integer> scores) {
    Dimension best = null;
    for (Dimension d : dims) {
        if (best == null
            || scores.getOrDefault(d.getCode(), 0) > scores.getOrDefault(best.getCode(), 0)) {
            best = d;   // 平票（相等）不替换：序号小的赢，结果可复现
        }
    }
    Map<String, String> winner = new LinkedHashMap<>();
    winner.put("TYPE", best.getCode());
    return new ScoreResult(best.getCode(), winner, List.of(best.getCode()));
}
```

（刻意不用 stream `max(comparing...thenComparing...)` 那种写法：
平票语义藏在比较器组合里极易写反，直白循环一眼能看出「严格大于才换」。）

**winner 为什么放 `TYPE` 一个键**：前端 `utils/report.js` 用「winner 是否恰好 4 组」
判断要不要显示维度条形图（`hasBars`）。非 MBTI 测评塞 4 组反而会画出错误的条；
放单键，前端自动只显示报告不显示条。

### 3.5 `resolveTop3` —— 霍兰德，取前三拼码

```java
/**
 * TOP3：按得分取前三个类型拼成三字母码（如 RIA），平票按 pairOrder。
 * quiz_result 没有组合码的行，topCodes 保留三个单字母给 fillReports 合并用。
 */
private ScoreResult resolveTop3(List<Dimension> dims, Map<String, Integer> scores) {
    List<Dimension> ranked = dims.stream()
        .sorted(Comparator
            .comparing((Dimension d) -> scores.getOrDefault(d.getCode(), 0)).reversed()
            .thenComparing(Dimension::getPairOrder))
        .toList();
    List<Dimension> top = ranked.subList(0, Math.min(3, ranked.size()));

    String type = top.stream().map(Dimension::getCode).collect(Collectors.joining());
    Map<String, String> winner = new LinkedHashMap<>();
    winner.put("TYPE", type);
    return new ScoreResult(type, winner, top.stream().map(Dimension::getCode).toList());
}
```

## 第 4 步：`fillReports` —— 取 quiz_result，填 4 个新字段

```java
/**
 * 从 quiz_result 取双档解析填进响应。
 * topCodes 单元素 -> 直取那一行；多元素（TOP3）-> 合并（第 5 步）。
 * 库里查不到行时降级：名字用结果码顶上，报告留空——前端对空报告有兜底，
 * 但正常数据不该走到这，走到说明 seed 没灌全。
 */
private void fillReports(Quiz quiz, ScoreResult s, SubmitResponse resp) {
    List<QuizResult> rows = resultMapper.selectList(
        new LambdaQueryWrapper<QuizResult>()
            .eq(QuizResult::getQuizId, quiz.getId())
            .in(QuizResult::getTypeCode, s.topCodes()));

    Map<String, QuizResult> byCode = rows.stream()
        .collect(Collectors.toMap(QuizResult::getTypeCode, r -> r, (a, b) -> a));

    List<QuizResult> ordered = s.topCodes().stream()
        .map(byCode::get)
        .filter(Objects::nonNull)
        .toList();

    if (ordered.isEmpty()) {
        resp.setResultName(s.type());
        return;
    }
    if (ordered.size() == 1) {
        QuizResult r = ordered.get(0);
        resp.setResultName(r.getName());
        resp.setResultSummary(r.getSummary());
        resp.setBasicReport(r.getBasicReport());
        resp.setAdvancedReport(r.getAdvancedReport());
        return;
    }
    mergeTop3Reports(ordered, resp);
}
```

别忘了给 `QuizService` 注入 `QuizResultMapper`（构造器加一个参数 + 一个字段，照现有四个 mapper 的样子写）。

## 第 5 步：`mergeTop3Reports` —— 唯一要真正处理 JSON 的地方

**为什么必须合并**：霍兰德的 `quiz_result` 只有 R/I/A/S/E/C 六行（每行一套双档解析），
运行时算出的 RIA 没有对应行。前端拿到的是一个 `basicReport`/`advancedReport`，
所以后端把三行拼成一份。

**合并规则**（主型 = 得分第一，副型 = 第二第三）：

| 字段 | 规则 |
|---|---|
| `resultName` | 三型名拼 `现实型 × 研究型 × 艺术型` |
| `resultSummary` | 主型的 summary |
| basic.one_liner / tip / weaknesses | 用主型 |
| basic.traits | 主型全部 + 每个副型第 1 条，封顶 6 |
| basic.strengths | 主型全部 + 每个副型第 1 条，封顶 5 |
| advanced.chapters | 主型 5 章 + 追加 1 章「你的副型：X 与 Y」 |
| advanced.career | 主型全部 + 每个副型前 2 条，封顶 6 |
| advanced.famous | 用主型 |

Jackson 是 `spring-boot-starter-webmvc` 自带的，不用加依赖（Spring Boot 4 自带的是 Jackson 3）：

```java
private static final ObjectMapper MAPPER = new ObjectMapper();

private void mergeTop3Reports(List<QuizResult> ordered, SubmitResponse resp) {
    QuizResult primary = ordered.get(0);
    List<QuizResult> secondary = ordered.subList(1, ordered.size());
    try {
        // ---- 初级解析 ----
        ObjectNode basic = (ObjectNode) MAPPER.readTree(
            primary.getBasicReport() == null ? "{}" : primary.getBasicReport());
        for (QuizResult r : secondary) {
            JsonNode b = MAPPER.readTree(r.getBasicReport() == null ? "{}" : r.getBasicReport());
            appendFirst(withArray(basic, "traits"), b.path("traits"), 1);
            appendFirst(withArray(basic, "strengths"), b.path("strengths"), 1);
        }
        cap(withArray(basic, "traits"), 6);
        cap(withArray(basic, "strengths"), 5);
        resp.setBasicReport(MAPPER.writeValueAsString(basic));

        // ---- 高级解析 ----
        ObjectNode adv = (ObjectNode) MAPPER.readTree(
            primary.getAdvancedReport() == null ? "{}" : primary.getAdvancedReport());

        ObjectNode extra = MAPPER.createObjectNode();
        String names = secondary.stream().map(QuizResult::getName)
            .collect(Collectors.joining(" 与 "));
        extra.put("title", "你的副型：" + names);
        StringBuilder sb = new StringBuilder();
        for (QuizResult r : secondary) {
            JsonNode b = MAPPER.readTree(r.getBasicReport() == null ? "{}" : r.getBasicReport());
            sb.append(r.getName()).append("：").append(b.path("one_liner").asText("")).append("。");
        }
        extra.put("content", sb.toString());
        withArray(adv, "chapters").add(extra);

        for (QuizResult r : secondary) {
            JsonNode a = MAPPER.readTree(r.getAdvancedReport() == null ? "{}" : r.getAdvancedReport());
            appendFirst(withArray(adv, "career"), a.path("career"), 2);
        }
        cap(withArray(adv, "career"), 6);
        resp.setAdvancedReport(MAPPER.writeValueAsString(adv));
    } catch (Exception e) {
        // JSON 坏了不让整个接口 500：降级为主型原文
        resp.setBasicReport(primary.getBasicReport());
        resp.setAdvancedReport(primary.getAdvancedReport());
    }
    resp.setResultName(ordered.stream().map(QuizResult::getName)
        .collect(Collectors.joining(" × ")));
    resp.setResultSummary(primary.getSummary());
}

/** 取 ObjectNode 里的数组字段；不存在或不是数组就建空数组放进去 */
private static ArrayNode withArray(ObjectNode parent, String field) {
    JsonNode n = parent.get(field);
    if (n instanceof ArrayNode a) return a;
    ArrayNode arr = MAPPER.createArrayNode();
    parent.set(field, arr);
    return arr;
}

/** 从 source 数组里取前 n 个追加到 target */
private static void appendFirst(ArrayNode target, JsonNode source, int n) {
    if (source instanceof ArrayNode a) {
        for (int i = 0; i < Math.min(n, a.size()); i++) {
            target.add(a.get(i).deepCopy());
        }
    }
}

/** 数组封顶，超出部分从尾部删 */
private static void cap(ArrayNode arr, int max) {
    while (arr.size() > max) arr.remove(arr.size() - 1);
}
```

需要的 import：

```java
import com.example.quiz.domain.QuizResult;
import com.example.quiz.mapper.QuizResultMapper;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.ArrayNode;
import tools.jackson.databind.node.ObjectNode;
import java.util.Objects;
```

> ⚠️ **包名必须是 `tools.jackson`，不是 `com.fasterxml`！**
> 本项目是 **Spring Boot 4.x（Spring Framework 7）**，自带的是 **Jackson 3**，包根从
> `com.fasterxml.jackson` 换成了 `tools.jackson`。JDK 里根本没有 `com.fasterxml.jackson.*`，
> 照旧写会直接编译失败：`程序包com.fasterxml.jackson.databind不存在`。
> 项目里 `PayService` / `WxAuthService` 已经是 `tools.jackson.databind.ObjectMapper`，保持一致即可。
> （注意：Jackson 2 之所以在**运行时**能被 Spring 探测到，只是因为 jjwt-jackson 是 runtime scope
> 拖进来的，它不在编译 classpath 上——所以 Spring 的 conditions 报告里看到 Jackson2、编译却找不到，别被误导。）
> Jackson 3 里 `new ObjectMapper()` 仍可用；想写得更"官方"也可以 `JsonMapper.builder().build()`（那时 import 换成 `tools.jackson.databind.json.JsonMapper`）。

## 第 6 步（可选加分，本期可跳过）：落库 `user_quiz_record`

`user_quiz_record` / `user_quiz_answer` 表 M4 就建好了，submit 目前不写它们。
做了它才有「历史记录 / 多次测评趋势」（roadmap 留存方向），简历上也能多写一条。

要点：

- `userId` 用 `UserContext.getUserId()` 取。submit 在 JWT 白名单里，**游客调时它是 null**——表设计允许 NULL，判空直接存。
- `score_json` 存 `scores` 序列化结果（Jackson `writeValueAsString`）。
- `result_code` 存 `resp.getType()`。
- 放在 fillReports 之后、return 之前；写库失败别影响返回（try/catch 包住，记日志）。

## 第 7 步：编译 + 自测

```bash
# 编译（JAVA_HOME 必须指到 D:/job/JDK）
JAVA_HOME=D:/job/JDK ./mvnw.cmd compile
```

自测工具已备好：`tools/make-submit-payload.mjs`（先 GET 出题接口拿真实题目 id，再拼提交 payload；顺便把出题接口也测了）：

```bash
# 后端先启动，然后每个测评各测一轮
node tools/make-submit-payload.mjs mbti > payload-mbti.json
curl -s -X POST http://localhost:8080/api/quiz/submit \
     -H "Content-Type: application/json" -d @payload-mbti.json
```

验收清单（全选第 0 项的策略，结果可预期）：

| 测评 | 断言 |
|---|---|
| `mbti` | `type` 是 4 字母（全选 0 → **ESTJ**：题库里每组左侧维度都排在选项 0，四组左胜）；`winner` 恰好 4 组；`basicReport` 字符串里 grep 得到 `one_liner` |
| `disc` | `type` 是单字母（全选 0 → **D**：每题选项 0 恒指向支配型维度）；`winner` 只有 `TYPE` 一键 |
| `enneagram` | 单数字码（全选 0 → 九型全平票 4 分 → 按序号取 **1** 完美型）；`resultName` 是「完美型」式名字 |
| `holland` | `type` 是 3 字母（全选 0 → 六型全平票 5 分 → 取序号前三 **RIA**）；`resultName` 含两个 `×`；`advancedReport` 的 `chapters` 有 **6** 章（主型 5 + 副型速览 1） |
| `attachment` | 英文码（全选 0 → 四型全平票 6 分 → **secure** 安全型）；`resultName` 是中文类型名 |

前端联调预期：真机提交后结果页应显示 **「✓ 解析已联网获取」** 徽标 + 完整双档解析；
把后端停掉再测，MBTI 落「⚠ 本地兜底」降级版——两条路径都通即闭环。

## 第 8 步：部署生产

```bash
# 1) 结构+数据（幂等，可重复跑）
mysql -h127.0.0.1 -P3307 -uguiz -p guiz < docs/db-full.sql

# 2) 打包
JAVA_HOME=D:/job/JDK ./mvnw.cmd package

# 3) 服务器重启（历史命令，注意必须带 prod profile）
cd /www/wwwroot/quiz-backend && pkill -f quiz-backend-*.jar && \
  nohup java -jar quiz-backend-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=prod > quiz.log 2>&1 &

# 4) 域名验收
node tools/make-submit-payload.mjs holland https://wangwang2.asia > ph.json
curl -s -X POST https://wangwang2.asia/api/quiz/submit \
     -H "Content-Type: application/json" -d @ph.json
```

---

## 踩坑清单（按你会遇到的顺序）

1. **Jackson 包名是 `tools.jackson` 不是 `com.fasterxml`**（2026-09-20 实踩）：Spring Boot 4 自带 Jackson 3，`new ObjectMapper()` 照写，但 import 必须是 `tools.jackson.databind.*`。写 `com.fasterxml` → `程序包com.fasterxml.jackson.databind不存在`，整个 `mvn compile` 挂掉。
2. **`pair_order` 不是字母序**（历史坑）：PAIR 拼码顺序只能用 `pair_order`，字母序拼出 EJST。
3. **dims 查询原来没有 ORDER BY**：平票结果依赖 MySQL 返回顺序 = 不可复现。第 3.1 步加 `orderByAsc(pairOrder)` 一并修掉。
4. **JSON 列用 String 透传**：不要在 Java 里 parse 再 serialize（TOP3 合并除外）——省事、不丢键、不改键名。
5. **TOP3 必须合并**：`quiz_result` 没有 RIA 这种组合码的行，只有 6 个单字母行。忘了合并直接按 type 查会查空。
6. **查不到 quiz_result 行别 NPE**：`resultName` 用结果码兜底、报告留空；前端对空报告有降级（`buildCloudReport` 里 `safeJson` 兜底）。
7. **非 MBTI 的 winner 别硬凑 4 组**：前端靠「winner 恰好 4 组」决定显不显示维度条。塞 `TYPE` 单键即可，条形图自动隐藏——这是设计好的行为，不是 bug。
8. **别信前端传来的分数**（老原则）：维度、分值全部查库；`optionIndex` 越界跳过（现有代码已处理，别删）。
9. **`seed-mbti.sql` 的 quiz INSERT 没带 `scoring_model` 列**：靠列 DEFAULT `'PAIR'` 兜底，是对的，不用手贱补 UPDATE。
10. **前端 `QUIZ_CODE` 目前仍硬编码 `'mbti'`**：多测评的「前端选测评→动态 code」是下一个前端任务（我来做）；你后端先把 5 个 code 全跑通，接口层面不要写死任何测评。

---

*文档生成：2026-09-20。前端契约详见 `docs/uni-app-frontend/utils/report.js`（report 形状）与
`SubmitResponse.java`（字段注释）。*
