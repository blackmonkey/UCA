/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "RecentLogCell.h"

#define TAG_LABEL_DATE (101)
#define TAG_LABEL_TIME (102)

#define CELL_HEIGHT    (44)
#define ITEM_PADDING   (5)

@implementation RecentLogCell

+ (CGFloat)height {
    return CELL_HEIGHT;
}

- (void)createSubViews {
    self.imageView.backgroundColor = [UIColor clearColor];
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.textColor = [UIColor whiteColor];
    self.detailTextLabel.backgroundColor = [UIColor clearColor];
    self.detailTextLabel.textColor = [UIColor colorFromHex:0xFFFC9D65];

    UILabel *labelDate = [[UILabel alloc] init];
    labelDate.tag = TAG_LABEL_DATE;
    labelDate.font = [UIFont systemFontOfSize:11];
    labelDate.textColor = [UIColor colorFromHex:0xFF646464];
    labelDate.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:labelDate];

    UILabel *labelTime = [[UILabel alloc] init];
    labelTime.tag = TAG_LABEL_TIME;
    labelTime.font = [UIFont systemFontOfSize:11];
    labelTime.textColor = [UIColor colorFromHex:0xFFFC9D65];
    labelTime.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:labelTime];
}

/**
 * 当UITableView进入编辑模式时，UITableCell会被向右推，其contentView.origin.x记录了
 * 被推动的距离；当UITableView退出编辑模式时，UITableCell.contentView.origin.x恢复
 * 为0。此函数根据这一点，来重排所有联系人信息控件。
 */
- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat editOffset = self.contentView.frame.origin.x;
    CGFloat wholeWidth = self.frame.size.width;

    CGRect titleRect = self.textLabel.frame;

    UILabel *labelDate = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_DATE];
    CGRect dateRect = labelDate.frame;
    dateRect.origin.x = wholeWidth - ITEM_PADDING - dateRect.size.width - editOffset;
    dateRect.origin.y = titleRect.origin.y + (titleRect.size.height - dateRect.size.height) / 2;
    labelDate.frame = dateRect;

    UILabel *labelTime = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_TIME];
    CGRect timeRect = labelTime.frame;
    timeRect.origin.x = dateRect.origin.x + (dateRect.size.width - timeRect.size.width) / 2;
    timeRect.origin.y = dateRect.origin.y + dateRect.size.height;
    labelTime.frame = timeRect;
}

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:RECENT_LOG_CELL_REUSE_IDENTIFIER];
    if (self != nil) {
        self.backgroundColor = [UIColor clearColor];
        self.accessoryType = UITableViewCellAccessoryNone;
        [self createSubViews];
    }
    return self;
}

- (void)bindWithRecentLog:(RecentLog *)recentLog {
    self.imageView.image = [UcaConstants iconOfRecentLogType:recentLog.type];
    self.textLabel.text = [UcaConstants descriptionOfRecentLogType:recentLog.type];
    self.detailTextLabel.text = recentLog.number;

    UILabel *labelDate = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_DATE];
    labelDate.text = [NSString getDate:recentLog.datetime];
    [labelDate sizeToFit];

    UILabel *labelTime = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_TIME];
    labelTime.text = [NSString getTime:recentLog.datetime];
    [labelTime sizeToFit];
}

- (void)bindWithLastImDate:(NSDate *)date {
    self.imageView.image = [UIImage imageNamed:@"res/message_recent"];
    self.textLabel.text = I18nString(@"最近消息");
    self.detailTextLabel.text = nil;

    UILabel *labelDate = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_DATE];
    labelDate.text = [NSString getDate:date];
    [labelDate sizeToFit];

    UILabel *labelTime = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_TIME];
    labelTime.text = nil;
    [labelTime sizeToFit];
}

@end
