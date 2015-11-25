/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation UIButton(Utils)

+ (UIButton *)buttonWithImageName:(NSString *)imgName andTarget:(__strong id)target andAction:(SEL)method {
    NSString *pressedImgName = [imgName stringByAppendingString:@"_pressed"];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:pressedImgName] forState:UIControlStateHighlighted];
    [btn setImage:[UIImage imageNamed:pressedImgName] forState:UIControlStateSelected];
    [btn addTarget:target action:method forControlEvents:UIControlEventTouchUpInside];

    CGRect rect = btn.frame;
    rect.size = [UIImage imageNamed:imgName].size;
    btn.frame = rect;

    return btn;
}

@end
