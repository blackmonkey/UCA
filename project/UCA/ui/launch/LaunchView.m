/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "LaunchView.h"

@implementation LaunchView

- (void)switchToLoginView {
    [UIImageView setAnimationDelegate:nil];
    [[UcaAppDelegate sharedInstance] performSelector:@selector(showLoginView) withObject:nil afterDelay:3];
}

- (void)loadView {
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/launch_logo"]];
    self.view = logoView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    /* 保存logo原始位置 */
    CGRect orgRect = self.view.frame;

    /* 将logo移出屏幕外（屏幕上方） */
    CGRect rect = orgRect;
    rect.origin.y = -5 - rect.size.height;
    self.view.frame = rect;

    /* 从上往下动画显示logo */
    [UIImageView beginAnimations:@"showLogo" context:nil];
    [UIImageView setAnimationBeginsFromCurrentState:YES];
    [UIImageView setAnimationDuration:0.75];
    [UIImageView setAnimationDelegate:self];
    [UIImageView setAnimationDidStopSelector:@selector(switchToLoginView)];
    [UIImageView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:YES];
    self.view.frame = orgRect;
    [UIImageView commitAnimations];
}

@end
