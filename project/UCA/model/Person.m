/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"Person"

@implementation Person

@synthesize id;
@synthesize presentation;
@synthesize displayName;
@synthesize userId;
@synthesize username;
@synthesize firstname;
@synthesize lastname;
@synthesize nickname;
@synthesize aliases;
@synthesize isFemale;
@synthesize descrip;
@synthesize photo;
@synthesize pin;
@synthesize groupId;
@synthesize groups;
@synthesize callMode;
@synthesize sipPhone;
@synthesize workPhone;
@synthesize familyPhone;
@synthesize mobilePhone;
@synthesize mobilePhone2;
@synthesize otherPhone;
@synthesize email;
@synthesize voicemail;
@synthesize company;
@synthesize companyAddress;
@synthesize departId;
@synthesize departName;
@synthesize position;
@synthesize familyAddress;
@synthesize showPersonalInfo;

- (id)init {
    self = [super init];
    if (self) {
        self.id = NOT_SAVED;
        self.userId = NOT_SAVED;
        self.departId = NOT_SAVED;
        self.presentation = UCALIB_PRESENTATIONSTATE_OFFLINE;
        self.username = @"";
        self.firstname = @"";
        self.lastname = @"";
        self.nickname = @"";
        self.descrip = @"";
        self.pin = @"";
        self.sipPhone = @"";
        self.workPhone = @"";
        self.familyPhone = @"";
        self.mobilePhone = @"";
        self.mobilePhone2 = @"";
        self.otherPhone = @"";
        self.email = @"";
        self.voicemail = @"";
        self.company = @"";
        self.companyAddress = @"";
        self.departName = @"";
        self.position = @"";
        self.familyAddress = @"";
        self.aliases = [NSArray array];
        self.groups = [NSArray array];
    }
    return self;
}

- (NSString *)displayName {
    BOOL hasFirstname = ![NSString isNullOrEmpty:self.firstname];
    BOOL hasLastname = ![NSString isNullOrEmpty:self.lastname];
    BOOL hasCnChr = ([self.firstname containsChinese] | [self.lastname containsChinese]);
    if (hasFirstname && hasLastname) {
        if (hasCnChr) {
            return [NSString stringWithFormat:@"%@ %@", self.lastname, self.firstname];
        }
        return [NSString stringWithFormat:@"%@ %@", self.firstname, self.lastname];
    } else if (hasFirstname) {
        return self.firstname;
    } else if (hasLastname) {
        return self.lastname;
    } else if (![NSString isNullOrEmpty:self.username]) {
        return self.username;
    }

    return [[self.sipPhone componentsSeparatedByString:@"@"] objectAtIndex:0];
}

@end
