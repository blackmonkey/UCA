/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation Contact

@synthesize accountId;
@synthesize contactType;
@synthesize accessed;
@synthesize accessedDbVal;
@synthesize unreadMessageCount;
@synthesize listDescription;
@synthesize cameraOn;
@synthesize voicemailOn;

- (id)init {
    if (self = [super init]) {
        self.accountId = [UcaAppDelegate sharedInstance].accountService.curAccountId;
        self.contactType = ContactType_Unknown;
        self.accessed = nil;
    }
    return self;
}

- (id)initWithGroup:(Group *)group {
    if (self = [self init]) {
        self.id = group.id;
        self.contactType = ContactType_Group;
        self.userId = group.userId;
        self.firstname = group.name;
        self.photo = group.photo;
        self.descrip = group.descrip;
        self.sipPhone = group.sipPhone;
    }
    return self;
}

- (id)initWithSession:(Session *)session {
    if (self = [self init]) {
        self.contactType = ContactType_Session;
        self.userId = session.id;
        self.firstname = session.name;
        self.descrip = session.descrip;
        self.sipPhone = session.sipPhone;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Contact class]]) {
        return NO;
    }

    Contact *contact = (Contact *)object;
    if (self.id == contact.id) {
        if (self.id == NOT_SAVED) {
            return self.userId == contact.userId;
        }
        return YES;
    }
    if (self.id == ORG_CONTACT_ID) {
        return self.userId == contact.userId;
    }
    return NO;
}
/*
- (NSString *)description {
    NSMutableString *res = [[NSMutableString alloc] init];

    [res appendString:@"--------------------\n"];
    [res appendFormat:@"id = %d\n", self.id];
    [res appendFormat:@"accountId = %d\n", self.accountId];
    [res appendFormat:@"contactType = %d\n", self.contactType];
    [res appendFormat:@"accessed = %@\n", self.accessed];
    [res appendFormat:@"unreadMessageCount = %d\n", self.unreadMessageCount];
    [res appendFormat:@"cameraOn = %d\n", self.cameraOn];
    [res appendFormat:@"userId = %d\n", self.userId];
    [res appendFormat:@"username = %@\n", self.username];
    [res appendFormat:@"firstname = %@\n", self.firstname];
    [res appendFormat:@"lastname = %@\n", self.lastname];
    [res appendFormat:@"nickname = %@\n", self.nickname];
    [res appendFormat:@"aliases = %@\n", self.aliases];
    [res appendFormat:@"isFemale = %d\n", self.isFemale];
    [res appendFormat:@"descrip = %@\n", self.descrip];
    [res appendFormat:@"photo = %@\n", self.photo];
    [res appendFormat:@"pin = %@\n", self.pin];
    [res appendFormat:@"groupId = %d\n", self.groupId];
    [res appendFormat:@"groups = %@\n", self.groups];
    [res appendFormat:@"callMode = %d\n", self.callMode];
    [res appendFormat:@"sipPhone = %@\n", self.sipPhone];
    [res appendFormat:@"workPhone = %@\n", self.workPhone];
    [res appendFormat:@"familyPhone = %@\n", self.familyPhone];
    [res appendFormat:@"mobilePhone = %@\n", self.mobilePhone];
    [res appendFormat:@"mobilePhone2 = %@\n", self.mobilePhone2];
    [res appendFormat:@"otherPhone = %@\n", self.otherPhone];
    [res appendFormat:@"email = %@\n", self.email];
    [res appendFormat:@"voicemail = %@\n", self.voicemail];
    [res appendFormat:@"company = %@\n", self.company];
    [res appendFormat:@"companyAddress = %@\n", self.companyAddress];
    [res appendFormat:@"departId = %d\n", self.departId];
    [res appendFormat:@"departName = %@\n", self.departName];
    [res appendFormat:@"position = %@\n", self.position];
    [res appendFormat:@"familyAddress = %@\n", self.familyAddress];
    [res appendFormat:@"showPersonalInfo = %d\n", self.showPersonalInfo];

    return res;
}
*/
- (NSString *)listDescription {
    if (![NSString isNullOrEmpty:self.descrip]) {
        return self.descrip;
    }
    if (![NSString isNullOrEmpty:self.familyPhone]) {
        return self.familyPhone;
    }
    if (![NSString isNullOrEmpty:self.mobilePhone]) {
        return self.mobilePhone;
    }
    if (![NSString isNullOrEmpty:self.mobilePhone2]) {
        return self.mobilePhone2;
    }
    if (![NSString isNullOrEmpty:self.otherPhone]) {
        return self.otherPhone;
    }
    if (![NSString isNullOrEmpty:self.workPhone]) {
        return self.workPhone;
    }
    return self.sipPhone;
}

- (id)accessedDbVal {
    if (self.accessed == nil) {
        return [NSNumber numberWithInt:0];
    }
    return self.accessed;
}

- (NSUInteger)unreadMessageCount {
    return [[UcaAppDelegate sharedInstance].messageService countOfUnreadMessagesWithContact:self];
}

- (void)copyDataFromPerson:(Person *)person {
    self.userId = person.userId;
    self.username = person.username;
    self.firstname = person.firstname;
    self.lastname = person.lastname;
    self.nickname = person.nickname;
    self.aliases = person.aliases;
    self.isFemale = person.isFemale;
    self.descrip = person.descrip;
    self.photo = person.photo;
    self.pin = person.pin;
    self.groupId = person.groupId;
    self.groups = person.groups;
    self.callMode = person.callMode;
    self.sipPhone = person.sipPhone;
    self.workPhone = person.workPhone;
    self.familyPhone = person.familyPhone;
    self.mobilePhone = person.mobilePhone;
    self.mobilePhone2 = person.mobilePhone2;
    self.otherPhone = person.otherPhone;
    self.email = person.email;
    self.voicemail = person.voicemail;
    self.company = person.company;
    self.companyAddress = person.companyAddress;
    self.departId = person.departId;
    self.departName = person.departName;
    self.position = person.position;
    self.familyAddress = person.familyAddress;
    self.showPersonalInfo = person.showPersonalInfo;
}

- (void)copyDataFromABRecord:(ABRecordRef)person {
    CFStringRef abLabel, abVal;

    self.userId = ABRecordGetRecordID(person);

    abVal = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    self.firstname = CFTYPEREF_TO_ID(abVal);
    UcaCFRelease(abVal);

    abVal = ABRecordCopyValue(person, kABPersonLastNameProperty);
    self.lastname = CFTYPEREF_TO_ID(abVal);
    UcaCFRelease(abVal);

    abVal = ABRecordCopyValue(person, kABPersonNicknameProperty);
    self.nickname = CFTYPEREF_TO_ID(abVal);
    UcaCFRelease(abVal);

    abVal = ABRecordCopyValue(person, kABPersonNoteProperty);
    self.descrip = CFTYPEREF_TO_ID(abVal);
    UcaCFRelease(abVal);

    if (ABPersonHasImageData(person)) {
        CFDataRef imgData = ABPersonCopyImageData(person);
        self.photo = [UIImage imageWithData:[NSData dataWithBytes:CFDataGetBytePtr(imgData)
                                                           length:CFDataGetLength(imgData)]];
        UcaCFRelease(imgData);
    }

    /** 记录电话号码信息 */
    ABMutableMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(multi); i++) {
        abLabel = ABMultiValueCopyLabelAtIndex(multi, i);
        abVal = ABMultiValueCopyValueAtIndex(multi, i);

        if (kCFCompareEqualTo == CFStringCompare(abLabel, kABPersonPhoneIPhoneLabel, kCFCompareCaseInsensitive)) {
            self.mobilePhone = CFTYPEREF_TO_ID(abVal);
        } else if (kCFCompareEqualTo == CFStringCompare(abLabel, kABPersonPhoneMobileLabel, kCFCompareCaseInsensitive)) {
            self.mobilePhone2 = CFTYPEREF_TO_ID(abVal);
        } else if (kCFCompareEqualTo == CFStringCompare(abLabel, kABHomeLabel, kCFCompareCaseInsensitive)) {
            self.familyPhone = CFTYPEREF_TO_ID(abVal);
        } else if (kCFCompareEqualTo == CFStringCompare(abLabel, kABWorkLabel, kCFCompareCaseInsensitive)) {
            self.workPhone = CFTYPEREF_TO_ID(abVal);
        } else if (kCFCompareEqualTo == CFStringCompare(abLabel, kABOtherLabel, kCFCompareCaseInsensitive)) {
            self.otherPhone = CFTYPEREF_TO_ID(abVal);
        }

        UcaCFRelease(abVal);
        UcaCFRelease(abLabel);
    }
    UcaCFRelease(multi);

    /** 仅记录第一条Email信息 */
    multi = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(multi) > 0) {
        abVal = ABMultiValueCopyValueAtIndex(multi, 0);
        self.email = CFTYPEREF_TO_ID(abVal);
        UcaCFRelease(abVal);
    }
    UcaCFRelease(multi);

    abVal = ABRecordCopyValue(person, kABPersonOrganizationProperty);
    self.company = CFTYPEREF_TO_ID(abVal);
    UcaCFRelease(abVal);

    abVal = ABRecordCopyValue(person, kABPersonDepartmentProperty);
    self.departName = CFTYPEREF_TO_ID(abVal);
    UcaCFRelease(abVal);

    abVal = ABRecordCopyValue(person, kABPersonJobTitleProperty);
    self.position = CFTYPEREF_TO_ID(abVal);
    UcaCFRelease(abVal);

    multi = ABRecordCopyValue(person, kABPersonAddressProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(multi); i++) {
        abLabel = ABMultiValueCopyLabelAtIndex(multi, i);

        BOOL isHome = (kCFCompareEqualTo == CFStringCompare(abLabel, kABHomeLabel, kCFCompareCaseInsensitive));
        BOOL isWork = (kCFCompareEqualTo == CFStringCompare(abLabel, kABWorkLabel, kCFCompareCaseInsensitive));

        if (isHome || isWork) {
            CFDictionaryRef abAddr = ABMultiValueCopyValueAtIndex(multi, i);
            if (CFDictionaryGetValueIfPresent(abAddr, kABPersonAddressStreetKey, (const void **)&abVal)) {
                if (isHome) {
                    self.familyAddress = CFTYPEREF_TO_ID(abVal);
                } else if (isWork) {
                    self.companyAddress = CFTYPEREF_TO_ID(abVal);
                }
                UcaCFRelease(abVal);
            }
            UcaCFRelease(abAddr);
        }

        UcaCFRelease(abLabel);
    }
    UcaCFRelease(multi);
}

- (void)copyDataToABRecord:(ABRecordRef)person {
    CFStringRef abLabel, abVal;

    ABRecordSetValue(person, kABPersonFirstNameProperty, ID_TO_CFTYPEREF(self.firstname), NULL);
    ABRecordSetValue(person, kABPersonLastNameProperty, ID_TO_CFTYPEREF(self.lastname), NULL);
    ABRecordSetValue(person, kABPersonNicknameProperty, ID_TO_CFTYPEREF(self.nickname), NULL);
    ABRecordSetValue(person, kABPersonNoteProperty, ID_TO_CFTYPEREF(self.descrip), NULL);

    if (self.photo) {
        NSData *data = UIImagePNGRepresentation(self.photo);
        CFDataRef imgData = CFDataCreate(NULL, data.bytes, data.length);
        ABPersonSetImageData(person, imgData, NULL);
        UcaCFRelease(imgData);
    } else {
        ABPersonRemoveImageData(person, NULL);
    }

    /** 记录电话号码信息 */
    BOOL hasNewValue = NO;
    ABMutableMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(multi); i++) {
        abLabel = ABMultiValueCopyLabelAtIndex(multi, i);

        if (kCFCompareEqualTo == CFStringCompare(abLabel, kABPersonPhoneIPhoneLabel, kCFCompareCaseInsensitive)) {
            abVal = ID_TO_CFTYPEREF(self.mobilePhone);
            hasNewValue = YES;
        } else if (kCFCompareEqualTo == CFStringCompare(abLabel, kABPersonPhoneMobileLabel, kCFCompareCaseInsensitive)) {
            abVal = ID_TO_CFTYPEREF(self.mobilePhone2);
            hasNewValue = YES;
        } else if (kCFCompareEqualTo == CFStringCompare(abLabel, kABHomeLabel, kCFCompareCaseInsensitive)) {
            abVal = ID_TO_CFTYPEREF(self.familyPhone);
            hasNewValue = YES;
        } else if (kCFCompareEqualTo == CFStringCompare(abLabel, kABWorkLabel, kCFCompareCaseInsensitive)) {
            abVal = ID_TO_CFTYPEREF(self.workPhone);
            hasNewValue = YES;
        } else if (kCFCompareEqualTo == CFStringCompare(abLabel, kABOtherLabel, kCFCompareCaseInsensitive)) {
            abVal = ID_TO_CFTYPEREF(self.otherPhone);
            hasNewValue = YES;
        }

        if (hasNewValue) {
            if (CFStringGetLength(abVal) == 0) {
                ABMultiValueRemoveValueAndLabelAtIndex(multi, i);
            } else {
                ABMultiValueReplaceValueAtIndex(multi, abVal, i);
            }
        }

        UcaCFRelease(abVal);
        UcaCFRelease(abLabel);
    }
    UcaCFRelease(multi);

    /** 仅记录第一条Email信息 */
    if ([self.email length] > 0) {
        multi = ABRecordCopyValue(person, kABPersonEmailProperty);
        if (ABMultiValueGetCount(multi) > 0) {
            ABMultiValueReplaceValueAtIndex(multi, ID_TO_CFTYPEREF(self.email), 0);
        } else {
            ABMultiValueAddValueAndLabel(multi, ID_TO_CFTYPEREF(self.email), kABHomeLabel, NULL);
        }
        UcaCFRelease(multi);
    }

    ABRecordSetValue(person, kABPersonOrganizationProperty, ID_TO_CFTYPEREF(self.company), NULL);
    ABRecordSetValue(person, kABPersonDepartmentProperty, ID_TO_CFTYPEREF(self.departName), NULL);
    ABRecordSetValue(person, kABPersonJobTitleProperty, ID_TO_CFTYPEREF(self.position), NULL);

    multi = ABRecordCopyValue(person, kABPersonAddressProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(multi); i++) {
        abLabel = ABMultiValueCopyLabelAtIndex(multi, i);

        BOOL isHome = (kCFCompareEqualTo == CFStringCompare(abLabel, kABHomeLabel, kCFCompareCaseInsensitive));
        BOOL isWork = (kCFCompareEqualTo == CFStringCompare(abLabel, kABWorkLabel, kCFCompareCaseInsensitive));

        if (isHome || isWork) {
            CFMutableDictionaryRef abAddr = (CFMutableDictionaryRef)ABMultiValueCopyValueAtIndex(multi, i);
            BOOL hasOldValue = CFDictionaryGetValueIfPresent(abAddr, kABPersonAddressStreetKey, (const void **)&abVal);
            UcaCFRelease(abVal);

            if (isHome) {
                abVal = ID_TO_CFTYPEREF(self.familyAddress);
            } else if (isWork) {
                abVal = ID_TO_CFTYPEREF(self.companyAddress);
            }

            if (hasOldValue) {
                if (CFStringGetLength(abVal) == 0) {
                    CFDictionaryRemoveValue(abAddr, kABPersonAddressStreetKey);
                } else {
                    CFDictionaryReplaceValue(abAddr, kABPersonAddressStreetKey, abVal);
                }
            } else if (CFStringGetLength(abVal) > 0) {
                CFDictionaryAddValue(abAddr, kABPersonAddressStreetKey, abVal);
            }

            ABMultiValueReplaceValueAtIndex(multi, abAddr, i);

            UcaCFRelease(abVal);
            UcaCFRelease(abAddr);
        }

        UcaCFRelease(abLabel);
    }
    ABRecordSetValue(person, kABPersonAddressProperty, multi, NULL);
    UcaCFRelease(multi);
}

- (NSComparisonResult)compareWithContact:(Contact *)theOther {
    if (self.presentation != theOther.presentation) {
        return self.presentation < theOther.presentation ? NSOrderedAscending : NSOrderedDescending;
    }
    return [self.displayName compare:theOther.displayName];
}

- (NSString *)numberMatched:(NSString *)pattern {
    NSArray *numbers = [NSArray arrayWithObjects:self.sipPhone, self.workPhone, self.familyPhone, self.mobilePhone, self.mobilePhone2, self.otherPhone, nil];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"self contains %@", pattern];
    NSArray *res = [numbers filteredArrayUsingPredicate:filter];
    if (res.count > 0) {
        return [res objectAtIndex:0];
    }
    return nil;
}

- (NSString *)firstValidPhonenumber {
    if (![NSString isNullOrEmpty:self.sipPhone]) {
        return self.sipPhone;
    }
    if (![NSString isNullOrEmpty:self.workPhone]) {
        return self.workPhone;
    }
    if (![NSString isNullOrEmpty:self.familyPhone]) {
        return self.familyPhone;
    }
    if (![NSString isNullOrEmpty:self.mobilePhone]) {
        return self.mobilePhone;
    }
    if (![NSString isNullOrEmpty:self.mobilePhone2]) {
        return self.mobilePhone2;
    }
    return self.otherPhone;
}

@end
