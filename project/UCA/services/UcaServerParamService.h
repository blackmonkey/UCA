/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaServerParamService : UcaService

@property (readonly, retain) NSArray *serverIps;

- (NSInteger)addParamWithIp:(NSString *)ip;
- (NSInteger)paramIdByIp:(NSString *)ip;
- (BOOL)updateParamById:(NSInteger)id withValue:(NSString *)ip;

@end
