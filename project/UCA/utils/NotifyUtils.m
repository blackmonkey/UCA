/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#undef TAG
#define TAG @"NotifyUtils"

@implementation NotifyUtils

+ (void)postNotification:(NSNotification *)notification {
    UcaLog(TAG, @"post notify: name=%@ object=%@ userinfo=%@", notification.name, notification.object, notification.userInfo);
    [[NSNotificationCenter defaultCenter] performSelectorInBackground:@selector(postNotification:) withObject:notification];
}

+ (void)postNotificationWithName:(NSString *)aName {
    [NotifyUtils postNotificationWithName:aName object:nil userInfo:nil];
}

+ (void)postNotificationWithName:(NSString *)aName object:(id)anObject {
    [NotifyUtils postNotificationWithName:aName object:anObject userInfo:nil];
}

+ (void)postNotificationWithName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    NSNotification *notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
    [NotifyUtils postNotification:notification];
}

+ (void)postNotificationWithName:(NSString *)aName afterDelay:(NSTimeInterval)interval {
    [NotifyUtils postNotificationWithName:aName object:nil userInfo:nil afterDelay:interval];
}

+ (void)postNotificationWithName:(NSString *)aName object:(id)anObject afterDelay:(NSTimeInterval)interval {
    [NotifyUtils postNotificationWithName:aName object:anObject userInfo:nil afterDelay:interval];
}

+ (void)postNotificationWithName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo afterDelay:(NSTimeInterval)interval {
    NSNotification *notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
    [[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) withObject:notification afterDelay:interval];
}

+ (void)cancelNotificationWithName:(NSString *)aName {
    [NotifyUtils cancelNotificationWithName:aName object:nil userInfo:nil];
}

+ (void)cancelNotificationWithName:(NSString *)aName object:(id)anObject {
    [NotifyUtils cancelNotificationWithName:aName object:anObject userInfo:nil];
}

+ (void)cancelNotificationWithName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    NSNotification *notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
    [NotifyUtils cancelPreviousPerformRequestsWithTarget:[NSNotificationCenter defaultCenter]
                                                selector:@selector(postNotification:)
                                                  object:notification];
}

+ (void)alert:(NSString *)msg {
    [NotifyUtils alert:msg delegate:nil];
}

+ (void)alert:(NSString *)msg delegate:(id)delegate {
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:msg
                                                   message:nil
                                                  delegate:delegate
                                         cancelButtonTitle:I18nString(@"确定")
                                         otherButtonTitles:nil];
    [view show];
}

+ (void)confirm:(NSString *)msg delegate:(id)delegate {
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:msg
                                                   message:nil
                                                  delegate:delegate
                                         cancelButtonTitle:I18nString(@"取消")
                                         otherButtonTitles:I18nString(@"确定"), nil];
    [view show];
}

+ (UIAlertView *)progressHud:(NSString *)msg {
    UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:msg
                                                   message:nil
                                                  delegate:nil
                                         cancelButtonTitle:nil
                                         otherButtonTitles:nil];
    [alertview sizeToFit];

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

    // FIXME: hardcoded indicator position
    CGRect rect = indicator.frame;
    rect.origin.x = 129;
    rect.origin.y = 68;
    indicator.frame = rect;
    [indicator startAnimating];

    [alertview addSubview:indicator];
    return alertview;
}

@end