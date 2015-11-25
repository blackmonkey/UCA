/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaCallingService : UcaService

@property (nonatomic, readonly, assign) NSString *curCallStatusText;
@property (nonatomic, readonly, assign) NSString *callDuration;

- (void)dialOut:(NSString *)number withVideo:(BOOL)hasVideo fromViewController:(UIViewController *)controller;
- (void)cancelCall;
- (void)pauseCall;
- (void)resumeCall;
- (void)hangupCall;
- (void)transferCall:(NSString *)number;
- (void)muteMic:(NSNumber *)mute;
- (BOOL)isMicMuted;
- (void)switchCamera;
- (BOOL)acceptCall;

@end
