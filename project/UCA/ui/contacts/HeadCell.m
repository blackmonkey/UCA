/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <QuartzCore/QuartzCore.h>
#import "HeadCell.h"

#pragma mark - Custom UILabel for count info

@interface CountInfoLabel : UILabel
@end

@implementation CountInfoLabel

- (void)drawTextInRect:(CGRect)rect {
    NSArray *counts = [self.text componentsSeparatedByString:@"/"];

    CGSize wholeSize = [self.text sizeWithFont:self.font];
    wholeSize.height = self.font.pointSize;

    CGSize unreadCountSize = [[counts objectAtIndex:0] sizeWithFont:self.font];
    CGSize totalCountSize = [[counts objectAtIndex:1] sizeWithFont:self.font];
    CGFloat slashWidth = wholeSize.width - unreadCountSize.width - totalCountSize.width;
    CGFloat slashLeft = (self.frame.size.width - slashWidth) / 2;
    CGFloat y = (self.frame.size.height - wholeSize.height) / 2;
    CGPoint totalCountPos = CGPointMake(slashLeft, y);
    CGPoint unreadCountPos = CGPointMake(slashLeft - unreadCountSize.width, y);

    UcaLog(@"CountLabel", @"font pointSize %f", self.font.pointSize);
    UcaLog(@"CountLabel", @"font ascender %f", self.font.ascender);
    UcaLog(@"CountLabel", @"font descender %f", self.font.descender);
    UcaLog(@"CountLabel", @"font capHeight %f", self.font.capHeight);
    UcaLog(@"CountLabel", @"font xHeight %f", self.font.xHeight);
    UcaLog(@"CountLabel", @"font lineHeight %f", self.font.lineHeight);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    CGContextSetShadowWithColor(context, self.shadowOffset, 0.5, [self.shadowColor CGColor]);
    CGContextSelectFont(context,
                      [self.font.fontName UTF8String],
                       wholeSize.height,
                       kCGEncodingMacRoman);
    CGContextSetTextDrawingMode(context, kCGTextFill);
//    CGContextSetCharacterSpacing(context, 10);

//    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);
//    CGContextSetTextMatrix(context, transform);

    NSString *txt = [counts objectAtIndex:0];
    CGContextSetFillColorWithColor(context, [[UIColor orangeColor] CGColor]);
    CGContextShowTextAtPoint(context, unreadCountPos.x, unreadCountPos.y, [txt UTF8String], [txt length]);

    txt = [@"/" stringByAppendingString:[counts objectAtIndex:1]];
    CGContextSetFillColorWithColor(context, [self.textColor CGColor]);
    CGContextShowTextAtPoint(context, totalCountPos.x, totalCountPos.y, [txt UTF8String], [txt length]);

    CGContextRestoreGState(context);
}

@end

#pragma mark - HeadCell implementation

#define TAG_BTN_AVATAR  (101)
#define TAG_BTN_BADGE   (102)
#define TAG_LABEL_COUNT (103)

/**
 * 各置顶信息控件坐标、尺寸比例。
 * 这些比例直接从视觉原型中测量而得。
 */
#define RATIO_AVATAR_LEFT  (0.1)       // 头像左边到HeadCell左边的距离，相对于HeadCell宽度的比例
#define RATIO_INFO_LEFT    (0.1203125) // 头像不显示时，名称、描述等信息左边到HeadCell左边的距离，相对于HeadCell宽度的比例
#define RATIO_INFO_LEFT2   (0.3453125) // 头像显示时，名称、描述等信息左边到HeadCell左边的距离，相对于HeadCell宽度的比例
#define RATIO_RIGHT_MARGIN (0.2109375) // HeadCell右边margin，相对于HeadCell宽度的比例

#define ITEM_PADDING (5)

@implementation HeadCell

+ (CGFloat)height {
    /**
     * 各类型的置顶控件的高度都是一样的。
     */
    return [UIImage imageNamed:@"res/head_cell_groups_background"].size.height;
}

- (void)createSubViews {
    self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_groups_background"]];
    self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_groups_pressed_background"]];

    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.font = [UIFont systemFontOfSize:15];

    self.detailTextLabel.backgroundColor = [UIColor clearColor];
    self.detailTextLabel.font = [UIFont systemFontOfSize:11];

    UIButton *btnAvatar = [UIButton buttonWithType:UIButtonTypeCustom];
    btnAvatar.tag = TAG_BTN_AVATAR;
    btnAvatar.hidden = YES;
    UIImage *avatar = [UIImage imageNamed:@"res/groups_avatar"];
    [btnAvatar setImage:avatar forState:UIControlStateNormal];
    [btnAvatar sizeToFit];
    [self.contentView addSubview:btnAvatar];

    UILabel *countInfo = [[UILabel alloc] init];
    countInfo.tag = TAG_LABEL_COUNT;
    countInfo.backgroundColor = [UIColor clearColor];
    countInfo.textColor = [UIColor colorFromHex:0xFF6A6A6A];
    countInfo.shadowColor = [UIColor colorFromHex:0x80C0C0C0];
    countInfo.shadowOffset = CGSizeMake(-0.5, -0.5);
    countInfo.font = [UIFont systemFontOfSize:9];
    [self.contentView addSubview:countInfo];

    UIButton *btnBadge = [UIButton buttonWithType:UIButtonTypeCustom];
    btnBadge.tag = TAG_BTN_BADGE;
    btnBadge.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter; // TODO: adjust title layout, font
    btnBadge.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    btnBadge.userInteractionEnabled = NO;
    [btnBadge setBackgroundImage:[UIImage imageNamed:@"res/im_button"] forState:UIControlStateNormal]; // TODO: create bigger bg image
    [btnBadge setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btnBadge sizeToFit];
    btnBadge.titleLabel.font = [UIFont systemFontOfSize:10];
    btnBadge.titleLabel.adjustsFontSizeToFitWidth = YES;
    btnBadge.titleLabel.minimumFontSize = 1;
    [self.contentView addSubview:btnBadge];
}

/**
 * 当UITableView进入编辑模式时，UITableCell会被向右推，其contentView.origin.x记录了
 * 被推动的距离；当UITableView退出编辑模式时，UITableCell.contentView.origin.x恢复
 * 为0。此函数根据这一点，来重排所有联系人信息控件。
 */
- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat editOffset = self.contentView.frame.origin.x;
    CGFloat wholeWidth = self.frame.size.width;

    UIButton *btnAvatar  = (UIButton *)[self.contentView viewWithTag:TAG_BTN_AVATAR];
    CGRect rect = btnAvatar.frame;
    rect.origin.x = wholeWidth * RATIO_AVATAR_LEFT - editOffset;
    rect.origin.y = (self.frame.size.height - rect.size.height) / 2;
    btnAvatar.frame = rect;

    CGFloat infoLeft = wholeWidth * ([btnAvatar isHidden] ? RATIO_INFO_LEFT : RATIO_INFO_LEFT2) - editOffset;

    rect = self.textLabel.frame;
    rect.origin.x = infoLeft;
    self.textLabel.frame = rect;

    rect = self.detailTextLabel.frame;
    rect.origin.x = infoLeft;
    rect.size.width = wholeWidth * (1 - RATIO_RIGHT_MARGIN) - editOffset - infoLeft;
    self.detailTextLabel.frame = rect;

    UILabel *countInfo = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_COUNT];
    rect = countInfo.frame;
    rect.origin.x = self.textLabel.frame.origin.x + self.textLabel.frame.size.width + ITEM_PADDING;
    rect.origin.y = self.textLabel.frame.origin.y + (self.textLabel.frame.size.height - rect.size.height) / 2;
    countInfo.frame = rect;

    UIButton *btnBadge = (UIButton *)[self.contentView viewWithTag:TAG_BTN_BADGE];
    if (![btnBadge isHidden]) {
        rect = btnBadge.frame;
        rect.origin.x = wholeWidth * (1 - RATIO_RIGHT_MARGIN) - editOffset - rect.size.width;
        rect.origin.y = self.textLabel.frame.origin.y + (self.textLabel.frame.size.height - rect.size.height) / 2;
        btnBadge.frame = rect;
    }
    rect = btnBadge.frame;
}

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:HEAD_CELL_REUSE_IDENTIFIER];
    if (self != nil) {
        self.backgroundColor = [UIColor clearColor];
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self createSubViews];
    }
    return self;
}

- (void)bindWithTarget:(id)target
                  type:(HeadType)type
                avatar:(UIImage *)photo
             countInfo:(NSString *)countInfo
                  name:(NSString *)name
              descript:(NSString *)descript
            badgeCount:(NSUInteger)badgeCount {

    UIButton *btnAvatar  = (UIButton *)[self.contentView viewWithTag:TAG_BTN_AVATAR];
    btnAvatar.hidden = (type != HeadType_Group);
    [btnAvatar removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    if (!btnAvatar.hidden) {
        [btnAvatar addTarget:target action:@selector(onAvatarClicked) forControlEvents:UIControlEventTouchUpInside];
    }

    self.textLabel.textColor = [UIColor blackColor];
    self.detailTextLabel.textColor = [UIColor colorFromHex:0xFFFC9D65];
    self.detailTextLabel.text = nil;

    switch (type) {
    case HeadType_Group: {
            self.textLabel.text = name;
            UIImage *defaultAvatar = [UIImage imageNamed:@"res/groups_avatar"];
            if (photo == nil) {
                photo = defaultAvatar;
            }
            [btnAvatar setImage:photo forState:UIControlStateNormal];
            CGRect rect = btnAvatar.frame;
            rect.size = defaultAvatar.size;
            btnAvatar.frame = rect;
        }

        self.detailTextLabel.text = descript;
        self.textLabel.textColor = [UIColor colorFromHex:0xFFFC9D65];
        self.detailTextLabel.textColor = [UIColor colorFromHex:0xFF646464];
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_groups_background"]];
        self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_groups_pressed_background"]];
        break;

    case HeadType_SystemMessage:
        self.textLabel.text = I18nString(@"系统消息");
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_message_background"]];
        self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_message_pressed_background"]];
        break;

    case HeadType_Session:
        self.textLabel.text = name;
        self.detailTextLabel.text = descript;
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_sessions_background"]];
        self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_sessions_pressed_background"]];
        break;

    case HeadType_Voicemail:
        self.textLabel.text = I18nString(@"语音邮件");
        self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_voicemail_background"]];
        self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/head_cell_voicemail_pressed_background"]];
        break;
    }

    [self.textLabel sizeToFit];

    UILabel *labelCountInfo = (UILabel *)[self.contentView viewWithTag:TAG_LABEL_COUNT];
    labelCountInfo.text = countInfo;
    [labelCountInfo sizeToFit];

    NSString *title = nil;
    UIButton *btnBadge = (UIButton *)[self.contentView viewWithTag:TAG_BTN_BADGE];
    btnBadge.hidden = (badgeCount <= 0);
    if (badgeCount > 0) {
        title = [NSString stringWithFormat:@"%d", badgeCount];
    }
    [btnBadge setTitle:title forState:UIControlStateNormal];
}

@end
