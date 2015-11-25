/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaService : NSObject

/**
 * 启动服务。
 * @return 如果启动成功则返回YES；否则返回NO。
 */
- (BOOL)start;

/**
 * 停止服务。
 * @return 如果停止成功则返回YES；否则返回NO。
 */
- (BOOL)stop;

@end
