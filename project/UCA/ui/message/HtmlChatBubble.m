/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "HtmlChatBubble.h"

@implementation HtmlChatBubble {
    UIImage *_bgImg;
    UIImageView *_bgImgView;
//    UIButton *_maskBtn;
    NSString *_truncHtml;
}

@synthesize html;
@synthesize sentBubble;
@synthesize imgSrcPrefix;

//- (void)onTapped {
//    if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(htmlChatBubbleOnTapped:)]) {
//        [self.touchDelegate htmlChatBubbleOnTapped:self];
//    }
//}
//
//- (void)onLongPressed:(UILongPressGestureRecognizer *)recognizer {
//    if (recognizer.state != UIGestureRecognizerStateEnded) {
//        return;
//    }
//
//    if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(htmlChatBubbleOnLongPressed:)]) {
//        [self.touchDelegate htmlChatBubbleOnLongPressed:self];
//    }
//}

- (id)init {
    self = [super init];
    if (self) {
        _bgImg = [UIImage imageNamed:@"res/chat_send_background"];
        _bgImgView = [[UIImageView alloc] initWithImage:_bgImg];
        [self insertSubview:_bgImgView atIndex:0];

//        _maskBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        _maskBtn.backgroundColor = [UIColor clearColor];
//        _maskBtn.opaque = NO;
//        _maskBtn.showsTouchWhenHighlighted = YES;
//        [_maskBtn addTarget:self action:@selector(onTapped) forControlEvents:UIControlEventTouchUpInside];
//
//        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)];
//        longPress.minimumPressDuration = 0.8;
//        [_maskBtn addGestureRecognizer:longPress];
//        [self addSubview:_maskBtn];

        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.sentBubble = YES;
        self.scrollView.scrollEnabled = NO;
        self.scrollView.bounces = NO;
    }
    return self;
}

- (void)setHtml:(NSString *)_html {
    if (![_html isEqualToString:self->html]) {
        self->html = _html;
        _truncHtml = [[[_html replaceImgSrc:imgSrcPrefix]
                       replaceEmoteCodeToIcon]
                      truncatedHtmlOfOutIm:self.sentBubble];
    }

    NSLog(@"HtmlChatBubble setHtml() loadHtml:%@", _truncHtml);
    [self loadHTMLString:_truncHtml
                 baseURL:[UcaAppDelegate sharedInstance].configService.imBaseUrl];
}

- (void)setSentBubble:(BOOL)sent {
    if (sent == self->sentBubble) {
        return;
    }

    self->sentBubble = sent;
    if (sent) {
        _bgImg = [UIImage imageNamed:@"res/chat_send_background"];
    } else {
        _bgImg = [UIImage imageNamed:@"res/chat_receive_background"];
    }
    _bgImgView.image = [_bgImg resizeFromCenter];
//    _bgImgView.image = [_bgImg stretchableImageWithLeftCapWidth:(_bgImg.size.width / 2)
//                                                   topCapHeight:(_bgImg.size.height / 2)];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _bgImgView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    _bgImgView.image = [_bgImg resizeFromCenter];
//    _bgImgView.image = [_bgImg stretchableImageWithLeftCapWidth:(_bgImg.size.width / 2)
//                                                   topCapHeight:(_bgImg.size.height / 2)];

//    _maskBtn.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

@end
