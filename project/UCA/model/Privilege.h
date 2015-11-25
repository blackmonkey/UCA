/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * Privilege记录帐号的权限信息
 */
@interface Privilege : NSObject

@property (nonatomic, assign) BOOL superAdmin;           // 超级用户访问权限
@property (nonatomic, assign) BOOL intrusionBreakdown;   // 强插强拆权限
@property (nonatomic, assign) BOOL fileTransfers;        // 文件传输
@property (nonatomic, assign) NSInteger sendFileSize;    // 发送文件大小上限(KB)
@property (nonatomic, assign) NSInteger sendFileSpeed;   // 文件传输速率上限(KB)
@property (nonatomic, assign) BOOL voicemail;            // 语音邮箱
@property (nonatomic, assign) BOOL tuiChangePin;         // 通过语音邮件系统修改PIN码
@property (nonatomic, assign) BOOL recordSystemPrompts;  // 自动语音提示语录制
@property (nonatomic, assign) BOOL instantMessage;       // 即时消息
@property (nonatomic, assign) BOOL autoAttendant;        // 名字拨号
@property (nonatomic, assign) BOOL forwardCallsExternal; // 呼叫外线转移
@property (nonatomic, assign) BOOL meetingCreate;        // 会议创建
@property (nonatomic, assign) BOOL cooperateWith;        // 协同

/**
 * 初始化Privilege实例。
 * @param size 发送文件大小上限(KB)。
 * @param speed 文件传输速率上限(KB)。
 * @param other 其他权限编码。
 * @return Privilege实例。
 */
- (id)initWithSendSize:(NSInteger)size andSendSpeed:(NSInteger)speed andOther:(NSInteger)other;

/**
 * 解析从数据库中获取的其他权限编码。
 * @param other 其他权限编码。
 */
- (void)decodeOtherPrivilege:(NSInteger)other;

/**
 * 将其他权限编码为数据库相应字段的值。
 * @return 其他权限编码。
 */
- (NSInteger)encodeOtherPrivilege;

@end
