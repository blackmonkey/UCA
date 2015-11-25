/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaNavigationController.h"
#import "UcaTabBarController.h"

@interface UcaAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) UcaNavigationController *navigationController;
@property (strong, nonatomic) UcaTabBarController *tabBarController;
@property (readonly, retain) UcaAccountService *accountService;
@property (readonly, retain) UcaConfigurationService *configService;
@property (readonly, retain) UcaDatabaseService *databaseService;
@property (readonly, retain) UcaServerParamService *serverParamService;
@property (readonly, retain) UcaContactService *contactService;
@property (readonly, retain) UcaMessageService *messageService;
@property (readonly, retain) UcaCallingService *callingService;
@property (readonly, retain) UcaOrgService *orgService;
@property (readonly, retain) UcaRecentService *recentService;
@property (readonly, retain) UcaGroupService *groupService;
@property (readonly, retain) UcaSessionService *sessionService;

+ (UcaAppDelegate *)sharedInstance;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)showLoginView;
- (void)showTabViews;

@end
