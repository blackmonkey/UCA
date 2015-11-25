/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <QuartzCore/QuartzCore.h>
#import "HtmlChatBubble.h"
#import "MessageElement.h"

#define SENDER_LABEL_HEIGHT  24
#define CELL_H_PADDING       8
#define CELL_V_PADDING       10
#define GAP_AVATAR_BUBBLE    5
#define GAP_AVATAR_SENDER    14
#define GAP_BUBBLE_STATUS    5
#define AVATAR_BORDER_WIDTH  1
#define AVATAR_SIZE          66
#define INDICATOR_SIZE       20
#define BUBBLE_HOLDER_WIDTH  80
#define BUBBLE_HOLDER_HEIGHT 40

#define TAG_IMG_SEND_FAILED   (101)
#define TAG_BTN_AVATAR        (102)
#define TAG_IND_INDICATOR     (103)
#define TAG_LABEL_SENDER_TIME (104)
#define TAG_MSG_CONTENT       (105)

@implementation MessageElement {
    BOOL _htmlLoaded;
    CGFloat _editOffset;

    QuickDialogTableView *_tableView;
    HtmlChatBubble *_messageBubble;
    UIImageView *_messageBubbleHolder;
}

@synthesize delegate;
@synthesize message;

- (void)resizeBubbleWithMaxWidth:(CGFloat)maxWidth {
    // 先将body的size设为足够大，并恢复table的size。
    CGSize size = [[UIScreen mainScreen] bounds].size;
    NSString *js = [NSString stringWithFormat:@"document.body.style.width = %.0f;document.body.style.height = %.0f;", size.width, size.height];
    [_messageBubble stringByEvaluatingJavaScriptFromString:js];
    js = [NSString stringWithFormat:@"var o = document.getElementById('%@'); o.style.width = 0;", IM_WRAPPER_ID];
    [_messageBubble stringByEvaluatingJavaScriptFromString:js];

    CGSize contentSize;

    js = [NSString stringWithFormat:@"var o = document.getElementById('%@'); o.offsetWidth + o.offsetLeft * 2", IM_WRAPPER_ID];
    contentSize.width = [[_messageBubble stringByEvaluatingJavaScriptFromString:js] floatValue];

    if (contentSize.width > maxWidth) {
        contentSize.width = maxWidth;

        js = [NSString stringWithFormat:@"var o = document.getElementById('%@'); o.style.width = %.0f - o.offsetLeft * 2", IM_WRAPPER_ID, contentSize.width];
        [_messageBubble stringByEvaluatingJavaScriptFromString:js];
    }

    js = [NSString stringWithFormat:@"var o = document.getElementById('%@'); o.offsetHeight + o.offsetTop * 2", IM_WRAPPER_ID];
    contentSize.height = [[_messageBubble stringByEvaluatingJavaScriptFromString:js] floatValue];

    CGRect rect = _messageBubble.frame;
    rect.size = contentSize;
    _messageBubble.frame = rect;
}

- (void)createSubViewsInCell:(UITableViewCell *)cell {
    UILabel *senderAndTime = [[UILabel alloc] initWithFrame:CGRectZero];
    senderAndTime.tag = TAG_LABEL_SENDER_TIME;
    senderAndTime.textAlignment = UITextAlignmentLeft;
    senderAndTime.font = [UIFont systemFontOfSize:12.0];
    senderAndTime.textColor = [UIColor whiteColor];
    senderAndTime.shadowColor = [UIColor colorFromHex:0x80C0C0C0];
    senderAndTime.shadowOffset = CGSizeMake(0, -0.5);
    senderAndTime.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:senderAndTime];

    UIButton *avatarView = [UIButton buttonWithType:UIButtonTypeCustom];
    avatarView.tag = TAG_BTN_AVATAR;
    avatarView.layer.borderWidth = AVATAR_BORDER_WIDTH;
    avatarView.layer.borderColor = [UIColor colorFromHex:0xF0FFFFFF].CGColor;
    avatarView.layer.shadowColor = [UIColor blackColor].CGColor;
    avatarView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
    avatarView.layer.shadowOpacity = 0.7;
    avatarView.layer.shadowRadius = 0.5; 
    avatarView.backgroundColor = [UIColor clearColor];
    [avatarView addTarget:self action:@selector(onAvatarClicked) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:avatarView];

    if (_htmlLoaded) {
        [cell.contentView addSubview:_messageBubble];
    } else {
        [cell.contentView addSubview:_messageBubbleHolder];
    }

    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicator.tag = TAG_IND_INDICATOR;
    indicator.hidesWhenStopped = YES;
    [indicator stopAnimating];
    [cell.contentView addSubview:indicator];

    UIImageView *sentFailed = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"res/status_dontbreak"]];
    sentFailed.tag = TAG_IMG_SEND_FAILED;
    [cell.contentView addSubview:sentFailed];
}

- (NSString *)fullHtml {
    return self.message.html;
}

- (NSString *)senderAndTimeInfo {
    NSMutableString *res = [[NSMutableString alloc] initWithString:[self.message senderName]];
    if ([self.message hasToWhom]) {
        [res appendFormat:I18nString(@"对%@说"), self.message.toWhom.displayName];
    }
    [res appendFormat:I18nString(@" @ %@"), [NSString getTime:self.message.datetime]];
    return res;
}

- (void)bindMessageInfoToCell:(UITableViewCell *)cell {
    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];

    UIImage *photo = nil;
    UIButton *avatarView = (UIButton *)[cell.contentView viewWithTag:TAG_BTN_AVATAR];
    if ([self.message isReceived]) {
        Person *sender = [self.message sender];
        if (sender.photo) {
            photo = sender.photo;
        }
    } else {
        Account *account = [app.accountService accountWithLoginInfo:app.accountService.curAccountId];
        if (account.photo) {
            photo = account.photo;
        }
    }
    if (!photo) {
        photo = [UIImage imageNamed:@"res/chat_default_avatar"];
    }
    CGFloat width, height;
    width = photo.size.width;
    height = photo.size.height;
    width=width>AVATAR_SIZE?AVATAR_SIZE:width;
    height=height>AVATAR_SIZE?AVATAR_SIZE:height;
    avatarView.frame = CGRectMake(0, 0,  width + AVATAR_BORDER_WIDTH * 2, height + AVATAR_BORDER_WIDTH * 2);
    [avatarView setImage:photo forState:UIControlStateNormal];

    UILabel *senderAndTime = (UILabel *)[cell.contentView viewWithTag:TAG_LABEL_SENDER_TIME];
    senderAndTime.text = [self senderAndTimeInfo];
    [senderAndTime sizeToFit];

    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:TAG_IND_INDICATOR];
    UIImageView *sentFailed = (UIImageView *)[cell.contentView viewWithTag:TAG_IMG_SEND_FAILED];
    if (!_htmlLoaded) {
        [indicator startAnimating];
        [sentFailed setHidden:YES];
    } else if ([self.message isSending]) {
        [indicator startAnimating];
        [sentFailed setHidden:YES];
    } else if ([self.message isSentFailed]) {
        [indicator stopAnimating];
        [sentFailed setHidden:NO];
    } else if ([self.message isSent]) {
        [indicator stopAnimating];
        [sentFailed setHidden:YES];
    } else {
        [indicator stopAnimating];
        [sentFailed setHidden:YES];
    }

    UIView *bubble = [cell.contentView viewWithTag:TAG_MSG_CONTENT];
    [bubble removeFromSuperview];
    if (_htmlLoaded) {
        [cell.contentView addSubview:_messageBubble];
    } else {
        [cell.contentView addSubview:_messageBubbleHolder];
    }
}

/**
 * 当UITableView进入编辑模式时，UITableCell会被向右推，其contentView.origin.x记录了
 * 被推动的距离；当UITableView退出编辑模式时，UITableCell.contentView.origin.x恢复
 * 为0。此函数根据这一点，来重排所有联系人信息控件。
 *
 * 320x480屏幕大小下，这段偏移的距离是32。因为UITableView更新cell时，先获取cell的高度，
 * 再获取cell的实例，所以函数editingOffset的返回值用于预先计算cell的高度。
 */
- (CGFloat)editingOffset {
    return _tableView.editing ? 32 : 0;
}

- (CGFloat)contentWidthOfCell:(UITableViewCell *)cell {
    CGFloat cellWidth = _tableView.frame.size.width;
    if (cell) {
        cellWidth = cell.frame.size.width;
    }
    return cellWidth - [self editingOffset] - CELL_H_PADDING * 2;
}

- (CGFloat)maxWidthOfSenderTimeInCell:(UITableViewCell *)cell {
    CGFloat avatarWidth = AVATAR_SIZE;
    if (cell) {
        avatarWidth = [cell.contentView viewWithTag:TAG_BTN_AVATAR].frame.size.width;
    }
    return [self contentWidthOfCell:cell] - avatarWidth - GAP_AVATAR_SENDER;
}

- (CGFloat)maxWidthOfBubbleInCell:(UITableViewCell *)cell {
    CGFloat avatarWidth = AVATAR_SIZE;
    CGFloat indicatorWidth = INDICATOR_SIZE;
    if (cell) {
        avatarWidth = [cell.contentView viewWithTag:TAG_BTN_AVATAR].frame.size.width;
        indicatorWidth = [cell.contentView viewWithTag:TAG_IND_INDICATOR].frame.size.width;
    }
    return [self contentWidthOfCell:cell] - avatarWidth - GAP_AVATAR_BUBBLE - GAP_BUBBLE_STATUS - indicatorWidth;
}

/**
 * 当UITableView进入编辑模式时，UITableCell会被向右推，其contentView.origin.x记录了
 * 被推动的距离；当UITableView退出编辑模式时，UITableCell.contentView.origin.x恢复
 * 为0。此函数根据这一点，来重排所有联系人信息控件。
 */
- (void)layoutSubViewsInCell:(UITableViewCell *)cell {
    UIButton *avatarView = (UIButton *)[cell.contentView viewWithTag:TAG_BTN_AVATAR];
    UILabel *senderAndTime = (UILabel *)[cell.contentView viewWithTag:TAG_LABEL_SENDER_TIME];
    UIView *bubble = [cell.contentView viewWithTag:TAG_MSG_CONTENT];
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:TAG_IND_INDICATOR];
    UIImageView *sentFailed = (UIImageView *)[cell.contentView viewWithTag:TAG_IMG_SEND_FAILED];

    CGFloat wholeWidth = cell.frame.size.width;

    CGRect rect = avatarView.frame;
    rect.origin.y = 0;
    if ([self.message isReceived]) {
        rect.origin.x = CELL_H_PADDING;
    } else {
        rect.origin.x = wholeWidth - CELL_H_PADDING - rect.size.width - [self editingOffset];
    }
    avatarView.frame = rect;

    rect = senderAndTime.frame;
    CGFloat maxW = [self maxWidthOfSenderTimeInCell:cell];
    if (rect.size.width > maxW) {
        rect.size.width = maxW;
    }
    rect.size.height = SENDER_LABEL_HEIGHT;
    rect.origin.y = 0;
    if ([self.message isReceived]) {
        rect.origin.x = avatarView.frame.origin.x + avatarView.frame.size.width + GAP_AVATAR_SENDER;
    } else {
        rect.origin.x = avatarView.frame.origin.x - GAP_AVATAR_SENDER - rect.size.width;
    }
    senderAndTime.frame = rect;

    if ([bubble isKindOfClass:[HtmlChatBubble class]]) {
        [self resizeBubbleWithMaxWidth:[self maxWidthOfBubbleInCell:cell]];
    }

    rect = bubble.frame;
    rect.origin.y = senderAndTime.frame.origin.y + senderAndTime.frame.size.height;
    if ([self.message isReceived]) {
        rect.origin.x = avatarView.frame.origin.x + avatarView.frame.size.width + GAP_AVATAR_BUBBLE;
    } else {
        rect.origin.x = avatarView.frame.origin.x - GAP_AVATAR_BUBBLE - bubble.frame.size.width;
    }
    bubble.frame = rect;

    rect = indicator.frame;
    rect.origin.y = bubble.frame.origin.y + bubble.frame.size.height - rect.size.height;
    if ([self.message isReceived]) {
        rect.origin.x = bubble.frame.origin.x + bubble.frame.size.width + GAP_BUBBLE_STATUS;
    } else {
        rect.origin.x = bubble.frame.origin.x - GAP_BUBBLE_STATUS - rect.size.width;
    }
    indicator.frame = rect;
    sentFailed.frame = rect;

    _height = MAX(bubble.frame.origin.y + bubble.frame.size.height,
                  avatarView.frame.origin.y + avatarView.frame.size.height);
}

- (void)createBubbleViews {
    _messageBubble = [[HtmlChatBubble alloc] init];
    _messageBubble.tag = TAG_MSG_CONTENT;
    _messageBubble.delegate = self;
    _messageBubble.sentBubble = (![self.message isReceived]);
    _messageBubble.imgSrcPrefix = [NSString stringWithFormat:@"msg%d_", self.message.id];
    _messageBubble.html = self.message.html;

    _messageBubbleHolder = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, BUBBLE_HOLDER_WIDTH, BUBBLE_HOLDER_HEIGHT)];
    _messageBubbleHolder.tag = TAG_MSG_CONTENT;

    UIImage *bgImg = nil;
    if ([self.message isReceived]) {
        bgImg = [UIImage imageNamed:@"res/chat_receive_background"];
    } else {
        bgImg = [UIImage imageNamed:@"res/chat_send_background"];
    }
    _messageBubbleHolder.image = [bgImg resizeFromCenter];
//    _messageBubbleHolder.image = [bgImg stretchableImageWithLeftCapWidth:(bgImg.size.width / 2)
//                                                            topCapHeight:(bgImg.size.height / 2)];
}

- (MessageElement *)initWithMessage:(Message *)msg {
    self = [super init];
    if (self) {
        self.message = msg;
        _htmlLoaded = NO;

        /**
         * 只能通过主线程去修改UI：因为创建_messageBubble的时候，会加载网页，所以会修改UI。
         * 相关crash信息：
         * bool _WebTryThreadLock(bool), 0x12358a40: Tried to obtain the web lock from a thread other than the main thread or
         * the web thread. This may be a result of calling to UIKit from a secondary thread. Crashing now...
         */
        [self performSelectorOnMainThread:@selector(createBubbleViews) withObject:nil waitUntilDone:YES];
    }
    return self;
}

- (void)dealloc {
    _messageBubble.delegate = nil;
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    _tableView = tableView;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"QuickformMessageCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"QuickformMessageCell"];
        cell.backgroundColor = [UIColor clearColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self createSubViewsInCell:cell];
    }
    [self bindMessageInfoToCell:cell];
    [self layoutSubViewsInCell:cell];
    cell.selectionStyle = (tableView.editing ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone);
    return cell;
}

- (CGFloat)getRowHeightForTableView:(QuickDialogTableView *)tableView {
    CGFloat h = MAX(_height, AVATAR_SIZE);
    if (_htmlLoaded) {
        [self resizeBubbleWithMaxWidth:[self maxWidthOfBubbleInCell:nil]];
        h = _messageBubble.frame.size.height + SENDER_LABEL_HEIGHT;
        h = MAX(h, AVATAR_SIZE);
    }
    return h + CELL_V_PADDING;
}

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidFinishLoad:(HtmlChatBubble *)webView {
    _htmlLoaded = YES;
    [_tableView reloadCellForElements:self, nil];
}

#pragma mark - IBAction methods

- (void)onAvatarClicked {
    if (!self.message) {
        return;
    }

    if ([self.message isReceived]) {
        if (delegate && [delegate respondsToSelector:@selector(messageElement:clickedContact:)]){
            Person *sender = [self.message sender];
            [delegate messageElement:self clickedContact:sender.id];
        }
    } else {
        if (delegate && [delegate respondsToSelector:@selector(messageElement:clickedAccount:)]){
            [delegate messageElement:self clickedAccount:self.message.accountId];
        }
    }
}

@end
