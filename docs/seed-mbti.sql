-- =============================================================================
-- 探我趣测 · MBTI 初始数据（由 tools/import_mbti_csv.py 从 CSV 生成）
-- 可重复执行：开头会先清掉 quiz_id = 1 的全部内容
-- =============================================================================

SET NAMES utf8mb4;

-- 先删子表再删父表，避免残留孤儿数据
DELETE FROM `question_option` WHERE `question_id` IN (SELECT `id` FROM `question` WHERE `quiz_id` = 1);
DELETE FROM `question`        WHERE `quiz_id` = 1;
DELETE FROM `quiz_result`     WHERE `quiz_id` = 1;
DELETE FROM `dimension`       WHERE `quiz_id` = 1;
DELETE FROM `quiz`            WHERE `id`      = 1;

-- 测评本体
INSERT INTO `quiz` (`id`,`code`,`name`,`subtitle`,`description`,`question_count`,`price_coin`,`status`) VALUES
(1,'mbti','MBTI 性格类型测试','4 个维度，看清你的思维偏好','MBTI 通过外向/内向、实感/直觉、思考/情感、判断/感知四个维度，把人的认知偏好分成 16 种类型。它不是能力测试，没有好坏之分，只是描述你更倾向于如何获取信息、做决定。',0,0,1);

-- 维度定义（8 个，4 组对撞）
INSERT INTO `dimension` (`id`,`quiz_id`,`code`,`name`,`pair_code`,`pair_order`) VALUES
(1,1,'E','外向','EI',1),
(2,1,'I','内向','EI',1),
(3,1,'S','实感','SN',2),
(4,1,'N','直觉','SN',2),
(5,1,'T','思考','TF',3),
(6,1,'F','情感','TF',3),
(7,1,'J','判断','JP',4),
(8,1,'P','感知','JP',4);

-- 题目（93 道）
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (2,1,'在社交聚会中，你通常会：',1,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(2,'主动与多人交谈，享受热闹氛围',1,1,0),
(2,'与少数几个人深入交流，或独自观察',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (3,1,'当你需要休息恢复精力时，你更倾向于：',2,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(3,'与朋友外出活动或聚会',1,1,0),
(3,'独自在家放松或做自己喜欢的事',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (4,1,'在团队讨论中，你通常：',3,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(4,'喜欢发表意见并参与热烈讨论',1,1,0),
(4,'更愿意倾听思考后再发言',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (5,1,'你更喜欢的周末是：',4,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(5,'参加聚会、活动或与朋友出游',1,1,0),
(5,'在家阅读、看电影或独自放松',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (6,1,'在陌生人面前，你通常会：',5,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(6,'感到自在，能很快融入交流',1,1,0),
(6,'感到有些拘谨，需要时间适应',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (7,1,'你认为自己是一个：',6,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(7,'外向、善于社交的人',1,1,0),
(7,'内向、喜欢独处的人',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (8,1,'在电话交谈中，你通常：',7,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(8,'乐于长时间聊天',1,1,0),
(8,'倾向于简短交流，喜欢面对面或文字',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (9,1,'当你有想法时，你倾向于：',8,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(9,'立即说出来与人讨论',1,1,0),
(9,'先在内心反复思考成熟后再表达',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (10,1,'在人群中，你通常会感到：',9,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(10,'精力充沛，充满活力',1,1,0),
(10,'精力消耗，需要独处恢复',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (11,1,'你更喜欢的工作环境是：',10,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(11,'开放式办公室，经常与同事交流',1,1,0),
(11,'安静独立的空间，专注工作',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (12,1,'参加活动后，你通常会：',11,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(12,'感到兴奋，想继续下一个活动',1,1,0),
(12,'感到疲惫，需要时间独处恢复',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (13,1,'你的朋友圈通常是：',12,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(13,'广泛，认识很多人',1,1,0),
(13,'精简，只有几个深交的朋友',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (14,1,'在解决问题时，你更倾向于：',13,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(14,'与他人讨论，集思广益',1,1,0),
(14,'独自思考，独立解决',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (15,1,'你更喜欢的沟通方式是：',14,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(15,'面对面交流或电话',1,1,0),
(15,'邮件、消息或书面沟通',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (16,1,'在聚会中，你更常扮演的角色是：',15,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(16,'活跃气氛的组织者',1,1,0),
(16,'安静倾听的参与者',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (17,1,'当你独处太久时，你会：',16,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(17,'感到无聊，想找人交流',1,1,0),
(17,'感到舒适，享受独处时光',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (18,1,'在新环境中，你通常会：',17,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(18,'主动认识新朋友',1,1,0),
(18,'等待他人接近或保持观察',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (19,1,'你认为自己是：',18,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(19,'一个表达者，喜欢分享想法',1,1,0),
(19,'一个思考者，喜欢深入思考',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (20,1,'在做决定前，你倾向于：',19,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(20,'与他人讨论听取意见',1,1,0),
(20,'自己独立思考分析',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (21,1,'你更喜欢：',20,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(21,'热闹繁忙的生活节奏',1,1,0),
(21,'安静平和的生活方式',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (22,1,'在会议中，你更倾向于：',21,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(22,'积极发言表达观点',1,1,0),
(22,'认真倾听，必要时才发言',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (23,1,'当你获得好成绩或成就时，你更想：',22,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(23,'与他人分享喜悦',1,1,0),
(23,'私下庆祝或默默满足',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (24,1,'你更喜欢的学习方式是：',23,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(24,'小组讨论或互动学习',1,1,0),
(24,'独立阅读或自学',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (25,1,'在社交场合，你更容易：',24,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(25,'开启话题，打破沉默',1,1,0),
(25,'等待他人主动交谈',2,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (26,1,'你更容易注意到：',25,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(26,'周围环境中的具体细节和实际信息',3,1,0),
(26,'事物的整体印象和隐藏的可能性',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (27,1,'在阅读时，你更偏好：',26,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(27,'具体的事实描述和实用信息',3,1,0),
(27,'抽象的概念探讨和理论分析',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (28,1,'在解决问题时，你倾向于：',27,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(28,'运用已验证的方法和经验',3,1,0),
(28,'尝试新的思路和创新方法',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (29,1,'你更信任：',28,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(29,'自己的亲身经验和实际观察',3,1,0),
(29,'直觉、灵感和第六感',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (30,1,'你认为作家应该：',29,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(30,'准确描述现实世界的细节',3,1,0),
(30,'发挥想象力创造新颖的世界',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (31,1,'在做计划时，你更关注：',30,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(31,'具体的步骤和实际操作',3,1,0),
(31,'整体的愿景和长远目标',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (32,1,'你更感兴趣的是：',31,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(32,'现实中正在发生的事情',3,1,0),
(32,'未来可能发生的变化',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (33,1,'在学习新技能时，你更倾向于：',32,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(33,'按部就班，先掌握基础',3,1,0),
(33,'跳跃式学习，先看整体',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (34,1,'你更喜欢的工作是：',33,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(34,'有明确流程和规范的工作',3,1,0),
(34,'需要创意和想象力的工作',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (35,1,'当你描述一件事时，你通常会：',34,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(35,'详细描述具体细节',3,1,0),
(35,'概括要点，描绘整体印象',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (36,1,'你更欣赏：',35,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(36,'实用性强、能解决问题的想法',3,1,0),
(36,'新颖独特、富有创意的想法',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (37,1,'面对新任务，你更倾向于：',36,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(37,'参照以往的成功经验',3,1,0),
(37,'寻找全新的解决方案',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (38,1,'你认为更重要的是：',37,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(38,'关注当下的实际情况',3,1,0),
(38,'思考未来的发展可能',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (39,1,'你更喜欢哪种类型的小说：',38,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(39,'真实背景的现实主义小说',3,1,0),
(39,'充满想象的科幻或奇幻小说',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (40,1,'在交流中，你更倾向于：',39,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(40,'使用具体的例子和事实',3,1,0),
(40,'使用比喻和抽象概念',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (41,1,'你更擅长：',40,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(41,'处理具体实际的事务',3,1,0),
(41,'发现潜在的机会和联系',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (42,1,'当别人说话太抽象时，你会：',41,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(42,'希望对方给出具体例子',3,1,0),
(42,'感到有趣，想继续探讨',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (43,1,'你更看重：',42,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(43,'事实和数据的准确性',3,1,0),
(43,'概念和理论的创新性',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (44,1,'在旅行时，你更倾向于：',43,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(44,'按照攻略参观著名景点',3,1,0),
(44,'探索未知，发现新奇体验',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (45,1,'你更容易被什么打动：',44,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(45,'真实感人的真实故事',3,1,0),
(45,'富有想象力的创意作品',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (46,1,'在观察事物时，你更容易：',45,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(46,'注意到细节和组成部分',3,1,0),
(46,'看到整体和内在联系',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (47,1,'你更喜欢的指导方式是：',46,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(47,'具体详细的操作步骤',3,1,0),
(47,'概括性的原则和方向',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (48,1,'你更相信：',47,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(48,'眼见为实的经验',3,1,0),
(48,'超越表象的洞察',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (49,1,'你更喜欢：',48,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(49,'按常规方式做事',3,1,0),
(49,'尝试新的方法',4,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (50,1,'在做决定时，你更看重：',49,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(50,'逻辑分析和客观标准',5,1,0),
(50,'他人感受和和谐关系',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (51,1,'当别人向你倾诉问题时，你会：',50,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(51,'提供解决方案和建议',5,1,0),
(51,'表达理解和情感支持',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (52,1,'你认为更好的领导方式是：',51,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(52,'公正客观，奖罚分明',5,1,0),
(52,'关心下属，注重人情',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (53,1,'在批评他人时，你倾向于：',52,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(53,'直接指出问题，对事不对人',5,1,0),
(53,'委婉表达，避免伤害感情',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (54,1,'你认为更重要的是：',53,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(54,'公平公正，一视同仁',5,1,0),
(54,'同情理解，因人而异',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (55,1,'在讨论问题时，你更倾向于：',54,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(55,'坚持自己的逻辑观点',5,1,0),
(55,'考虑他人的立场感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (56,1,'你更容易被什么说服：',55,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(56,'有逻辑的数据和事实',5,1,0),
(56,'真挚的情感和个人故事',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (57,1,'面对冲突时，你更倾向于：',56,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(57,'客观分析对错',5,1,0),
(57,'维护关系和谐',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (58,1,'你认为好的决定应该：',57,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(58,'基于理性的分析',5,1,0),
(58,'考虑到人的感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (59,1,'当朋友犯错时，你会：',58,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(59,'指出错误并分析原因',5,1,0),
(59,'先安慰再委婉提醒',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (60,1,'你更看重：',59,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(60,'效率和结果',5,1,0),
(60,'过程和体验',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (61,1,'在评价一件事时，你更关注：',60,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(61,'是否合理有效',5,1,0),
(61,'是否让人满意',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (62,1,'你更擅长：',61,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(62,'客观分析问题',5,1,0),
(62,'理解他人情感',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (63,1,'在做选择时，你更倾向于：',62,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(63,'权衡利弊得失',5,1,0),
(63,'听从内心的感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (64,1,'你认为团队管理应该：',63,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(64,'制定明确的规则标准',5,1,0),
(64,'营造和谐的氛围',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (65,1,'当别人情绪低落时，你会：',64,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(65,'帮助他们分析问题原因',5,1,0),
(65,'陪伴安慰，给予情感支持',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (66,1,'你更欣赏：',65,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(66,'理性冷静的人',5,1,0),
(66,'善良温暖的人',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (67,1,'在辩论中，你更注重：',66,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(67,'论点的逻辑正确性',5,1,0),
(67,'辩论的方式和态度',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (68,1,'你认为奖励应该基于：',67,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(68,'客观的业绩表现',5,1,0),
(68,'付出的努力和态度',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (69,1,'面对两难选择，你更倾向于：',68,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(69,'分析利弊，做出最优选择',5,1,0),
(69,'考虑对各方的影响',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (70,1,'你认为诚实和友善哪个更重要：',69,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(70,'诚实，说出真实想法',5,1,0),
(70,'友善，照顾他人感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (71,1,'在解决问题时，你更倾向于：',70,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(71,'用头脑分析',5,1,0),
(71,'用心感受',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (72,1,'你更不喜欢的场景是：',71,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(72,'逻辑混乱、毫无章法',5,1,0),
(72,'冷漠无情、缺乏关怀',6,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (73,1,'你更喜欢的工作方式是：',72,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(73,'制定详细计划并按计划执行',7,1,0),
(73,'保持灵活性，随机应变',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (74,1,'对于任务，你倾向于：',73,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(74,'提前完成，避免最后时刻的紧张',7,1,0),
(74,'在截止日期前完成，享受紧迫感',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (75,1,'你的书桌或房间通常是：',74,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(75,'整洁有序，物品摆放有规律',7,1,0),
(75,'相对随意，使用方便即可',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (76,1,'在旅行时，你更喜欢：',75,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(76,'提前规划行程和预订',7,1,0),
(76,'随性而为，到时再决定',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (77,1,'面对新任务，你倾向于：',76,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(77,'立即开始行动',7,1,0),
(77,'收集更多信息后再开始',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (78,1,'你更喜欢的日常生活是：',77,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(78,'按部就班，保持规律',7,1,0),
(78,'追求新鲜，尝试变化',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (79,1,'在完成项目时，你更倾向于：',78,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(79,'提前规划，按时完成',7,1,0),
(79,'在压力下工作效率更高',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (80,1,'你更看重：',79,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(80,'计划和确定性',7,1,0),
(80,'灵活和可能性',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (81,1,'当计划被打乱时，你会：',80,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(81,'感到不适，想尽快调整',7,1,0),
(81,'坦然接受，灵活应对',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (82,1,'你更倾向于：',81,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(82,'把事情安排得井井有条',7,1,0),
(82,'顺其自然，见机行事',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (83,1,'在会议中，你更希望：',82,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(83,'有明确的议程和时间安排',7,1,0),
(83,'开放式讨论，自由发挥',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (84,1,'你认为自己是一个：',83,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(84,'有计划、有条理的人',7,1,0),
(84,'随性、灵活的人',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (85,1,'对待截止日期，你更倾向于：',84,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(85,'提前很久完成',7,1,0),
(85,'在截止前一刻完成',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (86,1,'你更不喜欢的场景是：',85,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(86,'计划被打乱、充满变数',7,1,0),
(86,'过于死板、缺乏灵活性',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (87,1,'在做决定时，你更倾向于：',86,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(87,'尽快做出决定',7,1,0),
(87,'保留更多选择，暂不决定',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (88,1,'你更喜欢的周末安排是：',87,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(88,'提前计划好的活动',7,1,0),
(88,'看心情决定做什么',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (89,1,'对于规则，你更倾向于：',88,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(89,'遵守规则，按规章办事',7,1,0),
(89,'根据情况灵活处理',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (90,1,'你更擅长：',89,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(90,'制定计划并执行',7,1,0),
(90,'应对变化和突发情况',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (91,1,'你更欣赏：',90,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(91,'有始有终、善始善终的人',7,1,0),
(91,'思维活跃、创意不断的人',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (92,1,'在处理多件事情时，你更倾向于：',91,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(92,'一件一件按顺序完成',7,1,0),
(92,'同时处理，灵活切换',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (93,1,'你更看重的结果是：',92,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(93,'按计划达成目标',7,1,0),
(93,'享受过程中的发现',8,1,1);
INSERT INTO `question` (`id`,`quiz_id`,`content`,`sort_order`,`status`) VALUES (94,1,'对于未来，你更倾向于：',93,1);
INSERT INTO `question_option` (`question_id`,`content`,`dimension_id`,`score`,`sort_order`) VALUES
(94,'有明确的规划和目标',7,1,0),
(94,'保持开放，顺其自然',8,1,1);

-- 结果类型（16 型）
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'INTJ','建筑师','富有想象力和战略性的思想家，一切皆在计划之中。','富有想象力和战略性的思想家，一切皆在计划之中。','','{"strengths": ["战略思维", "独立思考", "意志坚定", "追求卓越", "善于规划"], "weaknesses": ["过于完美", "不善社交", "容易固执", "情感表达少", "过于挑剔"], "careers": ["科学家", "工程师", "系统分析师", "战略顾问", "投资分析师"]}',1);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'INTP','逻辑学家','富有创造力的发明家，对知识有着永不满足的渴望。','富有创造力的发明家，对知识有着永不满足的渴望。','','{"strengths": ["逻辑分析", "创新思维", "客观公正", "求知欲强", "善于解决复杂问题"], "weaknesses": ["脱离现实", "不善表达", "拖延倾向", "过于理论化", "缺乏耐心"], "careers": ["哲学家", "科学家", "程序员", "数学家", "研究员"]}',2);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ENTJ','指挥官','大胆、富有想象力的领导者，总能找到解决问题的方法。','大胆、富有想象力的领导者，总能找到解决问题的方法。','','{"strengths": ["领导才能", "决策果断", "自信坚定", "效率至上", "善于激励他人"], "weaknesses": ["控制欲强", "缺乏耐心", "忽视情感", "过于强势", "不善妥协"], "careers": ["企业高管", "律师", "项目经理", "创业者", "管理咨询顾问"]}',3);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ENTP','辩论家','聪明好奇的思想家，无法抗拒智力上的挑战。','聪明好奇的思想家，无法抗拒智力上的挑战。','','{"strengths": ["思维敏捷", "善于辩论", "创新能力强", "适应力好", "多才多艺"], "weaknesses": ["喜欢争论", "缺乏耐心", "难以专注", "忽视细节", "容易厌倦"], "careers": ["律师", "记者", "创业者", "营销专家", "产品经理"]}',4);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'INFJ','提倡者','安静而有影响力，具有理想主义色彩，致力于帮助他人。','安静而有影响力，具有理想主义色彩，致力于帮助他人。','','{"strengths": ["洞察力强", "富有同情心", "追求意义", "理想主义", "善于理解他人"], "weaknesses": ["过于完美", "容易倦怠", "不善拒绝", "敏感脆弱", "难以释怀"], "careers": ["心理咨询师", "作家", "教育工作者", "社会工作者", "非营利组织管理者"]}',5);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'INFP','调解员','诗意、善良的利他主义者，总是渴望帮助良善之事。','诗意、善良的利他主义者，总是渴望帮助良善之事。','','{"strengths": ["创意丰富", "富有同理心", "价值观坚定", "善于倾听", "追求和谐"], "weaknesses": ["过于理想化", "不善实际", "敏感易伤", "拖延倾向", "难以承受批评"], "careers": ["作家", "艺术家", "心理咨询师", "设计师", "社会工作者"]}',6);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ENFJ','主人公','富有魅力的激励者，能够引领听众走向美好明天。','富有魅力的激励者，能够引领听众走向美好明天。','','{"strengths": ["领导才能", "善于沟通", "富有同理心", "鼓舞他人", "有魅力"], "weaknesses": ["过于理想化", "忽视自己", "敏感脆弱", "控制欲强", "难以接受批评"], "careers": ["教师", "咨询师", "公关专家", "人力资源经理", "培训师"]}',7);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ENFP','竞选者','热情、富有创造力的社交达人，总能找到理由微笑。','热情、富有创造力的社交达人，总能找到理由微笑。','','{"strengths": ["热情洋溢", "创意无限", "善于交际", "乐观积极", "适应力强"], "weaknesses": ["注意力分散", "容易厌倦", "过度理想化", "情绪化", "缺乏坚持"], "careers": ["记者", "演员", "营销专员", "创意总监", "创业者"]}',8);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ISTJ','物流师','务实、专注于事实的个体，其可靠性不容置疑。','务实、专注于事实的个体，其可靠性不容置疑。','','{"strengths": ["责任心强", "细致认真", "值得信赖", "有条不紊", "注重细节"], "weaknesses": ["固执己见", "不善变通", "情感表达少", "过于保守", "不喜欢变化"], "careers": ["会计师", "审计师", "行政人员", "法官", "项目经理"]}',9);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ISFJ','守卫者','非常专注和温暖的守护者，时刻准备保护所爱之人。','非常专注和温暖的守护者，时刻准备保护所爱之人。','','{"strengths": ["忠诚可靠", "细心体贴", "记忆力强", "勤勉尽责", "善于照顾他人"], "weaknesses": ["过于谦虚", "不善拒绝", "回避冲突", "压抑情感", "过度付出"], "careers": ["护士", "教师", "行政助理", "社会工作者", "人力资源专员"]}',10);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ESTJ','总经理','出色的管理者，在管理事务和人员方面无与伦比。','出色的管理者，在管理事务和人员方面无与伦比。','','{"strengths": ["组织能力强", "执行力高", "责任心重", "值得信赖", "善于管理"], "weaknesses": ["固执己见", "缺乏耐心", "不善倾听", "过于强势", "缺乏灵活性"], "careers": ["企业经理", "法官", "财务主管", "军官", "项目总监"]}',11);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ESFJ','执政官','极具同情心、爱交际的人，总是热心帮助他人。','极具同情心、爱交际的人，总是热心帮助他人。','','{"strengths": ["善于社交", "乐于助人", "忠诚可靠", "组织能力强", "关心他人"], "weaknesses": ["过于在意他人看法", "不善接受批评", "自我牺牲", "缺乏灵活性", "容易受伤"], "careers": ["护士", "教师", "销售代表", "活动策划师", "客服经理"]}',12);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ISTP','鉴赏家','大胆而实际的实验家，善于使用各种工具。','大胆而实际的实验家，善于使用各种工具。','','{"strengths": ["动手能力强", "冷静理性", "适应力好", "解决问题能力强", "善于分析"], "weaknesses": ["情感表达少", "容易厌倦", "不善承诺", "过于独立", "缺乏耐心"], "careers": ["工程师", "技师", "飞行员", "运动员", "技术专家"]}',13);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ISFP','探险家','灵活而有魅力的艺术家，时刻准备探索和体验新事物。','灵活而有魅力的艺术家，时刻准备探索和体验新事物。','','{"strengths": ["艺术天赋", "适应力强", "温和友善", "观察力敏锐", "审美能力强"], "weaknesses": ["竞争心弱", "计划性差", "过于敏感", "不善表达", "容易逃避冲突"], "careers": ["艺术家", "设计师", "厨师", "摄影师", "音乐家"]}',14);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ESTP','企业家','聪明、精力充沛、善于感知的人，真正享受生活边缘。','聪明、精力充沛、善于感知的人，真正享受生活边缘。','','{"strengths": ["行动力强", "适应力好", "善于社交", "危机处理能力强", "观察力敏锐"], "weaknesses": ["缺乏耐心", "不善规划", "冒险倾向", "忽视情感", "容易厌倦"], "careers": ["销售代表", "运动员", "急救人员", "企业家", "投资交易员"]}',15);
INSERT INTO `quiz_result` (`quiz_id`,`type_code`,`name`,`summary`,`detail`,`image_url`,`traits`,`sort_order`) VALUES (1,'ESFP','表演者','自发的、精力充沛的艺人，生活永远不会无聊。','自发的、精力充沛的艺人，生活永远不会无聊。','','{"strengths": ["热情洋溢", "善于交际", "适应力强", "乐观积极", "善于娱乐他人"], "weaknesses": ["缺乏计划", "逃避困难", "注意力分散", "过于冲动", "不善长期规划"], "careers": ["演员", "主持人", "销售代表", "活动策划师", "旅游顾问"]}',16);
