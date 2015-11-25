/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseAdditions.h"

#undef TAG
#define TAG @"UcaDatabaseService"

#undef DATABASE_NAME
#define DATABASE_NAME @"UcaDataBase.db"

/**
 * 'DATABASE_VERSION' defines the current version of the database on the source code (objective-c) view.
 * The database itself contains this reference. Each time the database service is loaded we check that these
 * two values are identical. If these two values are different then, we merge the database stored in the device
 * into new database.
 * You should increment this value if you change the database version.
 */
#define DATABASE_VERSION 0

void sqlite3_trace_callback(void *udp, const char *sql);

void sqlite3_trace_callback(void *udp, const char *sql) {
    printf("[SQL]%s\n", sql);
}

@implementation UcaDatabaseService {
    FMDatabaseQueue *_dbQueue;
}

static NSString *sDatabasePath = nil;
static BOOL sDatabaseInitialized = NO;

- (BOOL)openDatabase {
    if (_dbQueue) {
        UcaLog(TAG, @"database %@ is already opened", sDatabasePath);
        return YES;
    }

    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:sDatabasePath];
    if (!_dbQueue) {
        UcaLog(TAG, @"Failed to open database from: %@", sDatabasePath);
        return NO;
    }
    return YES;
}

- (BOOL)closeDatabase {
    if (_dbQueue) {
        [_dbQueue close], _dbQueue = nil;
    }
    return YES;
}

- (void)mergeDatabaseFrom:(NSString *)databasePath oldVersion:(int)oldVersion newVersion:(int)newVersion {
    if (!_dbQueue) {
        return;
    }

    // TODO: merge data from oldVersion database to newVersion database.
}

- (BOOL)setDatabaseVersion:(int)ver {
    __block BOOL ok = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        ok = [db executeUpdateWithFormat:@"PRAGMA user_version = %d", ver];
    }];
    return ok;
}

- (int)databaseVersion {
    __block int ver = -1;

    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"PRAGMA user_version;"];
        if ([rs next]) {
            ver = [rs intForColumnIndex:0];
            UcaLog(TAG, @"found database version = %d", ver);
            [rs close];
            [rs setParentDB:nil];
        }
    }];

    return ver;
}

- (BOOL)checkAndCreateDatabase {
    if (sDatabaseInitialized) {
        return YES;
    }

    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];

    sDatabasePath = [documentsDir stringByAppendingPathComponent:DATABASE_NAME];
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:sDatabasePath];
    if (!_dbQueue) {
        return NO;
    }

    int storedVersion = [self databaseVersion];
    int sourceCodeVersion = DATABASE_VERSION;
    NSString *oldDatabasePath = nil;

    if (storedVersion != sourceCodeVersion) {
        UcaLog(TAG, @"database changed v-stored = %i and database v-code = %i", storedVersion, sourceCodeVersion);
        [_dbQueue close], _dbQueue = nil;
        oldDatabasePath = [sDatabasePath stringByAppendingFormat:@"%d", storedVersion];
        if (![[NSFileManager defaultManager] copyItemAtPath:sDatabasePath toPath:oldDatabasePath error:nil]) {
            UcaLog(TAG, @"Failed to backup stored database.");
            return NO;
        }
    }

    // 如果之前整合了旧版本数据库的数据，此时_dbQueue为nil，重新开启新数据库。
    if (!_dbQueue) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:sDatabasePath];
        if (!_dbQueue) {
            return NO;
        }
    }

    [self setDatabaseVersion:sourceCodeVersion];
//    FIXME: [self setDatabaseVersion:sourceCodeVersion] always return NO;
//    if (![self setDatabaseVersion:sourceCodeVersion]) {
//        UcaLog(TAG, @"Failed to initialize database");
//        [_dbQueue close], _dbQueue = nil;
//        return NO;
//    }

    if (storedVersion != sourceCodeVersion) {
        [self mergeDatabaseFrom:oldDatabasePath
                     oldVersion:storedVersion
                     newVersion:sourceCodeVersion];
    }

    sDatabaseInitialized = YES;
    return YES;
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }

    if (![self checkAndCreateDatabase]) {
        return NO;
    }

    if (![self openDatabase]) {
        return NO;
    }

#ifdef DEBUG_SQL
    [_dbQueue inDatabase:^(FMDatabase *db) {
        sqlite3_trace(db.sqliteHandle, sqlite3_trace_callback, NULL);
    }];
#endif

    return YES;
}

- (BOOL)stop {
    UcaLog(TAG, @"Stop()");
    if (![super stop]) {
        return NO;
    }
    return [self closeDatabase];
}

- (BOOL)createTableIfNeeds:(NSString *)tableName columnInfos:(NSArray *)colInfos {
    if ([NSString isNullOrEmpty:tableName] || [colInfos count] == 0) {
        return NO;
    }

    __block NSMutableString *sql = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (", tableName];
    for (int i = 0; i < [colInfos count]; i += 2) {
        [sql appendFormat:@"%@ %@, ", [colInfos objectAtIndex:i], [colInfos objectAtIndex:(i + 1)]];
    }
    [sql replaceCharactersInRange:NSMakeRange([sql length] - 2, 2) withString:@")"];

    __block BOOL ok = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        ok = [db executeUpdate:sql];
    }];
    return ok;
}

- (BOOL)executeUpdate:(NSString*)sql {
    return [self executeUpdate:sql withArguments:nil];
}

- (BOOL)executeUpdate:(NSString*)sql withArguments:(NSArray *)arguments {
    __block BOOL ok = NO;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        ok = [db executeUpdate:sql withArgumentsInArray:arguments];
    }];
    return ok;
}

- (FMResultSet *)executeQuery:(NSString *)sql {
    return [self executeQuery:sql withArguments:nil];
}

- (FMResultSet *)executeQuery:(NSString *)sql withArguments:(NSArray *)arguments {
    __block FMResultSet *res = nil;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeQuery:sql withArgumentsInArray:arguments];
    }];
    return res;
}

- (NSString *)commaDelimitedArguments:(NSInteger)countOfArguments {
    NSMutableArray *exprs = [NSMutableArray array];

    for (int i = 0; i < countOfArguments; i++) {
        [exprs addObject:@"?"];
    }

    return [exprs componentsJoinedByString:@", "];
}

- (NSString *)columnInsertClause:(NSArray *)columns {
    return [self commaDelimitedArguments:[columns count]];
}

- (NSString *)columnUpdateClause:(NSArray *)columns {
    NSMutableArray *exprs = [NSMutableArray array];

    for (int i = 0; i < [columns count]; i++) {
        [exprs addObject:[NSString stringWithFormat:@"%@ = ?", [columns objectAtIndex:i]]];
    }

    return [exprs componentsJoinedByString:@", "];
}

- (NSString *)columnConditionClause:(NSArray *)columns {
    NSMutableArray *exprs = [NSMutableArray array];

    for (int i = 0; i < [columns count]; i++) {
        [exprs addObject:[NSString stringWithFormat:@"%@ = ?", [columns objectAtIndex:i]]];
    }

    return [exprs componentsJoinedByString:@" AND "];
}

- (NSInteger)addRecordWithColumns:(NSArray *)columns
                        andValues:(NSArray *)values
                          toTable:(NSString *)tableName {
    if ([columns count] != [values count] || [columns count] == 0) {
        return NOT_SAVED;
    }

    NSMutableString *sql = [NSMutableString stringWithFormat:@"INSERT INTO %@ (", tableName];
    [sql appendString:[columns componentsJoinedByString:@", "]];
    [sql appendString:@") VALUES ("];
    [sql appendString:[self columnInsertClause:columns]];
    [sql appendString:@")"];

    BOOL ok = [self executeUpdate:sql withArguments:values];
    __block NSInteger recId = NOT_SAVED;
    if (ok) {
        [_dbQueue inDatabase:^(FMDatabase *db) {
            recId = [db lastInsertRowId];
        }];
    }

    return recId;
}

- (BOOL)updateRecord:(NSInteger)recordId
         withColumns:(NSArray *)columns
           andValues:(NSArray *)values
             inTable:(NSString *)tableName {
    NSString *clause = [NSString stringWithFormat:@"%@ = ?", COLUMN_ID];
    NSArray *arguments = [values arrayByAddingObject:[NSNumber numberWithInteger:recordId]];
    return [self updateRecordsWithColumns:columns
                                    where:clause
                             andArguments:arguments
                                  inTable:tableName];
}

- (BOOL)updateRecordsWithColumns:(NSArray *)columns
                           where:(NSString *)clause
                    andArguments:(NSArray *)arguments
                         inTable:(NSString *)tableName {
    if ([columns count] == 0 || [NSString isNullOrEmpty:tableName]) {
        return NO;
    }

    NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", tableName];
    [sql appendString:[self columnUpdateClause:columns]];
    if (![NSString isNullOrEmpty:clause]) {
        [sql appendFormat:@" WHERE %@", clause];
    }

    return [self executeUpdate:sql withArguments:arguments];
}

- (BOOL)deleteRecord:(NSInteger)recordId fromTable:(NSString *)tableName {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", tableName, COLUMN_ID];
    return [self executeUpdate:sql withArguments:[NSArray arrayWithObject:[NSNumber numberWithInt:recordId]]];
}

- (BOOL)deleteRecordsWhere:(NSArray *)columns equals:(NSArray *)values fromTable:(NSString *)tableName {
    if ([columns count] != [values count]) {
        return NO;
    }

    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@", tableName];
    if ([columns count] != 0) {
        [sql appendFormat:@" WHERE %@", [self columnConditionClause:columns]];
    }
    return [self executeUpdate:sql withArguments:values];
}

- (BOOL)deleteRecordsWhere:(NSString *)clause
              andArguments:(NSArray *)arguments
                 fromTable:(NSString *)tableName {

    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@", tableName];
    if (![NSString isNullOrEmpty:clause]) {
        [sql appendFormat:@" WHERE %@", clause];
    }
    return [self executeUpdate:sql withArguments:arguments];
}

- (NSUInteger)countOfRecordsWhere:(NSArray *)columns
                           equals:(NSArray *)values
                          inTable:(NSString *)tableName {
    if ([columns count] != [values count]) {
        return 0;
    }

    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM %@", tableName];
    if ([columns count] != 0) {
        [sql appendFormat:@" WHERE %@", [self columnConditionClause:columns]];
    }

    NSUInteger count = 0;
    FMResultSet *rs = [self executeQuery:sql withArguments:values];
    if ([rs next]) {
        count = [rs intForColumnIndex:0];
    }
    [rs close];
    [rs setParentDB:nil];
    return count;
}

- (NSInteger)recordIdWhere:(NSArray *)columns
                    equals:(NSArray *)values
                   inTable:(NSString *)tableName {
    if ([columns count] != [values count]) {
        return NOT_SAVED;
    }

    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", COLUMN_ID, tableName];
    if ([columns count] != 0) {
        [sql appendFormat:@" WHERE %@", [self columnConditionClause:columns]];
    }

    NSInteger recId = NOT_SAVED;
    FMResultSet *rs = [self executeQuery:sql withArguments:values];
    if ([rs next]) {
        recId = [rs intForColumnIndex:0];
    }
    [rs close];
    [rs setParentDB:nil];
    return recId;
}

- (NSArray *)recordIdsWhere:(NSString *)clause
               andArguments:(NSArray *)arguments
                    inTable:(NSString *)tableName {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", COLUMN_ID, tableName];
    if (![NSString isNullOrEmpty:clause]) {
        [sql appendFormat:@" WHERE %@", clause];
    }

    NSMutableArray *ids = [NSMutableArray array];
    FMResultSet *rs = [self executeQuery:sql withArguments:arguments];
    while ([rs next]) {
        [ids addObject:[NSNumber numberWithInt:[rs intForColumnIndex:0]]];
    }
    [rs close];
    [rs setParentDB:nil];

    return [ids count] > 0 ? ids : nil;
}

@end
