/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "NumPadView.h"

#define VERTICAL_PADDING (6)
#define PADDING_BETWEEN_EDITOR_AND_BACKSPACE (6)
#define EDITOR_INTERNAL_PADDING (8)

@implementation NumPadView {
    UIImageView *_bgPad;

    UIImageView *_bgPhonenumber;
    UILabel *_lbPhonenumber;

    PadButton *_btnPad0;
    PadButton *_btnPad1;
    PadButton *_btnPad2;
    PadButton *_btnPad3;
    PadButton *_btnPad4;
    PadButton *_btnPad5;
    PadButton *_btnPad6;
    PadButton *_btnPad7;
    PadButton *_btnPad8;
    PadButton *_btnPad9;
    PadButton *_btnPadStar;
    PadButton *_btnPadSharp;
    UIView *_numBtnPanel;

    UIButton *_btnBackspace;

    CGFloat _horizontalPadding;
}

@synthesize phoneNumber;
@synthesize height;
@synthesize delegate;

#pragma mark - View lifecycle

- (PadButton *)createButtonWithImageName:(NSString *)imgName andChars:(NSString *)btnChars andFrame:(CGRect)btnFrame andSoundId:(NSUInteger)sid {
    NSString *pressedImgName = [imgName stringByAppendingString:@"_pressed"];
    PadButton *btn = [[PadButton alloc] initWithFrame:btnFrame andSoundId:sid];
    btn.chars = btnChars;
    btn.delegate = self;
    [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:pressedImgName] forState:UIControlStateHighlighted];
    [btn setImage:[UIImage imageNamed:pressedImgName] forState:UIControlStateSelected];
    return btn;
}

- (id)initWithCanBackspace:(BOOL)canBackspace {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self->height = 218;

        _bgPad = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 130, self.height)];
        _bgPad.image = [[UIImage imageNamed:@"res/numpad_background"] resizeFromCenter];
        [self addSubview:_bgPad];

        _bgPhonenumber = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 130, 30)];
        _bgPhonenumber.image = [[UIImage imageNamed:@"res/numpad_textfield_background"] resizeFromCenter];
        [self addSubview:_bgPhonenumber];

        _lbPhonenumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
        _lbPhonenumber.backgroundColor = [UIColor clearColor];
        _lbPhonenumber.font = [UIFont boldSystemFontOfSize:24];
        _lbPhonenumber.textColor = [UIColor blackColor];
        _lbPhonenumber.minimumFontSize = 8;
        _lbPhonenumber.adjustsFontSizeToFitWidth = YES;
        _lbPhonenumber.lineBreakMode = UILineBreakModeMiddleTruncation;
        [self addSubview:_lbPhonenumber];

        if (canBackspace) {
            _btnBackspace = [UIButton buttonWithImageName:@"res/numpad_backspace" andTarget:self andAction:@selector(onBackspace)];
            [self addSubview:_btnBackspace];
        }

        _btnPad1     = [self createButtonWithImageName:@"res/numpad_1"     andChars:@"1.@"   andFrame:CGRectMake(  0,   0, 101, 43) andSoundId:NUM_BUTTON_0_SOUND_ID];
        _btnPad2     = [self createButtonWithImageName:@"res/numpad_2"     andChars:@"2abc"  andFrame:CGRectMake(101,   0, 101, 43) andSoundId:NUM_BUTTON_1_SOUND_ID];
        _btnPad3     = [self createButtonWithImageName:@"res/numpad_3"     andChars:@"3def"  andFrame:CGRectMake(202,   0, 101, 43) andSoundId:NUM_BUTTON_2_SOUND_ID];
        _btnPad4     = [self createButtonWithImageName:@"res/numpad_4"     andChars:@"4ghi"  andFrame:CGRectMake(  0,  43, 101, 43) andSoundId:NUM_BUTTON_3_SOUND_ID];
        _btnPad5     = [self createButtonWithImageName:@"res/numpad_5"     andChars:@"5jkl"  andFrame:CGRectMake(101,  43, 101, 43) andSoundId:NUM_BUTTON_4_SOUND_ID];
        _btnPad6     = [self createButtonWithImageName:@"res/numpad_6"     andChars:@"6mno"  andFrame:CGRectMake(202,  43, 101, 43) andSoundId:NUM_BUTTON_5_SOUND_ID];
        _btnPad7     = [self createButtonWithImageName:@"res/numpad_7"     andChars:@"7pqrs" andFrame:CGRectMake(  0,  86, 101, 43) andSoundId:NUM_BUTTON_6_SOUND_ID];
        _btnPad8     = [self createButtonWithImageName:@"res/numpad_8"     andChars:@"8tuv"  andFrame:CGRectMake(101,  86, 101, 43) andSoundId:NUM_BUTTON_7_SOUND_ID];
        _btnPad9     = [self createButtonWithImageName:@"res/numpad_9"     andChars:@"9wxyz" andFrame:CGRectMake(202,  86, 101, 43) andSoundId:NUM_BUTTON_8_SOUND_ID];
        _btnPadStar  = [self createButtonWithImageName:@"res/numpad_star"  andChars:@"*"     andFrame:CGRectMake(  0, 129, 101, 44) andSoundId:NUM_BUTTON_9_SOUND_ID];
        _btnPad0     = [self createButtonWithImageName:@"res/numpad_0"     andChars:@"0+"    andFrame:CGRectMake(101, 129, 101, 44) andSoundId:NUM_BUTTON_STAR_SOUND_ID];
        _btnPadSharp = [self createButtonWithImageName:@"res/numpad_sharp" andChars:@"#"     andFrame:CGRectMake(202, 129, 101, 44) andSoundId:NUM_BUTTON_SHARP_SOUND_ID];
        _numBtnPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 303, 173)];

        [_numBtnPanel addSubview:_btnPad1];
        [_numBtnPanel addSubview:_btnPad2];
        [_numBtnPanel addSubview:_btnPad3];
        [_numBtnPanel addSubview:_btnPad4];
        [_numBtnPanel addSubview:_btnPad5];
        [_numBtnPanel addSubview:_btnPad6];
        [_numBtnPanel addSubview:_btnPad7];
        [_numBtnPanel addSubview:_btnPad8];
        [_numBtnPanel addSubview:_btnPad9];
        [_numBtnPanel addSubview:_btnPadStar];
        [_numBtnPanel addSubview:_btnPad0];
        [_numBtnPanel addSubview:_btnPadSharp];
        [self addSubview:_numBtnPanel];
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat fullWidth = [ScreenUtils screenWidth];
    _horizontalPadding = (fullWidth - _numBtnPanel.frame.size.width) / 2;

    CGRect rect = _bgPad.frame;
    rect.size.width = fullWidth;
    _bgPad.frame = rect;

    rect = _bgPhonenumber.frame;
    rect.origin = CGPointMake(_horizontalPadding, VERTICAL_PADDING);
    rect.size.width = fullWidth - _horizontalPadding * 2;
    if (_btnBackspace != nil) {
        rect.size.width -= _btnBackspace.frame.size.width + PADDING_BETWEEN_EDITOR_AND_BACKSPACE;
    }
    _bgPhonenumber.frame = rect;

    rect = _lbPhonenumber.frame;
    rect.origin.x = _bgPhonenumber.frame.origin.x + EDITOR_INTERNAL_PADDING;
    rect.origin.y = _bgPhonenumber.frame.origin.y;
    rect.size.width = _bgPhonenumber.frame.size.width - EDITOR_INTERNAL_PADDING * 2;
    _lbPhonenumber.frame = rect;

    if (_btnBackspace != nil) {
        rect = _btnBackspace.frame;
        rect.origin.x = CGRectGetMaxX(_bgPhonenumber.frame) + PADDING_BETWEEN_EDITOR_AND_BACKSPACE;
        rect.origin.y = _bgPhonenumber.frame.origin.y + (_bgPhonenumber.frame.size.height - rect.size.height) / 2;
        _btnBackspace.frame = rect;
    }

    rect = _numBtnPanel.frame;
    rect.origin.x = _horizontalPadding;
    rect.origin.y = CGRectGetMaxY(_bgPhonenumber.frame) + VERTICAL_PADDING;
    _numBtnPanel.frame = rect;
}

- (NSString *)phoneNumber {
    return _lbPhonenumber.text;
}

- (void)setPhoneNumber:(NSString *)number {
    _lbPhonenumber.text = number;
}

#pragma mark - selector methods

- (void)onBackspace {
    NSString *number = _lbPhonenumber.text;
    if ([number length] > 0) {
        number = [number substringToIndex:(number.length - 1)];
    }
    _lbPhonenumber.text = number;

    if ([delegate respondsToSelector:@selector(numPadView:changedNumber:)]) {
        [delegate numPadView:self changedNumber:number];
    }
}

#pragma mark - PadButtonDelegate methods

- (void)padButton:(PadButton *)btn beginInputting:(unichar)curChar {
    NSString *number = _lbPhonenumber.text;
    if ([number length] > 0) {
        number = [number stringByAppendingFormat:@"%C", curChar];
    } else {
        number = [NSString stringWithFormat:@"%C", curChar];
    }
    _lbPhonenumber.text = number;

    if ([delegate respondsToSelector:@selector(numPadView:changedNumber:)]) {
        [delegate numPadView:self changedNumber:number];
    }
}

- (void)padButton:(PadButton *)btn changePreviousChar:(unichar)preChar toChar:(unichar)curChar {
    NSString *number = _lbPhonenumber.text;
    if ([number length] > 0) {
        number = [number substringToIndex:(number.length - 1)];
    }
    number = [number stringByAppendingFormat:@"%C", curChar];
    _lbPhonenumber.text = number;

    if ([delegate respondsToSelector:@selector(numPadView:changedNumber:)]) {
        [delegate numPadView:self changedNumber:number];
    }
}

@end
