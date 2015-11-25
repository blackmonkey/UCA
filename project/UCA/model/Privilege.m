/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"Privilege"

#define ONE_M                      (1048576)

#define SUPER_ADMIN_BIT            (0)
#define INTRUSION_BREAKDOWN_BIT    (1)
#define FILE_TRANSFERS_BIT         (2)
#define VOICEMAIL_BIT              (3)
#define TUI_CHANGE_PIN_BIT         (4)
#define RECORD_SYSTEM_PROMPTS_BIT  (5)
#define INSTANT_MESSAGE_BIT        (6)
#define AUTO_ATTENDANT_BIT         (7)
#define FORWARD_CALLS_EXTERNAL_BIT (8)
#define MEETING_CREATE_BIT         (9)
#define COOPERATE_WITH_BIT         (10)

@implementation Privilege

@synthesize superAdmin;
@synthesize intrusionBreakdown;
@synthesize fileTransfers;
@synthesize sendFileSize;
@synthesize sendFileSpeed;
@synthesize voicemail;
@synthesize tuiChangePin;
@synthesize recordSystemPrompts;
@synthesize instantMessage;
@synthesize autoAttendant;
@synthesize forwardCallsExternal;
@synthesize meetingCreate;
@synthesize cooperateWith;

- (id)initWithSendSize:(NSInteger)size andSendSpeed:(NSInteger)speed andOther:(NSInteger)other {
    self = [super init];
    if (self) {
        // 当SIP Server服务器上账号的权限（发送文件大小、文件传输速率）这两个地方为空时，其实际默认值为1M
        self.sendFileSize = (size > 0 ? size : ONE_M);
        self.sendFileSpeed = (speed > 0 ? size : ONE_M);
        [self decodeOtherPrivilege:other];
    }
    return self;
}

- (void)decodeOtherPrivilege:(NSInteger)other {
    self.superAdmin           = other & (1 << SUPER_ADMIN_BIT);
    self.intrusionBreakdown   = other & (1 << INTRUSION_BREAKDOWN_BIT);
    self.fileTransfers        = other & (1 << FILE_TRANSFERS_BIT);
    self.voicemail            = other & (1 << VOICEMAIL_BIT);
    self.tuiChangePin         = other & (1 << TUI_CHANGE_PIN_BIT);
    self.recordSystemPrompts  = other & (1 << RECORD_SYSTEM_PROMPTS_BIT);
    self.instantMessage       = other & (1 << INSTANT_MESSAGE_BIT);
    self.autoAttendant        = other & (1 << AUTO_ATTENDANT_BIT);
    self.forwardCallsExternal = other & (1 << FORWARD_CALLS_EXTERNAL_BIT);
    self.meetingCreate        = other & (1 << MEETING_CREATE_BIT);
    self.cooperateWith        = other & (1 << COOPERATE_WITH_BIT);
}

- (NSInteger)encodeOtherPrivilege {
    return (((int) self.superAdmin)              << SUPER_ADMIN_BIT)
            | (((int) self.intrusionBreakdown)   << INTRUSION_BREAKDOWN_BIT)
            | (((int) self.fileTransfers)        << FILE_TRANSFERS_BIT)
            | (((int) self.voicemail)            << VOICEMAIL_BIT)
            | (((int) self.tuiChangePin)         << TUI_CHANGE_PIN_BIT)
            | (((int) self.recordSystemPrompts)  << RECORD_SYSTEM_PROMPTS_BIT)
            | (((int) self.instantMessage)       << INSTANT_MESSAGE_BIT)
            | (((int) self.autoAttendant)        << AUTO_ATTENDANT_BIT)
            | (((int) self.forwardCallsExternal) << FORWARD_CALLS_EXTERNAL_BIT)
            | (((int) self.meetingCreate)        << MEETING_CREATE_BIT)
            | (((int) self.cooperateWith)        << COOPERATE_WITH_BIT);
}

@end
