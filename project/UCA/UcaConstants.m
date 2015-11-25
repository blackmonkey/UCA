/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation UcaLoginEvent
@synthesize handle;
@synthesize state;
@synthesize result;
@end

@implementation UcaAccountPresentationEvent
@synthesize handle;
@synthesize state;
@synthesize result;
@end

@implementation UcaContactPresentationEvent
@synthesize handle;
@synthesize uri;
@synthesize state;
@end

@implementation UcaNativeImEvent
@synthesize handle;
@synthesize senderSip;
@synthesize receiverSip;
@synthesize toWhomSip;
@synthesize htmlMsg;
@end

@implementation UcaCallStatusEvent
@synthesize handle;
@synthesize callId;
@synthesize status;
@synthesize peerUri;
@synthesize param;
@end

@implementation UcaSfpStatusEvent
@synthesize peerUri;
@synthesize fullPath;
@end

@implementation ContactPresence
@synthesize userId;
@synthesize state;
@synthesize cameraOn;
@synthesize mailboxOn;
@synthesize domain;

- (id)init {
    self = [super init];
    if (self) {
        self.userId = NOT_SAVED;
        self.state = UCALIB_PRESENTATIONSTATE_OFFLINE;
        self.cameraOn = NO;
        self.mailboxOn = NO;
    }
    return self;
}

@end

@implementation GroupChangeInfo
@synthesize groupId;
@synthesize userCount;
@synthesize groupSipPhone;
@synthesize kickedUserSip;
@synthesize presentUserSip;
@end

@implementation UcaSessionStatusEvent
@synthesize chatId;
@synthesize sessionSipPhone;
@synthesize status;
@synthesize errcode;
@synthesize param;
@end

@implementation UcaConstants

+ (NSString *)descriptionOfLoginStatus:(LoginStatus)status {
    NSString *desp = nil;
    switch (status) {
    case LoginStatus_Logging:
        desp = @"正在登录……";
        break;
    case LoginStatus_LoggedIn:
        desp = @"已登录";
        break;
    case LoginStatus_LoginFailed:
        desp = @"登录失败，请稍后重试。";
        break;
    case LoginStatus_LoginFailed_MultiLogin:
        desp = @"同时只允许登录一个帐号，请退出之前登录的帐号。";
        break;
    case LoginStatus_LoginFailed_SoapError:
        desp = @"Soap访问错误，请稍后重试。";
        break;
    case LoginStatus_LoginFailed_BadAuth:
        desp = @"用户名或密码错误，请检查用户名或密码。";
        break;
    case LoginStatus_LoginFailed_BadParam:
        desp = @"参数错误。";
        break;
    case LoginStatus_LoginFailed_NoNetwork:
        desp = @"网络不可达。";
        break;
    case LoginStatus_LoggingOut:
        desp = @"正在退出……";
        break;
    case LoginStatus_LoggedOut:
        desp = @"已退出";
        break;
    case LoginStatus_LogoutFailed:
        desp = @"退出失败，请稍后重试。";
        break;
    case LoginStatus_UnLoggedIn:
    default:
        desp = @"未登录";
        break;
    }
    return I18nString(desp);
}

+ (NSString *)descriptionOfPresentation:(UCALIB_PRESENTATIONSTATE)presentation {
    NSString *desp = nil;
    switch (presentation) {
    case UCALIB_PRESENTATIONSTATE_ONLINE:
        desp = @"在线";
        break;
    case UCALIB_PRESENTATIONSTATE_AWAY:
        desp = @"离开";
        break;
    case UCALIB_PRESENTATIONSTATE_BUSY:
        desp = @"忙碌";
        break;
    case UCALIB_PRESENTATIONSTATE_MEETING:
        desp = @"会议中";
        break;
    case UCALIB_PRESENTATIONSTATE_DONTBREAK:
        desp = @"免扰";
        break;
    default:
        desp = @"离线";
        break;
    }
    return I18nString(desp);
}

+ (UCALIB_PRESENTATIONSTATE)presentationFromDescription:(NSString *)descrip {
    if ([descrip isEqualToString:@"Online"]) {
        return UCALIB_PRESENTATIONSTATE_ONLINE;
    } else if ([descrip isEqualToString:@"Away"]) {
        return UCALIB_PRESENTATIONSTATE_AWAY;
    } else if ([descrip isEqualToString:@"Busy"]) {
        return UCALIB_PRESENTATIONSTATE_BUSY;
    } else if ([descrip isEqualToString:@"Onconference"]) {
        return UCALIB_PRESENTATIONSTATE_MEETING;
    }
    return UCALIB_PRESENTATIONSTATE_OFFLINE;
}

+ (NSArray *)descriptionOfAllPresentations {
    return [NSArray arrayWithObjects:I18nString(@"在线"),
                                     I18nString(@"离开"),
                                     I18nString(@"忙碌"),
                                     I18nString(@"会议中"),
                                     I18nString(@"免扰"),
                                     I18nString(@"离线"), nil];
}

+ (UIImage *)iconOfPresentation:(UCALIB_PRESENTATIONSTATE)presentation {
    switch (presentation) {
    case UCALIB_PRESENTATIONSTATE_ONLINE:
        return [UIImage imageNamed:@"res/status_online"];
    case UCALIB_PRESENTATIONSTATE_AWAY:
        return [UIImage imageNamed:@"res/status_away"];
    case UCALIB_PRESENTATIONSTATE_BUSY:
        return [UIImage imageNamed:@"res/status_busy"];
    case UCALIB_PRESENTATIONSTATE_MEETING:
        return [UIImage imageNamed:@"res/status_meeting"];
    case UCALIB_PRESENTATIONSTATE_DONTBREAK:
        return [UIImage imageNamed:@"res/status_dontbreak"];
    default:
        return [UIImage imageNamed:@"res/status_offline"];
    }
}

+ (NSArray *)iconOfAllPresentations {
    return [NSArray arrayWithObjects:[UIImage imageNamed:@"res/status_online"],
                                     [UIImage imageNamed:@"res/status_away"],
                                     [UIImage imageNamed:@"res/status_busy"],
                                     [UIImage imageNamed:@"res/status_meeting"],
                                     [UIImage imageNamed:@"res/status_dontbreak"],
                                     [UIImage imageNamed:@"res/status_offline"], nil];
}

+ (NSString *)descriptionOfGender:(BOOL)isFemale {
    return (isFemale ? I18nString(@"女") : I18nString(@"男"));
}

+ (NSArray *)descriptionOfGenders {
    return [NSArray arrayWithObjects:I18nString(@"男"), I18nString(@"女"), nil];
}

+ (UIImage *)iconOfRecentLogType:(RecentLogType)logType {
    switch (logType) {
    case RecentLogType_Voice_Accepted:
        return [UIImage imageNamed:@"res/calls_answered"];
    case RecentLogType_Voice_DialedOut:
        return [UIImage imageNamed:@"res/calls_dialed"];
    case RecentLogType_Voice_Missed:
        return [UIImage imageNamed:@"res/calls_missed"];
    case RecentLogType_Video_Accepted:
        return [UIImage imageNamed:@"res/video_answered"];
    case RecentLogType_Video_DialedOut:
        return [UIImage imageNamed:@"res/video_dialed"];
    case RecentLogType_Video_Missed:
        return [UIImage imageNamed:@"res/video_missed"];
    default:
        return nil;
    }
}

+ (NSString *)descriptionOfRecentLogType:(RecentLogType)logType {
    switch (logType) {
    case RecentLogType_Voice_Accepted:
        return I18nString(@"已接来电");
    case RecentLogType_Voice_DialedOut:
        return I18nString(@"拨出电话");
    case RecentLogType_Voice_Missed:
        return I18nString(@"未接来电");
    case RecentLogType_Video_Accepted:
        return I18nString(@"已接视频");
    case RecentLogType_Video_DialedOut:
        return I18nString(@"拨出视频");
    case RecentLogType_Video_Missed:
        return I18nString(@"未接视频");
    default:
        return nil;
    }
}

+ (NSString *)textOfCallStatus:(UCALIB_CALL_STATUS)status {
    switch (status) {
    case UCALIB_CALLSTATUS_IDLE                : return I18nString(@"空闲");
    case UCALIB_CALLSTATUS_INCOMING_RECEIVED   : return I18nString(@"来电");
    case UCALIB_CALLSTATUS_OUTGOING_INIT       : return I18nString(@"初始化连接");
    case UCALIB_CALLSTATUS_OUTGOING_PROGRESS   : return I18nString(@"连接中⋯⋯");
    case UCALIB_CALLSTATUS_OUTGOING_RINGING    : return I18nString(@"对方响铃中⋯⋯");
    case UCALIB_CALLSTATUS_CONNECTED           : return I18nString(@"通话建立");
    case UCALIB_CALLSTATUS_STREAMSRUNNING      : return I18nString(@"通话建立");
    case UCALIB_CALLSTATUS_PAUSING             : return I18nString(@"通话暂停中⋯⋯");
    case UCALIB_CALLSTATUS_PAUSED              : return I18nString(@"通话暂停");
    case UCALIB_CALLSTATUS_RESUMING            : return I18nString(@"通话恢复中⋯⋯");
    case UCALIB_CALLSTATUS_CALLEND             : return I18nString(@"呼叫结束");
    case UCALIB_CALLSTATUS_REFERED             : return I18nString(@"通话转移中⋯⋯");
    case UCALIB_CALLSTATUS_CALLERROR           : return I18nString(@"对方忙");
    default                                    : return nil;
    }
}

@end
