/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <AddressBook/AddressBook.h>
#import "NotifyUtils.h"

#undef TAG
#define TAG @"UcaContactService"

#undef TABLE_NAME_CONTACT
#define TABLE_NAME_CONTACT @"Contact"

#undef TABLE_NAME_ACCOUNT_CONTACT
#define TABLE_NAME_ACCOUNT_CONTACT @"AccountContacts"

/**
 * 数据表Contact只记录普通联系人（好友、私有联系人等）信息，多人会话信息
 * 和地址簿联系人，类型信息用字段contactType区分。
 * 群组的信息记录在数据表Group里。系统消息和语音信箱没有数据库记录，只用
 * SYSTEM_MESSAGE_CONTACT_ID和VOICEMAIL_CONTACT_ID这两个特殊ID表示。
 * 最近联系人的信息通过最近联系记录来构建，不单独使用数据表。
 * 组织架构、群组和多人会话的联系人随时向服务器查询。
 */
/* 数据表Contact的字段 */
#define COLUMN_USER_ID              @"userId"
#define COLUMN_USERNAME             @"username"
#define COLUMN_FIRSTNAME            @"firstname"
#define COLUMN_LASTNAME             @"lastname"
#define COLUMN_NICKNAME             @"nickname"
#define COLUMN_ALIASES              @"aliases"
#define COLUMN_IS_FEMALE            @"isFemale"
#define COLUMN_DESCRIPTION          @"description"
#define COLUMN_PHOTO                @"photo"
#define COLUMN_PIN                  @"pin"
#define COLUMN_GROUP_ID             @"groupId"
#define COLUMN_GROUPS               @"groups"
#define COLUMN_CALL_MODE            @"callMode"
#define COLUMN_SIPPHONE             @"sipPhone"
#define COLUMN_WORKPHONE            @"workPhone"
#define COLUMN_FAMILYPHONE          @"familyPhone"
#define COLUMN_MOBILEPHONE          @"mobilePhone"
#define COLUMN_MOBILEPHONE2         @"mobilePhone2"
#define COLUMN_OTHERPHONE           @"otherPhone"
#define COLUMN_EMAIL                @"email"
#define COLUMN_VOICEMAIL            @"voicemail"
#define COLUMN_COMPANY              @"company"
#define COLUMN_COMPANY_ADDRESS      @"companyAddress"
#define COLUMN_DEPARTMENT_ID        @"departmentId"
#define COLUMN_DEPARTMENT           @"department"
#define COLUMN_POSITION             @"position"
#define COLUMN_FAMILY_ADDRESS       @"familyAddress"
#define COLUMN_SHOW_PERSONAL_INFO   @"showPersonalInfo"
#define COLUMN_PRESENTATION         @"presentation"
#define COLUMN_CAMERA_ON            @"cameraOn"
#define COLUMN_VOICEMAIL_ON         @"voicemailOn"

/**
 * 数据表AccountContacts的字段
 *
 * 当COLUMN_CONTACT_TYPE为ContactType_Group时，COLUMN_CONTACT_ID的值表示数据表Group中的记录ID；
 * 当COLUMN_CONTACT_TYPE为其他值时，COLUMN_CONTACT_ID的值表示数据表Contact中的记录ID。
 *
 * COLUMN_CONTACT_TYPE的取值为ContactType_AddressBook, ContactType_Friend, ContactType_Private,
 * ContactType_Group和ContactType_Session。
 */
#define COLUMN_ACCOUNT_ID           @"accountId"
#define COLUMN_CONTACT_ID           @"contactId"
#define COLUMN_CONTACT_TYPE         @"contactType"
#define COLUMN_LAST_ACCESSED        @"lastAccessed"

static void onAddressBookChanged(ABAddressBookRef _addressBook, CFDictionaryRef info, void *context) {
    [NotifyUtils postNotificationWithName:UCA_NATIVE_ADDRESSBOOK_CHANGED];
}

@implementation UcaContactService {
    ABAddressBookRef _addressBook; // 手机地址簿
    UcaDatabaseService *_dbService;
    NSMutableString *_querySql;
    BOOL _started;
}

- (id)init {
    if ((self = [super init])) {
        _addressBook = ABAddressBookCreate();
        _dbService = [UcaAppDelegate sharedInstance].databaseService;
        _started = NO;

        _querySql = [[NSMutableString alloc] init];
        [_querySql appendString:@"SELECT "];
        [_querySql appendFormat:@"%@.%@ AS %@, ", TABLE_NAME_CONTACT, COLUMN_ID, COLUMN_ID];
        [_querySql appendFormat:@"%@.%@ AS %@, ", TABLE_NAME_ACCOUNT_CONTACT, COLUMN_CONTACT_TYPE, COLUMN_CONTACT_TYPE];
        [_querySql appendFormat:@"%@, ", COLUMN_USER_ID];
        [_querySql appendFormat:@"%@, ", COLUMN_USERNAME];
        [_querySql appendFormat:@"%@, ", COLUMN_FIRSTNAME];
        [_querySql appendFormat:@"%@, ", COLUMN_LASTNAME];
        [_querySql appendFormat:@"%@, ", COLUMN_NICKNAME];
        [_querySql appendFormat:@"%@, ", COLUMN_ALIASES];
        [_querySql appendFormat:@"%@, ", COLUMN_IS_FEMALE];
        [_querySql appendFormat:@"%@, ", COLUMN_DESCRIPTION];
        [_querySql appendFormat:@"%@, ", COLUMN_PHOTO];
        [_querySql appendFormat:@"%@, ", COLUMN_PIN];
        [_querySql appendFormat:@"%@, ", COLUMN_GROUP_ID];
        [_querySql appendFormat:@"%@, ", COLUMN_GROUPS];
        [_querySql appendFormat:@"%@, ", COLUMN_CALL_MODE];
        [_querySql appendFormat:@"%@, ", COLUMN_SIPPHONE];
        [_querySql appendFormat:@"%@, ", COLUMN_WORKPHONE];
        [_querySql appendFormat:@"%@, ", COLUMN_FAMILYPHONE];
        [_querySql appendFormat:@"%@, ", COLUMN_MOBILEPHONE];
        [_querySql appendFormat:@"%@, ", COLUMN_MOBILEPHONE2];
        [_querySql appendFormat:@"%@, ", COLUMN_OTHERPHONE];
        [_querySql appendFormat:@"%@, ", COLUMN_EMAIL];
        [_querySql appendFormat:@"%@, ", COLUMN_VOICEMAIL];
        [_querySql appendFormat:@"%@, ", COLUMN_COMPANY];
        [_querySql appendFormat:@"%@, ", COLUMN_COMPANY_ADDRESS];
        [_querySql appendFormat:@"%@, ", COLUMN_DEPARTMENT_ID];
        [_querySql appendFormat:@"%@, ", COLUMN_DEPARTMENT];
        [_querySql appendFormat:@"%@, ", COLUMN_POSITION];
        [_querySql appendFormat:@"%@, ", COLUMN_FAMILY_ADDRESS];
        [_querySql appendFormat:@"%@, ", COLUMN_SHOW_PERSONAL_INFO];
        [_querySql appendFormat:@"%@, ", COLUMN_PRESENTATION];
        [_querySql appendFormat:@"%@, ", COLUMN_CAMERA_ON];
        [_querySql appendFormat:@"%@, ", COLUMN_VOICEMAIL_ON];
        [_querySql appendFormat:@"%@.%@ AS %@ ", TABLE_NAME_ACCOUNT_CONTACT, COLUMN_LAST_ACCESSED, COLUMN_LAST_ACCESSED];
        [_querySql appendFormat:@"FROM %@ LEFT JOIN %@ ", TABLE_NAME_CONTACT, TABLE_NAME_ACCOUNT_CONTACT];
        [_querySql appendFormat:@"WHERE %@.%@ = %@.%@", TABLE_NAME_CONTACT, COLUMN_ID, TABLE_NAME_ACCOUNT_CONTACT, COLUMN_CONTACT_ID];
        [_querySql appendFormat:@" AND %@.%@ NOT IN(%d, %d)", TABLE_NAME_ACCOUNT_CONTACT, COLUMN_CONTACT_TYPE, ContactType_Group, ContactType_Session];
    }
    return self;
}

- (void)bindContact:(Contact *)contact fromQueryResult:(FMResultSet *)rs {
    contact.id = [rs intForColumn:COLUMN_ID];
    contact.userId = [rs intForColumn:COLUMN_USER_ID];
    contact.username = [rs stringForColumn:COLUMN_USERNAME];
    contact.firstname = [rs stringForColumn:COLUMN_FIRSTNAME];
    contact.lastname = [rs stringForColumn:COLUMN_LASTNAME];
    contact.nickname = [rs stringForColumn:COLUMN_NICKNAME];
    contact.aliases = [[rs stringForColumn:COLUMN_ALIASES] componentsSeparatedByString:@","];
    contact.isFemale = [rs boolForColumn:COLUMN_IS_FEMALE];
    contact.descrip = [rs stringForColumn:COLUMN_DESCRIPTION];

    NSData *data = [rs dataForColumn:COLUMN_PHOTO];
    if (data != nil && data.length > 0) {
        contact.photo = [UIImage imageWithData:data];
    }

    contact.pin = [rs stringForColumn:COLUMN_PIN];
    contact.groupId = [rs intForColumn:COLUMN_GROUP_ID];
    contact.groups = [[rs stringForColumn:COLUMN_GROUPS] componentsSeparatedByString:@","];
    contact.callMode = [rs intForColumn:COLUMN_CALL_MODE];
    contact.sipPhone = [rs stringForColumn:COLUMN_SIPPHONE];
    contact.workPhone = [rs stringForColumn:COLUMN_WORKPHONE];
    contact.familyPhone = [rs stringForColumn:COLUMN_FAMILYPHONE];
    contact.mobilePhone = [rs stringForColumn:COLUMN_MOBILEPHONE];
    contact.mobilePhone2 = [rs stringForColumn:COLUMN_MOBILEPHONE2];
    contact.otherPhone = [rs stringForColumn:COLUMN_OTHERPHONE];
    contact.email = [rs stringForColumn:COLUMN_EMAIL];
    contact.voicemail = [rs stringForColumn:COLUMN_VOICEMAIL];
    contact.company = [rs stringForColumn:COLUMN_COMPANY];
    contact.companyAddress = [rs stringForColumn:COLUMN_COMPANY_ADDRESS];
    contact.departId = [rs intForColumn:COLUMN_DEPARTMENT_ID];
    contact.departName = [rs stringForColumn:COLUMN_DEPARTMENT];
    contact.position = [rs stringForColumn:COLUMN_POSITION];
    contact.familyAddress = [rs stringForColumn:COLUMN_FAMILY_ADDRESS];
    contact.showPersonalInfo = [rs boolForColumn:COLUMN_SHOW_PERSONAL_INFO];
    contact.presentation = [rs intForColumn:COLUMN_PRESENTATION];
    contact.cameraOn = [rs boolForColumn:COLUMN_CAMERA_ON];
    contact.voicemailOn = [rs boolForColumn:COLUMN_VOICEMAIL_ON];

    int idx = [rs columnIndexForName:COLUMN_CONTACT_TYPE];
    if (-1 != idx) {
        contact.contactType = [rs intForColumnIndex:idx];
    }

    idx = [rs columnIndexForName:COLUMN_LAST_ACCESSED];
    if (-1 != idx) {
        contact.accessed = [rs dateForColumnIndex:idx];
    }
}

/**
 * 在数据表Contact中添加记录。
 * @param contact 联系人实例
 * @param setStatus 是否设置COLUMN_PRESENTATION、COLUMN_CAMERA_ON和COLUMN_VOICEMAIL_ON这三栏
 * @return 记录添加成功，则返回YES；否则，返回NO。
 */
- (BOOL)doAddContact:(Contact *)contact setStatus:(BOOL)setStatus {
    ContactType type = contact.contactType;
    if (type != ContactType_AddressBook && type != ContactType_Session) {
        type = ContactType_Unknown;
    }

    NSMutableArray *cols = [NSMutableArray arrayWithObjects:COLUMN_CONTACT_TYPE,
            COLUMN_USER_ID,
            COLUMN_USERNAME, COLUMN_FIRSTNAME, COLUMN_LASTNAME, COLUMN_NICKNAME,
            COLUMN_ALIASES,
            COLUMN_IS_FEMALE,
            COLUMN_DESCRIPTION, COLUMN_PHOTO, COLUMN_PIN,
            COLUMN_GROUP_ID,
            COLUMN_GROUPS,
            COLUMN_CALL_MODE,
            COLUMN_SIPPHONE, COLUMN_WORKPHONE, COLUMN_FAMILYPHONE,
            COLUMN_MOBILEPHONE, COLUMN_MOBILEPHONE2, COLUMN_OTHERPHONE,
            COLUMN_EMAIL, COLUMN_VOICEMAIL,
            COLUMN_COMPANY, COLUMN_COMPANY_ADDRESS,
            COLUMN_DEPARTMENT_ID,
            COLUMN_DEPARTMENT, COLUMN_POSITION,
            COLUMN_FAMILY_ADDRESS,
            COLUMN_SHOW_PERSONAL_INFO, nil];
    NSMutableArray *vals = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:type],
            [NSNumber numberWithInt:contact.userId],
            contact.username, contact.firstname, contact.lastname, contact.nickname,
            [contact.aliases componentsJoinedByString:@","],
            [NSNumber numberWithBool:contact.isFemale],
            contact.descrip, [UIImage pngDataOfImg:contact.photo], contact.pin,
            [NSNumber numberWithInt:contact.groupId],
            [contact.groups componentsJoinedByString:@","],
            [NSNumber numberWithInt:contact.callMode],
            contact.sipPhone, contact.workPhone, contact.familyPhone,
            contact.mobilePhone, contact.mobilePhone2, contact.otherPhone,
            contact.email, contact.voicemail,
            contact.company, contact.companyAddress,
            [NSNumber numberWithInt:contact.departId],
            contact.departName, contact.position,
            contact.familyAddress,
            [NSNumber numberWithBool:contact.showPersonalInfo], nil];

    if (setStatus) {
        [cols addObject:COLUMN_PRESENTATION];
        [cols addObject:COLUMN_CAMERA_ON];
        [cols addObject:COLUMN_VOICEMAIL_ON];
        [vals addObject:[NSNumber numberWithInt:contact.presentation]];
        [vals addObject:[NSNumber numberWithBool:contact.cameraOn]];
        [vals addObject:[NSNumber numberWithBool:contact.voicemailOn]];
    }

    contact.id = [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_CONTACT];
    return contact.id != NOT_SAVED;
}

/**
 * 在数据表AccountContacts中添加记录。
 * @param contact 联系人实例
 * @param setLastAccessed 是否设置COLUMN_LAST_ACCESSED栏
 * @return 记录添加成功，则返回YES；否则，返回NO。
 */
- (BOOL)doAddAccountContact:(Contact *)contact setLastAccessed:(BOOL)setLastAccessed {
    if (contact.id == NOT_SAVED) {
        return NO;
    }
    if (contact.contactType == ContactType_Unknown && contact.accessed == nil && setLastAccessed) {
        return NO;
    }

    NSMutableArray *cols = [NSMutableArray arrayWithObjects:COLUMN_ACCOUNT_ID,
            COLUMN_CONTACT_ID,
            COLUMN_CONTACT_TYPE, nil];
    NSMutableArray *vals = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:contact.accountId],
            [NSNumber numberWithInt:contact.id],
            [NSNumber numberWithInt:contact.contactType], nil];

    if (setLastAccessed) {
        [cols addObject:COLUMN_LAST_ACCESSED];
        [vals addObject:contact.accessedDbVal];
    }

    return NOT_SAVED != [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_ACCOUNT_CONTACT];
}

/**
 * 更新数据表Contact中的记录。
 * @param contact 联系人实例
 * @param updateStatus 是否更新COLUMN_PRESENTATION、COLUMN_CAMERA_ON和COLUMN_VOICEMAIL_ON这三栏
 * @return 记录更新成功，则返回YES；否则，返回NO。
 */
- (BOOL)doUpdateContact:(Contact *)contact updateStatus:(BOOL)updateStatus {
    ContactType type = contact.contactType;
    if (type != ContactType_AddressBook && type != ContactType_Session) {
        type = ContactType_Unknown;
    }

    NSMutableArray *cols = [NSMutableArray arrayWithObjects:COLUMN_CONTACT_TYPE,
            COLUMN_USER_ID,
            COLUMN_USERNAME, COLUMN_FIRSTNAME, COLUMN_LASTNAME, COLUMN_NICKNAME,
            COLUMN_ALIASES,
            COLUMN_IS_FEMALE,
            COLUMN_DESCRIPTION, COLUMN_PHOTO, COLUMN_PIN,
            COLUMN_GROUP_ID,
            COLUMN_GROUPS,
            COLUMN_CALL_MODE,
            COLUMN_SIPPHONE, COLUMN_WORKPHONE, COLUMN_FAMILYPHONE,
            COLUMN_MOBILEPHONE, COLUMN_MOBILEPHONE2, COLUMN_OTHERPHONE,
            COLUMN_EMAIL, COLUMN_VOICEMAIL,
            COLUMN_COMPANY, COLUMN_COMPANY_ADDRESS,
            COLUMN_DEPARTMENT_ID,
            COLUMN_DEPARTMENT, COLUMN_POSITION,
            COLUMN_FAMILY_ADDRESS,
            COLUMN_SHOW_PERSONAL_INFO, nil];
    NSMutableArray *vals = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:type],
            [NSNumber numberWithInt:contact.userId],
            contact.username, contact.firstname, contact.lastname, contact.nickname,
            [contact.aliases componentsJoinedByString:@","],
            [NSNumber numberWithBool:contact.isFemale],
            contact.descrip, [UIImage pngDataOfImg:contact.photo], contact.pin,
            [NSNumber numberWithInt:contact.groupId],
            [contact.groups componentsJoinedByString:@","],
            [NSNumber numberWithInt:contact.callMode],
            contact.sipPhone, contact.workPhone, contact.familyPhone,
            contact.mobilePhone, contact.mobilePhone2, contact.otherPhone,
            contact.email, contact.voicemail,
            contact.company, contact.companyAddress,
            [NSNumber numberWithInt:contact.departId],
            contact.departName, contact.position,
            contact.familyAddress,
            [NSNumber numberWithBool:contact.showPersonalInfo], nil];

    if (updateStatus) {
        [cols addObject:COLUMN_PRESENTATION];
        [cols addObject:COLUMN_CAMERA_ON];
        [cols addObject:COLUMN_VOICEMAIL_ON];
        [vals addObject:[NSNumber numberWithInt:contact.presentation]];
        [vals addObject:[NSNumber numberWithBool:contact.cameraOn]];
        [vals addObject:[NSNumber numberWithBool:contact.voicemailOn]];
    }

    return [_dbService updateRecord:contact.id withColumns:cols andValues:vals inTable:TABLE_NAME_CONTACT];
}

/**
 * 同步当前帐号相关的联系人信息。
 * @return 同步成功（即有变动），则返回YES；否则返回NO。
 */
- (BOOL)synchServerContacts:(UCALIB_LOGIN_HANDLE)loginHandle {
    char *friendsXml = NULL, *privatesXml = NULL;
    NSMutableArray *serverContacts = [NSMutableArray array];
    UCALIB_ERRCODE res = ucaLib_GetFriends(loginHandle, &friendsXml, &privatesXml);
    UcaLog(TAG, @"ucaLib_GetFriends return %d, curLoginhandle=%d", res, loginHandle);
    if (res != UCALIB_ERR_OK) {
        UcaLibRelease(friendsXml);
        UcaLibRelease(privatesXml);
        return NO;
    }

    [serverContacts addObjectsFromArray:[XmlUtils fetchContactsFromXml:friendsXml forType:ContactType_Friend]];
    [serverContacts addObjectsFromArray:[XmlUtils fetchContactsFromXml:privatesXml forType:ContactType_Private]];
    UcaLibRelease(friendsXml);
    UcaLibRelease(privatesXml);

    NSInteger curAccountId = NOT_SAVED;
    NSMutableArray *mergedContactIds = [NSMutableArray array];
    for (Contact *contact in serverContacts) {
        curAccountId = contact.accountId;

        /**
         * 从服务器获取的联系人信息中，不管是好友还是私有联系人，userId都是唯一的，
         * 即userId是服务器上联系人的UID。因为数据表Contact中还有多人会话、地址簿联系人记录，
         * 所以要结合COLUMN_USER_ID和COLUMN_CONTACT_TYPE来唯一检索数据表Contact中的记录。
         */
        NSInteger contactId = [_dbService recordIdWhere:[NSArray arrayWithObjects:COLUMN_USER_ID, COLUMN_CONTACT_TYPE, nil]
                                                 equals:[NSArray arrayWithObjects:[NSNumber numberWithInt:contact.userId],
                                                         [NSNumber numberWithInt:ContactType_Unknown], nil]
                                                inTable:TABLE_NAME_CONTACT];
        if (contactId == NOT_SAVED) {
            if ([self doAddContact:contact setStatus:NO]) {
                contactId = contact.id;
                [self doAddAccountContact:contact setLastAccessed:NO];
            }
        } else {
            contact.id = contactId;
            if ([self doUpdateContact:contact updateStatus:NO]) {
                NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ? AND %@ != ?",
                                 COLUMN_ID, TABLE_NAME_ACCOUNT_CONTACT, COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID,
                                 COLUMN_CONTACT_TYPE];
                NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInt:contact.accountId],
                                 [NSNumber numberWithInt:contactId], [NSNumber numberWithInt:ContactType_Group], nil];
                FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
                NSInteger recId = NOT_SAVED;
                if ([rs next]) {
                    recId = [rs intForColumn:COLUMN_ID];
                }
                [rs close];
                [rs setParentDB:nil];

                if (recId == NOT_SAVED) {
                    [self doAddAccountContact:contact setLastAccessed:NO];
                } else {
                    [_dbService updateRecord:recId
                                 withColumns:[NSArray arrayWithObject:COLUMN_CONTACT_TYPE]
                                   andValues:[NSArray arrayWithObject:[NSNumber numberWithInteger:contact.contactType]]
                                     inTable:TABLE_NAME_ACCOUNT_CONTACT];
                }
            }
        }

        if (contactId != NOT_SAVED) {
            [mergedContactIds addObject:[NSNumber numberWithInt:contactId]];
        }
    }

    BOOL changed = NO;
    if ([mergedContactIds count] > 0) {
        changed = YES;

        /* 处理所有存在于数据表AccountContacts中、却不存在于服务器上的联系人。 */
        NSString *contactIdsExp = [_dbService commaDelimitedArguments:[mergedContactIds count]];

        // 若lastAccessed为0，则删除相关AccountContacts记录。
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ IN (?, ?) AND %@ NOT IN (%@) AND (%@ = ? OR %@ ISNULL)",
                         TABLE_NAME_ACCOUNT_CONTACT, COLUMN_ACCOUNT_ID, COLUMN_CONTACT_TYPE, COLUMN_CONTACT_ID,
                         contactIdsExp, COLUMN_LAST_ACCESSED, COLUMN_LAST_ACCESSED];

        NSMutableArray *args = [NSMutableArray array];
        [args addObject:[NSNumber numberWithInt:curAccountId]];
        [args addObject:[NSNumber numberWithInt:ContactType_Friend]];
        [args addObject:[NSNumber numberWithInt:ContactType_Private]];
        [args addObjectsFromArray:mergedContactIds];
        [args addObject:[NSNumber numberWithInt:0]];

        [_dbService executeUpdate:sql withArguments:args];

        // 若lastAccessed不为0，则将相关AccountContacts记录的栏COLUMN_CONTACT_TYPE更新为ContactType_Unknown。
        [args insertObject:[NSNumber numberWithInt:ContactType_Unknown] atIndex:0];
        [_dbService updateRecordsWithColumns:[NSArray arrayWithObject:COLUMN_CONTACT_TYPE]
                                       where:[NSString stringWithFormat:@"%@ = ? AND %@ IN (?, ?) AND %@ NOT IN (%@) AND %@ > ?",
                                              COLUMN_ACCOUNT_ID, COLUMN_CONTACT_TYPE, COLUMN_CONTACT_ID, contactIdsExp, COLUMN_LAST_ACCESSED]
                                andArguments:args
                                     inTable:TABLE_NAME_ACCOUNT_CONTACT];
    }

    return changed;
}

- (void)synchAddressBookContacts {
    /**
     * 从地址簿获取的联系人信息中，userId记录ABRecordGetRecordID()的返回值，是唯一的。
     * 因此，可以用它来唯一检索数据表Contact中的记录。
     */
    NSString *sql = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ WHERE %@ > 0 AND %@ IN (SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ?)",
                     COLUMN_ID, COLUMN_USER_ID, TABLE_NAME_CONTACT, COLUMN_USER_ID, COLUMN_ID, COLUMN_CONTACT_ID,
                     TABLE_NAME_ACCOUNT_CONTACT, COLUMN_ACCOUNT_ID, COLUMN_CONTACT_TYPE];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:[NSNumber numberWithInt:[UcaAppDelegate sharedInstance].accountService.curAccountId]];
    [args addObject:[NSNumber numberWithInt:ContactType_AddressBook]];

    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    NSMutableArray *contactIds = [NSMutableArray array];
    NSMutableArray *userIds = [NSMutableArray array];
    while ([rs next]) {
        [contactIds addObject:[NSNumber numberWithInt:[rs intForColumnIndex:0]]];
        [userIds addObject:[NSNumber numberWithInt:[rs intForColumnIndex:1]]];
    }
    [rs close];
    [rs setParentDB:nil];

    for (NSInteger i = 0; i < userIds.count; i++) {
        NSNumber *contactId = [contactIds objectAtIndex:i];
        NSNumber *userId = [userIds objectAtIndex:i];

        ABRecordRef person = ABAddressBookGetPersonWithRecordID(_addressBook, [userId intValue]);
        if (person) {
            Contact *contact = [[Contact alloc] init];
            contact.id = [contactId intValue];
            contact.contactType = ContactType_AddressBook;
            [contact copyDataFromABRecord:person];

            [self doUpdateContact:contact updateStatus:NO];
        }
    }

    if ([userIds count] > 0) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACTS];
    }
}

- (void)synchContacts {
    UcaAccountService *accountService = [UcaAppDelegate sharedInstance].accountService;
    if ([accountService isLoggedIn]) {
        [self synchServerContacts:accountService.curLoginHandle];
    }
    [self synchAddressBookContacts];
}

- (Contact *)touchContactBySipPhone:(NSString *)sipPhone {
    if ([NSString isNullOrEmpty:sipPhone] || [sipPhone hasPrefix:@"img-"]) {
        return nil;
    }

    UcaAccountService *accountService = [UcaAppDelegate sharedInstance].accountService;

    NSRange r = [sipPhone rangeOfString:@"@"];
    if (r.location == NSNotFound) {
        Account *curAccount = accountService.currentAccount;
        if (curAccount) {
            NSString *domainSuffix = [NSString stringWithFormat:@"@%@", curAccount.serverDomain];
            if (![sipPhone hasSuffix:domainSuffix]) {
                sipPhone = [sipPhone stringByAppendingString:domainSuffix];
            }
        }
    }

    ContactType type = [sipPhone hasPrefix:@"imc-"] ? ContactType_Session : ContactType_Unknown;
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? AND %@ = ?",
                     TABLE_NAME_CONTACT, COLUMN_SIPPHONE, COLUMN_CONTACT_TYPE];
    NSArray *args = [NSArray arrayWithObjects:sipPhone, [NSNumber numberWithInt:type], nil];
    Contact *contact = nil;
    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    if ([rs next]) {
        contact = [[Contact alloc] init];
        contact.contactType = type;
        [self bindContact:contact fromQueryResult:rs];
    }
    [rs close];
    [rs setParentDB:nil];

    // 若成功获取联系人信息，或没找到多人会话信息，直接返回。
    if (contact != nil || type == ContactType_Session) {
        return contact;
    }

    /* 数据表Contact中不存在联系人记录包含sipPhone */
    NSString *xml = [XmlUtils buildGetPersonsInfo:[NSArray arrayWithObject:sipPhone]];
    char *outXml = NULL;
    UCALIB_ERRCODE res = ucaLib_GetPersonInfo(accountService.curLoginHandle, [xml UTF8String], &outXml);
    if (res == UCALIB_ERR_OK) {
        NSArray *contacts = [XmlUtils fetchContactsFromXml:outXml forType:type];
        if (contacts.count > 0) {
            contact = [contacts objectAtIndex:0];
            if (![self doAddContact:contact setStatus:NO]) {
                contact = nil;
            }
        }
    }
    UcaLibRelease(outXml);

    return contact;
}

- (Contact *)touchContactBySipPhone:(NSString *)sipPhone withTimestamp:(NSDate *)date {
    Contact *contact = [self touchContactBySipPhone:sipPhone];
    if (contact != nil) {
        contact.accessed = date;
        [self updateAccessOfContact:contact];
    }

    return contact;
}

- (Contact *)touchContactByUserid:(NSInteger)userId atDomain:(NSString *)domain {
    if (userId == NOT_SAVED) {
        return nil;
    }

    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? AND %@ = ?",
                     TABLE_NAME_CONTACT, COLUMN_USER_ID, COLUMN_CONTACT_TYPE];
    NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInt:userId],
                     [NSNumber numberWithInt:ContactType_Unknown], nil];
    Contact *contact = nil;
    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    if ([rs next]) {
        contact = [[Contact alloc] init];
        contact.contactType = ContactType_Unknown;
        [self bindContact:contact fromQueryResult:rs];
    }
    [rs close];
    [rs setParentDB:nil];

    // 若成功获取联系人信息，或没有域信息（无法向服务器获取联系人信息），直接返回。
    if (contact != nil || [NSString isNullOrEmpty:domain]) {
        return contact;
    }

    /* 数据表Contact中不存在联系人记录包含sipPhone */
    NSString *sipPhone = [NSString stringWithFormat:@"%d@%@", userId, domain];
    NSString *xml = [XmlUtils buildGetPersonsInfo:[NSArray arrayWithObject:sipPhone]];
    char *outXml = NULL;
    UCALIB_ERRCODE res = ucaLib_GetPersonInfo([UcaAppDelegate sharedInstance].accountService.curLoginHandle, [xml UTF8String], &outXml);
    if (res == UCALIB_ERR_OK) {
        NSArray *contacts = [XmlUtils fetchContactsFromXml:outXml forType:ContactType_Unknown];
        if (contacts.count > 0) {
            contact = [contacts objectAtIndex:0];
            if (![self doAddContact:contact setStatus:NO]) {
                contact = nil;
            }
        }
    }
    UcaLibRelease(outXml);

    return contact;
}

- (BOOL)touchContact:(Contact *)contact {
    if (contact == nil || contact.userId == NOT_SAVED || contact.contactType == ContactType_Group) {
        return NO;
    }

    ContactType type = contact.contactType;
    if (type != ContactType_AddressBook && type != ContactType_Session) {
        type = ContactType_Unknown;
    }

    NSInteger recId = [_dbService recordIdWhere:[NSArray arrayWithObjects:COLUMN_USER_ID, COLUMN_CONTACT_TYPE, nil]
                                         equals:[NSArray arrayWithObjects:[NSNumber numberWithInt:contact.userId],
                                                 [NSNumber numberWithInt:type], nil]
                                        inTable:TABLE_NAME_CONTACT];
    if (recId == NOT_SAVED) {
        return [self doAddContact:contact setStatus:NO];
    }
    return [self doUpdateContact:contact updateStatus:NO];
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }

    NSArray *colInfos = [NSArray arrayWithObjects:
                         COLUMN_ID, @"INTEGER PRIMARY KEY AUTOINCREMENT",
                         COLUMN_CONTACT_TYPE, @"TINYINT(1)",
                         COLUMN_USER_ID, @"INTEGER",
                         COLUMN_USERNAME, @"TEXT",
                         COLUMN_FIRSTNAME, @"TEXT",
                         COLUMN_LASTNAME, @"TEXT",
                         COLUMN_NICKNAME, @"TEXT",
                         COLUMN_ALIASES, @"TEXT",
                         COLUMN_IS_FEMALE, @"TINYINT(1)",
                         COLUMN_DESCRIPTION, @"TEXT",
                         COLUMN_PHOTO, @"BLOB",
                         COLUMN_PIN, @"TEXT",
                         COLUMN_GROUP_ID, @"INTEGER",
                         COLUMN_GROUPS, @"TEXT",
                         COLUMN_CALL_MODE, @"TINYINT(1)",
                         COLUMN_SIPPHONE, @"TEXT",
                         COLUMN_WORKPHONE, @"TEXT",
                         COLUMN_FAMILYPHONE, @"TEXT",
                         COLUMN_MOBILEPHONE, @"TEXT",
                         COLUMN_MOBILEPHONE2, @"TEXT",
                         COLUMN_OTHERPHONE, @"TEXT",
                         COLUMN_EMAIL, @"TEXT",
                         COLUMN_VOICEMAIL, @"TEXT",
                         COLUMN_COMPANY, @"TEXT",
                         COLUMN_COMPANY_ADDRESS, @"TEXT",
                         COLUMN_DEPARTMENT_ID, @"INTEGER",
                         COLUMN_DEPARTMENT, @"TEXT",
                         COLUMN_POSITION, @"TEXT",
                         COLUMN_FAMILY_ADDRESS, @"TEXT",
                         COLUMN_SHOW_PERSONAL_INFO, @"TINYINT(1) DEFAULT 1",
                         COLUMN_PRESENTATION, @"TINYINT(1)",
                         COLUMN_CAMERA_ON, @"TINYINT(1)",
                         COLUMN_VOICEMAIL_ON, @"TINYINT(1)",
                         nil];
    if (![_dbService createTableIfNeeds:TABLE_NAME_CONTACT columnInfos:colInfos]) {
        UcaLog(TAG, @"Failed to create table %@", TABLE_NAME_CONTACT);
        return NO;
    }

    // 将所有联系人的在线状态置为离线，摄像头未激活
    [_dbService updateRecordsWithColumns:[NSArray arrayWithObjects:COLUMN_PRESENTATION, COLUMN_CAMERA_ON, nil]
                                   where:nil
                            andArguments:[NSArray arrayWithObjects:[NSNumber numberWithInt:UCALIB_PRESENTATIONSTATE_OFFLINE],
                                          [NSNumber numberWithBool:NO], nil]
                                 inTable:TABLE_NAME_CONTACT];

    colInfos = [NSArray arrayWithObjects:
                COLUMN_ID, @"INTEGER PRIMARY KEY AUTOINCREMENT",
                COLUMN_ACCOUNT_ID, @"INTEGER",
                COLUMN_CONTACT_ID, @"INTEGER",
                COLUMN_CONTACT_TYPE, @"TINYINT(1)",
                COLUMN_LAST_ACCESSED, @"INTEGER",
                nil];
    if (![_dbService createTableIfNeeds:TABLE_NAME_ACCOUNT_CONTACT columnInfos:colInfos]) {
        UcaLog(TAG, @"Failed to create table %@", TABLE_NAME_ACCOUNT_CONTACT);
        return NO;
    }

    ABAddressBookRegisterExternalChangeCallback(_addressBook, onAddressBookChanged, NULL);

    _started = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onContactPresentationChanged:)
                                                 name:UCA_NATIVE_CONTACT_PRESENTATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onContactsPresentationChanged:)
                                                 name:UCA_NATIVE_CONTACTS_PRESENTATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(synchAddressBookContacts)
                                                 name:UCA_NATIVE_ADDRESSBOOK_CHANGED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeleteAccount:)
                                                 name:UCA_EVENT_DELETE_ACCOUNT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLoginChanged:)
                                                 name:UCA_EVENT_UPDATE_LOGIN_STATUS
                                               object:nil];

    [self performSelectorInBackground:@selector(synchContacts) withObject:nil];
    return YES;
}

- (BOOL)stop {
    UcaLog(TAG, @"Stop()");
    if (![super stop]) {
        return NO;
    }

    _started = NO;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    ABAddressBookUnregisterExternalChangeCallback(_addressBook, onAddressBookChanged, NULL);
    ABAddressBookSave(_addressBook, NULL);

    return YES;
}

- (void)dealloc {
    [self stop];
    UcaCFRelease(_addressBook);
}

- (void)updatePresentationWhenLogin:(UcaContactPresentationEvent *)event{
    NSString *sipPhone = [event.uri strimmedSipPhone];
    Contact *contact = [self touchContactBySipPhone:sipPhone];
    if (contact != nil) {
        [_dbService updateRecord:contact.id
                     withColumns:[NSArray arrayWithObject:COLUMN_PRESENTATION]
                       andValues:[NSArray arrayWithObject:[NSNumber numberWithInt:event.state]]
                         inTable:TABLE_NAME_CONTACT];
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACT object:contact];
    }
}

- (void)onContactPresentationChanged:(NSNotification *)notification {
    UcaContactPresentationEvent *event = notification.object;
    NSString *sipPhone = [event.uri strimmedSipPhone];
    Contact *contact = [self touchContactBySipPhone:sipPhone];
    if (contact != nil) {
        [_dbService updateRecord:contact.id
                     withColumns:[NSArray arrayWithObject:COLUMN_PRESENTATION]
                       andValues:[NSArray arrayWithObject:[NSNumber numberWithInt:event.state]]
                         inTable:TABLE_NAME_CONTACT];
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACT object:contact];
    }
}

- (void)updatePresentationsWhenLogin:(NSString *)xmlMsg {
    NSMutableArray *notes = [XmlUtils parseMultiPresenceNotification:[xmlMsg UTF8String]];
    for (ContactPresence *note in notes) {
        Contact *contact = [self touchContactByUserid:note.userId atDomain:note.domain];
        if (contact != nil) {
            [_dbService updateRecord:contact.id
                         withColumns:[NSArray arrayWithObjects:COLUMN_PRESENTATION, COLUMN_CAMERA_ON, COLUMN_VOICEMAIL_ON, nil]
                           andValues:[NSArray arrayWithObjects:[NSNumber numberWithInt:note.state],
                                      [NSNumber numberWithBool:note.cameraOn],
                                      [NSNumber numberWithBool:note.mailboxOn], nil]
                             inTable:TABLE_NAME_CONTACT];
        }
    }

    [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACTS];

}

- (void)onContactsPresentationChanged:(NSNotification *)notification {
    NSString *xmlMsg = notification.object;
    [self updatePresentationsWhenLogin:xmlMsg];
}

- (void)onDeleteAccount:(NSNotification *)notification {
    NSNumber *accountId = notification.object;
    [_dbService deleteRecordsWhere:[NSArray arrayWithObject:COLUMN_ACCOUNT_ID]
                            equals:[NSArray arrayWithObject:accountId]
                         fromTable:TABLE_NAME_ACCOUNT_CONTACT];
}

- (void)onLoginChanged:(NSNotification *)notification {
    if (!_started) {
        return;
    }

    UcaAccountService *accountService = notification.object;
    if (![accountService isLoggedIn]) {
        return;
    }

    if ([self synchServerContacts:accountService.curLoginHandle]) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACTS];
    }
}

/**
 * 跟服务器通讯添加好友。
 * @param contact 好友信息。
 * @return 添加成功则返回AddContact_Success，失败则返回AddContact_Failure，重复添加
 * 返回AddContact_Duplicate。
 */
- (AddContactResult)addFriendViaServer:(Contact *)contact {
    char *outXml = NULL;
    NSString *xml = [XmlUtils buildManageFriendXml:[NSArray arrayWithObject:contact] manage:ManageType_Add];
    UCALIB_LOGIN_HANDLE handle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    UCALIB_ERRCODE res = ucaLib_ManageFriends(handle, [xml UTF8String], &outXml);
    BOOL isDuplicated = (outXml != NULL && (strlen(outXml) > 0));

    UcaLog(TAG, @"addFriendViaServer() res=%d outXml:%p '%s'", res, outXml, outXml);
    UcaLibRelease(outXml);

    if (res != UCALIB_ERR_OK) {
        return AddContact_Failure;
    }
    if (isDuplicated) {
        return AddContact_Duplicate;
    }
    return AddContact_Success;
}

- (AddContactResult)addFriendWithRecentContact:(Contact *)contact {
    if (!contact) {
        UcaLog(TAG, @"Cannot add null recent contact as friend");
        return AddContact_Failure;
    }

    UcaAccountService *accountService = [UcaAppDelegate sharedInstance].accountService;
    if (![accountService isLoggedIn]) {
        UcaLog(TAG, @"Cannot add friend via server");
        return AddContact_Failure;
    }

    NSInteger recId = [_dbService recordIdWhere:[NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, COLUMN_CONTACT_TYPE, nil]
                                         equals:[NSArray arrayWithObjects:[NSNumber numberWithInt:contact.accountId],
                                                 [NSNumber numberWithInt:contact.id],
                                                 [NSNumber numberWithInt:ContactType_Friend], nil]
                                        inTable:TABLE_NAME_ACCOUNT_CONTACT];
    if (recId != NOT_SAVED) {
        return AddContact_Duplicate;
    }

    AddContactResult res = [self addFriendViaServer:contact];
    if (res != AddContact_Success) {
        return res;
    }
    BOOL ok  = [_dbService updateRecordsWithColumns:[NSArray arrayWithObject:COLUMN_CONTACT_TYPE]
                                              where:[NSString stringWithFormat:@"%@ = ? AND %@ = ?", COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID]
                                       andArguments:[NSArray arrayWithObjects:[NSNumber numberWithInt:ContactType_Friend],
                                                     [NSNumber numberWithInt:contact.accountId],
                                                     [NSNumber numberWithInt:contact.id], nil]
                                            inTable:TABLE_NAME_ACCOUNT_CONTACT];

    if (ok) {
        ucaLib_Subscribe(accountService.curLoginHandle, NULL);
        [NotifyUtils postNotificationWithName:UCA_EVENT_ADD_CONTACT object:contact];
    }

    return ok ? AddContact_Success : AddContact_Failure;
}

- (AddContactResult)addFriendWithContact:(Contact *)contact {
    if (!contact) {
        UcaLog(TAG, @"Cannot add null contact");
        return AddContact_Failure;
    }

    UcaAccountService *accountService = [UcaAppDelegate sharedInstance].accountService;
    if ([contact.sipPhone isEqualToString:accountService.currentAccount.sipPhone]) {
        return AddContact_Account;
    }

    if (![accountService isLoggedIn]) {
        UcaLog(TAG, @"Cannot add private contact via server");
        return AddContact_Failure;
    }

    /* contact在数据表Contact中肯定有相应记录，以（curAccountId，contact.id，
     * 且contactType != ContactType_Group）在数据表AccountContacts中检索 */
    NSString *sql = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ WHERE %@ = ? AND %@ = ? AND %@ != ?",
                     COLUMN_ID, COLUMN_CONTACT_TYPE, TABLE_NAME_ACCOUNT_CONTACT,
                     COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, COLUMN_CONTACT_TYPE];
    NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInt:contact.accountId],
                     [NSNumber numberWithInt:contact.id],
                     [NSNumber numberWithInt:ContactType_Group], nil];

    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    NSInteger recId = NOT_SAVED;
    ContactType type = ContactType_Unknown;
    if ([rs next]) {
        recId = [rs intForColumnIndex:0];
        type = [rs intForColumnIndex:1];
    }
    [rs close];
    [rs setParentDB:nil];

    if (recId != NOT_SAVED && type == ContactType_Friend) {
        return AddContact_Duplicate;
    }

    // To here, resId == NOT_SAVED or (resId != NOT_SAVED && type != ContactType_Friend)
    // First, add friend via server
    AddContactResult res = [self addFriendViaServer:contact];
    if (res != AddContact_Success) {
        return res;
    }

    /* If successfully added via server, add corresponding record in table AccountContacts */
    BOOL ok = NO;
    if (recId == NOT_SAVED) {
        contact.contactType = ContactType_Friend;
        ok = [self doAddAccountContact:contact setLastAccessed:NO];
    } else {
        ok = [_dbService updateRecord:recId
                          withColumns:[NSArray arrayWithObject:COLUMN_CONTACT_TYPE]
                            andValues:[NSArray arrayWithObject:[NSNumber numberWithInt:ContactType_Friend]]
                              inTable:TABLE_NAME_ACCOUNT_CONTACT];
    }

    if (ok) {
        ucaLib_Subscribe(accountService.curLoginHandle, NULL);
        [NotifyUtils postNotificationWithName:UCA_EVENT_ADD_CONTACT object:contact];
    }

    return ok ? AddContact_Success : AddContact_Failure;
}

/**
 * 跟服务器通讯添加私有联系人。
 * @param contact 私有联系人信息。
 * @return 添加成功则返回YES，否则返回NO。
 */
- (BOOL)addPrivateContactViaServer:(Contact *)contact {
    char *outXml = NULL;
    NSString *xml = [XmlUtils buildAddOrUpdatePrivateXml:contact manage:ManageType_Add];
    UCALIB_LOGIN_HANDLE handle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    UCALIB_ERRCODE res = ucaLib_ManagePrivate(handle, [xml UTF8String], &outXml);

    if (res == UCALIB_ERR_OK) {
        NSArray *contacts = [XmlUtils fetchContactsFromXml:outXml forType:ContactType_Private];
        if (contacts.count > 0) {
            Contact *tmpContact = [contacts objectAtIndex:0];
            contact.userId = tmpContact.userId;
        }
    }

    UcaLog(TAG, @"addPrivateContactViaServer() res=%d outXml:%p '%s'", res, outXml, outXml);
    UcaLibRelease(outXml);

    return contact.userId != NOT_SAVED;
}

- (AddContactResult)addAddressBookContact:(Contact *)contact {
    if (!contact) {
        UcaLog(TAG, @"Cannot add null addressbook contact");
        return AddContact_Failure;
    }

    BOOL ok = NO;
    NSInteger contactId = [_dbService recordIdWhere:[NSArray arrayWithObjects:COLUMN_USER_ID, COLUMN_CONTACT_TYPE, nil]
                                             equals:[NSArray arrayWithObjects:[NSNumber numberWithInt:contact.userId],
                                                     [NSNumber numberWithInt:ContactType_AddressBook], nil]
                                            inTable:TABLE_NAME_CONTACT];
    if (contactId != NOT_SAVED) {
        contact.id = contactId;
        NSInteger recId = [_dbService recordIdWhere:[NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, nil]
                                             equals:[NSArray arrayWithObjects:[NSNumber numberWithInt:contact.accountId],
                                                     [NSNumber numberWithInt:contactId], nil]
                                            inTable:TABLE_NAME_ACCOUNT_CONTACT];
        if (recId != NOT_SAVED) {
            return AddContact_Duplicate;
        }

        // To here, recId == NOT_SAVED
        ok = [self doAddAccountContact:contact setLastAccessed:NO];
    } else {
        ok = [self doAddContact:contact setStatus:NO];
        if (ok) {
            ok = [self doAddAccountContact:contact setLastAccessed:NO];
        }
    }

    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_ADD_CONTACT object:contact];
    }
    return ok ? AddContact_Success : AddContact_Failure;
}

- (AddContactResult)addPrivateContact:(Contact *)contact {
    if (!contact) {
        UcaLog(TAG, @"Cannot add null private contact");
        return AddContact_Failure;
    }

    UcaAccountService *accountService = [UcaAppDelegate sharedInstance].accountService;
    if ([contact.sipPhone isEqualToString:accountService.currentAccount.sipPhone]) {
        return AddContact_Account;
    }

    if (![accountService isLoggedIn]) {
        UcaLog(TAG, @"Cannot add private contact via server");
        return AddContact_Failure;
    }

    BOOL ok = [self addPrivateContactViaServer:contact];
    if (ok) {
        ok = [self doAddContact:contact setStatus:NO];
        if (ok) {
            ok = [self doAddAccountContact:contact setLastAccessed:NO];
        }
    }

    if (ok) {
        ucaLib_Subscribe(accountService.curLoginHandle, NULL);
        [NotifyUtils postNotificationWithName:UCA_EVENT_ADD_CONTACT object:contact];
    }

    return ok ? AddContact_Success : AddContact_Failure;
}

- (AddContactResult)addRelationWithGroup:(Group *)group {
    UcaAccountService *accountService = [UcaAppDelegate sharedInstance].accountService;
    NSArray *cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, COLUMN_CONTACT_TYPE, nil];
    NSArray *vals = [NSArray arrayWithObjects:[NSNumber numberWithInt:accountService.curAccountId],
                     [NSNumber numberWithInt:group.id], [NSNumber numberWithInt:ContactType_Group], nil];

    NSInteger recId = [_dbService recordIdWhere:cols equals:vals inTable:TABLE_NAME_ACCOUNT_CONTACT];
    if (recId != NOT_SAVED) {
        return AddContact_Duplicate;
    }
    recId = [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_ACCOUNT_CONTACT];
    return (recId != NOT_SAVED) ? AddContact_Success : AddContact_Failure;
}

- (BOOL)updateAccessOfContact:(Contact *)contact {
    if (!contact || contact.id == NOT_SAVED) {
        UcaLog(TAG, @"Cannot update access of null, not-saved or group contact");
        return NO;
    }

    // try identify contact type
    if (contact.contactType == ContactType_Unknown && ![NSString isNullOrEmpty:contact.sipPhone]) {
        if ([contact.sipPhone hasPrefix:@"img-"]) {
            contact.contactType = ContactType_Group;
        } else if ([contact.sipPhone hasPrefix:@"imc-"]) {
            contact.contactType = ContactType_Session;
        } else {
            NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ? AND %@ NOT IN (?, ?)",
                             COLUMN_CONTACT_TYPE, TABLE_NAME_ACCOUNT_CONTACT, COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID,
                             COLUMN_CONTACT_TYPE];
            NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInt:contact.accountId],
                             [NSNumber numberWithInt:contact.id], [NSNumber numberWithInt:ContactType_Group],
                             [NSNumber numberWithInt:ContactType_Session], nil];
            FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
            if ([rs next]) {
                contact.contactType = [rs intForColumn:COLUMN_CONTACT_TYPE];
            }
            [rs close];
            [rs setParentDB:nil];
        }
    }

    NSInteger recId = [_dbService recordIdWhere:[NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, COLUMN_CONTACT_TYPE, nil]
                                         equals:[NSArray arrayWithObjects:[NSNumber numberWithInt:contact.accountId],
                                                 [NSNumber numberWithInt:contact.id], [NSNumber numberWithInt:contact.contactType], nil]
                                        inTable:TABLE_NAME_ACCOUNT_CONTACT];
    BOOL ok = NO;
    if (recId == NOT_SAVED) {
        ok = [self doAddAccountContact:contact setLastAccessed:YES];
    } else {
        ok = [_dbService updateRecord:recId
                          withColumns:[NSArray arrayWithObject:COLUMN_LAST_ACCESSED]
                            andValues:[NSArray arrayWithObject:contact.accessedDbVal]
                              inTable:TABLE_NAME_ACCOUNT_CONTACT];
    }

    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACT object:contact];
    }
    return ok;
}

- (BOOL)updateAddressBookContact:(Contact *)contact {
    if (!contact || contact.id == NOT_SAVED || contact.contactType != ContactType_AddressBook) {
        UcaLog(TAG, @"Cannot update invalid contact");
        return NO;
    }

    ABRecordRef person = ABAddressBookGetPersonWithRecordID(_addressBook, contact.userId);
    [contact copyDataToABRecord:person];
    if (!ABAddressBookSave(_addressBook, NULL)) {
        UcaLog(TAG, @"Failed to save contact info into address book.");
        return NO;
    }

    BOOL ok = [self doUpdateContact:contact updateStatus:NO];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACT object:contact];
    }
    return ok;
}

- (BOOL)updatePrivateContact:(Contact *)contact {
    if (!contact || contact.id == NOT_SAVED || contact.contactType != ContactType_Private) {
        UcaLog(TAG, @"Cannot update invalid contact");
        return NO;
    }

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    if ([app.accountService isLoggedIn]) {
        char *outXml = NULL;
        NSString *xml = [XmlUtils buildAddOrUpdatePrivateXml:contact manage:ManageType_Update];
        UCALIB_ERRCODE res = ucaLib_ManagePrivate(app.accountService.curLoginHandle,
                                                  [xml UTF8String], &outXml);
        UcaLibRelease(outXml);
        if (res != UCALIB_ERR_OK) {
            UcaLog(TAG, @"Failed to upload contact info");
            return NO;
        }
    }

    BOOL ok = [self doUpdateContact:contact updateStatus:NO];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACT object:contact];
    }
    return ok;
}

- (BOOL)updateContact:(NSInteger)userId
         presentation:(UCALIB_PRESENTATIONSTATE)presentation
             cameraOn:(BOOL)cameraOn {
    BOOL ok = [_dbService updateRecordsWithColumns:[NSArray arrayWithObjects:COLUMN_PRESENTATION, COLUMN_CAMERA_ON, nil]
                           where:[NSString stringWithFormat:@"%@ = ?", COLUMN_USER_ID]
                    andArguments:[NSArray arrayWithObjects:[NSNumber numberWithInt:presentation],
                                  [NSNumber numberWithInt:cameraOn], [NSNumber numberWithInt:userId], nil]
                         inTable:TABLE_NAME_CONTACT];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACTS];
    }
    return ok;
}

- (BOOL)deleteContact:(Contact *)contact {
    return [self deleteContacts:[NSArray arrayWithObject:contact]];
}

- (BOOL)deleteContacts:(NSArray *)contacts {
    if ([contacts count] == 0) {
        UcaLog(TAG, @"no contact to delete");
        return NO;
    }

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    if ([app.accountService isLoggedIn]) {
        UcaAccountService *accountService = app.accountService;
        UCALIB_ERRCODE res = UCALIB_ERR_OK;
        NSString *xml;
        char *outXml = NULL;
        NSMutableArray *friends = [NSMutableArray array];
        NSMutableArray *privates = [NSMutableArray array];

        for (Contact *contact in contacts) {
            if (contact.contactType == ContactType_Friend) {
                [friends addObject:contact];
            } else if (contact.contactType == ContactType_Private) {
                [privates addObject:contact];
            }
        }

        if ([friends count] > 0) {
            xml = [XmlUtils buildManageFriendXml:friends manage:ManageType_Delete];
            res = ucaLib_ManageFriends(accountService.curLoginHandle, [xml UTF8String], &outXml);
            UcaLibRelease(outXml);
            if (res != UCALIB_ERR_OK) {
                UcaLog(TAG, @"Failed to delete friends from server");
                return NO;
            }
        }

        if ([privates count] > 0) {
            xml = [XmlUtils buildDeletePrivateXml:privates];
            res = ucaLib_ManagePrivate(accountService.curLoginHandle, [xml UTF8String], &outXml);
            UcaLibRelease(outXml);
            if (res != UCALIB_ERR_OK) {
                UcaLog(TAG, @"Failed to delete private contacts from server");
                return NO;
            }
        }
    }

    // 对于要删除的联系人，不管是哪种类(ContactType_AddressBook, ContactType_Friend,
    // ContactType_Private)，都只是把AccountContacts表中的关系清除掉。

    NSMutableArray *contactIds = [NSMutableArray array];
    for (Contact *contact in contacts) {
        [contactIds addObject:[NSString stringWithFormat:@"%d", contact.id]];
    }
    NSString *contactIdsStr = [contactIds componentsJoinedByString:@","];

    // 1. 如果没有最近访问时间，则删除AccountContacts表中相应记录。
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ IN (NULL, ?) AND %@ IN (%@)",
                     TABLE_NAME_ACCOUNT_CONTACT, COLUMN_ACCOUNT_ID, COLUMN_LAST_ACCESSED, COLUMN_CONTACT_ID, contactIdsStr];
    NSArray *args = [NSArray arrayWithObjects:
                     [NSNumber numberWithInt:app.accountService.curAccountId],
                     [NSNumber numberWithInt:0], nil];
    BOOL delOk = [_dbService executeUpdate:sql withArguments:args];

    // 2. 如果有最近访问时间，则将AccountContacts表中contactType栏设为ContactType_Unknown
    NSArray *cols = [NSArray arrayWithObject:COLUMN_CONTACT_TYPE];
    NSString *whereClause = [NSString stringWithFormat:@"%@ = ? AND %@ NOT IN (NULL, ?) AND %@ IN (%@)",
                            COLUMN_ACCOUNT_ID, COLUMN_LAST_ACCESSED, COLUMN_CONTACT_ID, contactIdsStr];
    args = [NSArray arrayWithObjects:
            [NSNumber numberWithInt:ContactType_Unknown], // COLUMN_CONTACT_TYPE -> ContactType_Unknown
            [NSNumber numberWithInt:app.accountService.curAccountId],
            [NSNumber numberWithInt:0], nil];
    BOOL updateOk = [_dbService updateRecordsWithColumns:cols
                                                   where:whereClause
                                            andArguments:args
                                                 inTable:TABLE_NAME_ACCOUNT_CONTACT];

    // 返回结果
    if (delOk || updateOk) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_CONTACTS];
    }
    return delOk && updateOk;
}

- (NSArray *)getContactsWithCondition:(NSString *)wClause
                         andArguments:(NSArray *)args
                                order:(NSString *)oClause {
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendString:_querySql];

    if (![NSString isNullOrEmpty:wClause]) {
        [sql appendFormat:@" AND (%@)", wClause];
    }
    if (![NSString isNullOrEmpty:oClause]) {
        [sql appendFormat:@" ORDER BY %@", oClause];
    }

    NSMutableArray *contacts = [NSMutableArray array];
    Contact *contact = nil;
    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    while ([rs next]) {
        contact = [[Contact alloc] init];
        [self bindContact:contact fromQueryResult:rs];
        [contacts addObject:contact];
    }
    [rs close];
    [rs setParentDB:nil];
    return contacts;
}

- (NSArray *)getContactsByPhoneNumber:(NSString *)number
                   onlySearchSipPhone:(BOOL)onlySearchSipPhone
                            fullMatch:(BOOL)fullMatch {
    NSString *condPat = [NSString stringWithFormat:@" = '%@'", number];
    if (!fullMatch) {
        condPat = [NSString stringWithFormat:@" LIKE '%%%@%%'", number];
    }

    NSMutableString *clause = [[NSMutableString alloc] init];
    [clause appendFormat:@"%@%@", COLUMN_SIPPHONE, condPat];
    if (!onlySearchSipPhone) {
        [clause appendFormat:@" OR %@%@", COLUMN_WORKPHONE, condPat];
        [clause appendFormat:@" OR %@%@", COLUMN_FAMILYPHONE, condPat];
        [clause appendFormat:@" OR %@%@", COLUMN_MOBILEPHONE, condPat];
        [clause appendFormat:@" OR %@%@", COLUMN_MOBILEPHONE2, condPat];
        [clause appendFormat:@" OR %@%@", COLUMN_OTHERPHONE, condPat];
    }

    return [self getContactsWithCondition:clause andArguments:nil order:nil];
}

- (NSArray *)getContactsByPhoneNumber:(NSString *)number {
    return [self getContactsByPhoneNumber:number onlySearchSipPhone:NO fullMatch:NO];
}

- (Contact *)getContactBySipPhone:(NSString *)addr {
    NSArray *contacts = [self getContactsByPhoneNumber:addr onlySearchSipPhone:YES fullMatch:YES];
    if ([contacts count] > 0) {
        return [contacts objectAtIndex:0];
    }
    return nil;
}

- (NSArray *)getNormalContacts {
    NSString *clause = [NSString stringWithFormat:@"%@.%@ IN (%d, %d, %d)",
                        TABLE_NAME_ACCOUNT_CONTACT, COLUMN_CONTACT_TYPE,
                        ContactType_AddressBook, ContactType_Friend, ContactType_Private];
    return [self getContactsWithCondition:clause andArguments:nil order:nil];
}

- (NSArray *)getFriends {
    NSString *clause = [NSString stringWithFormat:@"%@.%@ = %d",
                        TABLE_NAME_ACCOUNT_CONTACT, COLUMN_CONTACT_TYPE, ContactType_Friend];
    return [self getContactsWithCondition:clause andArguments:nil order:nil];
}

- (NSArray *)getRecentContacts {
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
    NSString *where = [NSString stringWithFormat:@"%@ > ?", COLUMN_LAST_ACCESSED];
    NSString *order = [NSString stringWithFormat:@"%@ DESC", COLUMN_LAST_ACCESSED];

    return [self getContactsWithCondition:where
                             andArguments:[NSArray arrayWithObject:refDate]
                                    order:order];
}

- (NSArray *)getRecentFriends {
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
    NSNumber *refType = [NSNumber numberWithInteger:ContactType_Friend];
    NSString *where = [NSString stringWithFormat:@"%@ > ? AND %@.%@ = ?", COLUMN_LAST_ACCESSED,
                       TABLE_NAME_ACCOUNT_CONTACT, COLUMN_CONTACT_TYPE];
    NSString *order = [NSString stringWithFormat:@"%@ DESC", COLUMN_LAST_ACCESSED];

    return [self getContactsWithCondition:where
                             andArguments:[NSArray arrayWithObjects:refDate, refType, nil]
                                    order:order];
}

- (Contact *)getContactById:(NSInteger)contactId {
    NSString *where = [NSString stringWithFormat:@"%@.%@ = ?", TABLE_NAME_CONTACT, COLUMN_ID];
    NSNumber *refId = [NSNumber numberWithInteger:contactId];
    NSArray *contacts = [self getContactsWithCondition:where
                                          andArguments:[NSArray arrayWithObject:refId]
                                                 order:nil];
    if ([contacts count] > 0) {
        return [contacts objectAtIndex:0];
    }
    return nil;
}

@end
