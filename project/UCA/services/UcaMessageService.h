/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaMessageService : UcaService

/**
 * 发送IM消息。
 * @param message 未保存的IM消息。
 */
- (void)sendMessage:(Message *)message;

/**
 * 将指定IM标记为已读。
 * @param msgId 指定IM消息的数据库记录ID。
 * @return 如果标记成功则返回YES；否则返回NO。
 */
- (BOOL)markMessageAsRead:(NSNumber *)msgId;

/**
 * 删除多条IM消息。
 * @param messages 指定IM消息。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteMessages:(NSArray *)messages;

/**
 * 发送单张图片。
 * @param messages 指定IM消息。
 * @return 如果发送成功则返回YES；否则返回NO。
 */
- (BOOL)sendImageMessage:(Message *)message;

/**
 * 获取当前帐号的未读IM消息数量。
 * @return 未读IM消息数量。
 */
- (NSUInteger)countOfUnreadMessages;

/**
 * 获取联系人发来的未读IM消息数量。
 * @param contact 指定联系人。
 * @return 未读IM消息数量。
 */
- (NSUInteger)countOfUnreadMessagesWithContact:(Contact *)contact;

/**
 * 获取联系人发来的未读IM消息数量。
 * @param contact 指定联系人。
 * @return 未读IM消息数量。
 */
- (NSUInteger)countOfMessagesWithContact:(Contact *)contact;

/**
 * 获取联系人相关的IM消息。
 * @param contact 指定联系人。
 * @return IM消息数组。
 */
- (NSArray *)messagesWithContact:(Contact *)contact;

/**
 * 获取联系人相关的IM消息。
 * @param contact 指定联系人。
 * @param timestamp 若为nil，则查询所有IM；否则，不包含该时间点前的IM。
 * @return IM消息数组。
 */
- (NSArray *)messagesWithContact:(Contact *)contact excludeBefore:(NSDate *)timestamp;

/**
 * 获取未读系统消息数量。
 * @return 未读系统消息数量。
 */
- (NSUInteger)countOfUnreadSystemMessages;

/**
 * 获取联系人发来的未读IM消息数量。
 * @param contactId 指定联系人ID。
 * @return 未读IM消息数量。
 */
- (NSUInteger)countOfSystemMessages;

/**
 * 获取联系人相关的IM消息。
 * @param contactId 指定联系人ID。
 * @return IM消息数组。
 */
- (NSArray *)systemMessages;

@end
