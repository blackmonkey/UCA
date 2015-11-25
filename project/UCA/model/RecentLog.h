/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * RecentLog记录通讯记录的信息。
 *
 * 通讯记录分拨出和接入两个方向。
 *
 * 拨出方向包括RecentLogType_Voice_DialedOut, RecentLogType_Video_DialedOut。
 *
 * 接入方向包括RecentLogType_Voice_Accepted, RecentLogType_Voice_Missed,
 * RecentLogType_Video_Accepted, RecentLogType_Video_Missed。
 *
 * 拨出方向的RecentLog.contactId记录的是远端接收者的信息，接入方向的
 * RecentLog.contactId记录的是远端发送者的信息。
 */
@interface RecentLog : NSObject

/** 记录于数据表RecentLog中的属性 */
@property (nonatomic, assign) NSInteger id;            // 数据库记录ID
@property (nonatomic, assign) NSInteger accountId;     // 通讯记录关联的帐号的数据库记录ID
@property (nonatomic, assign) NSInteger contactId;     // 通讯记录关联的联系人的数据库记录ID
@property (nonatomic, retain) NSString *number;        // 音视频通讯远端的电话号码，IM的内容。
@property (nonatomic, assign) RecentLogType type;      // 通讯记录类型
@property (nonatomic, retain) NSDate *datetime;        // 通讯记录发生的时间
@property (nonatomic, assign) NSTimeInterval duration; // 通讯记录持续的时间

/** 不记录于数据表RecentLog中的属性 */
@property (nonatomic, readonly, getter=isMissed) BOOL missed;    // 是否未接

@end
