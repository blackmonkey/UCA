/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaDetailButton.h"

#define ITEM_PADDING 5

@implementation UcaDetailButton

- (UcaDetailButton *)initWithTitle:(NSString *)title
                         imageName:(NSString *)imgName
                         frameSize:(CGSize)size {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        CGRect rect = self.frame;
        rect.size = size;
        self.frame = rect;

        UIImage *bg = [[UIImage imageNamed:@"res/detail_cell_background"] resizeFromCenter];
        [self setBackgroundImage:bg forState:UIControlStateNormal];

        if (![NSString isNullOrEmpty:imgName]) {
            [self setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
        }

        [self setTitle:title forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorFromHex:0xFF96AC88] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:16];
        self.titleLabel.textAlignment = UITextAlignmentCenter;
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect rect;
    CGSize wholeSize = self.frame.size;

    if ([self imageForState:UIControlStateNormal]) {
        rect = self.imageView.frame;
        rect.origin.x = ITEM_PADDING;
        rect.origin.y = (wholeSize.height - rect.size.height) / 2;
        self.imageView.frame = rect;

        rect = self.titleLabel.frame;
        rect.origin.x = CGRectGetMaxX(self.imageView.frame) + ITEM_PADDING;
        rect.origin.y = (wholeSize.height - rect.size.height) / 2;
        rect.size.width = wholeSize.width - self.imageView.frame.size.width - ITEM_PADDING * 3;
        self.titleLabel.frame = rect;
    } else {
        rect = self.titleLabel.frame;
        rect.origin.x = ITEM_PADDING;
        rect.origin.y = (wholeSize.height - rect.size.height) / 2;
        rect.size.width = wholeSize.width - ITEM_PADDING * 2;
        self.titleLabel.frame = rect;
    }
}

@end
