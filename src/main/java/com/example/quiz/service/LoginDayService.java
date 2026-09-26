package com.example.quiz.service;

import com.example.quiz.domain.User;
import com.example.quiz.dto.CheckinResponse;
import com.example.quiz.mapper.UserLoginDayMapper;
import com.example.quiz.mapper.UserMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneId;

/**
 * 登录天数（累计 / 连续）—— 权威数据在这一层。
 * ------------------------------------------------------------
 * 三条铁律，改代码时别破坏：
 *   1. **日期一律服务端生成**（Asia/Shanghai），绝不接受前端传日期；
 *   2. **同一天只算一次** —— 由 user_login_day 的 UNIQUE(user_id, login_date)
 *      保证，配合 INSERT IGNORE，重复调用天然幂等；
 *   3. **累计天数以明细表 COUNT(*) 为准**，user 上那三列只是冗余，
 *      对不上时以明细表为准（本类每次打点都会顺手把冗余列刷回正确值）。
 *
 * 为什么这么较真？这个字段以后要按天数折算代币。
 * 前端本地存储能被清、被改、换设备不同步，拿它结算等于白送。
 */
@Service
public class LoginDayService {

    /**
     * ⚠️ 必须显式指定时区。
     * 服务器（尤其是容器）默认时区常常是 UTC，直接用 LocalDate.now() 会差 8 小时：
     * 用户北京时间早上 8 点前打开小程序，会被算成"前一天"，
     * 表现为连续签到莫名断掉。这里写死上海时区，和 SQL 迁移里的
     * SET time_zone = '+08:00' 保持一致。
     */
    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");

    private final UserMapper userMapper;
    private final UserLoginDayMapper loginDayMapper;

    public LoginDayService(UserMapper userMapper, UserLoginDayMapper loginDayMapper) {
        this.userMapper = userMapper;
        this.loginDayMapper = loginDayMapper;
    }

    /**
     * 登录打点。可以随便重复调用，不会让天数虚增。
     *
     * @param userId 来自 JWT（UserContext），不是请求参数 —— 前端伪造不了
     * @return 累计 / 连续天数
     */
    @Transactional
    public CheckinResponse checkin(Long userId) {
        LocalDate today = LocalDate.now(ZONE);
        User u = requireUser(userId);

        LocalDate last = u.getLastLoginDate();

        // INSERT IGNORE：影响行数 1 = 今天第一次，0 = 已经记过（被 UNIQUE 忽略）
        int affected = loginDayMapper.insertIgnore(userId, today);
        boolean isNewDay = affected > 0;

        int total = nz(u.getTotalLoginDays());
        int consecutive = nz(u.getConsecutiveLoginDays());

        if (isNewDay) {
            // 以明细表为准重新数一次，顺手纠正可能被写歪的冗余列
            total = loginDayMapper.countByUser(userId);

            if (today.equals(last)) {
                // 冗余列说今天登录过、但明细里缺行 —— 说明数据被破坏过。
                // 保守处理：连续天数保持不动，不因为补一行就把它清零。
                consecutive = nz(u.getConsecutiveLoginDays());
            } else if (last != null && last.equals(today.minusDays(1))) {
                // 昨天也来过，接上
                consecutive = nz(u.getConsecutiveLoginDays()) + 1;
            } else {
                // 中间断过，从今天重新数
                consecutive = 1;
            }

            // 只更新这三列：新建对象 setId + 三个字段，
            // 不用查出来的那个对象整体 update，避免把并发下别人改的字段覆盖回去
            User patch = new User();
            patch.setId(userId);
            patch.setTotalLoginDays(total);
            patch.setConsecutiveLoginDays(consecutive);
            patch.setLastLoginDate(today);
            userMapper.updateById(patch);
        }

        CheckinResponse resp = new CheckinResponse();
        resp.setTotalLoginDays(total);
        resp.setConsecutiveLoginDays(consecutive);
        resp.setNewDay(isNewDay);
        return resp;
    }

    /**
     * 只查询，不打点。页面想刷新数字又不想上报时用。
     *
     * ⚠️ 这里要做一次"断签修正"：如果用户最后一次登录是前天或更早，
     *    说明连续已经断了，但冗余列还留着断之前的值。
     *    直接把那个旧值返回去，页面会显示一个不该存在的连续天数。
     */
    public CheckinResponse stats(Long userId) {
        LocalDate today = LocalDate.now(ZONE);
        User u = requireUser(userId);

        int consecutive = nz(u.getConsecutiveLoginDays());
        LocalDate last = u.getLastLoginDate();

        // last 是 null（从没打过点）或早于昨天 → 连续已断
        if (last == null || last.isBefore(today.minusDays(1))) {
            consecutive = 0;
        }

        CheckinResponse resp = new CheckinResponse();
        resp.setTotalLoginDays(nz(u.getTotalLoginDays()));
        resp.setConsecutiveLoginDays(consecutive);
        resp.setNewDay(false);   // 查询接口不涉及"是否今天第一次"
        return resp;
    }

    private User requireUser(Long userId) {
        if (userId == null) {
            throw new IllegalArgumentException("未登录");
        }
        User u = userMapper.selectById(userId);
        if (u == null) {
            throw new IllegalArgumentException("用户不存在");
        }
        return u;
    }

    /** null 安全：数据库默认值是 0，但老数据迁移前可能为 null */
    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
