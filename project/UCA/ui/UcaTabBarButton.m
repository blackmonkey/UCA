/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaTabBarButton.h"

@implementation UcaTabBarButton {
    UIImageView *_badge;
    CGFloat _badgeMargin;
    UIControlContentHorizontalAlignment _badgeHAlign;
    UIControlContentVerticalAlignment _badgeVAlign;
    BOOL _badgeBlink;
}

- (UcaTabBarButton *)initWithTitle:(NSString *)title imageName:(NSString *)imgName tag:(NSInteger)tag {
    self = [super initWithTitle:title imageName:imgName bgImageName:@"res/tabbar_item_pressed_background"];
    if (self) {
        self.tag = tag;
        [self setTitleShadowColor:[UIColor colorFromHex:0x80666666] forState:UIControlStateNormal];
        self.titleLabel.shadowOffset = CGSizeMake(0.5, 0.5);
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!_badge) {
        return;
    }

    CGRect rect = _badge.frame;

    switch (_badgeHAlign) {
    case UIControlContentHorizontalAlignmentFill:
        rect.size.width = self.imageView.frame.size.width;
    case UIControlContentHorizontalAlignmentLeft:
        rect.origin.x = self.imageView.frame.origin.x;
        break;

    case UIControlContentHorizontalAlignmentCenter:
        rect.origin.x = self.imageView.frame.origin.x + (self.imageView.frame.size.width - rect.size.width) / 2;
        break;

    case UIControlContentHorizontalAlignmentRight:
        rect.origin.x = self.imageView.frame.origin.x + self.imageView.frame.size.width - rect.size.width;
        break;

    default:
        break;
    }

    switch (_badgeVAlign) {
    case UIControlContentVerticalAlignmentFill:
        rect.size.height = self.imageView.frame.size.height;
    case UIControlContentVerticalAlignmentTop:
        rect.origin.y = self.imageView.frame.origin.y;
        break;

    case UIControlContentVerticalAlignmentCenter:
        rect.origin.y = self.imageView.frame.origin.y + (self.imageView.frame.size.height - rect.size.height) / 2;
        break;

    case UIControlContentVerticalAlignmentBottom:
        rect.origin.y = self.imageView.frame.origin.y + self.imageView.frame.size.height - rect.size.height;
        break;

    default:
        break;
    }

    _badge.frame = rect;
}

- (void)showBadge {
    _badge.hidden = NO;

    if (!_badgeBlink) {
        return;
    }

    _badge.alpha = 1.0;
    [UIView animateWithDuration:0.8
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{
                         _badge.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                     }];
}

- (void)hideBadge {
    _badge.hidden = YES;
}

- (void)resizeBadgeWithImage:(UIImage *)img {
    _badge.image = img;

    CGRect rect = _badge.frame;
    rect.size.width = img.size.width + _badgeMargin * 2;
    rect.size.height = img.size.height + _badgeMargin * 2;
    _badge.frame = rect;

    [self setNeedsLayout];
}

- (void)setBadge:(UIImage *)img {
    if (!_badge) {
        [self setBadge:img margin:0 hAlign:UIControlContentHorizontalAlignmentRight vAlign:UIControlContentVerticalAlignmentTop blink:NO];
    } else {
        [self resizeBadgeWithImage:img];
    }
}

- (void)setBadge:(UIImage *)img
          margin:(CGFloat)margin
          hAlign:(UIControlContentHorizontalAlignment)hAlign
          vAlign:(UIControlContentVerticalAlignment)vAlign
           blink:(BOOL)blink {
    _badgeMargin = margin;
    _badgeHAlign = hAlign;
    _badgeVAlign = vAlign;
    _badgeBlink  = blink;

    if (!_badge) {
        _badge = [[UIImageView alloc] init];
        _badge.contentMode = UIViewContentModeCenter;
        [self addSubview:_badge];
    }
    [self resizeBadgeWithImage:img];
}

@end
