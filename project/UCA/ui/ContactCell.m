/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <QuartzCore/QuartzCore.h>
#import "ContactCell.h"

#undef TAG
#define TAG @"ContactCell"

#define TAG_BTN_AVATAR     (101)
#define TAG_BTN_IM         (102)
#define TAG_BTN_CAMERA     (103)
#define TAG_BTN_PHONE      (104)
#define TAG_LABEL_NAME     (105)
#define TAG_LABEL_DEPART   (106)
#define TAG_LABEL_DESCRIPT (107)

/**
 * 各联系人信息控件坐标、尺寸比例。
 * 这些比例直接从视觉原型中测量而得。
 * 其中IM、音视频电话按钮的图标在320*460分辨率下的尺寸为16*16。
 */
#define RATIO_AVATAR_LEFT      (0.1)     // 头像左边到ContactCell左边的距离，相对于ContactCell宽度的比例
#define RATIO_AVATAR_TOP       (0.08696) // 头像上边到ContactCell上边的距离，相对于ContactCell高度的比例
#define RATIO_AVATAR_HEIGHT    (0.79130) // 头像高度相对于ContactCell高度的比例
#define RATIO_INFO_LEFT        (0.34062) // 名称、部门、签名等信息左边到ContactCell左边的距离，相对于ContactCell宽度的比例
#define RATIO_NAME_TOP         (0.12174) // 名称上边到ContactCell上边的距离，相对于ContactCell高度的比例
#define RATIO_NAME_HEIGHT      (0.29565) // 名称高度相对于ContactCell高度的比例
#define RATIO_DEPART_TOP       (0.41739) // 部门上边到ContactCell上边的距离，相对于ContactCell高度的比例
#define RATIO_DEPART_HEIGHT    (0.23478) // 部门高度相对于ContactCell高度的比例
#define RATIO_DESCRIPT_TOP     (0.65217) // 签名上边到ContactCell上边的距离，相对于ContactCell高度的比例
#define RATIO_DESCRIPT_HEIGHT  (0.23478) // 签名高度相对于ContactCell高度的比例
#define RATIO_RIGHT_MARGIN     (0.10469) // ContactCell右边margin，相对于ContactCell宽度的比例
#define RATIO_ICON_BTN_PADDING (0.02813) // IM、音视频电话按钮之间的间隔，相对于ContactCell宽度的比例
#define RATIO_BADGE_FONT_SIZE  (0.625)   // IM、音频电话按钮的badge字体大小，相对于按钮本身大小的比例

@implementation ContactCell

+ (CGFloat)height {
    return [UIImage imageNamed:@"res/contact_cell_background"].size.height;
}

- (void)layoutIconButton:(UIButton *)btn toLeft:(CGFloat)x vAlignWith:(UILabel *)labelView {
    CGRect rect = btn.frame;
    rect.origin.x = x;
    rect.origin.y = labelView.frame.origin.y + (labelView.frame.size.height - rect.size.height) / 2;
    btn.frame = rect;
}

- (void)createSubViews:(id)target {
    self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/contact_cell_background"]];
    self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/contact_cell_pressed_background"]];

    CGFloat cellHeight = self.backgroundView.frame.size.height;

    UIButton *btnAvatar = [UIButton buttonWithType:UIButtonTypeCustom];
    btnAvatar.tag = TAG_BTN_AVATAR;
    btnAvatar.frame = CGRectMake(0, cellHeight * RATIO_AVATAR_TOP,
            cellHeight * RATIO_AVATAR_HEIGHT, cellHeight * RATIO_AVATAR_HEIGHT);
    btnAvatar.layer.borderWidth = 1.0;
    btnAvatar.layer.borderColor = [UIColor whiteColor].CGColor;
    btnAvatar.layer.shadowColor = [UIColor grayColor].CGColor;
    btnAvatar.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    btnAvatar.layer.shadowOpacity = 0.5;
    btnAvatar.layer.shadowRadius = 0.5;
    btnAvatar.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    btnAvatar.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
    btnAvatar.contentEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
    [btnAvatar addTarget:target action:@selector(onAvatarBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:btnAvatar];

    UILabel *displayName = [[UILabel alloc] initWithFrame:CGRectMake(0, cellHeight * RATIO_NAME_TOP,
                            0, cellHeight * RATIO_NAME_HEIGHT)];
    displayName.tag = TAG_LABEL_NAME;
    displayName.backgroundColor = [UIColor clearColor];
    [ScreenUtils setLabelMaxFontSize:displayName];
    [self.contentView addSubview:displayName];

    UILabel *depart = [[UILabel alloc] initWithFrame:CGRectMake(0, cellHeight * RATIO_DEPART_TOP,
                            0, cellHeight * RATIO_DEPART_HEIGHT)];
    depart.tag = TAG_LABEL_DEPART;
    depart.textColor = [UIColor orangeColor];
    depart.backgroundColor = [UIColor clearColor];
    [ScreenUtils setLabelMaxFontSize:depart];
    [self.contentView addSubview:depart];

    UILabel *descript = [[UILabel alloc] initWithFrame:CGRectMake(0, cellHeight * RATIO_DESCRIPT_TOP,
                            0, cellHeight * RATIO_DESCRIPT_HEIGHT)];
    descript.tag = TAG_LABEL_DESCRIPT;
    descript.textColor = [UIColor darkGrayColor];
    descript.backgroundColor = [UIColor clearColor];
    [ScreenUtils setLabelMaxFontSize:descript];
    [self.contentView addSubview:descript];

    UIButton *btnIm = [UIButton buttonWithType:UIButtonTypeCustom];
    btnIm.tag = TAG_BTN_IM;
    btnIm.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    btnIm.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    [btnIm setBackgroundImage:[UIImage imageNamed:@"res/im_button"] forState:UIControlStateNormal];
    [btnIm setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btnIm sizeToFit];
    btnIm.titleLabel.font = [UIFont systemFontOfSize:(btnIm.frame.size.height * RATIO_BADGE_FONT_SIZE)];
    btnIm.titleLabel.adjustsFontSizeToFitWidth = YES;
    btnIm.titleLabel.minimumFontSize = 1;
    [btnIm addTarget:target action:@selector(onImBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self layoutIconButton:btnIm toLeft:0 vAlignWith:displayName];
    [self.contentView addSubview:btnIm];

    UIButton *btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    btnCamera.tag = TAG_BTN_CAMERA;
    [btnCamera setImage:[UIImage imageNamed:@"res/cam_on_button"] forState:UIControlStateNormal];
    [btnCamera setImage:[UIImage imageNamed:@"res/cam_off_button"] forState:UIControlStateDisabled];
    [btnCamera sizeToFit];
    [btnCamera addTarget:target action:@selector(onCameraBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self layoutIconButton:btnCamera toLeft:0 vAlignWith:displayName];
    [self.contentView addSubview:btnCamera];

    UIButton *btnPhone = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPhone.tag = TAG_BTN_PHONE;
    [btnPhone setBackgroundImage:[UIImage imageNamed:@"res/phone_on_button"] forState:UIControlStateNormal];
    [btnPhone setBackgroundImage:[UIImage imageNamed:@"res/phone_off_button"] forState:UIControlStateDisabled];
    [btnPhone sizeToFit];
    CGFloat ftSize = btnPhone.frame.size.height * RATIO_BADGE_FONT_SIZE;
    btnPhone.titleLabel.font = [UIFont boldSystemFontOfSize:ftSize];
    btnPhone.titleLabel.adjustsFontSizeToFitWidth = YES;
    btnPhone.titleLabel.minimumFontSize = 1;
    btnPhone.titleLabel.layer.backgroundColor = [UIColor redColor].CGColor;
    btnPhone.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    btnPhone.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    CGFloat offset = -ftSize / 2;
    btnPhone.contentEdgeInsets = UIEdgeInsetsMake(offset, offset, offset, offset);
    [btnPhone setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnPhone addTarget:target action:@selector(onPhoneBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self layoutIconButton:btnPhone toLeft:0 vAlignWith:displayName];
    [self.contentView addSubview:btnPhone];
}

/**
 * 当UITableView进入编辑模式时，UITableCell会被向右推，其contentView.origin.x记录了
 * 被推动的距离；当UITableView退出编辑模式时，UITableCell.contentView.origin.x恢复
 * 为0。此函数根据这一点，来重排所有联系人信息控件。
 */
- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect rect;
    CGRect contentRect = self.contentView.frame;
    CGFloat wholeWidth = self.frame.size.width;

    UIButton *btnAvatar  = (UIButton *)[self.contentView viewWithTag:TAG_BTN_AVATAR];
    rect = btnAvatar.frame;
    rect.origin.x = wholeWidth * RATIO_AVATAR_LEFT - contentRect.origin.x / 2;
    btnAvatar.frame = rect;
    btnAvatar.backgroundColor = [UIColor colorFromHex:0xFFE5E5E5];

    CGFloat rightLimit = wholeWidth * (1 - RATIO_RIGHT_MARGIN) - contentRect.origin.x;
    CGFloat btnLeft    = rightLimit;
    CGFloat btnPad     = wholeWidth * RATIO_ICON_BTN_PADDING;

    UIButton *btnPhone = (UIButton *)[self.contentView viewWithTag:TAG_BTN_PHONE];
    if (![btnPhone isHidden]) {
        btnPhone.titleLabel.layer.cornerRadius = btnPhone.titleLabel.bounds.size.height / 2;
        rect = btnPhone.frame;
        btnLeft -= rect.size.width;
        rect.origin.x = btnLeft;
        btnPhone.frame = rect;
        btnLeft -= btnPad;
    }

    UIButton *btnCamera = (UIButton *)[self.contentView viewWithTag:TAG_BTN_CAMERA];
    if (![btnCamera isHidden]) {
        rect = btnCamera.frame;
        btnLeft -= rect.size.width;
        rect.origin.x = btnLeft;
        btnCamera.frame = rect;
        btnLeft -= btnPad;
    }

    UIButton *btnIm = (UIButton *)[self.contentView viewWithTag:TAG_BTN_IM];
    if (![btnIm isHidden]) {
        rect = btnIm.frame;
        btnLeft -= rect.size.width;
        rect.origin.x = btnLeft;
        btnIm.frame = rect;
        btnLeft -= btnPad;
    }

    CGFloat infoLeft = wholeWidth * RATIO_INFO_LEFT - contentRect.origin.x;

    UILabel *displayName = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_NAME];
    rect = displayName.frame;
    rect.origin.x = infoLeft;
    rect.size.width = btnLeft - infoLeft;
    displayName.frame = rect;

    UILabel *depart = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_DEPART];
    rect = depart.frame;
    rect.origin.x = infoLeft;
    rect.size.width = rightLimit - infoLeft;
    depart.frame = rect;

    UILabel *descript = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_DESCRIPT];
    rect = descript.frame;
    rect.origin.x = infoLeft;
    rect.size.width = rightLimit - infoLeft;
    descript.frame = rect;
}

- (id)initWithTarget:(id)target {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CONTACT_CELL_REUSE_IDENTIFIER];
    if (self != nil) {
        self.backgroundColor = [UIColor clearColor];
        [self createSubViews:target];
    }
    return self;
}

- (void)bindWithTarget:(id)target andContact:(Contact *)contact isOwnContact:(BOOL)isOwnContact {
    self.accessoryType = UITableViewCellAccessoryNone;

    UIImage *image = nil;

    UIButton *btnAvatar  = (UIButton *)[self.contentView viewWithTag:TAG_BTN_AVATAR];
    if (contact.photo != nil) {
        image = contact.photo;
    } else {
        image = [UIImage imageNamed:@"res/default_avatar_small"];
    }
    // TODO: scale image aspect to button frame
    [btnAvatar setBackgroundImage:image forState:UIControlStateNormal];

    if (contact.contactType == ContactType_AddressBook) {
        [btnAvatar setImage:nil forState:UIControlStateNormal];
    } else {
        image = [UcaConstants iconOfPresentation:contact.presentation];
        [btnAvatar setImage:image forState:UIControlStateNormal];
    }

    [btnAvatar removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [btnAvatar addTarget:target action:@selector(onAvatarBtnClicked) forControlEvents:UIControlEventTouchUpInside];

    UILabel *displayName = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_NAME];
    displayName.text = contact.displayName;

    UILabel *depart = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_DEPART];
    depart.text = contact.departName; // TODO: show department full path name.

    UILabel *descript = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_DESCRIPT];
    descript.text = contact.listDescription;

    BOOL curLoggedIn = [[UcaAppDelegate sharedInstance].accountService isLoggedIn];
    NSString *title = nil;

    NSUInteger missedCount = contact.unreadMessageCount;
    UIButton *btnIm = (UIButton *)[self.contentView viewWithTag:TAG_BTN_IM];
    btnIm.hidden = (isOwnContact || (!curLoggedIn && (missedCount <= 0)));
    if (missedCount > 0) {
        title = [NSString stringWithFormat:@"%d", missedCount];
    }
    [btnIm setTitle:title forState:UIControlStateNormal];
    [btnIm removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [btnIm addTarget:target action:@selector(onImBtnClicked) forControlEvents:UIControlEventTouchUpInside];

    UIButton *btnCamera = (UIButton *)[self.contentView viewWithTag:TAG_BTN_CAMERA];
    btnCamera.hidden = (isOwnContact || !curLoggedIn);
    btnCamera.enabled = (!isOwnContact && contact.presentation != UCALIB_PRESENTATIONSTATE_OFFLINE && contact.cameraOn);
    [btnCamera setImage:image forState:UIControlStateNormal];
    [btnCamera removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [btnCamera addTarget:target action:@selector(onCameraBtnClicked) forControlEvents:UIControlEventTouchUpInside];

    UcaRecentService *service = [UcaAppDelegate sharedInstance].recentService;
    missedCount = [service getMissedCallsOfContact:contact].count;
    UIButton *btnPhone = (UIButton *)[self.contentView viewWithTag:TAG_BTN_PHONE];
    btnPhone.hidden = (isOwnContact || (!curLoggedIn && (missedCount <= 0)));
    btnPhone.enabled = (!isOwnContact && contact.presentation != UCALIB_PRESENTATIONSTATE_OFFLINE);
    title = nil;
    if (missedCount > 0) {
        title = [NSString stringWithFormat:@"%d", missedCount];
    }

    [btnPhone setTitle:title forState:UIControlStateNormal];
    [btnPhone removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [btnPhone addTarget:target action:@selector(onPhoneBtnClicked) forControlEvents:UIControlEventTouchUpInside];
}

@end
