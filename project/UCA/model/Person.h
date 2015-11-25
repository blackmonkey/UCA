/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * Person记录所有联系人和帐号共有的信息。
 */
@interface Person : NSObject

/** 本地记录的属性(不记录于数据表中) */
@property (nonatomic, assign) UCALIB_PRESENTATIONSTATE presentation; // 呈现状态
@property (readonly, retain) NSString *displayName;     // 显示于列表界面的全名

/** 本地记录的属性(记录于数据表中) */
@property (nonatomic, assign) NSInteger id;             // 数据库记录ID

/** 服务器提供的帐号属性(记录于数据表中) */
@property (nonatomic, assign) NSInteger userId;         // 用户Id
@property (nonatomic, retain) NSString *username;       // 帐号用户名
@property (nonatomic, retain) NSString *firstname;      // 姓名的前缀名
@property (nonatomic, retain) NSString *lastname;       // 姓名的后缀名
@property (nonatomic, retain) NSString *nickname;       // 昵称
@property (nonatomic, retain) NSArray *aliases;         // 别名，数据表中以","间隔保存。
@property (nonatomic, assign) BOOL isFemale;            // 性别
@property (nonatomic, retain) NSString *descrip;        // 个人描述
@property (nonatomic, retain) UIImage *photo;           // 个人头像
@property (nonatomic, retain) NSString *pin;            // 个人PIN码
@property (nonatomic, assign) NSInteger groupId;        // 所属工作组Id
@property (nonatomic, retain) NSArray *groups;          // 所属的分组，数据表中以","间隔保存。
@property (nonatomic, assign) NSInteger callMode;       // 呼叫模式
@property (nonatomic, retain) NSString *sipPhone;       // sip号码
@property (nonatomic, retain) NSString *workPhone;      // 工作号码
@property (nonatomic, retain) NSString *familyPhone;    // 家庭号码
@property (nonatomic, retain) NSString *mobilePhone;    // 联系电话一
@property (nonatomic, retain) NSString *mobilePhone2;   // 联系电话二
@property (nonatomic, retain) NSString *otherPhone;     // 其他号码
@property (nonatomic, retain) NSString *email;          // 邮箱地址
@property (nonatomic, retain) NSString *voicemail;      // 语音邮箱号码
@property (nonatomic, retain) NSString *company;        // 公司名称
@property (nonatomic, retain) NSString *companyAddress; // 公司地址
@property (nonatomic, assign) NSInteger departId;       // 部门ID
@property (nonatomic, retain) NSString *departName;     // 部门名称
@property (nonatomic, retain) NSString *position;       // 职位
@property (nonatomic, retain) NSString *familyAddress;  // 家庭地址
@property (nonatomic, assign) BOOL showPersonalInfo;    // 是否显示私有信息

@end
