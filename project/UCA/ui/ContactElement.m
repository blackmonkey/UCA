/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "ContactElement.h"
#import "ContactCell.h"

@implementation ContactElement {
    id<ContactElementDelegate> _delegate;
    BOOL _contactIsAccount;
}

@synthesize contact;

- (void)onAvatarBtnClicked {
    if ([_delegate respondsToSelector:@selector(contactElementAvatarOnClicked:)]) {
        [_delegate contactElementAvatarOnClicked:contact];
    }
}

- (void)onImBtnClicked {
    if ([_delegate respondsToSelector:@selector(contactElementImOnClicked:)]) {
        [_delegate contactElementImOnClicked:contact];
    }
}

- (void)onCameraBtnClicked {
    if ([_delegate respondsToSelector:@selector(contactElementCamOnClicked:)]) {
        [_delegate contactElementCamOnClicked:contact];
    }
}

- (void)onPhoneBtnClicked {
    if ([_delegate respondsToSelector:@selector(contactElementPhoneOnClicked:)]) {
        [_delegate contactElementPhoneOnClicked:self];
    }
}

- (void)setContact:(Contact *)_contact {
    self->contact = _contact;
    Account *curAccount = [UcaAppDelegate sharedInstance].accountService.currentAccount;
    _contactIsAccount = [_contact.sipPhone isEqualToString:curAccount.sipPhone];
    self.title = [_contact displayName];
}

- (id)initWithContact:(Contact *)_contact andDelegate:(id<ContactElementDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        self.contact = _contact;
        self.height = [ContactCell height];
    }

    return self;
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    ContactCell *cell = [tableView dequeueReusableCellWithIdentifier:CONTACT_CELL_REUSE_IDENTIFIER];
    if (cell == nil) {
        cell = [[ContactCell alloc] initWithTarget:self];
    }
    UcaLog(@"ContactElement", @"getCellForTableView return %@", cell);
    [cell bindWithTarget:self andContact:contact isOwnContact:_contactIsAccount];
    return cell;
}

- (void)handleElementSelected:(QuickDialogController *)controller {
    if (!_contactIsAccount && [_delegate respondsToSelector:@selector(contactElementOnClicked:)]) {
        [_delegate contactElementOnClicked:self];
    }
}

@end
