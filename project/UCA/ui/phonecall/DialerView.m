/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "DialerView.h"

@interface DialerView()
- (void)tryRefreshDataAndReload;
@end

@implementation DialerView {
    UIView *_padPanel;
    NumPadView *_numPad;
    UIImageView *_bgToolBar;
    UIButton *_btnVideoCall;
    UIButton *_btnAudioCall;
    UIButton *_btnHideNumPad;
    UIButton *_btnShowNumPad;

    NSArray *_contacts;
    NSString *_filterNumber;
    BOOL _refreshing;
    BOOL _toRefresh;

    // 呼叫转移相关成员
    BOOL _transferCall;
    BOOL _isVideoCall;
}

- (id)init {
    QRootElement *form = [[QRootElement alloc] init];
    form.title = I18nString(@"拨号盘");

    QSection *section = [[QSection alloc] init];
    section.key = nil;

    [form addSection:section];

    self = [super initWithRoot:form];
    if (self) {
        self.title = form.title;
        _refreshing = NO;
        _toRefresh = NO;
        _transferCall = NO;
        _isVideoCall = NO;
    }
    return self;
}

- (id)initToTransferCallWithVideo:(BOOL)hasVideo {
    self = [self init];
    if (self) {
        self.title = self.root.title = I18nString(@"通话转移");
        _transferCall = YES;
        _isVideoCall = hasVideo;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat fullWidth = self.view.frame.size.width;
    CGFloat fullHeight = self.view.frame.size.height;

    CGRect rect = self.quickDialogTableView.frame;
    rect.origin = CGPointZero;
    rect.size = self.view.frame.size;
    self.quickDialogTableView.frame = rect;

    rect = _btnShowNumPad.frame;
    rect.origin.x = (fullWidth - rect.size.width) / 2;
    rect.origin.y = fullHeight - rect.size.height;
    _btnShowNumPad.frame = rect;

    rect = _padPanel.frame;
    rect.size.width = fullWidth;
    rect.size.height = _numPad.height + _bgToolBar.frame.size.height;
    rect.origin.x = 0;
    rect.origin.y = fullHeight - rect.size.height;
    _padPanel.frame = rect;

    rect = _numPad.frame;
    rect.origin = CGPointZero;
    rect.size.width = fullWidth;
    rect.size.height = _numPad.height;
    _numPad.frame = rect;

    rect = _bgToolBar.frame;
    rect.origin.x = 0;
    rect.origin.y = _numPad.height;
    rect.size.width = fullWidth;
    _bgToolBar.frame = rect;

    CGFloat cellWidth = fullWidth / 3;

    rect = _btnVideoCall.frame;
    rect.origin.x = (cellWidth - rect.size.width) / 2;
    rect.origin.y = _bgToolBar.frame.origin.y + (_bgToolBar.frame.size.height - rect.size.height) / 2;
    _btnVideoCall.frame = rect;

    rect = _btnHideNumPad.frame;
    rect.origin.x = cellWidth + (cellWidth - rect.size.width) / 2;
    rect.origin.y = _bgToolBar.frame.origin.y + (_bgToolBar.frame.size.height - rect.size.height) / 2;
    _btnHideNumPad.frame = rect;

    rect = _btnAudioCall.frame;
    rect.origin.x = cellWidth * 2 + (cellWidth - rect.size.width) / 2;
    rect.origin.y = _bgToolBar.frame.origin.y + (_bgToolBar.frame.size.height - rect.size.height) / 2;
    _btnAudioCall.frame = rect;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.quickDialogTableView.backgroundColor = [UIColor clearColor];
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.view.backgroundColor = [UIColor clearColor];

    _btnShowNumPad = [UIButton buttonWithImageName:@"res/numpad_toolbar_show_button" andTarget:self andAction:@selector(showNumPad)];
    [self.view addSubview:_btnShowNumPad];

    _padPanel = [[UIView alloc] init];
    _padPanel.backgroundColor = [UIColor clearColor];

    _numPad = [[NumPadView alloc] initWithCanBackspace:YES];
    _numPad.delegate = self;
    [_padPanel addSubview:_numPad];

    _bgToolBar = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"res/toolbar_background"] resizeFromCenter]];
    [_padPanel addSubview:_bgToolBar];

    if (!_transferCall) {
        _btnVideoCall = [UIButton buttonWithImageName:@"res/numpad_toolbar_video_call_button" andTarget:self andAction:@selector(startVideoCall)];
        [_padPanel addSubview:_btnVideoCall];
    } else if (_isVideoCall) {
        _btnVideoCall = [UIButton buttonWithImageName:@"res/numpad_toolbar_video_call_button" andTarget:self andAction:@selector(startTransferCall)];
        [_padPanel addSubview:_btnVideoCall];
    }

    _btnHideNumPad = [UIButton buttonWithImageName:@"res/numpad_toolbar_hide_button" andTarget:self andAction:@selector(hideNumPad)];
    [_padPanel addSubview:_btnHideNumPad];

    if (!_transferCall) {
        _btnAudioCall = [UIButton buttonWithImageName:@"res/numpad_toolbar_audio_call_button" andTarget:self andAction:@selector(startAudioCall)];
        [_padPanel addSubview:_btnAudioCall];
    } else if (!_isVideoCall) {
        _btnAudioCall = [UIButton buttonWithImageName:@"res/numpad_toolbar_audio_call_button" andTarget:self andAction:@selector(startTransferCall)];
        [_padPanel addSubview:_btnAudioCall];
    }

    [self.view addSubview:_padPanel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self tryRefreshDataAndReload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

#pragma mark - selector methods

- (void)showNumPad {
    [UIView beginAnimations:@"showNumPad" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDuration:0.28f];

    CGRect rect = _padPanel.frame;
    rect.origin.y = self.view.frame.size.height - rect.size.height;
    _padPanel.frame = rect;

    [UIView commitAnimations];
}

- (void)hideNumPad {
    [UIView beginAnimations:@"hideNumPad" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDuration:0.28f];

    CGRect rect = _padPanel.frame;
    rect.origin.y = self.view.frame.size.height;
    _padPanel.frame = rect;

    [UIView commitAnimations];
}

- (void)startVideoCall {
    [[UcaAppDelegate sharedInstance].callingService dialOut:_numPad.phoneNumber
                                                  withVideo:YES
                                         fromViewController:self];
}

- (void)startAudioCall {
    [[UcaAppDelegate sharedInstance].callingService dialOut:_numPad.phoneNumber
                                                  withVideo:NO
                                         fromViewController:self];
}

- (void)startTransferCall {
    [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(transferCall:)
                                                                     withObject:_numPad.phoneNumber];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)refreshDataAndReload {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
#endif

    @synchronized (_contacts) {
        _refreshing = YES;

        QSection *section = [self.root getSectionForIndex:0];
        if (!section) {
            section = [[QSection alloc] init];
            section.key = nil;
            [self.root addSection:section];
        }
        [section.elements removeAllObjects];

        if (_numPad.phoneNumber.length > 0) {
            _btnVideoCall.enabled = YES;
            _btnAudioCall.enabled = YES;
            _contacts = [[UcaAppDelegate sharedInstance].contactService getContactsByPhoneNumber:_numPad.phoneNumber];
        } else {
            _btnVideoCall.enabled = NO;
            _btnAudioCall.enabled = NO;
            _contacts = nil;
        }

        for (Contact *contact in _contacts) {
            ContactElement *element = [[ContactElement alloc] initWithContact:contact andDelegate:self];
            [section addElement:element];
        }

        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];

        _refreshing = NO;

        if (_toRefresh) {
            _toRefresh = NO;
            [self refreshDataAndReload];
        }
    }
}

- (void)tryRefreshDataAndReload {
    if (_refreshing) {
        _toRefresh = YES;
    } else {
        [self refreshDataAndReload];
    }
}

#pragma mark - NumPadViewDelegate methods

- (void)numPadView:(NumPadView *)padView changedNumber:(NSString *)number {
    _filterNumber = number;
    [self tryRefreshDataAndReload];
}

#pragma mark - ContactElementDelegate methods

- (void)contactElementOnClicked:(ContactElement *)element {
    Contact *contact = element.contact;
    NSString *number = [contact numberMatched:_filterNumber];
    NSLog(@"contactElementOnClicked() number = '%@'", number);
    if ([NSString isNullOrEmpty:number]) {
        return;
    }

    _numPad.phoneNumber = number;
    if (_padPanel.frame.origin.y == self.view.frame.size.height) { // NumPad is hidden
        [self showNumPad];
    }
}

@end
