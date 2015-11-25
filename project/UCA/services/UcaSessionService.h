/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaSessionService : UcaService

@property (nonatomic, retain) NSMutableArray *sessions;

/**
 * 创建多人会话。
 */
- (void)createSession;

/**
 * 关闭多人会话。
 * @param sessionId 多人会话ID。
 */
- (void)closeSession:(NSNumber *)sessionId;

/**
 * 将指定联系人添加到v。
 * @param contacts 联系人。
 * @param session 多人会话实例。
 */
- (void)addContacts:(NSArray *)contacts toSession:(Session *)session;

/**
 * 从多人会话中删除指定联系人。
 * @param contacts 联系人。
 * @param session 多人会话实例。
 */
- (void)removeMembers:(NSArray *)contacts fromSession:(Session *)session;

/**
 * 多人会话在创建时，只有一个ID，没有sipPhone地址信息。当添加了成员后，或成员发了IM信息时，
 * 多人会话的sipPhone才会通过相应事件采集到。此时需要同步一下本服务中缓存的Session实例。
 * @param contact Session实例对应的Contact实例。
 */
- (void)synchSessionWithContact:(Contact *)contact;

@end
