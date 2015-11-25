/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <libxml/tree.h>
#import <SystemConfiguration/SystemConfiguration.h>

#undef TAG
#define TAG @"UcaAccountService"

#undef TABLE_NAME
#define TABLE_NAME @"Account"

#undef PARAM_TABLE_NAME
#define PARAM_TABLE_NAME @"ServerParam"
#define COLUMN_PARAM_IP  @"ip"

#define COLUMN_SERVER_PARAM_ID      @"serverParamId"
#define COLUMN_USER_ID              @"userId"
#define COLUMN_USERNAME             @"username"
#define COLUMN_PASSWORD             @"password"
#define COLUMN_FIRSTNAME            @"firstname"
#define COLUMN_LASTNAME             @"lastname"
#define COLUMN_NICKNAME             @"nickname"
#define COLUMN_ALIASES              @"aliases"
#define COLUMN_IS_FEMALE            @"isFemale"
#define COLUMN_DESCRIPTION          @"description"
#define COLUMN_PHOTO                @"photo"
#define COLUMN_PIN                  @"pin"
#define COLUMN_GROUP_ID             @"groupId"
#define COLUMN_GROUPS               @"groups"
#define COLUMN_CALL_MODE            @"callMode"
#define COLUMN_SIPPHONE             @"sipPhone"
#define COLUMN_WORKPHONE            @"workPhone"
#define COLUMN_FAMILYPHONE          @"familyPhone"
#define COLUMN_MOBILEPHONE          @"mobilePhone"
#define COLUMN_MOBILEPHONE2         @"mobilePhone2"
#define COLUMN_OTHERPHONE           @"otherPhone"
#define COLUMN_EMAIL                @"email"
#define COLUMN_VOICEMAIL            @"voicemail"
#define COLUMN_SERVER_DOMAIN        @"serverDomain"
#define COLUMN_CUSTOM_HISOTLOGY     @"customHisotlogy"
#define COLUMN_COMPANY              @"company"
#define COLUMN_COMPANY_ADDRESS      @"companyAddress"
#define COLUMN_DEPARTMENT_ID        @"departmentId"
#define COLUMN_DEPARTMENT           @"department"
#define COLUMN_POSITION             @"position"
#define COLUMN_FAMILY_ADDRESS       @"familyAddress"
#define COLUMN_SHOW_PERSONAL_INFO   @"showPersonalInfo"
#define COLUMN_SEND_FILE_SIZE       @"sendFileSize"
#define COLUMN_SEND_FILE_SPEED      @"sendFileSpeed"
#define COLUMN_OTHER_PRIVILEGES     @"otherPrivileges"
#define COLUMN_REMEMBER_PASSWORD    @"rememberPassword"

typedef enum {
    NotReachable = 0,
    ReachableViaWiFi,
    ReachableViaWWAN
} NetworkStatus;

static NetworkStatus gNetStatus = NotReachable;

static void networkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *nilCtx) {
    UcaLog(TAG, @"Network connection flag [%x]",flags);
    
    UCALIB_LOGIN_HANDLE loginHandle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    
    // 检测新的网络连接方式
    NetworkStatus newNetStatus = NotReachable;
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
            // WWAN connections are OK if the calling application is using the CFNetwork (CFSocketStream?) APIs.
            newNetStatus = ReachableViaWWAN;
        } else {
            newNetStatus = ReachableViaWiFi;
        }
    }
    
    if (newNetStatus == NotReachable) {
        // 没有网络连接
        ucalib_set_network_reachable(loginHandle, NO);
    } else if (gNetStatus == NotReachable) {
        // 没有网络连接 -> 有网络连接
        ucalib_set_network_reachable(loginHandle, YES);
    } else if (gNetStatus != newNetStatus) {
        // 原来的网络连接方式和新的网络连接方式不一样
        ucalib_set_network_reachable(loginHandle, NO);
        ucalib_set_network_reachable(loginHandle, YES);
    }
    
    gNetStatus = newNetStatus;
}

@implementation UcaAccountService {
    BOOL _subscribed;
    SCNetworkReachabilityRef _reachabilityRef;
    NSString *_curLoginIp;
    UcaDatabaseService *_dbService;
}

@synthesize currentAccount;
@synthesize curAccountId;
@synthesize curLoginHandle;
@synthesize curLoginStatus;
@synthesize curPresent;
@synthesize dstPresent;

- (id)init {
    if ((self = [super init])) {
        [self resetCurrentStatus];
        _dbService = [UcaAppDelegate sharedInstance].databaseService;
    }
    return self;
}

- (void)resetCurrentStatus {
    curAccountId   = NOT_SAVED;
    curLoginHandle = 0;
    curLoginStatus = LoginStatus_UnLoggedIn;
    curPresent     = UCALIB_PRESENTATIONSTATE_OFFLINE;
    dstPresent     = UCALIB_PRESENTATIONSTATE_OFFLINE;
    _subscribed    = NO;
}

- (void)synchAccount:(Account *)acnt {
    if (acnt.id == NOT_SAVED) {
        // new account, add it
        acnt.id = [self addAccountWithUsername:acnt.username
                                   andPassword:acnt.password
                                   andServerId:acnt.serverParam.id
                           andRememberPassword:acnt.rememberPassword];
    } else {
        // old account, update it
        [self updateAccount:acnt.id
                   password:acnt.password
              serverParamId:acnt.serverParam.id
           rememberPassword:acnt.rememberPassword];
    }
}

- (void)synchCurrentAccountFromServer {
    UCALIB_ERRCODE res;
    char *val = NULL;
    NSMutableArray *columns = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    NSString *serverDomain = @"";
    
    res = ucaLib_GetServerConfig(curLoginHandle, UCALIB_CONFIGKEY_SERVERDOMAINNAME, &val);
    if (res == UCALIB_ERR_OK && val != NULL) {
        serverDomain = [NSString stringOfUTF8String:val];
    }
    UcaLibRelease(val);
    
    res = ucaLib_GetServerConfig(curLoginHandle, UCALIB_CONFIGKEY_CUSTOMHISOTLOGYNAME, &val);
    if (res == UCALIB_ERR_OK && val != NULL) {
        [columns addObject:COLUMN_CUSTOM_HISOTLOGY];
        [values addObject:[NSString stringOfUTF8String:val]];
    }
    UcaLibRelease(val);
    
    res = ucaLib_GetServerConfig(curLoginHandle, UCALIB_SERVER_PERMISSION, &val);
    if (res == UCALIB_ERR_OK && val != NULL) {
        Privilege *privilege = [[Privilege alloc] init];
        [XmlUtils initPrivilege:privilege withXml:val];
        
        [columns addObject:COLUMN_SEND_FILE_SIZE];
        [values addObject:[NSNumber numberWithInteger:privilege.sendFileSize]];
        [columns addObject:COLUMN_SEND_FILE_SPEED];
        [values addObject:[NSNumber numberWithInteger:privilege.sendFileSpeed]];
        [columns addObject:COLUMN_OTHER_PRIVILEGES];
        [values addObject:[NSNumber numberWithInteger:[privilege encodeOtherPrivilege]]];
    }
    UcaLibRelease(val);
    
    res = ucaLib_GetServerConfig(curLoginHandle, UCALIB_SERVER_USERINFO, &val);
    if (res == UCALIB_ERR_OK && val != NULL) {
        Account *account = [[Account alloc] init];
        [XmlUtils initAccount:account withXml:val];
        
        if (![self isAccountRememberPassword:curAccountId]) {
            account.password = nil;
        }
        
        if ([NSString isNullOrEmpty:serverDomain] && ![NSString isNullOrEmpty:account.sipPhone]) {
            NSRange r = [account.sipPhone rangeOfString:@"@"];
            if (r.location != NSNotFound) {
                serverDomain = [account.sipPhone substringFromIndex:(r.location + 1)];
            }
        }
        if (![NSString isNullOrEmpty:serverDomain]) {
            [columns addObject:COLUMN_SERVER_DOMAIN];
            [values addObject:serverDomain];
        }
        
        account.photo = account.photo == nil ? [[UIImage alloc] init]: account.photo;
        NSData *photoData = UIImagePNGRepresentation(account.photo);
        photoData=photoData==nil?[NSData alloc]:photoData;
        
        [columns addObject:COLUMN_USER_ID];            [values addObject:[NSNumber numberWithInteger:account.userId]];
        [columns addObject:COLUMN_USERNAME];           [values addObject:(account.username == nil ? @"" : account.username)];
        [columns addObject:COLUMN_PASSWORD];           [values addObject:(account.password == nil ? @"" : account.password)];
        [columns addObject:COLUMN_FIRSTNAME];          [values addObject:(account.firstname == nil ? @"" : account.firstname)];
        [columns addObject:COLUMN_LASTNAME];           [values addObject:(account.lastname == nil ? @"" : account.lastname)];
        [columns addObject:COLUMN_NICKNAME];           [values addObject:(account.nickname == nil ? @"" : account.nickname)];
        [columns addObject:COLUMN_ALIASES];            [values addObject:(account.aliases == nil ? @"" : [account.aliases componentsJoinedByString:@","])];
        [columns addObject:COLUMN_IS_FEMALE];          [values addObject:[NSNumber numberWithBool:account.isFemale]];
        [columns addObject:COLUMN_DESCRIPTION];        [values addObject:(account.descrip == nil ? @"" : account.descrip)];
        [columns addObject:COLUMN_PIN];                [values addObject:(account.pin == nil ? @"" : account.pin)];
        [columns addObject:COLUMN_PHOTO];              [values addObject:photoData];
        [columns addObject:COLUMN_GROUP_ID];           [values addObject:[NSNumber numberWithInteger:account.groupId]];
        [columns addObject:COLUMN_GROUPS];             [values addObject:(account.groups == nil ? @"" : [account.groups componentsJoinedByString:@","])];
        [columns addObject:COLUMN_CALL_MODE];          [values addObject:[NSNumber numberWithInteger:account.callMode]];
        [columns addObject:COLUMN_SIPPHONE];           [values addObject:(account.sipPhone == nil ? @"" : account.sipPhone)];
        [columns addObject:COLUMN_WORKPHONE];          [values addObject:(account.workPhone == nil ? @"" : account.workPhone)];
        [columns addObject:COLUMN_FAMILYPHONE];        [values addObject:(account.familyPhone == nil ? @"" : account.familyPhone)];
        [columns addObject:COLUMN_MOBILEPHONE];        [values addObject:(account.mobilePhone == nil ? @"" : account.mobilePhone)];
        [columns addObject:COLUMN_MOBILEPHONE2];       [values addObject:(account.mobilePhone2 == nil ? @"" : account.mobilePhone2)];
        [columns addObject:COLUMN_OTHERPHONE];         [values addObject:(account.otherPhone == nil ? @"" : account.otherPhone)];
        [columns addObject:COLUMN_EMAIL];              [values addObject:(account.email == nil ? @"" : account.email)];
        [columns addObject:COLUMN_VOICEMAIL];          [values addObject:(account.voicemail == nil ? @"" : account.voicemail)];
        [columns addObject:COLUMN_COMPANY];            [values addObject:(account.company == nil ? @"" : account.company)];
        [columns addObject:COLUMN_COMPANY_ADDRESS];    [values addObject:(account.companyAddress == nil ? @"" : account.companyAddress)];
        [columns addObject:COLUMN_DEPARTMENT_ID];      [values addObject:[NSNumber numberWithInteger:account.departId]];
        [columns addObject:COLUMN_DEPARTMENT];         [values addObject:(account.departName == nil ? @"" : account.departName)];
        [columns addObject:COLUMN_POSITION];           [values addObject:(account.position == nil ? @"" : account.position)];
        [columns addObject:COLUMN_FAMILY_ADDRESS];     [values addObject:(account.familyAddress == nil ? @"" : account.familyAddress)];
        [columns addObject:COLUMN_SHOW_PERSONAL_INFO]; [values addObject:[NSNumber numberWithBool:account.showPersonalInfo]];
    }
    UcaLibRelease(val);
    
    BOOL ok = [_dbService updateRecord:curAccountId withColumns:columns andValues:values inTable:TABLE_NAME];
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_ACCOUNT object:nil];
    }
}

- (BOOL)synchCurrentAccountInfoToServer {
    Account *account = [self currentAccount];
    NSString *xml = [XmlUtils buildUserInfoWithAccount:account];
    UCALIB_ERRCODE res = ucaLib_SetServerConfig(curLoginHandle, UCALIB_SERVER_USERINFO, [xml UTF8String]);
    return res == UCALIB_ERR_OK;
}

- (void)tryClearLoginInfo {
    if (curLoginHandle != 0) {
        UCALIB_ERRCODE res;
        
        if (_subscribed) {
            res = ucaLib_UnSubscribe(curLoginHandle, NULL);
            UcaLog(TAG, @"tryClearLoginInfo() ucaLib_UnSubscribe() res: %d", res);
        }
        
        res = ucaLib_Logout(curLoginHandle);
        UcaLog(TAG, @"tryClearLoginInfo() ucaLib_Logout() res: %d", res);
    }
    [self resetCurrentStatus];
}

- (void)stopNetworkListener {
    if (_reachabilityRef != NULL) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        UcaCFRelease(_reachabilityRef);
    }
}

- (void)startNetworkListener {
    [self stopNetworkListener];
    
    if ([NSString isNullOrEmpty:_curLoginIp]) {
        UcaLog(TAG, @"Cannot monitor null domain ip");
        return;
    }
    
    struct sockaddr hostAddr = {0};
    hostAddr.sa_len = sizeof(hostAddr);
    hostAddr.sa_family = AF_INET;
    strcpy(hostAddr.sa_data, [_curLoginIp UTF8String]);
    
    gNetStatus = NotReachable;
    _reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, &hostAddr);
    
    // initial state is network off should be done as soon as possible
    SCNetworkReachabilityFlags flags;
    if (!SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        UcaLog(TAG, @"Cannot get reachability flags");
        return;
    }
    
    // FIXME: 此时调用networkReachabilityCallBack会导致帐号一登录就被踢出(UCALIB_SYSTEM_MESSAGE_CODE_KICKOFF)
    networkReachabilityCallBack(_reachabilityRef, flags, NULL);
    
    if (!SCNetworkReachabilitySetCallback(_reachabilityRef, (SCNetworkReachabilityCallBack)networkReachabilityCallBack, NULL)) {
        UcaLog(TAG, @"Cannot register reachability cb");
        return;
    }
    if (!SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
        UcaLog(TAG, @"Cannot register schedule reachability cb");
    }
}

- (void)onLoginEvent:(NSNotification *)notification {
    UcaLoginEvent *event = [notification object];
    BOOL needUpdate = NO;
    
    switch (event.state) {
        case UCALIB_LOGIN_STATE_OK:
            curLoginStatus = LoginStatus_LoggedIn;
            needUpdate = YES;
            if (curLoginHandle != 0) {
                UCALIB_ERRCODE res = ucaLib_Subscribe(curLoginHandle, NULL);
                _subscribed = (res == UCALIB_ERR_OK);
                UcaLog(TAG, @"ucaLib_Subscribe(%d) return %d", curLoginHandle, res);
                
                [self requestChangePresent:UCALIB_PRESENTATIONSTATE_ONLINE];
            }
            break;
            
        case UCALIB_LOGIN_STATE_EXIT:
            curLoginStatus = LoginStatus_LoggedOut;
            curLoginHandle = 0;
            needUpdate = YES;
            [self stopNetworkListener];
            break;
            
        case UCALIB_LOGIN_STATE_FAIL:
            UcaLog(TAG, @"onLoginEvent UCALIB_LOGIN_STATE_FAIL curLoginStatus=%d", curLoginStatus);
            if (curLoginStatus == LoginStatus_Logging) {
                curLoginStatus = LoginStatus_LoginFailed;
                needUpdate = YES;
            } else if (curLoginStatus == LoginStatus_LoggingOut) {
                curLoginStatus = LoginStatus_LogoutFailed;
                needUpdate = YES;
            }
            break;
            
        default:
            break;
    }
    
    if (needUpdate) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_LOGIN_STATUS object:self];
    }
}

- (void)onPresentEvent:(NSNotification *)notification {
    UcaAccountPresentationEvent *event = notification.object;
    if (event.result == UCALIB_PRESENTATIONRESULT_CODE_ERROR) {
        dstPresent = curPresent;
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_PRESENT_FAIL];
    } else if (event.result == UCALIB_PRESENTATIONRESULT_CODE_OK) {
        curPresent = dstPresent;
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_PRESENT_OK];
    }
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }
    
    NSArray *colInfos = [NSArray arrayWithObjects:
                         COLUMN_ID, @"INTEGER PRIMARY KEY AUTOINCREMENT",
                         COLUMN_SERVER_PARAM_ID, @"INTEGER",
                         COLUMN_USER_ID, @"INTEGER",
                         COLUMN_USERNAME, @"TEXT",
                         COLUMN_PASSWORD, @"TEXT",
                         COLUMN_FIRSTNAME, @"TEXT",
                         COLUMN_LASTNAME, @"TEXT",
                         COLUMN_NICKNAME, @"TEXT",
                         COLUMN_ALIASES, @"TEXT",
                         COLUMN_IS_FEMALE, @"TINYINT(1)",
                         COLUMN_DESCRIPTION, @"TEXT",
                         COLUMN_PHOTO, @"BLOB",
                         COLUMN_PIN, @"TEXT",
                         COLUMN_GROUP_ID, @"INTEGER",
                         COLUMN_GROUPS, @"TEXT",
                         COLUMN_CALL_MODE, @"TINYINT(1)",
                         COLUMN_SIPPHONE, @"TEXT",
                         COLUMN_WORKPHONE, @"TEXT",
                         COLUMN_FAMILYPHONE, @"TEXT",
                         COLUMN_MOBILEPHONE, @"TEXT",
                         COLUMN_MOBILEPHONE2, @"TEXT",
                         COLUMN_OTHERPHONE, @"TEXT",
                         COLUMN_EMAIL, @"TEXT",
                         COLUMN_VOICEMAIL, @"TEXT",
                         COLUMN_SERVER_DOMAIN, @"TEXT",
                         COLUMN_CUSTOM_HISOTLOGY, @"TEXT",
                         COLUMN_COMPANY, @"TEXT",
                         COLUMN_COMPANY_ADDRESS, @"TEXT",
                         COLUMN_DEPARTMENT_ID, @"INTEGER",
                         COLUMN_DEPARTMENT, @"TEXT",
                         COLUMN_POSITION, @"TEXT",
                         COLUMN_FAMILY_ADDRESS, @"TEXT",
                         COLUMN_SHOW_PERSONAL_INFO, @"TINYINT(1) DEFAULT 1",
                         COLUMN_SEND_FILE_SIZE, @"INTEGER",
                         COLUMN_SEND_FILE_SPEED, @"INTEGER",
                         COLUMN_OTHER_PRIVILEGES, @"INTEGER",
                         COLUMN_REMEMBER_PASSWORD, @"TINYINT(1)",
                         nil];
    if (![_dbService createTableIfNeeds:TABLE_NAME columnInfos:colInfos]) {
        UcaLog(TAG, @"Failed to create table %@", TABLE_NAME);
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLoginEvent:)
                                                 name:UCA_NATIVE_LOGIN
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPresentEvent:)
                                                 name:UCA_NATIVE_ACCOUNT_PRESENTATION
                                               object:nil];
    [self startNetworkListener];
    return YES;
}

- (BOOL)stop {
    UcaLog(TAG, @"Stop()");
    if (![super stop]) {
        return NO;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopNetworkListener];
    return YES;
}

- (NSInteger)addAccountWithUsername:(NSString *)username
                        andPassword:(NSString *)password
                        andServerId:(NSInteger)paramId
                andRememberPassword:(BOOL)rememberPassword {
    if ([NSString isNullOrEmpty:username] || paramId == NOT_SAVED
        || ([NSString isNullOrEmpty:password] && rememberPassword)) {
        return NOT_SAVED;
    }
    
    if (!rememberPassword || password == nil) {
        password = @"";
    }
    
    NSArray *cols = [NSArray arrayWithObjects:
                     COLUMN_USERNAME,
                     COLUMN_PASSWORD,
                     COLUMN_SERVER_PARAM_ID,
                     COLUMN_REMEMBER_PASSWORD, nil];
    NSArray *vals = [NSArray arrayWithObjects:
                     username,
                     password,
                     [NSNumber numberWithInteger:paramId],
                     [NSNumber numberWithBool:rememberPassword], nil];
    return [_dbService addRecordWithColumns:cols andValues:vals toTable:TABLE_NAME];
}

- (BOOL)updateAccount:(NSInteger)accountId password:(NSString *)pwd {
    if (pwd == nil) {
        pwd = @"";
    }
    NSArray *cols = [NSArray arrayWithObject:COLUMN_PASSWORD];
    NSArray *vals = [NSArray arrayWithObject:pwd];
    return [_dbService updateRecord:accountId withColumns:cols andValues:vals inTable:TABLE_NAME];
}

- (BOOL)updateAccount:(NSInteger)accountId serverParamId:(NSInteger)paramId rememberPassword:(BOOL)remember {
    NSMutableArray *cols = [NSMutableArray arrayWithObjects:COLUMN_SERVER_PARAM_ID, COLUMN_REMEMBER_PASSWORD, nil];
    NSMutableArray *vals = [NSMutableArray arrayWithObjects:[NSNumber numberWithInteger:paramId], [NSNumber numberWithBool:remember], nil];
    if (!remember) {
        [cols addObject:COLUMN_PASSWORD];
        [vals addObject:@""];
    }
    return [_dbService updateRecord:accountId withColumns:cols andValues:vals inTable:TABLE_NAME];
}

- (BOOL)updateAccount:(NSInteger)accountId password:(NSString *)pwd serverParamId:(NSInteger)paramId rememberPassword:(BOOL)remember {
    if (!remember || pwd == nil) {
        pwd = @"";
    }
    NSMutableArray *cols = [NSMutableArray arrayWithObjects:COLUMN_PASSWORD, COLUMN_SERVER_PARAM_ID, COLUMN_REMEMBER_PASSWORD, nil];
    NSMutableArray *vals = [NSMutableArray arrayWithObjects:pwd, [NSNumber numberWithInteger:paramId], [NSNumber numberWithBool:remember], nil];
    return [_dbService updateRecord:accountId withColumns:cols andValues:vals inTable:TABLE_NAME];
}

- (BOOL)updateAccount:(NSInteger)accountId
                photo:(UIImage *)photo
          description:(NSString *)descrip
             nickname:(NSString *)nickname
             isFemale:(BOOL)isFemale
        familyAddress:(NSString *)familyAddress
          familyPhone:(NSString *)familyPhone
          mobilePhone:(NSString *)mobilePhone
         mobilePhone2:(NSString *)mobilePhone2
           otherPhone:(NSString *)otherPhone
     showPersonalInfo:(BOOL)showPersonalInfo {
    NSMutableArray *cols = [NSMutableArray arrayWithObjects:
                            COLUMN_PHOTO, COLUMN_DESCRIPTION, COLUMN_NICKNAME, COLUMN_IS_FEMALE,
                            COLUMN_FAMILY_ADDRESS, COLUMN_FAMILYPHONE, COLUMN_MOBILEPHONE,
                            COLUMN_MOBILEPHONE2, COLUMN_OTHERPHONE, COLUMN_SHOW_PERSONAL_INFO,
                            nil];
    NSData *photoData = UIImagePNGRepresentation(photo);
    photoData=photoData==nil?[NSData alloc]:photoData;
    NSMutableArray *vals = [NSMutableArray arrayWithObjects:
                            photoData, descrip, nickname, [NSNumber numberWithBool:isFemale],
                            familyAddress, familyPhone, mobilePhone,
                            mobilePhone2, otherPhone, [NSNumber numberWithBool:showPersonalInfo], nil];
    BOOL ok = [_dbService updateRecord:accountId withColumns:cols andValues:vals inTable:TABLE_NAME];
    if (ok && [self isLoggedIn]) {
        ok = [self synchCurrentAccountInfoToServer];
    }
    return ok;
}

- (BOOL)deleteAccount:(NSInteger)accountId {
    BOOL ok = [_dbService deleteRecord:accountId fromTable:TABLE_NAME];
    UcaLog(TAG, "delete account %d, res:%d", accountId, ok);
    
    if (ok) {
        [NotifyUtils postNotificationWithName:UCA_EVENT_DELETE_ACCOUNT
                                       object:[NSNumber numberWithInteger:accountId]];
    }
    
    return ok;
}

- (void)bindAccount:(Account *)account
    fromQueryResult:(FMResultSet *)rs
      onlyLoginInfo:(BOOL)onlyLoginInfo {
    account.id = [rs intForColumn:COLUMN_ID];
    account.username = [rs stringForColumn:COLUMN_USERNAME];
    account.password = [rs stringForColumn:COLUMN_PASSWORD];
    account.serverParam.id = [rs intForColumn:COLUMN_SERVER_PARAM_ID];
    account.serverParam.ip = [NSString stringWithIp:[rs intForColumn:COLUMN_PARAM_IP]];
    
    NSData *data = [rs dataForColumn:COLUMN_PHOTO];
    if (data != nil && data.length > 0) {
        account.photo = [[UIImage alloc] initWithData:data];
    }
    account.rememberPassword = [rs boolForColumn:COLUMN_REMEMBER_PASSWORD];
    
    if (onlyLoginInfo) {
        return;
    }
    
    account.userId = [rs intForColumn:COLUMN_USER_ID];
    account.firstname = [rs stringForColumn:COLUMN_FIRSTNAME];
    account.lastname = [rs stringForColumn:COLUMN_LASTNAME];
    account.nickname = [rs stringForColumn:COLUMN_NICKNAME];
    account.aliases = [[rs stringForColumn:COLUMN_ALIASES] componentsSeparatedByString:@","];
    account.isFemale = [rs boolForColumn:COLUMN_IS_FEMALE];
    account.descrip = [rs stringForColumn:COLUMN_DESCRIPTION];
    account.pin = [rs stringForColumn:COLUMN_PIN];
    account.groupId = [rs intForColumn:COLUMN_GROUP_ID];
    account.groups = [[rs stringForColumn:COLUMN_GROUPS] componentsSeparatedByString:@","];
    account.callMode = [rs intForColumn:COLUMN_CALL_MODE];
    account.sipPhone = [rs stringForColumn:COLUMN_SIPPHONE];
    account.workPhone = [rs stringForColumn:COLUMN_WORKPHONE];
    account.familyPhone = [rs stringForColumn:COLUMN_FAMILYPHONE];
    account.mobilePhone = [rs stringForColumn:COLUMN_MOBILEPHONE];
    account.mobilePhone2 = [rs stringForColumn:COLUMN_MOBILEPHONE2];
    account.otherPhone = [rs stringForColumn:COLUMN_OTHERPHONE];
    account.email = [rs stringForColumn:COLUMN_EMAIL];
    account.voicemail = [rs stringForColumn:COLUMN_VOICEMAIL];
    account.serverDomain = [rs stringForColumn:COLUMN_SERVER_DOMAIN];
    account.customHisotlogy = [rs stringForColumn:COLUMN_CUSTOM_HISOTLOGY];
    account.company = [rs stringForColumn:COLUMN_COMPANY];
    account.companyAddress = [rs stringForColumn:COLUMN_COMPANY_ADDRESS];
    account.departId = [rs intForColumn:COLUMN_DEPARTMENT_ID];
    account.departName = [rs stringForColumn:COLUMN_DEPARTMENT];
    account.position = [rs stringForColumn:COLUMN_POSITION];
    account.familyAddress = [rs stringForColumn:COLUMN_FAMILY_ADDRESS];
    account.showPersonalInfo = [rs boolForColumn:COLUMN_SHOW_PERSONAL_INFO];
    
    account.privileges.sendFileSize = [rs intForColumn:COLUMN_SEND_FILE_SIZE];
    account.privileges.sendFileSpeed = [rs intForColumn:COLUMN_SEND_FILE_SPEED];
    [account.privileges decodeOtherPrivilege:[rs intForColumn:COLUMN_OTHER_PRIVILEGES]];
}

- (Account *)currentAccount {
    Account *account = [self accountWithId:curAccountId];
    if (account != nil) {
        account.presentation = curPresent;
    }
    return account;
}

- (Account *)accountWithId:(NSInteger)accountId {
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendString:@"SELECT "];
    [sql appendFormat:@"%@.%@ AS %@, ", TABLE_NAME, COLUMN_ID, COLUMN_ID];
    [sql appendFormat:@"%@, ", COLUMN_SERVER_PARAM_ID];
    [sql appendFormat:@"%@, ", COLUMN_PARAM_IP];
    [sql appendFormat:@"%@, ", COLUMN_USER_ID];
    [sql appendFormat:@"%@, ", COLUMN_USERNAME];
    [sql appendFormat:@"%@, ", COLUMN_PASSWORD];
    [sql appendFormat:@"%@, ", COLUMN_FIRSTNAME];
    [sql appendFormat:@"%@, ", COLUMN_LASTNAME];
    [sql appendFormat:@"%@, ", COLUMN_NICKNAME];
    [sql appendFormat:@"%@, ", COLUMN_ALIASES];
    [sql appendFormat:@"%@, ", COLUMN_IS_FEMALE];
    [sql appendFormat:@"%@, ", COLUMN_DESCRIPTION];
    [sql appendFormat:@"%@, ", COLUMN_PHOTO];
    [sql appendFormat:@"%@, ", COLUMN_PIN];
    [sql appendFormat:@"%@, ", COLUMN_GROUP_ID];
    [sql appendFormat:@"%@, ", COLUMN_GROUPS];
    [sql appendFormat:@"%@, ", COLUMN_CALL_MODE];
    [sql appendFormat:@"%@, ", COLUMN_SIPPHONE];
    [sql appendFormat:@"%@, ", COLUMN_WORKPHONE];
    [sql appendFormat:@"%@, ", COLUMN_FAMILYPHONE];
    [sql appendFormat:@"%@, ", COLUMN_MOBILEPHONE];
    [sql appendFormat:@"%@, ", COLUMN_MOBILEPHONE2];
    [sql appendFormat:@"%@, ", COLUMN_OTHERPHONE];
    [sql appendFormat:@"%@, ", COLUMN_EMAIL];
    [sql appendFormat:@"%@, ", COLUMN_VOICEMAIL];
    [sql appendFormat:@"%@, ", COLUMN_SERVER_DOMAIN];
    [sql appendFormat:@"%@, ", COLUMN_CUSTOM_HISOTLOGY];
    [sql appendFormat:@"%@, ", COLUMN_COMPANY];
    [sql appendFormat:@"%@, ", COLUMN_COMPANY_ADDRESS];
    [sql appendFormat:@"%@, ", COLUMN_DEPARTMENT_ID];
    [sql appendFormat:@"%@, ", COLUMN_DEPARTMENT];
    [sql appendFormat:@"%@, ", COLUMN_POSITION];
    [sql appendFormat:@"%@, ", COLUMN_FAMILY_ADDRESS];
    [sql appendFormat:@"%@, ", COLUMN_SHOW_PERSONAL_INFO];
    [sql appendFormat:@"%@, ", COLUMN_SEND_FILE_SIZE];
    [sql appendFormat:@"%@, ", COLUMN_SEND_FILE_SPEED];
    [sql appendFormat:@"%@, ", COLUMN_OTHER_PRIVILEGES];
    [sql appendFormat:@"%@ ", COLUMN_REMEMBER_PASSWORD];
    [sql appendFormat:@"FROM %@ LEFT JOIN %@ ", TABLE_NAME, PARAM_TABLE_NAME];
    [sql appendFormat:@"WHERE %@ = %@.%@", COLUMN_SERVER_PARAM_ID, PARAM_TABLE_NAME, COLUMN_ID];
    [sql appendFormat:@" AND %@.%@ = %d", TABLE_NAME, COLUMN_ID, accountId];
    
    Account *account = nil;
    FMResultSet *rs = [_dbService executeQuery:sql];
    if ([rs next]) {
        account = [[Account alloc] init];
        [self bindAccount:account fromQueryResult:rs onlyLoginInfo:NO];
    }
    [rs close];
    [rs setParentDB:nil];
    return account;
}

- (NSArray *)accountsWithLoginInfo {
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendString:@"SELECT "];
    [sql appendFormat:@"%@.%@ AS %@, ", TABLE_NAME, COLUMN_ID, COLUMN_ID];
    [sql appendFormat:@"%@, ", COLUMN_SERVER_PARAM_ID];
    [sql appendFormat:@"%@, ", COLUMN_PARAM_IP];
    [sql appendFormat:@"%@, ", COLUMN_USERNAME];
    [sql appendFormat:@"%@, ", COLUMN_PASSWORD];
    [sql appendFormat:@"%@, ", COLUMN_PHOTO];
    [sql appendFormat:@"%@ ", COLUMN_REMEMBER_PASSWORD];
    [sql appendFormat:@"FROM %@ LEFT JOIN %@ ", TABLE_NAME, PARAM_TABLE_NAME];
    [sql appendFormat:@"WHERE %@ = %@.%@ ", COLUMN_SERVER_PARAM_ID, PARAM_TABLE_NAME, COLUMN_ID];
    [sql appendFormat:@"ORDER BY %@ DESC", COLUMN_ID];
    
    NSMutableArray *accounts = [NSMutableArray array];
    Account *account = nil;
    FMResultSet *rs = [_dbService executeQuery:sql];
    while ([rs next]) {
        account = [[Account alloc] init];
        [self bindAccount:account fromQueryResult:rs onlyLoginInfo:YES];
        [accounts addObject:account];
    }
    [rs close];
    [rs setParentDB:nil];
    return accounts;
}

- (Account *)accountWithLoginInfo:(NSInteger)accountId {
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendString:@"SELECT "];
    [sql appendFormat:@"%@.%@ AS %@, ", TABLE_NAME, COLUMN_ID, COLUMN_ID];
    [sql appendFormat:@"%@, ", COLUMN_SERVER_PARAM_ID];
    [sql appendFormat:@"%@, ", COLUMN_PARAM_IP];
    [sql appendFormat:@"%@, ", COLUMN_USERNAME];
    [sql appendFormat:@"%@, ", COLUMN_PASSWORD];
    [sql appendFormat:@"%@, ", COLUMN_PHOTO];
    [sql appendFormat:@"%@ ", COLUMN_REMEMBER_PASSWORD];
    [sql appendFormat:@"FROM %@ LEFT JOIN %@ ", TABLE_NAME, PARAM_TABLE_NAME];
    [sql appendFormat:@"WHERE %@ = %@.%@", COLUMN_SERVER_PARAM_ID, PARAM_TABLE_NAME, COLUMN_ID];
    [sql appendFormat:@" AND %@.%@ = %d", TABLE_NAME, COLUMN_ID, accountId];
    
    Account *account = nil;
    FMResultSet *rs = [_dbService executeQuery:sql];
    if ([rs next]) {
        account = [[Account alloc] init];
        [self bindAccount:account fromQueryResult:rs onlyLoginInfo:YES];
    }
    [rs close];
    [rs setParentDB:nil];
    return account;
}

- (NSInteger)accountIdByUsername:(NSString *)username andServerParamId:(NSInteger)paramId {
    return [_dbService recordIdWhere:[NSArray arrayWithObjects:COLUMN_USERNAME, COLUMN_SERVER_PARAM_ID, nil]
                              equals:[NSArray arrayWithObjects:username, [NSNumber numberWithInteger:paramId], nil]
                             inTable:TABLE_NAME];
}

- (NSString *)accountPasswordById:(NSInteger)accountId {
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %d",
                     COLUMN_PASSWORD, TABLE_NAME, COLUMN_ID, accountId];
    NSString *pwd = nil;
    FMResultSet *rs = [_dbService executeQuery:sql];
    if ([rs next]) {
        pwd = [rs stringForColumn:COLUMN_PASSWORD];
    }
    [rs close];
    [rs setParentDB:nil];
    return pwd;
}

- (void)requestLogin:(Account *)account {
    if (account == nil) {
        //account = currentAccount;
        account = [self currentAccount];
    }
    
    curLoginStatus = LoginStatus_Logging;
    [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_LOGIN_STATUS object:self];
    
    UCALIB_ERRCODE res = 0;
    UCALIB_LOGIN_PARAM param;
    UCALIB_LOGIN_HANDLE handle;
    
    param.username = (char *)[account.username UTF8String];
    param.password = (char *)[account.password UTF8String];
    param.serverIP = (char *)[account.serverParam.ip UTF8String];
    param.serverPort = 0;
    
    _curLoginIp = account.serverParam.ip;
    
    UcaLog(TAG, @"ucaLib_Login() account:%@ password:%@, ip:%@", account.username, account.password, account.serverParam.ip);
    res = ucaLib_Login(&param, &handle);
    UcaLog(TAG, @"ucaLib_Login(%@) res: %d, handle = %d", account.username, res, handle);
    
    switch (res) {
        case UCALIB_ERR_OK:
            [self synchAccount:account];
            curAccountId = account.id;
            curLoginHandle = handle;
            break;
            
        case UCALIB_ERR_BADAUTH:
            curLoginStatus = LoginStatus_LoginFailed_BadAuth;
            break;
            
        case UCALIB_ERR_MULTILOGIN:
            curLoginStatus = LoginStatus_LoginFailed_MultiLogin;
            break;
            
        case UCALIB_ERR_SOAPERROR:
            curLoginStatus = LoginStatus_LoginFailed_SoapError;
            break;
            
        case UCALIB_ERR_BADPARAM:
            curLoginStatus = LoginStatus_LoginFailed_BadParam;
            break;
            
        case UCALIB_ERR_NETWORKUNREACHABLE:
            curLoginStatus = LoginStatus_LoginFailed_NoNetwork;
            break;
            
        default:
            curLoginStatus = LoginStatus_LoginFailed;
            break;
    }
    [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_LOGIN_STATUS object:self];
}

- (void)requestLogout {
    UcaLog(TAG, @"ucaLib_Logout() handle: %d", curLoginHandle);
    
    [[UcaAppDelegate sharedInstance].callingService performSelectorInBackground:@selector(hangupCall) withObject:nil];
    
    if (curLoginHandle == 0) {
        curLoginStatus = LoginStatus_LoggedOut;
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_LOGIN_STATUS object:self];
        return;
    }
    
    /*
     curLoginStatus = LoginStatus_LoggingOut;
     [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_LOGIN_STATUS object:self];
     */
    
    if (_subscribed) {
        ucaLib_UnSubscribe(curLoginHandle, NULL);
    }
    [self requestChangePresent:UCALIB_PRESENTATIONSTATE_OFFLINE];
    //curPresent = UCALIB_PRESENTATIONSTATE_OFFLINE;
    curLoginStatus = LoginStatus_LoggingOut;
    
    UCALIB_ERRCODE res = ucaLib_Logout(curLoginHandle);
    UcaLog(TAG, @"ucaLib_Logout() res: %d", res);
    if (res != UCALIB_ERR_OK) {
        ucaLib_Subscribe(curLoginHandle, NULL);
        curLoginStatus = LoginStatus_LoggedIn;
        [self requestChangePresent:UCALIB_PRESENTATIONSTATE_ONLINE];
    }
    [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_LOGIN_STATUS object:self];
}

- (void)requestChangePresent:(UCALIB_PRESENTATIONSTATE)present {
    dstPresent = present;
    UCALIB_ERRCODE res = UCALIB_ERR_OK;
    
    if ([self isLoggedIn]) {
        res = ucaLib_ChangePresentation(curLoginHandle, present);
        UcaLog(TAG, @"ucaLib_ChangePresentation(%d, %d) return %d", curLoginHandle, present, res);
    }
    
    if (res != UCALIB_ERR_OK) {
        dstPresent = curPresent;
        [NotifyUtils postNotificationWithName:UCA_EVENT_UPDATE_PRESENT_FAIL];
    } else {
        curPresent = dstPresent;
    }
}

- (BOOL)isLoggedIn {
    return (curLoginStatus == LoginStatus_LoggedIn || curLoginStatus == LoginStatus_LogoutFailed)
    && curLoginHandle != 0;
}

- (BOOL)isLoggedInFailed {
    return curLoginStatus == LoginStatus_LoginFailed
    || curLoginStatus == LoginStatus_LoginFailed_BadAuth
    || curLoginStatus == LoginStatus_LoginFailed_MultiLogin
    || curLoginStatus == LoginStatus_LoginFailed_SoapError
    || curLoginStatus == LoginStatus_LoginFailed_BadParam
    || curLoginStatus == LoginStatus_LoginFailed_NoNetwork;
}

- (BOOL)isLoggedOut {
    return curLoginStatus == LoginStatus_LoggedOut
    || curLoginStatus == LoginStatus_UnLoggedIn;
}

- (BOOL)isAccountRememberPassword:(NSInteger)accountId {
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %d",
                     COLUMN_REMEMBER_PASSWORD, TABLE_NAME, COLUMN_ID, accountId];
    BOOL remember = NO;
    FMResultSet *rs = [_dbService executeQuery:sql];
    if ([rs next]) {
        remember = [rs boolForColumn:COLUMN_REMEMBER_PASSWORD];
    }
    [rs close];
    [rs setParentDB:nil];
    return remember;
}

@end
