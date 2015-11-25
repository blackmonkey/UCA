/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * ServerParam记录服务器相关信息
 */
@interface ServerParam : NSObject

@property NSInteger id;          // 数据库记录ID
@property (strong) NSString *ip; // 服务器IP地址

@end
