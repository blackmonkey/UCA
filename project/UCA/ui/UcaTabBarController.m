/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaTabBarController.h"
#import "UcaTabBarButton.h"
#import "OrgViewController.h"
#import "ContactsListView.h"
#import "DialerView.h"
#import "AccountDetailsView.h"
#import "MoreMenuView.h"

#undef TAG
#define TAG @"UcaTabBarController"

#define TAB_IDX_ORG     (0)
#define TAB_IDX_CONTACT (1)
#define TAB_IDX_DIALOUT (2)
#define TAB_IDX_MYINFO  (3)
#define TAB_IDX_MORE    (4)

@implementation UcaTabBarController {
    NSArray *_tabButtons;
    NSArray *_tabControllers;

    UcaTabBarButton *_contactBtn;
    UcaTabBarButton *_myInfoBtn;
    ContactsListView *_contactViewCtrl;
}

- (void)updateUnreadInfo {
    NSUInteger count = [[UcaAppDelegate sharedInstance].messageService countOfUnreadMessages];
    if (count > 0) {
        [_contactBtn showBadge];
    } else {
        [_contactBtn hideBadge];
    }
}

- (void)updatePresent {
    UIImage *icon = [UcaConstants iconOfPresentation:[UcaAppDelegate sharedInstance].accountService.curPresent];
    [_myInfoBtn setBadge:icon];
}

- (void)onButtonClicked:(id)btn {
    [self setSelectedViewController:[_tabControllers objectAtIndex:[btn tag]]];
}

- (UcaTabBarButton *)createTabButton:(NSString *)iconName title:(NSString *)title tag:(NSInteger)tag {
    UcaTabBarButton *btn = [[UcaTabBarButton alloc] initWithTitle:title imageName:iconName tag:tag];
    [btn addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UcaTabBarButton *)createContactTabButton:(NSString *)iconName title:(NSString *)title tag:(NSInteger)tag {
    _contactBtn = [self createTabButton:iconName title:title tag:tag];
    [_contactBtn setBadge:[UIImage imageNamed:@"res/tabbar_item_message"]
                   margin:3.0
                   hAlign:UIControlContentHorizontalAlignmentRight
                   vAlign:UIControlContentVerticalAlignmentTop
                    blink:YES];
    return _contactBtn;
}

- (UcaTabBarButton *)createMyInfoTabButton:(NSString *)iconName title:(NSString *)title tag:(NSInteger)tag {
    _myInfoBtn = [self createTabButton:iconName title:title tag:tag];
    [_myInfoBtn setBadge:[UIImage imageNamed:@"res/status_offline"]
                  margin:1.0
                  hAlign:UIControlContentHorizontalAlignmentRight
                  vAlign:UIControlContentVerticalAlignmentBottom
                   blink:NO];
    [_myInfoBtn showBadge];
    return _myInfoBtn;
}

- (id)init {
    self = [super init];
    if (self) {
        _tabButtons = [NSArray arrayWithObjects:
                       [self createTabButton:@"res/tabbar_item_org" title:I18nString(@"组织架构") tag:TAB_IDX_ORG],
                       [self createContactTabButton:@"res/tabbar_item_contact" title:I18nString(@"联系人") tag:TAB_IDX_CONTACT],
                       [self createTabButton:@"res/tabbar_item_dialout" title:I18nString(@"拨号盘") tag:TAB_IDX_DIALOUT],
                       [self createMyInfoTabButton:@"res/tabbar_item_myinfo" title:I18nString(@"我的信息") tag:TAB_IDX_MYINFO],
                       [self createTabButton:@"res/tabbar_item_more" title:I18nString(@"更多组件") tag:TAB_IDX_MORE],
                       nil];

        _contactViewCtrl = [[ContactsListView alloc] init];
        UIViewController *orgViewCtrl      = [[OrgViewController alloc] init];
        UIViewController *numpadViewCtrl   = [[DialerView alloc] init];
        UIViewController *accountViewCtrl  = [[AccountDetailsView alloc] init];
        UIViewController *moreViewCtrl     = [[MoreMenuView alloc] init];

        UcaNavigationController *navOrgViewCtrl      = [[UcaNavigationController alloc] initWithRootViewController:orgViewCtrl];
        UcaNavigationController *navContactsViewCtrl = [[UcaNavigationController alloc] initWithRootViewController:_contactViewCtrl];
        UcaNavigationController *navNumpadViewCtrl   = [[UcaNavigationController alloc] initWithRootViewController:numpadViewCtrl];
        UcaNavigationController *navAccountViewCtrl  = [[UcaNavigationController alloc] initWithRootViewController:accountViewCtrl];
        UcaNavigationController *navMoreViewCtrl     = [[UcaNavigationController alloc] initWithRootViewController:moreViewCtrl];

        _tabControllers = [NSArray arrayWithObjects: navOrgViewCtrl, navContactsViewCtrl, navNumpadViewCtrl,
                           navAccountViewCtrl, navMoreViewCtrl, nil];
        [self setViewControllers:_tabControllers animated:YES];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIImage *tabBarBg = [UIImage imageNamed:@"res/tabbar_background"];
    if ([self.tabBar respondsToSelector:@selector(setBackgroundImage:)]) {
        [self.tabBar setBackgroundImage:tabBarBg];
    } else {
        // TODO: implement
    }

    for (NSUInteger i = 0, btnIdx = 0; i < [self.tabBar.subviews count] && btnIdx < [_tabButtons count]; i++) {
        UIView *v = (UIView *)[self.tabBar.subviews objectAtIndex:i];

        if ([[self.tabBar.subviews objectAtIndex:i] isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            UIButton *btn = (UIButton *)[_tabButtons objectAtIndex:btnIdx];
            btn.frame = v.frame;
            v.hidden = YES;
            [self.tabBar addSubview:btn];

            btnIdx++;
        }
    }

    [self updateUnreadInfo];
    if ([[[UcaAppDelegate sharedInstance].contactService getRecentContacts] count] > 0) {
        [_contactViewCtrl setFilterMode:FilterMode_Favourite];
        [self setSelectedIndex:TAB_IDX_CONTACT];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUnreadInfo)
                                                 name:UCA_EVENT_ADD_MESSAGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUnreadInfo)
                                                 name:UCA_EVENT_UPDATE_MESSAGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUnreadInfo)
                                                 name:UCA_EVENT_UPDATE_MESSAGES
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUnreadInfo)
                                                 name:UCA_EVENT_DELETE_MESSAGES
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePresent)
                                                 name:UCA_EVENT_UPDATE_PRESENT_OK
                                               object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateButtonsState:(NSUInteger)idx {
    for (NSUInteger i = 0; i < [_tabButtons count]; i++) {
        UIButton *btn = (UIButton *)[_tabButtons objectAtIndex:i];
        [btn setSelected:(i == idx)];
    }
}

- (void)setSelectedViewController:(UIViewController *)viewController {
    [super setSelectedViewController:viewController];

    NSUInteger idx = [_tabControllers indexOfObject:viewController];
    if (idx == NSNotFound) {
        return;
    }
    [self updateButtonsState:idx];
}

- (void)setSelectedIndex:(NSUInteger)idx {
    [super setSelectedIndex:idx];
    [self updateButtonsState:idx];
}

@end
