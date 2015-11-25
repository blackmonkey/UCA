/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "AccountListView.h"
#import "LoginView.h"

#undef TAG
#define TAG @"AccountListView"

#define ACCOUNT_LIST_FORM       @"ACCOUNT_LIST_FORM"
#define NEW_ACCOUNT_FORM        @"NEW_ACCOUNT_FORM"
#define EDIT_ACCOUNT_FORM       @"EDIT_ACCOUNT_FORM"
#define ACCOUNT_MENU_FORM       @"ACCOUNT_MENU_FORM"
#define INPUT_PASSWORD_FORM     @"INPUT_PASSWORD_FORM"
#define USERNAME_ENTRY          @"USERNAME_ENTRY"
#define PASSWORD_ENTRY          @"PASSWORD_ENTRY"
#define REMEMBER_PASSWORD_ENTRY @"REMEMBER_PASSWORD_ENTRY"
#define SERVER_ENTRY            @"SERVER_ENTRY"

@implementation AccountListView {
    Account *_accountToDelete;
}

- (Account *)getBoundAccount:(QElement *)element {
    return [[UcaAppDelegate sharedInstance].accountService accountWithLoginInfo:[(NSNumber *)element.object integerValue]];
}

- (void)commitModify:(QButtonElement *)button {
    QRootElement *rootElement = button.parentSection.rootElement;
    NSInteger accountId = [(NSNumber *)rootElement.object integerValue];

    QEntryElement *entry = (QAutoEntryElement *) [rootElement elementWithKey:SERVER_ENTRY];
    if ([NSString isNullOrEmpty:entry.textValue]) {
        [NotifyUtils alert:I18nString(@"请输入服务器IP地址！")];
        return;
    } else if (![NSString isValidIp:entry.textValue]) {
        [NotifyUtils alert:I18nString(@"该服务器IP地址无效，请重新输入！")];
        return;
    }

    UcaServerParamService *service = [UcaAppDelegate sharedInstance].serverParamService;
    ServerParam *param = [[ServerParam alloc] init];
    param.ip = entry.textValue;
    param.id = [service paramIdByIp:param.ip];
    if (param.id == NOT_SAVED) {
        param.id = [service addParamWithIp:param.ip];
    }

    QBooleanElement *boolEntry = (QBooleanElement *) [rootElement elementWithKey:REMEMBER_PASSWORD_ENTRY];

    [[UcaAppDelegate sharedInstance].accountService updateAccount:accountId
                                                    serverParamId:param.id
                                                 rememberPassword:boolEntry.boolValue];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)commitNewAccount:(QButtonElement *)button {
    Account *newAccount = [[Account alloc] init];
    QRootElement *rootElement = button.parentSection.rootElement;

    QEntryElement *entry = (QEntryElement *) [rootElement elementWithKey:USERNAME_ENTRY];
    if ([NSString isNullOrEmpty:entry.textValue]) {
        [NotifyUtils alert:I18nString(@"请输入用户名！")];
        return;
    }
    newAccount.username = entry.textValue;

    entry = (QEntryElement *) [rootElement elementWithKey:PASSWORD_ENTRY];
    if ([NSString isNullOrEmpty:entry.textValue]) {
        [NotifyUtils alert:I18nString(@"请输入密码！")];
        return;
    }
    newAccount.password = entry.textValue;

    QAutoEntryElement *paramEntry = (QAutoEntryElement *) [rootElement elementWithKey:SERVER_ENTRY];
    if ([NSString isNullOrEmpty:paramEntry.textValue]) {
        [NotifyUtils alert:I18nString(@"请输入服务器IP地址！")];
        return;
    } else if (![NSString isValidIp:paramEntry.textValue]) {
        [NotifyUtils alert:I18nString(@"该服务器IP地址无效，请重新输入！")];
        return;
    }

    newAccount.serverParam = [[ServerParam alloc] init];
    UcaServerParamService *paramService = [UcaAppDelegate sharedInstance].serverParamService;
    newAccount.serverParam.ip = paramEntry.textValue;
    newAccount.serverParam.id = [paramService paramIdByIp:newAccount.serverParam.ip];
    if (newAccount.serverParam.id == NOT_SAVED) {
        newAccount.serverParam.id = [paramService addParamWithIp:newAccount.serverParam.ip];
    }

    QBooleanElement *boolEntry = (QBooleanElement *) [rootElement elementWithKey:REMEMBER_PASSWORD_ENTRY];
    newAccount.rememberPassword = boolEntry.boolValue;

    UcaAccountService *accountService = [UcaAppDelegate sharedInstance].accountService;
    newAccount.id = [accountService accountIdByUsername:newAccount.username andServerParamId:newAccount.serverParam.id];
    if (newAccount.id != NOT_SAVED) {
        Account *accountInDb = [accountService accountWithLoginInfo:newAccount.id];
        if (accountInDb.rememberPassword && ![NSString isNullOrEmpty:accountInDb.password] && ![newAccount.password isEqualToString:accountInDb.password]) {
            [NotifyUtils alert:I18nString(@"输入的密码不对，请重新输入！")];
            return;
        }
    }

    LoginView *view = [[LoginView alloc] initWithAccount:newAccount];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)commitLogin:(QButtonElement *)button {
    QRootElement *rootElement = button.parentSection.rootElement;
    Account *account = [self getBoundAccount:rootElement];

    if ([rootElement.key isEqualToString:INPUT_PASSWORD_FORM]) {
        QEntryElement *entry = (QEntryElement *) [rootElement elementWithKey:PASSWORD_ENTRY];
        if ([NSString isNullOrEmpty:entry.textValue]) {
            [NotifyUtils alert:I18nString(@"请输入密码！")];
            return;
        }
        account.password = entry.textValue;
        // 此时不必将新密码存入数据库，因为不知道新密码是否有效。
        // 当成功登录后，会同步服务器上的账号信息，并更新数据表记录，此时新密码会被存入数据库。
    }

    LoginView *view = [[LoginView alloc] initWithAccount:account];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)workOffline:(QButtonElement *)button {
    UcaAppDelegate *appDelegate = [UcaAppDelegate sharedInstance];
    appDelegate.accountService.curAccountId = [(NSNumber *)button.object integerValue];
    [appDelegate showTabViews];
}

- (void)confirmDelete:(QButtonElement *)button {
    _accountToDelete = [self getBoundAccount:button];
    NSString *msg = [NSString stringWithFormat:I18nString(@"确定要删除该账号吗？\n%@ @ %@"), _accountToDelete.username, _accountToDelete.serverParam.ip];
    [NotifyUtils confirm:msg delegate:self];
}

- (void)deleteAccount {
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
    if ([service deleteAccount:_accountToDelete.id]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [NotifyUtils alert:I18nString(@"删除账号失败！")];
    }
}

- (void)cancelMenu:(QButtonElement *)button {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupInputPasswordFormWithRoot:(QRootElement *)rootElement {
    rootElement.key = INPUT_PASSWORD_FORM;
    rootElement.grouped = YES;

    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"请输入登录密码")];
    QEntryElement *passwordEntry = [[QEntryElement alloc] initWithTitle:nil Value:nil Placeholder:I18nString(@"密码")];
    passwordEntry.key = PASSWORD_ENTRY;
    passwordEntry.secureTextEntry = YES;
    [section addElement:passwordEntry];
    [rootElement addSection:section];

    section = [[QSection alloc] init];
    QButtonElement *btnElement = [[QButtonElement alloc] initWithTitle:I18nString(@"登录")];
    btnElement.controllerAction = @"commitLogin:";
    [section addElement:btnElement];
    [rootElement addSection:section];
}

- (void)setupEditAccountFormWithRoot:(QRootElement *)rootElement andAccount:(Account *)account {
    rootElement.key = EDIT_ACCOUNT_FORM;
    rootElement.grouped = YES;

    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"帐号")];
    // 帐号名永远不能修改
    QLabelElement *usernameEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"用户名") Value:account.username];
    [section addElement:usernameEntry];

    // 未登录状态下，不能修改密码
    QLabelElement *passwordEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"密码") Value:@"******"];
    [section addElement:passwordEntry];
    [rootElement addSection:section];

    section = [[QSection alloc] init];
    QBooleanElement *rememberPasswordEntry = [[QBooleanElement alloc] initWithTitle:I18nString(@"是否记住密码") BoolValue:account.rememberPassword];
    rememberPasswordEntry.key = REMEMBER_PASSWORD_ENTRY;
    rememberPasswordEntry.onImage = [UIImage imageNamed:@"res/imgOn"];
    rememberPasswordEntry.offImage = [UIImage imageNamed:@"res/imgOff"];
    [section addElement:rememberPasswordEntry];
    [rootElement addSection:section];

    section = [[QSection alloc] initWithTitle:I18nString(@"服务器")];
    QAutoEntryElement *serverEntry = [[QAutoEntryElement alloc] initWithTitle:nil value:account.serverParam.ip placeholder:I18nString(@"IP地址")];
    serverEntry.key = SERVER_ENTRY;
    serverEntry.autoCompleteValues = [[UcaAppDelegate sharedInstance].serverParamService serverIps];
    serverEntry.autoCompleteColor = [UIColor orangeColor];
#if __IPHONE_4_1 <= __IPHONE_OS_VERSION_MAX_ALLOWED
    serverEntry.keyboardType = UIKeyboardTypeDecimalPad;
#else
    serverEntry.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
#endif
    [section addElement:serverEntry];
    [rootElement addSection:section];

    section = [[QSection alloc] init];
    QButtonElement *okButton = [[QButtonElement alloc] initWithTitle:I18nString(@"确定")];
    okButton.controllerAction = @"commitModify:";
    [section addElement:okButton];
    [rootElement addSection:section];
}

- (void)updateEditForm {
    @synchronized (self) {
        Account *account = [self getBoundAccount:self.root];
        QBooleanElement *rememberPasswordEntry = (QBooleanElement *)[self.root elementWithKey:REMEMBER_PASSWORD_ENTRY];
        rememberPasswordEntry.boolValue = account.rememberPassword;
        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}

- (void)updateMenuForm {
    @synchronized (self) {
        if ([self.root numberOfSections] <= 0) {
            return;
        }
        QSection *section = [self.root getSectionForIndex:0];
        if ([section.elements count] <= 0) {
            return;
        }

        Account *account = [self getBoundAccount:self.root];
        QButtonElement *btnElement = (QButtonElement *)[section.elements objectAtIndex:0]; // "登录"按钮的子界面
        [btnElement.sections removeAllObjects];
        if (account.rememberPassword && ![NSString isNullOrEmpty:account.password]) {
            btnElement.controllerAction = @"commitLogin:";
        } else {
            btnElement.controllerAction = nil;
            [self setupInputPasswordFormWithRoot:btnElement];
        }
        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}

- (void)setupNewAccountFormWithRoot:(QRootElement *)rootElement {
    rootElement.title = I18nString(@"新帐号登录");
    rootElement.key = NEW_ACCOUNT_FORM;
    rootElement.grouped = YES;

    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"帐号")];

    QEntryElement *usernameEntry = [[QEntryElement alloc] initWithTitle:nil Value:nil Placeholder:I18nString(@"用户名")];
    usernameEntry.key = USERNAME_ENTRY;
    usernameEntry.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameEntry.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [section addElement:usernameEntry];

    QEntryElement *passwordEntry = [[QEntryElement alloc] initWithTitle:nil Value:nil Placeholder:I18nString(@"密码")];
    passwordEntry.key = PASSWORD_ENTRY;
    passwordEntry.secureTextEntry = YES;
    [section addElement:passwordEntry];

    [rootElement addSection:section];

    section = [[QSection alloc] init];
    QBooleanElement *rememberPasswordEntry = [[QBooleanElement alloc] initWithTitle:I18nString(@"是否记住密码") BoolValue:NO];
    rememberPasswordEntry.key = REMEMBER_PASSWORD_ENTRY;
    rememberPasswordEntry.onImage = [UIImage imageNamed:@"res/imgOn"];
    rememberPasswordEntry.offImage = [UIImage imageNamed:@"res/imgOff"];
    [section addElement:rememberPasswordEntry];
    [rootElement addSection:section];

    section = [[QSection alloc] initWithTitle:I18nString(@"服务器")];
    QAutoEntryElement *serverEntry = [[QAutoEntryElement alloc] initWithTitle:nil value:nil placeholder:I18nString(@"IP地址")];
    serverEntry.key = SERVER_ENTRY;
    serverEntry.autoCompleteValues = [[UcaAppDelegate sharedInstance].serverParamService serverIps];
    serverEntry.autoCompleteColor = [UIColor orangeColor];
#if __IPHONE_4_1 <= __IPHONE_OS_VERSION_MAX_ALLOWED
    serverEntry.keyboardType = UIKeyboardTypeDecimalPad;
#else
    serverEntry.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
#endif
    [section addElement:serverEntry];
    [rootElement addSection:section];

    section = [[QSection alloc] init];
    QButtonElement *okButton = [[QButtonElement alloc] initWithTitle:I18nString(@"确定")];
    okButton.controllerAction = @"commitNewAccount:";
    [section addElement:okButton];
    [rootElement addSection:section];
}

- (QElement *)createAccountEntry:(Account *)account {
    NSNumber *boundObj = [NSNumber numberWithInteger:account.id];

    QLabelElement *rootEntry = [[QLabelElement alloc] initWithTitle:account.username Value:account.serverParam.ip];
    rootEntry.key = ACCOUNT_MENU_FORM;
    rootEntry.grouped = YES;
    rootEntry.object = boundObj;
    if (account.photo) {
        rootEntry.image = account.photo;
    } else {
        rootEntry.image = [UIImage imageNamed:@"res/default_avatar_small"];
    }

    QSection *section = [[QSection alloc] init];

    QButtonElement *btnElement = [[QButtonElement alloc] initWithTitle:I18nString(@"登录")];
    btnElement.object = boundObj;
    if (account.rememberPassword && ![NSString isNullOrEmpty:account.password]) {
        btnElement.controllerAction = @"commitLogin:";
    } else {
        [self setupInputPasswordFormWithRoot:btnElement];
    }
    [section addElement:btnElement];

    btnElement = [[QButtonElement alloc] initWithTitle:I18nString(@"更改登录信息")];
    btnElement.object = boundObj;
    [self setupEditAccountFormWithRoot:btnElement andAccount:account];
    [section addElement:btnElement];

    btnElement = [[QButtonElement alloc] initWithTitle:I18nString(@"离线查看")];
    btnElement.object = boundObj;
    btnElement.controllerAction = @"workOffline:";
    [section addElement:btnElement];

    btnElement = [[QButtonElement alloc] initWithTitle:I18nString(@"删除帐号")];
    btnElement.object = boundObj;
    btnElement.controllerAction = @"confirmDelete:";
    [section addElement:btnElement];

    btnElement = [[QButtonElement alloc] initWithTitle:I18nString(@"返回")];
    btnElement.controllerAction = @"cancelMenu:";
    [section addElement:btnElement];

    [rootEntry addSection:section];

    return rootEntry;
}

- (void)setupRoot:(QRootElement *)rootElement withAccounts:(NSArray *)accounts {
    rootElement.grouped = YES;
    rootElement.title = I18nString(@"统一通讯助理");
    rootElement.key = ACCOUNT_LIST_FORM;

    Account *account = nil;
    QSection *section = [[QSection alloc] initWithTitle:I18nString(@"选择登录帐号")];
    for (int i = 0; i < [accounts count]; i++) {
        account = [accounts objectAtIndex:i];
        [section addElement:[self createAccountEntry:account]];
    }
    [rootElement addSection:section];

    section = [[QSection alloc] init];
    QLabelElement *newEntry = [[QLabelElement alloc] initWithTitle:I18nString(@"新帐号登录") Value:nil];
    newEntry.image = [UIImage imageNamed:@"res/edit_account"];
    [self setupNewAccountFormWithRoot:newEntry];
    [section addElement:newEntry];
    [rootElement addSection:section];
}

- (void)reloadDataAndRefresh {
    @synchronized (self) {
        NSArray *accounts = [[UcaAppDelegate sharedInstance].accountService accountsWithLoginInfo];
        [self.root.sections removeAllObjects];

        if ([accounts count] > 0) {
            [self setupRoot:self.root withAccounts:accounts];
        } else {
            [self setupNewAccountFormWithRoot:self.root];
        }
        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}

- (QRootElement *)createForm {
    QRootElement *form = [[QRootElement alloc] init];
    form.grouped = YES;
    form.title = I18nString(@"统一通讯助理");
    form.key = ACCOUNT_LIST_FORM;
    return form;
}

- (id)init {
    QRootElement *root = [self createForm];
    self = [super initWithRoot:root];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.quickDialogTableView.backgroundColor = APP_BGCOLOR;
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([self.root.key isEqualToString:ACCOUNT_LIST_FORM]) {
        self.navigationItem.hidesBackButton = YES;
        [self reloadDataAndRefresh];
    } else {
        self.navigationItem.hidesBackButton = NO;
        if ([self.root.key isEqualToString:EDIT_ACCOUNT_FORM]) {
            [self updateEditForm];
        } else if ([self.root.key isEqualToString:ACCOUNT_MENU_FORM]) {
            [self updateMenuForm];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

#pragma UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)_alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 确定删除账号
        [self deleteAccount];
    }
}

@end
