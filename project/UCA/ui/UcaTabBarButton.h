/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaToolButton.h"

@interface UcaTabBarButton : UcaToolButton

- (UcaTabBarButton *)initWithTitle:(NSString *)title imageName:(NSString *)imgName tag:(NSInteger)tag;

/**
 * 显示提醒图标。
 */
- (void)showBadge;

/**
 * 隐藏提醒图标。
 */
- (void)hideBadge;

/**
 * 设置提醒图标。
 * @param img 提醒图标。
 * @param margin 提醒图标四边的margin。
 * @param hAlign 提醒图标相对于按钮本身的水平对齐。
 * @param vAlign 提醒图标相对于按钮本身的竖直对齐。
 * @param blink 是否闪烁显示提醒图标。
 */
- (void)setBadge:(UIImage *)img;
- (void)setBadge:(UIImage *)img
          margin:(CGFloat)margin
          hAlign:(UIControlContentHorizontalAlignment)hAlign
          vAlign:(UIControlContentVerticalAlignment)vAlign
           blink:(BOOL)blink;

@end
