-- =============================================================================
-- 探我趣测 · 恋爱依恋类型测试（全套数据）
-- 由 tools/gen_reports.py 生成，请勿手改（改脚本后重跑）
-- -----------------------------------------------------------------------------
-- 算分模型：scoring_model = MAX —— 累加取最高分类型。
-- 题型：李克特五点量表，24 道陈述题，
--       选项 非常不同意(1 分) → 非常同意(5 分)，全部指向同一个类型维度。
-- 用法：mysql ... < docs/seed-attachment.sql（开头清 quiz_id=5 再重插，可重复执行）
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 5);
DELETE FROM `question`        WHERE `quiz_id` = 5;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 5;
DELETE FROM `dimension`       WHERE `quiz_id` = 5;
DELETE FROM `quiz`            WHERE `id`      = 5;

-- 测评本体（scoring_model = MAX）
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`emoji`,`tag`,`sort_order`,`question_count`,`price_coin`,`scoring_model`,`status`) VALUES
(5,'attachment','恋爱依恋类型测试','你为什么会这样爱一个人','依恋类型来自童年和主要照顾者的互动模式，成年后体现在亲密关系里：你是能安心靠近，还是总在担心被弃，又或者一靠近就想逃。它不是标签，而是你理解自己恋爱模式的起点——看清了，才有得选。','💞','情感',5,0,0,'MAX',1);

-- 类型维度（MAX/TOP3 模型下 dimension 一行 = 一个结果类型，pair_code 统一 TYPE）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(28,5,'secure','安全型','TYPE',1),
(29,5,'anxious','焦虑型','TYPE',2),
(30,5,'avoidant','回避型','TYPE',3),
(31,5,'fearful','恐惧型','TYPE',4);

-- 题目（24 道，李克特五点量表）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (500,5,'我在亲密关系里既能靠近，也能保有自己',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(500,'非常不同意',28,1,0),
(500,'不太同意',28,2,1),
(500,'一般',28,3,2),
(500,'比较同意',28,4,3),
(500,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (501,5,'对方需要空间时，我不会立刻觉得是被抛弃',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(501,'非常不同意',28,1,0),
(501,'不太同意',28,2,1),
(501,'一般',28,3,2),
(501,'比较同意',28,4,3),
(501,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (502,5,'有矛盾我倾向于直接沟通，而不是冷战或逃跑',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(502,'非常不同意',28,1,0),
(502,'不太同意',28,2,1),
(502,'一般',28,3,2),
(502,'比较同意',28,4,3),
(502,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (503,5,'我对关系的基本信任比较稳定',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(503,'非常不同意',28,1,0),
(503,'不太同意',28,2,1),
(503,'一般',28,3,2),
(503,'比较同意',28,4,3),
(503,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (504,5,'被爱和被需要我都能安稳接受',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(504,'非常不同意',28,1,0),
(504,'不太同意',28,2,1),
(504,'一般',28,3,2),
(504,'比较同意',28,4,3),
(504,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (505,5,'我不太担心对方会突然离开',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(505,'非常不同意',28,1,0),
(505,'不太同意',28,2,1),
(505,'一般',28,3,2),
(505,'比较同意',28,4,3),
(505,'非常同意',28,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (506,5,'对方回消息慢一点，我就会胡思乱想',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(506,'非常不同意',29,1,0),
(506,'不太同意',29,2,1),
(506,'一般',29,3,2),
(506,'比较同意',29,4,3),
(506,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (507,5,'我常需要反复确认对方还爱不爱我',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(507,'非常不同意',29,1,0),
(507,'不太同意',29,2,1),
(507,'一般',29,3,2),
(507,'比较同意',29,4,3),
(507,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (508,5,'亲密关系里我很容易患得患失',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(508,'非常不同意',29,1,0),
(508,'不太同意',29,2,1),
(508,'一般',29,3,2),
(508,'比较同意',29,4,3),
(508,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (509,5,'为了不分开，我有时会委屈自己迁就对方',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(509,'非常不同意',29,1,0),
(509,'不太同意',29,2,1),
(509,'一般',29,3,2),
(509,'比较同意',29,4,3),
(509,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (510,5,'独处时我会格外想念对方，甚至坐立不安',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(510,'非常不同意',29,1,0),
(510,'不太同意',29,2,1),
(510,'一般',29,3,2),
(510,'比较同意',29,4,3),
(510,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (511,5,'我很怕被冷落、被忽略',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(511,'非常不同意',29,1,0),
(511,'不太同意',29,2,1),
(511,'一般',29,3,2),
(511,'比较同意',29,4,3),
(511,'非常同意',29,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (512,5,'太亲密会让我想往后退一步喘口气',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(512,'非常不同意',30,1,0),
(512,'不太同意',30,2,1),
(512,'一般',30,3,2),
(512,'比较同意',30,4,3),
(512,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (513,5,'我不喜欢把脆弱和情绪摊开给人看',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(513,'非常不同意',30,1,0),
(513,'不太同意',30,2,1),
(513,'一般',30,3,2),
(513,'比较同意',30,4,3),
(513,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (514,5,'依赖别人会让我不自在，我更相信自己',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(514,'非常不同意',30,1,0),
(514,'不太同意',30,2,1),
(514,'一般',30,3,2),
(514,'比较同意',30,4,3),
(514,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (515,5,'对方靠太近时，我会不自觉地疏远',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(515,'非常不同意',30,1,0),
(515,'不太同意',30,2,1),
(515,'一般',30,3,2),
(515,'比较同意',30,4,3),
(515,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (516,5,'感情里我更看重独立和空间',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(516,'非常不同意',30,1,0),
(516,'不太同意',30,2,1),
(516,'一般',30,3,2),
(516,'比较同意',30,4,3),
(516,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (517,5,'表达「我需要你」对我来说很难',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(517,'非常不同意',30,1,0),
(517,'不太同意',30,2,1),
(517,'一般',30,3,2),
(517,'比较同意',30,4,3),
(517,'非常同意',30,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (518,5,'我既渴望亲密，又害怕靠太近会受伤害',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(518,'非常不同意',31,1,0),
(518,'不太同意',31,2,1),
(518,'一般',31,3,2),
(518,'比较同意',31,4,3),
(518,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (519,5,'对方越靠近，我越想推开，又怕真被推开',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(519,'非常不同意',31,1,0),
(519,'不太同意',31,2,1),
(519,'一般',31,3,2),
(519,'比较同意',31,4,3),
(519,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (520,5,'信任别人对我来说很难，总在等被辜负',21,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(520,'非常不同意',31,1,0),
(520,'不太同意',31,2,1),
(520,'一般',31,3,2),
(520,'比较同意',31,4,3),
(520,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (521,5,'亲密关系里我常在前冲和逃避之间来回',22,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(521,'非常不同意',31,1,0),
(521,'不太同意',31,2,1),
(521,'一般',31,3,2),
(521,'比较同意',31,4,3),
(521,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (522,5,'我容易把小事解读成对方要离开的信号',23,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(522,'非常不同意',31,1,0),
(522,'不太同意',31,2,1),
(522,'一般',31,3,2),
(522,'比较同意',31,4,3),
(522,'非常同意',31,5,4);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (523,5,'越在乎一个人，我越表现得不在乎',24,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(523,'非常不同意',31,1,0),
(523,'不太同意',31,2,1),
(523,'一般',31,3,2),
(523,'比较同意',31,4,3),
(523,'非常同意',31,5,4);

-- 结果类型（含初级 + 高级双档解析）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(5,'secure','安全型','靠近你，也不会弄丢自己','靠近你，也不会弄丢自己','','{"strengths": ["关系韧性好", "沟通直接", "给人安全感"], "weaknesses": ["偶尔显得不够热烈", "对戏剧化冲突耐受低"], "careers": ["需要协作的岗位", "团队协调", "咨询照护"]}','{"one_liner": "靠近你，也不会弄丢自己", "traits": ["能亲密也能独立", "信任稳定", "冲突时愿意沟通", "情绪较稳"], "strengths": ["关系韧性好", "沟通直接", "给人安全感"], "weaknesses": ["偶尔显得不够热烈", "对戏剧化冲突耐受低"], "tip": "你的稳定是稀缺资源，别因为它不轰烈就怀疑它的价值"}','{"chapters": [{"title": "深度画像", "content": "你在亲密关系里能既靠近又独立，对「被爱」有基本信任，不把关系当成自我证明。"}, {"title": "思维与决策", "content": "冲突时倾向直面沟通，而不是冷战或讨好，能区分对方的情绪和自己的责任。"}, {"title": "职场与做事", "content": "协作类天然占优，是团队里可靠的缓冲带。"}, {"title": "关系与情感", "content": "你能稳定地给也稳定地接，伴侣通常觉得被托住而非被消耗。"}, {"title": "压力与成长", "content": "压力下仍较稳定，但别替对方过度承担。成长是允许自己偶尔示弱。"}], "career": ["需要协作的岗位", "团队协调", "咨询照护"], "famous": "关系里那个让对方不用猜的人"}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(5,'anxious','焦虑型','越在乎，越怕抓不住','越在乎，越怕抓不住','','{"strengths": ["投入深", "情感丰富", "愿意经营关系"], "weaknesses": ["患得患失", "容易自我怀疑", "用讨好保关系"], "careers": ["服务", "教育", "创意", "需要人际的岗位"]}','{"one_liner": "越在乎，越怕抓不住", "traits": ["重视亲密", "敏感于被忽视", "需要反复确认", "怕被抛弃"], "strengths": ["投入深", "情感丰富", "愿意经营关系"], "weaknesses": ["患得患失", "容易自我怀疑", "用讨好保关系"], "tip": "把「他回慢了=不爱了」写下来，你会发现中间还差十个推理步骤"}','{"chapters": [{"title": "深度画像", "content": "你对亲密有强需求，也常因不确定对方还在不在而内耗，爱得用力。"}, {"title": "思维与决策", "content": "对方一点冷淡都会被放大成要失去的信号，容易先发制人地讨或闹。"}, {"title": "职场与做事", "content": "在乎评价，协作中容易过度迁就，需练习表达边界。"}, {"title": "关系与情感", "content": "热情、黏，但对方被压得喘不过气时会反推。需要学会自我安抚。"}, {"title": "压力与成长", "content": "压力下更黏人或更自我攻击。成长是建立我是安全的自我对话。"}], "career": ["服务", "教育", "创意", "需要人际的岗位"], "famous": "那个恋爱里会反复问你爱不爱我的人"}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(5,'avoidant','回避型','靠近可以，别贴上来','靠近可以，别贴上来','','{"strengths": ["情绪自给", "不黏人", "理性"], "weaknesses": ["回避深度沟通", "用疏远应对冲突", "显得冷淡"], "careers": ["技术", "研究", "独立作业", "分析"]}','{"one_liner": "靠近可以，别贴上来", "traits": ["重视独立", "不轻易暴露脆弱", "需要空间", "怕被依赖"], "strengths": ["情绪自给", "不黏人", "理性"], "weaknesses": ["回避深度沟通", "用疏远应对冲突", "显得冷淡"], "tip": "试着每月说一次我其实需要在你身边，亲密不是失去自由"}','{"chapters": [{"title": "深度画像", "content": "你对亲密有本能防备，靠独立和空间获得安全感，靠近太猛会想退。"}, {"title": "思维与决策", "content": "冲突时倾向沉默、回避，而不是摊开谈，怕被情绪淹没。"}, {"title": "职场与做事", "content": "独立作业强，但深度协作需要练习主动同步。"}, {"title": "关系与情感", "content": "靠谱但克制，伴侣常觉得够不到你。需要练习把感受说出来。"}, {"title": "压力与成长", "content": "压力下更封闭。成长是允许自己在关系里偶尔不理性。"}], "career": ["技术", "研究", "独立作业", "分析"], "famous": "那个再亲密也留一扇门的人"}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`basic_report`,`advanced_report`,`sort_order`) VALUES
(5,'fearful','恐惧型','想靠近，又怕靠太近会疼','想靠近，又怕靠太近会疼','','{"strengths": ["感受力强", "能共情", "一旦信任很投入"], "weaknesses": ["反复拉扯", "把小事读成被弃信号", "用不在乎保护自己"], "careers": ["需要支持但有边界的岗位", "创作", "咨询"]}','{"one_liner": "想靠近，又怕靠太近会疼", "traits": ["渴望亲密又怕受伤", "在靠近和推开间摇摆", "难信任", "容易自我防御"], "strengths": ["感受力强", "能共情", "一旦信任很投入"], "weaknesses": ["反复拉扯", "把小事读成被弃信号", "用不在乎保护自己"], "tip": "你推开对方的那一下，往往正是你最想被留住的时候——试着说出来"}','{"chapters": [{"title": "深度画像", "content": "你是焦虑与回避的混合，既渴望亲密又害怕靠太近受伤，于是反复靠近又逃开。"}, {"title": "思维与决策", "content": "越在乎越表现得不在乎，用疏离防御可能的被辜负，常把小事放大成危机。"}, {"title": "职场与做事", "content": "协作里忽冷忽热，需要稳定的反馈机制让自己安心。"}, {"title": "关系与情感", "content": "情深但难稳，伴侣容易在你推拉间疲惫。需要先把「我需要你」说出口。"}, {"title": "压力与成长", "content": "压力下更自我封闭或突然爆发。成长是识别防御动作，给关系一点耐心。"}], "career": ["需要支持但有边界的岗位", "创作", "咨询"], "famous": "那个嘴上说随便、心里在意很久的人"}',4);
