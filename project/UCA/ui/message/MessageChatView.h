/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "MessageElement.h"

@interface MessageChatView : QuickDialogController<UIActionSheetDelegate, MessageElementDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (id)initWithContact:(Contact *)contact;
- (id)initWithGroup:(Group *)group showHistory:(BOOL)show;
- (id)initWithSession:(Session *)session;

@end
