/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"UcaGroupService"

#undef TABLE_NAME_CONTACT
#define TABLE_NAME_CONTACT @"Contact"

#undef TABLE_NAME_GROUP
#define TABLE_NAME_GROUP @"UGroup"

#undef TABLE_NAME_GROUP_CONTACT
#define TABLE_NAME_GROUP_CONTACT @"GroupContacts"

#undef TABLE_NAME_ACCOUNT_CONTACT
#define TABLE_NAME_ACCOUNT_CONTACT @"AccountContacts"

/* 数据表UGroup的字段 */
#define COLUMN_USER_ID         @"userId"          // 服务器上的群组ID
#define COLUMN_NAME            @"name"
#define COLUMN_SIPPHONE        @"sipPhone"
#define COLUMN_FILE_SPACE_SIZE @"fileSpaceSize"
#define COLUMN_CREATOR         @"creator"
#define COLUMN_CREATE_TIME     @"createTime"
#define COLUMN_ADMINS          @"administrators"
#define COLUMN_USER_COUNT      @"userCount"
#define COLUMN_USER_MAX_AMOUNT @"userMaxAmount"
#define COLUMN_TYPE            @"type"
#define COLUMN_PHOTO           @"photo"
#define COLUMN_ANNUNCIATE      @"annunciate"
#define COLUMN_DESCRIP         @"descrip"
#define COLUMN_CAN_ADMIN       @"canAdmin"
#define COLUMN_CAN_UPLOAD      @"canUpload"

/* 数据表GroupContacts的字段 */
#define COLUMN_GROUP_ID        @"groupId"
#define COLUMN_CONTACT_ID      @"contactId"

/* 数据表AccountContacts的字段 */
#define COLUMN_ACCOUNT_ID      @"accountId"
#define COLUMN_CONTACT_TYPE    @"contactType"
#define COLUMN_LAST_ACCESSED   @"lastAccessed"

#define KEY_GROUP       @"KEY_GROUP"
#define KEY_ANNUNCIATE  @"KEY_ANNUNCIATE"
#define KEY_XML         @"KEY_XML"

@implementation UcaGroupService {
    NSArray *_opContacts;
    Group *_opGroup;
    UcaDatabaseService *_dbService;
    BOOL _started;
}

@synthesize groups;
@synthesize fetchedData;

- (id)init {
    self = [super init];
    if (self) {
        fetchedData = NO;
        _dbService = [UcaAppDelegate sharedInstance].databaseService;
    }

    return self;
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }

    NSArray *colInfos = [NSArray arrayWithObjects:
                         COLUMN_ID, @"INTEGER PRIMARY KEY AUTOINCREMENT",
                         COLUMN_USER_ID, @"INTEGER",
                         COLUMN_NAME, @"TEXT",
                         COLUMN_SIPPHONE, @"TEXT",
                         COLUMN_FILE_SPACE_SIZE, @"INTEGER",
                         COLUMN_CREATOR, @"TEXT",
                         COLUMN_CREATE_TIME, @"TEXT",
                         COLUMN_ADMINS, @"TEXT",
                         COLUMN_USER_COUNT, @"INTEGER",
                         COLUMN_USER_MAX_AMOUNT, @"INTEGER",
                         COLUMN_TYPE, @"TEXT",
                         COLUMN_PHOTO, @"BLOB",
                         COLUMN_ANNUNCIATE, @"TEXT",
                         COLUMN_DESCRIP, @"TEXT",
                         COLUMN_CAN_ADMIN, @"TINYINT(1)",
                         COLUMN_CAN_UPLOAD, @"TINYINT(1)",
                         nil];
    if (![_dbService createTableIfNeeds:TABLE_NAME_GROUP columnInfos:colInfos]) {
        UcaLog(TAG, @"Failed to create table %@", TABLE_NAME_GROUP);
        return NO;
    }

    // 将所有群组设置为不可管理，不可上传
    [_dbService updateRecordsWithColumns:[NSArray arrayWithObjects:COLUMN_CAN_ADMIN, COLUMN_CAN_UPLOAD, nil]
                                   where:nil
                            andArguments:[NSArray arrayWithObjects:[NSNumber numberWithBool:NO],
                                          [NSNumber numberWithBool:NO], nil]
                                 inTable:TABLE_NAME_GROUP];

    colInfos = [NSArray arrayWithObjects:
                COLUMN_ID, @"INTEGER PRIMARY KEY AUTOINCREMENT",
                COLUMN_GROUP_ID, @"INTEGER",
                COLUMN_CONTACT_ID, @"INTEGER",
                nil];
    if (![_dbService createTableIfNeeds:TABLE_NAME_GROUP_CONTACT columnInfos:colInfos]) {
        UcaLog(TAG, @"Failed to create table %@", TABLE_NAME_GROUP_CONTACT);
        return NO;
    }

    _started = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchGroupInfos:)
                                                 name:UCA_REQUEST_FETCH_GROUP_INFO
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMemeberChanged:)
                                                 name:UCA_NATIVE_GROUP_MEMBER_CHANGED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMemeberPresentation:)
                                                 name:UCA_NATIVE_GROUP_PRESENTATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLoginChanged:)
                                                 name:UCA_EVENT_UPDATE_LOGIN_STATUS
                                               object:nil];
    [self performSelectorInBackground:@selector(synchGroups:) withObject:[NSNumber numberWithBool:NO]];
    return YES;
}

- (BOOL)stop {
    UcaLog(TAG, @"Stop()");
    if (![super stop]) {
        return NO;
    }
    _started = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    return YES;
}

/**
 * 在数据表UGroup中添加记录。
 * @param group 群组实例
 * @return 记录添加成功，则返回YES；否则，返回NO。
 */
- (BOOL)doAddGroup:(Group *)group {
    NSArray *cols = [NSArray arrayWithObjects:COLUMN_USER_ID,
            COLUMN_NAME,
            COLUMN_SIPPHONE,
            COLUMN_FILE_SPACE_SIZE,
            COLUMN_CREATOR,
            COLUMN_CREATE_TIME,
            COLUMN_ADMINS,
            COLUMN_USER_COUNT,
            COLUMN_USER_MAX_AMOUNT,
            COLUMN_TYPE,
            COLUMN_PHOTO,
            COLUMN_ANNUNCIATE,
            COLUMN_DESCRIP,
            COLUMN_CAN_ADMIN,
            COLUMN_CAN_UPLOAD, nil];
    NSArray *vals = [NSArray arrayWithObjects:[NSNumber numberWithInt:group.userId],
            group.name,
            group.sipPhone,
            [NSNumber numberWithInt:group.fileSpaceSize],
            group.creator,
            group.createTime,
            [group.administrators componentsJoinedByString:@","],
            [NSNumber numberWithInt:group.userCount],
            [NSNumber numberWithInt:group.userMaxAmount],
            group.type,
            [UIImage pngDataOfImg:group.photo],
            group.annunciate,
            group.descrip,
            [NSNumber numberWithBool:group.canAdmin],
            [NSNumber numberWithBool:group.canUpload], nil];

    UcaContactService *contactService = [UcaAppDelegate sharedInstance].contactService;
    group.id = [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_GROUP];
    BOOL ok = (group.id != NOT_SAVED);
    if (ok) {
        [contactService addRelationWithGroup:group];
    }

    @synchronized (group.contacts) {
        for (Contact *contact in group.contacts) {
            if ([contactService touchContact:contact]) {
                cols = [NSArray arrayWithObjects:COLUMN_GROUP_ID, COLUMN_CONTACT_ID, nil];
                vals = [NSArray arrayWithObjects:[NSNumber numberWithInt:group.id],
                        [NSNumber numberWithInt:contact.id], nil];
                [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_GROUP_CONTACT];
            } else {
                ok = NO;
            }
        }
    }

    return ok;
}

- (BOOL)doUpdateGroup:(Group *)group {
    NSArray *cols = [NSArray arrayWithObjects:COLUMN_USER_ID,
            COLUMN_NAME,
            COLUMN_SIPPHONE,
            COLUMN_FILE_SPACE_SIZE,
            COLUMN_CREATOR,
            COLUMN_CREATE_TIME,
            COLUMN_ADMINS,
            COLUMN_USER_COUNT,
            COLUMN_USER_MAX_AMOUNT,
            COLUMN_TYPE,
            COLUMN_PHOTO,
            COLUMN_ANNUNCIATE,
            COLUMN_DESCRIP,
            COLUMN_CAN_ADMIN,
            COLUMN_CAN_UPLOAD, nil];
    NSArray *vals = [NSArray arrayWithObjects:[NSNumber numberWithInt:group.userId],
            group.name,
            group.sipPhone,
            [NSNumber numberWithInt:group.fileSpaceSize],
            group.creator,
            group.createTime,
            [group.administrators componentsJoinedByString:@","],
            [NSNumber numberWithInt:group.userCount],
            [NSNumber numberWithInt:group.userMaxAmount],
            group.type,
            [UIImage pngDataOfImg:group.photo],
            group.annunciate,
            group.descrip,
            [NSNumber numberWithBool:group.canAdmin],
            [NSNumber numberWithBool:group.canUpload], nil];

    BOOL ok = [_dbService updateRecord:group.id withColumns:cols andValues:vals inTable:TABLE_NAME_GROUP];
    NSInteger recId = NOT_SAVED;
    UcaContactService *contactService = [UcaAppDelegate sharedInstance].contactService;
    NSMutableArray *curContactIds = [NSMutableArray array];
    @synchronized (group.contacts) {
        for (Contact *contact in group.contacts) {
            if ([contactService touchContact:contact]) {
                [curContactIds addObject:[NSString stringWithFormat:@"%d", contact.id]];

                cols = [NSArray arrayWithObjects:COLUMN_GROUP_ID, COLUMN_CONTACT_ID, nil];
                vals = [NSArray arrayWithObjects:[NSNumber numberWithInt:group.id],
                        [NSNumber numberWithInt:contact.id], nil];
                recId = [_dbService recordIdWhere:cols equals:vals inTable:TABLE_NAME_GROUP_CONTACT];
                if (recId == NOT_SAVED) {
                    [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_GROUP_CONTACT];
                }
            } else {
                ok = NO;
            }
        }
    }

    // Remove kicked off members
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ NOT IN (%@)",
                     TABLE_NAME_GROUP_CONTACT, COLUMN_GROUP_ID, COLUMN_CONTACT_ID, [curContactIds componentsJoinedByString:@","]];
    NSArray *args = [NSArray arrayWithObject:[NSNumber numberWithInt:group.id]];
    ok &= [_dbService executeUpdate:sql withArguments:args];

    return ok;
}

- (BOOL)touchGroup:(Group *)group {
    if (group == nil || group.userId == NOT_SAVED) {
        return NO;
    }

    NSInteger recId = [_dbService recordIdWhere:[NSArray arrayWithObject:COLUMN_USER_ID]
                                         equals:[NSArray arrayWithObject:[NSNumber numberWithInt:group.userId]]
                                        inTable:TABLE_NAME_GROUP];
    if (recId == NOT_SAVED) {
        return [self doAddGroup:group];
    }
    group.id = recId;
    return [self doUpdateGroup:group];
}

- (Group *)touchGroupBySipPhone:(NSString *)sipPhone withTimestamp:(NSDate *)date {
    Group *group = [[Group alloc] init];
    group.sipPhone = sipPhone;

    NSString *val = [[sipPhone componentsSeparatedByString:@"@"] objectAtIndex:0]; // "img-1096"
    val = [val substringFromIndex:4];                                              // "1096"
    group.userId = [val integerValue];

    NSInteger accountId = [[UcaAppDelegate sharedInstance].accountService curAccountId];
    NSInteger recId = [_dbService recordIdWhere:[NSArray arrayWithObject:COLUMN_SIPPHONE]
                                         equals:[NSArray arrayWithObject:sipPhone]
                                        inTable:TABLE_NAME_GROUP];
    if (recId == NOT_SAVED) {
        if ([self doAddGroup:group]) {
            NSArray *cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, COLUMN_CONTACT_TYPE, COLUMN_LAST_ACCESSED, nil];
            NSArray *vals = [NSArray arrayWithObjects:[NSNumber numberWithInt:accountId],
                             [NSNumber numberWithInt:group.id], [NSNumber numberWithInt:ContactType_Group], date, nil];
            [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_ACCOUNT_CONTACT];
        }
    } else {
        group = [self groupOfId:recId];
        NSArray *cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, COLUMN_CONTACT_TYPE, nil];
        NSArray *vals = [NSArray arrayWithObjects:[NSNumber numberWithInt:accountId],
                         [NSNumber numberWithInt:group.id], [NSNumber numberWithInt:ContactType_Group], nil];
        recId = [_dbService recordIdWhere:cols equals:vals inTable:TABLE_NAME_ACCOUNT_CONTACT];
        if (recId == NOT_SAVED) {
            cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, COLUMN_CONTACT_TYPE, COLUMN_LAST_ACCESSED, nil];
            vals = [NSArray arrayWithObjects:[NSNumber numberWithInt:accountId],
                    [NSNumber numberWithInt:group.id], [NSNumber numberWithInt:ContactType_Group], date, nil];
            [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_ACCOUNT_CONTACT];
        } else {
            cols = [NSArray arrayWithObject:COLUMN_LAST_ACCESSED];
            vals = [NSArray arrayWithObject:date];
            [_dbService updateRecord:recId withColumns:cols andValues:vals inTable:TABLE_NAME_ACCOUNT_CONTACT];
        }
    }

    return group;
}

- (void)synchGroups:(NSNumber *)notify {
    BOOL doNotify = [notify boolValue];
    UcaAccountService *accountService = [UcaAppDelegate sharedInstance].accountService;
    if (![accountService isLoggedIn]) {
        return;
    }

    /**
     * Fetch groups information from server.
     */

    char *outXml = NULL;

    UCALIB_ERRCODE res = ucaLib_GetGroupList(accountService.curLoginHandle, &outXml);
    UcaLog(TAG, @"ucaLib_GetGroupList() res=%d outXml='%s'", res, outXml);

    if (res != UCALIB_ERR_OK) {
        UcaLibRelease(outXml);
        if (doNotify) {
            [NotifyUtils alert:I18nString(@"获取固定群组失败，请稍后尝试！")];
            [NotifyUtils postNotificationWithName:UCA_RESPOND_FETCH_GROUP_INFO_FAIL];
        }
        return;
    }

    NSMutableArray *serverGroups = [NSMutableArray array];
    [serverGroups addObjectsFromArray:[XmlUtils parseGroupInfos:outXml]];
    UcaLibRelease(outXml);

    /**
     * Delete the groups that current account not in.
     */
    NSMutableArray *sipPhones = [NSMutableArray array];
    for (Group *group in serverGroups) {
        [sipPhones addObject:group.sipPhone];
    }
    NSString *sipPhonesStr = [sipPhones componentsJoinedByString:@"','"];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ = ? AND %@ NOT IN (SELECT %@ FROM %@ WHERE %@ IN ('%@'))",
                     TABLE_NAME_ACCOUNT_CONTACT, COLUMN_ACCOUNT_ID, COLUMN_CONTACT_TYPE, COLUMN_CONTACT_ID,
                     COLUMN_ID, TABLE_NAME_GROUP, COLUMN_SIPPHONE, sipPhonesStr];
    NSArray *args = [NSArray arrayWithObjects:
                     [NSNumber numberWithInt:accountService.curAccountId],
                     [NSNumber numberWithInt:ContactType_Group], nil];
    BOOL delOk = [_dbService executeUpdate:sql withArguments:args];

    /**
     * Fetch group members information from server, and map them with database.
     */
    for (Group *group in serverGroups) {
        outXml = NULL;
        res = ucaLib_GetGroupMemberInfo(accountService.curLoginHandle, [[XmlUtils buildGetGroupMembers:group.id] UTF8String], &outXml);
        if (res != UCALIB_ERR_OK) {
            UcaLibRelease(outXml);
            continue;
        }

        [group addContacts:[XmlUtils fetchContactsFromXml:outXml forType:ContactType_Unknown]];
        UcaLibRelease(outXml);

        [self touchGroup:group];
    }

    self->fetchedData = YES;

    if (doNotify) {
        [NotifyUtils postNotificationWithName:UCA_RESPOND_FETCH_GROUP_INFO_OKAY];
    }
}

- (void)onLoginChanged:(NSNotification *)notification {
    if (!_started) {
        return;
    }

    UcaAccountService *accountService = notification.object;
    if (![accountService isLoggedIn]) {
        // 将所有群组设置为不可管理，不可上传
        [_dbService updateRecordsWithColumns:[NSArray arrayWithObjects:COLUMN_CAN_ADMIN, COLUMN_CAN_UPLOAD, nil]
                                       where:nil
                                andArguments:[NSArray arrayWithObjects:[NSNumber numberWithBool:NO],
                                              [NSNumber numberWithBool:NO], nil]
                                     inTable:TABLE_NAME_GROUP];
        self->fetchedData = YES;
        return;
    }
    [self synchGroups:[NSNumber numberWithBool:YES]];
}

- (void)fetchGroupInfos:(NSNotification *)note {
    [self synchGroups:[NSNumber numberWithBool:YES]];
}

- (void)onMemeberChanged:(NSNotification *)note {
    NSString *xml = note.object;
    GroupChangeInfo *info = [XmlUtils parseGroupChangeInfo:[xml UTF8String]];

    NSInteger groupId = [_dbService recordIdWhere:[NSArray arrayWithObject:COLUMN_USER_ID]
                                           equals:[NSArray arrayWithObject:[NSNumber numberWithInt:info.groupId]]
                                          inTable:TABLE_NAME_GROUP];
    if (groupId == NOT_SAVED) {
        return;
    }

    BOOL ok = [_dbService updateRecord:groupId
                           withColumns:[NSArray arrayWithObject:COLUMN_USER_COUNT]
                             andValues:[NSArray arrayWithObject:[NSNumber numberWithInt:info.userCount]]
                               inTable:TABLE_NAME_GROUP];

    // 删除被踢出的组员。
    NSString *sipPhones = [info.kickedUserSip componentsJoinedByString:@"','"];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ? AND %@ IN (SELECT %@ FROM %@ WHERE %@ IN ('%@'))",
                     TABLE_NAME_GROUP_CONTACT, COLUMN_GROUP_ID, COLUMN_CONTACT_ID, COLUMN_ID,
                     TABLE_NAME_CONTACT, COLUMN_SIPPHONE, sipPhones];
    NSArray *args = [NSArray arrayWithObject:[NSNumber numberWithInt:groupId]];
    ok &= [_dbService executeUpdate:sql withArguments:args];

    // 记录新加的组员
    UcaContactService *contactService = [UcaAppDelegate sharedInstance].contactService;
    NSInteger recId = NOT_SAVED;
    NSMutableArray *cols = [NSMutableArray arrayWithObjects:COLUMN_GROUP_ID, COLUMN_CONTACT_ID, nil];
    for (NSString *sipPhone in info.presentUserSip) {
        Contact *contact = [contactService touchContactBySipPhone:sipPhone];
        NSMutableArray *vals = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:groupId],
                                [NSNumber numberWithInt:contact.id], nil];
        recId = [_dbService recordIdWhere:cols equals:vals inTable:TABLE_NAME_GROUP_CONTACT];
        if (recId == NOT_SAVED) {
            recId = [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_GROUP_CONTACT];
            ok &= (recId != NOT_SAVED);
        }
    }

    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_INDICATE_GROUP_UPDATED];
    }
}

- (void)onMemeberPresentation:(NSNotification *)note {
    NSString *xmlMsg = note.object;
    NSMutableArray *notifications = [XmlUtils parseMultiPresenceNotification:[xmlMsg UTF8String]];
    UcaContactService *contactService = [UcaAppDelegate sharedInstance].contactService;
    BOOL notify = NO;

    for (ContactPresence *note in notifications) {
        notify |= [contactService updateContact:note.userId
                                   presentation:note.state
                                       cameraOn:note.cameraOn];
    }

    if (notify) {
        [NotifyUtils postNotificationWithName:UCA_INDICATE_GROUP_UPDATED];
    }
}

/**
 * 更细群组公告。
 * @param param 参数，包含如下键值对：
 *     {
 *         KEY_GROUP      : 群组实例,
 *         KEY_ANNUNCIATE : 新公告
 *         KEY_XML        : 更新输入XML
 *     }
 */
- (void)doModifyGroupWithXml:(NSDictionary *)param {
    Group *group = [param objectForKey:KEY_GROUP];
    NSString *newAnn = [param objectForKey:KEY_ANNUNCIATE];
    NSString *xml = [param objectForKey:KEY_XML];
    char *outXml = NULL;

    UCALIB_ERRCODE res = ucaLib_ManageGroup([[UcaAppDelegate sharedInstance].accountService curLoginHandle], [xml UTF8String], &outXml);
    UcaLog(TAG, @"ucaLib_ManageGroup() res=%d outXml='%s'", res, outXml);

    if (res != UCALIB_ERR_OK) {
        [NotifyUtils postNotificationWithName:UCA_INDICATE_MODIFY_GROUP_FAIL];
        UcaLibRelease(outXml);
        return;
    }

    // Update database
    BOOL ok = [_dbService updateRecord:group.id
                           withColumns:[NSArray arrayWithObject:COLUMN_ANNUNCIATE]
                             andValues:[NSArray arrayWithObject:newAnn]
                               inTable:TABLE_NAME_GROUP];

    // TODO: parse outXml to detect potential error?
    UcaLibRelease(outXml);

    [NotifyUtils postNotificationWithName:(ok ? UCA_INDICATE_MODIFY_GROUP_OKAY : UCA_INDICATE_MODIFY_GROUP_FAIL)];
}

- (void)modifyGroup:(Group *)group withNewAnnunciate:(NSString *)newAnn {
    NSString *xml = [XmlUtils buildModifyGroup:group.id annunciate:newAnn];
    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:
                           group, KEY_GROUP, newAnn, KEY_ANNUNCIATE, xml, KEY_XML, nil];
    [self performSelectorInBackground:@selector(doModifyGroupWithXml:) withObject:param];
}

- (BOOL)doManageGroupMemberWithXml:(NSString *)xml {
    char *outXml = NULL;

    UCALIB_ERRCODE res = ucaLib_ManageGroupMember([[UcaAppDelegate sharedInstance].accountService curLoginHandle], [xml UTF8String], &outXml);
    UcaLog(TAG, @"ucaLib_ManageGroupMember() res=%d outXml='%s'", res, outXml);

    if (res != UCALIB_ERR_OK) {
        UcaLibRelease(outXml);
        return NO;
    }

    // TODO: parse outXml to detect potential error?
    UcaLibRelease(outXml);
    return YES;
}

- (void)doAddGroupMemberWithXml:(NSString *)xml {
    BOOL ok = [self doManageGroupMemberWithXml:xml];

    if (ok && _opGroup && _opContacts) {
        BOOL recId = NOT_SAVED;
        NSMutableArray *cols = [NSMutableArray arrayWithObjects:COLUMN_GROUP_ID, COLUMN_CONTACT_ID, nil];
        for (Contact *contact in _opContacts) {
            NSMutableArray *vals = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:_opGroup.id],
                                    [NSNumber numberWithInt:contact.id], nil];
            recId = [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME_GROUP_CONTACT];
            ok &= (recId != NOT_SAVED);
        }
    }
    _opGroup = nil;
    _opContacts = nil;

    [NotifyUtils postNotificationWithName:(ok ? UCA_INDICATE_ADD_GROUP_MEMBERS_OKAY : UCA_INDICATE_ADD_GROUP_MEMBERS_FAIL)];
}

- (void)doRemoveGroupMemberWithXml:(NSString *)xml {
    BOOL ok = [self doManageGroupMemberWithXml:xml];

    if (ok && _opGroup && _opContacts) {
        NSMutableArray *cols = [NSMutableArray arrayWithObjects:COLUMN_GROUP_ID, COLUMN_CONTACT_ID, nil];
        for (Contact *contact in _opContacts) {
            NSMutableArray *vals = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:_opGroup.id],
                                    [NSNumber numberWithInt:contact.id], nil];
            ok &= [_dbService deleteRecordsWhere:cols equals:vals fromTable:TABLE_NAME_GROUP_CONTACT];
        }
    }
    _opGroup = nil;
    _opContacts = nil;

    [NotifyUtils postNotificationWithName:(ok ? UCA_INDICATE_DELET_GROUP_MEMBERS_OKAY : UCA_INDICATE_DELET_GROUP_MEMBERS_FAIL)];
}

- (void)addContacts:(NSArray *)contacts toGroup:(Group *)group {
    _opContacts = contacts;
    _opGroup = group;

    NSString *xml = [XmlUtils buildAddContacts:contacts toGroup:group];
    [self performSelectorInBackground:@selector(doAddGroupMemberWithXml:) withObject:xml];
}

- (void)removeMembers:(NSArray *)contacts fromGroup:(Group *)group {
    _opContacts = contacts;
    _opGroup = group;

    NSString *xml = [XmlUtils buildRemoveMembers:contacts fromGroup:group];
    [self performSelectorInBackground:@selector(doRemoveGroupMemberWithXml:) withObject:xml];
}

- (void)bindGroup:(Group *)group fromQueryResult:(FMResultSet *)rs {
    group.id = [rs intForColumn:COLUMN_ID];
    group.userId = [rs intForColumn:COLUMN_USER_ID];
    group.name = [rs stringForColumn:COLUMN_NAME];
    group.sipPhone = [rs stringForColumn:COLUMN_SIPPHONE];
    group.fileSpaceSize = [rs intForColumn:COLUMN_FILE_SPACE_SIZE];
    group.creator = [rs stringForColumn:COLUMN_CREATOR];
    group.createTime = [rs stringForColumn:COLUMN_CREATE_TIME];
    group.administrators = [NSMutableArray arrayWithArray:[[rs stringForColumn:COLUMN_ADMINS] componentsSeparatedByString:@","]];
    group.userCount = [rs intForColumn:COLUMN_USER_COUNT];
    group.userMaxAmount = [rs intForColumn:COLUMN_USER_MAX_AMOUNT];
    group.type = [rs stringForColumn:COLUMN_TYPE];
    NSData *data = [rs dataForColumn:COLUMN_PHOTO];
    if (data != nil && data.length > 0) {
        group.photo = [UIImage imageWithData:data];
    }
    group.annunciate = [rs stringForColumn:COLUMN_ANNUNCIATE];
    group.descrip = [rs stringForColumn:COLUMN_DESCRIP];
    group.canAdmin = [rs boolForColumn:COLUMN_CAN_ADMIN];
    group.canUpload = [rs boolForColumn:COLUMN_CAN_UPLOAD];
}

- (Group *)groupOfId:(NSInteger)gid {
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?",
                     TABLE_NAME_GROUP, COLUMN_ID];
    NSArray *args = [NSArray arrayWithObject:[NSNumber numberWithInteger:gid]];
    NSMutableArray *grps = [NSMutableArray array];
    Group *group = nil;
    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    while ([rs next]) {
        group = [[Group alloc] init];
        [self bindGroup:group fromQueryResult:rs];
        [grps addObject:group];
    }
    [rs close];
    [rs setParentDB:nil];

    if ([grps count] <= 0) {
        return nil;
    }

    group = [grps objectAtIndex:0];
    UcaContactService *contactService = [UcaAppDelegate sharedInstance].contactService;
    sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?", COLUMN_CONTACT_ID, TABLE_NAME_GROUP_CONTACT, COLUMN_GROUP_ID];
    rs = [_dbService executeQuery:sql withArguments:args];
    while ([rs next]) {
        NSInteger contactId = [rs intForColumn:COLUMN_CONTACT_ID];
        Contact *contact = [contactService getContactById:contactId];
        [group addContact:contact];
    }
    [rs close];
    [rs setParentDB:nil];

    return group;
}

- (NSMutableArray *)groups {
    NSInteger accountId = [[UcaAppDelegate sharedInstance].accountService curAccountId];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ IN (SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ?)",
                     TABLE_NAME_GROUP, COLUMN_ID, COLUMN_CONTACT_ID, TABLE_NAME_ACCOUNT_CONTACT, COLUMN_ACCOUNT_ID, COLUMN_CONTACT_TYPE];
    NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInteger:accountId],
                     [NSNumber numberWithInteger:ContactType_Group], nil];
    NSMutableArray *grps = [NSMutableArray array];
    UcaContactService *contactService = [UcaAppDelegate sharedInstance].contactService;
    Group *group = nil;
    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    while ([rs next]) {
        group = [[Group alloc] init];
        [self bindGroup:group fromQueryResult:rs];

        sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?", COLUMN_CONTACT_ID, TABLE_NAME_GROUP_CONTACT, COLUMN_GROUP_ID];
        args = [NSArray arrayWithObject:[NSNumber numberWithInteger:group.id]];
        FMResultSet *rsContact = [_dbService executeQuery:sql withArguments:args];
        while ([rsContact next]) {
            NSInteger contactId = [rsContact intForColumn:COLUMN_CONTACT_ID];
            Contact *contact = [contactService getContactById:contactId];
            [group addContact:contact];
        }
        [rsContact close];
        [rsContact setParentDB:nil];

        [grps addObject:group];
    }
    [rs close];
    [rs setParentDB:nil];

    return grps;
}

- (BOOL)fetchedData {
    if ([[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
        return self->fetchedData;
    }
    return YES;
}

@end
