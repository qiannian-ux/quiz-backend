-- =============================================================================
-- 探我趣测 · 九型人格测评（全套数据）
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 算分模型：scoring_model = MAX —— 九个类型维度各自累加，取总分最高的那个。
-- 题型：李克特五点量表，36 道陈述题（每型 4 题），
--       选项 非常不同意(1 分) → 非常同意(5 分)，全部指向同一个类型维度。
--       （question_option 做成独立表就是为了兼容这种量表，而不只是二选一）
-- 用法：mysql ... < docs/seed-enneagram.sql（开头清 quiz_id=3 再重插，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 3);
DELETE FROM `question`        WHERE `quiz_id` = 3;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 3;
DELETE FROM `dimension`       WHERE `quiz_id` = 3;
DELETE FROM `quiz`            WHERE `id`      = 3;

-- 测评本体（scoring_model = MAX：累加取最高分类型）
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`emoji`,`tag`,`sort_order`,`question_count`,`price_coin`,`scoring_model`,`status`) VALUES
(3,'enneagram','九型人格测试','看清你行为背后的真实动机','MBTI 描述你怎么思考，九型追问你为什么这么做。它把人分成九种核心动机，并指出每种类型在压力和安全状态下的变化方向——这也是为什么同一个人在不同阶段会显得判若两人。','🔮','性格',3,0,0,'MAX',1);

-- 类型维度（9 个，MAX 模型下 dimension 一行 = 一个结果类型，pair_code 统一 TYPE）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(13,3,'1','完美型','TYPE',1),
(14,3,'2','助人型','TYPE',2),
(15,3,'3','成就型','TYPE',3),
(16,3,'4','浪漫型','TYPE',4),
(17,3,'5','观察型','TYPE',5),
(18,3,'6','忠诚型','TYPE',6),
(19,3,'7','享乐型','TYPE',7),
(20,3,'8','领袖型','TYPE',8),
(21,3,'9','和平型','TYPE',9);

-- 题目（36 道，李克特五点量表）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (300,3,'看到事情做得不标准，我会忍不住想纠正',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(300,'非常不同意',13,1,0),
(300,'不太同意',13,2,1),
(300,'一般',13,3,2),
(300,'比较同意',13,4,3),
(300,'非常同意',13,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (301,3,'我很难容忍自己和别人敷衍了事',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(301,'非常不同意',13,1,0),
(301,'不太同意',13,2,1),
(301,'一般',13,3,2),
(301,'比较同意',13,4,3),
(301,'非常同意',13,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (302,3,'做决定前我会反复检查有没有遗漏',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(302,'非常不同意',13,1,0),
(302,'不太同意',13,2,1),
(302,'一般',13,3,2),
(302,'比较同意',13,4,3),
(302,'非常同意',13,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (303,3,'别人说我太较真，但我觉得那是对事不对人',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(303,'非常不同意',13,1,0),
(303,'不太同意',13,2,1),
(303,'一般',13,3,2),
(303,'比较同意',13,4,3),
(303,'非常同意',13,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (304,3,'察觉到别人需要帮忙，我会主动凑上去',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(304,'非常不同意',14,1,0),
(304,'不太同意',14,2,1),
(304,'一般',14,3,2),
(304,'比较同意',14,4,3),
(304,'非常同意',14,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (305,3,'我很容易把别人的事排在自己前面',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(305,'非常不同意',14,1,0),
(305,'不太同意',14,2,1),
(305,'一般',14,3,2),
(305,'比较同意',14,4,3),
(305,'非常同意',14,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (306,3,'被需要的时候，我才觉得自己有价值',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(306,'非常不同意',14,1,0),
(306,'不太同意',14,2,1),
(306,'一般',14,3,2),
(306,'比较同意',14,4,3),
(306,'非常同意',14,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (307,3,'付出后如果没得到回应，我会有点失落',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(307,'非常不同意',14,1,0),
(307,'不太同意',14,2,1),
(307,'一般',14,3,2),
(307,'比较同意',14,4,3),
(307,'非常同意',14,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (308,3,'我习惯先把目标定下来，再倒推怎么做',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(308,'非常不同意',15,1,0),
(308,'不太同意',15,2,1),
(308,'一般',15,3,2),
(308,'比较同意',15,4,3),
(308,'非常同意',15,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (309,3,'效率低、没进展会让我烦躁',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(309,'非常不同意',15,1,0),
(309,'不太同意',15,2,1),
(309,'一般',15,3,2),
(309,'比较同意',15,4,3),
(309,'非常同意',15,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (310,3,'我很在意别人眼里我是不是成功',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(310,'非常不同意',15,1,0),
(310,'不太同意',15,2,1),
(310,'一般',15,3,2),
(310,'比较同意',15,4,3),
(310,'非常同意',15,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (311,3,'为了推进事情，我可以暂时放下情绪',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(311,'非常不同意',15,1,0),
(311,'不太同意',15,2,1),
(311,'一般',15,3,2),
(311,'比较同意',15,4,3),
(311,'非常同意',15,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (312,3,'我常觉得自己和别人有种说不清的不同',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(312,'非常不同意',16,1,0),
(312,'不太同意',16,2,1),
(312,'一般',16,3,2),
(312,'比较同意',16,4,3),
(312,'非常同意',16,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (313,3,'情绪起伏是我理解自己和创作的来源',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(313,'非常不同意',16,1,0),
(313,'不太同意',16,2,1),
(313,'一般',16,3,2),
(313,'比较同意',16,4,3),
(313,'非常同意',16,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (314,3,'平淡的日子会让我觉得缺了点什么',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(314,'非常不同意',16,1,0),
(314,'不太同意',16,2,1),
(314,'一般',16,3,2),
(314,'比较同意',16,4,3),
(314,'非常同意',16,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (315,3,'我很在意什么东西是真正属于我的风格',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(315,'非常不同意',16,1,0),
(315,'不太同意',16,2,1),
(315,'一般',16,3,2),
(315,'比较同意',16,4,3),
(315,'非常同意',16,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (316,3,'遇到不懂的事，我会先自己查清楚再问人',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(316,'非常不同意',17,1,0),
(316,'不太同意',17,2,1),
(316,'一般',17,3,2),
(316,'比较同意',17,4,3),
(316,'非常同意',17,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (317,3,'我需要大量独处时间来恢复和思考',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(317,'非常不同意',17,1,0),
(317,'不太同意',17,2,1),
(317,'一般',17,3,2),
(317,'比较同意',17,4,3),
(317,'非常同意',17,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (318,3,'比起参与，我更愿意先旁观把结构看明白',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(318,'非常不同意',17,1,0),
(318,'不太同意',17,2,1),
(318,'一般',17,3,2),
(318,'比较同意',17,4,3),
(318,'非常同意',17,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (319,3,'被人过度打扰会让我很不舒服',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(319,'非常不同意',17,1,0),
(319,'不太同意',17,2,1),
(319,'一般',17,3,2),
(319,'比较同意',17,4,3),
(319,'非常同意',17,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (320,3,'做重要决定前我会把最坏情况想一遍',21,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(320,'非常不同意',18,1,0),
(320,'不太同意',18,2,1),
(320,'一般',18,3,2),
(320,'比较同意',18,4,3),
(320,'非常同意',18,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (321,3,'我倾向于找可靠的人或规矩来依靠',22,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(321,'非常不同意',18,1,0),
(321,'不太同意',18,2,1),
(321,'一般',18,3,2),
(321,'比较同意',18,4,3),
(321,'非常同意',18,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (322,3,'环境突然变化时我会很不安',23,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(322,'非常不同意',18,1,0),
(322,'不太同意',18,2,1),
(322,'一般',18,3,2),
(322,'比较同意',18,4,3),
(322,'非常同意',18,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (323,3,'我容易怀疑，但一旦信任就会很忠诚',24,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(323,'非常不同意',18,1,0),
(323,'不太同意',18,2,1),
(323,'一般',18,3,2),
(323,'比较同意',18,4,3),
(323,'非常同意',18,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (324,3,'我脑子里同时装着好几个想做的事',25,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(324,'非常不同意',19,1,0),
(324,'不太同意',19,2,1),
(324,'一般',19,3,2),
(324,'比较同意',19,4,3),
(324,'非常同意',19,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (325,3,'无聊和受限是我最难受的状态',26,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(325,'非常不同意',19,1,0),
(325,'不太同意',19,2,1),
(325,'一般',19,3,2),
(325,'比较同意',19,4,3),
(325,'非常同意',19,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (326,3,'遇到不愉快，我倾向于换个事情转移注意力',27,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(326,'非常不同意',19,1,0),
(326,'不太同意',19,2,1),
(326,'一般',19,3,2),
(326,'比较同意',19,4,3),
(326,'非常同意',19,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (327,3,'我喜欢把计划留有余地，随时可以改',28,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(327,'非常不同意',19,1,0),
(327,'不太同意',19,2,1),
(327,'一般',19,3,2),
(327,'比较同意',19,4,3),
(327,'非常同意',19,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (328,3,'遇到不公或被压制，我会直接顶回去',29,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(328,'非常不同意',20,1,0),
(328,'不太同意',20,2,1),
(328,'一般',20,3,2),
(328,'比较同意',20,4,3),
(328,'非常同意',20,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (329,3,'我习惯掌控局面，不喜欢被人牵着走',30,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(329,'非常不同意',20,1,0),
(329,'不太同意',20,2,1),
(329,'一般',20,3,2),
(329,'比较同意',20,4,3),
(329,'非常同意',20,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (330,3,'保护自己在乎的人是我的本能',31,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(330,'非常不同意',20,1,0),
(330,'不太同意',20,2,1),
(330,'一般',20,3,2),
(330,'比较同意',20,4,3),
(330,'非常同意',20,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (331,3,'软弱和犹豫会让我不耐烦',32,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(331,'非常不同意',20,1,0),
(331,'不太同意',20,2,1),
(331,'一般',20,3,2),
(331,'比较同意',20,4,3),
(331,'非常同意',20,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (332,3,'我尽量避免冲突，能顺就顺',33,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(332,'非常不同意',21,1,0),
(332,'不太同意',21,2,1),
(332,'一般',21,3,2),
(332,'比较同意',21,4,3),
(332,'非常同意',21,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (333,3,'别人争起来时我常当和事佬',34,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(333,'非常不同意',21,1,0),
(333,'不太同意',21,2,1),
(333,'一般',21,3,2),
(333,'比较同意',21,4,3),
(333,'非常同意',21,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (334,3,'我容易顺着别人的意见，忽略自己真正想要什么',35,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(334,'非常不同意',21,1,0),
(334,'不太同意',21,2,1),
(334,'一般',21,3,2),
(334,'比较同意',21,4,3),
(334,'非常同意',21,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (335,3,'稳定和舒服的节奏对我来说很重要',36,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(335,'非常不同意',21,1,0),
(335,'不太同意',21,2,1),
(335,'一般',21,3,2),
(335,'比较同意',21,4,3),
(335,'非常同意',21,5,4);

-- 结果类型（9 型，含初级 + 高级双档解析）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'1','完美型','心里有一把尺，量别人之前先量自己','心里有一把尺，量别人之前先量自己','','{"strengths": ["能把事做到位", "原则感强，可靠", "善于发现问题和改进点"], "weaknesses": ["容易挑剔和苛责", "完美主义拖慢进度", "情绪上容易积压不满"], "careers": ["质量管理", "财务审计", "法务合规", "工程技术"]}','{"one_liner": "心里有一把尺，量别人之前先量自己", "traits": ["标准高，眼里揉不进沙子", "责任感强，答应的事一定做到", "习惯自我批评", "对「对不对」比对「开不开心」更敏感"], "strengths": ["能把事做到位", "原则感强，可靠", "善于发现问题和改进点"], "weaknesses": ["容易挑剔和苛责", "完美主义拖慢进度", "情绪上容易积压不满"], "tip": "试着把「必须做对」换成「先做完再改」，你的标准已经够高了"}','{"chapters": [{"title": "深度画像", "content": "你内心有一套清晰的是非标准，相信按标准做事才安心，对自己的要求往往比对别人更严。"}, {"title": "思维与决策", "content": "决策前反复权衡对错，倾向选择更正确的选项，而不是更舒服的那个。"}, {"title": "职场与做事", "content": "适合需要严谨、规范和质量的岗位；混乱和敷衍会让你极度不适。"}, {"title": "关系与情感", "content": "爱之深责之切，关心常以指出问题的形式出现，容易让对方觉得被挑剔。"}, {"title": "压力与成长", "content": "压力下更苛责、更紧绷。成长是允许「够好」存在，也允许自己不完美。"}], "career": ["质量管理", "财务审计", "法务合规", "工程技术"], "famous": "团队里把方案挑到最后一版的人"}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'2','助人型','把别人照顾好，是我表达在乎的方式','把别人照顾好，是我表达在乎的方式','','{"strengths": ["共情和照顾人", "擅长维护关系", "愿意付出"], "weaknesses": ["边界感弱，容易透支", "付出后期待回报", "难以表达自己的需求"], "careers": ["客户服务", "人力资源", "护理健康", "社群运营"]}','{"one_liner": "把别人照顾好，是我表达在乎的方式", "traits": ["敏感，能迅速察觉别人的需要", "习惯主动帮忙", "渴望被需要", "很难拒绝人"], "strengths": ["共情和照顾人", "擅长维护关系", "愿意付出"], "weaknesses": ["边界感弱，容易透支", "付出后期待回报", "难以表达自己的需求"], "tip": "每周留一段只给自己的时间，那不是自私，是续航"}','{"chapters": [{"title": "深度画像", "content": "你对他人的情绪极其敏感，习惯通过帮忙来建立连接，被需要时最有存在感。"}, {"title": "思维与决策", "content": "决策常围绕对方会怎么想，容易为了关系牺牲自己的真实想法。"}, {"title": "职场与做事", "content": "适合服务、协调、支持类工作；纯竞争和冷冰冰的环境会消耗你。"}, {"title": "关系与情感", "content": "付出型，容易吸引索取型的人。需要学会筛选，而不是拯救。"}, {"title": "压力与成长", "content": "压力下更讨好、更委屈。成长是学会直接说出我也需要。"}], "career": ["客户服务", "人力资源", "护理健康", "社群运营"], "famous": "谁有麻烦第一个想到的那个人"}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'3','成就型','目标感拉满，停下来反而会慌','目标感拉满，停下来反而会慌','','{"strengths": ["执行力强", "能快速调整策略", "抗压，能打硬仗"], "weaknesses": ["容易把自我价值等同于成绩", "忽略情绪和关系", "为了效率牺牲深度"], "careers": ["销售", "项目管理", "创业", "市场运营"]}','{"one_liner": "目标感拉满，停下来反而会慌", "traits": ["效率优先", "适应力强", "在意形象和成果", "不喜欢没有进展"], "strengths": ["执行力强", "能快速调整策略", "抗压，能打硬仗"], "weaknesses": ["容易把自我价值等同于成绩", "忽略情绪和关系", "为了效率牺牲深度"], "tip": "给自己设一段不产出也没关系的时间，人不是 KPI"}','{"chapters": [{"title": "深度画像", "content": "你习惯用成果定义自己，擅长把目标拆成动作并迅速推进，停下来会有空虚感。"}, {"title": "思维与决策", "content": "决策以效率和结果为导向，能快速切换方案，对情绪成本耐心有限。"}, {"title": "职场与做事", "content": "适合有明确目标、能看见回报的岗位；长期没有反馈的事会让你失去动力。"}, {"title": "关系与情感", "content": "可靠能干，但容易把关系也当项目经营，需要练习不带目的地陪伴。"}, {"title": "压力与成长", "content": "压力下更急躁、更工作狂。成长是允许自己不做也可以。"}], "career": ["销售", "项目管理", "创业", "市场运营"], "famous": "群里永远在报进度、也最怕掉队的人"}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'4','浪漫型','渴望被真正看见，也不想和谁一样','渴望被真正看见，也不想和谁一样','','{"strengths": ["感受力和创造力", "能表达别人说不出的东西", "对美和真诚敏感"], "weaknesses": ["容易陷入情绪反刍", "羡慕别人所拥有的", "平淡时会觉得缺失"], "careers": ["内容创作", "视觉设计", "心理咨询", "艺术相关"]}','{"one_liner": "渴望被真正看见，也不想和谁一样", "traits": ["情绪细腻", "审美和自我表达欲强", "容易觉得自己与他人不同", "追求真实"], "strengths": ["感受力和创造力", "能表达别人说不出的东西", "对美和真诚敏感"], "weaknesses": ["容易陷入情绪反刍", "羡慕别人所拥有的", "平淡时会觉得缺失"], "tip": "把「缺的那块」写下来具体化，它往往没那么不可得"}','{"chapters": [{"title": "深度画像", "content": "你对真实和独特有强需求，渴望被完整地看见，也常被一种少了点什么的感觉驱动。"}, {"title": "思维与决策", "content": "决策重感受和真实，宁可吃亏也不愿假，因此有时显得不够务实。"}, {"title": "职场与做事", "content": "适合有表达、创作、审美空间的工作；机械重复会让你迅速枯萎。"}, {"title": "关系与情感", "content": "投入深，也容易因对方不够懂你而失望。需要学会直接表达需求，而不是等对方猜。"}, {"title": "压力与成长", "content": "压力下更沉溺情绪。成长是把感受转成作品，而不是转成内耗。"}], "career": ["内容创作", "视觉设计", "心理咨询", "艺术相关"], "famous": "朋友圈文案最有个人味道的那个人"}',4);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'5','观察型','先把世界看明白，再决定要不要参与','先把世界看明白，再决定要不要参与','','{"strengths": ["深度思考和钻研", "客观理性", "能独立解决复杂问题"], "weaknesses": ["回避社交和求助", "过度准备而不行动", "显得疏离"], "careers": ["研发工程", "数据分析", "学术研究", "系统设计"]}','{"one_liner": "先把世界看明白，再决定要不要参与", "traits": ["求知欲强", "需要大量独处", "克制，不轻易暴露情绪", "重视独立"], "strengths": ["深度思考和钻研", "客观理性", "能独立解决复杂问题"], "weaknesses": ["回避社交和求助", "过度准备而不行动", "显得疏离"], "tip": "给研究设一个截止点，先做出一版，再迭代"}','{"chapters": [{"title": "深度画像", "content": "你靠理解世界获得安全感，习惯退后一步观察，把精力留给真正感兴趣的事。"}, {"title": "思维与决策", "content": "决策前充分收集信息，重逻辑轻情绪，对未知领域先学再动。"}, {"title": "职场与做事", "content": "适合研究、分析、技术类岗位；频繁会议和社交是主要消耗。"}, {"title": "关系与情感", "content": "忠诚但不黏人，情感表达偏克制。亲密关系需要你主动分享内心。"}, {"title": "压力与成长", "content": "压力下更退缩、更隔离。成长是允许自己在没完全准备好时也能参与。"}], "career": ["研发工程", "数据分析", "学术研究", "系统设计"], "famous": "不怎么出现、一开口信息量最大的人"}',5);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'6','忠诚型','先想清楚最坏情况，我才敢往前走','先想清楚最坏情况，我才敢往前走','','{"strengths": ["预判风险", "尽责可靠", "危机中稳定"], "weaknesses": ["过度担忧，迟迟不敢行动", "容易怀疑他人", "压力下摇摆"], "careers": ["风控合规", "运维支持", "质量管理", "行政后勤"]}','{"one_liner": "先想清楚最坏情况，我才敢往前走", "traits": ["风险意识强", "重视承诺和忠诚", "容易焦虑", "依赖可靠的人或规则"], "strengths": ["预判风险", "尽责可靠", "危机中稳定"], "weaknesses": ["过度担忧，迟迟不敢行动", "容易怀疑他人", "压力下摇摆"], "tip": "把担心写下来并标上概率，你会发现大多数都不会发生"}','{"chapters": [{"title": "深度画像", "content": "你对安全感和确定性需求很高，习惯先设想最坏情况并准备预案，忠诚一旦给出很难收回。"}, {"title": "思维与决策", "content": "决策谨慎，需要可信的依据或可依靠的人，对突变适应较慢。"}, {"title": "职场与做事", "content": "适合需要严谨、风险把控、执行到位的岗位；朝令夕改最伤你。"}, {"title": "关系与情感", "content": "忠诚体贴，但需要反复确认对方的态度。稳定回应比惊喜更能安抚你。"}, {"title": "压力与成长", "content": "压力下更焦虑或更依赖权威。成长是给担心设时限，然后行动。"}], "career": ["风控合规", "运维支持", "质量管理", "行政后勤"], "famous": "出发前一定要把预案做全的那个人"}',6);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'7','享乐型','把日子过得有意思，比什么都重要','把日子过得有意思，比什么都重要','','{"strengths": ["创意和联想", "带动气氛", "适应变化快"], "weaknesses": ["三分钟热度", "回避沉重话题", "承诺恐惧"], "careers": ["市场策划", "产品创新", "活动运营", "内容创意"]}','{"one_liner": "把日子过得有意思，比什么都重要", "traits": ["乐观，点子多", "讨厌受限和无聊", "兴趣广泛", "回避痛苦情绪"], "strengths": ["创意和联想", "带动气氛", "适应变化快"], "weaknesses": ["三分钟热度", "回避沉重话题", "承诺恐惧"], "tip": "允许自己无聊十分钟，很多情绪需要被看见而不是被绕开"}','{"chapters": [{"title": "深度画像", "content": "你追求新鲜和可能性，擅长把局面变得有趣，也习惯用下一个来消化不愉快。"}, {"title": "思维与决策", "content": "决策乐观且快速，倾向保留选项，对长期约束本能抗拒。"}, {"title": "职场与做事", "content": "适合创意、开拓、需要脑洞的岗位；流程化执行和长期填表会消耗你。"}, {"title": "关系与情感", "content": "有趣慷慨，但面对沉重情绪容易转移话题，需要练习留下来倾听。"}, {"title": "压力与成长", "content": "压力下更浮躁或更逃避。成长是选一件事坚持到看到结果。"}], "career": ["市场策划", "产品创新", "活动运营", "内容创意"], "famous": "永远在计划下一次旅行的人"}',7);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'8','领袖型','我的地盘我做主，谁也别想欺负我在乎的人','我的地盘我做主，谁也别想欺负我在乎的人','','{"strengths": ["敢拍板敢担责", "危机中冲在前面", "护短，讲义气"], "weaknesses": ["强势，容易压过别人", "耐心偏低", "不擅长示弱"], "careers": ["团队管理", "创业", "商务谈判", "项目攻坚"]}','{"one_liner": "我的地盘我做主，谁也别想欺负我在乎的人", "traits": ["直接果断", "掌控欲强", "保护欲强", "不怕冲突"], "strengths": ["敢拍板敢担责", "危机中冲在前面", "护短，讲义气"], "weaknesses": ["强势，容易压过别人", "耐心偏低", "不擅长示弱"], "tip": "在表达立场前先问一句对方的想法，你会发现阻力小很多"}','{"chapters": [{"title": "深度画像", "content": "你对控制权和公平极度敏感，习惯站在前面扛事，对软弱和欺压零容忍。"}, {"title": "思维与决策", "content": "决策快且果断，凭直觉和力量感推进，对冗长讨论缺乏耐心。"}, {"title": "职场与做事", "content": "适合攻坚、管理、需要拍板的场景；被微观管控会让你窒息。"}, {"title": "关系与情感", "content": "直接忠诚、护短，但容易用强硬掩盖脆弱。亲密关系里需要练习示弱。"}, {"title": "压力与成长", "content": "压力下更具攻击性。成长是学会授权，也给别人发挥的空间。"}], "career": ["团队管理", "创业", "商务谈判", "项目攻坚"], "famous": "有人受委屈时第一个站出来的那个人"}',8);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(3,'9','和平型','和和气气的，比争个对错重要','和和气气的，比争个对错重要','','{"strengths": ["包容，能调和矛盾", "稳定可靠", "善于倾听"], "weaknesses": ["难以表达自己的需求", "拖延，回避重要决定", "容易随波逐流"], "careers": ["行政后勤", "客服支持", "教务", "技术支持"]}','{"one_liner": "和和气气的，比争个对错重要", "traits": ["温和好相处", "回避冲突", "容易顺着别人", "追求安稳"], "strengths": ["包容，能调和矛盾", "稳定可靠", "善于倾听"], "weaknesses": ["难以表达自己的需求", "拖延，回避重要决定", "容易随波逐流"], "tip": "每天练习说一次自己的真实想法，哪怕只是选一顿饭"}','{"chapters": [{"title": "深度画像", "content": "你本能地维护和谐与平稳，习惯把别人的需求放在前面，也因此常忽略自己真正想要什么。"}, {"title": "思维与决策", "content": "决策偏保守，倾向维持现状，遇到冲突选择延后或回避。"}, {"title": "职场与做事", "content": "适合稳定、协作、服务类岗位；高频对抗和急剧变动会消耗你。"}, {"title": "关系与情感", "content": "包容体贴，但委屈会累积成被动抵抗。需要学会提前、平静地表达。"}, {"title": "压力与成长", "content": "压力下更拖延、更麻木。成长是意识到不选择本身也是一种选择。"}], "career": ["行政后勤", "客服支持", "教务", "技术支持"], "famous": "从不站队、但谁都愿意跟他聊的那个人"}',9);
