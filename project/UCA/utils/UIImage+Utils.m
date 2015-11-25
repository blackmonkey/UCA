/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation UIImage(Utils)

- (UIImage *)resizeFromCenter {
    int left = ((int)self.size.width) / 2;
    int top = ((int)self.size.height) / 2;
    int right = ((int)self.size.width) - left - 1;
    int bottom = ((int)self.size.height) - top - 1;
    return [self resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right)];
}

+ (UIImage *)detailBackground {
    UIImage *bg = [UIImage imageNamed:@"res/detail_background"];
    int left = ((int)bg.size.width) / 2;
    int top = bg.size.height * 0.6;
    int right = ((int)bg.size.width) - left - 1;
    int bottom = ((int)bg.size.height) - top - 1;
    return [bg resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right)];
}

+ (NSData *)pngDataOfImg:(UIImage *)img {
    if (img) {
        return UIImagePNGRepresentation(img);
    }
    return [NSData data];
}

@end
