/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "RecentLog.h"

@interface RecentLogElement : QRootElement

@property (nonatomic, retain) RecentLog *recentLog;
@property (nonatomic, retain) NSDate *lastImDate;

- (id)initWithRecentLog:(RecentLog *)log;
- (id)initWithLastImDate:(NSDate *)date;

@end
