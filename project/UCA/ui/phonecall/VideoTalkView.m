/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <QuartzCore/QuartzCore.h>
#import "AudioToolbox/AudioToolbox.h"
#import "VideoTalkView.h"
#import "DialerView.h"

#undef TAG
#define TAG @"VideoTalkView"

@implementation VideoTalkView {
    UIView *_topToolBar;
    UIImageView *_bgTopToolBar;
    UIButton *_btnSpeakerHeadset;
    UIButton *_btnPauseResume;
    UIButton *_btnForward;
    UIButton *_btnHangup;

    UIView *_bottomToolBar;
    UIImageView *_bgBottomToolBar;
    UIButton *_btnSpeakerOn;
    UIButton *_btnSpeakerOff;
    UIButton *_btnSwitchCam;
    UIButton *_btnFullScreen;
    UIButton *_btnExitFullScreen;

    UIView* _display; // 显示对方画面
    UIView* _preview; // 显示己方画面
}

- (id)init {
    self = [super init];
    if (self) {
        self.title = I18nString(@"视频通话");
    }
    return self;
}

#pragma mark - View lifecycle

- (void)layoutTopToolBar {
    if (_topToolBar.hidden) {
        _topToolBar.frame = CGRectZero;
        return;
    }

    CGFloat fullWidth = self.view.bounds.size.width;

    CGRect rect = _topToolBar.frame;
    rect.origin = CGPointZero;
    rect.size.width = fullWidth;
    rect.size.height = _bgTopToolBar.frame.size.height;
    _topToolBar.frame = rect;

    rect = _bgTopToolBar.frame;
    rect.origin = CGPointZero;
    rect.size.width = fullWidth;
    _bgTopToolBar.frame = rect;

    CGFloat cellWidth = fullWidth / 4;

    rect = _btnSpeakerHeadset.frame;
    rect.origin.x = (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgTopToolBar.frame.size.height - rect.size.height) / 2;
    _btnSpeakerHeadset.frame = rect;

    rect = _btnPauseResume.frame;
    rect.origin.x = cellWidth + (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgTopToolBar.frame.size.height - rect.size.height) / 2;
    _btnPauseResume.frame = rect;

    rect = _btnForward.frame;
    rect.origin.x = cellWidth * 2 + (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgTopToolBar.frame.size.height - rect.size.height) / 2;
    _btnForward.frame = rect;

    rect = _btnHangup.frame;
    rect.origin.x = cellWidth * 3 + (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgTopToolBar.frame.size.height - rect.size.height) / 2;
    _btnHangup.frame = rect;
}

- (void)layouteDisplays {
    CGFloat fullWidth = self.view.bounds.size.width;

    CGRect rect = _display.frame;
    rect.origin.x = 0;
    rect.origin.y = _topToolBar.frame.size.height;
    rect.size.width = fullWidth;
    rect.size.height = self.view.bounds.size.height - _topToolBar.frame.size.height - _bottomToolBar.frame.size.height;
    _display.frame = rect;

    rect = _preview.frame;
    rect.size.width = fullWidth / 3;
    rect.size.height = rect.size.width;
    rect.origin.x = fullWidth - rect.size.width;
    rect.origin.y = _topToolBar.frame.size.height;
    _preview.frame = rect;
}

- (void)layoutBottomToolBar {
    CGFloat fullWidth = self.view.bounds.size.width;

    CGRect rect = _bottomToolBar.frame;
    rect.origin.x = 0;
    rect.origin.y = self.view.bounds.size.height - _bgBottomToolBar.frame.size.height;
    rect.size.width = fullWidth;
    rect.size.height = _bgBottomToolBar.frame.size.height;
    _bottomToolBar.frame = rect;

    rect = _bgBottomToolBar.frame;
    rect.origin = CGPointZero;
    rect.size.width = fullWidth;
    _bgBottomToolBar.frame = rect;

    CGFloat cellWidth = _bottomToolBar.frame.size.height;

    rect = _btnSpeakerOn.frame;
    rect.origin.x = (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgBottomToolBar.frame.size.height - rect.size.height) / 2;
    _btnSpeakerOn.frame = rect;
    _btnSpeakerOff.frame = rect;

    rect = _btnSwitchCam.frame;
    rect.origin.x = cellWidth + (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgBottomToolBar.frame.size.height - rect.size.height) / 2;
    _btnSwitchCam.frame = rect;

    rect = _btnFullScreen.frame;
    rect.origin.x = fullWidth - cellWidth + (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgBottomToolBar.frame.size.height - rect.size.height) / 2;
    _btnFullScreen.frame = rect;
    _btnExitFullScreen.frame = rect;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutTopToolBar];
    [self layoutBottomToolBar];
    [self layouteDisplays];
}

- (void)createTopToolBar {
    _topToolBar = [[UIView alloc] init];
    _topToolBar.backgroundColor = [UIColor clearColor];

    _bgTopToolBar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"res/toolbar_background"] resizeFromCenter]];
    [_topToolBar addSubview:_bgTopToolBar];

    _btnSpeakerHeadset = [UIButton buttonWithImageName:@"res/phonecall_top_toolbar_Speaker" andTarget:self andAction:@selector(switchToSpeakerOrHeadset:)];
    [_topToolBar addSubview:_btnSpeakerHeadset];

    _btnPauseResume = [UIButton buttonWithImageName:@"res/phonecall_top_toolbar_pause" andTarget:self andAction:@selector(pauseOrResume:)];
    [_topToolBar addSubview:_btnPauseResume];

    _btnForward = [UIButton buttonWithImageName:@"res/phonecall_top_toolbar_forward" andTarget:self andAction:@selector(askForward:)];
    [_topToolBar addSubview:_btnForward];

    _btnHangup = [UIButton buttonWithImageName:@"res/phonecall_top_toolbar_hangup" andTarget:self andAction:@selector(hangup:)];
    [_topToolBar addSubview:_btnHangup];

    [self.view addSubview:_topToolBar];
}

- (void)createDisplays {
    _display = [[UIView alloc] init];
    _display.backgroundColor = [UIColor colorFromHex:0xFF242424];
    [self.view addSubview:_display];

    _preview = [[UIView alloc] init];
    _preview.backgroundColor = [UIColor colorFromHex:0xFF242424];
    _preview.layer.borderWidth = 1.0;
    _preview.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _preview.layer.shadowColor = [UIColor grayColor].CGColor;
    _preview.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    _preview.layer.shadowOpacity = 0.5;
    _preview.layer.shadowRadius = 0.5;
    [self.view addSubview:_preview];
}

- (void)createBottomToolBar {
    _bottomToolBar = [[UIView alloc] init];
    _bottomToolBar.backgroundColor = [UIColor clearColor];

    _bgBottomToolBar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"res/toolbar_background"] resizeFromCenter]];
    [_bottomToolBar addSubview:_bgBottomToolBar];

    _btnSpeakerOn = [UIButton buttonWithImageName:@"res/phonecall_toolbar_exist_mute" andTarget:self andAction:@selector(switchOnSpeaker:)];
    [_bottomToolBar addSubview:_btnSpeakerOn];

    _btnSpeakerOff = [UIButton buttonWithImageName:@"res/phonecall_toolbar_mute" andTarget:self andAction:@selector(switchOffSpeaker:)];
    [_bottomToolBar addSubview:_btnSpeakerOff];

    _btnSpeakerOff.hidden = [[UcaAppDelegate sharedInstance].callingService isMicMuted];
    _btnSpeakerOn.hidden = !_btnSpeakerOff.hidden;

    _btnSwitchCam = [UIButton buttonWithImageName:@"res/phonecall_toolbar_switch_camera" andTarget:self andAction:@selector(switchCam:)];
    [_bottomToolBar addSubview:_btnSwitchCam];

    _btnFullScreen = [UIButton buttonWithImageName:@"res/phonecall_toolbar_fullscreen" andTarget:self andAction:@selector(fullScreen:)];
    [_bottomToolBar addSubview:_btnFullScreen];

    _btnExitFullScreen = [UIButton buttonWithImageName:@"res/phonecall_toolbar_exit_fullscreen" andTarget:self andAction:@selector(exitFullScreen:)];
    _btnExitFullScreen.hidden = YES;
    [_bottomToolBar addSubview:_btnExitFullScreen];

    [self.view addSubview:_bottomToolBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    self.view.backgroundColor = [UIColor colorFromHex:0xFF242424];

    [self createTopToolBar];
    [self createDisplays];
    [self createBottomToolBar];

    UCALIB_LOGIN_HANDLE handle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    ucaLib_enable_video(handle, YES);
    ucaLib_enable_video_preview(handle, YES);
    ucaLib_set_native_video_window_id(handle, (unsigned long)ID_TO_CFTYPEREF(_display));
    ucaLib_set_native_preview_window_id(handle, (unsigned long)ID_TO_CFTYPEREF(_preview));
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCallStatus:)
                                                 name:UCA_INDICATE_CALL_STATUS_TEXT
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationLandscapeRight;
}

#pragma mark - selector methods

- (void)switchToSpeakerOrHeadset:(id)btn {
    // FIXME: 验证声音输出是否成功转向，同时麦克风输入是否正确。
    // _btnSpeakerHeadset处于选中状态时，语音通过喇叭输出
    UInt32 route = _btnSpeakerHeadset.selected ? kAudioSessionOverrideAudioRoute_None : kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
                            sizeof(route),
                            &route);
    _btnSpeakerHeadset.selected = !_btnSpeakerHeadset.selected;
}

- (void)pauseOrResume:(id)btn {
    if (_btnPauseResume.selected) { // _btnPauseResume处于选中状态时，通话已暂停
        [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(resumeCall) withObject:nil];
    } else {
        [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(pauseCall) withObject:nil];
    }
}

- (void)askForward:(id)btn {
    DialerView *view = [[DialerView alloc] initToTransferCallWithVideo:NO];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)hangup:(id)btn {
    _btnHangup.enabled = NO;
    [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(hangupCall) withObject:nil];
}

- (void)switchOnSpeaker:(id)btn {
    [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(muteMic:)
                                                                     withObject:[NSNumber numberWithBool:NO]];
    _btnSpeakerOn.hidden = YES;
    _btnSpeakerOff.hidden = NO;
}

- (void)switchOffSpeaker:(id)btn {
    [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(muteMic:)
                                                                     withObject:[NSNumber numberWithBool:YES]];
    _btnSpeakerOn.hidden = NO;
    _btnSpeakerOff.hidden = YES;
}

- (void)switchCam:(id)btn {
    [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(switchCamera) withObject:nil];
}

- (void)hideTabBar {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect rect;
    for (UIView *v in self.tabBarController.view.subviews) {
        rect = v.frame;
        if ([v isKindOfClass:[UITabBar class]]) {
            rect.origin.y = screenRect.size.height;
        } else {
            rect.size.height = screenRect.size.height;
        }
        v.frame = rect;
    }
}

- (void)showTabBar {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat fHeight = screenRect.size.height - 49;
    CGRect rect;
    for (UIView *v in self.tabBarController.view.subviews) {
        rect = v.frame;
        if ([v isKindOfClass:[UITabBar class]]) {
            rect.origin.y = fHeight;
        } else {
            rect.size.height = fHeight;
        }
        v.frame = rect;
    }
}

- (void)fullScreen:(id)btn {
    UIApplication *app = [UIApplication sharedApplication];
    app.statusBarOrientation = UIInterfaceOrientationLandscapeRight;
    app.statusBarHidden = YES;
    self.navigationController.navigationBarHidden = YES;
    [self hideTabBar];
    self.view.transform = CGAffineTransformIdentity;
    self.view.transform = CGAffineTransformMakeRotation(M_PI_2);
    _topToolBar.hidden = YES;
    _btnFullScreen.hidden = YES;
    _btnExitFullScreen.hidden = NO;
    ucaLib_set_device_rotation([UcaAppDelegate sharedInstance].accountService.curLoginHandle, 270);
}

- (void)exitFullScreen:(id)btn {
    UIApplication *app = [UIApplication sharedApplication];
    app.statusBarOrientation = UIInterfaceOrientationPortrait;
    app.statusBarHidden = NO;
    self.navigationController.navigationBarHidden = NO;
    [self showTabBar];
    self.view.transform = CGAffineTransformIdentity;
    self.view.transform = CGAffineTransformMakeRotation(0);
    _topToolBar.hidden = NO;
    _btnFullScreen.hidden = NO;
    _btnExitFullScreen.hidden = YES;
    ucaLib_set_device_rotation([UcaAppDelegate sharedInstance].accountService.curLoginHandle, 0);
}

- (void)onCallStatus:(NSNotification *)note {
    UCALIB_CALL_STATUS status = [(NSNumber *)note.object integerValue];
    UcaLog(TAG, @"onCallStatus %d", status);

    if (status == UCALIB_CALLSTATUS_OUTGOING_PROGRESS
        || status == UCALIB_CALLSTATUS_STREAMSRUNNING) {
        _btnPauseResume.enabled = YES;
        _btnPauseResume.selected = NO;
    } else if (status == UCALIB_CALLSTATUS_PAUSING) {
        _btnPauseResume.enabled = NO;
        [_btnPauseResume setImage:[_btnPauseResume imageForState:UIControlStateSelected]
                         forState:UIControlStateDisabled];
    } else if (status == UCALIB_CALLSTATUS_PAUSED) {
        _btnPauseResume.enabled = YES;
        _btnPauseResume.selected = YES;
    } else if (status == UCALIB_CALLSTATUS_RESUMING) {
        _btnPauseResume.enabled = NO;
        [_btnPauseResume setImage:[_btnPauseResume imageForState:UIControlStateNormal]
                         forState:UIControlStateDisabled];
    }
}

@end
