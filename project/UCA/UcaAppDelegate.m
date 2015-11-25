/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaWindow.h"
#import "LaunchView.h"
#import "AccountListView.h"

#undef TAG
#define TAG @"UcaAppDelegate"

void UcaStack_SystemMessage(IN UCALIB_SYSTEM_MESSAGE_CODE msgCode, IN const char *msg);
void UcaStack_LoginResult(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_LOGIN_STATE state, IN UCALIB_ERRCODE result);
void UcaStack_PresentationResult(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_PRESENTATIONSTATE status, IN UCALIB_PRESENTATIONRESULT_CODE result);
void UcaStack_ImMsg(IN UCALIB_LOGIN_HANDLE handle, IN const char *uri, IN const char *htmlMsg);
void UcaStack_ChatImMsg(IN UCALIB_LOGIN_HANDLE handle, IN const char *from, IN const char *to, IN const char *towhom, IN const char *htmlMsg);
void UcaStack_PresentationNotify(IN UCALIB_LOGIN_HANDLE handle, IN const char *uri, IN UCALIB_PRESENTATIONSTATE state);
void UcaStack_PresentationNotifyList(IN UCALIB_LOGIN_HANDLE handle, IN const char *uri, IN const char *xmlMsg);
void UcaStack_MemberChangeNotifyList(IN UCALIB_LOGIN_HANDLE handle, IN const char *uriFmt, IN const char *xmlMsg);
void UcaStack_CallStatus(IN UCALIB_LOGIN_HANDLE handle, IN const int callId, IN UCALIB_CALL_STATUS status, IN const char *peerUri, IN const void *param);
void UcaStack_SfpStatus(IN UCALIB_LOGIN_HANDLE handle, IN const int sfpId, IN UCALIB_SFP_STATUS status, IN const char *peerUri, IN const char *filename, IN const char *filesize, IN const char *filetype, IN const void *param);
void UcaStack_ChatStatus(IN UCALIB_LOGIN_HANDLE handle,IN const int chatid,IN const char *uri,IN UCALIB_CHAT_STATUS status,IN UCALIB_CHAT_ERRCODE errcode, IN const void *param);
void sqlite3_trace_callback(void *udp, const char *sql);

void UcaStack_SystemMessage(IN UCALIB_SYSTEM_MESSAGE_CODE msgCode,
                            IN const char *msg) {
    NSString *nsMsg = [NSString stringOfUTF8String:msg];
    if ([NSString isNullOrEmpty:nsMsg]) {
        nsMsg = I18nString(@"未知错误");
    }
    UcaLog(TAG, @"UCAStack_SystemMessage: %d, '%s'->'%@'", msgCode, msg, nsMsg);

    if (![[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
        return;
    }

    switch (msgCode) {
    case UCALIB_SYSTEM_MESSAGE_CODE_KICKOFF:
        [NotifyUtils postNotificationWithName:UCA_NATIVE_KICK_OFF];
        break;
    case UCALIB_SYSTEM_MESSAGE_MSG_CANTREACH:
        [NotifyUtils postNotificationWithName:UCA_NATIVE_IM_SENT_FAILED
                                       object:nsMsg];
        break;
    case UCALIB_SYSTEM_MESSAGE_ERROR:
        [NotifyUtils alert:nsMsg];
        break;
    }
}

void UcaStack_LoginResult(IN UCALIB_LOGIN_HANDLE handle,
                          IN UCALIB_LOGIN_STATE state,
                          IN UCALIB_ERRCODE result) {
    UcaLog(TAG, @"UCAStack_LoginResult: %d, %d, %d", handle, state, result);

    UcaLoginEvent *event = [[UcaLoginEvent alloc] init];
    event.handle = handle;
    event.state = state;
    [NotifyUtils postNotificationWithName:UCA_NATIVE_LOGIN object:event];
}

void UcaStack_PresentationResult(IN UCALIB_LOGIN_HANDLE handle,
                                 IN UCALIB_PRESENTATIONSTATE state,
                                 IN UCALIB_PRESENTATIONRESULT_CODE result) {
    UcaLog(TAG, @"UcaStack_PresentationResult: %d, %d, %d", handle, state, result);

    UcaAccountPresentationEvent *event = [[UcaAccountPresentationEvent alloc] init];
    event.handle = handle;
    event.result = result;
    if ([[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
        [NotifyUtils postNotificationWithName:UCA_NATIVE_ACCOUNT_PRESENTATION object:event];
    }
}

void UcaStack_ImMsg(IN UCALIB_LOGIN_HANDLE handle,
                    IN const char *uri,
                    IN const char *htmlMsg) {
    UcaNativeImEvent *event = [[UcaNativeImEvent alloc] init];
    event.handle = handle;
    event.senderSip = [NSString stringOfUTF8String:uri];
    event.htmlMsg = [NSString stringOfUTF8String:htmlMsg];

    UcaLog(TAG, @"UCAStack_IMMsg: %d, '%@' from '%s'", handle, event.htmlMsg, uri);
    [NotifyUtils postNotificationWithName:UCA_NATIVE_IM_RECEIVED object:event];
}

void UcaStack_ChatImMsg(IN UCALIB_LOGIN_HANDLE handle,
                        IN const char *from,
                        IN const char *to,
                        IN const char *towhom,
                        IN const char *htmlMsg) {
    UcaNativeImEvent *event = [[UcaNativeImEvent alloc] init];
    event.handle = handle;
    event.senderSip = [NSString stringOfUTF8String:from];
    event.receiverSip = [NSString stringOfUTF8String:to];
    event.toWhomSip = [NSString stringOfUTF8String:towhom];
    event.htmlMsg = [NSString stringOfUTF8String:htmlMsg];

    UcaLog(TAG, @"UcaStack_ChatImMsg: %d, '%s', '%s', '%s', '%@'", handle, from, to, towhom, event.htmlMsg);
    [NotifyUtils postNotificationWithName:UCA_NATIVE_IM_RECEIVED object:event];
}

void UcaStack_PresentationNotify(IN UCALIB_LOGIN_HANDLE handle,
                                 IN const char *uri,
                                 IN UCALIB_PRESENTATIONSTATE state) {
    UcaLog(TAG, @"UcaStack_PresentationNotify: %d, '%s', %d", handle, uri, state);

    UcaContactPresentationEvent *event = [[UcaContactPresentationEvent alloc] init];
    event.handle = handle;
    event.uri = [NSString stringOfUTF8String:uri];
    event.state = state;
    [[UcaAppDelegate sharedInstance].contactService updatePresentationWhenLogin:event];
    [NotifyUtils postNotificationWithName:UCA_NATIVE_CONTACT_PRESENTATION object:event];
}

void UcaStack_PresentationNotifyList(IN UCALIB_LOGIN_HANDLE handle,
                                     IN const char *uri,
                                     IN const char *xmlMsg) {
    NSString *nsUri = [[NSString stringOfUTF8String:uri] strimmedSipPhone];
    NSString *nsMsg = [NSString stringOfUTF8String:xmlMsg];
    UcaLog(TAG, @"UcaStack_PresentationNotifyList: %d, '%s'->'%@', '%@'", handle, uri, nsUri, nsMsg);

    if (strlen(uri) < 4) { // uriFmt must be list-5004752@sipserver.maipu.com, img-1096@sipserver.maipu.com or imc-2012082006473511@123.0.0.151
        return;
    }

    NSString *noteName = nil;
    if ([nsUri hasPrefix:@"img-"]) {
        noteName = UCA_NATIVE_GROUP_PRESENTATION;
    } else if ([nsUri hasPrefix:@"imc-"]) {
        noteName = UCA_NATIVE_SESSION_PRESENTATION;
    } else if ([nsUri hasPrefix:@"list-"]) {
        noteName = UCA_NATIVE_CONTACTS_PRESENTATION;
    }
    if (![NSString isNullOrEmpty:noteName]) {
        [[UcaAppDelegate sharedInstance].contactService updatePresentationsWhenLogin:nsMsg];
        [NotifyUtils postNotificationWithName:noteName object:nsMsg];
    }
}

void UcaStack_MemberChangeNotifyList(IN UCALIB_LOGIN_HANDLE handle,
                                     IN const char *uriFmt,
                                     IN const char *xmlMsg) {
    NSString *nsMsg = [NSString stringOfUTF8String:xmlMsg];
    UcaLog(TAG, @"UcaStack_MemberChangeNotifyList: %d, '%s', '%@'", handle, uriFmt, nsMsg);

    // uriFmt必须符合img-1096@sipserver.maipu.com或imc-2012082006473511@123.0.0.151的格式
    if (strlen(uriFmt) < 4) {
        return;
    }

    if (strncmp("img-", uriFmt, 4) == 0) {
        [NotifyUtils postNotificationWithName:UCA_NATIVE_GROUP_MEMBER_CHANGED object:nsMsg];
    } else if (strncmp("imc-", uriFmt, 4) == 0) {
        [NotifyUtils postNotificationWithName:UCA_NATIVE_SESSION_MEMBER_CHANGED object:nsMsg];
    }
}

void UcaStack_CallStatus(IN UCALIB_LOGIN_HANDLE handle,
                         IN const int callId,
                         IN UCALIB_CALL_STATUS status,
                         IN const char *peerUri,
                         IN const void *param) {
    UcaLog(TAG, @"UcaStack_CallStatus: %d, %d, %d, '%s', %p", handle, callId, status, peerUri, param);

    UcaCallStatusEvent *event = [[UcaCallStatusEvent alloc] init];
    event.handle = handle;
    event.callId = callId;
    event.status = status;
    event.peerUri = [NSString stringOfUTF8String:peerUri];
    if (status == UCALIB_CALLSTATUS_INCOMING_RECEIVED) {
        event.param = [NSString stringOfUTF8String:(const char *)param];
    } else {
        event.param = nil;
    }
    [NotifyUtils postNotificationWithName:UCA_NATIVE_CALL_STATUS object:event];
}

void UcaStack_SfpStatus(IN UCALIB_LOGIN_HANDLE handle,
                        IN const int sfpId,
                        IN UCALIB_SFP_STATUS status,
                        IN const char *peerUri,
                        IN const char *filename,
                        IN const char *filesize,
                        IN const char *filetype,
                        IN const void *param) {
    UcaLog(TAG, @"UcaStack_SfpStatus: %d, %d, %d, '%s', '%s', '%s', '%s', %p", handle, sfpId, status, peerUri, filename, filesize, filetype, param);
    if (status == UCALIB_SFP_STATUS_INCOMING_RECEIVED) {
        UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
        NSString *nsFname = [NSString stringWithUTF8String:filename];
        NSString *fullPath = [[app.configService.imBaseUrl path] stringByAppendingPathComponent:nsFname];
        ucaLib_SfpRecvFile(app.accountService.curLoginHandle, [fullPath UTF8String], sfpId, 0);

        UcaSfpStatusEvent *event = [[UcaSfpStatusEvent alloc] init];
        // TODO: Ensure peerUri matches form XXX@sipserver.maipu.com
        event.peerUri = [NSString stringOfUTF8String:peerUri];
        event.fullPath = fullPath;

        [NotifyUtils postNotificationWithName:UCA_NATIVE_IM_IMG_RECEIVED object:event];
    }
}

void UcaStack_ChatStatus(IN UCALIB_LOGIN_HANDLE handle,
                         IN const int chatid,
                         IN const char *uri,
                         IN UCALIB_CHAT_STATUS status,
                         IN UCALIB_CHAT_ERRCODE errcode,
                         IN const void *param) {
    UcaLog(TAG, @"UcaStack_ChatStatus: %d, %d, '%s', %d, %d, %p", handle, chatid, uri, status, errcode, param);
    UcaSessionStatusEvent *event = [[UcaSessionStatusEvent alloc] init];
    event.chatId = chatid;
    // TODO: Ensure uri matches form XXX@sipserver.maipu.com
    event.sessionSipPhone = [NSString stringWithUTF8String:uri];
    event.status = status;
    event.errcode = errcode;
    event.param = param;
    [NotifyUtils postNotificationWithName:UCA_NATIVE_SESSION_STATUS object:event];
}

static UCALIB_CBKS sUcaStack_Callbacks = {
    .systemMessage          = UcaStack_SystemMessage,          // 获取系统消息
    .loginState             = UcaStack_LoginResult,            // 获取登录状态
    .presentationState      = UcaStack_PresentationResult,     // 获取呈现状态改变结果
    .imMsg                  = UcaStack_ImMsg,                  // 获取收到的即时消息
    .chatimMsg              = UcaStack_ChatImMsg,              // 获取收到固定群组或多人会话的即时消息
    .presentationNotify     = UcaStack_PresentationNotify,     // 获取好友的呈现状态变化
    .presentationNotifyList = UcaStack_PresentationNotifyList, // 批量获取使用者的呈现状态变化
    .memberChangeNotifyList = UcaStack_MemberChangeNotifyList, // 批量获取使用者的成员变化
    .callStatus             = UcaStack_CallStatus,             // 通话回调状态接口
    .sfpStatus              = UcaStack_SfpStatus,              // 文件传输回调状态接口
    .chatStatus             = UcaStack_ChatStatus,             // 多人会话回调状态接口
};

@implementation UcaAppDelegate

@synthesize window = _window;
@synthesize navigationController;
@synthesize tabBarController = _tabBarController;
@synthesize accountService;
@synthesize configService;
@synthesize databaseService;
@synthesize serverParamService;
@synthesize contactService;
@synthesize messageService;
@synthesize callingService;
@synthesize orgService;
@synthesize recentService;
@synthesize groupService;
@synthesize sessionService;

- (void)showLoginView {
    AccountListView *view = [[AccountListView alloc] init];
    [navigationController popToRootViewControllerAnimated:NO];
    [navigationController pushViewController:view animated:YES];
}

- (void)showTabViews {
    BOOL ok = [self.contactService start];
    ok &= [self.groupService start];
    if (!ok) {
        [NotifyUtils alert:I18nString(@"读取联系人信息失败，请重启应用！")];
        return;
    }

    self.tabBarController = [[UcaTabBarController alloc] init];

    navigationController.navigationBarHidden = YES;
    [navigationController popToRootViewControllerAnimated:NO];
    [navigationController pushViewController:self.tabBarController animated:YES];
}

- (void)onKickOff {
    [navigationController popToRootViewControllerAnimated:YES];

    if ([accountService isLoggedIn]) {
        [accountService requestLogout];
    }
    accountService.curLoginStatus = LoginStatus_LoggedOut;

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:I18nString(@"您的帐号在别处登录，您已被迫退出！")
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:I18nString(@"确定")
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)copyEmotIconsToDocumentFolder {
    NSArray *iconFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"gif" inDirectory:@"res/emoticons"];
    NSString *emotPath = [[self->configService.imBaseUrl path] stringByAppendingPathComponent:@"emoticons"];
    NSError *error = nil;

    if (![[NSFileManager defaultManager] fileExistsAtPath:emotPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:emotPath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            UcaLog(TAG, @"Failed to create folder emoticons!");
            return;
        }
    }

    /* NOTE: No need to check whether the target file already exists, since it won't copy while the target exists. */
    for (NSString *iconFile in iconFiles) {
        NSString *baseName = [[iconFile componentsSeparatedByString:@"/"] lastObject];
        NSString *newIconFile = [emotPath stringByAppendingPathComponent:baseName];
        [[NSFileManager defaultManager] copyItemAtPath:iconFile
                                                toPath:newIconFile
                                                 error:nil];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /* Initialize VoIP stack */
    UCALIB_ERRCODE res = ucaLib_Init(&sUcaStack_Callbacks);
    if (UCALIB_ERR_OK != res) {
        UcaLog(TAG, @"ERROR: ucaLib_Init() Failed: %d", res);
        return NO;
    }

    self->configService = [[UcaConfigurationService alloc] init];
    self->databaseService = [[UcaDatabaseService alloc] init];
    self->serverParamService = [[UcaServerParamService alloc] init];
    self->accountService = [[UcaAccountService alloc] init];
    self->contactService = [[UcaContactService alloc] init];
    self->messageService = [[UcaMessageService alloc] init];
    self->callingService = [[UcaCallingService alloc] init];
    self->orgService = [[UcaOrgService alloc] init];
    self->recentService = [[UcaRecentService alloc] init];
    self->groupService = [[UcaGroupService alloc] init];
    self->sessionService = [[UcaSessionService alloc] init];

    // Order is important
    BOOL ok = YES;
    ok &= [self.configService start];
    ok &= [self.databaseService start];
    ok &= [self.serverParamService start];
    ok &= [self.accountService start];
    ok &= [self.messageService start];
    ok &= [self.callingService start];
    ok &= [self.orgService start];
    ok &= [self.recentService start];
    ok &= [self.sessionService start];

    [self copyEmotIconsToDocumentFolder];

    /* Initialize UI */
    self.window = [[UcaWindow alloc] init];

    /* Show launching view */
    LaunchView *view = [[LaunchView alloc] init];
    navigationController = [[UcaNavigationController alloc] initWithRootViewController:view];
    [self.window setRootViewController:navigationController];
    [self.window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKickOff)
                                                 name:UCA_NATIVE_KICK_OFF
                                               object:nil];
    return ok;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.accountService requestLogout];

    UCALIB_ERRCODE res = ucaLib_Terminate();
    UcaLog(TAG, @"ucaLib_Terminate() return: %d", res);

    // Order is important
    [self.sessionService stop];
    [self.groupService stop];
    [self.recentService stop];
    [self.orgService stop];
    [self.callingService stop];
    [self.messageService stop];
    [self.contactService stop];
    [self.accountService stop];
    [self.serverParamService stop];
    [self.databaseService stop];
    [self.configService stop];
}

+ (UcaAppDelegate *)sharedInstance {
    return ((UcaAppDelegate *) [[UIApplication sharedApplication] delegate]);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    // Return YES for supported orientations

//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        return (orientation != UIInterfaceOrientationPortraitUpsideDown);
//    }
//    return YES;
    return NO;
}

#pragma UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self showLoginView];
}

@end
