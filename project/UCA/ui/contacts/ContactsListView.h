/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "ContactElement.h"
#import "GroupElement.h"

#define KEY_VOICE_MAIL_ENTRY @"KEY_VOICE_MAIL_ENTRY"
#define KEY_SYS_MSG_ENTRY    @"KEY_SYS_MSG_ENTRY"
#define KEY_GROUP_ENTRY      @"KEY_GROUP_ENTRY"
#define KEY_SESSION_ENTRY    @"KEY_SESSION_ENTRY"

typedef enum {
    FilterMode_Favourite,
    FilterMode_Group,
    FilterMode_Recent
} FilterMode;

@interface ContactsListView : QuickDialogController<UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate, ContactElementDelegate, GroupElementDelegate>

@property (nonatomic, assign) FilterMode filterMode; // 联系人列表类型

@end
