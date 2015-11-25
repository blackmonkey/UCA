/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"Account"

@implementation Account

@synthesize serverParam;
@synthesize rememberPassword;
@synthesize password;
@synthesize serverDomain;
@synthesize customHisotlogy;
@synthesize privileges;

- (id)init {
    self = [super init];
    if (self) {
        self.serverParam = [[ServerParam alloc] init];
        self.privileges = [[Privilege alloc] init];
        self.password = @"";
        self.serverDomain = @"";
        self.customHisotlogy = @"";
        self.showPersonalInfo = YES;
        self.rememberPassword = NO;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[Account class]]) {
        Account *account = (Account *)object;
        return self.id == account.id;
    }

    return NO;
}

- (NSString *)displayName {
    if (self.id == [UcaAppDelegate sharedInstance].accountService.curAccountId) {
        return I18nString(@"我");
    }
    return [super displayName];
}

@end
