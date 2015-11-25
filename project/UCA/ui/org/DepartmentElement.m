/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "DepartmentCell.h"
#import "DepartmentElement.h"

@implementation DepartmentElement {
    QuickDialogController *_controller;
}

@synthesize department;

- (id)initWithDepartment:(Department *)_depart {
    self = [super init];
    if (self) {
        department = _depart;
        self.allowSelectInEditMode = NO;
        self.title = _depart.name;
        self.height = [DepartmentCell height];
        self.key = [[NSNumber numberWithInteger:_depart.id] stringValue];
    }

    return self;
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    _controller = controller;

    DepartmentCell *cell = [tableView dequeueReusableCellWithIdentifier:DEPARTMENT_CELL_REUSE_IDENTIFIER];
    if (cell == nil) {
        cell = [[DepartmentCell alloc] init];
    }
    [cell bindWithDepart:department];
    return cell;
}

- (void)selected:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller indexPath:(NSIndexPath *)path {
    if (tableView.editing) {
        return;
    }

    [super selected:tableView controller:controller indexPath:path];
}

@end
