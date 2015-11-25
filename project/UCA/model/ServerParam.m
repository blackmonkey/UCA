/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation ServerParam

@synthesize id;
@synthesize ip;

- (id)init {
    self = [super init];
    if (self) {
        self.id = NOT_SAVED;
        self.ip = @"";
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[ServerParam class]]) {
        ServerParam *param = (ServerParam *)object;
        return self.id == param.id;
    }

    return NO;
}

@end
