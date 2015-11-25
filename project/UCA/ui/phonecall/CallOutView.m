/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "CallOutView.h"
#import "AudioTalkView.h"
#import "VideoTalkView.h"

#undef TAG
#define TAG @"CallOutView"

#define ACTION_SHEET_DISMISS_FAKE_KEY 100

@implementation CallOutView {
    BOOL _isVideoCall;

    UIImageView *_logoView;
    UILabel *_lbStatus;
    UIActionSheet *_shHangup;
}

- (id)initWithNumber:(NSString *)number hasVideo:(BOOL)hasVideo {
    self = [super init];
    if (self) {
        _shHangup = [[UIActionSheet alloc] initWithTitle:nil
                                                delegate:self
                                       cancelButtonTitle:I18nString(@"挂断")
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:nil];
        _shHangup.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

        _isVideoCall = hasVideo;
        self.title = (hasVideo ? I18nString(@"视频通话") : I18nString(@"语音通话"));
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat fullWidth = self.view.frame.size.width;

    CGRect rect = _logoView.frame;
    rect.origin.x = (fullWidth - rect.size.width) / 2;
    rect.origin.y = 115;
    _logoView.frame = rect;

    rect = _lbStatus.frame;
    rect.origin.x = 0;
    rect.origin.y = CGRectGetMaxY(_logoView.frame);
    rect.size.width = fullWidth;
    rect.size.height = 58;
    _lbStatus.frame = rect;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.hidesBackButton = YES;
    self.view.backgroundColor = [UIColor colorFromHex:0xFF242424];

    if (_isVideoCall) {
        _logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/phonecall_video_logo"]];
    } else {
        _logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/phonecall_audio_logo"]];
    }
    [self.view addSubview:_logoView];

    _lbStatus = [[UILabel alloc] init];
    _lbStatus.backgroundColor = [UIColor clearColor];
    _lbStatus.textColor = [UIColor colorFromHex:0xFF90FED7];
    _lbStatus.font = [UIFont systemFontOfSize:22];
    _lbStatus.textAlignment = UITextAlignmentCenter;
    _lbStatus.text = (_isVideoCall ? I18nString(@"视频连接中⋯⋯") : I18nString(@"语音连接中⋯⋯"));
    [self.view addSubview:_lbStatus];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCallStatus:)
                                                 name:UCA_INDICATE_CALL_STATUS_TEXT
                                               object:nil];
    [_shHangup showFromTabBar:self.tabBarController.tabBar];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // 用假键值来关闭action sheet，以防触发cancelCall。
    [_shHangup dismissWithClickedButtonIndex:ACTION_SHEET_DISMISS_FAKE_KEY animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

#pragma mark - selector methods

- (void)onCallStatus:(NSNotification *)note {
    UCALIB_CALL_STATUS status = [(NSNumber *)note.object integerValue];
    _lbStatus.text = [UcaAppDelegate sharedInstance].callingService.curCallStatusText;
    UcaLog(TAG, @"onCallStatus %d %@", status, _lbStatus.text);

    if (status == UCALIB_CALLSTATUS_CONNECTED) {
        UIViewController *view = nil;
        if (_isVideoCall) {
            view = [[VideoTalkView alloc] init];
        } else {
            view = [[AudioTalkView alloc] init];
        }
        if (view != nil) {
            [self.navigationController pushViewController:view animated:YES];
        }
    }
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(hangupCall) withObject:nil];
    }
}

@end
