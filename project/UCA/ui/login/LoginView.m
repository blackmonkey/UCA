/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "LoginView.h"

#undef TAG
#define TAG @"LoginView"

#define TAG_LOGIN_RESULT_ALERT     (100)
#define TAG_CONFIRM_SWITCH_ACCOUNT (101)

@implementation LoginView {
    BOOL _canSwitchView;
    BOOL _requestSwitchAccount;
    Account *_account;

    UIAlertView *_confirmSwitchAlert;
    UIAlertView *_loginResultAlert;

    UIImageView *_avatarView;
    UILabel *_lbUserInfo;
    UILabel *_lbLoginInfo;
    UIActivityIndicatorView *_indicatorView;
}

- (void)dismissSwitchAlert {
    if ([_confirmSwitchAlert isVisible]) {
        [_confirmSwitchAlert dismissWithClickedButtonIndex:_confirmSwitchAlert.cancelButtonIndex
                                                  animated:YES];
    }
    _confirmSwitchAlert = nil;
}

/**
 * Back to login view when the user wanna switch account or the current account logins failed.
 * In either case,
 */
- (void)backToLoginView {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_indicatorView stopAnimating];

    [self dismissSwitchAlert];
    self.navigationItem.rightBarButtonItem = nil;

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    [app.accountService resetCurrentStatus];
    [app showLoginView];
}

- (void)forwardToTabviews {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_indicatorView stopAnimating];

    [self dismissSwitchAlert];
    self.navigationItem.rightBarButtonItem = nil;

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    app.accountService.curAccountId = _account.id;
    [app showTabViews];
}

- (void)confirmSwitchAccount {
    if (_requestSwitchAccount || _confirmSwitchAlert != nil) {
        return;
    }

    _confirmSwitchAlert = [[UIAlertView alloc] initWithTitle:I18nString(@"切换帐号会终止当前账号的登录，确定继续吗？")
                                                     message:nil
                                                    delegate:self
                                           cancelButtonTitle:I18nString(@"取消")
                                           otherButtonTitles:I18nString(@"确定"), nil];
    _confirmSwitchAlert.tag = TAG_CONFIRM_SWITCH_ACCOUNT;
    [_confirmSwitchAlert show];
}

- (void)trySwitchAccount {
    @synchronized (self) {
        _requestSwitchAccount = YES;
        _lbLoginInfo.text = I18nString(@"等待切换账号⋯⋯");

        UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
        UcaAccountService *service = app.accountService;
        if ([service isLoggedIn] || [service isLoggedOut] || [service isLoggedInFailed]) {
            [self backToLoginView];
        }
    }
}

- (void)updateSubViews:(NSNotification *)note {
    @synchronized (self) {
        UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
        UcaAccountService *service = app.accountService;

        NSString *statusMsg = [UcaConstants descriptionOfLoginStatus:service.curLoginStatus];
        if (_requestSwitchAccount) {
            _lbLoginInfo.text = I18nString(@"等待切换账号⋯⋯");
        } else {
            _lbLoginInfo.text = statusMsg;
        }

        if ([service isLoggedIn]) {
            [service synchAccount:_account];

            if (_requestSwitchAccount) {
                [self backToLoginView];
                return;
            }

            _lbLoginInfo.text = I18nString(@"正在更新帐号信息⋯⋯");

            service.curAccountId = _account.id;
            [service synchCurrentAccountFromServer];

            if (_requestSwitchAccount) {
                [self backToLoginView];
                return;
            }

            if (_canSwitchView) {
                _canSwitchView = NO;
                [self forwardToTabviews];
            }
        } else if ([service isLoggedOut]) {
            [self backToLoginView];
        } else if ([service isLoggedInFailed]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [_indicatorView stopAnimating];

            if (_requestSwitchAccount) {
                [self backToLoginView];
                return;
            }

            [self dismissSwitchAlert];

            if (!_loginResultAlert) {
                if (_account.id == NOT_SAVED) {
                    _loginResultAlert = [[UIAlertView alloc] initWithTitle:statusMsg
                                                                   message:nil
                                                                  delegate:self
                                                         cancelButtonTitle:I18nString(@"返回登录界面")
                                                         otherButtonTitles:nil];
                } else {
                    _loginResultAlert = [[UIAlertView alloc] initWithTitle:statusMsg
                                                                   message:nil
                                                                  delegate:self
                                                         cancelButtonTitle:I18nString(@"返回登录界面")
                                                         otherButtonTitles:I18nString(@"进入离线模式"), nil];
                }
                _loginResultAlert.tag = TAG_LOGIN_RESULT_ALERT;
                [_loginResultAlert show];
            } else {
                _loginResultAlert.title = statusMsg;
                if (_loginResultAlert.hidden) {
                    _loginResultAlert.hidden = NO;
                }
            }
        }
    }
}

- (id)initWithAccount:(Account *)account {
    self = [super init];
    if (self) {
        self.title = I18nString(@"登录");
        _canSwitchView = YES;
        _requestSwitchAccount = NO;
        _account = account;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    _account = nil;
    _confirmSwitchAlert = nil;
    _loginResultAlert = nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat fullWidth = self.view.frame.size.width;

    CGRect rect = _avatarView.frame;
    rect.origin.x = 0;
    rect.origin.y = -40;
    _avatarView.frame = rect;

    rect = _lbUserInfo.frame;
    rect.origin.x = 0;
    rect.origin.y = 267;
    rect.size.width = fullWidth;
    rect.size.height = 30;
    _lbUserInfo.frame = rect;

    rect = _lbLoginInfo.frame;
    rect.origin.x = 0;
    rect.origin.y = 302;
    rect.size.width = fullWidth;
    rect.size.height = 21;
    _lbLoginInfo.frame = rect;

    rect = _indicatorView.frame;
    rect.origin.x = (fullWidth - rect.size.width) / 2;
    rect.origin.y = 329;
    _indicatorView.frame = rect;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:I18nString(@"切换帐号")
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(confirmSwitchAccount)];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateSubViews:)
                                                 name:UCA_EVENT_UPDATE_LOGIN_STATUS
                                               object:nil];

    self.view.backgroundColor = [UIColor clearColor];

    _avatarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/login_avatar"]];
    [self.view addSubview:_avatarView];

    _lbUserInfo = [[UILabel alloc] init];
    _lbUserInfo.backgroundColor = [UIColor clearColor];
    _lbUserInfo.textColor = [UIColor whiteColor];
    _lbUserInfo.font = [UIFont boldSystemFontOfSize:18];
    _lbUserInfo.textAlignment = UITextAlignmentCenter;
    _lbUserInfo.text = [NSString stringWithFormat:@"%@ @ %@", _account.username, _account.serverParam.ip];
    [self.view addSubview:_lbUserInfo];

    _lbLoginInfo = [[UILabel alloc] init];
    _lbLoginInfo.backgroundColor = [UIColor clearColor];
    _lbLoginInfo.textColor = [UIColor whiteColor];
    _lbLoginInfo.font = [UIFont systemFontOfSize:14];
    _lbLoginInfo.textAlignment = UITextAlignmentCenter;
    _lbLoginInfo.text = I18nString(@"正在登录⋯⋯");
    [self.view addSubview:_lbLoginInfo];

    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_indicatorView startAnimating];
    [self.view addSubview:_indicatorView];

    [[UcaAppDelegate sharedInstance].accountService performSelectorInBackground:@selector(requestLogin:)
                                                                     withObject:_account];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _account = nil;
    _confirmSwitchAlert = nil;
    _loginResultAlert = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self dismissSwitchAlert];
    if ([_loginResultAlert isVisible]) {
        _loginResultAlert.hidden = YES;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

#pragma UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)_alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];

    if (_alertView.tag == TAG_LOGIN_RESULT_ALERT) {
        [app.accountService tryClearLoginInfo];
        _loginResultAlert = nil;

        if (buttonIndex == _alertView.cancelButtonIndex) { // back to login view
            [self backToLoginView];
        } else if (buttonIndex == _alertView.firstOtherButtonIndex) { // offline mode
            [self forwardToTabviews];
        }
    } else if (_alertView.tag == TAG_CONFIRM_SWITCH_ACCOUNT) {
        _confirmSwitchAlert = nil;

        if (buttonIndex == _alertView.firstOtherButtonIndex) { // confirm switch
            [self trySwitchAccount];
        }
    }
}

@end
