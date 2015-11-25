/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaOrgService : UcaService

@property (nonatomic, assign) id addTarget;

- (void)fetchOrgInfoByDepartId:(NSInteger)departId;

- (void)searchOrgInfo:(NSString *)keywords;

- (Department *)getTopRootDepartment;

@end
