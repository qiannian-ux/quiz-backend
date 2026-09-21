import io, re
p = r'C:/Users/35156/IdeaProjects/quiz-backend/docs/mbti_questions_mysql.sql'
s = io.open(p, encoding='utf-8').read()
print('字符数:', len(s), ' 行数:', s.count('\n'))
for kw in ['"public"', '+08', "'true'"]:
    for m in re.finditer(re.escape(kw), s):
        a = max(0, m.start()-80)
        print('---', kw, '@', m.start(), '---')
        print(s[a:m.start()+60].replace('\n', ' '))
print('=== 前300字符 ===')
print(s[:300])
