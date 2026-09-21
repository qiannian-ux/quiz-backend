# -*- coding: utf-8 -*-
"""
把 PostgreSQL 导出的 mbti_questions_rows.sql 转成 MySQL 8.0 能直接执行的版本。
差异点：
  1. "public"."mbti_questions"  -> `mbti_questions`
  2. "列名"                     -> `列名`
  3. 'true' / 'false'           -> 1 / 0
  4. '2026-03-28 19:54:03.784876+08' -> '2026-03-28 19:54:03'（MySQL datetime 不认时区后缀）
"""
import re
import io
import collections

SRC = r'C:\Users\35156\Downloads\mbti_questions_rows.sql'
OUT = r'C:\Users\35156\IdeaProjects\quiz-backend\docs\mbti_questions_mysql.sql'

src = io.open(SRC, encoding='utf-8').read()

# 1) schema 限定符
s = src.replace('"public"."mbti_questions"', '`mbti_questions`')

# 2) 双引号标识符 -> 反引号
s = re.sub(r'"(\w+)"', r'`\1`', s)

TS = re.compile(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+\+\d+$')
STR = re.compile(r"'((?:[^']|'')*)'")


def fix(m):
    v = m.group(1)
    if v == 'true':
        return '1'
    if v == 'false':
        return '0'
    if TS.match(v):
        return "'" + v[:19] + "'"
    return m.group(0)


s = STR.sub(fix, s)

# 维度分布统计：每条记录里 option_a_dimension 出现在第 4 个字段
dims = collections.Counter()
for m in re.finditer(r"'\d+', '.*?', '.*?', '([EINSTFJP])', '\d+'", s):
    dims[m.group(1)] += 1

# 题目 id 统计
ids = [int(x) for x in re.findall(r"VALUES \('(\d+)'", s)] + \
      [int(x) for x in re.findall(r"\), \('(\d+)'", s)]

HEADER = """-- MBTI 题库（PostgreSQL -> MySQL 8.0 转换版）
-- 转换点：schema 限定符 / 双引号标识符 / 'true'->1 / 时间戳去掉 +08 时区
-- 目标库：guiz    字符集：utf8mb4
DROP TABLE IF EXISTS `mbti_questions`;
CREATE TABLE IF NOT EXISTS `mbti_questions` (
  `id`                 BIGINT       NOT NULL                COMMENT '题目ID',
  `question_text`      VARCHAR(500) NOT NULL                COMMENT '题干',
  `option_a_text`      VARCHAR(255) NOT NULL                COMMENT '选项A文案',
  `option_a_dimension` VARCHAR(8)   NOT NULL                COMMENT '选项A维度 E/I/S/N/T/F/J/P',
  `option_a_score`     INT          NOT NULL DEFAULT 1      COMMENT '选项A得分',
  `option_b_text`      VARCHAR(255) NOT NULL                COMMENT '选项B文案',
  `option_b_dimension` VARCHAR(8)   NOT NULL                COMMENT '选项B维度',
  `option_b_score`     INT          NOT NULL DEFAULT 1      COMMENT '选项B得分',
  `sort_order`         INT          NOT NULL DEFAULT 0      COMMENT '排序',
  `is_active`          TINYINT(1)   NOT NULL DEFAULT 1      COMMENT '是否启用',
  `created_at`         DATETIME     NULL,
  `updated_at`         DATETIME     NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MBTI 题库';

"""

io.open(OUT, 'w', encoding='utf-8').write(HEADER + s + '\n')

print('输出文件:', OUT)
print('题目条数:', len(ids))
if ids:
    print('ID 范围:', min(ids), '~', max(ids))
print('维度分布(按选项A):', dict(sorted(dims.items())))
