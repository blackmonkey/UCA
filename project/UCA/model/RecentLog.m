/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation RecentLog

@synthesize id;
@synthesize accountId;
@synthesize contactId;
@synthesize number;
@synthesize type;
@synthesize datetime;
@synthesize duration;
@synthesize missed;

- (id)init {
    if (self = [super init]) {
        self.id = NOT_SAVED;
        self.accountId = [UcaAppDelegate sharedInstance].accountService.curAccountId;
        self.contactId = NOT_SAVED;
        self.number = @"";
        self.datetime = [NSDate date];
        self.duration = 0;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[RecentLog class]]) {
        RecentLog *recentLog = (RecentLog *)object;
        if (self.id == recentLog.id) {
            return  YES;
        }
    }

    return NO;
}

- (BOOL)isMissed {
    return self.type == RecentLogType_Voice_Missed || self.type == RecentLogType_Video_Missed;
}

@end
