/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@class AvatarElement;

@protocol AvatarElementDelegate <NSObject>

@optional
- (BOOL)AvatarShouldChangeCharactersInRangeForElement:(AvatarElement *)element andCell:(UITableViewCell *)cell;
- (void)AvatarEditingChangedForElement:(AvatarElement *)element  andCell:(UITableViewCell *)cell;
- (void)AvatarDidBeginEditingElement:(AvatarElement *)element  andCell:(UITableViewCell *)cell;
- (void)AvatarDidEndEditingElement:(AvatarElement *)element andCell:(UITableViewCell *)cell;
- (void)AvatarMustReturnForElement:(AvatarElement *)element andCell:(UITableViewCell *)cell;

@end

@interface AvatarElement : QRootElement<UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
@protected
    NSString *_text;
    UIImage *_image;
    BOOL _editable;
    UIFont *_font;
    UIColor *_color;
}

@property(nonatomic, strong) NSString *text;
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, assign) BOOL editable;
@property(nonatomic, strong) UIFont *font;
@property(nonatomic, retain) UIColor *color;
@property(nonatomic, assign/*unsafe_unretained*/) id<AvatarElementDelegate> delegate;

- (AvatarElement *)initWithText:(NSString *)text andImage:(UIImage *)image editable:(BOOL)editable;

@end
