/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <Foundation/Foundation.h>

@protocol ContactSearchBarDelegate <NSObject>

@required
- (void)contactSearchBarEnterEditing;
- (void)contactSearchBarConfirmEditing;
- (void)contactSearchBarExitEditing;

@end

@interface ContactSearchBar : UISearchBar

- (id)initWithEditTitle:(NSString *)editTitle andEditDelegate:(id<ContactSearchBarDelegate>)editDelegate;

- (void)showEditButton:(BOOL)showEdit andConfirmButton:(BOOL)showConfirm andExitButton:(BOOL)showExit;

@end
