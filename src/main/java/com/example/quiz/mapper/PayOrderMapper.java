package com.example.quiz.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.quiz.domain.PayOrder;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface PayOrderMapper extends BaseMapper<PayOrder> {

    @Select("SELECT * FROM pay_order WHERE out_trade_no = #{outTradeNo} LIMIT 1")
    PayOrder selectByOutTradeNo(String outTradeNo);

    @Select("SELECT * FROM pay_order WHERE wx_order_id = #{wxOrderId} LIMIT 1")
    PayOrder selectByWxOrderId(String wxOrderId);
}
