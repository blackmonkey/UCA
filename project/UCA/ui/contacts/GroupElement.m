/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "GroupElement.h"
#import "HeadCell.h"
#import "GroupDetailsEntry.h"

@implementation GroupElement {
    id<GroupElementDelegate> _delegate;
}

@synthesize group;

- (id)initWithGroup:(Group *)g {
    return [self initWithGroup:g andDelegate:nil];
}

- (id)initWithGroup:(Group *)g andDelegate:(id<GroupElementDelegate>)delegate {
    self = [super init];
    if (self) {
        self.group = g;
        _delegate = delegate;
    }

    return self;
}

- (void)onAvatarClicked {
    if(_delegate && [_delegate respondsToSelector:@selector(groupElementAvatarOnClicked:)]){
        [_delegate groupElementAvatarOnClicked:self.group];
    }
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    HeadCell *cell = [tableView dequeueReusableCellWithIdentifier:HEAD_CELL_REUSE_IDENTIFIER];
    if (cell == nil) {
        cell = [[HeadCell alloc] init];
    }

    [cell bindWithTarget:self
                    type:HeadType_Group
                  avatar:self.group.photo
               countInfo:self.group.countInfo
                    name:self.group.name
                descript:self.group.annunciate
              badgeCount:self.group.unreadCount];

    return cell;
}

@end
