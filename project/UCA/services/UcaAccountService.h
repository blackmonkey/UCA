/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaAccountService : UcaService

@property (readonly, retain)  Account                 *currentAccount;
@property (nonatomic, assign) NSInteger                curAccountId;
@property (nonatomic, assign) UCALIB_LOGIN_HANDLE      curLoginHandle;
@property (nonatomic, assign) LoginStatus              curLoginStatus;
@property (nonatomic, assign) UCALIB_PRESENTATIONSTATE curPresent;
@property (nonatomic, assign) UCALIB_PRESENTATIONSTATE dstPresent;

/**
 * 同步帐号信息至数据库。
 * @param acnt 如果acnt不存在于数据表Account中，添加之；否则，更新之。
 */
- (void)synchAccount:(Account *)acnt;

/**
 * 从服务器同步当前账号信息。
 */
- (void)synchCurrentAccountFromServer;

/**
 * 清除登录失败时残留的登录信息。
 */
- (void)tryClearLoginInfo;

/**
 * 添加帐号。
 * @param username 帐号用户名。
 * @param password 帐号密码。
 * @param paramId 帐号所在服务器的记录ID。
 * @param rememberPassword 是否记住帐号密码。
 * @return 如果添加成功则返回有效记录ID；否则返回NOT_SAVED。
 */
- (NSInteger)addAccountWithUsername:(NSString *)username
                   andPassword:(NSString *)password
                   andServerId:(NSInteger)paramId
           andRememberPassword:(BOOL)rememberPassword;

/**
 * 更新账号密码。
 * @param accountId 帐号ID。
 * @param password 帐号密码。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateAccount:(NSInteger)accountId password:(NSString *)pwd;

/**
 * 更新账号登录信息。
 * @param accountId 帐号ID。
 * @param paramId 帐号相关服务器记录ID。
 * @param remember 是否记住密码。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateAccount:(NSInteger)accountId serverParamId:(NSInteger)paramId rememberPassword:(BOOL)remember;

/**
 * 更新账号登录信息。
 * @param accountId 帐号ID。
 * @param pwd 帐号密码。
 * @param paramId 帐号相关服务器记录ID。
 * @param remember 是否记住密码。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateAccount:(NSInteger)accountId password:(NSString *)pwd serverParamId:(NSInteger)paramId rememberPassword:(BOOL)remember;

/**
 * 更新账号信息并同步到服务器上。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
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
     showPersonalInfo:(BOOL)showPersonalInfo;

/**
 * 删除帐号。
 * @param accountId 帐号ID。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteAccount:(NSInteger)accountId;

/**
 * 获取所有帐号的登录相关信息。
 * @return 如果成功则返回所有帐号的登录相关信息；否则返回nil。
 */
- (NSArray *)accountsWithLoginInfo;

/**
 * 获取指定帐号的登录相关信息。
 * @param accountId 帐号ID。
 * @return 如果成功则返回指定帐号的登录相关信息；否则返回nil。
 */
- (Account *)accountWithLoginInfo:(NSInteger)accountId;

/**
 * 获取指定帐号ID。
 * @param username 帐号用户名。
 * @param paramId 帐号关联的服务器参数ID。
 * @return 如果成功则返回帐号ID；否则返回NOT_SAVED。
 */
- (NSInteger)accountIdByUsername:(NSString *)username andServerParamId:(NSInteger)paramId;

/**
 * 获取帐号密码。
 * @param accountId 帐号ID。
 * @return 如果成功则返回帐号密码；否则返回nil。
 */
- (NSString *)accountPasswordById:(NSInteger)accountId;

/**
 * 获取帐号。
 * @param accountId 帐号ID。
 * @return 如果成功则返回帐号；否则返回nil。
 */
- (Account *)accountWithId:(NSInteger)accountId;

/**
 * 重置当前登录状态记录。
 */
- (void)resetCurrentStatus;

/**
 * 登录帐号。
 * @param account 指定帐号。
 */
- (void)requestLogin:(Account *)account;

/**
 * 退出当前帐号。
 */
- (void)requestLogout;

/**
 * 更改当前帐号在线状态。
 * @param present 目标在线状态。
 */
- (void)requestChangePresent:(UCALIB_PRESENTATIONSTATE)present;

/**
 * 当前帐号是否登录成功。
 * @return 如果登录成功则返回YES；否则返回NO。
 */
- (BOOL)isLoggedIn;

/**
 * 当前帐号是否登录失败。
 * @return 如果登录失败则返回YES；否则返回NO。
 */
- (BOOL)isLoggedInFailed;

/**
 * 当前帐号是否退出成功。
 * @return 如果退出成功则返回YES；否则返回NO。
 */
- (BOOL)isLoggedOut;

/**
 * 当前帐号是否记住密码。
 * @return 如果是则返回YES；否则返回NO。
 */
- (BOOL)isAccountRememberPassword:(NSInteger)accountId;

@end
