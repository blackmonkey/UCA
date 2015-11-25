/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation ScreenUtils

+ (CGFloat)screenWidth {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsPortrait(orientation)) {
        return [[UIScreen mainScreen] applicationFrame].size.width;
    }
    return [[UIScreen mainScreen] applicationFrame].size.height;
}

+ (CGFloat)screenHeight {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsPortrait(orientation)) {
        return [[UIScreen mainScreen] applicationFrame].size.height;
    }
    return [[UIScreen mainScreen] applicationFrame].size.width;
}

+ (void)setLabelMaxFontSize:(UILabel *)label {
    label.font = [UIFont systemFontOfSize:(label.frame.size.height - 2)];
}

@end
