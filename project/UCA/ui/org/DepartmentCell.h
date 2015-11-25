/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#define DEPARTMENT_CELL_REUSE_IDENTIFIER @"DEPARTMENT_CELL_REUSE_IDENTIFIER"

/**
 * DepartmentCell用于显示部门列表项，用于组织架构列表。
 */

@interface DepartmentCell : UITableViewCell

/**
 * 获取DepartmentCell的高度。
 * @return DepartmentCell的高度
 */
+ (CGFloat)height;

/**
 * 为DepartmentCell实例绑定信息。
 * @param depart 相应部门。
 */
- (void)bindWithDepart:(Department *)depart;

@end
