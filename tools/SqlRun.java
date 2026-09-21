/**
 * 在没有 mysql 客户端的机器上跑 SQL 文件的极简工具。
 *
 * 背景：本机（Windows + PortableGit）装不了 mysql CLI，
 * 但项目自带 mysql-connector-j（pom 里 runtime scope），
 * 所以直接用 JDBC 驱动把 .sql 文件喂进去最省事。
 *
 * 用法（单文件源码模式，不需要编译）：
 *   java -cp <mysql-connector-j-x.y.z.jar> tools/SqlRun.java <jdbcUrl> <user> <pass> <sqlFile> [--dry]
 *
 * 例（本地走私 MySQL）：
 *   java -cp ~/.m2/repository/com/mysql/mysql-connector-j/9.x/mysql-connector-j-9.x.jar \
 *        tools/SqlRun.java "jdbc:mysql://127.0.0.1:3306/quiz_smoke?serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&useSSL=false" root 123456 docs/db-full.sql
 *
 * 实现要点（别改简单了，会踩）：
 *   1. 支持 MySQL 的 DELIMITER $$ ... $$ 块（存储过程用），朴素按 ';' 切会把过程体切碎。
 *   2. 去掉整行注释（-- ）再拼行，避免注释里的分号被当成语句结束。
 *   3. statement 用 execute()，兼容 SELECT（有结果集）和 DDL/DML。
 *   4. 出错默认继续往下跑（修表脚本幂等，个别已存在的列报错不影响），末尾汇总失败条数。
 */
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class SqlRun {

    public static void main(String[] args) throws Exception {
        if (args.length < 4) {
            System.out.println("用法: java -cp <mysql-connector-j.jar> SqlRun.java <jdbcUrl> <user> <pass> <sqlFile> [--dry]");
            System.exit(2);
        }
        String url = args[0], user = args[1], pass = args[2], file = args[3];
        boolean dry = args.length > 4 && "--dry".equals(args[4]);

        List<String> statements = split(read(file));
        System.out.println("[SqlRun] " + file + " -> " + url + "，共 " + statements.size() + " 条语句"
            + (dry ? "（DRY RUN，不执行）" : ""));
        if (dry) {
            statements.forEach(s -> System.out.println("----\n" + s));
            return;
        }

        int ok = 0, failed = 0;
        try (Connection conn = DriverManager.getConnection(url, user, pass)) {
            for (String sql : statements) {
                try (Statement st = conn.createStatement()) {
                    boolean hasRs = st.execute(sql);
                    if (hasRs) {
                        print(st.getResultSet());
                    }
                    ok++;
                } catch (SQLException e) {
                    failed++;
                    System.out.println("[FAIL] " + head(sql) + "\n       -> " + e.getMessage());
                }
            }
        }
        System.out.println("[SqlRun] 完成：成功 " + ok + " 条，失败 " + failed + " 条");
        if (failed > 0) System.exit(1);
    }

    /** 读文件并去掉整行注释（保留行结构，方便后面按分号切） */
    private static List<String> read(String file) throws IOException {
        List<String> lines = new ArrayList<>();
        for (String raw : Files.readAllLines(Path.of(file), StandardCharsets.UTF_8)) {
            String t = raw.strip();
            if (t.startsWith("--") || t.startsWith("#")) continue;
            lines.add(raw);
        }
        return lines;
    }

    /** 按 ';' 切语句，但先把 DELIMITER 块整体保护起来 */
    private static List<String> split(List<String> lines) {
        List<String> out = new ArrayList<>();
        StringBuilder buf = new StringBuilder();
        String delimiter = ";";
        for (String line : lines) {
            String t = line.strip();
            if (t.toUpperCase().startsWith("DELIMITER")) {
                String newDelim = t.substring("DELIMITER".length()).strip();
                if (buf.length() > 0 && !buf.toString().isBlank()) {
                    out.add(buf.toString().strip());
                    buf.setLength(0);
                }
                delimiter = newDelim;
                continue;
            }
            buf.append(line).append('\n');
            if (t.endsWith(delimiter)) {
                String stmt = buf.toString().strip();
                // 去掉尾部分隔符（DELIMITER 块的多余换行由 MySQL 自己处理）
                if (stmt.endsWith(delimiter)) stmt = stmt.substring(0, stmt.length() - delimiter.length()).strip();
                if (!stmt.isBlank()) out.add(stmt);
                buf.setLength(0);
            }
        }
        if (buf.length() > 0 && !buf.toString().isBlank()) out.add(buf.toString().strip());
        return out;
    }

    private static void print(ResultSet rs) throws SQLException {
        ResultSetMetaData md = rs.getMetaData();
        StringBuilder header = new StringBuilder();
        for (int i = 1; i <= md.getColumnCount(); i++) header.append(md.getColumnLabel(i)).append('\t');
        System.out.println(header.toString().strip());
        int rows = 0;
        while (rs.next() && rows < 50) {
            StringBuilder row = new StringBuilder();
            for (int i = 1; i <= md.getColumnCount(); i++) row.append(rs.getString(i)).append('\t');
            System.out.println(row.toString().strip());
            rows++;
        }
        System.out.println("(" + rows + " 行)");
    }

    private static String head(String s) {
        String one = s.replaceAll("\\s+", " ");
        return one.length() > 120 ? one.substring(0, 120) + "..." : one;
    }
}
