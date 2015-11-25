/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "ContactOperationListView.h"
#import "ContactDetailsView.h"
#import "MessageChatView.h"
#import "GroupListView.h"

#undef TAG
#define TAG @"ContactOperationListView"

#define TITLE_SESSION_MEMBER                   I18nString(@"添加多人会话成员")
#define MENU_ADD_GROUP_MEMBER                  I18nString(@"添加群成员")
#define MENU_ADD_GROUP_MEMBER_FROM_ORG         I18nString(@"从组织架构添加")
#define MENU_ADD_GROUP_MEMBER_FROM_FRIEND      I18nString(@"从好友添加")
#define MENU_ADD_GROUP_MEMBER_FROM_OTHER_GROUP I18nString(@"从其他群组添加")
#define MENU_ADD_GROUP_MEMBER_FROM_RECENTS     I18nString(@"从最近联系人添加")
#define MENU_DELETE_GROUP_MEMBER               I18nString(@"删除群成员")

@interface ContactOperationListView()
- (void)enterEditingMode;
- (void)exitEditingMode;
@end

@implementation ContactOperationListView {
    ContactListOperation _operation;
    Group *_srcGroup;
    Group *_dstGroup;
    Session *_dstSession;
    BOOL _hasContacts;
    BOOL _refreshing;
    BOOL _toRefresh;

    UIBarButtonItem *_menuButton;
    UIBarButtonItem *_addButton;
    UIBarButtonItem *_commitButton;
    UIBarButtonItem *_cancelButton;

    UIAlertView *_progressHud;
}

- (void)reloadTitlebarButtons {
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.rightBarButtonItems = nil;

    if (self.quickDialogTableView.editing) {
        switch (_operation) {
        case ContactListOperation_ListGroupMembers:
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_commitButton, _cancelButton, nil];
            break;

        case ContactListOperation_AddGroupMemberFromFriends:
        case ContactListOperation_AddGroupMemberFromGroup:
        case ContactListOperation_AddGroupMemberFromRecents:
        case ContactListOperation_AddSessionMemberFromFriends:
        case ContactListOperation_AddSessionMemberFromRecents:
            if (_hasContacts) {
                self.navigationItem.rightBarButtonItem = _commitButton;
            }
            break;
        }
    } else if (_operation == ContactListOperation_ListGroupMembers && [_srcGroup canAdmin]) {
        if (_hasContacts) {
            self.navigationItem.rightBarButtonItem = _menuButton;
        } else {
            self.navigationItem.rightBarButtonItem = _addButton;
        }
    }
}

- (void)refreshDataAndReload {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
#endif

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    NSArray *contacts = nil;

    @synchronized (self) {
        _refreshing = YES;

        [self.root.sections removeAllObjects];

        switch (_operation) {
        case ContactListOperation_ListGroupMembers:
        case ContactListOperation_AddGroupMemberFromGroup:
            contacts = _srcGroup.contacts;
            break;

        case ContactListOperation_AddGroupMemberFromFriends:
        case ContactListOperation_AddSessionMemberFromFriends:
            contacts = [app.contactService getFriends];
            break;

        case ContactListOperation_AddGroupMemberFromRecents:
        case ContactListOperation_AddSessionMemberFromRecents:
            contacts = [app.contactService getRecentFriends];
            break;
        }

        NSString *initial = nil;
        QSection *section = nil;

        for (Contact *contact in contacts) {
            if (_dstGroup && [_dstGroup.contacts containsObject:contact]) {
                continue;
            }
            if (_dstSession && [_dstSession.contacts containsObject:contact]) {
                continue;
            }

            initial = [contact.displayName initial];
            if ([NSString isNullOrEmpty:initial]) {
                initial = @"#";
            }

            section = [self.root sectionWithKey:initial];
            if (!section) {
                section = [[QSection alloc] init];
                section.key = initial;
                section.useKeyAsIndexTitle = (_operation != ContactListOperation_AddGroupMemberFromRecents);
                [self.root addSection:section];
            }

            ContactElement *element = [[ContactElement alloc] initWithContact:contact andDelegate:self];
            [section addElement:element];
        }

        _hasContacts = ([self.root.sections count] > 0);
        if (_hasContacts) {
            [self.root.sections sortUsingComparator:^NSComparisonResult(__strong QSection *section1, __strong QSection *section2) {
                return [section1.key compare:section2.key];
            }];
            if (_operation != ContactListOperation_AddGroupMemberFromRecents) {
                for (section in self.root.sections) {
                    [section.elements sortUsingComparator:^NSComparisonResult(__strong ContactElement *element1, __strong ContactElement *element2) {
                        return [element1.contact compareWithContact:element2.contact];
                    }];
                }
            }
            if (_operation != ContactListOperation_ListGroupMembers) {
                [self enterEditingMode];
            }
        } else {
            section = [[QSection alloc] init];
            section.key = nil;

            QEmptyListElement *element;
            if (_operation == ContactListOperation_ListGroupMembers) {
                element = [[QEmptyListElement alloc] initWithTitle:I18nString(@"没有成员") Value:nil];
            } else {
                element = [[QEmptyListElement alloc] initWithTitle:I18nString(@"没有其他联系人") Value:nil];
            }
            [section addElement:element];

            [self.root addSection:section];
            [self exitEditingMode];
        }

        [self reloadTitlebarButtons];
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

- (QRootElement *)createForm {
    QRootElement *form = [[QRootElement alloc] init];

    QSection *section = [[QSection alloc] init];
    section.key = nil;

    QLoadingElement *element = [[QLoadingElement alloc] init];
    [section addElement:element];

    [form addSection:section];

    return form;
}

- (void)initTitleBarButtons {
    _menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"res/titlebar_menu_button"]
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(showMenu:)];
    _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                               target:self
                                                               action:@selector(showAddMemberMenu:)];
    _commitButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                  target:self
                                                                  action:@selector(commitOperation:)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                  target:self
                                                                  action:@selector(exitEditingMode)];
}

- (id)initWithOperation:(ContactListOperation)operation andGroup:(Group *)group {
    NSAssert(operation != ContactListOperation_AddGroupMemberFromGroup,
             @"Do NOT transfer ContactListOperation_AddGroupMemberFromGroup to initWithOperation:andGroup:! Use initAddMemberFromGroup:toGroup: instead.");

    QRootElement *root = [self createForm];
    self = [super initWithRoot:root];
    if (self) {
        if (operation == ContactListOperation_ListGroupMembers) {
            _srcGroup = group;
            root.title = group.name;
        } else if (operation == ContactListOperation_AddGroupMemberFromFriends
                   || operation == ContactListOperation_AddGroupMemberFromRecents) {
            _dstGroup = group;
            root.title = MENU_ADD_GROUP_MEMBER;
        }

        _operation = operation;
        _refreshing = NO;
        _toRefresh = NO;
        [self initTitleBarButtons];
    }
    return self;
}

- (id)initWithOperation:(ContactListOperation)operation andSession:(Session *)session {
    QRootElement *root = [self createForm];
    self = [super initWithRoot:root];
    if (self) {
        if (operation == ContactListOperation_AddSessionMemberFromFriends
            || operation == ContactListOperation_AddSessionMemberFromRecents) {
            _dstSession = session;
            root.title = TITLE_SESSION_MEMBER;
        }

        _operation = operation;
        _refreshing = NO;
        _toRefresh = NO;
        [self initTitleBarButtons];
    }
    return self;
}

- (id)initAddMemberFromGroup:(Group *)srcGroup toGroup:(Group *)dstGroup {
    QRootElement *root = [self createForm];
    self = [super initWithRoot:root];
    if (self) {
        _operation = ContactListOperation_AddGroupMemberFromGroup;
        _srcGroup = srcGroup;
        _dstGroup = dstGroup;
        _refreshing = NO;
        _toRefresh = NO;
        [self initTitleBarButtons];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.quickDialogTableView.backgroundColor = [UIColor clearColor];
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.quickDialogTableView.allowsMultipleSelectionDuringEditing = YES;
    self.quickDialogTableView.useSectionKeyAsIndexTitle = YES;

    if (_operation == ContactListOperation_ListGroupMembers) {
        [self exitEditingMode];
    } else {
        [self enterEditingMode];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (_operation == ContactListOperation_ListGroupMembers) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tryRefreshDataAndReload)
                                                     name:UCA_INDICATE_GROUP_UPDATED
                                                   object:nil];
    }

    [self tryRefreshDataAndReload];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - selector methods

- (Contact *)getContactWithIndexPath:(NSIndexPath *)indexPath {
    @synchronized (self) {
        QElement * element = [self.root getElementAtIndexPath:indexPath];
        if (!element || ![element isKindOfClass:[ContactElement class]]) {
            return nil;
        }

        return [(ContactElement *)element contact];
    }
}

- (NSMutableArray *)getContactsOfIndexPathes:(NSArray *)pathes {
    @synchronized (self) {
        Contact *contact = nil;
        NSMutableArray *selectedContacts = [NSMutableArray array];
        for (NSIndexPath *indexPath in pathes) {
            contact = [self getContactWithIndexPath:indexPath];
            if (contact) {
                [selectedContacts addObject:contact];
            }
        }
        return selectedContacts;
    }
}

- (void)showMenu:(id)button {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:I18nString(@"取消")
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:MENU_ADD_GROUP_MEMBER, MENU_DELETE_GROUP_MEMBER, nil];
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)showAddMemberMenu:(id)button {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:MENU_ADD_GROUP_MEMBER
                                                       delegate:self
                                              cancelButtonTitle:I18nString(@"取消")
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:MENU_ADD_GROUP_MEMBER_FROM_ORG, MENU_ADD_GROUP_MEMBER_FROM_FRIEND, MENU_ADD_GROUP_MEMBER_FROM_OTHER_GROUP, MENU_ADD_GROUP_MEMBER_FROM_RECENTS, nil];
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)regesiterAddListener {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAddMembersOkay)
                                                 name:UCA_INDICATE_ADD_GROUP_MEMBERS_OKAY
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAddMembersFail)
                                                 name:UCA_INDICATE_ADD_GROUP_MEMBERS_FAIL
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAddMembersOkay)
                                                 name:UCA_INDICATE_ADD_SESSION_MEMBERS_OKAY
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAddMembersFail)
                                                 name:UCA_INDICATE_ADD_SESSION_MEMBERS_FAIL
                                               object:nil];
}

- (void)deregesiterAddListener {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_ADD_GROUP_MEMBERS_OKAY
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_ADD_GROUP_MEMBERS_FAIL
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_ADD_SESSION_MEMBERS_OKAY
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_ADD_SESSION_MEMBERS_FAIL
                                                  object:nil];
}

- (void)onAddMembersOkay {
    [self deregesiterAddListener];
    [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
    [NotifyUtils alert:I18nString(@"添加成功！")];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onAddMembersFail {
    [self deregesiterAddListener];
    [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
    [NotifyUtils alert:I18nString(@"添加失败！请稍后重试。")];
}

- (void)commitOperation:(id)button {
    NSArray *pathes = self.quickDialogTableView.indexPathsForSelectedRows;
    if (pathes.count == 0) {
        // 没有选中联系人
        if (_operation == ContactListOperation_ListGroupMembers) {
            [self exitEditingMode];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
        return;
    }

    if (_operation == ContactListOperation_ListGroupMembers) {
        // confirm deleting members
        [NotifyUtils confirm:I18nString(@"是否删除选中联系人？") delegate:self];
        return;
    }

    if (!_progressHud) {
        _progressHud = [NotifyUtils progressHud:I18nString(@"正在添加，请稍等⋯⋯")];
    }
    [_progressHud show];

    [self regesiterAddListener];

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    NSMutableArray *contacts = [self getContactsOfIndexPathes:pathes];
    if (_dstGroup) {
        [app.groupService addContacts:contacts toGroup:_dstGroup];
    } else if (_dstSession) {
        [app.sessionService addContacts:contacts toSession:_dstSession];
    }
}

- (void)regesiterDeleteListener {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeleteMembersOkay)
                                                 name:UCA_INDICATE_DELET_GROUP_MEMBERS_OKAY
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeleteMembersFail)
                                                 name:UCA_INDICATE_DELET_GROUP_MEMBERS_FAIL
                                               object:nil];
}

- (void)deregesiterDeleteListener {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_DELET_GROUP_MEMBERS_OKAY
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_DELET_GROUP_MEMBERS_FAIL
                                                  object:nil];
}

- (void)onDeleteMembersOkay {
    [self deregesiterDeleteListener];
    [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
    [NotifyUtils alert:I18nString(@"删除成功！")];
    [self exitEditingMode];
    [self tryRefreshDataAndReload];
}

- (void)onDeleteMembersFail {
    [self deregesiterDeleteListener];
    [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
    [NotifyUtils alert:I18nString(@"删除失败！请稍后重试。")];
}

- (void)deleteMembers {
    if (!_progressHud) {
        _progressHud = [NotifyUtils progressHud:I18nString(@"正在删除，请稍等⋯⋯")];
    }
    [_progressHud show];

    [self regesiterDeleteListener];

    NSArray *pathes = self.quickDialogTableView.indexPathsForSelectedRows;
    NSMutableArray *contacts = [self getContactsOfIndexPathes:pathes];

    [[UcaAppDelegate sharedInstance].groupService removeMembers:contacts fromGroup:_srcGroup];
}

- (void)enterEditingMode {
    if (!self.quickDialogTableView.editing) {
        self.quickDialogTableView.editing = YES;
        [self reloadTitlebarButtons];
    }
}

- (void)exitEditingMode {
    if (self.quickDialogTableView.editing) {
        self.quickDialogTableView.editing = NO;
        [self reloadTitlebarButtons];
    }
}

#pragma mark - ContactCellDelegate delegate methods

- (BOOL)canResponseToContact:(Contact *)contact {
    return !self.quickDialogTableView.editing
            && _operation == ContactListOperation_ListGroupMembers
            && nil != contact;
}

- (void)contactElementOnClicked:(ContactElement *)element {
    if (![self canResponseToContact:element.contact]) {
        return;
    }
    [self contactElementImOnClicked:element.contact];
}

- (void)contactElementAvatarOnClicked:(Contact *)contact {
    if (![self canResponseToContact:contact]) {
        return;
    }

    ContactDetailsView *view = [[ContactDetailsView alloc] initWithContact:contact];
    [self displayViewController:view];
}

- (void)contactElementImOnClicked:(Contact *)contact {
    if (![self canResponseToContact:contact]) {
        return;
    }

    if (![[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
        [NotifyUtils alert:I18nString(@"您目前处于离线状态，无法发送即时消息。请登录后再重试。")];
    } else if ([NSString isNullOrEmpty:contact.sipPhone]) {
        [NotifyUtils alert:I18nString(@"该联系人没有SIP电话，无法进行即时消息聊天。")];
    } else {
        MessageChatView *view = [[MessageChatView alloc] initWithContact:contact];
        [self displayViewController:view];
    }
}

- (void)contactElementCamOnClicked:(Contact *)contact {
    if (![self canResponseToContact:contact]) {
        return;
    }

    // TODO:
    // 1. 当只有一个有效电话时，直接调用相关ViewControler进行通话交互，否则调用一个
    // QuickDialogViewController来显示所有有效电话，以供用户选择。
    // 2. 这部分代码重复了6次，应予优化。

    NSString *number = [contact firstValidPhonenumber];
    if ([NSString isNullOrEmpty:number]) {
        return;
    }
    [[UcaAppDelegate sharedInstance].callingService dialOut:number
                                                  withVideo:YES
                                         fromViewController:self];
}

- (void)contactElementPhoneOnClicked:(ContactElement *)element {
    if (![self canResponseToContact:element.contact]) {
        return;
    }

    // TODO:
    // 1. 当只有一个有效电话时，直接调用相关ViewControler进行通话交互，否则调用一个
    // QuickDialogViewController来显示所有有效电话，以供用户选择。
    // 2. 这部分代码重复了6次，应予优化。

    NSString *number = [element.contact firstValidPhonenumber];
    if ([NSString isNullOrEmpty:number]) {
        return;
    }
    [[UcaAppDelegate sharedInstance].callingService dialOut:number
                                                  withVideo:NO
                                         fromViewController:self];
}

#pragma mark - UIAlertViewDelegate methods
/**
 * 确认或取消删除选中群成员。
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // confirm
        if (_operation == ContactListOperation_ListGroupMembers) {
            [self performSelectorInBackground:@selector(deleteMembers) withObject:nil];
        }
    } else { // cancel
        [self exitEditingMode];
    }
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    NSString *menuTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER]) {
        [self showAddMemberMenu:nil];
    } else if ([menuTitle isEqualToString:MENU_DELETE_GROUP_MEMBER]) {
        [self enterEditingMode];
    } else {
        UIViewController *view = nil;
        if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER_FROM_ORG]) {
            UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
            app.orgService.addTarget = _srcGroup;
            app.tabBarController.selectedIndex = 0; // 显示组织架构界面
        } else if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER_FROM_FRIEND]) {
            view = [[ContactOperationListView alloc] initWithOperation:ContactListOperation_AddGroupMemberFromFriends
                                                              andGroup:_srcGroup];
        } else if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER_FROM_OTHER_GROUP]) {
            view = [[GroupListView alloc] initWithGroups:[UcaAppDelegate sharedInstance].groupService.groups
                                             exceptGroup:_srcGroup];
        } else if ([menuTitle isEqualToString:MENU_ADD_GROUP_MEMBER_FROM_RECENTS]) {
            view = [[ContactOperationListView alloc] initWithOperation:ContactListOperation_AddGroupMemberFromRecents
                                                              andGroup:_srcGroup];
        }
        if (view) {
            [self displayViewController:view];
        }
    }
}

@end
