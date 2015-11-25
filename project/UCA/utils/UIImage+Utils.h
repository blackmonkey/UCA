﻿/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UIImage(Utils)

- (UIImage *)resizeFromCenter;
+ (UIImage *)detailBackground;
+ (NSData *)pngDataOfImg:(UIImage *)img;

@end