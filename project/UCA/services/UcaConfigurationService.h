/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaConfigurationService : UcaService {
@protected
    NSUserDefaults* defaults;
}

@property (nonatomic, assign) NSInteger lastLoginAccountId;
@property (nonatomic, assign) BOOL activeImTone;
@property (nonatomic, assign) BOOL activeCamera;
@property (readonly, assign) NSUInteger maxShowImLength;
@property (nonatomic, retain) NSURL *imBaseUrl;
@property (readonly, retain) NSDictionary *emotes;

/**
 * 获取汉字的拼音首字母。
 * @param chr 汉字。
 * @return 拼音首字母。
 */
- (NSString *)getInitialOfCnChr:(NSString *)chr;

@end
