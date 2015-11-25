/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "MoreMenuView.h"
#import "HelpIndexesView.h"
#import "SettingView.h"
#import "UcaToolButton.h"

#define PADDING 20

@implementation MoreMenuView {
    UcaToolButton *_btnHelp;
    UcaToolButton *_btnSetting;
    UcaToolButton *_btnSwitch;
}

- (id)init {
    self = [super init];
    if (self) {
        self.title = I18nString(@"更多组件");
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect rect = _btnHelp.frame;
    rect.origin = CGPointMake(PADDING, PADDING);
    _btnHelp.frame = rect;

    rect = _btnSetting.frame;
    rect.origin = CGPointMake(CGRectGetMaxX(_btnHelp.frame) + PADDING, PADDING);
    _btnSetting.frame = rect;

    rect = _btnSwitch.frame;
    rect.origin = CGPointMake(CGRectGetMaxX(_btnSetting.frame) + PADDING, PADDING);
    _btnSwitch.frame = rect;
}

- (UcaToolButton *)createButton:(NSString *)title iconName:(NSString *)iconName {
    UcaToolButton *btn = [[UcaToolButton alloc] initWithTitle:title
                                                    imageName:iconName
                                             pressedImageName:[iconName stringByAppendingString:@"_pressed"]
                                                     fontSize:14];
    btn.titleLabel.shadowColor = [UIColor colorFromHex:0x80C0C0C0];
    btn.titleLabel.shadowOffset = CGSizeMake(0, -0.5);
    return btn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    _btnHelp = [self createButton:I18nString(@"帮 助") iconName:@"res/help_entry"];
    [_btnHelp addTarget:self action:@selector(showHelpIndexes) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnHelp];

    _btnSetting = [self createButton:I18nString(@"设 置") iconName:@"res/setting_entry"];
    [_btnSetting addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnSetting];

    _btnSwitch = [self createButton:I18nString(@"切换用户") iconName:@"res/switch_account_entry"];
    [_btnSwitch addTarget:self action:@selector(switchAccount) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnSwitch];
}

- (void)showHelpIndexes {
    HelpIndexesView *view = [[HelpIndexesView alloc] init];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)showSettings {
    SettingView *view = [[SettingView alloc] init];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)switchAccount {
    [NotifyUtils confirm:I18nString(@"确定要切换用户？") delegate:self];
}

- (void)switchAccountConfirm {
    [NotifyUtils postNotificationWithName:UCA_EVENT_SHUTDOWN_TABS];
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    if ([app.accountService isLoggedIn]) {
        [app.accountService performSelectorInBackground:@selector(requestLogout) withObject:nil];
    }
    [app.contactService stop];
    [app showLoginView];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self switchAccountConfirm];
    } else { // cancel

    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

@end
