/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "DepartmentCell.h"

/**
 * 各部门信息控件坐标、尺寸比例。
 * 这些比例直接从视觉原型中测量而得。
 */
#define RATIO_NAME_LEFT (0.1109375) // 名称左边到DepartmentCell左边的距离，相对于DepartmentCell宽度的比例

@implementation DepartmentCell

+ (CGFloat)height {
    return [UIImage imageNamed:@"res/depart_cell_background"].size.height;
}

/**
 * 当UITableView进入编辑模式时，UITableCell会被向右推，其contentView.origin.x记录了
 * 被推动的距离；当UITableView退出编辑模式时，UITableCell.contentView.origin.x恢复
 * 为0。此函数根据这一点，来重排所有联系人信息控件。
 */
- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect rect = self.textLabel.frame;
    rect.origin.x = self.frame.size.width * RATIO_NAME_LEFT - self.contentView.frame.origin.x;
    self.textLabel.frame = rect;
}

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DEPARTMENT_CELL_REUSE_IDENTIFIER];
    if (self != nil) {
        self.backgroundColor = [UIColor clearColor];
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/depart_cell_background"]];
        self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/depart_cell_pressed_background"]];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont systemFontOfSize:18];
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    return self;
}

- (void)bindWithDepart:(Department *)depart {
    self.textLabel.text = depart.name;
}

@end
