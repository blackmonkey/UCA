/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "Department.h"

@implementation Department

@synthesize id;
@synthesize url;
@synthesize urlName;
@synthesize name;
@synthesize office;
@synthesize parent;
@synthesize subDeparts;
@synthesize userInfos;
@synthesize totalCount;
@synthesize fetchedCount;
@synthesize fetchedInfos;

- (id)init {
    self = [super init];
    if (self) {
        self.id = NOT_SAVED;
        self.url = nil;
        self.urlName = nil;
        self.name = nil;
        self.office = nil;
        self.parent = nil;
        self.subDeparts = [NSMutableArray array];
        self.userInfos = [NSMutableArray array];
        self.totalCount = NSUIntegerMax;
        self.fetchedInfos = NO;
    }

    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[Department class]]) {
        Department *depart = (Department *)object;
        return self.id == depart.id;
    }

    return NO;
}

- (NSUInteger)fetchedCount {
    return (self.subDeparts.count + self.userInfos.count);
}

- (void)copyBaseInfo:(Department *)depart {
    self.id = depart.id;
    self.url = depart.url;
    self.urlName = depart.urlName;
    self.name = depart.name;
    self.office = depart.office;
}

- (void)addSubDepart:(Department *)depart {
    [self.subDeparts addObject:depart];
    depart.parent = self;
}

- (Department *)getSubDepartById:(NSInteger)departId {
    for (Department *depart in self.subDeparts) {
        if (depart.id == departId) {
            return depart;
        }
    }
    return nil;
}

@end
