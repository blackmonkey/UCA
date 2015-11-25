/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "OrgViewController.h"
#import "DepartmentElement.h"
#import "MessageChatView.h"
#import "ContactDetailsView.h"

#undef TAG
#define TAG @"OrgViewController"

#define DEPART_SECTION_KEY @"@"
#define LOADING_SECTION_KEY @"_"

static DepartmentElement *topRoot = nil;

@implementation OrgViewController {
    BOOL _searchTableViewShown;
    BOOL _fetchingOrgInfo;
    BOOL _fetchingSearchResult;
    BOOL _hasFetchedSearchResult;

    NSMutableArray *_searchResult; // 保存搜索结果
    BOOL _foundContact;            // 搜索结果中是否含有联系人

    ContactSearchBar *_SearchBar;
    UISearchDisplayController *_SearchDisplayController;

    UIBarButtonItem *_cancelAddingButton;
    UIBarButtonItem *_confirmAddingButton;
    UIBarButtonItem *_addContactButton;
    UIBarButtonItem *_refreshButton;
}

- (void)reloadOrgInfoTableTitlebar {
    NSMutableArray *buttons = [NSMutableArray array];
    if (self.quickDialogTableView.editing) {
        [buttons addObject:_confirmAddingButton];
        [buttons addObject:_cancelAddingButton];
    } else {
        BOOL foundContactElement = NO;
        for (QSection *section in self.root.sections) {
            for (QElement *element in section.elements) {
                if ([element isKindOfClass:[ContactElement class]]) {
                    [buttons addObject:_addContactButton];
                    foundContactElement = YES;
                    break;
                }
            }
            if (foundContactElement) {
                break;
            }
        }

        if (!_fetchingOrgInfo && [[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
            [buttons addObject:_refreshButton];
        }
    }
    self.navigationItem.rightBarButtonItems = buttons;
    self.navigationItem.title = self.root.title;
    self.tabBarItem.title = I18nString(@"组织架构");
}

- (void)reloadSearchResultTableTitleBar {
    UcaLog(TAG, @"reloadSearchResultTableTitleBar shown:%d", _searchTableViewShown);
    if (_searchTableViewShown && _foundContact) {
        if (_SearchDisplayController.searchResultsTableView.editing) {
            [_SearchBar showEditButton:NO andConfirmButton:YES andExitButton:YES];
        } else {
            [_SearchBar showEditButton:YES andConfirmButton:NO andExitButton:NO];
        }
    } else {
        [_SearchBar showEditButton:NO andConfirmButton:NO andExitButton:NO];
    }
}

- (void)enterEditingMode {
    if (!_searchTableViewShown && !self.quickDialogTableView.editing) {
        self.quickDialogTableView.editing = YES;
        [self reloadOrgInfoTableTitlebar];
    }
}

- (void)exitEditingMode {
    if (!_searchTableViewShown && self.quickDialogTableView.editing) {
        self.quickDialogTableView.editing = NO;
        [self reloadOrgInfoTableTitlebar];
    }
}

- (void)reloadOrgInfoTable {
    UcaLog(TAG, @"reloadOrgInfoTable");
    [self reloadOrgInfoTableTitlebar];
    [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)reloadSearchResultTable {
    UcaLog(TAG, @"reloadSearchResultTable shown:%d", _searchTableViewShown);
    if (_searchTableViewShown) {
        [self reloadSearchResultTableTitleBar];
        [_SearchDisplayController.searchResultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}

- (Contact *)getContactWithIndexPath:(NSIndexPath *)indexPath {
    QElement *element = nil;

    if (_searchTableViewShown) {
        if (indexPath.row >= 0 && indexPath.row < _searchResult.count) {
            element = [_searchResult objectAtIndex:indexPath.row];
        }
    } else {
        element = [self.root getElementAtIndexPath:indexPath];
    }

    if (!element || ![element isKindOfClass:[ContactElement class]]) {
        return nil;
    }

    return ((ContactElement *)element).contact;
}

- (void)confirmAddContacts {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];

    NSArray *selectedPath = nil;
    if (_searchTableViewShown) {
        selectedPath = _SearchDisplayController.searchResultsTableView.indexPathsForSelectedRows;
    } else {
        selectedPath = self.quickDialogTableView.indexPathsForSelectedRows;
    }

    if (selectedPath.count > 0) {
        @synchronized (self) {
            // 添加选中的Contact
            NSMutableString *errMsg = [[NSMutableString alloc] init];
            NSMutableArray *failedAdd = [NSMutableArray array];
            NSMutableArray *reAdd = [NSMutableArray array];

            if (app.orgService.addTarget == nil) {
                for (NSIndexPath *path in selectedPath) {
                    Contact *contact = [self getContactWithIndexPath:path];
                    AddContactResult acr = [app.contactService addFriendWithContact:contact];
                    if (acr == AddContact_Failure) {
                        [failedAdd addObject:contact.displayName];
                    } else if (acr == AddContact_Duplicate) {
                        [reAdd addObject:contact.displayName];
                    }
                }
            } else if ([app.orgService.addTarget isKindOfClass:[Group class]]) {
                NSMutableArray *contacts = [NSMutableArray array];
                for (NSIndexPath *path in selectedPath) {
                    [contacts addObject:[self getContactWithIndexPath:path]];
                }
                [app.groupService addContacts:contacts toGroup:app.orgService.addTarget];
                app.orgService.addTarget = nil;
            } else if ([app.orgService.addTarget isKindOfClass:[Session class]]) {
                NSMutableArray *contacts = [NSMutableArray array];
                for (NSIndexPath *path in selectedPath) {
                    [contacts addObject:[self getContactWithIndexPath:path]];
                }
                [app.sessionService addContacts:contacts toSession:app.orgService.addTarget];
                app.orgService.addTarget = nil;
            }

            // 显示添加失败通知
            if (failedAdd.count > 0) {
                [errMsg appendString:I18nString(@"以下联系人添加失败，请稍后重试：\n")];
                [errMsg appendString:[failedAdd componentsJoinedByString:@", "]];
                [errMsg appendString:@"\n"];
            }
            if (reAdd.count > 0) {
                [errMsg appendString:I18nString(@"以下联系人重复添加：\n")];
                [errMsg appendString:[reAdd componentsJoinedByString:@", "]];
                [errMsg appendString:@"\n"];
            }
            if (errMsg.length > 0) {
                [NotifyUtils alert:errMsg];
            } else {
                [NotifyUtils alert:I18nString(@"添加成功！")];
            }
        }
    }

    if (_searchTableViewShown) {
        [self contactSearchBarExitEditing];
    } else {
        [self exitEditingMode];
    }
}

- (void)updateRoot:(DepartmentElement *)root withInfo:(Department *)depart {
    root.department = depart;
    root.key = [[NSNumber numberWithInteger:depart.id] stringValue];
    root.title = depart.name;
    if ([NSString isNullOrEmpty:depart.name]) {
        root.title = I18nString(@"组织架构");
    }

    /* 更新部门列表 */
    QSection *section = [root sectionWithKey:DEPART_SECTION_KEY];
    if (section == nil) {
        section = [[QSection alloc] init];
        section.key = DEPART_SECTION_KEY;
        [root.sections insertObject:section atIndex:0];
    }

    DepartmentElement *dpElement = nil;
    for (Department *dp in depart.subDeparts) {
        dpElement = nil;
        for (QElement *el in section.elements) {
            if ([el.key integerValue] == dp.id) {
                dpElement = (DepartmentElement *)el;
                break;
            }
        }
        if (dpElement == nil) {
            dpElement = [[DepartmentElement alloc] initWithDepartment:dp];
            [section addElement:dpElement];
        }
        [self updateRoot:dpElement withInfo:dp];
    }

    /* 更新联系人列表 */
    NSString *initial = nil;
    ContactElement *contactElement = nil;
    for (Contact *contact in depart.userInfos) {
        initial = [contact.displayName initial];
        if ([NSString isNullOrEmpty:initial]) {
            initial = @"#";
        }

        section = [root sectionWithKey:initial];
        if (section == nil) {
            section = [[QSection alloc] init];
            section.key = initial;
            section.useKeyAsIndexTitle = YES;
            [root addSection:section];
        }

        contactElement = nil;
        for (ContactElement *el in section.elements) {
            if (el.contact.userId == contact.userId) {
                contactElement = el;
                break;
            }
        }
        if (contactElement == nil) {
            contactElement = [[ContactElement alloc] initWithContact:contact andDelegate:self];
            [section addElement:contactElement];
        } else {
            contactElement.contact = contact;
        }
    }

    /* 更新信息获取状态 */
    section = [root sectionWithKey:LOADING_SECTION_KEY];
    if (section == nil) {
        section = [[QSection alloc] init];
        section.key = LOADING_SECTION_KEY;
        [root addSection:section];
    } else {
        [section.elements removeAllObjects];
    }
    if (!depart.fetchedInfos || (depart.fetchedInfos && (depart.fetchedCount < depart.totalCount))) {
        if ([[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
            QLoadingElement *element = [[QLoadingElement alloc] init];
            [section addElement:element];
        } else if (depart.fetchedCount <= 0) {
            QEmptyListElement *element = [[QEmptyListElement alloc] initWithTitle:I18nString(@"离线状态下，无法获取部门信息。") Value:nil];
            [section addElement:element];
        }
    } else if (depart.totalCount == 0) {
        QEmptyListElement *element = [[QEmptyListElement alloc] initWithTitle:I18nString(@"没有子部门或联系人") Value:nil];
        [section addElement:element];
    }

    /* 排序联系人 */
    for (section in root.sections) {
        if (section.key == nil || [section.key isEqualToString:DEPART_SECTION_KEY] || [section.key isEqualToString:LOADING_SECTION_KEY]) {
            continue;
        }
        // 到此，section必为联系人章节
        if (section.elements.count <= 1) {
            continue;
        }
        [section.elements sortUsingComparator:^NSComparisonResult(__strong ContactElement *el1, __strong ContactElement *el2) {
            return [el1.contact compareWithContact:el2.contact];
        }];
    }

    /* 排序所有章节 */
    [root.sections sortUsingComparator:^NSComparisonResult(__strong QSection *sec1, __strong QSection *sec2) {
        return [sec1.key compare:sec2.key];
    }];

    /* 将信息获取状态章节移动到表单末尾 */
    NSUInteger index;
    section = [root sectionWithKey:LOADING_SECTION_KEY];
    if (section) {
        index = [root.sections indexOfObject:section];
        if (index != (root.sections.count - 1)) {
            [root.sections moveObjectFromIndex:index toIndex:(root.sections.count - 1)];
        }
    }

    /* 将部门章节移动到表单头 */
    section = [root sectionWithKey:DEPART_SECTION_KEY];
    if (section) {
        index = [root.sections indexOfObject:section];
        if (index != 0) {
            [root.sections moveObjectFromIndex:index toIndex:0];
        }
    }
}

/**
 * 创建最初显示的表单，组织架构从顶级部门开始显示。
 */
- (DepartmentElement *)createForm {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    Department *depart = [app.orgService getTopRootDepartment];
    DepartmentElement *form = [[DepartmentElement alloc] initWithDepartment:depart];
    form.title = depart.name;
    if ([NSString isNullOrEmpty:depart.name]) {
        form.title = I18nString(@"组织架构");
    }

    QSection *section = [[QSection alloc] init];
    section.key = DEPART_SECTION_KEY;
    [form addSection:section];

    section = [[QSection alloc] init];
    section.key = LOADING_SECTION_KEY;
    QElement *element;
    if ([app.accountService isLoggedIn]) {
        element = [[QLoadingElement alloc] init];
    } else {
        element = [[QEmptyListElement alloc] initWithTitle:I18nString(@"离线状态下，无法获取部门信息。") Value:nil];
    }
    [section addElement:element];
    [form addSection:section];

    return form;
}

- (id)init {
    topRoot = [self createForm];
    self = [super initWithRoot:topRoot];
    return self;
}

- (void)loadView {
    [super loadView];
    _SearchBar = [[ContactSearchBar alloc] initWithEditTitle:I18nString(@"添加联系人") andEditDelegate:self];
    _SearchBar.delegate = self;
    [_SearchBar sizeToFit];

    _SearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_SearchBar contentsController:self];
    _SearchDisplayController.searchResultsDelegate = self;
    _SearchDisplayController.searchResultsDataSource = self;
    _SearchDisplayController.delegate = self;

    UIView *view = [[UIView alloc] init];
    [view addSubview:_SearchBar];
    [view addSubview:self.quickDialogTableView];
    self.view = view;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect wholeRect = self.view.frame;

    [_SearchBar sizeToFit];
    CGRect rect = _SearchBar.frame;
    rect.origin.x = rect.origin.y = 0;
    rect.size.width = wholeRect.size.width;
    _SearchBar.frame = rect;

    rect.origin.x = 0;
    rect.origin.y = rect.size.height;
    rect.size.height = wholeRect.size.height - rect.size.height;
    self.quickDialogTableView.frame = rect;
}

#pragma mark - View lifecycle

/**
 * 去除潜在的下载指示器。
 * @return 去除成功，则返回YES；否则返回NO。
 */
- (BOOL)removePotentialLoadingIndicator:(QElement *)_root {
    if (![_root isKindOfClass:[QRootElement class]]) {
        return NO;
    }

    QRootElement *root = (QRootElement *)_root;
    QSection *section = [root sectionWithKey:LOADING_SECTION_KEY];
    if (section == nil) {
        return NO;
    }

    QElement *element = [section.elements lastObject];
    if (element == nil || ![element isKindOfClass:[QLoadingElement class]]) {
        return NO;
    }

    [section.elements removeObject:element];
    return YES;
}

- (void)addLoadingIndicator:(QRootElement *)root {
    QSection *section = [root sectionWithKey:LOADING_SECTION_KEY];
    if (section == nil) {
        section = [[QSection alloc] init];
        section.key = LOADING_SECTION_KEY;
        [root addSection:section];
    }

    QElement *element = [section.elements lastObject];
    if (element != nil) {
        if ([element isKindOfClass:[QLoadingElement class]]) {
            return;
        } else {
            [section.elements removeObject:element];
            element = nil;
        }
    }

    // to here, element must be nil
    element = [[QLoadingElement alloc] init];
    [section addElement:element];
}

- (QElement *)getElementFromTopRootWithKey:(NSString *)key {
    QElement *el = [topRoot elementWithKey:key];
    if (el == nil && [topRoot.key isEqualToString:key]) {
        el = topRoot;
    }
    return el;
}

- (void)onFetchedOrgInfo:(NSNotification *)note {
    @synchronized (self) {
        NSInteger fetchedDepartId = [(NSNumber *)(note.object) integerValue];
        Department *depart = ((DepartmentElement *)self.root).department;
        BOOL fetchedShownDepart = (fetchedDepartId == depart.id);

        if ([note.name isEqualToString:UCA_EVENT_FETCHED_ORG_INFO_FAILED]) {
            NSString *key = [(NSNumber *)(note.object) stringValue];
            QElement *root = [self getElementFromTopRootWithKey:key];
            if ([self removePotentialLoadingIndicator:root] && root == self.root) {
                [self reloadOrgInfoTable];
            }
            if (fetchedShownDepart) {
                [NotifyUtils alert:I18nString(@"组织架构信息获取失败，请稍候重试。")];
            }
            return;
        }

        // 根据UcaOrgService里的部门信息树更新整个QuickDialog表单。
        depart = [[UcaAppDelegate sharedInstance].orgService getTopRootDepartment];
        [self updateRoot:topRoot withInfo:depart];

        if (fetchedShownDepart) {
            [self removePotentialLoadingIndicator:self.root];
            QElement *root = [self getElementFromTopRootWithKey:self.root.key];
            self.root = (DepartmentElement *)root;
            [self reloadOrgInfoTable];
        }
    }
}

- (void)onSearchedOrgInfo:(NSNotification *)note {
    @synchronized (self) {
        _fetchingSearchResult = NO;
        _hasFetchedSearchResult = YES;

        if ([note.name isEqualToString:UCA_EVENT_SEARCHED_ORG_INFO_FAILED]) {
            [NotifyUtils alert:I18nString(@"搜索失败，请稍候重试。")];
            [self reloadSearchResultTable];
            return;
        }

        [_searchResult removeAllObjects];

        NSDictionary *infos = note.userInfo;
        if (!infos) {
            UcaLog(TAG, @"Search : Found nothing");
            [self reloadSearchResultTable];
            return;
        }

        DepartmentElement *departElement = nil;
        NSMutableArray *data = [infos objectForKey:KEY_DEPARTS];
        for (Department *depart in data) {
            departElement = [[DepartmentElement alloc] initWithDepartment:depart];
            [_searchResult addObject:departElement];

            // 为每一个找到的部门准备一个空章节，以便用户可以查看该部门信息。
            QSection *section = [[QSection alloc] init];
            [departElement addSection:section];
        }

        ContactElement *contactElement = nil;
        data = [infos objectForKey:KEY_USERINFOS];
        _foundContact = (data != nil && data.count > 0);
        for (Contact *contact in data) {
            contactElement = [[ContactElement alloc] initWithContact:contact andDelegate:self];
            [_searchResult addObject:contactElement];
        }

        [self reloadSearchResultTable];
    }
}

- (void)tryFetchOrgInfo {
    @synchronized (self) {
        UcaLog(TAG, @"tryFetchOrgInfo");

        UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
        if (![app.accountService isLoggedIn]) {
            return;
        }

        Department* depart = ((DepartmentElement *)self.root).department;
        if (!depart.fetchedInfos || (depart.fetchedInfos && (depart.fetchedCount < depart.totalCount))) {
            _fetchingOrgInfo = YES;
            [app.orgService fetchOrgInfoByDepartId:depart.id];
            [self addLoadingIndicator:self.root];
            [self reloadOrgInfoTable];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UcaLog(TAG, @"viewDidLoad");

    self.quickDialogTableView.backgroundColor = APP_BGCOLOR;
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.quickDialogTableView.useSectionKeyAsIndexTitle = YES;
    self.quickDialogTableView.allowsMultipleSelectionDuringEditing = YES;

    _searchTableViewShown = NO;
    _fetchingOrgInfo = NO;
    _fetchingSearchResult = NO;
    _hasFetchedSearchResult = NO;
    _searchResult = [NSMutableArray array];

    _cancelAddingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                        target:self
                                                                        action:@selector(exitEditingMode)];
    _confirmAddingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                         target:self
                                                                         action:@selector(confirmAddContacts)];
    _addContactButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                      target:self
                                                                      action:@selector(enterEditingMode)];
    _refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                   target:self
                                                                   action:@selector(tryFetchOrgInfo)];
    [self reloadOrgInfoTableTitlebar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UcaLog(TAG, @"viewDidAppear %@", self.root);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onFetchedOrgInfo:)
                                                 name:UCA_EVENT_FETCHED_ORG_INFO
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onFetchedOrgInfo:)
                                                 name:UCA_EVENT_FETCHED_ORG_INFO_FAILED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSearchedOrgInfo:)
                                                 name:UCA_EVENT_SEARCHED_ORG_INFO
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSearchedOrgInfo:)
                                                 name:UCA_EVENT_SEARCHED_ORG_INFO_FAILED
                                               object:nil];
    [self tryFetchOrgInfo];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    UcaLog(TAG, @"viewDidDisappear %@", self.root);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

#pragma mark - ContactSearchBarDelegate

- (void)contactSearchBarEnterEditing {
    if (_searchTableViewShown && !_SearchDisplayController.searchResultsTableView.editing) {
        _SearchDisplayController.searchResultsTableView.editing = YES;
        [self reloadSearchResultTableTitleBar];
    }
}

- (void)contactSearchBarConfirmEditing {
    if (_searchTableViewShown) {
        [self confirmAddContacts];
    }
}

- (void)contactSearchBarExitEditing {
    if (_searchTableViewShown && _SearchDisplayController.searchResultsTableView.editing) {
        _SearchDisplayController.searchResultsTableView.editing = NO;
        [self reloadSearchResultTableTitleBar];
    }
}

#pragma mark - ContactElementDelegate methods

- (BOOL)canResponseToContact:(Contact *)contact {
    if (_searchTableViewShown) {
        return !_SearchDisplayController.searchResultsTableView.editing && contact != nil;
    }
    return !self.quickDialogTableView.editing && contact != nil;
}

- (void)contactElementOnClicked:(ContactElement *)element {
    [self contactElementImOnClicked:element.contact];
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

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _hasFetchedSearchResult ? _searchResult.count : (_fetchingSearchResult ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 只有两种情况下，本函数才会被调用：1. 搜索到有效结果；2. 要显示正在搜索的进度动画
    UITableViewCell *cell = nil;
    if (_fetchingSearchResult) {
        QLoadingElement *element = [[QLoadingElement alloc] init];
        cell = [element getCellForTableView:(QuickDialogTableView *)tableView controller:self];
    } else if (indexPath.row >= 0 && indexPath.row < _searchResult.count) {
        QRootElement *element = [_searchResult objectAtIndex:indexPath.row];
        cell = [element getCellForTableView:(QuickDialogTableView *)tableView controller:self];
        if ([cell isKindOfClass:[DepartmentElement class]]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= _searchResult.count) {
        return NO;
    }

    QRootElement *element = [_searchResult objectAtIndex:indexPath.row];
    return element.allowSelectInEditMode && tableView.editing;
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_fetchingSearchResult) {
        return 44; // 进度动画默认高度
    }

    if (indexPath.row < 0 || indexPath.row >= _searchResult.count) {
        return 0;
    }

    QRootElement *element = [_searchResult objectAtIndex:indexPath.row];
    return element.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    if (_fetchingSearchResult || indexPath.row < 0 || indexPath.row >= _searchResult.count) {
        return;
    }

    QRootElement *element = [_searchResult objectAtIndex:indexPath.row];
    if ([element isKindOfClass:[ContactElement class]]) {
        [element handleElementSelected:self];
    } else if ([element isKindOfClass:[DepartmentElement class]]) {
        [element selected:(QuickDialogTableView *)tableView controller:self indexPath:indexPath];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_fetchingSearchResult || indexPath.row < 0 || indexPath.row >= _searchResult.count) {
        return nil;
    }

    QRootElement *element = [_searchResult objectAtIndex:indexPath.row];
    if (element.allowSelectInEditMode) {
        return indexPath;
    }
    return (tableView.editing ? nil : indexPath);
}

#pragma mark - UISearchDisplayDelegate methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    _hasFetchedSearchResult = NO;
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    _hasFetchedSearchResult = NO;
    return NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    _searchTableViewShown = YES;
    _SearchDisplayController.searchResultsTableView.allowsMultipleSelectionDuringEditing = YES;
    _SearchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self reloadSearchResultTableTitleBar];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    _searchTableViewShown = NO;
    [self reloadSearchResultTableTitleBar];
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (!_fetchingSearchResult) {
        _fetchingSearchResult = YES;
        _hasFetchedSearchResult = NO;
        [self contactSearchBarExitEditing];
        [self reloadSearchResultTable];
        [[UcaAppDelegate sharedInstance].orgService searchOrgInfo:searchBar.text];
    } else {
        [NotifyUtils alert:I18nString(@"正在搜索，请稍候⋯⋯")];
    }
}

@end
