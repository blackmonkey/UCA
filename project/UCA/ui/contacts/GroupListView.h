/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * GroupListView仅用于在“从群组中添加群成员”的过程中，显示备选群组列表。
 */

@interface GroupListView : QuickDialogController

- (id)initWithGroups:(NSArray *)groups exceptGroup:(Group *)group;

@end
