/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaRecentService : UcaService

/**
 * 添加最近通讯记录。
 * 如果通讯号码不在联系人数据表Contact中，则自动添加联系人记录。
 * 如果通讯号码在联系人数据表Contact中，则自动更新联系人访问时间。
 * @param recentLog 未保存的最近通讯记录。
 * @return 如果添加成功则返回YES；否则返回NO。
 */
- (BOOL)addRecentLog:(RecentLog *)recentLog;

/**
 * 批量删除最近通讯记录。
 * @param recentLogs 一个或多个最近通讯记录。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteRecentLogs:(NSArray *)recentLogs;

/**
 * 删除联系人的所有最近通讯记录。
 * @param contact 指定联系人。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteRecentLogsOfContact:(Contact *)contact;

/**
 * 批量设置最近未接电话记录为已读状态。
 * @param contact 指定联系人。
 * @return 如果设置成功则返回YES；否则返回NO。
 */
- (BOOL)clearMissedCallsOfContact:(Contact *)contact;

/**
 * 更新最近通话记录的类型。
 * @param recentLog 通话记录。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateRecentLogType:(RecentLog *)recentLog;

/**
 * 更新最近通话记录的时长。
 * @param recentLog 通话记录。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateRecentLogDuration:(RecentLog *)recentLog;

/**
 * 获取联系人的全部最近通讯记录。
 * @param contact 指定联系人。
 * @return 最近通讯记录。
 */
- (NSArray *)getRecentLogsOfContact:(Contact *)contact;

/**
 * 获取联系人的全部未接来电。
 * @param contact 指定联系人。
 * @return 最近通讯记录。
 */
- (NSArray *)getMissedCallsOfContact:(Contact *)contact;

@end
