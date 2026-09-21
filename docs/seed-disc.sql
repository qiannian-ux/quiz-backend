-- =============================================================================
-- 探我趣测 · DISC 行为风格测评（全套数据）
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 算分模型：scoring_model = MAX —— 四个类型维度各自累加，取总分最高的那个。
--          （区别于 MBTI 的 PAIR：按 pair_code 对撞取大，拼出 4 字母码）
-- 题目：20 道四选一，每个选项给对应类型维度 +1 分。
-- 用法：mysql ... < docs/seed-disc.sql（开头清 quiz_id=2 再重插，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 2);
DELETE FROM `question`        WHERE `quiz_id` = 2;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 2;
DELETE FROM `dimension`       WHERE `quiz_id` = 2;
DELETE FROM `quiz`            WHERE `id`      = 2;

-- 测评本体（scoring_model = MAX：累加取最高分类型）
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`emoji`,`tag`,`sort_order`,`question_count`,`price_coin`,`scoring_model`,`status`) VALUES
(2,'disc','DISC 行为风格测试','2 分钟看清你做事的风格','DISC 把人的行事风格分成支配、影响、稳健、谨慎四种倾向。它不测能力高低，只描述你在压力和目标面前更习惯怎么行动——这也是同事最容易误解你的地方。','🔥','性格',2,0,0,'MAX',1);

-- 类型维度（4 个，MAX 模型下 dimension 一行 = 一个结果类型，pair_code 统一 TYPE）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(9,2,'D','支配型','TYPE',1),
(10,2,'I','影响型','TYPE',2),
(11,2,'S','稳健型','TYPE',3),
(12,2,'C','谨慎型','TYPE',4);

-- 题目（20 道，四选一）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (200,2,'面对一个突发任务，你的第一反应是：',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(200,'立刻定目标，分配谁做什么',9,1,0),
(200,'先拉人聊聊，把气氛搞起来',10,1,1),
(200,'先确认细节，别出错',11,1,2),
(200,'先查清规则和历史数据',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (201,2,'团队讨论陷入僵局时，你会：',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(201,'直接拍板，责任我来担',9,1,0),
(201,'讲个笑话缓和，再引导大家说',10,1,1),
(201,'安静听着，等别人先表态',11,1,2),
(201,'把分歧点列出来逐条分析',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (202,2,'你理想的工作节奏是：',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(202,'快、有挑战、能说了算',9,1,0),
(202,'热闹、能认识人、不枯燥',10,1,1),
(202,'稳定、可预期、少变动',11,1,2),
(202,'有标准、能钻研、不被催',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (203,2,'方案被人当面否定，你会：',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(203,'当场据理力争',9,1,0),
(203,'表面笑笑，心里有点受伤',10,1,1),
(203,'不太舒服，但先不回应',11,1,2),
(203,'追问依据，用数据回敬',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (204,2,'做决定时你更依赖：',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(204,'我想要的结果',9,1,0),
(204,'大家的感受',10,1,1),
(204,'过去的经验',11,1,2),
(204,'事实和数据',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (205,2,'周末你更愿意：',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(205,'搞点有成就感的事',9,1,0),
(205,'约朋友出去玩',10,1,1),
(205,'在家陪家人或休息',11,1,2),
(205,'研究点感兴趣的东西',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (206,2,'你最受不了别人：',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(206,'磨叽、不推进',9,1,0),
(206,'冷淡、不给反馈',10,1,1),
(206,'突然变卦、制造冲突',11,1,2),
(206,'含糊、不讲逻辑',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (207,2,'带团队时你更在意：',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(207,'目标有没有达成',9,1,0),
(207,'团队氛围好不好',10,1,1),
(207,'成员状态稳不稳',11,1,2),
(207,'流程是否规范',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (208,2,'新项目启动会上，你通常：',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(208,'追问 deadline 和责任人',9,1,0),
(208,'主动暖场、活跃气氛',10,1,1),
(208,'记下分工，默默配合',11,1,2),
(208,'问清楚验收标准',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (209,2,'面对规则，你觉得：',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(209,'规则是用来突破的',9,1,0),
(209,'差不多就行，别太死板',10,1,1),
(209,'按规矩来最省心',11,1,2),
(209,'规则必须严谨执行',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (210,2,'你发消息的习惯是：',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(210,'短、直接、说重点',9,1,0),
(210,'语音多、表情多、爱分享',10,1,1),
(210,'斟酌一下再发，怕伤人',11,1,2),
(210,'会检查错别字和数据',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (211,2,'被临时加塞一个活，你会：',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(211,'评估值不值，不值就推掉',9,1,0),
(211,'先答应，边做边想',10,1,1),
(211,'接下来说，哪怕自己加班',11,1,2),
(211,'先问优先级，排进计划',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (212,2,'你更希望别人怎么评价你：',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(212,'有魄力',9,1,0),
(212,'有感染力',10,1,1),
(212,'靠谱',11,1,2),
(212,'专业',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (213,2,'处理冲突时你倾向：',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(213,'正面沟通，快刀斩乱麻',9,1,0),
(213,'打圆场，先把情绪顺过来',10,1,1),
(213,'回避，等它自己过去',11,1,2),
(213,'讲道理，分清对错',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (214,2,'学习一项新技能，你喜欢：',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(214,'直接上手，边错边学',9,1,0),
(214,'找人一起学，互相聊',10,1,1),
(214,'按部就班跟着教程',11,1,2),
(214,'先把原理吃透',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (215,2,'你桌面的状态通常是：',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(215,'乱，但我知道东西在哪',9,1,0),
(215,'贴满便签和照片',10,1,1),
(215,'整洁，按习惯摆放',11,1,2),
(215,'分类清晰，有标签',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (216,2,'别人常觉得你说话：',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(216,'太冲',9,1,0),
(216,'太多',10,1,1),
(216,'太少',11,1,2),
(216,'太较真',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (217,2,'面对风险，你：',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(217,'敢赌，输了再来',9,1,0),
(217,'看感觉，乐观居多',10,1,1),
(217,'能避就避',11,1,2),
(217,'先算概率再决定',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (218,2,'完成一件大事后，你的第一想法是：',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(218,'下一个目标是什么',9,1,0),
(218,'赶紧跟人分享',10,1,1),
(218,'终于可以喘口气',11,1,2),
(218,'复盘哪里还能优化',12,1,3);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (219,2,'你最看重的工作回报是：',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(219,'话语权和上升空间',9,1,0),
(219,'被认可和人际关系',10,1,1),
(219,'稳定和被需要',11,1,2),
(219,'专业成长和准确性',12,1,3);

-- 结果类型（4 型，含初级 + 高级双档解析）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(2,'D','支配型','目标在手，其余皆可让路','目标在手，其余皆可让路','','{"strengths": ["推进力极强", "危机中敢决策", "敢于承担责任"], "weaknesses": ["显得强势", "耐心偏低", "容易忽略他人感受"], "careers": ["团队管理", "业务拓展", "创业", "项目攻坚"]}','{"one_liner": "目标在手，其余皆可让路", "traits": ["结果导向", "果断，不拖泥带水", "天然想主导", "抗压能力强"], "strengths": ["推进力极强", "危机中敢决策", "敢于承担责任"], "weaknesses": ["显得强势", "耐心偏低", "容易忽略他人感受"], "tip": "发指令前补一句为什么要做，团队配合度立刻不一样"}','{"chapters": [{"title": "深度画像", "content": "你对结果有近乎本能的渴望，喜欢掌控节奏，遇到阻碍第一反应是绕过去而不是等待。"}, {"title": "思维与决策", "content": "决策快，以目标为唯一准绳，情绪和过程细节常被排在后面。"}, {"title": "职场与做事", "content": "在开拓、攻坚、需要拍板的场景里最强；流程和文书工作会消耗你。"}, {"title": "关系与情感", "content": "直接且忠诚，但容易把关系也当任务推进，需要练习先听后说。"}, {"title": "压力与成长", "content": "压力下更具压迫感甚至专断。成长是学会授权，并解释自己的动机。"}], "career": ["团队管理", "业务拓展", "创业", "项目攻坚"], "famous": "会议里第一个问什么时候交付的人"}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(2,'I','影响型','把人聚起来，事情就成了一半','把人聚起来，事情就成了一半','','{"strengths": ["感染他人", "破冰和连接", "现场活跃气氛"], "weaknesses": ["细节把控弱", "容易分心", "过于在意评价"], "careers": ["市场营销", "品牌公关", "培训讲师", "活动策划"]}','{"one_liner": "把人聚起来，事情就成了一半", "traits": ["外向热情", "善于表达", "乐观", "渴望被认可"], "strengths": ["感染他人", "破冰和连接", "现场活跃气氛"], "weaknesses": ["细节把控弱", "容易分心", "过于在意评价"], "tip": "把承诺写进清单，热情才不会变成烂尾"}','{"chapters": [{"title": "深度画像", "content": "你从人际互动中获取能量，擅长让气氛变好、让人愿意参与，也享受被关注。"}, {"title": "思维与决策", "content": "凭直觉和感受决策，重大家怎么看，对枯燥数据耐心有限。"}, {"title": "职场与做事", "content": "适合对外、创意、需要影响力的岗位；长期独立填表类会让你枯萎。"}, {"title": "关系与情感", "content": "慷慨有趣，是很好的陪伴者，但面对沉重情绪容易转移话题。"}, {"title": "压力与成长", "content": "压力下冲动或过度表达。成长是建立清单和复盘习惯。"}], "career": ["市场营销", "品牌公关", "培训讲师", "活动策划"], "famous": "群里永远在暖场、也最能张罗的人"}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(2,'S','稳健型','慢一点没关系，稳稳走到就行','慢一点没关系，稳稳走到就行','','{"strengths": ["稳定执行", "善于倾听", "能长期坚持"], "weaknesses": ["抗拒变化", "难以拒绝别人", "表达被动"], "careers": ["客户服务", "行政后勤", "护理健康", "技术支持"]}','{"one_liner": "慢一点没关系，稳稳走到就行", "traits": ["温和", "耐心", "可靠", "回避冲突"], "strengths": ["稳定执行", "善于倾听", "能长期坚持"], "weaknesses": ["抗拒变化", "难以拒绝别人", "表达被动"], "tip": "练习把需求说出口，别人没你那么会读空气"}','{"chapters": [{"title": "深度画像", "content": "你偏好可预期的节奏，是团队里最稳定的支撑，厌恶突发状况和当面冲突。"}, {"title": "思维与决策", "content": "谨慎，重经验与他人感受，决策慢，但一旦决定就不易动摇。"}, {"title": "职场与做事", "content": "适合需要耐心、细致、服务意识的岗位；频繁变动最伤你。"}, {"title": "关系与情感", "content": "忠诚体贴，但委屈会累积，需要学会提前、平静地表达。"}, {"title": "压力与成长", "content": "压力下退缩沉默。成长是给自己设表达底线，每周练一次拒绝。"}], "career": ["客户服务", "行政后勤", "护理健康", "技术支持"], "famous": "那个不抢话但永远靠得住的人"}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(2,'C','谨慎型','先把规则和数据弄清楚，再动手','先把规则和数据弄清楚，再动手','','{"strengths": ["分析准确", "流程规范", "质量把控"], "weaknesses": ["过度纠结细节", "决策偏慢", "容易显得苛刻"], "careers": ["财务审计", "数据分析", "质量管理", "研发工程"]}','{"one_liner": "先把规则和数据弄清楚，再动手", "traits": ["严谨", "重逻辑", "追求准确", "低调"], "strengths": ["分析准确", "流程规范", "质量把控"], "weaknesses": ["过度纠结细节", "决策偏慢", "容易显得苛刻"], "tip": "给任务设一个足够好的标准，完美主义也是拖延的一种"}','{"chapters": [{"title": "深度画像", "content": "你相信凡事都有标准，对含糊和错误容忍度极低，习惯用事实和数据说话。"}, {"title": "思维与决策", "content": "重证据与逻辑，决策前会充分验证，厌恶拍脑袋。"}, {"title": "职场与做事", "content": "适合专业、分析、质量类岗位；混乱和拍脑袋决策让你痛苦。"}, {"title": "关系与情感", "content": "认真可靠，但容易用挑错来表达关心，需要练习先肯定再补充。"}, {"title": "压力与成长", "content": "压力下更较真、更退缩。成长是接受完成优于完美。"}], "career": ["财务审计", "数据分析", "质量管理", "研发工程"], "famous": "能一眼看出报表里错了一位的人"}',4);
