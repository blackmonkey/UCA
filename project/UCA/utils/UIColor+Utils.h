/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * UIColor(Utils)提供颜色相关的工具函数。
 */

@interface UIColor(Utils)

/**
 * 从0xAARRGGBB获取UIColor。
 * @param hex 0xAARRGGBB
 */
+ (UIColor *)colorFromHex:(NSUInteger)hex;

@end
