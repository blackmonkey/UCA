/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "ContactElement.h"

/**
 * 联系人列表相关操作
 */
typedef enum {
    ContactListOperation_ListGroupMembers,
    ContactListOperation_AddGroupMemberFromFriends,
    ContactListOperation_AddGroupMemberFromGroup,
    ContactListOperation_AddGroupMemberFromRecents,
    ContactListOperation_AddSessionMemberFromFriends,
    ContactListOperation_AddSessionMemberFromRecents
} ContactListOperation;

@interface ContactOperationListView : QuickDialogController<UIAlertViewDelegate, UIActionSheetDelegate, ContactElementDelegate>

- (id)initWithOperation:(ContactListOperation)operation andGroup:(Group *)group;
- (id)initWithOperation:(ContactListOperation)operation andSession:(Session *)session;
- (id)initAddMemberFromGroup:(Group *)srcGroup toGroup:(Group *)dstGroup;

@end
