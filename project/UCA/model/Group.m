/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation Group

@synthesize id;
@synthesize userId;
@synthesize name;
@synthesize fileSpaceSize;
@synthesize creator;
@synthesize createTime;
@synthesize userCount;
@synthesize userMaxAmount;
@synthesize type;
@synthesize canAdmin;
@synthesize canUpload;
@synthesize photo;
@synthesize annunciate;
@synthesize descrip;
@synthesize administrators;
@synthesize contacts;
@synthesize unreadCount;
@synthesize countInfo;
@synthesize sipPhone;

- (id)init {
    self = [super init];
    if (self) {
        self.id = NOT_SAVED;
        self.userId = NOT_SAVED;
        self.administrators = [NSMutableArray array];
        self.contacts = [NSMutableArray array];
        self.name = @"";
        self.creator = @"";
        self.createTime = @"";
        self.type = @"";
        self.annunciate = @"";
        self.descrip = @"";
    }
    return self;
}

- (id)initWithContact:(Contact *)contact {
    if (self = [self init]) {
        self.id = contact.id;
        self.userId = contact.userId;
        self.name = contact.firstname;
        self.photo = contact.photo;
        self.descrip = contact.descrip;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Group class]]) {
        return NO;
    }

    Group *theOther = (Group *)object;
    return self.id == theOther.id;
}

- (void)dealloc {
    [self.administrators removeAllObjects];
    [self.contacts removeAllObjects];
}

- (NSString *)countInfo {
    NSUInteger onlineCount = 0;
    @synchronized (self.contacts) {
        for (Contact *contact in self.contacts) {
            if (contact.presentation != UCALIB_PRESENTATIONSTATE_OFFLINE) {
                onlineCount++;
            }
        }
    }
    return [NSString stringWithFormat:@"%d/%d", onlineCount, self.userCount];
}

- (NSString *)name {
    if ([NSString isNullOrEmpty:self->name]) {
        return [NSString stringWithFormat:I18nString(@"固定群组%d"), self.id];
    }
    return self->name;
}

- (NSString *)sipPhone {
    if ([NSString isNullOrEmpty:self->sipPhone]) {
        Account *curAccount = [UcaAppDelegate sharedInstance].accountService.currentAccount;
        if (curAccount && [curAccount.serverDomain length] > 0) {
            return [NSString stringWithFormat:@"img-%d@%@", self.userId, curAccount.serverDomain];
        }
        return [NSString stringWithFormat:@"img-%d", self.userId];
    }
    return self->sipPhone;
}

- (NSUInteger)unreadCount {
    Contact *contact = [[Contact alloc] initWithGroup:self];
    return [[UcaAppDelegate sharedInstance].messageService countOfUnreadMessagesWithContact:contact];
}

- (void)addContact:(Contact *)contact {
    if (contact == nil) {
        return;
    }
    @synchronized (self.contacts) {
        [self.contacts addObject:contact];
    }
}

- (void)addContacts:(NSArray *)otherContacts {
    if (otherContacts == nil) {
        return;
    }
    @synchronized (self.contacts) {
        [self.contacts addObjectsFromArray:otherContacts];
    }
}

- (void)removeContacts:(NSArray *)otherContacts {
    if (otherContacts == nil) {
        return;
    }
    @synchronized (self.contacts) {
        [self.contacts removeObjectsInArray:otherContacts];
    }
}

@end
