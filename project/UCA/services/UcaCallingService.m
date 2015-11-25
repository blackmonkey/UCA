/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaCallingService.h"
#import "UcaNavigationController.h"
#import "IncomingCallView.h"
#import "CallOutView.h"

#undef TAG
#define TAG @"UcaCallingService"

@interface UcaCallingService()
- (BOOL)isUnderPhoneCall;
@end

@implementation UcaCallingService {
    /**
     * 拨出或来电时，调用CallOutView、VoiceIncomingCallView等的起始界面。
     */
    UIViewController *_launchView;

    /**
     * CallOutView、VoiceIncomingCallView等界面是否以Modal View方式加载。
     * 来电时，该值为YES；拨出时，该值为NO。
     */
    BOOL _launchAsModalView;

    NSDate *_callBegin;
    BOOL _canSwitchCamera;
    BOOL _isVideoCall;
    NSInteger _curCameraId;
    int _curCallId;
    UCALIB_CALL_STATUS _curCallStatus;
    RecentLog *_curCallLog;
}

@synthesize curCallStatusText;
@synthesize callDuration;

/**
 * 更新电话号码相关的联系人访问时间。
 * @return 第一个更新的联系人。
 */
- (Contact *)touchContactBySipPhone:(NSString *)sipPhone {
    UcaContactService *service = [UcaAppDelegate sharedInstance].contactService;
    Contact *contact = [service touchContactBySipPhone:sipPhone withTimestamp:[NSDate date]];
    return contact;
}

- (void)saveCallDurationIntoDb {
    if (_callBegin && _curCallLog) {
        _curCallLog.duration = -[_callBegin timeIntervalSinceNow];
        [[UcaAppDelegate sharedInstance].recentService updateRecentLogDuration:_curCallLog];
    }
}

- (RecentLog *)addMissedCallOfContact:(NSInteger)contactId
                           fromNumber:(NSString *)number
                             hasVideo:(BOOL)hasVidoe {
    RecentLog *log = [[RecentLog alloc] init];
    log.contactId = contactId;
    log.number = number;
    log.type = hasVidoe ? RecentLogType_Video_Missed : RecentLogType_Voice_Missed;
    [[UcaAppDelegate sharedInstance].recentService addRecentLog:log];
    return log;
}

- (void)onCallStatus:(NSNotification *)note {
    UcaCallStatusEvent *callEvent = note.object;

    UcaLog(TAG, @"phone call of %@, _curCallId = %d, callEvent.callId = %d", callEvent.peerUri, _curCallId, callEvent.callId);

    NSString *number = [callEvent.peerUri strimmedSipPhone];
    Contact *contact = [self touchContactBySipPhone:number];

    BOOL hasVideo = NO;
    if (![NSString isNullOrEmpty:callEvent.param]) {
        hasVideo = [[callEvent.param lowercaseString] containsSubstring:@"video"];
    }


    if ([self isUnderPhoneCall] && callEvent.status == UCALIB_CALLSTATUS_INCOMING_RECEIVED) {
        UcaLog(TAG, @"Auto refuse incoming call due to busy");
        ucaLib_CallCancel(callEvent.handle, callEvent.callId);

        [self addMissedCallOfContact:contact.id
                          fromNumber:number
                            hasVideo:hasVideo];
        return;
    }

    if (_curCallId != NOT_SAVED && _curCallId != callEvent.callId) {
        UcaLog(TAG, @"Auto refuse incoming call due to busy, callback");
        [self addMissedCallOfContact:contact.id
                          fromNumber:number
                            hasVideo:hasVideo];
        return;
    }

    _curCallId = callEvent.callId;
    _curCallStatus = callEvent.status;

    [NotifyUtils postNotificationWithName:UCA_INDICATE_CALL_STATUS_TEXT
                                   object:[NSNumber numberWithInteger:callEvent.status]];

    if (callEvent.status == UCALIB_CALLSTATUS_CALLEND
        || callEvent.status == UCALIB_CALLSTATUS_CALLERROR) {
        if (_launchAsModalView) {
            [_launchView dismissModalViewControllerAnimated:YES];
        } else {
            [_launchView.navigationController popToViewController:_launchView animated:YES];
        }

        if (_curCallLog && _curCallLog.type != RecentLogType_Voice_Missed
            && _curCallLog.type != RecentLogType_Video_Missed) {
            [self saveCallDurationIntoDb];
        }

        _launchAsModalView = NO;
        _launchView = nil;
        _callBegin = nil;
        _isVideoCall = NO;
        _curCallStatus = UCALIB_CALLSTATUS_IDLE;
        _curCallId = NOT_SAVED;
        _curCallLog = nil;
    }

    if (callEvent.status == UCALIB_CALLSTATUS_CONNECTED) {
        _callBegin = [NSDate date];

        // 初始化摄像头
        if (_isVideoCall) {
            NSInteger hasFrontCam = NO;
            UCALIB_ERRCODE res = ucaLib_get_camera_support(callEvent.handle, FRONTCAM, &hasFrontCam);
            UcaLog(TAG, @"ucaLib_get_camera_support(FRONTCAM) res = %d, hasFrontCam = %d", res, hasFrontCam);

            NSInteger hasBackCam = NO;
            res = ucaLib_get_camera_support(callEvent.handle, BACKCAM, &hasBackCam);
            UcaLog(TAG, @"ucaLib_get_camera_support(BACKCAM) res = %d, hasBackCam = %d", res, hasBackCam);

            _canSwitchCamera = (hasFrontCam && hasBackCam);

            if (hasFrontCam) {
                // 初始设置为前置摄像头
                res = ucaLib_camera_change(callEvent.handle, FRONTCAM);
                UcaLog(TAG, @"ucaLib_camera_change(FRONTCAM) res = %d", res);
                _curCameraId = FRONTCAM;
            } else if (hasBackCam) {
                // 无前置摄像头，全部设置为BACKCAM
                res = ucaLib_camera_change(callEvent.handle, BACKCAM);
                UcaLog(TAG, @"ucaLib_camera_change(BACKCAM) res = %d", res);
                _curCameraId = BACKCAM;
            }
        }
    }

    if (callEvent.status != UCALIB_CALLSTATUS_INCOMING_RECEIVED) {
        return;
    }

    // 处理来电

    UcaLog(TAG, @"Show callAcceptView, event param: '%@'", callEvent.param);

    _isVideoCall = hasVideo;

    _curCallLog = [self addMissedCallOfContact:contact.id
                                    fromNumber:number
                                      hasVideo:_isVideoCall];

    IncomingCallView *view = [[IncomingCallView alloc] initWithNumber:number
                                                           andContact:contact
                                                             hasVideo:_isVideoCall];
    UcaNavigationController *viewNavCtrl = [[UcaNavigationController alloc] initWithRootViewController:view];
    UcaNavigationController *appNavCtrl = [UcaAppDelegate sharedInstance].navigationController;
    _launchAsModalView = YES;
    _launchView = appNavCtrl.topViewController;
    [appNavCtrl presentModalViewController:viewNavCtrl animated:YES];
}

- (id)init {
    self = [super init];
    if (self) {
        _curCallId = NOT_SAVED;
        _curCallStatus = UCALIB_CALLSTATUS_IDLE;
    }
    return self;
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCallStatus:)
                                                 name:UCA_NATIVE_CALL_STATUS
                                               object:nil];
    return YES;
}

- (BOOL)stop {
    UcaLog(TAG, @"Stop()");
    if (![super stop]) {
        return NO;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    return YES;
}

- (BOOL)isUnderPhoneCall {
    return _curCallStatus != UCALIB_CALLSTATUS_IDLE &&
           _curCallStatus != UCALIB_CALLSTATUS_CALLEND &&
           _curCallStatus != UCALIB_CALLSTATUS_REFERED;
}

- (NSString *)curCallStatusText {
    NSString *statusTxt = [UcaConstants textOfCallStatus:_curCallStatus];
    if (_curCallStatus == UCALIB_CALLSTATUS_OUTGOING_PROGRESS) {
        statusTxt = [NSString stringWithFormat:@"%@%@", (_isVideoCall ? I18nString(@"视频") : I18nString(@"语音")), statusTxt];
    }
    return statusTxt;
}

- (NSString *)callDuration {
    NSTimeInterval duration = -[_callBegin timeIntervalSinceNow];
    return [NSString getDuration:duration];
}

- (void)dialNumber:(NSString *)number {
    UCALIB_ERRCODE res = ucaLib_CallInvite([UcaAppDelegate sharedInstance].accountService.curLoginHandle,
                                           [number UTF8String], _isVideoCall ? VIDEO_MODE : AUDIO_MODE,
                                           &_curCallId);
    UcaLog(TAG, @"ucaLib_CallInvite() res = %d, _curCallId = %d", res, _curCallId);
}

- (void)dialOut:(NSString *)number withVideo:(BOOL)hasVideo fromViewController:(UIViewController *)controller {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    UcaAccountService *accountService = app.accountService;
    if ([number isEqualToString:accountService.currentAccount.sipPhone]) {
        [NotifyUtils alert:I18nString(@"不能打电话给您自己。")];
        return;
    }

    if ([self isUnderPhoneCall]) {
        [NotifyUtils alert:I18nString(@"您目前正在通话中，不能拨出另一通电话，请挂断当前通话后再重试。")];
        return;
    }

    NSString *type = ((hasVideo) ? I18nString(@"视频") : I18nString(@"语音"));
    if (![accountService isLoggedIn]) {
        [NotifyUtils alert:[NSString stringWithFormat:I18nString(@"您目前处于离线状态，无法进行%@通话。请登录后再重试。"), type]];
        return;
    }

    int netReachable = NO;
    ucalib_is_network_reachabled(accountService.curLoginHandle, &netReachable);
    if (!netReachable) {
        [NotifyUtils alert:[NSString stringWithFormat:I18nString(@"目前没有网络连接，无法进行%@通话。请建立网络连接后再重试。"), type]];
        return;
    }

    Contact *contact = [self touchContactBySipPhone:number];

    _isVideoCall = hasVideo;
    _launchAsModalView = NO;
    _launchView = controller;

    CallOutView *view = [[CallOutView alloc] initWithNumber:number hasVideo:hasVideo];
    [controller.navigationController pushViewController:view animated:YES];

    _curCallLog = [[RecentLog alloc] init];
    _curCallLog.contactId = contact.id;
    _curCallLog.number = number;
    _curCallLog.type = _isVideoCall ? RecentLogType_Video_DialedOut : RecentLogType_Voice_DialedOut;
    [app.recentService addRecentLog:_curCallLog];

    [self performSelectorInBackground:@selector(dialNumber:) withObject:number];
}

- (void)cancelCall {
    UCALIB_ERRCODE res = ucaLib_CallCancel([UcaAppDelegate sharedInstance].accountService.curLoginHandle,
                                           _curCallId);
    UcaLog(TAG, @"ucaLib_CallCancel() res = %d", res);
}

- (void)pauseCall {
    UCALIB_ERRCODE res = ucaLib_CallPause([UcaAppDelegate sharedInstance].accountService.curLoginHandle,
                                          _curCallId);
    UcaLog(TAG, @"ucaLib_CallPause() res = %d", res);
}

- (void)resumeCall {
    UCALIB_ERRCODE res = ucaLib_CallResume([UcaAppDelegate sharedInstance].accountService.curLoginHandle,
                                           _curCallId);
    UcaLog(TAG, @"ucaLib_CallResume() res = %d", res);
}

- (void)hangupCall {
    if (![self isUnderPhoneCall]) {
        UcaLog(TAG, @"hangupCall() no calling");
        return;
    }

    UCALIB_ERRCODE res = ucaLib_CallHangUp([UcaAppDelegate sharedInstance].accountService.curLoginHandle,
                                           _curCallId);
    UcaLog(TAG, @"ucaLib_CallHangUp() res = %d", res);

    [self saveCallDurationIntoDb];
}

- (void)transferCall:(NSString *)number {
    UCALIB_ERRCODE res = ucaLib_BlindTransferCall([UcaAppDelegate sharedInstance].accountService.curLoginHandle,
                                                  _curCallId, [number UTF8String]);
    UcaLog(TAG, @"ucaLib_BlindTransferCall() res = %d", res);
}

- (void)muteMic:(NSNumber *)mute {
    UCALIB_ERRCODE res = ucaLib_MuteMic([UcaAppDelegate sharedInstance].accountService.curLoginHandle,
                                        [mute boolValue]);
    UcaLog(TAG, @"ucaLib_MuteMic() res = %d", res);
}

- (BOOL)isMicMuted {
    NSInteger muted = NO;
    UCALIB_ERRCODE res = ucaLib_MicMuted([UcaAppDelegate sharedInstance].accountService.curLoginHandle,
                                         &muted);
    UcaLog(TAG, @"ucaLib_MicMuted() res = %d, muted = %d", res, muted);
    return muted;
}

- (void)switchCamera {
    if (!_canSwitchCamera) {
        UcaLog(TAG, @"no camera, cannot switch");
        return;
    }

    UCALIB_LOGIN_HANDLE handle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    UCALIB_ERRCODE res;
    if (_curCameraId == FRONTCAM) {
        res = ucaLib_camera_change(handle, BACKCAM);
        UcaLog(TAG, @"ucaLib_camera_change(BACKCAM) res = %d", res);
        _curCameraId = BACKCAM;
    } else {
        res = ucaLib_camera_change(handle, FRONTCAM);
        UcaLog(TAG, @"ucaLib_camera_change(FRONTCAM) res = %d", res);
        _curCameraId = FRONTCAM;
    }
}

- (BOOL)acceptCall {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    UCALIB_LOGIN_HANDLE handle = app.accountService.curLoginHandle;
    UCALIB_ERRCODE res = ucaLib_CallAccept(handle, _curCallId);
    UcaLog(TAG, @"ucaLib_CallAccept() res = %d", res);
    if (UCALIB_ERR_OK != res) {
        ucaLib_CallCancel(handle, _curCallId);
        [NotifyUtils alert:I18nString(@"接受来电失败")];
        return NO;
    }
    if (_curCallLog) {
        _curCallLog.type = _isVideoCall ? RecentLogType_Video_Accepted : RecentLogType_Voice_Accepted;
        [app.recentService updateRecentLogType:_curCallLog];
    }
    return YES;
}

@end
