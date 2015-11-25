/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "AudioToolbox/AudioToolbox.h"
#import "PadButton.h"

@implementation PadButton {
    unichar _curChar;
    NSUInteger _soundId;
}

@synthesize chars;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame andSoundId:(NSUInteger)sid {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor yellowColor];
        _curChar = 0;
        _soundId = sid;
    }
    return self;
}

- (void)setChars:(NSString *)chrs {
    self->chars = chrs;
    self.multipleTouchEnabled = ([chrs length] > 1);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    AudioServicesPlaySystemSound(_soundId);

    UITouch *touch = [touches anyObject];
    unichar preChar = _curChar;
    NSInteger idx = (touch.tapCount - 1) % [self.chars length];
    _curChar = [self.chars characterAtIndex:idx];

    if (touch.tapCount == 1 || [self.chars length] == 1) {
        if (preChar > 0 && [delegate respondsToSelector:@selector(padButton:endInputting:)]) {
            [delegate padButton:self endInputting:preChar];
        }
        if ([delegate respondsToSelector:@selector(padButton:beginInputting:)]) {
            [delegate padButton:self beginInputting:_curChar];
        }
    } else {
        if ([delegate respondsToSelector:@selector(padButton:changePreviousChar:toChar:)]) {
            [delegate padButton:self changePreviousChar:preChar toChar:_curChar];
        }
    }
}

@end
