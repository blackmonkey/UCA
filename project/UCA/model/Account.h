/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "ServerParam.h"

/**
 * Account记录帐号相关信息
 */
@interface Account : Person

/** 本地记录的属性(记录于数据表Account中) */
@property (nonatomic, retain) ServerParam *serverParam;  // 服务器信息
@property (nonatomic, assign) BOOL rememberPassword;     // 是否记住帐号密码

/** 服务器提供的帐号属性(记录于数据表Account中) */
@property (nonatomic, retain) NSString *password;        // 帐号密码
@property (nonatomic, retain) NSString *serverDomain;    // 服务器域名(只读)
@property (nonatomic, retain) NSString *customHisotlogy; // 组织架构公司名称(只读)
@property (nonatomic, retain) Privilege *privileges;     // 服务器权限

@end
