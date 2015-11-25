/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "AccountDetailsView.h"

#undef TAG
#define TAG @"AccountDetailsView"

#define AVATAR_ENTRY        @"AVATAR_ENTRY"
#define PRESENTSTATUS_ENTRY @"PRESENTSTATUS_ENTRY"
#define NICKNAME_ENTRY      @"NICKNAME_ENTRY"
#define SEX_ENTRY           @"SEX_ENTRY"
#define FAMILY_ADDR_ENTRY   @"FAMILY_ADDR_ENTRY"
#define FAMILY_PHONE_ENTRY  @"FAMILY_PHONE_ENTRY"
#define PHONE1_ENTRY        @"PHONE1_ENTRY"
#define PHONE2_ENTRY        @"PHONE2_ENTRY"
#define OTHER_PHONE_ENTRY   @"OTHER_PHONE_ENTRY"
#define SHOW_INFO_ENTRY     @"SHOW_INFO_ENTRY"
#define IM_RINGS_ENTRY      @"IM_RINGS_ENTRY"

/**
 * QRadioElement有个BUG：QRadioElement会用其所在页面的类创建一个新的页面，并显示
 * 所有选项。当选中某一选项时，其callback函数被调用，此时该callback函数内self指向选
 * 项所在页面，而不是QRadioElement自身所在页面，因此不能通过该self来访问
 * QRadioElement自身所在页面controller中的变量。
 */
static AccountDetailsView *sInstance = nil;

@implementation AccountDetailsView {
    NSInteger modifications;
    NSNumber *_dstPresent;
    UIBarButtonItem *confirmBtn;
    UIBarButtonItem *cancelBtn;

    Account *_curAccount;
}

- (QRadioElement *)replaceEntry:(QElement *)entry toRadioWithItems:(NSArray *)items selected:(NSInteger)selected {
    QRadioElement *newEntry = nil;
    NSString *title = ((QLabelElement *)entry).title;

    if ([entry isKindOfClass:[QRadioElement class]]) {
        newEntry = (QRadioElement *)entry;
        newEntry.items = items;
        newEntry.selected = selected;
        return newEntry;
    }

    QSection *section = entry.parentSection;
    NSUInteger index = [section indexOfElement:entry];
    newEntry = [[QRadioElement alloc] initWithItems:items
                                           selected:selected
                                              title:title];
    newEntry.key = entry.key;
    newEntry.delegate = self;
    [section.elements replaceObjectAtIndex:index withObject:newEntry];
    return newEntry;
}

- (QLabelElement *)replaceEntry:(QElement *)entry toLabelWithValue:(id)value {
    QSection *section = entry.parentSection;
    NSUInteger index = [section indexOfElement:entry];
    QLabelElement *newEntry = nil;
    NSString *title = ((QLabelElement *)entry).title;

    if ([entry isKindOfClass:[QRadioElement class]] || [entry isKindOfClass:[QEntryElement class]]) {
        newEntry = [[QLabelElement alloc] initWithTitle:title
                                                  Value:value];
    }

    if (newEntry == nil) {
        return (QLabelElement *)entry;
    }

    newEntry.key = entry.key;
    [section.elements replaceObjectAtIndex:index withObject:newEntry];
    return newEntry;
}

- (QEntryElement *)replaceEntry:(QElement *)entry toInputWithValue:(NSString *)value {
    QEntryElement *newEntry = nil;

    if ([entry isKindOfClass:[QEntryElement class]]) {
        newEntry = (QEntryElement *)entry;
        newEntry.textValue = value;
        return newEntry;
    }

    QSection *section = entry.parentSection;
    NSUInteger index = [section indexOfElement:entry];
    newEntry = [[QEntryElement alloc] initWithTitle:((QEntryElement *)entry).title
                                              Value:value
                                        Placeholder:nil];
    newEntry.key = entry.key;
    newEntry.delegate = self;
    [section.elements replaceObjectAtIndex:index withObject:newEntry];
    return newEntry;
}

- (void)reloadTable {
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;

    QRadioElement *presentEntry = (QRadioElement *)[[self root] elementWithKey:PRESENTSTATUS_ENTRY];
    presentEntry.selected = service.curPresent;

    if (modifications > 0) {
        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//        [self.quickDialogTableView reloadCellForElements:presentEntry, nil];
        return;
    }

    AvatarElement *avatarElement  = (AvatarElement *)[[self root] elementWithKey:AVATAR_ENTRY];

    QElement *sexEntry         = [[self root] elementWithKey:SEX_ENTRY];
    QElement *nickNameEntry    = [[self root] elementWithKey:NICKNAME_ENTRY];
    QElement *familyAddrEntry  = [[self root] elementWithKey:FAMILY_ADDR_ENTRY];
    QElement *familyPhoneEntry = [[self root] elementWithKey:FAMILY_PHONE_ENTRY];
    QElement *phone1Entry      = [[self root] elementWithKey:PHONE1_ENTRY];
    QElement *phone2Entry      = [[self root] elementWithKey:PHONE2_ENTRY];
    QElement *otherPhoneEntry  = [[self root] elementWithKey:OTHER_PHONE_ENTRY];
    QBooleanElement *showInfoEntry = (QBooleanElement *)[[self root] elementWithKey:SHOW_INFO_ENTRY];

    _curAccount = service.currentAccount;

    avatarElement.image = _curAccount.photo;
    avatarElement.text = _curAccount.descrip;
    avatarElement.editable = [service isLoggedIn];

    showInfoEntry.boolValue = _curAccount.showPersonalInfo;
    showInfoEntry.enabled = [service isLoggedIn];

    if ([service isLoggedIn]) {
        sexEntry = [self replaceEntry:sexEntry
                     toRadioWithItems:[UcaConstants descriptionOfGenders]
                             selected:(_curAccount.isFemale ? 1 : 0)];

        nickNameEntry = [self replaceEntry:nickNameEntry toInputWithValue:_curAccount.nickname];
        familyAddrEntry = [self replaceEntry:familyAddrEntry toInputWithValue:_curAccount.familyAddress];
        familyPhoneEntry = [self replaceEntry:familyPhoneEntry toInputWithValue:_curAccount.familyPhone];
        phone1Entry = [self replaceEntry:phone1Entry toInputWithValue:_curAccount.mobilePhone];
        phone2Entry = [self replaceEntry:phone2Entry toInputWithValue:_curAccount.mobilePhone2];
        otherPhoneEntry = [self replaceEntry:otherPhoneEntry toInputWithValue:_curAccount.otherPhone];
    } else {
        sexEntry = [self replaceEntry:sexEntry toLabelWithValue:[UcaConstants descriptionOfGender:_curAccount.isFemale]];
        nickNameEntry = [self replaceEntry:nickNameEntry toLabelWithValue:_curAccount.nickname];
        familyAddrEntry = [self replaceEntry:familyAddrEntry toLabelWithValue:_curAccount.familyAddress];
        familyPhoneEntry = [self replaceEntry:familyPhoneEntry toLabelWithValue:_curAccount.familyPhone];
        phone1Entry = [self replaceEntry:phone1Entry toLabelWithValue:_curAccount.mobilePhone];
        phone2Entry = [self replaceEntry:phone2Entry toLabelWithValue:_curAccount.mobilePhone2];
        otherPhoneEntry = [self replaceEntry:otherPhoneEntry toLabelWithValue:_curAccount.otherPhone];
    }

    [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//    [self.quickDialogTableView reloadCellForElements:avatarElement, presentEntry,
//        nickNameEntry, sexEntry, familyAddrEntry,
//        familyPhoneEntry, phone1Entry, phone2Entry, otherPhoneEntry, showInfoEntry, nil];
}

- (IBAction)confirmModification:(id)button {
    AvatarElement *avatarElement = (AvatarElement *)[[self root] elementWithKey:AVATAR_ENTRY];
    UIImage *photo = avatarElement.image;
    NSString *descrip = avatarElement.text;

    NSString *nickname = ((QEntryElement *)[[self root] elementWithKey:NICKNAME_ENTRY]).textValue;
    BOOL isFemale = (((QRadioElement *)[[self root] elementWithKey:SEX_ENTRY]).selected == 1);
    NSString *familyAddress = ((QEntryElement *)[[self root] elementWithKey:FAMILY_ADDR_ENTRY]).textValue;
    NSString *familyPhone = ((QEntryElement *)[[self root] elementWithKey:FAMILY_PHONE_ENTRY]).textValue;
    NSString *mobilePhone = ((QEntryElement *)[[self root] elementWithKey:PHONE1_ENTRY]).textValue;
    NSString *mobilePhone2 = ((QEntryElement *)[[self root] elementWithKey:PHONE2_ENTRY]).textValue;
    NSString *otherPhone = ((QEntryElement *)[[self root] elementWithKey:OTHER_PHONE_ENTRY]).textValue;
    BOOL showPersonalInfo = ((QBooleanElement *)[[self root] elementWithKey:SHOW_INFO_ENTRY]).boolValue;

    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;

    if (![service updateAccount:service.curAccountId
                          photo:photo
                    description:descrip
                       nickname:nickname
                       isFemale:isFemale
                  familyAddress:familyAddress
                    familyPhone:familyPhone
                    mobilePhone:mobilePhone
                   mobilePhone2:mobilePhone2
                     otherPhone:otherPhone
               showPersonalInfo:showPersonalInfo]) {
        [NotifyUtils alert:I18nString(@"更新帐号信息失败，请稍后重试。")];
        return;
    }

    modifications = 0;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
}

- (IBAction)cancelModification:(id)button {
    modifications = 0;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
    [self reloadTable];
}

- (void)tryShowTopModifyButtons {
    modifications++;
    if (modifications > 0) {
        self.navigationItem.leftBarButtonItem = cancelBtn;
        self.navigationItem.rightBarButtonItem = confirmBtn;
    }
}

- (void)tryHideTopModifyButtons {
    modifications--;
    if (modifications <= 0) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)onAccountUpdate:(NSNotification *)note {
//    [self performSelectorInBackground:@selector(reloadTableWithAccount:) withObject:account];
//    [self reloadTableWithAccount:account];

    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
    if ([service isLoggedIn]) {
        [self performSelectorOnMainThread:@selector(reloadTable) withObject:nil waitUntilDone:YES];
    }

    if ([note.name isEqualToString:UCA_EVENT_UPDATE_PRESENT_FAIL]) {
        _dstPresent = nil;
        [NotifyUtils alert:I18nString(@"更改“我的状态”失败，请稍后重试。")];
    } else if ([note.name isEqualToString:UCA_EVENT_UPDATE_PRESENT_OK]) {
        _dstPresent = nil;
    } else if (_dstPresent != nil && [service isLoggedIn]) {
        [service requestChangePresent:[_dstPresent intValue]];
    } else if ([service isLoggedInFailed]) {
        _dstPresent = nil;
        [NotifyUtils alert:[UcaConstants descriptionOfLoginStatus:service.curLoginStatus]];
    }
}

- (void)onChangePresentation:(QRadioElement *)element {
    UCALIB_PRESENTATIONSTATE dstPresent = element.selected;
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;

    if (dstPresent == service.curPresent) {
        return;
    }

    _dstPresent = [NSNumber numberWithInt:dstPresent];

    if (dstPresent == UCALIB_PRESENTATIONSTATE_OFFLINE && [service isLoggedIn]) {
        [NotifyUtils confirm:I18nString(@"切换到“离线”状态将导致退出本帐号，确定吗？") delegate:sInstance];
    } else if (dstPresent != UCALIB_PRESENTATIONSTATE_OFFLINE && ([service isLoggedOut] || [service isLoggedInFailed])) {
        [NotifyUtils confirm:I18nString(@"确定登录本帐号吗？") delegate:sInstance];
    } else if ([service isLoggedIn] || [service isLoggedOut] || [service isLoggedInFailed]) {
        [service requestChangePresent:dstPresent];
    }
}

- (void)onChangeSex:(QRadioElement *)element {
    _curAccount = [UcaAppDelegate sharedInstance].accountService.currentAccount;
    if (element.selected != _curAccount.isFemale) {
        [sInstance tryShowTopModifyButtons];
    } else {
        [sInstance tryHideTopModifyButtons];
    }
}

- (void)onShareInfoChanged:(QBooleanElement *)switcher {
    _curAccount = [UcaAppDelegate sharedInstance].accountService.currentAccount;
    if (switcher.boolValue != _curAccount.showPersonalInfo) {
        [self tryShowTopModifyButtons];
    } else {
        [self tryHideTopModifyButtons];
    }
}

- (QBooleanElement *)createBoolEntry:(NSString *)title value:(BOOL)value {
    QBooleanElement *entry = [[QBooleanElement alloc] initWithTitle:title BoolValue:value];
    entry.onImage = [UIImage imageNamed:@"res/imgOn"];
    entry.offImage = [UIImage imageNamed:@"res/imgOff"];
    return entry;
}

/**
 * 按以下格式创建表单章节：
 *
 * 头像 & 签名: photo, descrip
 * 登录: presentationDesp
 */
- (QSection *)createHeadSection:(Account *)account {
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;

    QSection *section = [[QSection alloc] init];

    AvatarElement *avatarElement = [[AvatarElement alloc] initWithText:account.descrip
                                                              andImage:account.photo
                                                              editable:[service isLoggedIn]];
    avatarElement.key = AVATAR_ENTRY;
    avatarElement.delegate = self;
    [section addElement:avatarElement];

    QRadioElement *presentStatusEntry = [[QRadioElement alloc] initWithItems:[UcaConstants descriptionOfAllPresentations]
                                                                    selected:service.curPresent
                                                                       title:I18nString(@"我的状态")];
    presentStatusEntry.icons = [UcaConstants iconOfAllPresentations];
    presentStatusEntry.controllerAction = @"onChangePresentation:";
    presentStatusEntry.key = PRESENTSTATUS_ENTRY;
    [section addElement:presentStatusEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 帐号: username
 * 服务器: serverParam, serverDomain
 */
- (QSection *)createAccountSection:(Account *)account {
    QSection *section = [[QSection alloc] init];

    QLabelElement *usernameEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"用户名") Value:account.username];
    [section addElement:usernameEntry];

    QLabelElement *serverIpEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"服务器IP") Value:account.serverParam.ip];
    [section addElement:serverIpEntry];

    QLabelElement *serverDomainEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"服务器域名") Value:account.serverDomain];
    [section addElement:serverDomainEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 姓名: firstname, lastname, nickname, aliases
 */
- (QSection *)createNameSection:(Account *)account {
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
    QSection *section = [[QSection alloc] init];

    QLabelElement *firstnameEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"姓") Value:account.firstname];
    QLabelElement *lastnameEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"名") Value:account.lastname];

    QLabelElement *nicknameEntry =nil;
    if ([service isLoggedIn]) {
        // 登录状态下，可以修改
        nicknameEntry = [[QEntryElement alloc] initWithTitle:I18nString(@"昵称") Value:account.nickname Placeholder:nil];
        ((QEntryElement *)nicknameEntry).delegate = self;
    } else {
        // 未登录状态下，不能修改
        nicknameEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"昵称") Value:account.nickname];
    }
    nicknameEntry.key = NICKNAME_ENTRY;

    [section addElement:firstnameEntry];
    [section addElement:lastnameEntry];
    [section addElement:nicknameEntry];

    QTextElement *aliasEntry = [[QTextElement alloc] initWithText:[account.aliases componentsJoinedByString:@","]];
    aliasEntry.title = I18nString(@"别名");
    [section addElement:aliasEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 性别: isFemale
 */
- (QSection *)createSexSection:(Account *)account {
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
    QSection *section = [[QSection alloc] init];

    QLabelElement *sexEntry = nil;
    if ([service isLoggedIn]) {
        // 登录状态下，可以修改
        sexEntry = [[QRadioElement alloc] initWithItems:[UcaConstants descriptionOfGenders]
                                               selected:account.isFemale
                                                  title:I18nString(@"性别")];

        sexEntry.controllerAction = @"onChangeSex:";
    } else {
        // 未登录状态下，不能修改
        sexEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"性别")
                                                  Value:[UcaConstants descriptionOfGender:account.isFemale]];
    }
    sexEntry.key = SEX_ENTRY;
    [section addElement:sexEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 群组: groups
 */
- (QSection *)createGroupSection:(Account *)account {
    QSection *section = [[QSection alloc] init];

    QTextElement *groupsEntry = [[QTextElement alloc] initWithText:[account.groups componentsJoinedByString:@","]];
    groupsEntry.title = I18nString(@"所属的分组");
    [section addElement:groupsEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 邮箱: email, voicemail
 */
- (QSection *)createMailSection:(Account *)account {
    QSection *section = [[QSection alloc] init];
    QLabelElement *emailEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"邮箱地址") Value:account.email];
    [section addElement:emailEntry];
    QLabelElement *voiceMailEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"语音邮箱") Value:account.voicemail];
    [section addElement:voiceMailEntry];
    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 家庭: familyAddress, familyPhone
 */
- (QSection *)createHomeSection:(Account *)account {
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"家庭")];

    QLabelElement *addrEntry = nil;
    QLabelElement *phoneEntry = nil;

    if ([service isLoggedIn]) {
        // 登录状态下，可以修改
        addrEntry = [[QEntryElement alloc] initWithTitle:I18nString(@"地址") Value:account.familyAddress Placeholder:nil];
        phoneEntry = [[QEntryElement alloc] initWithTitle:I18nString(@"电话") Value:account.familyPhone Placeholder:nil];
        ((QEntryElement *)addrEntry).delegate = self;
        ((QEntryElement *)phoneEntry).delegate = self;
    } else {
        // 未登录状态下，不能修改
        addrEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"地址") Value:account.familyAddress];
        phoneEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"电话") Value:account.familyPhone];
    }
    addrEntry.key = FAMILY_ADDR_ENTRY;
    phoneEntry.key = FAMILY_PHONE_ENTRY;

    [section addElement:addrEntry];
    [section addElement:phoneEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 公司: customHisotlogy, company, companyAddress, department, position, workPhone
 */
- (QSection *)createCompanySection:(Account *)account {
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"公司")];

    QLabelElement *customHisotlogyEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"组织架构") Value:account.customHisotlogy];
    QLabelElement *nameEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"名称") Value:account.company];
    QLabelElement *addrEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"地址") Value:account.companyAddress];
    QLabelElement *departEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"部门") Value:account.departName];
    QLabelElement *positionEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"职位") Value:account.position];
    QLabelElement *phoneEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"电话") Value:account.workPhone];

    [section addElement:customHisotlogyEntry];
    [section addElement:nameEntry];
    [section addElement:addrEntry];
    [section addElement:departEntry];
    [section addElement:positionEntry];
    [section addElement:phoneEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 其他电话: sipPhone, mobilePhone, mobilePhone2, otherPhone
 */
- (QSection *)createPhoneSection:(Account *)account {
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"电话")];

    QLabelElement *sipEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"软终端号码") Value:account.sipPhone];
    [section addElement:sipEntry];

    QLabelElement *phone1Entry = nil;
    QLabelElement *phone2Entry = nil;
    QLabelElement *otherEntry  = nil;

    if ([service isLoggedIn]) {
        // 登录状态下，可以修改
        phone1Entry = [[QEntryElement alloc] initWithTitle:I18nString(@"联系电话一") Value:account.mobilePhone Placeholder:nil];
        phone2Entry = [[QEntryElement alloc] initWithTitle:I18nString(@"联系电话二") Value:account.mobilePhone2 Placeholder:nil];
        otherEntry  = [[QEntryElement alloc] initWithTitle:I18nString(@"其他号码") Value:account.otherPhone Placeholder:nil];
        ((QEntryElement *)phone1Entry).delegate = self;
        ((QEntryElement *)phone2Entry).delegate = self;
        ((QEntryElement *)otherEntry).delegate  = self;
    } else {
        // 未登录状态下，不能修改
        phone1Entry = [[QLabelElement alloc] initWithTitle:I18nString(@"联系电话一") Value:account.mobilePhone];
        phone2Entry = [[QLabelElement alloc] initWithTitle:I18nString(@"联系电话二") Value:account.mobilePhone2];
        otherEntry  = [[QLabelElement alloc] initWithTitle:I18nString(@"其他号码") Value:account.otherPhone];
    }
    phone1Entry.key = PHONE1_ENTRY;
    phone2Entry.key = PHONE2_ENTRY;
    otherEntry.key  = OTHER_PHONE_ENTRY;

    [section addElement:phone1Entry];
    [section addElement:phone2Entry];
    [section addElement:otherEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 配置: showPersonalInfo
 */
- (QSection *)createSettingSection:(Account *)account {
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"配置")];

    QBooleanElement *shareInfoEntry = [self createBoolEntry:I18nString(@"显示个人信息给其他人看") value:account.showPersonalInfo];
    if ([service isLoggedIn]) {
        // 登录状态下，可以修改
        shareInfoEntry.enabled = YES;
        shareInfoEntry.controllerAccessoryAction = @"onShareInfoChanged:";
    } else {
        // 未登录状态下，不能修改
        shareInfoEntry.enabled = NO;
    }
    shareInfoEntry.key = SHOW_INFO_ENTRY;
    [section addElement:shareInfoEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 权限: privileges
 */
- (QSection *)createPrivilegeSection:(Account *)account {
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"权限")];

    QLabelElement *sendSizeEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"发送文件大小上限(KB)") Value:[NSNumber numberWithInt:account.privileges.sendFileSize]];
    [section addElement:sendSizeEntry];

    QLabelElement *sendSpeedEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"文件传输速率上限(KB)") Value:[NSNumber numberWithInt:account.privileges.sendFileSpeed]];
    [section addElement:sendSpeedEntry];

    QBooleanElement *permEntry = [self createBoolEntry:I18nString(@"文件传输") value:account.privileges.fileTransfers];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"超级用户") value:account.privileges.superAdmin];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"强插强拆") value:account.privileges.intrusionBreakdown];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"语音邮箱") value:account.privileges.voicemail];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"通过语音邮件系统修改PIN码") value:account.privileges.tuiChangePin];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"自动语音提示语录制") value:account.privileges.recordSystemPrompts];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"即时消息") value:account.privileges.instantMessage];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"名字拨号") value:account.privileges.autoAttendant];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"呼叫外线转移") value:account.privileges.forwardCallsExternal];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"会议创建") value:account.privileges.meetingCreate];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    permEntry = [self createBoolEntry:I18nString(@"协同") value:account.privileges.cooperateWith];
    permEntry.enabled = NO;
    [section addElement:permEntry];

    return section;
}

/**
 * 按以下格式创建UI：
 *
 * 头像 & 签名: photo, descrip
 * 登录: presentationDesp
 *
 * 帐号: username
 * 服务器: serverParam, serverDomain
 *
 * 姓名: firstname, lastname, nickname, aliases
 *
 * 性别: isFemale
 *
 * 群组: groups
 *
 * 邮箱: email, voicemail
 *
 * 家庭: familyAddress, familyPhone
 *
 * 公司: customHisotlogy, company, companyAddress, department, position, workPhone
 *
 * 其他电话: sipPhone, mobilePhone, mobilePhone2, otherPhone
 *
 * 配置: showPersonalInfo
 *
 * 权限: privileges
 */
- (QRootElement *)createFormWithAccount:(Account *)account {
    QRootElement *form = [[QRootElement alloc] init];
    form.grouped = YES;
    form.title = I18nString(@"我的资料");
    [form addSection:[self createHeadSection:account]];
    [form addSection:[self createAccountSection:account]];
    [form addSection:[self createNameSection:account]];
    [form addSection:[self createSexSection:account]];
    [form addSection:[self createGroupSection:account]];
    [form addSection:[self createMailSection:account]];
    [form addSection:[self createHomeSection:account]];
    [form addSection:[self createCompanySection:account]];
    [form addSection:[self createPhoneSection:account]];
    [form addSection:[self createSettingSection:account]];
    [form addSection:[self createPrivilegeSection:account]];
    return form;
}

- (id)init {
    Account *account = [UcaAppDelegate sharedInstance].accountService.currentAccount;
    QRootElement *root = [self createFormWithAccount:account];
    self = [super initWithRoot:root];
    if (self) {
        self.title = root.title;
        confirmBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                   target:self
                                                                   action:@selector(confirmModification:)];
        cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                  target:self
                                                                  action:@selector(cancelModification:)];
        modifications = 0;
        _curAccount = account;
    }
    if (!sInstance) {
        sInstance = self;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Preserve selection between presentations.
    self.quickDialogTableView.backgroundColor = APP_BGCOLOR;
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.navigationController.navigationBarHidden = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAccountUpdate:)
                                                 name:UCA_EVENT_UPDATE_ACCOUNT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAccountUpdate:)
                                                 name:UCA_EVENT_UPDATE_LOGIN_STATUS
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAccountUpdate:)
                                                 name:UCA_EVENT_UPDATE_PRESENT_OK
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAccountUpdate:)
                                                 name:UCA_EVENT_UPDATE_PRESENT_FAIL
                                               object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.quickDialogTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma UIAlertViewDelegate methods
/**
 * 确认退出或登录账号。
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // confirm
        UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
        if ([service isLoggedIn]) {
            _dstPresent = nil;
            [service performSelectorInBackground:@selector(requestLogout) withObject:nil];
        } else if ([service isLoggedOut] || [service isLoggedInFailed]) {
            [service performSelectorInBackground:@selector(requestLogin:) withObject:nil];
        }
    } else { // cancel
        _dstPresent = nil;
        [self reloadTable];
    }
}

#pragma QuickDialogEntryElementDelegate methods

- (void)QEntryDidEndEditingElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    BOOL changed = NO;

    if ([element.key isEqualToString:NICKNAME_ENTRY]) {
        changed = ![_curAccount.nickname isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:FAMILY_ADDR_ENTRY]) {
        changed = ![_curAccount.familyAddress isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:FAMILY_PHONE_ENTRY]) {
        changed = ![_curAccount.familyPhone isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:PHONE1_ENTRY]) {
        changed = ![_curAccount.mobilePhone isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:PHONE2_ENTRY]) {
        changed = ![_curAccount.mobilePhone2 isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:OTHER_PHONE_ENTRY]) {
        changed = ![_curAccount.otherPhone isEqualToString:element.textValue];
    }

    if (changed) {
        [self tryShowTopModifyButtons];
    } else {
        [self tryHideTopModifyButtons];
    }
}

#pragma AvatarElementDelegate methods

- (void)AvatarDidEndEditingElement:(AvatarElement *)element andCell:(UITableViewCell *)cell {
    if ([element.text isEqualToString:_curAccount.descrip] && element.image == _curAccount.photo) {
        [self tryHideTopModifyButtons];
    } else {
        [self tryShowTopModifyButtons];
    }
}

@end
