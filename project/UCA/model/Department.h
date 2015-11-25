/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <Foundation/Foundation.h>

#define TOP_ROOT_DEPART_ID (-1)

/**
 * Department记录部门相关信息
 */
@interface Department : NSObject

// 解析XML获取的信息
@property (nonatomic, assign) NSInteger id;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *urlName;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *office;
@property (nonatomic, retain) Department *parent;
@property (nonatomic, retain) NSMutableArray *subDeparts;
@property (nonatomic, retain) NSMutableArray *userInfos;

// 搜索所用的信息
@property (nonatomic, assign) NSUInteger totalCount;
@property (readonly, assign) NSUInteger fetchedCount;
@property (nonatomic, assign) BOOL fetchedInfos;

- (void)copyBaseInfo:(Department *)depart;
- (void)addSubDepart:(Department *)depart;
- (Department *)getSubDepartById:(NSInteger)departId;

@end
