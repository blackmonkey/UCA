/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "NumPadView.h"
#import "ContactElement.h"

@interface DialerView : QuickDialogController<NumPadViewDelegate, ContactElementDelegate>

- (id)initToTransferCallWithVideo:(BOOL)hasVideo;

@end
