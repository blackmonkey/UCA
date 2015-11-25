/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "AudioToolbox/AudioToolbox.h"
#import "AudioTalkView.h"
#import "DialerView.h"

#undef TAG
#define TAG @"AudioTalkView"

@interface AudioTalkView()
- (void)updateDuration:(id)sender;
@end

@implementation AudioTalkView {
    UIView *_toolBarPanel;
    UIImageView *_bgToolBar;
    UIButton *_btnSpeakerHeadset;
    UIButton *_btnPauseResume;
    UIButton *_btnForward;
    UIButton *_btnHangup;
    UIImageView *_logoView;
    UILabel *_lbStatus;
    UILabel *_lbDuration;
    NSTimer *_timer;
}

- (id)init {
    self = [super init];
    if (self) {
        self.title = I18nString(@"语音通话");
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat fullWidth = self.view.frame.size.width;

    CGRect rect = _toolBarPanel.frame;
    rect.origin = CGPointZero;
    rect.size.width = fullWidth;
    rect.size.height = _bgToolBar.frame.size.height;
    _toolBarPanel.frame = rect;

    rect = _bgToolBar.frame;
    rect.origin = CGPointZero;
    rect.size.width = fullWidth;
    _bgToolBar.frame = rect;

    CGFloat cellWidth = fullWidth / 4;

    rect = _btnSpeakerHeadset.frame;
    rect.origin.x = (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgToolBar.frame.size.height - rect.size.height) / 2;
    _btnSpeakerHeadset.frame = rect;

    rect = _btnPauseResume.frame;
    rect.origin.x = cellWidth + (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgToolBar.frame.size.height - rect.size.height) / 2;
    _btnPauseResume.frame = rect;

    rect = _btnForward.frame;
    rect.origin.x = cellWidth * 2 + (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgToolBar.frame.size.height - rect.size.height) / 2;
    _btnForward.frame = rect;

    rect = _btnHangup.frame;
    rect.origin.x = cellWidth * 3 + (cellWidth - rect.size.width) / 2;
    rect.origin.y = (_bgToolBar.frame.size.height - rect.size.height) / 2;
    _btnHangup.frame = rect;

    rect = _logoView.frame;
    rect.origin.x = (fullWidth - rect.size.width) / 2;
    rect.origin.y = 115;
    _logoView.frame = rect;

    rect = _lbStatus.frame;
    rect.origin.x = 0;
    rect.origin.y = CGRectGetMaxY(_logoView.frame);
    rect.size.width = fullWidth;
    rect.size.height = 58;
    _lbStatus.frame = rect;

    rect = _lbDuration.frame;
    rect.origin.x = 0;
    rect.origin.y = CGRectGetMaxY(_lbStatus.frame);
    rect.size.width = fullWidth;
    rect.size.height = 14;
    _lbDuration.frame = rect;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    self.view.backgroundColor = [UIColor colorFromHex:0xFF242424];

    _toolBarPanel = [[UIView alloc] init];
    _toolBarPanel.backgroundColor = [UIColor clearColor];

    _bgToolBar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"res/toolbar_background"] resizeFromCenter]];
    [_toolBarPanel addSubview:_bgToolBar];

    _btnSpeakerHeadset = [UIButton buttonWithImageName:@"res/phonecall_top_toolbar_Speaker" andTarget:self andAction:@selector(switchToSpeakerOrHeadset:)];
    [_toolBarPanel addSubview:_btnSpeakerHeadset];

    _btnPauseResume = [UIButton buttonWithImageName:@"res/phonecall_top_toolbar_pause" andTarget:self andAction:@selector(pauseOrResume:)];
    [_toolBarPanel addSubview:_btnPauseResume];

    _btnForward = [UIButton buttonWithImageName:@"res/phonecall_top_toolbar_forward" andTarget:self andAction:@selector(askForward:)];
    [_toolBarPanel addSubview:_btnForward];

    _btnHangup = [UIButton buttonWithImageName:@"res/phonecall_top_toolbar_hangup" andTarget:self andAction:@selector(hangup:)];
    [_toolBarPanel addSubview:_btnHangup];
    [self.view addSubview:_toolBarPanel];

    _logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/phonecall_audio_talk_logo"]];
    [self.view addSubview:_logoView];

    _lbStatus = [[UILabel alloc] init];
    _lbStatus.backgroundColor = [UIColor clearColor];
    _lbStatus.textColor = [UIColor colorFromHex:0xFF90FED7];
    _lbStatus.font = [UIFont systemFontOfSize:22];
    _lbStatus.textAlignment = UITextAlignmentCenter;
    _lbStatus.text = I18nString(@"语音通话中");
    [self.view addSubview:_lbStatus];

    _lbDuration = [[UILabel alloc] init];
    _lbDuration.backgroundColor = [UIColor clearColor];
    _lbDuration.textColor = [UIColor colorFromHex:0xFF90FED7];
    _lbDuration.font = [UIFont systemFontOfSize:14];
    _lbDuration.textAlignment = UITextAlignmentCenter;
    [self updateDuration:nil];
    [self.view addSubview:_lbDuration];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCallStatus:)
                                                 name:UCA_INDICATE_CALL_STATUS_TEXT
                                               object:nil];

    _timer = [NSTimer scheduledTimerWithTimeInterval:1
                                              target:self
                                            selector:@selector(updateDuration:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_timer invalidate];
    _timer = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

#pragma mark - selector methods

- (void)updateDuration:(id)sender {
    _lbDuration.text = [UcaAppDelegate sharedInstance].callingService.callDuration;
}

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

- (void)onCallStatus:(NSNotification *)note {
    UCALIB_CALL_STATUS status = [(NSNumber *)note.object integerValue];
    _lbStatus.text = [UcaAppDelegate sharedInstance].callingService.curCallStatusText;
    UcaLog(TAG, @"onCallStatus %d %@", status, _lbStatus.text);

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
