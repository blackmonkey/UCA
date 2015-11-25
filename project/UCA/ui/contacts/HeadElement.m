/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "HeadCell.h"
#import "HeadElement.h"

@implementation HeadElement

@synthesize type;
@synthesize countInfo;
@synthesize name;
@synthesize descript;
@synthesize badgeCount;

- (id)init {
    self = [super init];
    if (self) {
        self.allowSelectInEditMode = NO;
        self.height = [HeadCell height];
    }

    return self;
}

- (id)initWithSession:(Session *)session {
    self = [self init];
    if (self) {
        self.object = session;
        self.type = HeadType_Session;
        self.countInfo = session.countInfo;
        self.name = session.name;
        self.descript = session.descrip;
        self.badgeCount = session.unreadCount;
    }
    return self;
}

- (void)setName:(NSString *)_name {
    self->name = _name;
    self.title = _name;
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    HeadCell *cell = [tableView dequeueReusableCellWithIdentifier:HEAD_CELL_REUSE_IDENTIFIER];
    if (cell == nil) {
        cell = [[HeadCell alloc] init];
    }
    [cell bindWithTarget:self
                    type:self.type
                  avatar:nil
               countInfo:self.countInfo
                    name:self.name
                descript:self.descript
              badgeCount:self.badgeCount];
    return cell;
}

- (void)selected:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller indexPath:(NSIndexPath *)path {
    if (tableView.editing) {
        return;
    }

    [super selected:tableView controller:controller indexPath:path];
}

@end
