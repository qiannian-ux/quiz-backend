/**
 * 本地题库（MBTI 93 题 + 16 型人格）
 * ------------------------------------------------------------
 * 本文件由 tools/gen_frontend_questions.py 从 CSV 自动生成，
 * 改数据请改 CSV 后重跑脚本，不要手改这里。
 *
 * 为什么还要本地题库？
 *   接口优先 + 本地兜底：弱网 / 后端挂了，用户照样能完整测完，
 *   不至于白屏。真实项目里这叫离线兜底。
 *
 * 数据模型（与后端 question / question_option / dimension 三表一一对应）：
 *   question.id            -> id
 *   question.content       -> title
 *   question_option        -> options[]，每个带 type（维度码）与 score
 *   dimension.pair_code    -> DIMENSION_PAIRS[].key，用于对撞算分
 */

export const LOCAL_QUESTIONS = [
  {
    "id": 2,
    "title": "在社交聚会中，你通常会：",
    "sortOrder": 1,
    "options": [
      {
        "text": "主动与多人交谈，享受热闹氛围",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "与少数几个人深入交流，或独自观察",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 3,
    "title": "当你需要休息恢复精力时，你更倾向于：",
    "sortOrder": 2,
    "options": [
      {
        "text": "与朋友外出活动或聚会",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "独自在家放松或做自己喜欢的事",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 4,
    "title": "在团队讨论中，你通常：",
    "sortOrder": 3,
    "options": [
      {
        "text": "喜欢发表意见并参与热烈讨论",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "更愿意倾听思考后再发言",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 5,
    "title": "你更喜欢的周末是：",
    "sortOrder": 4,
    "options": [
      {
        "text": "参加聚会、活动或与朋友出游",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "在家阅读、看电影或独自放松",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 6,
    "title": "在陌生人面前，你通常会：",
    "sortOrder": 5,
    "options": [
      {
        "text": "感到自在，能很快融入交流",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "感到有些拘谨，需要时间适应",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 7,
    "title": "你认为自己是一个：",
    "sortOrder": 6,
    "options": [
      {
        "text": "外向、善于社交的人",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "内向、喜欢独处的人",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 8,
    "title": "在电话交谈中，你通常：",
    "sortOrder": 7,
    "options": [
      {
        "text": "乐于长时间聊天",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "倾向于简短交流，喜欢面对面或文字",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 9,
    "title": "当你有想法时，你倾向于：",
    "sortOrder": 8,
    "options": [
      {
        "text": "立即说出来与人讨论",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "先在内心反复思考成熟后再表达",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 10,
    "title": "在人群中，你通常会感到：",
    "sortOrder": 9,
    "options": [
      {
        "text": "精力充沛，充满活力",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "精力消耗，需要独处恢复",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 11,
    "title": "你更喜欢的工作环境是：",
    "sortOrder": 10,
    "options": [
      {
        "text": "开放式办公室，经常与同事交流",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "安静独立的空间，专注工作",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 12,
    "title": "参加活动后，你通常会：",
    "sortOrder": 11,
    "options": [
      {
        "text": "感到兴奋，想继续下一个活动",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "感到疲惫，需要时间独处恢复",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 13,
    "title": "你的朋友圈通常是：",
    "sortOrder": 12,
    "options": [
      {
        "text": "广泛，认识很多人",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "精简，只有几个深交的朋友",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 14,
    "title": "在解决问题时，你更倾向于：",
    "sortOrder": 13,
    "options": [
      {
        "text": "与他人讨论，集思广益",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "独自思考，独立解决",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 15,
    "title": "你更喜欢的沟通方式是：",
    "sortOrder": 14,
    "options": [
      {
        "text": "面对面交流或电话",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "邮件、消息或书面沟通",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 16,
    "title": "在聚会中，你更常扮演的角色是：",
    "sortOrder": 15,
    "options": [
      {
        "text": "活跃气氛的组织者",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "安静倾听的参与者",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 17,
    "title": "当你独处太久时，你会：",
    "sortOrder": 16,
    "options": [
      {
        "text": "感到无聊，想找人交流",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "感到舒适，享受独处时光",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 18,
    "title": "在新环境中，你通常会：",
    "sortOrder": 17,
    "options": [
      {
        "text": "主动认识新朋友",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "等待他人接近或保持观察",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 19,
    "title": "你认为自己是：",
    "sortOrder": 18,
    "options": [
      {
        "text": "一个表达者，喜欢分享想法",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "一个思考者，喜欢深入思考",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 20,
    "title": "在做决定前，你倾向于：",
    "sortOrder": 19,
    "options": [
      {
        "text": "与他人讨论听取意见",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "自己独立思考分析",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 21,
    "title": "你更喜欢：",
    "sortOrder": 20,
    "options": [
      {
        "text": "热闹繁忙的生活节奏",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "安静平和的生活方式",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 22,
    "title": "在会议中，你更倾向于：",
    "sortOrder": 21,
    "options": [
      {
        "text": "积极发言表达观点",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "认真倾听，必要时才发言",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 23,
    "title": "当你获得好成绩或成就时，你更想：",
    "sortOrder": 22,
    "options": [
      {
        "text": "与他人分享喜悦",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "私下庆祝或默默满足",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 24,
    "title": "你更喜欢的学习方式是：",
    "sortOrder": 23,
    "options": [
      {
        "text": "小组讨论或互动学习",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "独立阅读或自学",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 25,
    "title": "在社交场合，你更容易：",
    "sortOrder": 24,
    "options": [
      {
        "text": "开启话题，打破沉默",
        "type": "E",
        "score": 1,
        "order": 0
      },
      {
        "text": "等待他人主动交谈",
        "type": "I",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 26,
    "title": "你更容易注意到：",
    "sortOrder": 25,
    "options": [
      {
        "text": "周围环境中的具体细节和实际信息",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "事物的整体印象和隐藏的可能性",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 27,
    "title": "在阅读时，你更偏好：",
    "sortOrder": 26,
    "options": [
      {
        "text": "具体的事实描述和实用信息",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "抽象的概念探讨和理论分析",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 28,
    "title": "在解决问题时，你倾向于：",
    "sortOrder": 27,
    "options": [
      {
        "text": "运用已验证的方法和经验",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "尝试新的思路和创新方法",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 29,
    "title": "你更信任：",
    "sortOrder": 28,
    "options": [
      {
        "text": "自己的亲身经验和实际观察",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "直觉、灵感和第六感",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 30,
    "title": "你认为作家应该：",
    "sortOrder": 29,
    "options": [
      {
        "text": "准确描述现实世界的细节",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "发挥想象力创造新颖的世界",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 31,
    "title": "在做计划时，你更关注：",
    "sortOrder": 30,
    "options": [
      {
        "text": "具体的步骤和实际操作",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "整体的愿景和长远目标",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 32,
    "title": "你更感兴趣的是：",
    "sortOrder": 31,
    "options": [
      {
        "text": "现实中正在发生的事情",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "未来可能发生的变化",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 33,
    "title": "在学习新技能时，你更倾向于：",
    "sortOrder": 32,
    "options": [
      {
        "text": "按部就班，先掌握基础",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "跳跃式学习，先看整体",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 34,
    "title": "你更喜欢的工作是：",
    "sortOrder": 33,
    "options": [
      {
        "text": "有明确流程和规范的工作",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "需要创意和想象力的工作",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 35,
    "title": "当你描述一件事时，你通常会：",
    "sortOrder": 34,
    "options": [
      {
        "text": "详细描述具体细节",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "概括要点，描绘整体印象",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 36,
    "title": "你更欣赏：",
    "sortOrder": 35,
    "options": [
      {
        "text": "实用性强、能解决问题的想法",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "新颖独特、富有创意的想法",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 37,
    "title": "面对新任务，你更倾向于：",
    "sortOrder": 36,
    "options": [
      {
        "text": "参照以往的成功经验",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "寻找全新的解决方案",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 38,
    "title": "你认为更重要的是：",
    "sortOrder": 37,
    "options": [
      {
        "text": "关注当下的实际情况",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "思考未来的发展可能",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 39,
    "title": "你更喜欢哪种类型的小说：",
    "sortOrder": 38,
    "options": [
      {
        "text": "真实背景的现实主义小说",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "充满想象的科幻或奇幻小说",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 40,
    "title": "在交流中，你更倾向于：",
    "sortOrder": 39,
    "options": [
      {
        "text": "使用具体的例子和事实",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "使用比喻和抽象概念",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 41,
    "title": "你更擅长：",
    "sortOrder": 40,
    "options": [
      {
        "text": "处理具体实际的事务",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "发现潜在的机会和联系",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 42,
    "title": "当别人说话太抽象时，你会：",
    "sortOrder": 41,
    "options": [
      {
        "text": "希望对方给出具体例子",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "感到有趣，想继续探讨",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 43,
    "title": "你更看重：",
    "sortOrder": 42,
    "options": [
      {
        "text": "事实和数据的准确性",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "概念和理论的创新性",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 44,
    "title": "在旅行时，你更倾向于：",
    "sortOrder": 43,
    "options": [
      {
        "text": "按照攻略参观著名景点",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "探索未知，发现新奇体验",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 45,
    "title": "你更容易被什么打动：",
    "sortOrder": 44,
    "options": [
      {
        "text": "真实感人的真实故事",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "富有想象力的创意作品",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 46,
    "title": "在观察事物时，你更容易：",
    "sortOrder": 45,
    "options": [
      {
        "text": "注意到细节和组成部分",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "看到整体和内在联系",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 47,
    "title": "你更喜欢的指导方式是：",
    "sortOrder": 46,
    "options": [
      {
        "text": "具体详细的操作步骤",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "概括性的原则和方向",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 48,
    "title": "你更相信：",
    "sortOrder": 47,
    "options": [
      {
        "text": "眼见为实的经验",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "超越表象的洞察",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 49,
    "title": "你更喜欢：",
    "sortOrder": 48,
    "options": [
      {
        "text": "按常规方式做事",
        "type": "S",
        "score": 1,
        "order": 0
      },
      {
        "text": "尝试新的方法",
        "type": "N",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 50,
    "title": "在做决定时，你更看重：",
    "sortOrder": 49,
    "options": [
      {
        "text": "逻辑分析和客观标准",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "他人感受和和谐关系",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 51,
    "title": "当别人向你倾诉问题时，你会：",
    "sortOrder": 50,
    "options": [
      {
        "text": "提供解决方案和建议",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "表达理解和情感支持",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 52,
    "title": "你认为更好的领导方式是：",
    "sortOrder": 51,
    "options": [
      {
        "text": "公正客观，奖罚分明",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "关心下属，注重人情",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 53,
    "title": "在批评他人时，你倾向于：",
    "sortOrder": 52,
    "options": [
      {
        "text": "直接指出问题，对事不对人",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "委婉表达，避免伤害感情",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 54,
    "title": "你认为更重要的是：",
    "sortOrder": 53,
    "options": [
      {
        "text": "公平公正，一视同仁",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "同情理解，因人而异",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 55,
    "title": "在讨论问题时，你更倾向于：",
    "sortOrder": 54,
    "options": [
      {
        "text": "坚持自己的逻辑观点",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "考虑他人的立场感受",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 56,
    "title": "你更容易被什么说服：",
    "sortOrder": 55,
    "options": [
      {
        "text": "有逻辑的数据和事实",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "真挚的情感和个人故事",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 57,
    "title": "面对冲突时，你更倾向于：",
    "sortOrder": 56,
    "options": [
      {
        "text": "客观分析对错",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "维护关系和谐",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 58,
    "title": "你认为好的决定应该：",
    "sortOrder": 57,
    "options": [
      {
        "text": "基于理性的分析",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "考虑到人的感受",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 59,
    "title": "当朋友犯错时，你会：",
    "sortOrder": 58,
    "options": [
      {
        "text": "指出错误并分析原因",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "先安慰再委婉提醒",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 60,
    "title": "你更看重：",
    "sortOrder": 59,
    "options": [
      {
        "text": "效率和结果",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "过程和体验",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 61,
    "title": "在评价一件事时，你更关注：",
    "sortOrder": 60,
    "options": [
      {
        "text": "是否合理有效",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "是否让人满意",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 62,
    "title": "你更擅长：",
    "sortOrder": 61,
    "options": [
      {
        "text": "客观分析问题",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "理解他人情感",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 63,
    "title": "在做选择时，你更倾向于：",
    "sortOrder": 62,
    "options": [
      {
        "text": "权衡利弊得失",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "听从内心的感受",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 64,
    "title": "你认为团队管理应该：",
    "sortOrder": 63,
    "options": [
      {
        "text": "制定明确的规则标准",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "营造和谐的氛围",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 65,
    "title": "当别人情绪低落时，你会：",
    "sortOrder": 64,
    "options": [
      {
        "text": "帮助他们分析问题原因",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "陪伴安慰，给予情感支持",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 66,
    "title": "你更欣赏：",
    "sortOrder": 65,
    "options": [
      {
        "text": "理性冷静的人",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "善良温暖的人",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 67,
    "title": "在辩论中，你更注重：",
    "sortOrder": 66,
    "options": [
      {
        "text": "论点的逻辑正确性",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "辩论的方式和态度",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 68,
    "title": "你认为奖励应该基于：",
    "sortOrder": 67,
    "options": [
      {
        "text": "客观的业绩表现",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "付出的努力和态度",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 69,
    "title": "面对两难选择，你更倾向于：",
    "sortOrder": 68,
    "options": [
      {
        "text": "分析利弊，做出最优选择",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "考虑对各方的影响",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 70,
    "title": "你认为诚实和友善哪个更重要：",
    "sortOrder": 69,
    "options": [
      {
        "text": "诚实，说出真实想法",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "友善，照顾他人感受",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 71,
    "title": "在解决问题时，你更倾向于：",
    "sortOrder": 70,
    "options": [
      {
        "text": "用头脑分析",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "用心感受",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 72,
    "title": "你更不喜欢的场景是：",
    "sortOrder": 71,
    "options": [
      {
        "text": "逻辑混乱、毫无章法",
        "type": "T",
        "score": 1,
        "order": 0
      },
      {
        "text": "冷漠无情、缺乏关怀",
        "type": "F",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 73,
    "title": "你更喜欢的工作方式是：",
    "sortOrder": 72,
    "options": [
      {
        "text": "制定详细计划并按计划执行",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "保持灵活性，随机应变",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 74,
    "title": "对于任务，你倾向于：",
    "sortOrder": 73,
    "options": [
      {
        "text": "提前完成，避免最后时刻的紧张",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "在截止日期前完成，享受紧迫感",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 75,
    "title": "你的书桌或房间通常是：",
    "sortOrder": 74,
    "options": [
      {
        "text": "整洁有序，物品摆放有规律",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "相对随意，使用方便即可",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 76,
    "title": "在旅行时，你更喜欢：",
    "sortOrder": 75,
    "options": [
      {
        "text": "提前规划行程和预订",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "随性而为，到时再决定",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 77,
    "title": "面对新任务，你倾向于：",
    "sortOrder": 76,
    "options": [
      {
        "text": "立即开始行动",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "收集更多信息后再开始",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 78,
    "title": "你更喜欢的日常生活是：",
    "sortOrder": 77,
    "options": [
      {
        "text": "按部就班，保持规律",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "追求新鲜，尝试变化",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 79,
    "title": "在完成项目时，你更倾向于：",
    "sortOrder": 78,
    "options": [
      {
        "text": "提前规划，按时完成",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "在压力下工作效率更高",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 80,
    "title": "你更看重：",
    "sortOrder": 79,
    "options": [
      {
        "text": "计划和确定性",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "灵活和可能性",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 81,
    "title": "当计划被打乱时，你会：",
    "sortOrder": 80,
    "options": [
      {
        "text": "感到不适，想尽快调整",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "坦然接受，灵活应对",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 82,
    "title": "你更倾向于：",
    "sortOrder": 81,
    "options": [
      {
        "text": "把事情安排得井井有条",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "顺其自然，见机行事",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 83,
    "title": "在会议中，你更希望：",
    "sortOrder": 82,
    "options": [
      {
        "text": "有明确的议程和时间安排",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "开放式讨论，自由发挥",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 84,
    "title": "你认为自己是一个：",
    "sortOrder": 83,
    "options": [
      {
        "text": "有计划、有条理的人",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "随性、灵活的人",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 85,
    "title": "对待截止日期，你更倾向于：",
    "sortOrder": 84,
    "options": [
      {
        "text": "提前很久完成",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "在截止前一刻完成",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 86,
    "title": "你更不喜欢的场景是：",
    "sortOrder": 85,
    "options": [
      {
        "text": "计划被打乱、充满变数",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "过于死板、缺乏灵活性",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 87,
    "title": "在做决定时，你更倾向于：",
    "sortOrder": 86,
    "options": [
      {
        "text": "尽快做出决定",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "保留更多选择，暂不决定",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 88,
    "title": "你更喜欢的周末安排是：",
    "sortOrder": 87,
    "options": [
      {
        "text": "提前计划好的活动",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "看心情决定做什么",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 89,
    "title": "对于规则，你更倾向于：",
    "sortOrder": 88,
    "options": [
      {
        "text": "遵守规则，按规章办事",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "根据情况灵活处理",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 90,
    "title": "你更擅长：",
    "sortOrder": 89,
    "options": [
      {
        "text": "制定计划并执行",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "应对变化和突发情况",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 91,
    "title": "你更欣赏：",
    "sortOrder": 90,
    "options": [
      {
        "text": "有始有终、善始善终的人",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "思维活跃、创意不断的人",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 92,
    "title": "在处理多件事情时，你更倾向于：",
    "sortOrder": 91,
    "options": [
      {
        "text": "一件一件按顺序完成",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "同时处理，灵活切换",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 93,
    "title": "你更看重的结果是：",
    "sortOrder": 92,
    "options": [
      {
        "text": "按计划达成目标",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "享受过程中的发现",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  },
  {
    "id": 94,
    "title": "对于未来，你更倾向于：",
    "sortOrder": 93,
    "options": [
      {
        "text": "有明确的规划和目标",
        "type": "J",
        "score": 1,
        "order": 0
      },
      {
        "text": "保持开放，顺其自然",
        "type": "P",
        "score": 1,
        "order": 1
      }
    ]
  }
]

export const PERSONALITY_TYPES = {
  "INTJ": {
    "code": "INTJ",
    "name": "建筑师",
    "emoji": "建",
    "group": "NT",
    "groupLabel": "分析家",
    "color": "#7F77DD",
    "summary": "富有想象力和战略性的思想家，一切皆在计划之中。",
    "desc": "富有想象力和战略性的思想家，一切皆在计划之中。",
    "strengths": [
      "战略思维",
      "独立思考",
      "意志坚定",
      "追求卓越",
      "善于规划"
    ],
    "weaknesses": [
      "过于完美",
      "不善社交",
      "容易固执",
      "情感表达少",
      "过于挑剔"
    ],
    "careers": [
      "科学家",
      "工程师",
      "系统分析师",
      "战略顾问",
      "投资分析师"
    ]
  },
  "INTP": {
    "code": "INTP",
    "name": "逻辑学家",
    "emoji": "逻",
    "group": "NT",
    "groupLabel": "分析家",
    "color": "#7F77DD",
    "summary": "富有创造力的发明家，对知识有着永不满足的渴望。",
    "desc": "富有创造力的发明家，对知识有着永不满足的渴望。",
    "strengths": [
      "逻辑分析",
      "创新思维",
      "客观公正",
      "求知欲强",
      "善于解决复杂问题"
    ],
    "weaknesses": [
      "脱离现实",
      "不善表达",
      "拖延倾向",
      "过于理论化",
      "缺乏耐心"
    ],
    "careers": [
      "哲学家",
      "科学家",
      "程序员",
      "数学家",
      "研究员"
    ]
  },
  "ENTJ": {
    "code": "ENTJ",
    "name": "指挥官",
    "emoji": "指",
    "group": "NT",
    "groupLabel": "分析家",
    "color": "#7F77DD",
    "summary": "大胆、富有想象力的领导者，总能找到解决问题的方法。",
    "desc": "大胆、富有想象力的领导者，总能找到解决问题的方法。",
    "strengths": [
      "领导才能",
      "决策果断",
      "自信坚定",
      "效率至上",
      "善于激励他人"
    ],
    "weaknesses": [
      "控制欲强",
      "缺乏耐心",
      "忽视情感",
      "过于强势",
      "不善妥协"
    ],
    "careers": [
      "企业高管",
      "律师",
      "项目经理",
      "创业者",
      "管理咨询顾问"
    ]
  },
  "ENTP": {
    "code": "ENTP",
    "name": "辩论家",
    "emoji": "辩",
    "group": "NT",
    "groupLabel": "分析家",
    "color": "#7F77DD",
    "summary": "聪明好奇的思想家，无法抗拒智力上的挑战。",
    "desc": "聪明好奇的思想家，无法抗拒智力上的挑战。",
    "strengths": [
      "思维敏捷",
      "善于辩论",
      "创新能力强",
      "适应力好",
      "多才多艺"
    ],
    "weaknesses": [
      "喜欢争论",
      "缺乏耐心",
      "难以专注",
      "忽视细节",
      "容易厌倦"
    ],
    "careers": [
      "律师",
      "记者",
      "创业者",
      "营销专家",
      "产品经理"
    ]
  },
  "INFJ": {
    "code": "INFJ",
    "name": "提倡者",
    "emoji": "提",
    "group": "NF",
    "groupLabel": "外交家",
    "color": "#1D9E75",
    "summary": "安静而有影响力，具有理想主义色彩，致力于帮助他人。",
    "desc": "安静而有影响力，具有理想主义色彩，致力于帮助他人。",
    "strengths": [
      "洞察力强",
      "富有同情心",
      "追求意义",
      "理想主义",
      "善于理解他人"
    ],
    "weaknesses": [
      "过于完美",
      "容易倦怠",
      "不善拒绝",
      "敏感脆弱",
      "难以释怀"
    ],
    "careers": [
      "心理咨询师",
      "作家",
      "教育工作者",
      "社会工作者",
      "非营利组织管理者"
    ]
  },
  "INFP": {
    "code": "INFP",
    "name": "调解员",
    "emoji": "调",
    "group": "NF",
    "groupLabel": "外交家",
    "color": "#1D9E75",
    "summary": "诗意、善良的利他主义者，总是渴望帮助良善之事。",
    "desc": "诗意、善良的利他主义者，总是渴望帮助良善之事。",
    "strengths": [
      "创意丰富",
      "富有同理心",
      "价值观坚定",
      "善于倾听",
      "追求和谐"
    ],
    "weaknesses": [
      "过于理想化",
      "不善实际",
      "敏感易伤",
      "拖延倾向",
      "难以承受批评"
    ],
    "careers": [
      "作家",
      "艺术家",
      "心理咨询师",
      "设计师",
      "社会工作者"
    ]
  },
  "ENFJ": {
    "code": "ENFJ",
    "name": "主人公",
    "emoji": "主",
    "group": "NF",
    "groupLabel": "外交家",
    "color": "#1D9E75",
    "summary": "富有魅力的激励者，能够引领听众走向美好明天。",
    "desc": "富有魅力的激励者，能够引领听众走向美好明天。",
    "strengths": [
      "领导才能",
      "善于沟通",
      "富有同理心",
      "鼓舞他人",
      "有魅力"
    ],
    "weaknesses": [
      "过于理想化",
      "忽视自己",
      "敏感脆弱",
      "控制欲强",
      "难以接受批评"
    ],
    "careers": [
      "教师",
      "咨询师",
      "公关专家",
      "人力资源经理",
      "培训师"
    ]
  },
  "ENFP": {
    "code": "ENFP",
    "name": "竞选者",
    "emoji": "竞",
    "group": "NF",
    "groupLabel": "外交家",
    "color": "#1D9E75",
    "summary": "热情、富有创造力的社交达人，总能找到理由微笑。",
    "desc": "热情、富有创造力的社交达人，总能找到理由微笑。",
    "strengths": [
      "热情洋溢",
      "创意无限",
      "善于交际",
      "乐观积极",
      "适应力强"
    ],
    "weaknesses": [
      "注意力分散",
      "容易厌倦",
      "过度理想化",
      "情绪化",
      "缺乏坚持"
    ],
    "careers": [
      "记者",
      "演员",
      "营销专员",
      "创意总监",
      "创业者"
    ]
  },
  "ISTJ": {
    "code": "ISTJ",
    "name": "物流师",
    "emoji": "物",
    "group": "SJ",
    "groupLabel": "守卫者",
    "color": "#378ADD",
    "summary": "务实、专注于事实的个体，其可靠性不容置疑。",
    "desc": "务实、专注于事实的个体，其可靠性不容置疑。",
    "strengths": [
      "责任心强",
      "细致认真",
      "值得信赖",
      "有条不紊",
      "注重细节"
    ],
    "weaknesses": [
      "固执己见",
      "不善变通",
      "情感表达少",
      "过于保守",
      "不喜欢变化"
    ],
    "careers": [
      "会计师",
      "审计师",
      "行政人员",
      "法官",
      "项目经理"
    ]
  },
  "ISFJ": {
    "code": "ISFJ",
    "name": "守卫者",
    "emoji": "守",
    "group": "SJ",
    "groupLabel": "守卫者",
    "color": "#378ADD",
    "summary": "非常专注和温暖的守护者，时刻准备保护所爱之人。",
    "desc": "非常专注和温暖的守护者，时刻准备保护所爱之人。",
    "strengths": [
      "忠诚可靠",
      "细心体贴",
      "记忆力强",
      "勤勉尽责",
      "善于照顾他人"
    ],
    "weaknesses": [
      "过于谦虚",
      "不善拒绝",
      "回避冲突",
      "压抑情感",
      "过度付出"
    ],
    "careers": [
      "护士",
      "教师",
      "行政助理",
      "社会工作者",
      "人力资源专员"
    ]
  },
  "ESTJ": {
    "code": "ESTJ",
    "name": "总经理",
    "emoji": "总",
    "group": "SJ",
    "groupLabel": "守卫者",
    "color": "#378ADD",
    "summary": "出色的管理者，在管理事务和人员方面无与伦比。",
    "desc": "出色的管理者，在管理事务和人员方面无与伦比。",
    "strengths": [
      "组织能力强",
      "执行力高",
      "责任心重",
      "值得信赖",
      "善于管理"
    ],
    "weaknesses": [
      "固执己见",
      "缺乏耐心",
      "不善倾听",
      "过于强势",
      "缺乏灵活性"
    ],
    "careers": [
      "企业经理",
      "法官",
      "财务主管",
      "军官",
      "项目总监"
    ]
  },
  "ESFJ": {
    "code": "ESFJ",
    "name": "执政官",
    "emoji": "执",
    "group": "SJ",
    "groupLabel": "守卫者",
    "color": "#378ADD",
    "summary": "极具同情心、爱交际的人，总是热心帮助他人。",
    "desc": "极具同情心、爱交际的人，总是热心帮助他人。",
    "strengths": [
      "善于社交",
      "乐于助人",
      "忠诚可靠",
      "组织能力强",
      "关心他人"
    ],
    "weaknesses": [
      "过于在意他人看法",
      "不善接受批评",
      "自我牺牲",
      "缺乏灵活性",
      "容易受伤"
    ],
    "careers": [
      "护士",
      "教师",
      "销售代表",
      "活动策划师",
      "客服经理"
    ]
  },
  "ISTP": {
    "code": "ISTP",
    "name": "鉴赏家",
    "emoji": "鉴",
    "group": "SP",
    "groupLabel": "探索者",
    "color": "#EF9F27",
    "summary": "大胆而实际的实验家，善于使用各种工具。",
    "desc": "大胆而实际的实验家，善于使用各种工具。",
    "strengths": [
      "动手能力强",
      "冷静理性",
      "适应力好",
      "解决问题能力强",
      "善于分析"
    ],
    "weaknesses": [
      "情感表达少",
      "容易厌倦",
      "不善承诺",
      "过于独立",
      "缺乏耐心"
    ],
    "careers": [
      "工程师",
      "技师",
      "飞行员",
      "运动员",
      "技术专家"
    ]
  },
  "ISFP": {
    "code": "ISFP",
    "name": "探险家",
    "emoji": "探",
    "group": "SP",
    "groupLabel": "探索者",
    "color": "#EF9F27",
    "summary": "灵活而有魅力的艺术家，时刻准备探索和体验新事物。",
    "desc": "灵活而有魅力的艺术家，时刻准备探索和体验新事物。",
    "strengths": [
      "艺术天赋",
      "适应力强",
      "温和友善",
      "观察力敏锐",
      "审美能力强"
    ],
    "weaknesses": [
      "竞争心弱",
      "计划性差",
      "过于敏感",
      "不善表达",
      "容易逃避冲突"
    ],
    "careers": [
      "艺术家",
      "设计师",
      "厨师",
      "摄影师",
      "音乐家"
    ]
  },
  "ESTP": {
    "code": "ESTP",
    "name": "企业家",
    "emoji": "企",
    "group": "SP",
    "groupLabel": "探索者",
    "color": "#EF9F27",
    "summary": "聪明、精力充沛、善于感知的人，真正享受生活边缘。",
    "desc": "聪明、精力充沛、善于感知的人，真正享受生活边缘。",
    "strengths": [
      "行动力强",
      "适应力好",
      "善于社交",
      "危机处理能力强",
      "观察力敏锐"
    ],
    "weaknesses": [
      "缺乏耐心",
      "不善规划",
      "冒险倾向",
      "忽视情感",
      "容易厌倦"
    ],
    "careers": [
      "销售代表",
      "运动员",
      "急救人员",
      "企业家",
      "投资交易员"
    ]
  },
  "ESFP": {
    "code": "ESFP",
    "name": "表演者",
    "emoji": "表",
    "group": "SP",
    "groupLabel": "探索者",
    "color": "#EF9F27",
    "summary": "自发的、精力充沛的艺人，生活永远不会无聊。",
    "desc": "自发的、精力充沛的艺人，生活永远不会无聊。",
    "strengths": [
      "热情洋溢",
      "善于交际",
      "适应力强",
      "乐观积极",
      "善于娱乐他人"
    ],
    "weaknesses": [
      "缺乏计划",
      "逃避困难",
      "注意力分散",
      "过于冲动",
      "不善长期规划"
    ],
    "careers": [
      "演员",
      "主持人",
      "销售代表",
      "活动策划师",
      "旅游顾问"
    ]
  }
}

export const DIMENSION_PAIRS = [
  {
    "key": "EI",
    "left": "E",
    "right": "I",
    "label": "精力来源",
    "leftName": "外向",
    "rightName": "内向",
    "color": "#FF9DB4"
  },
  {
    "key": "SN",
    "left": "S",
    "right": "N",
    "label": "信息获取",
    "leftName": "实感",
    "rightName": "直觉",
    "color": "#8FB8FF"
  },
  {
    "key": "TF",
    "left": "T",
    "right": "F",
    "label": "决策方式",
    "leftName": "思考",
    "rightName": "情感",
    "color": "#8FD6C2"
  },
  {
    "key": "JP",
    "left": "J",
    "right": "P",
    "label": "生活态度",
    "leftName": "判断",
    "rightName": "感知",
    "color": "#FFC46B"
  }
]
/**
 * 把后端返回的题目转换成前端统一格式。
 * 后端返回 { id, content, options: [{ id, content, dimensionCode, score }] }，
 * 这里统一拍平成 { id, title, options: [{ text, type, score }] }，
 * 让本地题和后端题在页面里长得一模一样，算分逻辑不用分两套。
 */
export function normalizeRemoteQuestion(raw) {
  if (!raw || !raw.content) return null
  const options = (raw.options || []).map((o) => ({
    text: o.content,
    type: o.dimensionCode,
    score: o.score != null ? o.score : 1,
    optionId: o.id
  }))
  if (options.length < 2) return null
  return {
    id: raw.id,
    title: raw.content,
    options,
    fromServer: true
  }
}
