/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation UIColor(Utils)

+ (UIColor *)colorFromHex:(NSUInteger)hex {
    CGFloat r = ((hex & 0xFF0000) >> 16);
    CGFloat g = ((hex & 0xFF00) >> 8);
    CGFloat b =  (hex & 0xFF);
    CGFloat a = ((hex & 0xFF000000) >> 24);
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
}

@end
