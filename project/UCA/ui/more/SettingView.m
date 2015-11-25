/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "SettingView.h"

#define OLD_PWD_KEY   @"OLD_PWD_KEY"
#define NEW_PWD_KEY   @"NEW_PWD_KEY"
#define NEW_PWD2_KEY  @"NEW_PWD2_KEY"

@implementation SettingView

- (QBooleanElement *)createBoolEntry:(NSString *)title value:(BOOL)value {
    QBooleanElement *entry = [[QBooleanElement alloc] initWithTitle:title BoolValue:value];
    entry.onImage = [UIImage imageNamed:@"res/imgOn"];
    entry.offImage = [UIImage imageNamed:@"res/imgOff"];
    return entry;
}

- (void)onImToneChanged:(QBooleanElement *)switcher {
    [UcaAppDelegate sharedInstance].configService.activeImTone = switcher.boolValue;
}

- (void)onCameraOnChanged:(QBooleanElement *)switcher {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    app.configService.activeCamera = switcher.boolValue;
    ucaLib_enable_video(app.accountService.curLoginHandle, switcher.boolValue);
}

- (void)setupAudioSettingEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = [[QSection alloc] init];

    QTextElement *noteElement = [[QTextElement alloc] initWithText:I18nString(@"注意：修改此设置会在下一次收到即时消息时生效")];
    noteElement.color = [UIColor redColor];
    [section addElement:noteElement];

    BOOL defVal = [UcaAppDelegate sharedInstance].configService.activeImTone;
    QBooleanElement *imToneElement = [self createBoolEntry:I18nString(@"即时消息提示音") value:defVal];
    imToneElement.controllerAccessoryAction = @"onImToneChanged:";
    [section addElement:imToneElement];

    // TODO: 其他设置没找到涉及的接口，7月7日后跟迈普确认了再做。

    [root addSection:section];
}

- (void)setupVideoSettingEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = [[QSection alloc] init];

    QTextElement *noteElement = [[QTextElement alloc] initWithText:I18nString(@"注意：修改此设置会在下一次视频会话时生效")];
    noteElement.color = [UIColor redColor];
    [section addElement:noteElement];

    BOOL defVal = [UcaAppDelegate sharedInstance].configService.activeCamera;
    QBooleanElement *cameraOnElement = [self createBoolEntry:I18nString(@"允许视频") value:defVal];
    cameraOnElement.controllerAccessoryAction = @"onCameraOnChanged:";
    [section addElement:cameraOnElement];

    // TODO: 其他设置没找到涉及的接口，7月7日后跟迈普确认了再做。

    [root addSection:section];
}

- (void)setupCallSettingEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = [[QSection alloc] init];

    [root addSection:section];
}

- (void)setupAdvanceSettingEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = [[QSection alloc] init];

    [root addSection:section];
}

- (void)setupSysSettingEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = [[QSection alloc] init];

    QLabelElement *audioSettingElement = [[QLabelElement alloc] initWithTitle:I18nString(@"音频设置") Value:nil];
    [self setupAudioSettingEntry:audioSettingElement];
    [section addElement:audioSettingElement];

    QLabelElement *videoSettingElement = [[QLabelElement alloc] initWithTitle:I18nString(@"视频设置") Value:nil];
    [self setupVideoSettingEntry:videoSettingElement];
    [section addElement:videoSettingElement];

/*
    // TODO: 呼叫设置里的参数不知道涉及到哪些接口，7月7日后跟迈普确认了再做。
    QLabelElement *callSettingElement = [[QLabelElement alloc] initWithTitle:I18nString(@"呼叫设置") Value:nil];
    [self setupCallSettingEntry:callSettingElement];
    [section addElement:callSettingElement];

    // TODO: 7月7日后再做
    QLabelElement *advanceSettingElement = [[QLabelElement alloc] initWithTitle:I18nString(@"高级设置") Value:nil];
    [self setupAdvanceSettingEntry:advanceSettingElement];
    [section addElement:advanceSettingElement];
*/
    [root addSection:section];
}

- (void)commitModify:(QButtonElement *)button {
    QEntryElement *oldPwdElement = (QEntryElement *)[self.root elementWithKey:OLD_PWD_KEY];
    QEntryElement *newPwdElement = (QEntryElement *)[self.root elementWithKey:NEW_PWD_KEY];
    QEntryElement *newPwdElement2 = (QEntryElement *)[self.root elementWithKey:NEW_PWD2_KEY];

    if ([NSString isNullOrEmpty:oldPwdElement.textValue]) {
        [NotifyUtils alert:I18nString(@"旧密码不能为空，请重新输入！")];
        return;
    }
    if ([NSString isNullOrEmpty:newPwdElement.textValue]) {
        [NotifyUtils alert:I18nString(@"新密码不能为空，请重新输入！")];
        return;
    }
    if (![newPwdElement.textValue isEqualToString:newPwdElement2.textValue]) {
        [NotifyUtils alert:I18nString(@"两次输入的新密码不一致，请重新输入！")];
        return;
    }

    NSString *msg = I18nString(@"密码修改成功！");
    UcaAccountService *service = [UcaAppDelegate sharedInstance].accountService;
    UCALIB_ERRCODE res = ucaLib_ChangePasswd(service.curLoginHandle, [oldPwdElement.textValue UTF8String], [newPwdElement.textValue UTF8String]);
    if (res == UCALIB_ERR_OK) {
        if ([service isAccountRememberPassword:service.curAccountId]) {
            [service updateAccount:service.curAccountId password:newPwdElement.textValue];
        }
    } else if (res == UCALIB_ERR_BADOLDPASSWD) {
        msg = I18nString(@"密码修改失败！旧密码输入错误！");
    } else {
        msg = I18nString(@"密码修改失败！");
    }
    [NotifyUtils alert:msg];
}


- (void)setupSecuritySettingEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = nil;
    if ([[UcaAppDelegate sharedInstance].accountService isLoggedIn]) {
        section = [[QSection alloc] initWithTitle:I18nString(@"修改密码")];

        QEntryElement *oldPwdElement = [[QEntryElement alloc] initWithTitle:I18nString(@"旧密码") Value:nil Placeholder:nil];
        oldPwdElement.key = OLD_PWD_KEY;
        oldPwdElement.secureTextEntry = YES;
        [section addElement:oldPwdElement];

        QEntryElement *newPwdElement = [[QEntryElement alloc] initWithTitle:I18nString(@"新密码") Value:nil Placeholder:nil];
        newPwdElement.key = NEW_PWD_KEY;
        newPwdElement.secureTextEntry = YES;
        [section addElement:newPwdElement];

        QEntryElement *newPwdElement2 = [[QEntryElement alloc] initWithTitle:I18nString(@"确认新密码") Value:nil Placeholder:nil];
        newPwdElement2.key = NEW_PWD2_KEY;
        newPwdElement2.secureTextEntry = YES;
        [section addElement:newPwdElement2];

        [root addSection:section];

        section = [[QSection alloc] init];
        QButtonElement *okButton = [[QButtonElement alloc] initWithTitle:I18nString(@"确定")];
        okButton.controllerAction = @"commitModify:";
        [section addElement:okButton];

        [root addSection:section];
    } else {
        section = [[QSection alloc] init];
        QTextElement *infoElement = [[QTextElement alloc] initWithText:I18nString(@"当前账号还没有登录，请登录后再进入此处修改密码。")];
        infoElement.color = [UIColor redColor];
        [section addElement:infoElement];
        [root addSection:section];
    }
}

- (QRootElement *)createForm {
    QRootElement *form = [[QRootElement alloc] init];
    form.grouped = YES;
    form.title = I18nString(@"设置");

    QSection *section = [[QSection alloc] init];

    QLabelElement *sysSettingElement = [[QLabelElement alloc] initWithTitle:I18nString(@"系统设置") Value:nil];
    [self setupSysSettingEntry:sysSettingElement];
    [section addElement:sysSettingElement];

    QLabelElement *secSettingElement = [[QLabelElement alloc] initWithTitle:I18nString(@"安全设置") Value:nil];
    [self setupSecuritySettingEntry:secSettingElement];
    [section addElement:secSettingElement];

    [form addSection:section];
    return form;
}

- (id)init {

    QRootElement *root = [self createForm];
    return [super initWithRoot:root];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Preserve selection between presentations.
    self.quickDialogTableView.backgroundColor = APP_BGCOLOR;
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

@end
