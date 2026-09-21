-- =============================================================================
-- 探我趣测 · 霍兰德职业兴趣测试（全套数据）
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 算分模型：scoring_model = TOP3 —— 累加取前三拼码。
--   结果不是预存的单行，而是按得分取前三的类型码拼成三字母（如 RIA/SEC）；
--   本文件 quiz_result 仍按 6 个类型维度各存一行（含双档解析），
--   后端取前三维后，把对应三行的报告组合返回即可。
-- 题型：李克特五点量表，30 道陈述题，
--       选项 非常不同意(1 分) → 非常同意(5 分)，全部指向同一个类型维度。
-- 用法：mysql ... < docs/seed-holland.sql（开头清 quiz_id=4 再重插，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 4);
DELETE FROM `question`        WHERE `quiz_id` = 4;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 4;
DELETE FROM `dimension`       WHERE `quiz_id` = 4;
DELETE FROM `quiz`            WHERE `id`      = 4;

-- 测评本体（scoring_model = TOP3）
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`emoji`,`tag`,`sort_order`,`question_count`,`price_coin`,`scoring_model`,`status`) VALUES
(4,'holland','霍兰德职业兴趣测试','测测你天生适合什么工作','霍兰德把职业兴趣分成现实、研究、艺术、社会、企业、常规六种，绝大多数人不是单一类型，而是以某几个为主。结果取你最靠前的三个类型拼成代码（如 RIA、SEC），它描述的是你和环境相处的方式，帮你少走几年弯路，而不是限定你只能做什么。','🧭','职业',4,0,0,'TOP3',1);

-- 类型维度（MAX/TOP3 模型下 dimension 一行 = 一个结果类型，pair_code 统一 TYPE）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(22,4,'R','现实型','TYPE',1),
(23,4,'I','研究型','TYPE',2),
(24,4,'A','艺术型','TYPE',3),
(25,4,'S','社会型','TYPE',4),
(26,4,'E','企业型','TYPE',5),
(27,4,'C','常规型','TYPE',6);

-- 题目（30 道，李克特五点量表）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (400,4,'我更喜欢动手操作、摆弄具体的东西而不是空想',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(400,'非常不同意',22,1,0),
(400,'不太同意',22,2,1),
(400,'一般',22,3,2),
(400,'比较同意',22,4,3),
(400,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (401,4,'摆弄工具、器械、设备让我觉得踏实',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(401,'非常不同意',22,1,0),
(401,'不太同意',22,2,1),
(401,'一般',22,3,2),
(401,'比较同意',22,4,3),
(401,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (402,4,'比起开会讨论，我更愿意去现场把事做出来',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(402,'非常不同意',22,1,0),
(402,'不太同意',22,2,1),
(402,'一般',22,3,2),
(402,'比较同意',22,4,3),
(402,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (403,4,'修理、组装、运动这类需要手巧的事我做着顺手',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(403,'非常不同意',22,1,0),
(403,'不太同意',22,2,1),
(403,'一般',22,3,2),
(403,'比较同意',22,4,3),
(403,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (404,4,'看得见摸得着的结果让我更有安全感',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(404,'非常不同意',22,1,0),
(404,'不太同意',22,2,1),
(404,'一般',22,3,2),
(404,'比较同意',22,4,3),
(404,'非常同意',22,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (405,4,'遇到不懂的现象，我会想搞清楚背后的原理',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(405,'非常不同意',23,1,0),
(405,'不太同意',23,2,1),
(405,'一般',23,3,2),
(405,'比较同意',23,4,3),
(405,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (406,4,'我喜欢独立钻研、自己找答案',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(406,'非常不同意',23,1,0),
(406,'不太同意',23,2,1),
(406,'一般',23,3,2),
(406,'比较同意',23,4,3),
(406,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (407,4,'抽象问题和逻辑推导对我很有吸引力',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(407,'非常不同意',23,1,0),
(407,'不太同意',23,2,1),
(407,'一般',23,3,2),
(407,'比较同意',23,4,3),
(407,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (408,4,'比起热闹社交，我更愿意待在实验室或书堆里',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(408,'非常不同意',23,1,0),
(408,'不太同意',23,2,1),
(408,'一般',23,3,2),
(408,'比较同意',23,4,3),
(408,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (409,4,'做决定前我希望数据或证据先说话',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(409,'非常不同意',23,1,0),
(409,'不太同意',23,2,1),
(409,'一般',23,3,2),
(409,'比较同意',23,4,3),
(409,'非常同意',23,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (410,4,'表达自我、创造独特的东西让我有成就感',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(410,'非常不同意',24,1,0),
(410,'不太同意',24,2,1),
(410,'一般',24,3,2),
(410,'比较同意',24,4,3),
(410,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (411,4,'我对美、氛围、情绪的感知很敏感',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(411,'非常不同意',24,1,0),
(411,'不太同意',24,2,1),
(411,'一般',24,3,2),
(411,'比较同意',24,4,3),
(411,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (412,4,'我不喜欢被固定流程和条条框框束缚',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(412,'非常不同意',24,1,0),
(412,'不太同意',24,2,1),
(412,'一般',24,3,2),
(412,'比较同意',24,4,3),
(412,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (413,4,'写东西、画画、做音乐这类事能让我沉浸',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(413,'非常不同意',24,1,0),
(413,'不太同意',24,2,1),
(413,'一般',24,3,2),
(413,'比较同意',24,4,3),
(413,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (414,4,'我常被有创意、不按常理出牌的人吸引',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(414,'非常不同意',24,1,0),
(414,'不太同意',24,2,1),
(414,'一般',24,3,2),
(414,'比较同意',24,4,3),
(414,'非常同意',24,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (415,4,'和人打交道、帮别人解决问题让我有动力',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(415,'非常不同意',25,1,0),
(415,'不太同意',25,2,1),
(415,'一般',25,3,2),
(415,'比较同意',25,4,3),
(415,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (416,4,'我擅长察觉别人的情绪并给予支持',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(416,'非常不同意',25,1,0),
(416,'不太同意',25,2,1),
(416,'一般',25,3,2),
(416,'比较同意',25,4,3),
(416,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (417,4,'比起独自钻研，我更喜欢团队和协作',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(417,'非常不同意',25,1,0),
(417,'不太同意',25,2,1),
(417,'一般',25,3,2),
(417,'比较同意',25,4,3),
(417,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (418,4,'教书、咨询、照护这类与人相关的事我做得来',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(418,'非常不同意',25,1,0),
(418,'不太同意',25,2,1),
(418,'一般',25,3,2),
(418,'比较同意',25,4,3),
(418,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (419,4,'被人信任、当成依靠让我有价值感',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(419,'非常不同意',25,1,0),
(419,'不太同意',25,2,1),
(419,'一般',25,3,2),
(419,'比较同意',25,4,3),
(419,'非常同意',25,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (420,4,'我乐于说服别人、推动事情往前走',21,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(420,'非常不同意',26,1,0),
(420,'不太同意',26,2,1),
(420,'一般',26,3,2),
(420,'比较同意',26,4,3),
(420,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (421,4,'我喜欢有目标、有竞争、能看到成果的事',22,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(421,'非常不同意',26,1,0),
(421,'不太同意',26,2,1),
(421,'一般',26,3,2),
(421,'比较同意',26,4,3),
(421,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (422,4,'带动一群人去实现一个想法让我兴奋',23,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(422,'非常不同意',26,1,0),
(422,'不太同意',26,2,1),
(422,'一般',26,3,2),
(422,'比较同意',26,4,3),
(422,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (423,4,'我不太怕承担风险和责任',24,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(423,'非常不同意',26,1,0),
(423,'不太同意',26,2,1),
(423,'一般',26,3,2),
(423,'比较同意',26,4,3),
(423,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (424,4,'我享受在众人面前表达、用影响力换反馈',25,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(424,'非常不同意',26,1,0),
(424,'不太同意',26,2,1),
(424,'一般',26,3,2),
(424,'比较同意',26,4,3),
(424,'非常同意',26,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (425,4,'按流程、规则、清单有条理地做事让我安心',26,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(425,'非常不同意',27,1,0),
(425,'不太同意',27,2,1),
(425,'一般',27,3,2),
(425,'比较同意',27,4,3),
(425,'非常同意',27,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (426,4,'我对数字、记录、细节的准确很在意',27,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(426,'非常不同意',27,1,0),
(426,'不太同意',27,2,1),
(426,'一般',27,3,2),
(426,'比较同意',27,4,3),
(426,'非常同意',27,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (427,4,'稳定的节奏和结构化的环境最舒服',28,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(427,'非常不同意',27,1,0),
(427,'不太同意',27,2,1),
(427,'一般',27,3,2),
(427,'比较同意',27,4,3),
(427,'非常同意',27,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (428,4,'我不喜欢混乱和随时变动',29,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(428,'非常不同意',27,1,0),
(428,'不太同意',27,2,1),
(428,'一般',27,3,2),
(428,'比较同意',27,4,3),
(428,'非常同意',27,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (429,4,'把繁杂的事务整理得井井有条让我有成就感',30,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(429,'非常不同意',27,1,0),
(429,'不太同意',27,2,1),
(429,'一般',27,3,2),
(429,'比较同意',27,4,3),
(429,'非常同意',27,5,4);

-- 结果类型（含初级 + 高级双档解析）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'R','现实型','动手比空谈更让我踏实','动手比空谈更让我踏实','','{"strengths": ["能落地执行", "不怕脏累和重复", "空间与机械感好"], "weaknesses": ["不太喜欢抽象讨论", "对人际政治耐心低", "文字表达偏弱"], "careers": ["工程技术", "机械维修", "农林园艺", "建筑施工"]}','{"one_liner": "动手比空谈更让我踏实", "traits": ["偏好具体操作", "务实，重视实际结果", "动手能力强", "喜欢可感知的成果"], "strengths": ["能落地执行", "不怕脏累和重复", "空间与机械感好"], "weaknesses": ["不太喜欢抽象讨论", "对人际政治耐心低", "文字表达偏弱"], "tip": "把大目标拆成可操作的步骤，你的价值在动手那一环最突出"}','{"chapters": [{"title": "深度画像", "content": "你是典型行动派，靠把东西实实在在做出来获得成就感，对空泛讨论天然无感。"}, {"title": "思维与决策", "content": "决策重可行和结果，倾向先试再想，对纸上谈兵容忍度低。"}, {"title": "职场与做事", "content": "适合需要实操、技术、现场的工作；纯文案和人际周旋会消耗你。"}, {"title": "关系与情感", "content": "实在、不绕弯，但容易被误会为不够浪漫或细腻。"}, {"title": "压力与成长", "content": "压力下更固执或逃避沟通。成长是补一点表达，让成果被看见。"}], "career": ["工程技术", "机械维修", "农林园艺", "建筑施工"], "famous": "东西坏了第一个动手修的人"}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'I','研究型','先弄懂原理，再决定怎么动','先弄懂原理，再决定怎么动','','{"strengths": ["深度思考", "客观理性", "能啃复杂问题"], "weaknesses": ["容易过度分析", "推动落地偏弱", "不擅长推销自己"], "careers": ["科研", "数据分析", "算法工程", "医药研发"]}','{"one_liner": "先弄懂原理，再决定怎么动", "traits": ["求知欲强", "偏好独立钻研", "重证据和逻辑", "不爱社交消耗"], "strengths": ["深度思考", "客观理性", "能啃复杂问题"], "weaknesses": ["容易过度分析", "推动落地偏弱", "不擅长推销自己"], "tip": "给研究设一个交付节点，先出一版再迭代，别等想透才动手"}','{"chapters": [{"title": "深度画像", "content": "你靠理解世界获得安全感，习惯先搞清原理再行动，对未知领域会自己查到底。"}, {"title": "思维与决策", "content": "决策前大量收集信息，重逻辑轻情绪，对拍脑袋反感。"}, {"title": "职场与做事", "content": "适合研究、分析、技术类岗位；频繁会议和强社交是主要消耗。"}, {"title": "关系与情感", "content": "忠诚但不黏人，表达克制，亲密关系需要你主动分享。"}, {"title": "压力与成长", "content": "压力下更封闭。成长是允许自己在没准备好时也参与。"}], "career": ["科研", "数据分析", "算法工程", "医药研发"], "famous": "不怎么出现、一开口信息量最大的人"}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'A','艺术型','不表达、不创造，我就空了','不表达、不创造，我就空了','','{"strengths": ["创造力和想象力", "能打动人", "对美敏感"], "weaknesses": ["不喜欢条框和重复", "情绪起伏大", "落地容易虎头蛇尾"], "careers": ["设计", "内容创作", "音乐艺术", "广告创意"]}','{"one_liner": "不表达、不创造，我就空了", "traits": ["审美和情绪感知强", "追求独特", "讨厌被框死", "表达欲强"], "strengths": ["创造力和想象力", "能打动人", "对美敏感"], "weaknesses": ["不喜欢条框和重复", "情绪起伏大", "落地容易虎头蛇尾"], "tip": "给灵感配一个最小交付节奏，创作也需要一点点纪律"}','{"chapters": [{"title": "深度画像", "content": "你对真实和独特有强需求，靠表达和创造确认自己的存在，反感千篇一律。"}, {"title": "思维与决策", "content": "决策重感受和美感，宁可绕路也要保住表达空间。"}, {"title": "职场与做事", "content": "适合有创作、审美、表达空间的工作；机械重复会让你枯萎。"}, {"title": "关系与情感", "content": "投入深，也容易被误解为情绪化。直接表达需求比等对方猜更有效。"}, {"title": "压力与成长", "content": "压力下更情绪化或自我怀疑。成长是把感受落成作品。"}], "career": ["设计", "内容创作", "音乐艺术", "广告创意"], "famous": "朋友圈审美最在线、文案最有个人味的人"}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'S','社会型','帮到人，我才觉得值','帮到人，我才觉得值','','{"strengths": ["共情和照顾", "沟通和协调", "让人安心"], "weaknesses": ["边界感弱", "容易透支", "回避冲突"], "careers": ["教师", "心理咨询", "医护", "社工"]}','{"one_liner": "帮到人，我才觉得值", "traits": ["善解人意", "偏好协作", "重视关系", "愿意付出"], "strengths": ["共情和照顾", "沟通和协调", "让人安心"], "weaknesses": ["边界感弱", "容易透支", "回避冲突"], "tip": "每周留一段只给自己的时间，照顾别人之前先稳住自己"}','{"chapters": [{"title": "深度画像", "content": "你从人与人的连接里获得意义，习惯通过支持他人来建立价值，被需要时最踏实。"}, {"title": "思维与决策", "content": "决策常围绕人的感受，容易为了关系牺牲自己的真实想法。"}, {"title": "职场与做事", "content": "适合教育、咨询、照护、协作类工作；纯竞争环境会消耗你。"}, {"title": "关系与情感", "content": "付出型，容易吸引索取型。需要学会筛选而非拯救。"}, {"title": "压力与成长", "content": "压力下更讨好。成长是直接说出我也需要。"}], "career": ["教师", "心理咨询", "医护", "社工"], "famous": "谁有麻烦第一个想到的那个人"}',4);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'E','企业型','把想法推成现实，比什么都带劲','把想法推成现实，比什么都带劲','','{"strengths": ["推动和执行", "说服与动员", "抗压"], "weaknesses": ["强势", "耐心低", "容易忽略细节"], "careers": ["销售管理", "创业", "项目管理", "商务"]}','{"one_liner": "把想法推成现实，比什么都带劲", "traits": ["目标导向", "爱影响人", "敢担责", "不怕竞争"], "strengths": ["推动和执行", "说服与动员", "抗压"], "weaknesses": ["强势", "耐心低", "容易忽略细节"], "tip": "在要求别人前先说清为什么，配合度会高一截"}','{"chapters": [{"title": "深度画像", "content": "你天然想主导和推动，靠把目标变成结果获得能量，对停滞不耐烦。"}, {"title": "思维与决策", "content": "决策快、重结果，能迅速调配资源，对情绪成本耐心有限。"}, {"title": "职场与做事", "content": "适合管理、销售、创业、需要影响力的岗位；被微观管控会窒息。"}, {"title": "关系与情感", "content": "直接忠诚，但容易把关系当项目推进，需要练习先听后说。"}, {"title": "压力与成长", "content": "压力下更具压迫感。成长是学会授权和解释动机。"}], "career": ["销售管理", "创业", "项目管理", "商务"], "famous": "发一句话就能把分工排完的人"}',5);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(4,'C','常规型','有条理，我心里才不慌','有条理，我心里才不慌','','{"strengths": ["可靠", "细节把控", "流程化能力"], "weaknesses": ["抗拒变化", "灵活性不足", "显得刻板"], "careers": ["财务", "行政", "质检", "数据录入"]}','{"one_liner": "有条理，我心里才不慌", "traits": ["重视规则和流程", "细心", "追求准确", "偏好稳定"], "strengths": ["可靠", "细节把控", "流程化能力"], "weaknesses": ["抗拒变化", "灵活性不足", "显得刻板"], "tip": "允许计划有 10% 的临时调整区，你会轻松很多"}','{"chapters": [{"title": "深度画像", "content": "你靠秩序和确定性获得安全感，相信把每一步做对结果就不会错。"}, {"title": "思维与决策", "content": "依规则、流程、历史经验决策，对未经验证的新方法保持怀疑。"}, {"title": "职场与做事", "content": "适合财务、行政、运营、质量类需要精确的工作；混乱让你不适。"}, {"title": "关系与情感", "content": "踏实可靠，表达偏笨拙，常用把事做好代替说爱。"}, {"title": "压力与成长", "content": "压力下更固执。成长是接受没有完美流程。"}], "career": ["财务", "行政", "质检", "数据录入"], "famous": "交给他的事你从不催第二遍的人"}',6);
