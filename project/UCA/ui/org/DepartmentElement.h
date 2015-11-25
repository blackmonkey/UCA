/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <Foundation/Foundation.h>

@interface DepartmentElement : QRootElement

@property (nonatomic, retain) Department *department;

- (id)initWithDepartment:(Department *)_depart;

@end
