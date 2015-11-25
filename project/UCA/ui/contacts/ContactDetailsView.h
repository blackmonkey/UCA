/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface ContactDetailsView : QuickDialogController<QuickDialogEntryElementDelegate, AvatarElementDelegate> {
    BOOL _nativeContactsChangedWhileInactive;
    Contact *_contact;
    NSInteger _modifications;
    UIBarButtonItem *_confirmBtn;
    UIBarButtonItem *_cancelBtn;
    UIBarButtonItem *_deleteBtn;
}

- (id)initWithContact:(Contact *)contact;

@end
