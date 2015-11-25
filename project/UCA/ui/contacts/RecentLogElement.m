/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "RecentLogElement.h"
#import "RecentLogCell.h"

@implementation RecentLogElement

@synthesize recentLog;
@synthesize lastImDate;

- (id)initWithRecentLog:(RecentLog *)log {
    self = [super init];
    if (self) {
        self.allowSelectInEditMode = YES;
        self.recentLog = log;
        self.lastImDate = nil;
        self.height = [RecentLogCell height];
    }

    return self;
}

- (id)initWithLastImDate:(NSDate *)date {
    self = [super init];
    if (self) {
        self.allowSelectInEditMode = NO;
        self.recentLog = nil;
        self.lastImDate = date;
        self.height = [RecentLogCell height];
    }

    return self;
}


- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    RecentLogCell *cell = [tableView dequeueReusableCellWithIdentifier:RECENT_LOG_CELL_REUSE_IDENTIFIER];
    if (cell == nil) {
        cell = [[RecentLogCell alloc] init];
    }
    if (self.recentLog) {
        [cell bindWithRecentLog:self.recentLog];
    } else {
        [cell bindWithLastImDate:self.lastImDate];
    }
    return cell;
}

- (void)selected:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller indexPath:(NSIndexPath *)path {
    [super selected:tableView controller:controller indexPath:path];

    // TODO: call back or IM back on the number of recentLog, while fetch the contact name.
}

@end
