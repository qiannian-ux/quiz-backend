package com.example.quiz.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.quiz.domain.UserLoginDay;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDate;

/**
 * 登录日期明细表操作。
 * ------------------------------------------------------------
 * 这里两个方法都绕开 MyBatis-Plus 的通用方法，原因写在各方法上。
 */
@Mapper
public interface UserLoginDayMapper extends BaseMapper<UserLoginDay> {

    /**
     * 记一次登录，重复调用不会虚增。
     * ------------------------------------------------------------
     * 为什么用 INSERT IGNORE 而不是先 select 再 insert？
     *   1. 少一次查询；
     *   2. 关键：先查后插在并发下会插重（两个请求同时查到"没有"），
     *      而 INSERT IGNORE + UNIQUE 由数据库兜底，怎么并发都只会有一行。
     *
     * @return 影响行数：1 = 今天第一次登录（真新增）；0 = 已有，被忽略了
     */
    @Insert("INSERT IGNORE INTO user_login_day (user_id, login_date) VALUES (#{userId}, #{loginDate})")
    int insertIgnore(@Param("userId") Long userId, @Param("loginDate") LocalDate loginDate);

    /**
     * 累计登录天数。
     * ------------------------------------------------------------
     * 为什么不直接用 user.total_login_days 那个冗余列？
     *   冗余列可能被别处写歪，也可能迁移后没回填。这里以明细为准重新数一次，
     *   顺手还能把冗余列刷回正确值（自愈）。
     *   登录打点一天才一次，COUNT 的开销可以忽略。
     */
    @Select("SELECT COUNT(*) FROM user_login_day WHERE user_id = #{userId}")
    int countByUser(@Param("userId") Long userId);
}
