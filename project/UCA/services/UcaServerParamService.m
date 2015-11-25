/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"UcaServerParamService"

#undef TABLE_NAME
#define TABLE_NAME @"ServerParam"

#define COLUMN_IP @"ip"

@implementation UcaServerParamService {
    UcaDatabaseService *_dbService;
}

@synthesize serverIps;

- (id)init {
    self = [super init];
    if (self) {
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
                         COLUMN_IP, @"INTEGER",
                         nil];
    if (![_dbService createTableIfNeeds:TABLE_NAME columnInfos:colInfos]) {
        UcaLog(TAG, @"Failed to create table %@", TABLE_NAME);
        return NO;
    }
    return YES;
}

- (NSInteger)addParamWithIp:(NSString *)ip {
    return [_dbService addRecordWithColumns:[NSArray arrayWithObject:COLUMN_IP]
                                  andValues:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[NSString ipWithString:ip]]]
                                    toTable:TABLE_NAME];
}

- (BOOL)updateParamById:(NSInteger)id withValue:(NSString *)ip{
    return [_dbService updateRecord:id
                        withColumns:[NSArray arrayWithObject:COLUMN_IP]
                        andValues:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[NSString ipWithString:ip]]]
                        inTable:TABLE_NAME];
}

- (NSInteger)paramIdByIp:(NSString *)ip {
    return [_dbService recordIdWhere:[NSArray arrayWithObject:COLUMN_IP]
                              equals:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[NSString ipWithString:ip]]]
                             inTable:TABLE_NAME];
}

- (NSArray *)serverIps {
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ ORDER BY %@ DESC", COLUMN_IP, TABLE_NAME, COLUMN_ID];
    NSMutableArray *ips = [NSMutableArray array];
    FMResultSet *rs = [_dbService executeQuery:sql];
    while ([rs next]) {
        [ips addObject:[NSString stringWithIp:[rs intForColumn:COLUMN_IP]]];
    }
    [rs close];
    [rs setParentDB:nil];
    return ips;
}

@end
