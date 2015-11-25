/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "GroupDetailsEntry.h"
#import "UcaDetailButton.h"
#import "GroupDetailsView.h"
#import "ContactOperationListView.h"
#import "GroupListView.h"
#import "MessageChatView.h"

#define HEADER_WIDTH    260
#define HEADER_HEIGHT   144
#define BTN_SHORT_WIDTH 124
#define BTN_WIDTH       260
#define BTN_HEIGHT      32
#define ITEM_PADDING    5

#define MENU_ADD_GROUP_MEMBER                  I18nString(@"添加群成员")
#define MENU_ADD_GROUP_MEMBER_FROM_ORG         I18nString(@"从组织架构添加")
#define MENU_ADD_GROUP_MEMBER_FROM_FRIEND      I18nString(@"从好友添加")
#define MENU_ADD_GROUP_MEMBER_FROM_OTHER_GROUP I18nString(@"从其他群组添加")
#define MENU_ADD_GROUP_MEMBER_FROM_RECENTS     I18nString(@"从最近联系人添加")

@implementation GroupDetailsEntry {
    Group *_group;

    UIImageView *_bgView;
    UIImageView *_headerBgView;
    UIImageView *_avatarView;
    UILabel *_annunciateView;
    UcaDetailButton *_btnIm;
    UcaDetailButton *_btnRecentLog;
    UcaDetailButton *_btnViewMember;
    UcaDetailButton *_btnAddMember;
    UcaDetailButton *_btnViewDetails;
}

- (id)initWithGroup:(Group *)group {
    self = [super init];
    if (self) {
        _group = group;
        self.title = _group.name;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];

    CGRect rect;
    self.view.backgroundColor = [UIColor clearColor];

    _bgView = [[UIImageView alloc] initWithImage:[UIImage detailBackground]];
    [self.view addSubview:_bgView];

    _headerBgView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"res/detail_cell_background"] resizeFromCenter]];
    rect = _headerBgView.frame;
    rect.size = CGSizeMake(HEADER_WIDTH, HEADER_HEIGHT);
    _headerBgView.frame = rect;
    [self.view addSubview:_headerBgView];

    UIImage *defaultAvatar = [UIImage imageNamed:@"res/group_info_default_avatar"];
    _avatarView = [[UIImageView alloc] initWithImage:defaultAvatar];
    if (_group.photo) {
        _avatarView.image = _group.photo;
    }
    rect = _avatarView.frame;
    rect.size = defaultAvatar.size;
    _avatarView.frame = rect;
    [self.view addSubview:_avatarView];

    _annunciateView = [[UILabel alloc] init];
    _annunciateView.backgroundColor = [UIColor clearColor];
    _annunciateView.text = _group.annunciate;
    _annunciateView.font = [UIFont systemFontOfSize:13];
    _annunciateView.textColor = [UIColor colorFromHex:0xFFFC9D65];
    _annunciateView.numberOfLines = 0;
    rect = _annunciateView.frame;
    rect.size.width = _headerBgView.frame.size.width - _avatarView.frame.size.width - ITEM_PADDING * 2;
    rect.size.height = _avatarView.frame.size.height;
    _annunciateView.frame = rect;
    [self.view addSubview:_annunciateView];

    CGSize shortBtnSize = CGSizeMake(BTN_SHORT_WIDTH, BTN_HEIGHT);
    _btnIm = [[UcaDetailButton alloc] initWithTitle:I18nString(@"即时消息") imageName:@"res/detail_im" frameSize:shortBtnSize];
    [_btnIm addTarget:self action:@selector(viewIm:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnIm];

    _btnRecentLog = [[UcaDetailButton alloc] initWithTitle:I18nString(@"最近通讯") imageName:@"res/detail_recent" frameSize:shortBtnSize];
    [_btnRecentLog addTarget:self action:@selector(viewRecentLog:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnRecentLog];

    _btnViewMember = [[UcaDetailButton alloc] initWithTitle:I18nString(@"查看群成员") imageName:@"res/group_view_member" frameSize:shortBtnSize];
    [_btnViewMember addTarget:self action:@selector(viewMember:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnViewMember];

    _btnViewDetails = [[UcaDetailButton alloc] initWithTitle:I18nString(@"查看完整档案") imageName:nil frameSize:shortBtnSize];
    [_btnViewDetails addTarget:self action:@selector(viewDetails:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnViewDetails];

    if ([_group canAdmin]) {
        _btnAddMember = [[UcaDetailButton alloc] initWithTitle:MENU_ADD_GROUP_MEMBER imageName:@"res/group_add_member" frameSize:shortBtnSize];
        [_btnAddMember addTarget:self action:@selector(addMember:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_btnAddMember];

        rect = _btnViewDetails.frame;
        rect.size.width = BTN_WIDTH;
        _btnViewDetails.frame = rect;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    CGRect rect = _bgView.frame;
    rect.origin.x = (self.view.frame.size.width - rect.size.width) / 2;
    rect.origin.y = rect.origin.x;
    _bgView.frame = rect;

    rect = _headerBgView.frame;
    rect.origin.x = _bgView.frame.origin.x + (_bgView.frame.size.width - rect.size.width) / 2;
    rect.origin.y = rect.origin.x;
    _headerBgView.frame = rect;

    rect = _avatarView.frame;
    rect.origin.x = _headerBgView.frame.origin.x;
    rect.origin.y = _headerBgView.frame.origin.y + (_headerBgView.frame.size.height - rect.size.height) / 2;
    _avatarView.frame = rect;

    rect = _annunciateView.frame;
    rect.origin.x = CGRectGetMaxX(_avatarView.frame) + ITEM_PADDING;
    rect.origin.y = _avatarView.frame.origin.y;
    _annunciateView.frame = rect;

    CGFloat btnPadding = _headerBgView.frame.size.width - BTN_SHORT_WIDTH * 2;

    rect = _btnIm.frame;
    rect.origin.x = _headerBgView.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_headerBgView.frame) + btnPadding;
    _btnIm.frame = rect;

    rect = _btnRecentLog.frame;
    rect.origin.x = CGRectGetMaxX(_headerBgView.frame) - rect.size.width;
    rect.origin.y = _btnIm.frame.origin.y;
    _btnRecentLog.frame = rect;

    rect = _btnViewMember.frame;
    rect.origin.x = _btnIm.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_btnIm.frame) + btnPadding;
    _btnViewMember.frame = rect;

    if ([_group canAdmin]) {
        rect = _btnAddMember.frame;
        rect.origin.x = _btnRecentLog.frame.origin.x;
        rect.origin.y = _btnViewMember.frame.origin.y;
        _btnAddMember.frame = rect;

        rect = _btnViewDetails.frame;
        rect.origin.x = _btnIm.frame.origin.x;
        rect.origin.y = CGRectGetMaxY(_btnViewMember.frame) + btnPadding;
        _btnViewDetails.frame = rect;
    } else {
        rect = _btnViewDetails.frame;
        rect.origin.x = _btnRecentLog.frame.origin.x;
        rect.origin.y = _btnViewMember.frame.origin.y;
        _btnViewDetails.frame = rect;
    }

    rect = _bgView.frame;
    rect.size.height = CGRectGetMaxY(_btnViewDetails.frame) + (_bgView.frame.size.width - _headerBgView.frame.size.width) / 2 - rect.origin.y;
    _bgView.frame = rect;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (IBAction)viewIm:(id)btn {
    MessageChatView *view = [[MessageChatView alloc] initWithGroup:_group showHistory:NO];
    [self.navigationController pushViewController:view animated:YES];
}

- (IBAction)viewRecentLog:(id)btn {
    MessageChatView *view = [[MessageChatView alloc] initWithGroup:_group showHistory:YES];
    [self.navigationController pushViewController:view animated:YES];
}

- (IBAction)viewMember:(id)btn {
    ContactOperationListView *view = [[ContactOperationListView alloc] initWithOperation:ContactListOperation_ListGroupMembers
                                                                                andGroup:_group];
    [self.navigationController pushViewController:view animated:YES];
}

- (IBAction)addMember:(id)btn {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:MENU_ADD_GROUP_MEMBER
                                                       delegate:self
                                              cancelButtonTitle:I18nString(@"取消")
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:MENU_ADD_GROUP_MEMBER_FROM_ORG, MENU_ADD_GROUP_MEMBER_FROM_FRIEND, MENU_ADD_GROUP_MEMBER_FROM_OTHER_GROUP, MENU_ADD_GROUP_MEMBER_FROM_RECENTS, nil];
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (IBAction)viewDetails:(id)btn {
    GroupDetailsView *view = [[GroupDetailsView alloc] initWithGroup:_group];
    [self.navigationController pushViewController:view animated:YES];
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    UIViewController *view = nil;
    NSString *menuTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER_FROM_ORG]) {
        UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
        app.orgService.addTarget = _group;
        app.tabBarController.selectedIndex = 0; // 显示组织架构界面
    } else if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER_FROM_FRIEND]) {
        view = [[ContactOperationListView alloc] initWithOperation:ContactListOperation_AddGroupMemberFromFriends
                                                          andGroup:_group];
    } else if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER_FROM_OTHER_GROUP]) {
        view = [[GroupListView alloc] initWithGroups:[UcaAppDelegate sharedInstance].groupService.groups
                                         exceptGroup:_group];
    } else if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER_FROM_RECENTS]) {
        view = [[ContactOperationListView alloc] initWithOperation:ContactListOperation_AddGroupMemberFromRecents
                                                          andGroup:_group];
    }
    if (view) {
        [self.navigationController pushViewController:view animated:YES];
    }
}

@end
