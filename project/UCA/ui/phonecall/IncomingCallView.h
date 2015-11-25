/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface IncomingCallView : UIViewController<UIActionSheetDelegate>

- (id)initWithNumber:(NSString *)number andContact:(Contact *)contact hasVideo:(BOOL)hasVideo;

@end
