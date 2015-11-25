/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"UcaRecentService"

#undef TABLE_NAME
#define TABLE_NAME @"RecentLog"

#define COLUMN_ACCOUNT_ID   @"accountId"
#define COLUMN_CONTACT_ID   @"contactId"
#define COLUMN_NUMBER       @"number"
#define COLUMN_TYPE         @"type"
#define COLUMN_DATETIME     @"datetime"
#define COLUMN_DURATION     @"duration"

@implementation UcaRecentService {
    UcaDatabaseService *_dbService;
}

- (id)init {
    if ((self = [super init])) {
        _dbService = [UcaAppDelegate sharedInstance].databaseService;
    }
    return self;
}

// TODO: merge this method into Contact class
- (NSString *)getNumberTitleFromContact:(Contact *)contact withNumber:(NSString *)number {
    if ([number isEqualToString:contact.sipPhone]) {
        return I18nString(@"软终端号码");
    } else if ([number isEqualToString:contact.workPhone]) {
        return I18nString(@"公司电话");
    } else if ([number isEqualToString:contact.familyPhone]) {
        return I18nString(@"家庭电话");
    } else if ([number isEqualToString:contact.mobilePhone]) {
        return I18nString(@"联系电话一");
    } else if ([number isEqualToString:contact.mobilePhone2]) {
        return I18nString(@"联系电话二");
    } else if ([number isEqualToString:contact.otherPhone]) {
        return I18nString(@"其他号码");
    }
    return nil;
}

- (void)onDeleteContact:(NSNotification *)notification {
    Contact *contact = notification.object;
    [self deleteRecentLogsOfContact:contact];
}

- (void)onDeleteAccount:(NSNotification *)notification {
    NSNumber *accountId = notification.object;
    BOOL ok = [_dbService deleteRecordsWhere:[NSArray arrayWithObject:COLUMN_ACCOUNT_ID]
                                      equals:[NSArray arrayWithObject:accountId]
                                   fromTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_DELETE_RECENT_LOGS];
    }
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }

    NSArray *colInfos = [NSArray arrayWithObjects:
                         COLUMN_ID, @"INTEGER PRIMARY KEY AUTOINCREMENT",
                         COLUMN_ACCOUNT_ID, @"INTEGER",
                         COLUMN_CONTACT_ID, @"INTEGER",
                         COLUMN_NUMBER, @"TEXT",
                         COLUMN_TYPE, @"TINYINT(1)",
                         COLUMN_DATETIME, @"INTEGER",
                         COLUMN_DURATION, @"INTEGER",
                         nil];
    if (![_dbService createTableIfNeeds:TABLE_NAME columnInfos:colInfos]) {
        UcaLog(TAG, @"Failed to create table %@", TABLE_NAME);
        return NO;
    }


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeleteContact:)
                                                 name:UCA_EVENT_DELETE_CONTACT
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeleteAccount:)
                                                 name:UCA_EVENT_DELETE_ACCOUNT
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

/**
 * 获取符合附加条件的最近通讯记录。
 * @param conditionStr 若为nil或空字符串时，获取当前帐号下的所有最近通讯记录；若不为空，则必须
 * 符合@"AND (...)"的格式。
 * @return 按时间倒序排列的最近通讯记录。
 */
- (NSArray *)recentLogsWhere:(NSString *)clause andArgument:(NSArray *)extraArgs {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    NSMutableString *sql = [[NSMutableString alloc] init];
    NSMutableArray *args = [NSMutableArray array];

    [sql appendFormat:@"SELECT * FROM %@ WHERE %@ = ?", TABLE_NAME, COLUMN_ACCOUNT_ID];
    [args addObject:[NSNumber numberWithInteger:app.accountService.curAccountId]];

    if (![NSString isNullOrEmpty:clause]) {
        [sql appendFormat:@" AND (%@)", clause];
        [args addObjectsFromArray:extraArgs];
    }

    [sql appendFormat:@" ORDER BY %@ DESC", COLUMN_DATETIME];

    NSMutableArray *logs = [NSMutableArray array];
    RecentLog *log = nil;
    FMResultSet *rs = [_dbService executeQuery:sql withArguments:args];
    while ([rs next]) {
        log = [[RecentLog alloc] init];
        log.id = [rs intForColumn:COLUMN_ID];
        log.accountId = [rs intForColumn:COLUMN_ACCOUNT_ID];
        log.contactId = [rs intForColumn:COLUMN_CONTACT_ID];
        log.number = [rs stringForColumn:COLUMN_NUMBER];
        log.type = [rs intForColumn:COLUMN_TYPE];
        log.datetime = [rs dateForColumn:COLUMN_DATETIME];
        log.duration = [rs intForColumn:COLUMN_DURATION];
        [logs addObject:log];
    }
    [rs close];
    [rs setParentDB:nil];
    return logs;
}

- (NSArray *)getRecentLogsOfContact:(Contact *)contact {
    NSString *clause = [NSString stringWithFormat:@"%@ = ?", COLUMN_CONTACT_ID];
    NSArray *args = [NSArray arrayWithObject:[NSNumber numberWithInteger:contact.id]];
    return [self recentLogsWhere:clause andArgument:args];
}

- (NSArray *)getMissedCallsOfContact:(Contact *)contact {
    NSString *clause = [NSString stringWithFormat:@"%@ = ? AND %@ IN (?, ?)", COLUMN_CONTACT_ID, COLUMN_TYPE];
    NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInteger:contact.id],
                     [NSNumber numberWithInteger:RecentLogType_Voice_Missed],
                     [NSNumber numberWithInteger:RecentLogType_Video_Missed], nil];
    return [self recentLogsWhere:clause andArgument:args];
}

- (BOOL)addRecentLog:(RecentLog *)recentLog {
    if (!recentLog) {
        UcaLog(TAG, @"Cannot add null RecentLog");
        return NO;
    }

    NSArray *cols = [NSArray arrayWithObjects:
                     COLUMN_ACCOUNT_ID,
                     COLUMN_CONTACT_ID,
                     COLUMN_NUMBER,
                     COLUMN_TYPE,
                     COLUMN_DATETIME,
                     COLUMN_DURATION, nil];
    NSArray *vals = [NSArray arrayWithObjects:
                     [NSNumber numberWithInteger:recentLog.accountId],
                     [NSNumber numberWithInteger:recentLog.contactId],
                     recentLog.number,
                     [NSNumber numberWithInteger:recentLog.type],
                     recentLog.datetime,
                     [NSNumber numberWithInteger:recentLog.duration], nil];
    recentLog.id = [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME];
    BOOL ok = (recentLog.id != NOT_SAVED);
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_ADD_RECENT_LOG object:recentLog];
    }
    return ok;
}

// TODO: optimize this method
- (NSString *)buildIds:(NSArray *)recentLogs {
    NSMutableString *ids = [[NSMutableString alloc] init];
    for (RecentLog *recentLog in recentLogs) {
        [ids appendFormat:@"%d,", recentLog.id];
    }
    [ids deleteCharactersInRange:NSMakeRange([ids length] - 1, 1)];
    return ids;
}

- (BOOL)deleteRecentLogs:(NSArray *)recentLogs {
    if (!recentLogs || recentLogs.count <= 0) {
        UcaLog(TAG, @"Cannot delete null or empty recentLogs");
        return NO;
    }

    NSMutableArray *ids = [NSMutableArray array];
    for (RecentLog *recentLog in recentLogs) {
        [ids addObject:[NSString stringWithFormat:@"%d", recentLog.id]];
    }

    NSString *clause = [NSString stringWithFormat:@"%@ IN (%@)", COLUMN_ID, [ids componentsJoinedByString:@","]];
    BOOL ok = [_dbService deleteRecordsWhere:clause andArguments:nil fromTable:TABLE_NAME];
    if (ok) {
        // alert listeners
        [NotifyUtils postNotificationWithName:UCA_EVENT_DELETE_RECENT_LOGS];
    }
    UcaLog(TAG, @"deleteRecentLogs:%d", ok);
    return ok;
}

- (BOOL)deleteRecentLogsOfContact:(Contact *)contact {
    if (!contact) {
        return NO;
    }

    NSArray *cols = [NSArray arrayWithObjects:COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, nil];
    NSArray *vals = [NSArray arrayWithObjects:[NSNumber numberWithInteger:contact.accountId],
                     [NSNumber numberWithInteger:contact.id], nil];
    BOOL ok = [_dbService deleteRecordsWhere:cols equals:vals fromTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_DELETE_RECENT_LOGS];
    }
    UcaLog(TAG, @"deleteRecentLogsOfContact:%d", ok);
    return ok;
}

- (BOOL)clearMissedCallsOfContact:(Contact *)contact {
    if (!contact) {
        UcaLog(TAG, @"[clearMissedCallsOfContact]Cannot set null contact");
        return NO;
    }

    NSString *clause = [NSString stringWithFormat:@"%@ = ? AND %@ = ? AND %@ IN (?, ?)",
                        COLUMN_ACCOUNT_ID, COLUMN_CONTACT_ID, COLUMN_TYPE];
    NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInteger:contact.accountId],
                     [NSNumber numberWithInteger:contact.id],
                     [NSNumber numberWithInteger:RecentLogType_Voice_Missed],
                     [NSNumber numberWithInteger:RecentLogType_Video_Missed], nil];
    BOOL ok = [_dbService deleteRecordsWhere:clause andArguments:args fromTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_DELETE_RECENT_LOGS];
    }
    UcaLog(TAG, @"clearMissedCallsOfContact:%d", ok);
    return ok;
}

- (BOOL)updateRecentLogType:(RecentLog *)recentLog {
    if (!recentLog) {
        return NO;
    }

    NSArray *cols = [NSArray arrayWithObject:COLUMN_TYPE];
    NSArray *vals = [NSArray arrayWithObject:[NSNumber numberWithInt:recentLog.type]];
    BOOL ok = [_dbService updateRecord:recentLog.id withColumns:cols andValues:vals inTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_RECENT_LOGS];
    }
    UcaLog(TAG, @"updateRecentLogType:%d", ok);
    return ok;
}

- (BOOL)updateRecentLogDuration:(RecentLog *)recentLog {
    if (!recentLog) {
        return NO;
    }

    NSArray *cols = [NSArray arrayWithObject:COLUMN_DURATION];
    NSArray *vals = [NSArray arrayWithObject:[NSNumber numberWithInt:recentLog.duration]];
    BOOL ok = [_dbService updateRecord:recentLog.id withColumns:cols andValues:vals inTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_RECENT_LOGS];
    }
    UcaLog(TAG, @"updateRecentLogDuration:%d", ok);
    return ok;
}

@end
