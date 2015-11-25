/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "ContactSearchBar.h"

#undef TAG
#define TAG @"ContactSearchBar"

#define RATIO_SEARCH_TEXT_WIDTH  (0.75)     // UISearchBar输入框宽度，相对于UISearchBar背景宽度的比例
#define RATIO_SEARCH_CANCEL_LEFT (0.8125)   // UISearchBar取消按钮左边到UISearchBar背景左边的距离，相对于UISearchBar背景宽度的比例
#define RATIO_BTN_PADDING        (0.015625) // UISearchBar按钮之间的间隔，相对于UISearchBar背景宽度的比例

#define INDEX_OF_EDIT_BUTTON    (0)
#define INDEX_OF_CANCEL_BUTTON  (1)
#define INDEX_OF_CONFIRM_BUTTON (2)

@implementation ContactSearchBar {
    UISegmentedControl *_editButtons;
    id<ContactSearchBarDelegate> _editDelegate;
    NSArray *_editButtonTitles;
}

- (id)initWithEditTitle:(NSString *)editTitle andEditDelegate:(id<ContactSearchBarDelegate>)editDelegate {
    self = [super init];
    if (self) {
        _editDelegate = editDelegate;
        _editButtonTitles = [NSArray arrayWithObjects:editTitle, I18nString(@"取消"), I18nString(@"确定"), nil];

        _editButtons = [[UISegmentedControl alloc] init];
        _editButtons.momentary = YES;
        _editButtons.segmentedControlStyle = UISegmentedControlStyleBar;
        _editButtons.tintColor = self.tintColor;
        _editButtons.hidden = YES;
        [_editButtons addTarget:self action:@selector(handleEditButtons:) forControlEvents:UIControlEventValueChanged|UIControlEventTouchUpInside];
        [self addSubview:_editButtons];

    }

    return self;
}

- (IBAction)handleEditButtons:(id)btn {
    NSInteger segIndex = _editButtons.selectedSegmentIndex;
    NSString *segTitle = [_editButtons titleForSegmentAtIndex:segIndex];

    if ([segTitle isEqualToString:[_editButtonTitles objectAtIndex:INDEX_OF_EDIT_BUTTON]]) {
        [_editDelegate contactSearchBarEnterEditing];
    } else if ([segTitle isEqualToString:[_editButtonTitles objectAtIndex:INDEX_OF_CANCEL_BUTTON]]) {
        [_editDelegate contactSearchBarExitEditing];
    } else if ([segTitle isEqualToString:[_editButtonTitles objectAtIndex:INDEX_OF_CONFIRM_BUTTON]]) {
        [_editDelegate contactSearchBarConfirmEditing];
    }
}

- (void)showEditButton:(BOOL)showEdit andConfirmButton:(BOOL)showConfirm andExitButton:(BOOL)showExit {
    [_editButtons removeAllSegments];
    if (showEdit) {
        [_editButtons insertSegmentWithTitle:[_editButtonTitles objectAtIndex:INDEX_OF_EDIT_BUTTON] atIndex:0 animated:YES];
    }
    if (showConfirm) {
        [_editButtons insertSegmentWithTitle:[_editButtonTitles objectAtIndex:INDEX_OF_CONFIRM_BUTTON] atIndex:0 animated:YES];
    }
    if (showExit) {
        [_editButtons insertSegmentWithTitle:[_editButtonTitles objectAtIndex:INDEX_OF_CANCEL_BUTTON] atIndex:0 animated:YES];
    }
    [_editButtons sizeToFit];
    _editButtons.hidden = ([_editButtons numberOfSegments] <= 0);
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // 仅当编辑按钮显示时，才重新layout。
    if ([_editButtons isHidden]) {
        return;
    }

    UIView *bgView = nil;
    UIView *textField = nil;
    UIView *cancelSearchButton = nil;

    for (UIView *v in self.subviews) {
        if ([v isKindOfClass:[NSClassFromString(@"UISearchBarBackground") class]]) {
            bgView = v;
        } else if ([v isKindOfClass:[NSClassFromString(@"UISearchBarTextField") class]]) {
            textField = v;
        } else if ([v isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
            cancelSearchButton = v;
        }
    }

    CGRect textFieldRect = textField.frame;
    textFieldRect.size.width = bgView.frame.size.width * RATIO_SEARCH_TEXT_WIDTH;

    CGRect cancelSearchBtnRect = cancelSearchButton.frame;
    cancelSearchBtnRect.origin.x = bgView.frame.size.width * RATIO_SEARCH_CANCEL_LEFT;

    CGFloat btnPadding = bgView.frame.size.width * RATIO_BTN_PADDING;
    CGFloat right = cancelSearchBtnRect.origin.x + cancelSearchBtnRect.size.width;
    CGRect rect = _editButtons.frame;
    rect.origin.x = right - _editButtons.frame.size.width;
    rect.origin.y = (self.frame.size.height - _editButtons.frame.size.height) / 2;
    _editButtons.frame = rect;
    right = rect.origin.x - btnPadding;

    cancelSearchBtnRect.origin.x = right - cancelSearchButton.frame.size.width;
    cancelSearchButton.frame = cancelSearchBtnRect;

    textFieldRect.size.width = cancelSearchBtnRect.origin.x - btnPadding - textFieldRect.origin.x;
    textField.frame = textFieldRect;
}

@end
