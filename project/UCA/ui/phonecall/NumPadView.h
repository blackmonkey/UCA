/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "PadButton.h"

@class NumPadView;

@protocol NumPadViewDelegate <NSObject>

@optional
- (void)numPadView:(NumPadView *)padView changedNumber:(NSString *)number;

@end

@interface NumPadView : UIView<PadButtonDelegate>

@property (nonatomic, retain) NSString *phoneNumber;
@property (nonatomic, readonly, assign) NSUInteger height;
@property (nonatomic, retain) id<NumPadViewDelegate> delegate;

- (id)initWithCanBackspace:(BOOL)canBackspace;

@end
