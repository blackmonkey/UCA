/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#ifndef __UCA_CONSTANTS_H__
#define __UCA_CONSTANTS_H__

#undef NOT_SAVED
#define NOT_SAVED (-1)

#undef ORG_CONTACT_ID
#define ORG_CONTACT_ID (-2)

#undef SYS_MSG_CONTACT_ID
#define SYS_MSG_CONTACT_ID (-3)

#undef VOICE_MAIL_CONTACT_ID
#define VOICE_MAIL_CONTACT_ID (-4)

/**
 * Default application background color RGB:239, 244, 255
 */
#undef APP_BGCOLOR
#define APP_BGCOLOR [UIColor clearColor]

#undef GROUP_TABLE_CELL_TEXTFIELD_FRAME
#define GROUP_TABLE_CELL_TEXTFIELD_FRAME CGRectMake(5, 5, 290, 34)

#undef GROUP_TABLE_NARROW_CELL_TEXTFIELD_FRAME
#define GROUP_TABLE_NARROW_CELL_TEXTFIELD_FRAME CGRectMake(5, 5, 180, 34)

/**
 * 登录状态
 */
typedef enum {
    LoginStatus_UnLoggedIn,             // 未登录
    LoginStatus_Logging,                // 正在登录
    LoginStatus_LoggedIn,               // 登录成功
    LoginStatus_LoginFailed,            // 登录失败
    LoginStatus_LoginFailed_MultiLogin, // 登录失败：多帐号登录
    LoginStatus_LoginFailed_SoapError,  // 登录失败：Soap访问错误
    LoginStatus_LoginFailed_BadAuth,    // 登录失败：用户名或密码错误
    LoginStatus_LoginFailed_BadParam,   // 登录失败：参数错误
    LoginStatus_LoginFailed_NoNetwork,  // 登录失败：网络不可达
    LoginStatus_LoggingOut,             // 正在退出
    LoginStatus_LoggedOut,              // 退出成功
    LoginStatus_LogoutFailed            // 退出失败
} LoginStatus;

/**
 * 联系人类型
 */
typedef enum {
    ContactType_Unknown,       // 未知(最近)联系人，组织架构、群组、多人会话中的联系人
    ContactType_AddressBook,   // 本地联系人
    ContactType_Friend,        // 好友
    ContactType_Private,       // 私有联系人
    ContactType_Group,         // 群组
    ContactType_Session,       // 多人会话
} ContactType;

/**
 * 通讯记录类型
 */
typedef enum {
    RecentLogType_Voice_Accepted,
    RecentLogType_Voice_DialedOut,
    RecentLogType_Voice_Missed,
    RecentLogType_Video_Accepted,
    RecentLogType_Video_DialedOut,
    RecentLogType_Video_Missed
} RecentLogType;

@interface UcaLoginEvent : NSObject
@property (nonatomic) UCALIB_LOGIN_HANDLE handle;
@property (nonatomic) UCALIB_LOGIN_STATE state;
@property (nonatomic) UCALIB_ERRCODE result;
@end

@interface UcaAccountPresentationEvent : NSObject
@property (nonatomic) UCALIB_LOGIN_HANDLE handle;
@property (nonatomic) UCALIB_PRESENTATIONSTATE state;
@property (nonatomic) UCALIB_PRESENTATIONRESULT_CODE result;
@end

@interface UcaContactPresentationEvent : NSObject
@property (nonatomic) UCALIB_LOGIN_HANDLE handle;
@property (nonatomic, retain) NSString *uri;
@property (nonatomic) UCALIB_PRESENTATIONSTATE state;
@end

@interface UcaNativeImEvent : NSObject
@property (nonatomic) UCALIB_LOGIN_HANDLE handle;
@property (nonatomic, retain) NSString *senderSip;
@property (nonatomic, retain) NSString *receiverSip;
@property (nonatomic, retain) NSString *toWhomSip;
@property (nonatomic, retain) NSString *htmlMsg;
@end

@interface UcaCallStatusEvent : NSObject
@property (nonatomic) UCALIB_LOGIN_HANDLE handle;
@property (nonatomic) int callId;
@property (nonatomic) UCALIB_CALL_STATUS status;
@property (nonatomic, retain) NSString *peerUri;
@property (nonatomic, retain) NSString *param;
@end

@interface UcaSfpStatusEvent : NSObject
@property (nonatomic, retain) NSString *peerUri;
@property (nonatomic, retain) NSString *fullPath;
@end

@interface ContactPresence : NSObject
@property (nonatomic) NSInteger userId;
@property (nonatomic) UCALIB_PRESENTATIONSTATE state;
@property (nonatomic) BOOL cameraOn;
@property (nonatomic) BOOL mailboxOn;
@property (nonatomic, retain) NSString *domain;
@end

@interface GroupChangeInfo : NSObject
@property (nonatomic, assign) NSInteger groupId;
@property (nonatomic, assign) NSUInteger userCount;
@property (nonatomic, retain) NSString *groupSipPhone;
@property (nonatomic, retain) NSMutableArray *kickedUserSip;
@property (nonatomic, retain) NSMutableArray *presentUserSip;
@end

@interface UcaSessionStatusEvent : NSObject
@property (nonatomic, assign) NSInteger chatId;
@property (nonatomic, retain) NSString *sessionSipPhone;
@property (nonatomic, assign) UCALIB_CHAT_STATUS status;
@property (nonatomic, assign) UCALIB_CHAT_ERRCODE errcode;
@property (nonatomic, assign) const void *param;
@end

/**
 * UcaConstants提供常量相关的工具函数。
 */
@interface UcaConstants : NSObject

/**
 * 获取登录状态文字描述。
 */
+ (NSString *)descriptionOfLoginStatus:(LoginStatus)status;

/**
 * 获取呈现状态文字描述。
 */
+ (NSString *)descriptionOfPresentation:(UCALIB_PRESENTATIONSTATE)presentation;

/**
 * 从呈现状态文字描述获取呈现状态。
 */
+ (UCALIB_PRESENTATIONSTATE)presentationFromDescription:(NSString *)descrip;

/**
 * 获取所有呈现状态文字描述。
 */
+ (NSArray *)descriptionOfAllPresentations;

/**
 * 获取呈现状态图标。
 */
+ (UIImage *)iconOfPresentation:(UCALIB_PRESENTATIONSTATE)presentation;

/**
 * 获取所有呈现状态图标。
 */
+ (NSArray *)iconOfAllPresentations;

/**
 * 获取性别文字描述。
 */
+ (NSString *)descriptionOfGender:(BOOL)isFemale;

/**
 * 获取所有性别文字描述。
 */
+ (NSArray *)descriptionOfGenders;

/**
 * 获取通讯记录类型图标。
 */
+ (UIImage *)iconOfRecentLogType:(RecentLogType)logType;

+ (NSString *)descriptionOfRecentLogType:(RecentLogType)logType;

+ (NSString *)textOfCallStatus:(UCALIB_CALL_STATUS)status;

@end

#endif
