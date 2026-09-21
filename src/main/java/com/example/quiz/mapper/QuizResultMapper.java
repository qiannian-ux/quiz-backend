package com.example.quiz.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.quiz.domain.QuizResult;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface QuizResultMapper extends BaseMapper<QuizResult> {
}
