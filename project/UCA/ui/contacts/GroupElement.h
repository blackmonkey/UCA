/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#include "HeadElement.h"

@class GroupElement;

@protocol GroupElementDelegate <NSObject>

@required
- (void)groupElementAvatarOnClicked:(Group *)group;

@end

@interface GroupElement : HeadElement

@property (nonatomic, retain) Group *group;

- (id)initWithGroup:(Group *)g;
- (id)initWithGroup:(Group *)g andDelegate:(id<GroupElementDelegate>)delegate;

@end
