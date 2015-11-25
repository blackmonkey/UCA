/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#define RECENT_LOG_CELL_REUSE_IDENTIFIER @"RECENT_LOG_CELL_REUSE_IDENTIFIER"

/**
 * RecentLogCell用语显示最近通讯记录的信息。
 */

@interface RecentLogCell : UITableViewCell

/**
 * 获取RecentLogCell的高度。
 * @return RecentLogCell的高度
 */
+ (CGFloat)height;

/**
 * 为RecentLogCell实例绑定最近通讯记录。
 * @param recentLog ;
 */
- (void)bindWithRecentLog:(RecentLog *)recentLog;

- (void)bindWithLastImDate:(NSDate *)date;

@end


