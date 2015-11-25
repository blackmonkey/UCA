/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaWindow.h"

@implementation UcaWindow {
    UIImageView *_bgImgView;
}

- (id)init {
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self) {
        _bgImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/app_background"]];
        [self addSubview:_bgImgView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect rect = _bgImgView.frame;
    rect.origin.y = self.frame.size.height - rect.size.height;
    _bgImgView.frame = rect;
}

@end
