/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaToolButton : UIButton

- (UcaToolButton *)initWithTitle:(NSString *)title
                       imageName:(NSString *)imgName
                     bgImageName:(NSString *)bgImgName;

- (UcaToolButton *)initWithTitle:(NSString *)title
                       imageName:(NSString *)imgName
                pressedImageName:(NSString *)pressedImgName
                        fontSize:(CGFloat)fontSize;

- (UcaToolButton *)initWithTitle:(NSString *)title
                       imageName:(NSString *)imgName
                     bgImageName:(NSString *)bgImgName
                       frameSize:(CGSize)frameSize
                        fontSize:(CGFloat)fontSize;

@end
