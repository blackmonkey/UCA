/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"UcaSessionService"

#define POST_DELAY 30

@implementation UcaSessionService {
    NSArray *_opContacts;
    Session *_opSession;
}

@synthesize sessions;

- (id)init {
    self = [super init];
    if (self) {
        sessions = [NSMutableArray array];
    }

    return self;
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMemeberChanged:)
                                                 name:UCA_NATIVE_SESSION_MEMBER_CHANGED
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMemeberPresentation:)
                                                 name:UCA_NATIVE_SESSION_PRESENTATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSessionStatusChanged:)
                                                 name:UCA_NATIVE_SESSION_STATUS
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

- (void)onMemeberChanged:(NSNotification *)note {
    NSString *xml = note.object;
    GroupChangeInfo *info = [XmlUtils parseGroupChangeInfo:[xml UTF8String]];
    UcaContactService *service = [UcaAppDelegate sharedInstance].contactService;
    BOOL notify = NO;
    @synchronized (self.sessions) {
        for (Session *s in self.sessions) {
            if (s.id != info.groupId) {
                continue;
            }
            notify = YES;

            s.sipPhone = info.groupSipPhone;

            NSPredicate *filter = [NSPredicate predicateWithFormat:@"sipPhone in %@", info.kickedUserSip];
            NSArray *filteredContacts = [s.contacts filteredArrayUsingPredicate:filter];
            [s removeContacts:filteredContacts];

            // Find members already in the session
            filter = [NSPredicate predicateWithFormat:@"sipPhone in %@", info.presentUserSip];
            filteredContacts = [s.contacts filteredArrayUsingPredicate:filter];

            NSMutableArray *filteredSips = [NSMutableArray array];
            for (Contact *c in filteredContacts) {
                [filteredSips addObject:c.sipPhone];
                [service touchContactBySipPhone:c.sipPhone];
            }

            // Remove the members already in the session, then we get the new members
            [info.presentUserSip removeObjectsInArray:filteredSips];
            for (NSString *sipPhone in info.presentUserSip) {
                Contact *c = [service touchContactBySipPhone:sipPhone];
                [s addContacts:[NSArray arrayWithObject:c]];
            }
        }

        if (notify) {
            [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_UPDATED];
        }
    }
}

- (void)onMemeberPresentation:(NSNotification *)note {
    NSString *xmlMsg = note.object;
    NSMutableArray *notifications = [XmlUtils parseMultiPresenceNotification:[xmlMsg UTF8String]];
    UcaContactService *service = [UcaAppDelegate sharedInstance].contactService;
    BOOL notify = NO;
    @synchronized (self.sessions) {
        for (ContactPresence *note in notifications) {
            for (Session *s in self.sessions) {
                for (Contact *contact in s.contacts) {
                    if (contact.userId == note.userId) {
                        contact.presentation = note.state;
                        contact.cameraOn = note.cameraOn;
                        [service updateContact:contact.userId
                                  presentation:contact.presentation
                                       cameraOn:contact.cameraOn];
                        notify = YES;
                    }
                }
            }
        }
    }

    if (notify) {
        [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_UPDATED];
    }
}

- (void)onSessionStatusChanged:(NSNotification *)note {
    UcaSessionStatusEvent *event = note.object;

    @synchronized (self.sessions) {
        for (Session *session in self.sessions) {
            if (session.id == event.chatId) {
                session.sipPhone = [event.sessionSipPhone strimmedSipPhone];
            }
        }
    }

    if (event.status == UCALIB_CHAT_CREAT_SUCCEED) {
        [NotifyUtils cancelNotificationWithName:UCA_INDICATE_SESSION_CREATED_OKAY];
        [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_CREATED_OKAY];
    } else if (event.status == UCALIB_CHAT_CREAT_FAILED) {
        [NotifyUtils cancelNotificationWithName:UCA_INDICATE_SESSION_CREATED_FAIL];
        [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_CREATED_FAIL];
    } else if (event.status == UCALIB_CHAT_REFER_SUCCEED) {
        [NotifyUtils cancelNotificationWithName:UCA_INDICATE_ADD_SESSION_MEMBERS_OKAY];
        [NotifyUtils postNotificationWithName:UCA_INDICATE_ADD_SESSION_MEMBERS_OKAY];
    } else if (event.status == UCALIB_CHAT_REFER_FAILED) {
        [NotifyUtils cancelNotificationWithName:UCA_INDICATE_ADD_SESSION_MEMBERS_FAIL];
        [NotifyUtils postNotificationWithName:UCA_INDICATE_ADD_SESSION_MEMBERS_FAIL];
    } else if (event.status == UCALIB_CHAT_INVITE_INCOMING) {
        UcaContactService *service = [UcaAppDelegate sharedInstance].contactService;
        [service touchContactBySipPhone:event.sessionSipPhone withTimestamp:[NSDate date]];

        @synchronized (self.sessions) {
            Session *session = [[Session alloc] init];
            session.id = event.chatId;
            session.sipPhone = event.sessionSipPhone;
            [self.sessions addObject:session];
        }
        [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_UPDATED];
    }
}

- (void)createSession {
    UCALIB_LOGIN_HANDLE handle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    NSInteger sessionId = 0;
    UCALIB_ERRCODE res = ucaLib_MsgConfCreate(handle, &sessionId);
    UcaLog(TAG, @"ucaLib_MsgConfCreate() res=%d, sessionId=%d", res, sessionId);
    if (res == UCALIB_ERR_OK) {
        @synchronized (self.sessions) {
            Session *session = [[Session alloc] init];
            session.id = sessionId;
            [self.sessions addObject:session];
        }

        [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_CREATED_OKAY afterDelay:POST_DELAY];
    } else {
        [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_CREATED_FAIL afterDelay:POST_DELAY];
    }
}

- (void)closeSession:(NSNumber *)sessionId {
    UCALIB_LOGIN_HANDLE handle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    UCALIB_ERRCODE res = ucaLib_MsgConfClose(handle, [sessionId integerValue]);
    UcaLog(TAG, @"ucaLib_MsgConfClose(%d) res=%d", [sessionId integerValue], res);
    if (res == UCALIB_ERR_OK) {
        @synchronized (self.sessions) {
            Session *session = [[Session alloc] init];
            session.id = [sessionId integerValue];
            [self.sessions removeObject:session];
        }
        [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_CLOSED_OKAY object:sessionId];
    } else {
        [NotifyUtils postNotificationWithName:UCA_INDICATE_SESSION_CLOSED_FAIL object:sessionId];
    }
}

- (void)doAddMembers {
    UCALIB_LOGIN_HANDLE handle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    UCALIB_ERRCODE res;
    NSMutableArray *addedContacts = [NSMutableArray array];

    for (Contact *contact in _opContacts) {
        res = ucaLib_MsgConfJoinOther(handle, _opSession.id, [contact.sipPhone UTF8String]);
        UcaLog(TAG, @"ucaLib_MsgConfJoinOther(%d, %@) res=%d", _opSession.id, contact.sipPhone, res);
        if (res == UCALIB_ERR_OK) {
            [addedContacts addObject:contact];
        }
    }

    BOOL ok = (addedContacts.count > 0);
    if (ok && _opSession) {
        [_opSession addContacts:addedContacts];
    }
    _opSession = nil;
    _opContacts = nil;

    // FIXME: POST_DELAY到了后，该消息并未被触发。鉴于目前UCALIB并没有对ucaLib_MsgConfJoinOther
    // 发出任何回调消息，所以这里直接post通知消息。
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_INDICATE_ADD_SESSION_MEMBERS_OKAY];// afterDelay:POST_DELAY];
    } else {
        [NotifyUtils postNotificationWithName:UCA_INDICATE_ADD_SESSION_MEMBERS_FAIL];// afterDelay:POST_DELAY];
    }
}

- (void)doRemoveMembers {
    // TODO: Need Maipu offer an API to do the removing.
    BOOL ok = YES;
    if (ok && _opSession && _opContacts) {
        [_opSession removeContacts:_opContacts];
    }
    _opSession = nil;
    _opContacts = nil;

    [NotifyUtils postNotificationWithName:(ok ? UCA_INDICATE_DELET_SESSION_MEMBERS_OKAY : UCA_INDICATE_DELET_SESSION_MEMBERS_FAIL)];
}

- (void)addContacts:(NSArray *)contacts toSession:(Session *)session {
    _opContacts = contacts;
    _opSession = session;
    [self performSelectorInBackground:@selector(doAddMembers) withObject:nil];
}

- (void)removeMembers:(NSArray *)contacts fromSession:(Session *)session {
    _opContacts = contacts;
    _opSession = session;
    [self performSelectorInBackground:@selector(doRemoveMembers) withObject:nil];
}

- (void)synchSessionWithContact:(Contact *)contact {
    @synchronized (self.sessions) {
        for (Session *session in self.sessions) {
            if (session.id == contact.userId) {
                session.sipPhone = contact.sipPhone;
            }
        }
    }
}

@end
