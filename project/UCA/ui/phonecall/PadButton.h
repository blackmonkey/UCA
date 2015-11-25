/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#define NUM_BUTTON_0_SOUND_ID     1200
#define NUM_BUTTON_1_SOUND_ID     1201
#define NUM_BUTTON_2_SOUND_ID     1202
#define NUM_BUTTON_3_SOUND_ID     1203
#define NUM_BUTTON_4_SOUND_ID     1204
#define NUM_BUTTON_5_SOUND_ID     1205
#define NUM_BUTTON_6_SOUND_ID     1206
#define NUM_BUTTON_7_SOUND_ID     1207
#define NUM_BUTTON_8_SOUND_ID     1208
#define NUM_BUTTON_9_SOUND_ID     1209
#define NUM_BUTTON_STAR_SOUND_ID  1210
#define NUM_BUTTON_SHARP_SOUND_ID 1211

@class PadButton;

@protocol PadButtonDelegate <NSObject>

@optional
- (void)padButton:(PadButton *)btn beginInputting:(unichar)curChar;
- (void)padButton:(PadButton *)btn endInputting:(unichar)preChar;
- (void)padButton:(PadButton *)btn changePreviousChar:(unichar)preChar toChar:(unichar)curChar;

@end

@interface PadButton : UIButton

@property (nonatomic, retain) NSString *chars;
@property (nonatomic, retain) id<PadButtonDelegate> delegate;

- (id)initWithFrame:(CGRect)frame andSoundId:(NSUInteger)sid;

@end
