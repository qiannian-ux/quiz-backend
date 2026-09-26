#!/bin/bash
# =============================================================================
# 线上部署体检（在宝塔「终端」里整段粘贴执行，只读，不动任何东西）
# -----------------------------------------------------------------------------
# 用来回答一个问题：线上跑的 jar，到底是不是我这台刚打的那个？
#
# 判据：新的 jar 里 /api/weather 已经在 JWT 白名单里，会放行；
#       旧 jar 会直接 401 {"code":401,"msg":"未登录"}。
#       所以只要线上 /api/weather 返回 401，就等于"新代码没生效"。
# =============================================================================
APP_DIR="/www/wwwroot/quiz-backend"
JAR="quiz-backend-0.0.1-SNAPSHOT.jar"
SUP="/www/server/panel/pyenv/bin/supervisorctl"

echo "=========== 1. java 进程（看有几个、什么时候起的）"
ps -ef | grep -i "[j]ava" || echo "  没有 java 进程"

echo
echo "=========== 2. 8080 端口被谁占着"
ss -ltnp | grep 8080 || echo "  8080 没进程在听"

echo
echo "=========== 3. jar 文件时间 + 是否含天气类"
ls -l --time-style=full-iso "$APP_DIR/$JAR" 2>/dev/null || echo "  $APP_DIR/$JAR 不存在"
unzip -l "$APP_DIR/$JAR" 2>/dev/null | grep -ci "Weather" | \
  sed 's/^/  含 Weather 关键字行数: /'
unzip -l "$APP_DIR/$JAR" 2>/dev/null | grep -i "WeatherService.class" | head -n 1 || \
  echo "  ★ jar 里没有 WeatherService.class —— 部署的就是旧包"

echo
echo "=========== 4. Supervisor 状态（装了才有）"
if [ -x "$SUP" ]; then
  "$SUP" status
else
  echo "  没装 supervisorctl（$SUP），走的应该是 nohup"
fi

echo
echo "=========== 5. 应用日志最后 25 行"
tail -n 25 "$APP_DIR/quiz.log" 2>/dev/null || echo "  没有 $APP_DIR/quiz.log"

echo
echo "=========== 6. 线上接口实测（绕过 Nginx 反代，直接打 8080）"
for u in "api/weather?city=%E6%88%90%E9%83%BD" "api/quiz/list"; do
  printf "  %-42s -> " "$u"
  curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://127.0.0.1:8080/$u"
done
echo "  天气接口完整返回："
curl -s "http://127.0.0.1:8080/api/weather?city=%E6%88%90%E9%83%BD" | head -c 300
echo

echo
echo "=========== 结论判读"
echo "  weather 返回 401  -> 线上是旧 jar，见下一步修复"
echo "  weather 返回 ok:false + msg -> 新包已生效，只是 weather.key / api-host 没配好"
echo "  weather 返回 ok:true        -> 全部正常"
