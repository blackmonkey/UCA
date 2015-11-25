/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <QuartzCore/QuartzCore.h>
#import "IncomingCallView.h"
#import "AudioTalkView.h"
#import "VideoTalkView.h"

#undef TAG
#define TAG @"IncomingCallView"

#define PANEL_PADDING   8
#define PANEL_HEIGHT    82
#define TRACK_EDGE_SIZE 3

#define MENU_ACCEPT          I18nString(@"接受为视频通话")
#define MENU_ACCEPT_AS_AUDIO I18nString(@"接受为语音通话")

@implementation IncomingCallView {
    NSString *_phonenumber;
    Contact *_contact;
    BOOL _isVideoCall;

    UIView *_nameNumberPanel;
    UIImageView *_avatarView;
    UILabel *_nameNumber;
    UIImageView *_logoView;

    UIView *_toolBar;
    UIButton *_btnAction;

    UIImageView *_bgSliderAccept;
    UILabel *_hintSliderAccept;
    UISlider *_sliderAccept;
}

- (id)initWithNumber:(NSString *)number andContact:(Contact *)contact hasVideo:(BOOL)hasVideo {
    self = [super init];
    if (self) {
        _phonenumber = number;
        _contact = contact;
        _isVideoCall = hasVideo;
        self.title = (hasVideo ? I18nString(@"视频来电") : I18nString(@"语音来电"));
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat fullWidth = self.view.frame.size.width;
    CGFloat fullHeight = self.view.frame.size.height;

    CGRect rect = _nameNumberPanel.frame;
    rect.size.width = fullWidth;
    _nameNumberPanel.frame = rect;

    rect = _avatarView.frame;
    rect.origin = CGPointMake(PANEL_PADDING, PANEL_PADDING);
    _avatarView.frame = rect;

    rect = _nameNumber.frame;
    rect.origin.x = CGRectGetMaxX(_avatarView.frame) + PANEL_PADDING;
    rect.origin.y = PANEL_PADDING;
    rect.size.width = fullWidth - PANEL_PADDING - rect.origin.x;
    rect.size.height = _avatarView.frame.size.height;
    _nameNumber.frame = rect;

    rect = _logoView.frame;
    rect.origin.x = (fullWidth - rect.size.width) / 2;
    rect.origin.y = (fullHeight - rect.size.height) / 2;
    _logoView.frame = rect;

    rect = _toolBar.frame;
    rect.origin.y = fullHeight - rect.size.height;
    rect.size.width = fullWidth;
    _toolBar.frame = rect;

    rect = _btnAction.frame;
    rect.origin.y = (_toolBar.frame.size.height - rect.size.height) / 2;
    rect.origin.x = fullWidth - PANEL_PADDING - rect.size.width;
    _btnAction.frame = rect;

    rect = _bgSliderAccept.frame;
    rect.origin.x = PANEL_PADDING;
    rect.origin.y = (_toolBar.frame.size.height - rect.size.height) / 2;
    rect.size.width = _btnAction.frame.origin.x - PANEL_PADDING - rect.origin.x;
    _bgSliderAccept.frame = rect;
    _hintSliderAccept.frame = rect;

    rect.origin.x += TRACK_EDGE_SIZE;
    rect.size.width -= TRACK_EDGE_SIZE * 2;
    _sliderAccept.frame = rect;
}

- (void)setView:(UIView *)v borderColor:(NSUInteger)hexColor {
    v.layer.borderWidth = 1;
    v.layer.borderColor = [UIColor colorFromHex:hexColor].CGColor;
    v.layer.shadowColor = [UIColor blackColor].CGColor;
    v.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    v.layer.shadowOpacity = 0.7;
    v.layer.shadowRadius = 0.5;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    _nameNumberPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PANEL_HEIGHT, PANEL_HEIGHT)];
    _nameNumberPanel.backgroundColor = [UIColor colorFromHex:0x610D4241];
    [self setView:_nameNumberPanel borderColor:0x2FCDFCFB];
    [self.view addSubview:_nameNumberPanel];

    UIImage *avatar = _contact.photo;
    if (avatar == nil) {
        avatar = [UIImage imageNamed:@"res/chat_default_avatar"];
    }
    _avatarView = [[UIImageView alloc] initWithImage:avatar];
    [self setView:_avatarView borderColor:0xF0FFFFFF];
    [_nameNumberPanel addSubview:_avatarView];

    _nameNumber = [[UILabel alloc] init];
    _nameNumber.backgroundColor = [UIColor colorFromHex:0x610D4241];
    _nameNumber.textColor = [UIColor colorFromHex:0xFF72FED7];
    _nameNumber.font = [UIFont systemFontOfSize:15];
    _nameNumber.textAlignment = UITextAlignmentCenter;
    _nameNumber.numberOfLines = 2;
    _nameNumber.shadowColor = [UIColor colorFromHex:0x80C0C0C0];
    _nameNumber.shadowOffset = CGSizeMake(0, -0.5);
    _nameNumber.text = [NSString stringWithFormat:@"%@\n%@", _contact.displayName, _phonenumber];
    [self setView:_nameNumber borderColor:0x2FCDFCFB];
    [_nameNumberPanel addSubview:_nameNumber];

    if (_isVideoCall) {
        _logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/phonecall_incoming_video_logo"]];
    } else {
        _logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/phonecall_incoming_audio_logo"]];
    }
    [self.view addSubview:_logoView];

    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PANEL_HEIGHT, PANEL_HEIGHT)];
    _toolBar.backgroundColor = [UIColor colorFromHex:0x4D4A4A4A];
    [self setView:_toolBar borderColor:0x5CFFFFFF];
    [self.view addSubview:_toolBar];

    UIImage *sliderBgImg = [[UIImage imageNamed:@"res/phonecall_toolbar_switch_background"] resizeFromCenter];
    _bgSliderAccept = [[UIImageView alloc] initWithImage:sliderBgImg];
    [_toolBar addSubview:_bgSliderAccept];

    _hintSliderAccept = [[UILabel alloc] init];
    _hintSliderAccept.backgroundColor = [UIColor clearColor];
    _hintSliderAccept.textColor = [UIColor colorFromHex:0xFF90FFD7];
    _hintSliderAccept.font = [UIFont systemFontOfSize:17];
    _hintSliderAccept.textAlignment = UITextAlignmentCenter;
    _hintSliderAccept.shadowColor = [UIColor colorFromHex:0x80C0C0C0];
    _hintSliderAccept.shadowOffset = CGSizeMake(0, -0.5);
    _hintSliderAccept.text = I18nString(@"滑动接听");
    [_toolBar addSubview:_hintSliderAccept];

    UIImage *thumbImg = [UIImage imageNamed:@"res/phonecall_toolbar_switch_nob"];
    UIImage *transBgImg = [UIImage imageNamed:@"res/tranparent_slider_bg"];
    _sliderAccept = [[UISlider alloc] init];
    _sliderAccept.backgroundColor = [UIColor clearColor];
    _sliderAccept.continuous = YES;
    _sliderAccept.center = _bgSliderAccept.center;
    [_sliderAccept setMinimumTrackImage:transBgImg forState:UIControlStateHighlighted];
    [_sliderAccept setMinimumTrackImage:transBgImg forState:UIControlStateNormal];
    [_sliderAccept setMaximumTrackImage:transBgImg forState:UIControlStateHighlighted];
    [_sliderAccept setMaximumTrackImage:transBgImg forState:UIControlStateNormal];
    [_sliderAccept setThumbImage:thumbImg forState:UIControlStateHighlighted];
    [_sliderAccept setThumbImage:thumbImg forState:UIControlStateNormal];
    [_sliderAccept addTarget:self action:@selector(onSliderDragUp:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:_sliderAccept];

    _btnAction = [UIButton buttonWithImageName:@"res/phonecall_toolbar_hangup" andTarget:self andAction:@selector(cancelCall)];
    [_toolBar addSubview:_btnAction];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

#pragma mark - selector methods

- (void)cancelCall {
    [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(cancelCall) withObject:nil];
}

- (void)onSliderDragUp:(UISlider *)slider {
    if (slider.value == slider.maximumValue) {
        if (_isVideoCall) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                     delegate:self
                                                            cancelButtonTitle:I18nString(@"取消")
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:MENU_ACCEPT, MENU_ACCEPT_AS_AUDIO, nil];
            actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            [actionSheet showInView:self.view];
        } else if ([[UcaAppDelegate sharedInstance].callingService acceptCall]) {
            AudioTalkView *view = [[AudioTalkView alloc] init];
            [self.navigationController pushViewController:view animated:YES];
        }
    } else {
        [slider setValue:0 animated:YES];
    }
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [_sliderAccept setValue:0 animated:YES];
        return;
    }

    if (![[UcaAppDelegate sharedInstance].callingService acceptCall]) {
        [_sliderAccept setValue:0 animated:YES];
        return;
    }

    NSString *menuTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([menuTitle isEqualToString:MENU_ACCEPT]) {
        VideoTalkView *view = [[VideoTalkView alloc] init];
        [self.navigationController pushViewController:view animated:YES];
    } else if ([menuTitle isEqualToString:MENU_ACCEPT_AS_AUDIO]) {
        AudioTalkView *view = [[AudioTalkView alloc] init];
        [self.navigationController pushViewController:view animated:YES];
    }
}

@end
