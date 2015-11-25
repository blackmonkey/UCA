/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation Session

@synthesize id;
@synthesize sipPhone;
@synthesize contacts;
@synthesize unreadCount;
@synthesize descrip;
@synthesize name;
@synthesize countInfo;

- (id)init {
    self = [super init];
    if (self) {
        self.id = NOT_SAVED;
        self.contacts = [NSMutableArray array];
        self.sipPhone = @"";
    }

    return self;
}

- (id)initWithContact:(Contact *)contact {
    if (self = [self init]) {
        self.id = contact.userId;
        self.sipPhone = contact.sipPhone;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Session class]]) {
        return NO;
    }

    Session *theOther = (Session *)object;
    return self.id == theOther.id;
}

- (void)dealloc {
    [self.contacts removeAllObjects];
}

- (NSUInteger)unreadCount {
    Contact *contact = [[Contact alloc] initWithSession:self];
    return [[UcaAppDelegate sharedInstance].messageService countOfUnreadMessagesWithContact:contact];
}

- (NSString *)descrip  {
    NSMutableArray *names = [NSMutableArray array];
    for (Contact *contact in self.contacts) {
        [names addObject:contact.displayName];
    }
    return [names componentsJoinedByString:@", "];
}

- (NSString *)name {
    return [NSString stringWithFormat:I18nString(@"多人会话%d"), self.id];
}

- (NSString *)countInfo {
    NSUInteger onlineCount = 0;
    NSUInteger totalCount = self.contacts.count;
    for (Contact *contact in self.contacts) {
        if (contact.presentation != UCALIB_PRESENTATIONSTATE_OFFLINE) {
            onlineCount++;
        }
    }
    return [NSString stringWithFormat:@"%d/%d", onlineCount, totalCount];
}

- (NSString *)sipPhone {
    if ([NSString isNullOrEmpty:self->sipPhone]) {
        Account *curAccount = [UcaAppDelegate sharedInstance].accountService.currentAccount;
        if (curAccount && [curAccount.serverDomain length] > 0) {
            return [NSString stringWithFormat:@"imc-%d@%@", self.id, curAccount.serverDomain];
        }
        return [NSString stringWithFormat:@"imc-%d", self.id];
    }
    return self->sipPhone;
}

- (void)addContacts:(NSArray *)otherContacts {
    @synchronized (self.contacts) {
        [self.contacts addObjectsFromArray:otherContacts];
    }
}

- (void)removeContacts:(NSArray *)otherContacts {
    @synchronized (self.contacts) {
        [self.contacts removeObjectsInArray:otherContacts];
    }
}

@end
