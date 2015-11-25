/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"UcaConfigurationService"

/**
 * Configuration Entry
 */

#define SERVER_IP               @"SERVER_IP"
#define SERVER_PORT             @"SERVER_PORT"
#define LATEST_LOGIN_ACCOUNT_ID @"LATEST_LOGIN_ACCOUNT_ID"
#define ACTIVE_IM_TONE          @"ACTIVE_IM_TONE"
#define ACTIVE_CAMERA           @"ACTIVE_CAMERA"
#define MAX_LENGTH_SHOWN_IM     @"MAX_LENGTH_SHOWN_IM"
#define IM_BASE_URL             @"IM_BASE_URL"

/**
 * Default Configuration Values
 */

#define DEFAULT_SERVER_IP   @"221.10.5.202"
#define DEFAULT_SERVER_PORT 8443

/**
 * Private Implementation
 */

@interface UcaConfigurationService(Private)
- (void)userDefaultsDidChange:(NSNotification *)note;
- (NSDictionary *)getDefaults;
- (void)synchronize;
@end

@implementation UcaConfigurationService(Private)

- (void)userDefaultsDidChange:(NSNotification *)note {
}

- (NSDictionary *)getDefaults {
    return [NSDictionary dictionaryWithObjectsAndKeys:

        /* === SERVER === */
        DEFAULT_SERVER_IP, SERVER_IP,
        [NSNumber numberWithInt:DEFAULT_SERVER_PORT], SERVER_PORT,

        [NSNumber numberWithBool:YES], ACTIVE_IM_TONE,
        [NSNumber numberWithBool:YES], ACTIVE_CAMERA,

        [NSNumber numberWithInteger:200], MAX_LENGTH_SHOWN_IM,
        nil];
}

- (void)synchronize {
    [defaults synchronize];
}

@end

/**
 * Default Implementation
 */

@implementation UcaConfigurationService {
    NSDictionary *initialOfCnChrs;
}

@synthesize lastLoginAccountId;
@synthesize activeImTone;
@synthesize activeCamera;
@synthesize maxShowImLength;
@synthesize imBaseUrl;
@synthesize emotes;

- (void)dealloc {
    [self stop];
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }

    NSString *path;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

    if (defaults == nil) {
        defaults = [NSUserDefaults standardUserDefaults];

        NSDictionary *_defaults = [self getDefaults];
        [defaults registerDefaults:_defaults];
    }

    if (initialOfCnChrs == nil) {
        path = [[NSBundle mainBundle] pathForResource:@"initialOfCnChrs" ofType:@"plist"];
        initialOfCnChrs = [[NSDictionary alloc] initWithContentsOfFile:path];
    }

    NSArray *pathes = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [pathes objectAtIndex:0];
    self.imBaseUrl = [NSURL fileURLWithPath:docPath isDirectory:YES];

    if (self->emotes == nil) {
        path = [[NSBundle mainBundle] pathForResource:@"emotes" ofType:@"plist"];
        self->emotes = [[NSDictionary alloc] initWithContentsOfFile:path];
    }

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

- (NSInteger)lastLoginAccountId {
    NSInteger val = [defaults integerForKey:LATEST_LOGIN_ACCOUNT_ID];
    return val != 0 ? val - 1 : NOT_SAVED;
}

- (void)setLastLoginAccountId:(NSInteger)id {
    [defaults setInteger:(id != NOT_SAVED ? id + 1 : 0)
                  forKey:LATEST_LOGIN_ACCOUNT_ID];
    if (![NSThread isMainThread]) {
        [self synchronize];
    }
}

- (BOOL)activeImTone {
    return [defaults boolForKey:ACTIVE_IM_TONE];
}

- (void)setActiveImTone:(BOOL)active {
    [defaults setBool:active forKey:ACTIVE_IM_TONE];
    if (![NSThread isMainThread]) {
        [self synchronize];
    }
}

- (BOOL)activeCamera {
    return [defaults boolForKey:ACTIVE_CAMERA];
}

- (void)setActiveCamera:(BOOL)active {
    [defaults setBool:active forKey:ACTIVE_CAMERA];
    if (![NSThread isMainThread]) {
        [self synchronize];
    }
}

- (NSString *)getInitialOfCnChr:(NSString *)chr {
    return [initialOfCnChrs objectForKey:chr];
}

- (NSUInteger)maxShowImLength {
    return (NSUInteger)[defaults integerForKey:MAX_LENGTH_SHOWN_IM];
}

- (NSURL *)imBaseUrl {
    return [defaults URLForKey:IM_BASE_URL];
}

- (void)setImBaseUrl:(NSURL *)url {
    [defaults setURL:url forKey:IM_BASE_URL];
    if (![NSThread isMainThread]) {
        [self synchronize];
    }
}

@end
