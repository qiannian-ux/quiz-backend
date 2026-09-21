package com.example.quiz.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.quiz.domain.Question;
import org.apache.ibatis.annotations.Mapper;

/**
 * 题目 Mapper。
 *
 * 原来这里有个 selectQuestionWithOptions() 配合 QuestionMapper.xml 做嵌套查询，
 * 已删除。原因：嵌套查询是「每道题查一次选项」，100 道题就是 101 条 SQL（N+1 问题）。
 * 现在改成在 Service 里一次性查出所有选项、内存里按 questionId 分组，
 * 无论多少题都只要 2 条 SQL。
 */
@Mapper
public interface QuestionMapper extends BaseMapper<Question> {
}
