/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"UcaMessageService"

#undef TABLE_NAME
#define TABLE_NAME @"Message"

#define COLUMN_ACCOUNT_ID   @"accountId"
#define COLUMN_STATUS       @"status"
#define COLUMN_SENDER_SIP   @"senderSip"
#define COLUMN_RECEIVER_SIP @"receiverSip"
#define COLUMN_TOWHOM_SIP   @"toWhomSip"
#define COLUMN_DATETIME     @"datetime"
#define COLUMN_HTML         @"html"

@interface UcaMessageService()
- (NSInteger)addMessage:(Message *)message;
- (void)renameDownloadedImImage:(NSString *)html forMessageId:(NSInteger)msgId;
- (BOOL)updateMessage:(NSInteger)msgId withStatus:(MessageStatus)status;
@end

@implementation UcaMessageService {
    NSMutableDictionary *_imgToRename;
    UcaDatabaseService *_dbService;
}

- (id)init {
    if ((self = [super init])) {
        _imgToRename = [[NSMutableDictionary alloc] init];
        _dbService = [UcaAppDelegate sharedInstance].databaseService;
    }
    return self;
}

- (void)onDeleteAccount:(NSNotification *)notification {
    NSNumber *accountId = notification.object;
    BOOL ok = [_dbService deleteRecordsWhere:[NSArray arrayWithObject:COLUMN_ACCOUNT_ID]
                                      equals:[NSArray arrayWithObject:accountId]
                                   fromTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_DELETE_MESSAGES];
    }
}

- (void)onDeleteContact:(NSNotification *)notification {
    NSInteger curAccountId = [UcaAppDelegate sharedInstance].accountService.curAccountId;
    Contact *contact = notification.object;
    NSString *sipPhone = contact.sipPhone;
    if ([NSString isNullOrEmpty:sipPhone]) {
        return;
    }

    NSString *clause = [NSString stringWithFormat:@"%@ = ? AND (%@ = ? OR %@ = ?)",
                        COLUMN_ACCOUNT_ID, COLUMN_SENDER_SIP, COLUMN_RECEIVER_SIP];
    NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInteger:curAccountId], sipPhone, sipPhone, nil];
    BOOL ok = [_dbService deleteRecordsWhere:clause andArguments:args fromTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_DELETE_MESSAGES];
    }
}

/**
 * 更新电话号码相关的联系人访问时间。
 */
- (void)touchContactBySipPhone:(NSString *)sipPhone withTimestamp:(NSDate *)date {
    if ([sipPhone hasPrefix:@"img-"]) {
        UcaGroupService *service = [UcaAppDelegate sharedInstance].groupService;
        [service touchGroupBySipPhone:sipPhone withTimestamp:date];
    } else {
        UcaContactService *service = [UcaAppDelegate sharedInstance].contactService;
        [service touchContactBySipPhone:sipPhone withTimestamp:date];
    }
}

- (void)onReceivedIm:(NSNotification *)notification {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    UcaNativeImEvent *event = notification.object;
    if (event.handle != app.accountService.curLoginHandle) {
        return;
    }

    if ([event.senderSip hasPrefix:@"sip:"]) {
        event.senderSip = [event.senderSip strimmedSipPhone];
    }
    if ([event.receiverSip hasPrefix:@"sip:"]) {
        event.receiverSip = [event.receiverSip strimmedSipPhone];
    }
    if ([event.toWhomSip hasPrefix:@"sip:"]) {
        event.toWhomSip = [event.toWhomSip strimmedSipPhone];
    }

    Message *msg = [[Message alloc] init];
    msg.senderSip = event.senderSip;
    msg.receiverSip = event.receiverSip;
    msg.toWhomSip = event.toWhomSip;
    msg.html = [event.htmlMsg replaceImgSrc:@""];

    Person *sender = [msg sender];

    if ([event.htmlMsg isEqualToString:@"typing"]) {
        if ([sender isKindOfClass:[Contact class]]) {
            [NotifyUtils postNotificationWithName:UCA_EVENT_TYPING object:sender];
        }
        return;
    }

    if ([sender isKindOfClass:[Account class]]) {
        msg.status = Message_Sent;
    } else {
        msg.status = Message_Received_Unread;
    }

    [self touchContactBySipPhone:sender.sipPhone withTimestamp:msg.datetime];
    [self touchContactBySipPhone:msg.receiver.sipPhone withTimestamp:msg.datetime];
    [self touchContactBySipPhone:msg.toWhom.sipPhone withTimestamp:msg.datetime];

    msg.id = [self addMessage:msg];
    [self renameDownloadedImImage:event.htmlMsg forMessageId:msg.id];
    [NotifyUtils postNotificationWithName:UCA_EVENT_ADD_MESSAGE
                                   object:[NSNumber numberWithInteger:msg.id]];
}

- (void)onReceivedImImg:(NSNotification *)note {
    UcaSfpStatusEvent *event = note.object;
    [self touchContactBySipPhone:event.peerUri withTimestamp:[NSDate date]];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    @synchronized (_imgToRename) {
        NSString *dstFilename = [_imgToRename objectForKey:event.fullPath];
        if (![NSString isNullOrEmpty:dstFilename] && [fileManager fileExistsAtPath:event.fullPath]) {
            [fileManager moveItemAtPath:event.fullPath toPath:dstFilename error:nil];
            [_imgToRename removeObjectForKey:event.fullPath];
        }
    }
}

- (void)onImSentFailed:(NSNotification *)note {
    NSString *failedIm = note.object;
    NSInteger curAccountId = [UcaAppDelegate sharedInstance].accountService.curAccountId;

    // FIXME: 因为ucalib缺少IM发送成功的callback状态，sendMessage里ucaLib_SendMsg调用
    // 成功时，并不一定该IM就已经发送成功了，所以这里SQL query的条件IM的状态等于Message_Sending
    // 是假设ucalib提供了IM发送成功的callback状态，并且sendMessage里ucaLib_SendMsg调用
    // 成功时，将IM的状态设置为Message_Sending而不是Message_Sent。
    NSArray *cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_STATUS, COLUMN_HTML, nil];
    NSArray *vals = [NSArray arrayWithObjects:[NSNumber numberWithInteger:curAccountId],
                     [NSNumber numberWithInteger:Message_Sending], failedIm, nil];
    NSInteger msgId = [_dbService recordIdWhere:cols equals:vals inTable:TABLE_NAME];
    if (msgId == NOT_SAVED) {
        return;
    }

    [self updateMessage:msgId withStatus:Message_SendFailed];
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }

    NSArray *colInfos = [NSArray arrayWithObjects:
                         COLUMN_ID, @"INTEGER PRIMARY KEY AUTOINCREMENT",
                         COLUMN_ACCOUNT_ID, @"INTEGER",
                         COLUMN_STATUS, @"TINYINT(1)",
                         COLUMN_SENDER_SIP, @"TEXT",
                         COLUMN_RECEIVER_SIP, @"TEXT",
                         COLUMN_TOWHOM_SIP, @"TEXT",
                         COLUMN_DATETIME, @"INTEGER",
                         COLUMN_HTML, @"TEXT",
                         nil];
    if (![_dbService createTableIfNeeds:TABLE_NAME columnInfos:colInfos]) {
        UcaLog(TAG, @"Failed to create table %@", TABLE_NAME);
        return NO;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeleteAccount:)
                                                 name:UCA_EVENT_DELETE_ACCOUNT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeleteContact:)
                                                 name:UCA_EVENT_DELETE_CONTACT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceivedIm:)
                                                 name:UCA_NATIVE_IM_RECEIVED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceivedImImg:)
                                                 name:UCA_NATIVE_IM_IMG_RECEIVED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onImSentFailed:)
                                                 name:UCA_NATIVE_IM_SENT_FAILED
                                               object:nil];
    return YES;
}

- (BOOL)stop {
    UcaLog(TAG, @"Stop()");
    if (![super stop]) {
        return NO;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    return YES;
}

- (void)renameDownloadedImImage:(NSString *)html forMessageId:(NSInteger)msgId {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    NSString *root = [app.configService.imBaseUrl path];
    NSString *pathPrefix = [[app.configService.imBaseUrl path] stringByAppendingPathComponent:[NSString stringWithFormat:@"msg%d_", msgId]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"<img +jt=['\"]?true['\"]? +src=['\"]?+([^'\"]+)['\"]?+"
                                                                        options:NSRegularExpressionCaseInsensitive
                                                                          error:nil];
    NSArray *matches = [re matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    for (NSTextCheckingResult *match in matches) {
        if ([match numberOfRanges] < 1) {
            continue;
        }

        NSRange r = [match rangeAtIndex:1];
        NSString *imgName = [[[html substringWithRange:r] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]] lastObject];
        NSString *srcFilename = [root stringByAppendingPathComponent:imgName];
        NSString *dstFilename = [pathPrefix stringByAppendingString:imgName];
        if ([fileManager fileExistsAtPath:srcFilename]) {
            [fileManager moveItemAtPath:srcFilename toPath:dstFilename error:nil];
        } else {
            @synchronized (_imgToRename) {
                [_imgToRename setObject:dstFilename forKey:srcFilename];
            }
        }
    }
}

- (void)sendMessage:(Message *)msg {
    if (msg.id == NOT_SAVED) {
        msg.id = [self addMessage:msg];
        [NotifyUtils postNotificationWithName:UCA_EVENT_ADD_MESSAGE
                                       object:[NSNumber numberWithInteger:msg.id]];
    }

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    UcaLog(TAG, @"sendMessage() from %d to '%@' with '%@'", app.accountService.curLoginHandle, msg.receiverSip, msg.html);
    UCALIB_ERRCODE res = ucaLib_SendMsg(app.accountService.curLoginHandle,
                                        [msg.receiverSip UTF8String],
                                        [msg.html UTF8String],
                                        NULL);
    UcaLog(TAG, @"sendMessage() return %d", res);
    if (res == UCALIB_ERR_OK) {
        msg.status = Message_Sent;
        [self touchContactBySipPhone:msg.receiver.sipPhone withTimestamp:msg.datetime];
    } else {
        msg.status = Message_SendFailed;
    }

    [self updateMessage:msg.id withStatus:msg.status];
}

- (NSInteger)addMessage:(Message *)msg {
    NSArray *cols = [NSArray arrayWithObjects:
                     COLUMN_ACCOUNT_ID,
                     COLUMN_STATUS,
                     COLUMN_SENDER_SIP,
                     COLUMN_RECEIVER_SIP,
                     COLUMN_TOWHOM_SIP,
                     COLUMN_DATETIME,
                     COLUMN_HTML, nil];
    NSArray *vals = [NSArray arrayWithObjects:
                     [NSNumber numberWithInteger:msg.accountId],
                     [NSNumber numberWithInteger:msg.status],
                     [NSString isNullOrEmpty:msg.senderSip] ? @"" : msg.senderSip,
                     [NSString isNullOrEmpty:msg.receiverSip] ? @"" : msg.receiverSip,
                     [NSString isNullOrEmpty:msg.toWhomSip] ? @"" : msg.toWhomSip,
                     msg.datetime,
                     msg.html, nil];
    return [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME];
}

- (BOOL)updateMessage:(NSInteger)msgId withStatus:(MessageStatus)status {
    BOOL ok = [_dbService updateRecord:msgId
                           withColumns:[NSArray arrayWithObject:COLUMN_STATUS]
                             andValues:[NSArray arrayWithObject:[NSNumber numberWithInteger:status]]
                               inTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_MESSAGE
                                       object:[NSNumber numberWithInteger:msgId]];
    }
    return ok;
}

- (BOOL)markMessageAsRead:(NSNumber *)msgId {
    if (!msgId) {
        UcaLog(TAG, @"Cannot mark unspecified message");
        return NO;
    }

    return [self updateMessage:[msgId integerValue] withStatus:Message_Received_Read];
}

- (BOOL)removeImageOfMessage:(Message *)message {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:[app.configService.imBaseUrl path] error:nil];
    NSString *prefix = [NSString stringWithFormat:@"msg%d_", message.id];

    BOOL ok = YES;
    for (NSString *fname in files) {
        if (![fname hasPrefix:prefix]) {
            continue;
        }

        NSString *fullPath = [[app.configService.imBaseUrl path] stringByAppendingPathComponent:fname];
        ok |= [fileManager removeItemAtPath:fullPath error:nil];
    }
    return ok;
}

- (BOOL)deleteMessages:(NSArray *)messages {
    if (!messages || messages.count == 0) {
        UcaLog(TAG, @"no messages to delete");
        return NO;
    }

    NSMutableArray *ids = [NSMutableArray array];
    for (Message *message in messages) {
        [ids addObject:[NSString stringWithFormat:@"%d", message.id]];
    }

    NSString *clause = [NSString stringWithFormat:@"%@ IN (%@)", COLUMN_ID, [ids componentsJoinedByString:@", "]];
    BOOL ok = [_dbService deleteRecordsWhere:clause andArguments:nil fromTable:TABLE_NAME];
    if (ok) {
        for (Message *msg in messages) {
            [self removeImageOfMessage:msg];
        }

        [NotifyUtils postNotificationWithName:UCA_EVENT_DELETE_MESSAGES];
    }
    return ok;
}

- (BOOL)sendImageMessage:(Message *)message {
    message.id = [self addMessage:message];
    if (message.id == NOT_SAVED) {
        return NO;
    }

    NSData *imgData = nil;
    NSString *ext = [message.imageName pathExtension];
    if ([[ext lowercaseString] isEqualToString:@"png"]) {
        imgData = UIImagePNGRepresentation(message.image);
    } else {
        imgData = UIImageJPEGRepresentation(message.image, 0.5);
    }

    if (imgData == nil || [imgData length] <= 0) {
        return NO;
    }

    message.imageName = [NSString stringWithFormat:@"msg%d_%@", message.id, message.imageName];

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    NSString *fullPath = [[app.configService.imBaseUrl path] stringByAppendingPathComponent:message.imageName];

    if (![imgData writeToFile:fullPath atomically:YES]) {
        return NO;
    }

    [self sendMessage:message];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:fullPath error:nil];
    if (!fileAttributes) {
        return NO;
    }

    NSString *fileSize = [NSString stringWithFormat:@"%lld",[fileAttributes fileSize]];
    UCALIB_ERRCODE res = ucaLib_SfpSendFile(app.accountService.curLoginHandle,
                                            [message.receiverSip UTF8String],
                                            [fullPath UTF8String],
                                            [message.imageName UTF8String],
                                            "<picture>",
                                            [fileSize UTF8String],
                                            0.0, NULL);
    return res == UCALIB_ERR_OK;
}

- (NSUInteger)countOfUnreadMessages {
    NSNumber *curAccountId = [NSNumber numberWithInteger:[UcaAppDelegate sharedInstance].accountService.curAccountId];
    NSArray *cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_STATUS, nil];
    NSArray *vals = [NSArray arrayWithObjects:curAccountId, [NSNumber numberWithInteger:Message_Received_Unread], nil];
    return [_dbService countOfRecordsWhere:cols equals:vals inTable:TABLE_NAME];
}

- (NSUInteger)countOfUnreadMessagesWithContact:(Contact *)contact {
    if (!contact) {
        UcaLog(TAG, @"Cannot fetch unread message count of null contact");
        return 0;
    }
    NSNumber *curAccountId = [NSNumber numberWithInteger:[UcaAppDelegate sharedInstance].accountService.curAccountId];
    NSArray *cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_SENDER_SIP, COLUMN_STATUS, nil];
    NSArray *vals = [NSArray arrayWithObjects:curAccountId, contact.sipPhone, [NSNumber numberWithInteger:Message_Received_Unread], nil];
    return [_dbService countOfRecordsWhere:cols equals:vals inTable:TABLE_NAME];
}

- (NSUInteger)countOfMessagesWithContact:(Contact *)contact {
    if (!contact) {
        UcaLog(TAG, @"Cannot fetch message count of null contact");
        return 0;
    }
    NSNumber *curAccountId = [NSNumber numberWithInteger:[UcaAppDelegate sharedInstance].accountService.curAccountId];
    NSArray *cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_SENDER_SIP, nil];
    NSArray *vals = [NSArray arrayWithObjects:curAccountId, contact.sipPhone, nil];
    return [_dbService countOfRecordsWhere:cols equals:vals inTable:TABLE_NAME];
}

- (NSArray *)messagesWithContact:(Contact *)contact {
    return [self messagesWithContact:contact excludeBefore:nil];
}

- (NSArray *)messagesWithContact:(Contact *)contact excludeBefore:(NSDate *)timestamp {
    if (!contact) {
        UcaLog(TAG, @"Cannot fetch messages of null contact");
        return nil;
    }

    NSMutableString *sql = [[NSMutableString alloc] init];
    NSMutableArray *args = [NSMutableArray array];

    [sql appendFormat:@"SELECT * FROM %@", TABLE_NAME];
    if ([contact.sipPhone hasPrefix:@"img-"] || [contact.sipPhone hasPrefix:@"imc-"]) {
        [sql appendFormat:@" WHERE (%@ = ? OR %@ = ?)", COLUMN_SENDER_SIP, COLUMN_RECEIVER_SIP];
        [args addObject:contact.sipPhone];
        [args addObject:contact.sipPhone];
    } else {
        NSString *curAccountSipPhone = [UcaAppDelegate sharedInstance].accountService.currentAccount.sipPhone;
        [sql appendFormat:@" WHERE ((%@ = ? AND %@ = ?) OR (%@ = ? AND %@ = ?))",
            COLUMN_SENDER_SIP, COLUMN_RECEIVER_SIP, COLUMN_SENDER_SIP, COLUMN_RECEIVER_SIP];
        [args addObject:contact.sipPhone];
        [args addObject:curAccountSipPhone];
        [args addObject:curAccountSipPhone];
        [args addObject:contact.sipPhone];
    }

    if (timestamp != nil) {
        [sql appendFormat:@" AND %@ > ?", COLUMN_DATETIME];
        [args addObject:timestamp];
    }
    [sql appendFormat:@" ORDER BY %@ ASC", COLUMN_DATETIME];

    NSMutableArray *msgs = [NSMutableArray array];
    Message *msg = nil;
    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    while ([rs next]) {
        msg = [[Message alloc] init];
        msg.id = [rs intForColumn:COLUMN_ID];
        msg.accountId = [rs intForColumn:COLUMN_ACCOUNT_ID];
        msg.status = [rs intForColumn:COLUMN_STATUS];
        msg.datetime = [rs dateForColumn:COLUMN_DATETIME];
        msg.senderSip = [rs stringForColumn:COLUMN_SENDER_SIP];
        msg.receiverSip = [rs stringForColumn:COLUMN_RECEIVER_SIP];
        msg.toWhomSip = [rs stringForColumn:COLUMN_TOWHOM_SIP];
        msg.html = [rs stringForColumn:COLUMN_HTML];

        [msgs addObject:msg];
    }
    [rs close];
    [rs setParentDB:nil];
    return msgs;
}

- (NSUInteger)countOfUnreadSystemMessages {
    Contact *sysContact = [[Contact alloc] init];
    sysContact.sipPhone = SYSTEM_SIPPHONE;
    return [self countOfUnreadMessagesWithContact:sysContact];
}

- (NSUInteger)countOfSystemMessages {
    Contact *sysContact = [[Contact alloc] init];
    sysContact.sipPhone = SYSTEM_SIPPHONE;
    return [self countOfMessagesWithContact:sysContact];
}

- (NSArray *)systemMessages {
    Contact *sysContact = [[Contact alloc] init];
    sysContact.sipPhone = SYSTEM_SIPPHONE;
    return [self messagesWithContact:sysContact];
}

@end
