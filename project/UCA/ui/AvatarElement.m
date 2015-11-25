/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <QuartzCore/QuartzCore.h>
#import "AvatarElement.h"

#define AVATAR_VIEW_SIZE (100.f)
#define TAG_BTN_AVATAR   (100)
#define TAG_TXT_DESCRIPT (101)
#define TAG_SEG_PRE_NEXT (102)

@interface AvatarElement ()
- (void)handleActionBarPreviousNext:(UISegmentedControl *)control;
- (BOOL)handleActionBarDone:(UIBarButtonItem *)doneButton;
- (QEntryElement *)findNextElementToFocusOn;
- (QEntryElement *)findPreviousElementToFocusOn;
@end

@implementation AvatarElement {
    UISegmentedControl *_prevNext;
    QuickDialogTableView *_quickformTableView;
    UIButton *_avatarView;
    UITextView *_descripView;
    UITableViewCell *_cell;
    UIImagePickerController *_imagePickerController;
}

@synthesize text = _text;
@synthesize image = _image;
@synthesize editable = _editable;
@synthesize font = _font;
@synthesize color = _color;
@synthesize delegate = _delegate;

- (UIImage *)getAvatarPhoto {
    return _image != nil ? _image : [UIImage imageNamed:@"res/default_avatar"];
}

- (void)handleActionBarPreviousNext:(UISegmentedControl *)control {
    QEntryElement *element;
    const BOOL isNext = control.selectedSegmentIndex == 1;
    if (isNext){
        element = [self findNextElementToFocusOn];
    } else {
        element = [self findPreviousElementToFocusOn];
    }
    if (element != nil){
        UITableViewCell *cell = [_quickformTableView cellForElement:element];
        if (cell!=nil){
            [cell becomeFirstResponder];
        } else {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 50 * USEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                UITableViewCell *c = [_quickformTableView cellForElement:element];
                if (c!=nil){
                    [c becomeFirstResponder];
                }
            });
        }
    }
}

- (BOOL)handleActionBarDone:(UIBarButtonItem *)doneButton {
    [_descripView endEditing:YES];
    [_descripView endEditing:NO];
    [_descripView resignFirstResponder];
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];

    if(_delegate && [_delegate respondsToSelector:@selector(AvatarMustReturnForElement:andCell:)]){
        [_delegate AvatarMustReturnForElement:self andCell:_cell];
    }

    return NO;
}

- (QEntryElement *)findPreviousElementToFocusOn {
    QEntryElement *previousElement = nil;
    for (QSection *section in _parentSection.rootElement.sections) {
        for (QElement * e in section.elements){
            if (e == self) {
                return previousElement;
            } else if ([e isKindOfClass:[QEntryElement class]] && ![e isKindOfClass:[QRadioElement class]]){
                previousElement = (QEntryElement *)e;
            }
        }
    }
    return nil;
}

- (QEntryElement *)findNextElementToFocusOn {
    BOOL foundSelf = NO;
    for (QSection *section in _parentSection.rootElement.sections) {
        for (QElement * e in section.elements){
            if (e == self) {
                foundSelf = YES;
            } else if (foundSelf && [e isKindOfClass:[QEntryElement class]] && ![e isKindOfClass:[QRadioElement class]]){
                return (QEntryElement *) e;
            }
        }
    }
    return nil;
}

- (AvatarElement *)init {
    self = [super init];
    _font = [UIFont systemFontOfSize:14];
    _color = [UIColor blackColor];

    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _imagePickerController.allowsEditing = YES;

    return self;
}

- (AvatarElement *)initWithText:(NSString *)txt andImage:(UIImage *)img editable:(BOOL)edit {
    self = [self init];
    _text = txt;
    _image = img;
    _editable = edit;
    return self;
}

-(UIToolbar *)createActionBar {
    UIToolbar *actionBar = [[UIToolbar alloc] init];
    actionBar.translucent = YES;
    [actionBar sizeToFit];
    actionBar.barStyle = UIBarStyleBlackTranslucent;

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:I18nString(@"完成")
                                                                   style:UIBarButtonItemStyleDone target:self
                                                                  action:@selector(handleActionBarDone:)];

    _prevNext = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:I18nString(@"上处"), I18nString(@"下处"), nil]];
    _prevNext.tag = TAG_SEG_PRE_NEXT;
    _prevNext.momentary = YES;
    _prevNext.segmentedControlStyle = UISegmentedControlStyleBar;
    _prevNext.tintColor = actionBar.tintColor;
    [_prevNext addTarget:self action:@selector(handleActionBarPreviousNext:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *prevNextWrapper = [[UIBarButtonItem alloc] initWithCustomView:_prevNext];
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [actionBar setItems:[NSArray arrayWithObjects:prevNextWrapper, flexible, doneButton, nil]];

    return actionBar;
}

- (void)updatePrevNextStatus {
    [_prevNext setEnabled:([self findPreviousElementToFocusOn] != nil) forSegmentAtIndex:0];
    [_prevNext setEnabled:([self findNextElementToFocusOn] != nil) forSegmentAtIndex:1];
}

- (IBAction)changeAvatar:(id)button {
    [_quickformTableView.controller presentModalViewController:_imagePickerController animated:YES];
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    _quickformTableView = tableView;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"QuickformAvatar"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"QuickformAvatar"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        _avatarView = [UIButton buttonWithType:UIButtonTypeCustom];
        _avatarView.tag = TAG_BTN_AVATAR;
        _avatarView.frame = CGRectMake(10.f, 10.f, AVATAR_VIEW_SIZE, AVATAR_VIEW_SIZE);
        [_avatarView setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [_avatarView setContentVerticalAlignment:UIControlContentVerticalAlignmentBottom];
        [_avatarView addTarget:self action:@selector(changeAvatar:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:_avatarView];

        _descripView = [[UITextView alloc] initWithFrame:CGRectZero];
        _descripView.tag = TAG_TXT_DESCRIPT;
        _descripView.backgroundColor = cell.backgroundColor;
        _descripView.delegate = self;
        _descripView.inputAccessoryView = [self createActionBar];

        // 绘制边框
        _descripView.layer.borderColor = [[UIColor colorFromHex:0x80AAAAAA] CGColor];
        _descripView.layer.cornerRadius = 5.f;
        _descripView.clipsToBounds = YES;
        [cell.contentView addSubview:_descripView];
    } else {
        _avatarView = (UIButton *)[cell.contentView viewWithTag:TAG_BTN_AVATAR];
        _descripView = (UITextView *)[cell.contentView viewWithTag:TAG_TXT_DESCRIPT];
        _prevNext = (UISegmentedControl *)[_descripView.inputAccessoryView viewWithTag:TAG_SEG_PRE_NEXT];
    }

    _avatarView.userInteractionEnabled = _editable;
    _avatarView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _avatarView.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
    [_avatarView setTitleShadowColor:[UIColor colorFromHex:0x80AAAAAA]
                            forState:UIControlStateNormal];
    [_avatarView setImage:(_editable ? [UIImage imageNamed:@"res/edit_avatar"] : nil) forState:UIControlStateNormal];
    [_avatarView setBackgroundImage:[self getAvatarPhoto] forState:UIControlStateNormal];

    _descripView.text = _text;
    _descripView.font = _font;
    _descripView.textColor = _color;
    _descripView.editable = _editable;
    _descripView.layer.borderWidth = _editable ? 1.f : 0.f;
    _descripView.frame = CGRectMake(_avatarView.frame.origin.x + AVATAR_VIEW_SIZE + 5.f,
                                   _avatarView.frame.origin.y,
                                   tableView.frame.size.width - AVATAR_VIEW_SIZE - (tableView.root.grouped ? 45.f : 25.f),
                                   AVATAR_VIEW_SIZE);
    [self updatePrevNextStatus];
    _cell = cell;
    return cell;
}

- (CGFloat)getRowHeightForTableView:(QuickDialogTableView *)tableView {
    CGFloat predictedHeight = AVATAR_VIEW_SIZE + 20.f;

    return (_height >= predictedHeight) ? _height : predictedHeight;
}

- (void)fetchValueIntoObject:(id)obj {
    if (_key == nil)
        return;

    [obj setValue:_text forKey:_key];
}

#pragma mark UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 50 * USEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [_quickformTableView scrollToRowAtIndexPath:[_quickformTableView indexForElement:self] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    });

    if (_descripView.returnKeyType == UIReturnKeyDefault) {
        UIReturnKeyType returnType = ([self findNextElementToFocusOn]!=nil) ? UIReturnKeyNext : UIReturnKeyDone;
        _descripView.returnKeyType = returnType;
    }

    if (_delegate && [_delegate respondsToSelector:@selector(AvatarDidBeginEditingElement:andCell:)]) {
        [_delegate AvatarDidBeginEditingElement:self andCell:_cell];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    _text = _descripView.text;

    if (_delegate && [_delegate respondsToSelector:@selector(AvatarDidEndEditingElement:andCell:)]) {
        [_delegate AvatarDidEndEditingElement:self andCell:_cell];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(_delegate && [_delegate respondsToSelector:@selector(AvatarShouldChangeCharactersInRangeForElement:andCell:)]){
        return [_delegate AvatarShouldChangeCharactersInRangeForElement:self andCell:_cell];
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    _text = _descripView.text;

    if (_delegate && [_delegate respondsToSelector:@selector(AvatarEditingChangedForElement:andCell:)]){
        [_delegate AvatarEditingChangedForElement:self andCell:_cell];
    }
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    _image = [info valueForKey:UIImagePickerControllerEditedImage];
    [_avatarView setBackgroundImage:_image forState:UIControlStateNormal];
    [_quickformTableView.controller dismissModalViewControllerAnimated:YES];

    [self textViewDidEndEditing:_descripView];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [_quickformTableView.controller dismissModalViewControllerAnimated:YES];
}

@end
