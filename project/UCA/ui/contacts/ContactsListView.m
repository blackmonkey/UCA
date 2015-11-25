/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "ContactsListView.h"
#import "ContactDetailsView.h"
#import "MessageChatView.h"
#import "RecentLogListView.h"
#import "SystemMessageListView.h"
#import "GroupDetailsEntry.h"

#undef TAG
#define TAG @"ContactsListView"

#define MENU_CREATE_SESSION               I18nString(@"创建多人会话")
#define MENU_ADD_CONTACT                  I18nString(@"添加好友成员")
#define MENU_DELETE_CONTACT               I18nString(@"删除好友成员")
#define MENU_ADD_CONTACT_FROM_SERVER      I18nString(@"从企业组织架构添加好友")
#define MENU_ADD_CONTACT_MANUALLY         I18nString(@"自己输入添加好友")
#define MENU_ADD_CONTACT_FROM_ADDRESSBOOK I18nString(@"从通讯录添加好友")

@interface ContactsListView()
- (void)registerListener;
- (void)deregisterListener;
@end

/**
 * Default implementation
 */

@implementation ContactsListView {
    UIBarButtonItem *_menuButton;
    UIBarButtonItem *_addButton;
    UIBarButtonItem *_confirmDeleteButton;
    UIBarButtonItem *_cancelDeleteButton;
    UIBarButtonItem *_deleteButton;
    UISegmentedControl *_filterController;
    UIAlertView *_progressHud;

    BOOL _refreshing;
    BOOL _toRefresh;
}

@synthesize filterMode;

- (Contact *)getContactWithIndexPath:(NSIndexPath *)indexPath {
    @synchronized (self) {
        QElement * element = [self.root getElementAtIndexPath:indexPath];
        if (!element || ![element isKindOfClass:[ContactElement class]]) {
            return nil;
        }

        return ((ContactElement *)element).contact;
    }
}

- (void)reloadTitlebarButtons {
    if (self.quickDialogTableView.editing) {
        self.navigationItem.leftBarButtonItem = _cancelDeleteButton;
        self.navigationItem.rightBarButtonItem = _confirmDeleteButton;
    } else {
        self.navigationItem.leftBarButtonItem = nil;

        if (filterMode == FilterMode_Group) {
            if ([[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
                self.navigationItem.rightBarButtonItem = _menuButton;
            } else {
                self.navigationItem.rightBarButtonItem = nil;
            }
        } else {
            BOOL hasContacts = NO;
            for (QSection *sec in self.root.sections) {
                for (QElement *el in sec.elements) {
                    if ([el isKindOfClass:[ContactElement class]]) {
                        hasContacts = YES;
                        break;
                    }
                }
                if (hasContacts) {
                    break;
                }
            }
            if (hasContacts) {
                // FIXME: 当filterMode为FilterMode_Recent的时候，允许添加好友和删除好友
                self.navigationItem.rightBarButtonItem = (filterMode == FilterMode_Favourite ? _menuButton : _deleteButton);
            } else {
                self.navigationItem.rightBarButtonItem = (filterMode == FilterMode_Favourite ? _addButton : nil);
            }
        }
    }
}

- (void)setFormWithFavourites:(NSMutableArray *)contacts {
    @synchronized (self) {
        NSString *initial = nil;
        QSection *section = nil;

        for (Contact *contact in contacts) {
            initial = [contact.displayName initial];
            if ([NSString isNullOrEmpty:initial]) {
                initial = @"#";
            }

            section = [self.root sectionWithKey:initial];
            if (!section) {
                section = [[QSection alloc] init];
                section.key = initial;
                section.useKeyAsIndexTitle = YES;
                [self.root addSection:section];
            }

            ContactElement *element = [[ContactElement alloc] initWithContact:contact andDelegate:self];
            [section addElement:element];
        }

        [self.root.sections sortUsingComparator:^NSComparisonResult(__strong QSection *section1, __strong QSection *section2) {
            return [section1.key compare:section2.key];
        }];
        for (section in self.root.sections) {
            [section.elements sortUsingComparator:^NSComparisonResult(__strong ContactElement *element1, __strong ContactElement *element2) {
                return [element1.contact compareWithContact:element2.contact];
            }];
        }
    // TODO: enable this if it is required.
//    [_sections insertObject:UITableViewIndexSearch atIndex:0];
    }
}

- (void)setFormWithGroups:(NSMutableArray *)groups hasFetchedData:(BOOL)fetchedData {
    // Create section of groups
    QSection *section = [[QSection alloc] init];
    section.key = nil;
    [self.root addSection:section];

    if (![[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
        [section addElement:[[QEmptyListElement alloc] initWithTitle:I18nString(@"离线状态下无法获取群组和多人会话信息。") Value:nil]];
        return;
    }

    if (!fetchedData) {
        [NotifyUtils postNotificationWithName:UCA_REQUEST_FETCH_GROUP_INFO];
        [section addElement:[[QLoadingElement alloc] init]];
    } else {
        @synchronized (groups) {
            if ([groups count] == 0) {
                [section addElement:[[QEmptyListElement alloc] initWithTitle:I18nString(@"没有群组信息") Value:nil]];
            }
            for (Group *group in groups) {
                GroupElement *groupElement = [[GroupElement alloc] initWithGroup:group andDelegate:self];
                groupElement.controllerAction = @"launchGroupChat:";
                [section addElement:groupElement];
            }
        }
    }
}

- (void)setFormWithSessions:(NSMutableArray *)sessions {
    if (![[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
        return;
    }

    QSection *section = [self.root.sections objectAtIndex:0];
    @synchronized (sessions) {
        for (Session *session in sessions) {
            HeadElement *sessionElement = [[HeadElement alloc] initWithSession:session];
            sessionElement.controllerAction = @"launchSessionChat:";
            [section addElement:sessionElement];
        }
    }
}

- (void)setFormWithRecents:(NSMutableArray *)contacts {
    @synchronized (self) {
        UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
        NSUInteger unreadCount = 0;
        NSUInteger totalCount = 0;

        QSection *topSection = [[QSection alloc] init];
        topSection.key = nil;
        [self.root addSection:topSection];

        QSection *groupSection = [[QSection alloc] init];
        groupSection.key = nil;
        [self.root addSection:groupSection];

        QSection *sessionSection = [[QSection alloc] init];
        sessionSection.key = nil;
        [self.root addSection:sessionSection];

        QSection *contactsSection = [[QSection alloc] init];
        contactsSection.key = nil;
        [self.root addSection:contactsSection];

#ifdef ENABLE_VOICE_MAIL
        HeadElement *voiceMail = [[HeadElement alloc] init];
        voiceMail.key = KEY_VOICE_MAIL_ENTRY;
        voiceMail.type = HeadType_Voicemail;
        voiceMail.countInfo = @"15/200"; // TODO: get real count info
        [topSection addElement:voiceMail];
#endif

        unreadCount = [app.messageService countOfUnreadSystemMessages];
        totalCount = [app.messageService countOfSystemMessages];
        HeadElement *sysMsgEntry = [[HeadElement alloc] init];
        sysMsgEntry.key = KEY_SYS_MSG_ENTRY;
        sysMsgEntry.type = HeadType_SystemMessage;
        sysMsgEntry.countInfo = [NSString stringWithFormat:@"%d/%d", unreadCount, totalCount];
        sysMsgEntry.controllerAction = @"showSysMessages:";
        [topSection addElement:sysMsgEntry];

        for (Contact *contact in contacts) {
            switch (contact.contactType) {
            case ContactType_Unknown:
            case ContactType_AddressBook:
            case ContactType_Friend:
            case ContactType_Private: {
                    ContactElement *element = [[ContactElement alloc] initWithContact:contact andDelegate:self];
                    [contactsSection addElement:element];
                }
                break;

            case ContactType_Group: {
                    GroupElement *element = [[GroupElement alloc] initWithGroup:[[Group alloc] initWithContact:contact]
                                                                    andDelegate:self];
                    [groupSection addElement:element];
                }
                break;

            case ContactType_Session: {
                    HeadElement *element = [[HeadElement alloc] initWithSession:[[Session alloc] initWithContact:contact]];
                    [sessionSection addElement:element];
                }
                break;
            }
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
    NSMutableArray *contacts = nil;

    @synchronized (self) {
        _refreshing = YES;

//        [self deregisterListener];
        [self.root.sections removeAllObjects];

        if (filterMode == FilterMode_Favourite) {
            contacts = [NSMutableArray arrayWithArray:[app.contactService getNormalContacts]];
            if (contacts.count == 0) {
                QSection *section = [[QSection alloc] init];
                section.key = nil;

                QEmptyListElement *element = [[QEmptyListElement alloc] initWithTitle:I18nString(@"没有联系人") Value:nil];
                [section addElement:element];

                [self.root addSection:section];
            } else {
                [self setFormWithFavourites:contacts];
            }
        } else if (filterMode == FilterMode_Group) {
            [self setFormWithGroups:app.groupService.groups hasFetchedData:app.groupService.fetchedData];
            [self setFormWithSessions:app.sessionService.sessions];
        } else if (filterMode == FilterMode_Recent) {
            contacts = [NSMutableArray arrayWithArray:[app.contactService getRecentContacts]];
            [self setFormWithRecents:contacts];
        }

        UcaLog(TAG, @"refreshDataAndReload() contacts count:%d", contacts.count);

        [self reloadTitlebarButtons];
        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//        [self registerListener];

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

- (IBAction)showAddContactMenu:(id)button {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    if ([[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
        [sheet addButtonWithTitle:MENU_ADD_CONTACT];
    } else {
        [sheet addButtonWithTitle:MENU_ADD_CONTACT_FROM_ADDRESSBOOK];
    }
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:I18nString(@"取消")];
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (IBAction)showMenu:(id)button {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    if (filterMode == FilterMode_Group) {
        [sheet addButtonWithTitle:MENU_CREATE_SESSION];
    } else {
        if ([[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
            [sheet addButtonWithTitle:MENU_CREATE_SESSION];
            [sheet addButtonWithTitle:MENU_ADD_CONTACT];
        } else {
            [sheet addButtonWithTitle:MENU_ADD_CONTACT_FROM_ADDRESSBOOK];
        }
        [sheet addButtonWithTitle:MENU_DELETE_CONTACT];
    }
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:I18nString(@"取消")];
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)addContactFromAddressBook {
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self presentModalViewController:picker animated:YES];
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

/**
 * 删除或更新每一个选中的联系人，都会导致tableView刷新，从而导致选择信息的丢失，所以先记录一分选择信息。
 */
- (NSMutableArray *)getSelectedContacts {
    @synchronized (self) {
        Contact *contact = nil;
        NSMutableArray *selectedContacts = [NSMutableArray array];
        for (NSIndexPath *indexPath in self.quickDialogTableView.indexPathsForSelectedRows) {
            contact = [self getContactWithIndexPath:indexPath];
            [selectedContacts addObject:contact];
        }
        return selectedContacts;
    }
}

- (void)deleteFavourites {
    @synchronized (self) {
        UcaContactService *service = [UcaAppDelegate sharedInstance].contactService;
        NSMutableArray *contacts = [self getSelectedContacts];
        [self exitEditingMode];

        // 删除选中的Contact
        NSMutableString *errMsg = [NSMutableString stringWithString:I18nString(@"以下联系人删除失败，请稍后重试：")];
        NSUInteger failedCount = 0;
        for (Contact *contact in contacts) {
            if (![service deleteContact:contact]) {
                failedCount++;
                [errMsg appendFormat:@"\n%@", contact.displayName];
            }
        }

        [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
        // 显示删除失败通知
        if (failedCount > 0) {
            [NotifyUtils alert:errMsg];
        } else {
            [NotifyUtils alert:I18nString(@"删除成功！")];
        }
    }
}

/**
 * 清空选中最近联系人的联系历史（并不是真正的删除）。
 */
- (void)deleteRecents {
    @synchronized (self) {
        UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
        NSMutableArray *contacts = [self getSelectedContacts];
        [self exitEditingMode];

        NSMutableString *errMsg = [NSMutableString stringWithString:I18nString(@"以下最近联系人删除失败，请稍后重试：")];
        NSUInteger failedCount = 0;
        for (Contact *contact in contacts) {
            [app.recentService deleteRecentLogsOfContact:contact];
            contact.accessed = nil;
            if (![app.contactService updateAccessOfContact:contact]) {
                failedCount++;
                [errMsg appendFormat:@"\n%@", contact.displayName];
            }
        }

        [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
        // 显示失败通知
        if (failedCount > 0) {
            [NotifyUtils alert:errMsg];
        } else {
            [NotifyUtils alert:I18nString(@"删除成功！")];
        }
    }
}

- (IBAction)confirmDeleteContacts:(id)button {
    NSArray *selectedPath = self.quickDialogTableView.indexPathsForSelectedRows;
    if (selectedPath.count == 1) {
        Contact *contact = [self getContactWithIndexPath:[selectedPath objectAtIndex:0]];
        NSString *msg = [NSString stringWithFormat:I18nString(@"是否删除%@？"), contact.displayName];
        [NotifyUtils confirm:msg delegate:self];
    } else if (selectedPath.count > 1) {
        [NotifyUtils confirm:I18nString(@"是否删除选中联系人？") delegate:self];
    } else { // 没有选中联系人
        [self exitEditingMode];
    }
}

- (void)handleChangeFilter:(UISegmentedControl *)control {
    filterMode = control.selectedSegmentIndex;
    [self exitEditingMode];
    [self tryRefreshDataAndReload];
}

- (void)showSysMessages:(HeadElement *)element {
    SystemMessageListView *view = [[SystemMessageListView alloc] init];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)launchGroupChat:(GroupElement *)element {
    MessageChatView *view = [[MessageChatView alloc] initWithGroup:element.group showHistory:YES];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)launchSessionChat:(HeadElement *)element {
    MessageChatView *view = [[MessageChatView alloc] initWithSession:((Session *)(element.object))];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)initTitleBar {
    _filterController = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:I18nString(@"好友"),
                                                                            I18nString(@"群组"),
                                                                            I18nString(@"最近"), nil]];
    _filterController.momentary = NO;
    _filterController.segmentedControlStyle = UISegmentedControlStyleBar;
    _filterController.selectedSegmentIndex = filterMode;
    [_filterController addTarget:self action:@selector(handleChangeFilter:) forControlEvents:UIControlEventValueChanged];

    self.navigationItem.titleView = _filterController;
}

- (QRootElement *)createForm {
    QRootElement *form = [[QRootElement alloc] init];
    form.title = I18nString(@"联系人");

    QSection *section = [[QSection alloc] init];
    section.key = nil;

    QLoadingElement *element = [[QLoadingElement alloc] init];
    [section addElement:element];

    [form addSection:section];

    return form;
}

- (void)setFilterMode:(FilterMode)mode {
    self->filterMode = mode;
    _filterController.selectedSegmentIndex = mode;
}

- (id)init {
    QRootElement *root = [self createForm];
    self = [super initWithRoot:root];

    if (self) {
        filterMode = FilterMode_Favourite;
        _progressHud = [NotifyUtils progressHud:I18nString(@"请稍等⋯⋯")];

        _cancelDeleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(exitEditingMode)];
        _confirmDeleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(confirmDeleteContacts:)];
        _menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"res/titlebar_menu_button"]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(showMenu:)];
        _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                   target:self
                                                                   action:@selector(showAddContactMenu:)];
        _deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                      target:self
                                                                      action:@selector(enterEditingMode)];

        _refreshing = NO;
        _toRefresh = NO;

        self.title = root.title;
        [self initTitleBar];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.quickDialogTableView.backgroundColor = APP_BGCOLOR;
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.quickDialogTableView.allowsMultipleSelectionDuringEditing = YES;
    self.quickDialogTableView.useSectionKeyAsIndexTitle = YES;

    [self exitEditingMode];
}

- (void)registerListener {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_ADD_CONTACT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_DELETE_CONTACT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_UPDATE_CONTACT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_UPDATE_CONTACTS
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_RESPOND_FETCH_GROUP_INFO_FAIL
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_RESPOND_FETCH_GROUP_INFO_OKAY
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_INDICATE_GROUP_UPDATED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_INDICATE_SESSION_UPDATED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deregisterListener)
                                                 name:UCA_EVENT_SHUTDOWN_TABS
                                               object:nil];
}

- (void)deregisterListener {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _filterController.selectedSegmentIndex = filterMode;
    [self registerListener];
    [self tryRefreshDataAndReload];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self deregisterListener];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - GroupElementDelegate delegate methods
- (void)groupElementAvatarOnClicked:(Group *)group {
    GroupDetailsEntry *view = [[GroupDetailsEntry alloc] initWithGroup:group];
    [self displayViewController:view];
}

#pragma mark - ContactCellDelegate delegate methods

- (BOOL)canResponseToContact:(Contact *)contact {
    if (self.quickDialogTableView.editing) {
        return NO;
    }

    return nil != contact;
}

- (void)contactElementOnClicked:(ContactElement *)element {
    if (![self canResponseToContact:element.contact]) {
        return;
    }

    if (filterMode == FilterMode_Favourite) {
        [self contactElementImOnClicked:element.contact];
    } else if (filterMode == FilterMode_Recent) {
        RecentLogListView *view = [[RecentLogListView alloc] initWithEntry:element onlyMissed:NO];
        [self.navigationController pushViewController:view animated:YES];
    }
}

- (void)contactElementAvatarOnClicked:(Contact *)contact {
    if (![self canResponseToContact:contact]) {
        return;
    }

    ContactDetailsView *view = [[ContactDetailsView alloc] initWithContact:contact];
    [self.navigationController pushViewController:view animated:YES];
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
        [self.navigationController pushViewController:view animated:YES];
    }
}

- (void)contactElementCamOnClicked:(Contact *)contact {
    if (![self canResponseToContact:contact]) {
        return;
    }
    UcaLog(TAG, @"contactCellCamOnClicked: %@", contact.displayName);

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

    if (filterMode == FilterMode_Favourite) {
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
    } else if (filterMode == FilterMode_Recent) {
        RecentLogListView *view = [[RecentLogListView alloc] initWithEntry:element onlyMissed:YES];
        [self.navigationController pushViewController:view animated:YES];
    }
}

#pragma mark - UIAlertViewDelegate methods
/**
 * 确认或取消删除选中联系人。
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // confirm
        _progressHud.title = I18nString(@"正在删除，请稍等⋯⋯");
        [_progressHud show];
        if (filterMode == FilterMode_Favourite) {
            [self performSelectorInBackground:@selector(deleteFavourites) withObject:nil];
        } else if (filterMode == FilterMode_Recent) {
            [self performSelectorInBackground:@selector(deleteRecents) withObject:nil];
        }
    } else { // cancel
        [self exitEditingMode];
    }
}

#pragma mark - Action sheet delegate

- (void)onSessionCreate:(NSNotification *)note {
    BOOL ok = [note.name isEqualToString:UCA_INDICATE_SESSION_CREATED_OKAY];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_SESSION_CREATED_OKAY
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_SESSION_CREATED_FAIL
                                                  object:nil];
    [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
    [NotifyUtils alert:(ok ? I18nString(@"创建成功！") : I18nString(@"创建失败！"))];
    if (ok) {
        [self tryRefreshDataAndReload];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    NSString *menuTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([menuTitle isEqualToString:MENU_CREATE_SESSION]) {
        _progressHud.title = I18nString(@"正在创建，请稍等⋯⋯");
        [_progressHud show];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onSessionCreate:)
                                                     name:UCA_INDICATE_SESSION_CREATED_OKAY
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onSessionCreate:)
                                                     name:UCA_INDICATE_SESSION_CREATED_FAIL
                                                   object:nil];

        [app.sessionService performSelectorInBackground:@selector(createSession) withObject:nil];
    } else if ([menuTitle isEqualToString:MENU_ADD_CONTACT]) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:I18nString(@"取消")
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:MENU_ADD_CONTACT_FROM_SERVER, MENU_ADD_CONTACT_MANUALLY, MENU_ADD_CONTACT_FROM_ADDRESSBOOK, nil];
        sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [sheet showFromTabBar:self.tabBarController.tabBar];
    } else if ([menuTitle isEqualToString:MENU_DELETE_CONTACT]) {
        [self enterEditingMode];
    } else if ([menuTitle isEqualToString:MENU_ADD_CONTACT_FROM_SERVER]) {
        app.orgService.addTarget = nil;
        app.tabBarController.selectedIndex = 0; // 显示组织架构界面
    } else if ([menuTitle isEqualToString:MENU_ADD_CONTACT_MANUALLY]) {
        ContactDetailsView *view = [[ContactDetailsView alloc] initWithContact:nil];
        [self.navigationController pushViewController:view animated:YES];
    } else if ([menuTitle isEqualToString:MENU_ADD_CONTACT_FROM_ADDRESSBOOK]) {
        [self addContactFromAddressBook];
    }
}

#pragma mark ABPeoplePickerNavigationControllerDelegate methods

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    UcaContactService *service = app.contactService;

    Contact *contact = [[Contact alloc] init];
    contact.contactType = ContactType_AddressBook;
    [contact copyDataFromABRecord:person];

    AddContactResult res = [service addAddressBookContact:contact];
    if (res == AddContact_Failure) {
        [NotifyUtils alert:[NSString stringWithFormat:I18nString(@"联系人“%@”添加失败。"), contact.displayName]];
    } else if (res == AddContact_Duplicate) {
        [NotifyUtils alert:[NSString stringWithFormat:I18nString(@"联系人“%@”已经是你的好友了。"), contact.displayName]];
    }

    [self dismissModalViewControllerAnimated:YES];
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier {
    return YES;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissModalViewControllerAnimated:YES];
}

@end
