/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "ContactDetailsView.h"
#import "MessageChatView.h"

#define AVATAR_ENTRY           @"AVATAR_ENTRY"
#define PRESENTSTATUS_ENTRY    @"PRESENTSTATUS_ENTRY"
#define FIRSTNAME_ENTRY        @"FIRSTNAME_ENTRY"
#define LASTNAME_ENTRY         @"LASTNAME_ENTRY"
#define NICKNAME_ENTRY         @"NICKNAME_ENTRY"
#define SEX_ENTRY              @"SEX_ENTRY"
#define GROUPS_ENTRY           @"GROUPS_ENTRY"
#define EMAIL_ENTRY            @"EMAIL_ENTRY"
#define VOICEEMAIL_ENTRY       @"VOICEEMAIL_ENTRY"
#define FAMILY_ADDR_ENTRY      @"FAMILY_ADDR_ENTRY"
#define FAMILY_PHONE_ENTRY     @"FAMILY_PHONE_ENTRY"
#define COMPANY_NAME_ENTRY     @"COMPANY_NAME_ENTRY"
#define COMPANY_ADDR_ENTRY     @"COMPANY_ADDR_ENTRY"
#define COMPANY_DEPART_ENTRY   @"COMPANY_DEPART_ENTRY"
#define COMPANY_POSITION_ENTRY @"COMPANY_POSITION_ENTRY"
#define COMPANY_PHONE_ENTRY    @"COMPANY_PHONE_ENTRY"
#define SIP_ENTRY              @"SIP_ENTRY"
#define PHONE1_ENTRY           @"PHONE1_ENTRY"
#define PHONE2_ENTRY           @"PHONE2_ENTRY"
#define OTHER_PHONE_ENTRY      @"OTHER_PHONE_ENTRY"
#define SHOW_INFO_ENTRY        @"SHOW_INFO_ENTRY"

/**
 * QRadioElement有个BUG：QRadioElement会用其所在页面的类创建一个新的页面，并显示
 * 所有选项。当选中某一选项时，其callback函数被调用，此时该callback函数内self指向选
 * 项所在页面，而不是QRadioElement自身所在页面，因此不能通过该self来访问
 * QRadioElement自身所在页面controller中的变量。
 */
static ContactDetailsView *sInstance = nil;

@implementation ContactDetailsView

- (BOOL)isEditable:(Contact *)contact {
    switch (contact.contactType) {
    case ContactType_AddressBook:
        return YES;
    case ContactType_Unknown:
    case ContactType_Friend:
        return NO;
    case ContactType_Private:
    default:
        return [[UcaAppDelegate sharedInstance].accountService isLoggedIn];
    }
}

- (void)reloadTitleBarButtons {
    NSArray *buttons = nil;
    if (_modifications > 0) {
        if (_contact.id != NOT_SAVED) {
            buttons = [NSArray arrayWithObjects:_deleteBtn, _confirmBtn, _cancelBtn, nil];
        } else {
            buttons = [NSArray arrayWithObjects:_confirmBtn, _cancelBtn, nil];
        }
    } else {
        if (_contact.id != NOT_SAVED) {
            buttons = [NSArray arrayWithObject:_deleteBtn];
        }
    }
    self.navigationItem.rightBarButtonItems = buttons;
}

- (void)reloadTable {
    QLabelElement *presentStatusEntry = (QLabelElement *)[[self root] elementWithKey:PRESENTSTATUS_ENTRY];
    QLabelElement *voiceEmailEntry = (QLabelElement *)[[self root] elementWithKey:VOICEEMAIL_ENTRY];
    QLabelElement *sipEntry = (QLabelElement *)[[self root] elementWithKey:SIP_ENTRY];
    QTextElement *groupsEntry = (QTextElement *)[[self root] elementWithKey:GROUPS_ENTRY];

    if (_contact.contactType == ContactType_Friend) {
        presentStatusEntry.value = [UcaConstants descriptionOfPresentation:_contact.presentation];
        presentStatusEntry.valueIcon = [UcaConstants iconOfPresentation:_contact.presentation];
        voiceEmailEntry.value = _contact.voicemail;
        sipEntry.value =  _contact.sipPhone;
        groupsEntry.text =  [_contact.groups componentsJoinedByString:@","];
    }

    if (_modifications > 0) {
        if (_contact.contactType == ContactType_Friend) {
            [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//            [self.quickDialogTableView reloadCellForElements:presentStatusEntry, voiceEmailEntry,
//                sipEntry, groupsEntry, nil];
        }
        return;
    }

    AvatarElement *avatarElement = (AvatarElement *)[[self root] elementWithKey:AVATAR_ENTRY];
    QEntryElement *firstnameEntry = (QEntryElement *)[[self root] elementWithKey:FIRSTNAME_ENTRY];
    QEntryElement *lastnameEntry = (QEntryElement *)[[self root] elementWithKey:LASTNAME_ENTRY];
    QEntryElement *nicknameEntry = (QEntryElement *)[[self root] elementWithKey:NICKNAME_ENTRY];
    QRadioElement *sexEntry = (QRadioElement *)[[self root] elementWithKey:SEX_ENTRY];
    QEntryElement *emailEntry = (QEntryElement *)[[self root] elementWithKey:EMAIL_ENTRY];
    QEntryElement *familyAddrEntry = (QEntryElement *)[[self root] elementWithKey:FAMILY_ADDR_ENTRY];
    QEntryElement *familyPhoneEntry = (QEntryElement *)[[self root] elementWithKey:FAMILY_PHONE_ENTRY];
    QEntryElement *companyEntry = (QEntryElement *)[[self root] elementWithKey:COMPANY_NAME_ENTRY];
    QEntryElement *companyAddrEntry = (QEntryElement *)[[self root] elementWithKey:COMPANY_ADDR_ENTRY];
    QEntryElement *departmentEntry = (QEntryElement *)[[self root] elementWithKey:COMPANY_DEPART_ENTRY];
    QEntryElement *positionEntry = (QEntryElement *)[[self root] elementWithKey:COMPANY_POSITION_ENTRY];
    QEntryElement *workPhoneEntry = (QEntryElement *)[[self root] elementWithKey:COMPANY_PHONE_ENTRY];
    QEntryElement *mobilePhoneEntry = (QEntryElement *)[[self root] elementWithKey:PHONE1_ENTRY];
    QEntryElement *mobilePhone2Entry = (QEntryElement *)[[self root] elementWithKey:PHONE2_ENTRY];
    QEntryElement *otherPhoneEntry = (QEntryElement *)[[self root] elementWithKey:OTHER_PHONE_ENTRY];
    QBooleanElement *showPersonalInfoEntry = (QBooleanElement *)[[self root] elementWithKey:SHOW_INFO_ENTRY];

    avatarElement.image = _contact.photo;
    avatarElement.text = _contact.descrip;
    showPersonalInfoEntry.boolValue =  _contact.showPersonalInfo;

    if ([self isEditable:_contact]) {
        sexEntry.selected =  _contact.isFemale;
        firstnameEntry.textValue =  _contact.firstname;
        lastnameEntry.textValue =  _contact.lastname;
        nicknameEntry.textValue =  _contact.nickname;
        emailEntry.textValue =  _contact.email;
        familyAddrEntry.textValue =  _contact.familyAddress;
        familyPhoneEntry.textValue =  _contact.familyPhone;
        companyEntry.textValue =  _contact.company;
        companyAddrEntry.textValue =  _contact.companyAddress;
        departmentEntry.textValue =  _contact.departName;
        positionEntry.textValue =  _contact.position;
        workPhoneEntry.textValue =  _contact.workPhone;
        mobilePhoneEntry.textValue =  _contact.mobilePhone;
        mobilePhone2Entry.textValue =  _contact.mobilePhone2;
        otherPhoneEntry.textValue =  _contact.otherPhone;
    } else {
        sexEntry.value = [UcaConstants descriptionOfGender:_contact.isFemale];
        firstnameEntry.value =  _contact.firstname;
        lastnameEntry.value =  _contact.lastname;
        nicknameEntry.value =  _contact.nickname;
        emailEntry.value =  _contact.email;
        familyAddrEntry.value =  _contact.familyAddress;
        familyPhoneEntry.value =  _contact.familyPhone;
        companyEntry.value =  _contact.company;
        companyAddrEntry.value =  _contact.companyAddress;
        departmentEntry.value =  _contact.departName;
        positionEntry.value =  _contact.position;
        workPhoneEntry.value =  _contact.workPhone;
        mobilePhoneEntry.value =  _contact.mobilePhone;
        mobilePhone2Entry.value =  _contact.mobilePhone2;
        otherPhoneEntry.value =  _contact.otherPhone;
    }

    [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];

/*
    if (_contact.contactType == ContactType_Friend) {
        [self.quickDialogTableView reloadCellForElements:presentStatusEntry, voiceEmailEntry,
         sipEntry, groupsEntry, avatarElement, firstnameEntry, lastnameEntry, nicknameEntry,
         sexEntry, emailEntry, familyAddrEntry, familyPhoneEntry, companyEntry, companyAddrEntry,
         departmentEntry, positionEntry, workPhoneEntry, mobilePhoneEntry, mobilePhone2Entry,
         otherPhoneEntry, showPersonalInfoEntry, nil];
    } else {
        [self.quickDialogTableView reloadCellForElements:avatarElement, firstnameEntry,
         lastnameEntry, nicknameEntry, sexEntry, emailEntry, familyAddrEntry, familyPhoneEntry,
         companyEntry, companyAddrEntry, departmentEntry, positionEntry, workPhoneEntry,
         mobilePhoneEntry, mobilePhone2Entry, otherPhoneEntry, showPersonalInfoEntry, nil];
    }
*/
}

- (IBAction)confirmModification:(id)button {
    AvatarElement *avatarElement = (AvatarElement *)[[self root] elementWithKey:AVATAR_ENTRY];
    _contact.photo = avatarElement.image;
    _contact.descrip = avatarElement.text;

    _contact.firstname = ((QEntryElement *)[[self root] elementWithKey:FIRSTNAME_ENTRY]).textValue;
    _contact.lastname = ((QEntryElement *)[[self root] elementWithKey:LASTNAME_ENTRY]).textValue;
    _contact.nickname = ((QEntryElement *)[[self root] elementWithKey:NICKNAME_ENTRY]).textValue;
    _contact.isFemale = (((QRadioElement *)[[self root] elementWithKey:SEX_ENTRY]).selected == 1);
    _contact.email = ((QEntryElement *)[[self root] elementWithKey:EMAIL_ENTRY]).textValue;
    _contact.familyAddress = ((QEntryElement *)[[self root] elementWithKey:FAMILY_ADDR_ENTRY]).textValue;
    _contact.familyPhone = ((QEntryElement *)[[self root] elementWithKey:FAMILY_PHONE_ENTRY]).textValue;
    _contact.company = ((QEntryElement *)[[self root] elementWithKey:COMPANY_NAME_ENTRY]).textValue;
    _contact.companyAddress = ((QEntryElement *)[[self root] elementWithKey:COMPANY_ADDR_ENTRY]).textValue;
    _contact.departName = ((QEntryElement *)[[self root] elementWithKey:COMPANY_DEPART_ENTRY]).textValue;
    _contact.position = ((QEntryElement *)[[self root] elementWithKey:COMPANY_POSITION_ENTRY]).textValue;
    _contact.workPhone = ((QEntryElement *)[[self root] elementWithKey:COMPANY_PHONE_ENTRY]).textValue;
    _contact.mobilePhone = ((QEntryElement *)[[self root] elementWithKey:PHONE1_ENTRY]).textValue;
    _contact.mobilePhone2 = ((QEntryElement *)[[self root] elementWithKey:PHONE2_ENTRY]).textValue;
    _contact.otherPhone = ((QEntryElement *)[[self root] elementWithKey:OTHER_PHONE_ENTRY]).textValue;
    _contact.showPersonalInfo = ((QBooleanElement *)[[self root] elementWithKey:SHOW_INFO_ENTRY]).boolValue;

    NSString *msg = nil;
    BOOL ok = NO;
    UcaContactService *service = [UcaAppDelegate sharedInstance].contactService;
    if (_contact.id == NOT_SAVED) {
        AddContactResult res = [service addPrivateContact:_contact];
        if (res == AddContact_Failure) {
            msg = [NSString stringWithFormat:I18nString(@"添加“%@”失败，请稍后重试。"), _contact.displayName];
            [NotifyUtils alert:msg];
        } else if (res == AddContact_Duplicate) {
            msg = [NSString stringWithFormat:I18nString(@"添加“%@”失败，好友已经存在。"), _contact.displayName];
            [NotifyUtils alert:msg];
        } else {
            ok = YES;
        }
    } else {
        if (_contact.contactType == ContactType_AddressBook) {
            ok = [service updateAddressBookContact:_contact];
        } else if (_contact.contactType == ContactType_Private) {
            ok = [service updatePrivateContact:_contact];
        }
        if (!ok) {
            msg = [NSString stringWithFormat:I18nString(@"更新“%@”失败，请稍后重试。"), _contact.displayName];
            [NotifyUtils alert:msg];
        }
    }

    if (ok) {
        _modifications = 0;
        [self reloadTitleBarButtons];
    }
}

- (IBAction)cancelModification:(id)button {
    _modifications = 0;
    [self reloadTitleBarButtons];
    [self reloadTable];
}

- (IBAction)confirmDeleteContact:(id)button {
    NSMutableString *msg = [[NSMutableString alloc] init];
    if (_contact.contactType == ContactType_AddressBook) {
        [msg appendString:I18nString(@"确定要从手机通讯簿中删除联系人“")];
    } else {
        [msg appendString:I18nString(@"确定要删除联系人“")];
    }
    if (![NSString isNullOrEmpty:_contact.displayName]) {
        [msg appendString:_contact.displayName];
    }
    [msg appendString:I18nString(@"”吗？")];
    [NotifyUtils confirm:msg delegate:self];
}

- (void)tryShowTopModifyButtons {
    _modifications++;
    [self reloadTitleBarButtons];
}

- (void)tryHideTopModifyButtons {
    _modifications--;
    [self reloadTitleBarButtons];
}

- (void)onContactEvent:(NSNotification *)notification {
    Contact *contact = notification.object;
    if (contact.userId != _contact.userId) {
        return;
    }

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self reloadTable];
    }
#else
    [self reloadTable];
#endif
}

- (void)onChangeSex:(QRadioElement *)element {
    if (element.selected != sInstance->_contact.isFemale) {
        [sInstance tryShowTopModifyButtons];
    } else {
        [sInstance tryHideTopModifyButtons];
    }
}

- (void)onShareInfoChanged:(QBooleanElement *)switcher {
    if (switcher.boolValue != _contact.showPersonalInfo) {
        [self tryShowTopModifyButtons];
    } else {
        [self tryHideTopModifyButtons];
    }
}

/**
 * 按以下格式创建表单章节：
 *
 * 头像 & 签名: photo, descrip
 * 登录: presentationDesp
 */
- (QSection *)createHeadSection:(Contact *)contact {
    QSection *section = [[QSection alloc] init];

    AvatarElement *avatarElement = [[AvatarElement alloc] initWithText:contact.descrip
                                                              andImage:contact.photo
                                                              editable:[self isEditable:contact]];
    avatarElement.key = AVATAR_ENTRY;
    avatarElement.delegate = self;
    [section addElement:avatarElement];

    if (contact.contactType == ContactType_Friend) {
        NSString *presentDescrip = [UcaConstants descriptionOfPresentation:contact.presentation];
        QLabelElement *presentStatusEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"在线状态") Value:presentDescrip];
        presentStatusEntry.valueIcon = [UcaConstants iconOfPresentation:contact.presentation];
        presentStatusEntry.key = PRESENTSTATUS_ENTRY;
        [section addElement:presentStatusEntry];
    }

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 姓名: firstname, lastname, nickname
 */
- (QSection *)createNameSection:(Contact *)contact {
    QSection *section = [[QSection alloc] init];

    QLabelElement *firstnameEntry = nil;
    QLabelElement *lastnameEntry  = nil;
    QLabelElement *nicknameEntry  = nil;

    if ([self isEditable:contact]) {
        firstnameEntry = [[QEntryElement alloc] initWithTitle:I18nString(@"姓") Value:contact.firstname Placeholder:nil];
        lastnameEntry  = [[QEntryElement alloc] initWithTitle:I18nString(@"名") Value:contact.lastname Placeholder:nil];
        nicknameEntry  = [[QEntryElement alloc] initWithTitle:I18nString(@"昵称") Value:contact.nickname Placeholder:nil];
        ((QEntryElement *)firstnameEntry).delegate = self;
        ((QEntryElement *)lastnameEntry).delegate  = self;
        ((QEntryElement *)nicknameEntry).delegate  = self;
    } else {
        firstnameEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"姓") Value:contact.firstname];
        lastnameEntry  = [[QLabelElement alloc] initWithTitle:I18nString(@"名") Value:contact.lastname];
        nicknameEntry  = [[QLabelElement alloc] initWithTitle:I18nString(@"昵称") Value:contact.nickname];
    }

    firstnameEntry.key = FIRSTNAME_ENTRY;
    lastnameEntry.key  = LASTNAME_ENTRY;
    nicknameEntry.key  = NICKNAME_ENTRY;

    [section addElement:firstnameEntry];
    [section addElement:lastnameEntry];
    [section addElement:nicknameEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 性别: isFemale
 */
- (QSection *)createSexSection:(Contact *)contact {
    QSection *section = [[QSection alloc] init];

    QLabelElement *sexEntry = nil;
    if ([self isEditable:contact]) {
        sexEntry = [[QRadioElement alloc] initWithItems:[UcaConstants descriptionOfGenders]
                                               selected:contact.isFemale
                                                  title:I18nString(@"性别")];

        sexEntry.controllerAction = @"onChangeSex:";
    } else {
        sexEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"性别")
                                                  Value:[UcaConstants descriptionOfGender:contact.isFemale]];
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
- (QSection *)createGroupSection:(Contact *)contact {
    QSection *section = [[QSection alloc] init];

    QTextElement *groupsEntry = [[QTextElement alloc] initWithText:[contact.groups componentsJoinedByString:@","]];
    groupsEntry.title = I18nString(@"所属的分组");
    groupsEntry.key = GROUPS_ENTRY;
    [section addElement:groupsEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 邮箱: email, voicemail
 */
- (QSection *)createMailSection:(Contact *)contact {
    QSection *section = [[QSection alloc] init];

    QLabelElement *emailEntry = nil;
    if ([self isEditable:contact]) {
        emailEntry  = [[QEntryElement alloc] initWithTitle:I18nString(@"邮箱地址") Value:contact.email Placeholder:nil];
        ((QEntryElement *)emailEntry).delegate = self;
    } else {
        emailEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"邮箱地址") Value:contact.email];
    }
    emailEntry.key = EMAIL_ENTRY;
    [section addElement:emailEntry];

    if (contact.contactType == ContactType_Friend) {
        QLabelElement *voiceEmailEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"语音邮箱") Value:contact.voicemail];
        voiceEmailEntry.key = VOICEEMAIL_ENTRY;
        [section addElement:voiceEmailEntry];
    }

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 家庭: familyAddress, familyPhone
 */
- (QSection *)createHomeSection:(Contact *)contact {
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"家庭")];

    QLabelElement *addrEntry  = nil;
    QLabelElement *phoneEntry = nil;

    if ([self isEditable:contact]) {
        addrEntry  = [[QEntryElement alloc] initWithTitle:I18nString(@"地址") Value:contact.familyAddress Placeholder:nil];
        phoneEntry = [[QEntryElement alloc] initWithTitle:I18nString(@"电话") Value:contact.familyPhone Placeholder:nil];
        ((QEntryElement *)addrEntry).delegate  = self;
        ((QEntryElement *)phoneEntry).delegate = self;
    } else {
        addrEntry  = [[QLabelElement alloc] initWithTitle:I18nString(@"地址") Value:contact.familyAddress];
        phoneEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"电话") Value:contact.familyPhone];
    }

    addrEntry.key  = FAMILY_ADDR_ENTRY;
    phoneEntry.key = FAMILY_PHONE_ENTRY;

    [section addElement:addrEntry];
    [section addElement:phoneEntry];

    return section;
}

/**
 * 按以下格式创建表单章节：
 *
 * 公司: company, companyAddress, department, position, workPhone
 */
- (QSection *)createCompanySection:(Contact *)contact {
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"公司")];

    QLabelElement *nameEntry     = nil;
    QLabelElement *addrEntry     = nil;
    QLabelElement *departEntry   = nil;
    QLabelElement *positionEntry = nil;
    QLabelElement *phoneEntry    = nil;

    if ([self isEditable:contact]) {
        nameEntry     = [[QEntryElement alloc] initWithTitle:I18nString(@"名称") Value:contact.company Placeholder:nil];
        addrEntry     = [[QEntryElement alloc] initWithTitle:I18nString(@"地址") Value:contact.companyAddress Placeholder:nil];
        departEntry   = [[QEntryElement alloc] initWithTitle:I18nString(@"部门") Value:contact.departName Placeholder:nil];
        positionEntry = [[QEntryElement alloc] initWithTitle:I18nString(@"职位") Value:contact.position Placeholder:nil];
        phoneEntry    = [[QEntryElement alloc] initWithTitle:I18nString(@"电话") Value:contact.workPhone Placeholder:nil];
        ((QEntryElement *)nameEntry).delegate     = self;
        ((QEntryElement *)addrEntry).delegate     = self;
        ((QEntryElement *)departEntry).delegate   = self;
        ((QEntryElement *)positionEntry).delegate = self;
        ((QEntryElement *)phoneEntry).delegate    = self;
    } else {
        nameEntry     = [[QLabelElement alloc] initWithTitle:I18nString(@"名称") Value:contact.company];
        addrEntry     = [[QLabelElement alloc] initWithTitle:I18nString(@"地址") Value:contact.companyAddress];
        departEntry   = [[QLabelElement alloc] initWithTitle:I18nString(@"部门") Value:contact.departName];
        positionEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"职位") Value:contact.position];
        phoneEntry    = [[QLabelElement alloc] initWithTitle:I18nString(@"电话") Value:contact.workPhone];
    }

    nameEntry.key     = COMPANY_NAME_ENTRY;
    addrEntry.key     = COMPANY_ADDR_ENTRY;
    departEntry.key   = COMPANY_DEPART_ENTRY;
    positionEntry.key = COMPANY_POSITION_ENTRY;
    phoneEntry.key    = COMPANY_PHONE_ENTRY;

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
- (QSection *)createPhoneSection:(Contact *)contact {
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"电话")];

    if (contact.contactType == ContactType_Friend
            || (contact.contactType == ContactType_Unknown && ![NSString isNullOrEmpty:contact.sipPhone])) {
        QLabelElement *sipEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"软终端号码") Value:contact.sipPhone];
        sipEntry.key = SIP_ENTRY;
        [section addElement:sipEntry];
    }

    QLabelElement *phone1Entry = nil;
    QLabelElement *phone2Entry = nil;
    QLabelElement *otherEntry  = nil;

    if ([self isEditable:contact]) {
        phone1Entry = [[QEntryElement alloc] initWithTitle:I18nString(@"联系电话一") Value:contact.mobilePhone Placeholder:nil];
        phone2Entry = [[QEntryElement alloc] initWithTitle:I18nString(@"联系电话二") Value:contact.mobilePhone2 Placeholder:nil];
        otherEntry  = [[QEntryElement alloc] initWithTitle:I18nString(@"其他号码") Value:contact.otherPhone Placeholder:nil];
        ((QEntryElement *)phone1Entry).delegate = self;
        ((QEntryElement *)phone2Entry).delegate = self;
        ((QEntryElement *)otherEntry).delegate  = self;
    } else {
        phone1Entry = [[QLabelElement alloc] initWithTitle:I18nString(@"联系电话一") Value:contact.mobilePhone];
        phone2Entry = [[QLabelElement alloc] initWithTitle:I18nString(@"联系电话二") Value:contact.mobilePhone2];
        otherEntry  = [[QLabelElement alloc] initWithTitle:I18nString(@"其他号码") Value:contact.otherPhone];
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
- (QSection *)createSettingSection:(Contact *)contact {
    QSection *section = [[QSection alloc] init];

    QBooleanElement *shareInfoEntry = [[QBooleanElement alloc] initWithTitle:I18nString(@"显示个人信息给其他人看") BoolValue:contact.showPersonalInfo];
    shareInfoEntry.onImage = [UIImage imageNamed:@"res/imgOn"];
    shareInfoEntry.offImage = [UIImage imageNamed:@"res/imgOff"];
    if ([self isEditable:contact]) {
        shareInfoEntry.enabled = YES;
        shareInfoEntry.controllerAccessoryAction = @"onShareInfoChanged:";
    } else {
        shareInfoEntry.enabled = NO;
    }
    shareInfoEntry.key = SHOW_INFO_ENTRY;
    [section addElement:shareInfoEntry];

    return section;
}

/**
 * 按以下格式创建UI：
 *
 * 头像 & 签名: photo, descrip
 * 登录: presentationDesp
 *
 * 姓名: firstname, lastname, nickname
 *
 * 性别: isFemale
 *
 * 群组: groups
 *
 * 邮箱: email, voicemail
 *
 * 家庭: familyAddress, familyPhone
 *
 * 公司: company, companyAddress, department, position, workPhone
 *
 * 其他电话: sipPhone, mobilePhone, mobilePhone2, otherPhone
 *
 * 配置: showPersonalInfo
 */
- (QRootElement *)createFormWithContact:(Contact *)contact {
    QRootElement *form = [[QRootElement alloc] init];
    form.grouped = YES;

    if (contact.id == NOT_SAVED) {
        form.title = I18nString(@"自己输入添加好友");
    } else {
        form.title = contact.displayName;
    }

    [form addSection:[self createHeadSection:contact]];
    [form addSection:[self createNameSection:contact]];
    [form addSection:[self createSexSection:contact]];
    if (contact.contactType == ContactType_Friend) {
        [form addSection:[self createGroupSection:contact]];
    }
    [form addSection:[self createMailSection:contact]];
    [form addSection:[self createHomeSection:contact]];
    [form addSection:[self createCompanySection:contact]];
    [form addSection:[self createPhoneSection:contact]];
    if (contact.contactType != ContactType_AddressBook
            && contact.contactType != ContactType_Unknown) {
        [form addSection:[self createSettingSection:contact]];
    }
    return form;
}

- (id)initWithContact:(Contact *)contact {
    if (!contact) {
        contact = [[Contact alloc] init];
        contact.contactType = ContactType_Private;
    }

    QRootElement *root = [self createFormWithContact:contact];
    self = [super initWithRoot:root];
    if (self) {
        _modifications = 0;
        _contact = contact;
        _confirmBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(confirmModification:)];
        _cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancelModification:)];
        _deleteBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                   target:self
                                                                   action:@selector(confirmDeleteContact:)];
        self.title = root.title;
        [self reloadTitleBarButtons];
    }
    if (!sInstance) {
        sInstance = self;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    _contact = nil;
}

- (void)onShutdownTabs {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _contact = nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Preserve selection between presentations.
    self.quickDialogTableView.backgroundColor = APP_BGCOLOR;
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.navigationController.navigationBarHidden = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onContactEvent:)
                                                 name:UCA_EVENT_UPDATE_CONTACT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onContactEvent:)
                                                 name:UCA_EVENT_UPDATE_CONTACTS
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onShutdownTabs)
                                                 name:UCA_EVENT_SHUTDOWN_TABS
                                               object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _contact = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadTable];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma UIAlertViewDelegate methods
/**
 * 确认删除联系人与否。
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // confirm delete
        if ([[UcaAppDelegate sharedInstance].contactService deleteContact:_contact]) {
          [NotifyUtils alert:I18nString(@"联系人删除成功")];
        } else {
          [NotifyUtils alert:I18nString(@"联系人删除失败")];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma QuickDialogEntryElementDelegate methods

- (void)QEntryDidEndEditingElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    BOOL changed = NO;

    if ([element.key isEqualToString:FIRSTNAME_ENTRY]) {
        changed = ![_contact.firstname isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:LASTNAME_ENTRY]) {
        changed = ![_contact.lastname isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:NICKNAME_ENTRY]) {
        changed = ![_contact.nickname isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:EMAIL_ENTRY]) {
        changed = ![_contact.email isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:FAMILY_ADDR_ENTRY]) {
        changed = ![_contact.familyAddress isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:FAMILY_PHONE_ENTRY]) {
        changed = ![_contact.familyPhone isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:COMPANY_NAME_ENTRY]) {
        changed = ![_contact.company isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:COMPANY_ADDR_ENTRY]) {
        changed = ![_contact.companyAddress isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:COMPANY_DEPART_ENTRY]) {
        changed = ![_contact.departName isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:COMPANY_POSITION_ENTRY]) {
        changed = ![_contact.position isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:COMPANY_PHONE_ENTRY]) {
        changed = ![_contact.workPhone isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:PHONE1_ENTRY]) {
        changed = ![_contact.mobilePhone isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:PHONE2_ENTRY]) {
        changed = ![_contact.mobilePhone2 isEqualToString:element.textValue];
    } else if ([element.key isEqualToString:OTHER_PHONE_ENTRY]) {
        changed = ![_contact.otherPhone isEqualToString:element.textValue];
    }

    if (changed) {
        [self tryShowTopModifyButtons];
    } else {
        [self tryHideTopModifyButtons];
    }
}

#pragma AvatarElementDelegate methods

- (void)AvatarDidEndEditingElement:(AvatarElement *)element andCell:(UITableViewCell *)cell {
    if ([element.text isEqualToString:_contact.descrip] && element.image == _contact.photo) {
        [self tryHideTopModifyButtons];
    } else {
        [self tryShowTopModifyButtons];
    }
}

@end
