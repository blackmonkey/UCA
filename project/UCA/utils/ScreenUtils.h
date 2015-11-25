/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * ScreenUtils提供屏幕相关的工具函数。
 */

@interface ScreenUtils : NSObject

/**
 * 获取当前屏幕(横屏/竖屏)的宽度。
 * @return 屏幕宽度。
 */
+ (CGFloat)screenWidth;

/**
 * 获取当前屏幕(横屏/竖屏)的高度。
 * @return 屏幕高度。
 */
+ (CGFloat)screenHeight;

/**
 * 给指定的UILabel设置其能容纳的最大字体。
 */
+ (void)setLabelMaxFontSize:(UILabel *)label;

@end
