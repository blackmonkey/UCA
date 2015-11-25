/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaToolButton.h"

#define TOP_PADDING        3
#define BOTTOM_PADDING     1
#define HORIZON_PADDING    2
#define ICON_TITLE_PADDING 2

@implementation UcaToolButton

- (UcaToolButton *)initWithTitle:(NSString *)title
                       imageName:(NSString *)imgName
                     bgImageName:(NSString *)bgImgName {
    return [self initWithTitle:title imageName:imgName bgImageName:bgImgName frameSize:CGSizeZero fontSize:10];
}

- (UcaToolButton *)initWithTitle:(NSString *)title
                       imageName:(NSString *)imgName
                pressedImageName:(NSString *)pressedImgName
                        fontSize:(CGFloat)fontSize {
    self = [self initWithTitle:title imageName:imgName bgImageName:nil frameSize:CGSizeZero fontSize:fontSize];
    if (self) {
        UIImage *btnIcon = [UIImage imageNamed:pressedImgName];
        [self setImage:btnIcon forState:UIControlStateSelected];
        [self setImage:btnIcon forState:UIControlStateHighlighted];
    }
    return self;
}

- (UcaToolButton *)initWithTitle:(NSString *)title
                       imageName:(NSString *)imgName
                     bgImageName:(NSString *)bgImgName
                       frameSize:(CGSize)frameSize
                        fontSize:(CGFloat)fontSize {
    self = [super init];

    if (self) {
        self.backgroundColor = [UIColor clearColor];

        UIImage *bgImg = nil;
        if (![NSString isNullOrEmpty:bgImgName]) {
            bgImg = [UIImage imageNamed:bgImgName];
            [self setBackgroundImage:[bgImg resizeFromCenter] forState:UIControlStateSelected];
            [self setBackgroundImage:[bgImg resizeFromCenter] forState:UIControlStateHighlighted];
        }

        UIImage *btnIcon = [UIImage imageNamed:imgName];
        [self setImage:btnIcon forState:UIControlStateNormal];

        [self setTitle:title forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.minimumFontSize = 1;
        self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.textAlignment = UITextAlignmentCenter;

        CGSize iconSize = btnIcon.size;
        CGSize minSize = (bgImg != nil ? bgImg.size : CGSizeZero);

        CGFloat w = iconSize.width + HORIZON_PADDING * 2;
        if (minSize.width < w) {
            minSize.width = w;
        }

        CGFloat h = TOP_PADDING + iconSize.height + ICON_TITLE_PADDING + iconSize.width / 4 + BOTTOM_PADDING;
        if (minSize.height < h) {
            minSize.height = h;
        }

        if (CGSizeEqualToSize(frameSize, CGSizeZero)) {
            frameSize = minSize;
        } else if (frameSize.width < minSize.width) {
            frameSize.width = minSize.width;
        } else if (frameSize.height < minSize.height) {
            frameSize.height = minSize.height;
        }

        CGRect rect = self.frame;
        rect.size = frameSize;
        self.frame = rect;
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat margin = (self.frame.size.height - self.imageView.frame.size.height - self.titleLabel.frame.size.height) / 3;

    CGRect rect = self.imageView.frame;
    rect.origin.x = (self.frame.size.width - rect.size.width) / 2;
    rect.origin.y = MAX(TOP_PADDING, margin);
    self.imageView.frame = rect;

    rect = self.titleLabel.frame;
    rect.origin.x = HORIZON_PADDING;
    rect.origin.y = self.frame.size.height - rect.size.height - MAX(BOTTOM_PADDING, margin);
    rect.size.width = self.frame.size.width - HORIZON_PADDING * 2;
    self.titleLabel.frame = rect;
}

@end
