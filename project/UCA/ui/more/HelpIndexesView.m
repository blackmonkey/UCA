/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "HelpIndexesView.h"

@implementation HelpIndexesView {
    NSDictionary *_helpInfo;
}

- (void)setupInfoEntryWithTitle:(NSString *)title andInfoKey:(NSString *)key forRoot:(QSection *)root {
    QLabelElement *entryElement = [[QLabelElement alloc] initWithTitle:title Value:nil];
    entryElement.grouped = YES;

    QSection *section = [[QSection alloc] init];
    QTextElement *infoElement = [[QTextElement alloc] initWithText:[_helpInfo objectForKey:key]];
    [section addElement:infoElement];
    [entryElement addSection:section];

    [root addElement:entryElement];
}

- (void)setupHelpEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = [[QSection alloc] init];
    QTextElement *tipElement = [[QTextElement alloc] initWithText:[_helpInfo objectForKey:@"help_tip"]];
    [section addElement:tipElement];
    [root addSection:section];

    section = [[QSection alloc] initWithTitle:I18nString(@"我们为你提供什么帮助？")];

    [self setupInfoEntryWithTitle:I18nString(@"UCA【登录帐号】") andInfoKey:@"help_login_info" forRoot:section];
    [self setupInfoEntryWithTitle:I18nString(@"UCA【切换帐号】") andInfoKey:@"help_switch_account_info" forRoot:section];
    [self setupInfoEntryWithTitle:I18nString(@"UCA【组织架构】") andInfoKey:@"help_custom_hisotlogy_info" forRoot:section];
    [self setupInfoEntryWithTitle:I18nString(@"UCA【联系人】") andInfoKey:@"help_contacts_info" forRoot:section];
    [self setupInfoEntryWithTitle:I18nString(@"UCA【拨号盘】") andInfoKey:@"help_numpad_info" forRoot:section];
    [self setupInfoEntryWithTitle:I18nString(@"UCA【我的资料】") andInfoKey:@"help_account_info" forRoot:section];

    [root addSection:section];
}

- (void)setupTechHelpEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = [[QSection alloc] init];
    QTextElement *element = [[QTextElement alloc] initWithText:[_helpInfo objectForKey:@"help_tech_info"]];
    [section addElement:element];
    [root addSection:section];
}

- (void)setupDemoEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = [[QSection alloc] init];
    QEmptyListElement *element = [[QEmptyListElement alloc] initWithTitle:[_helpInfo objectForKey:@"help_none_info"] Value:nil];
    [section addElement:element];
    [root addSection:section];
}

- (void)setupAboutEntry:(QRootElement *)root {
    root.grouped = YES;

    QSection *section = nil;

#ifdef SHOW_BUILD_INFO
    NSDictionary *buildInfo = [[NSBundle mainBundle] infoDictionary];

    section = [[QSection alloc] initWithTitle:@"Build Information"];

    NSString *version = [NSString stringOfUTF8String:UCALIBSDK_VERSION];
    QLabelElement *buildVersion = [[QLabelElement alloc] initWithTitle:@"Build Version" Value:version];
    [section addElement:buildVersion];

    QLabelElement *buildNumber = [[QLabelElement alloc] initWithTitle:@"Build Number" Value:[buildInfo objectForKey:@"CFBuildNumber"]];
    [section addElement:buildNumber];

    QLabelElement *buildDate = [[QLabelElement alloc] initWithTitle:@"Build Date" Value:[buildInfo objectForKey:@"CFBuildDate"]];
    [section addElement:buildDate];

    [root addSection:section];
#endif

    section = [[QSection alloc] init];
    QTextElement *element = [[QTextElement alloc] initWithText:[_helpInfo objectForKey:@"help_about_info"]];
    [section addElement:element];
    [root addSection:section];
}

- (QRootElement *)createForm {
    QRootElement *form = [[QRootElement alloc] init];
    form.grouped = YES;
    form.title = I18nString(@"帮助");

    QSection *indexesSection = [[QSection alloc] init];

    QLabelElement *helpElement = [[QLabelElement alloc] initWithTitle:I18nString(@"寻求帮助") Value:nil];
    [self setupHelpEntry:helpElement];
    [indexesSection addElement:helpElement];

    QLabelElement *techHelpElement = [[QLabelElement alloc] initWithTitle:I18nString(@"寻求技术帮助") Value:nil];
    [self setupTechHelpEntry:techHelpElement];
    [indexesSection addElement:techHelpElement];

#ifdef ENABLE_VIDEO_TUTORIAL
    QLabelElement *demoElement = [[QLabelElement alloc] initWithTitle:I18nString(@"视频演示") Value:nil];
    [self setupDemoEntry:demoElement];
    [indexesSection addElement:demoElement];
#endif

    QLabelElement *aboutElement = [[QLabelElement alloc] initWithTitle:I18nString(@"关于UCA") Value:nil];
    [self setupAboutEntry:aboutElement];
    [indexesSection addElement:aboutElement];

    [form addSection:indexesSection];
    return form;
}

- (id)init {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"helpinfo" ofType:@"plist"];
    _helpInfo = [[NSDictionary alloc] initWithContentsOfFile:path];

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
