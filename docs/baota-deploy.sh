#!/bin/bash
# =============================================================================
# 探我趣测 · 宝塔面板一键部署脚本
# -----------------------------------------------------------------------------
# 解决什么：每次改完后端 → 本地打包 → 宝塔上传 jar → 服务器上自动停旧起新。
#
# 两种用法（同一个脚本都能处理，脚本自己判断当前是哪种模式）：
#
#   A) 全自动（推荐搭配「计划任务」）
#      宝塔 → 计划任务 → 添加任务 → 类型选「Shell 脚本」→ 周期选「自定义」
#      cron 填 */1 * * * *  → 脚本内容填本文件的绝对路径
#      之后你只要往 /www/wwwroot/quiz-backend/ 覆盖上传 jar，最多 1 分钟内自动生效。
#
#   B) 手动触发（搭配 Supervisor / 或者自己敲）
#      宝塔 → 终端 → 执行：bash /www/wwwroot/quiz-backend/deploy.sh
#
# 进程托管（关键，决定靠不靠谱）：
#   · 如果服务器装了宝塔「软件商店 → Supervisor 管理器」并加了守护进程
#     （进程名见下面的 SVC_NAME），脚本会走 supervisorctl restart，由它负责拉起；
#   · 否则脚本自己 pkill + nohup 起（缺守护：服务器重启/进程被杀不会自动回来）。
#
# 幂等：md5 没变就什么都不做，可以放心每分钟跑一次。
# =============================================================================

# ---------- 按需改这几个变量 ----------
APP_DIR="/www/wwwroot/quiz-backend"
JAR_NAME="quiz-backend-0.0.1-SNAPSHOT.jar"
JAR_FULL="$APP_DIR/$JAR_NAME"
SVC_NAME="quiz-backend"          # Supervisor 里的进程名，不匹配就按 nohup 模式走
LOG_FILE="$APP_DIR/quiz.log"     # 用 >> 追加，别用 > 覆盖，否则历史错误全没了
KEEP_BACKUPS=3
# -------------------------------------

log() { echo "[$(date '+%F %T')] $*"; }

# 1) 目录和文件存在性
if [ ! -f "$JAR_FULL" ]; then
  log "跳过：$JAR_FULL 不存在"
  exit 0
fi

# 2) 防半包：上传/传输没结束时，两次读到的大小必须一致
BEFORE=$(stat -c %s "$JAR_FULL" 2>/dev/null)
sleep 3
AFTER=$(stat -c %s "$JAR_FULL" 2>/dev/null)
if [ "$BEFORE" != "$AFTER" ] || [ -z "$AFTER" ]; then
  log "跳过：jar 正在写入或大小异常（$BEFORE -> $AFTER），下一轮再试"
  exit 0
fi

# 3) md5 比对：没变就不动，避免每分钟白重启一次
MD5_FILE="$APP_DIR/.jar.md5"
NEW_MD5=$(md5sum "$JAR_FULL" | awk '{print $1}')
OLD_MD5=""
[ -f "$MD5_FILE" ] && OLD_MD5=$(cat "$MD5_FILE")
if [ "$NEW_MD5" = "$OLD_MD5" ] && [ -n "$NEW_MD5" ]; then
  exit 0
fi
log "md5 变化：${OLD_MD5:-无} -> $NEW_MD5，开始部署"

# 4) 备份上一版
mkdir -p "$APP_DIR/backup"
if [ -f "$JAR_FULL" ]; then
  cp -f "$JAR_FULL" "$APP_DIR/backup/$(date '+%F_%H%M%S').jar"
  cd "$APP_DIR/backup" && ls -1t *.jar 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm -f
fi

# 5) 停旧进程。两种模式二选一，避免"杀了又立刻被拉起"或"两个实例抢 8080"。
SUP="supervisorctl"
[ -x "/www/server/panel/pyenv/bin/$SUP" ] && SUP="/www/server/panel/pyenv/bin/$SUP"

if command -v "$SUP" >/dev/null 2>&1 && "$SUP" status "$SVC_NAME" >/dev/null 2>&1; then
  MODE="supervisor"
  log "停止 Supervisor 守护进程 $SVC_NAME"
  "$SUP" stop "$SVC_NAME" >/dev/null 2>&1
else
  MODE="nohup"
  log "杀掉旧 java 进程"
  pkill -9 -f "$JAR_NAME" >/dev/null 2>&1
fi
sleep 3
if ss -ltnp 2>/dev/null | grep -q ':8080'; then
  log "⚠ 8080 仍被占用，稍等再试或手动查进程：ss -ltnp | grep 8080"
fi

# 6) 起新进程
cd "$APP_DIR" || exit 1
if [ "$MODE" = "supervisor" ]; then
  "$SUP" start "$SVC_NAME" >/dev/null 2>&1
else
  JAVA="java"
  command -v java >/dev/null 2>&1 || JAVA=$(ls /www/server/java/bin/java 2>/dev/null || echo /usr/bin/java)
  nohup "$JAVA" -jar "$JAR_FULL" --spring.profiles.active=prod >> "$LOG_FILE" 2>&1 &
fi
echo "$NEW_MD5" > "$MD5_FILE"

# 7) 等它起来，给出判断
sleep 10
if grep -q "Started QuizBackendApplication" "$LOG_FILE"; then
  log "部署完成，日志末 5 行："
  tail -n 5 "$LOG_FILE"
else
  log "⚠ 没看到 Started QuizBackendApplication，日志末 20 行："
  tail -n 20 "$LOG_FILE"
fi
