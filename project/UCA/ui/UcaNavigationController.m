/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaNavigationController.h"

//#undef TAG
//#define TAG @"UcaNavigationController"

#define TAG_NAVBAR_BGIMG_VIEW (6183746)

@implementation UcaNavigationController {
    UIImageView *_bgImgView;
    BOOL _toInsertBgImgView;
}

- (void)loadView {
    [super loadView];

    UIImage *navBarBg = [UIImage imageNamed:@"res/app_title_background"];
    if ([self.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationBar setBackgroundImage:navBarBg forBarMetrics:UIBarMetricsDefault];
    } else {
        _toInsertBgImgView = YES;
        if (!_bgImgView) {
            _bgImgView = [[UIImageView alloc] initWithImage:navBarBg];
            _bgImgView.tag = TAG_NAVBAR_BGIMG_VIEW;
            _bgImgView.contentMode = UIViewContentModeScaleToFill;

            CGRect rect = _bgImgView.frame;
            rect.size.width = self.navigationBar.frame.size.width;
            _bgImgView.frame = rect;
        }
    }

    self.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [UIFont systemFontOfSize:15.0], UITextAttributeFont,
                                              [UIColor colorFromHex:0xFFD4E8E7], UITextAttributeTextColor,
                                              [UIColor colorFromHex:0x80C0C0C0], UITextAttributeTextShadowColor,
                                              UIOffsetMake(0, -0.5), UITextAttributeTextShadowOffset,
                                              nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (_toInsertBgImgView) {
        UIImageView *bgView = (UIImageView *)[self.navigationBar viewWithTag:TAG_NAVBAR_BGIMG_VIEW];
        if (!bgView) {
            [self.navigationBar insertSubview:_bgImgView belowSubview:self.navigationBar.subviews.lastObject];
        }
    }
//
//    UcaLog(TAG, @"view=%@", self.view);
//    UcaLog(TAG, @"navigationBar=%@", self.navigationBar);
//    UcaLog(TAG, @"navigationBar.subviews=%@", self.navigationBar.subviews);
//    UcaLog(TAG, @"navigationBar.titleTextAttributes=%@", self.navigationBar.titleTextAttributes);
//    UcaLog(TAG, @"navigationBar.topItem=%@", self.navigationBar.topItem);
//    UcaLog(TAG, @"navigationBar.topItem.backBarButtonItem=%@", self.navigationBar.topItem.backBarButtonItem);
//    UcaLog(TAG, @"navigationBar.topItem.leftBarButtonItem=%@", self.navigationBar.topItem.leftBarButtonItem);
//    UcaLog(TAG, @"navigationBar.topItem.leftBarButtonItems=%@", self.navigationBar.topItem.leftBarButtonItems);
//    UcaLog(TAG, @"navigationBar.topItem.rightBarButtonItem=%@", self.navigationBar.topItem.rightBarButtonItem);
//    UcaLog(TAG, @"navigationBar.topItem.rightBarButtonItems=%@", self.navigationBar.topItem.rightBarButtonItems);
//    UcaLog(TAG, @"navigationBar.topItem.titleView=%@", self.navigationBar.topItem.titleView);
//    UcaLog(TAG, @"navigationBar.items=%@", self.navigationBar.items);
//    UcaLog(TAG, @"navigationBar.backItem=%@", self.navigationBar.backItem);
//    UcaLog(TAG, @"navigationBar.backItem.backBarButtonItem=%@", self.navigationBar.backItem.backBarButtonItem);
//    UcaLog(TAG, @"navigationBar.backItem.leftBarButtonItem=%@", self.navigationBar.backItem.leftBarButtonItem);
//    UcaLog(TAG, @"navigationBar.backItem.leftBarButtonItems=%@", self.navigationBar.backItem.leftBarButtonItems);
//    UcaLog(TAG, @"navigationBar.backItem.rightBarButtonItem=%@", self.navigationBar.backItem.rightBarButtonItem);
//    UcaLog(TAG, @"navigationBar.backItem.rightBarButtonItems=%@", self.navigationBar.backItem.rightBarButtonItems);
//    UcaLog(TAG, @"navigationItem=%@", self.navigationItem);
//    UcaLog(TAG, @"navigationItem.backBarButtonItem=%@", self.navigationItem.backBarButtonItem);
//    UcaLog(TAG, @"navigationItem.leftBarButtonItem=%@", self.navigationItem.leftBarButtonItem);
//    UcaLog(TAG, @"navigationItem.leftBarButtonItems=%@", self.navigationItem.leftBarButtonItems);
//    UcaLog(TAG, @"navigationItem.rightBarButtonItem=%@", self.navigationItem.rightBarButtonItem);
//    UcaLog(TAG, @"navigationItem.rightBarButtonItems=%@", self.navigationItem.rightBarButtonItems);
//    UcaLog(TAG, @"navigationItem.titleView=%@", self.navigationItem.titleView);
}

@end
