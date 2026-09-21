-- =============================================================================
-- 回填 quiz 表的展示字段：question_count / emoji / tag（幂等，随便跑几次都一样）
-- -----------------------------------------------------------------------------
-- 为什么要回填这三列：
--   1) question_count：seed 插 quiz 行时题库还没插，一律写成 0，跑完没人回填，
--      于是首页 GET /api/quiz/list 拿到的 question_count 全是 0，前端显示「0 题」。
--      按 question 表真实题数 UPDATE 永远是对的（题库可能被重导、题目会被下架 status=0），
--      写死在 seed 里反而会对不上。
--   2) emoji / tag：MBTI 那行是从 CSV 生成的（tools/import_mbti_csv.py 只输题库），
--      没写 emoji/tag，结果首页唯独 MBTI 没图标(tag 也是 null)。
--      这里按 code 补上；只对 NULL/空值生效，手改过的不会被覆盖。
-- =============================================================================

UPDATE `quiz` q
SET question_count = (
    SELECT COUNT(*) FROM `question` WHERE quiz_id = q.id AND `status` = 1
)
WHERE EXISTS (SELECT 1 FROM `question` WHERE quiz_id = q.id);

UPDATE `quiz`
SET emoji = '🧠', tag = '性格'
WHERE `code` = 'mbti' AND (emoji IS NULL OR emoji = '');

-- 校验：应该看到 93 / 20 / 36 / 30 / 24，且 mbti 有 emoji
SELECT id, `code`, `name`, emoji, tag, question_count FROM `quiz` ORDER BY sort_order;
