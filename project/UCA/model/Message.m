/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation Message

@synthesize image;
@synthesize imageName;
@synthesize senderName;
@synthesize sender;
@synthesize receiver;
@synthesize toWhom;
@synthesize read;
@synthesize received;
@synthesize sending;
@synthesize sent;
@synthesize sentFailed;
@synthesize id;
@synthesize accountId;
@synthesize status;
@synthesize senderSip;
@synthesize receiverSip;
@synthesize toWhomSip;
@synthesize datetime;
@synthesize html;

- (id)init {
    self = [super init];
    if (self) {
        self.id = NOT_SAVED;
        self.accountId = [UcaAppDelegate sharedInstance].accountService.curAccountId;
        self.datetime = [NSDate date];
        self.senderSip = @"";
        self.receiverSip = @"";
        self.toWhomSip = @"";
    }

    return self;
}

- (id)initWithReceiverSipPhone:(NSString *)sipPhone {
    self = [self init];
    if (self) {
        self.status = Message_Sending;
        self.receiverSip = sipPhone;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Message class]]) {
        return NO;
    }

    Message *theOther = (Message *)object;
    if (self.id == theOther.id) {
        return YES;
    }
    return (accountId == theOther.accountId)
            && (status == theOther.status)
            && [senderSip isEqualToString:theOther.senderSip]
            && [receiverSip isEqualToString:theOther.receiverSip]
            && [datetime isEqual:theOther.datetime]
            && [html isEqualToString:theOther.html];
}

- (NSString *)senderName {
    return self.sender.displayName;
}

- (Person *)getContactBySipPhone:(NSString *)sipPhone {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    Account *curAccount = app.accountService.currentAccount;

    if ([NSString isNullOrEmpty:sipPhone] || [sipPhone isEqualToString:curAccount.sipPhone]) {
        return curAccount;
    }

    Contact *contact = [app.contactService getContactBySipPhone:sipPhone];
    if (!contact) {
        contact = [[Contact alloc] init];
        contact.sipPhone = sipPhone;

        if ([sender.sipPhone hasPrefix:@"img-"]) {
            contact.contactType = ContactType_Group;
        } else if ([sender.sipPhone hasPrefix:@"imc-"]) {
            contact.contactType = ContactType_Session;
        } else {
            contact.contactType = ContactType_Unknown;
        }
    }
    return contact;
}

- (Person *)sender {
    return [self getContactBySipPhone:senderSip];
}

- (Person *)receiver {
    return [self getContactBySipPhone:receiverSip];
}

- (Person *)toWhom {
    return [self getContactBySipPhone:toWhomSip];
}

- (void)setRead:(BOOL)yes {
    status = (yes ? Message_Received_Read : Message_Received_Unread);
}

- (BOOL)isRead {
    // 发出的IM也视为已读
    return status != Message_Received_Unread;
}

- (BOOL)isReceived {
    return status == Message_Received_Read || status == Message_Received_Unread;
}

- (BOOL)isSending {
    return status == Message_Sending;
}

- (BOOL)isSent {
    return status == Message_Sent;
}

- (BOOL)isSentFailed {
    return status == Message_SendFailed;
}

- (BOOL)hasToWhom {
    return ![NSString isNullOrEmpty:self.toWhomSip];
}

@end
