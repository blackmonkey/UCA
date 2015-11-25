/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#include "HeadElement.h"

#define HEAD_CELL_REUSE_IDENTIFIER @"HEAD_CELL_REUSE_IDENTIFIER"

/**
 * HeadCell始终放置于最近联系人列表顶部。
 */

@interface HeadCell : UITableViewCell

/**
 * 获取HeadCell的高度。
 * @return HeadCell的高度
 */
+ (CGFloat)height;

/**
 * 为HeadCell实例绑定信息。
 * @param target 必须实现onAvatarClicked。
 * @param type 类型。
 * @param photo 头像。
 * @param countInfo 图标右侧的未读/总数信息。
 * @param name 名称。
 * @param descript 描述信息。
 * @param badgeCount 未读数量标记。
 */
- (void)bindWithTarget:(id)target
                  type:(HeadType)type
                avatar:(UIImage *)photo
             countInfo:(NSString *)countInfo
                  name:(NSString *)name
              descript:(NSString *)descript
            badgeCount:(NSUInteger)badgeCount;

@end
