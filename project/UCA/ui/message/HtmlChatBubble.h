/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface HtmlChatBubble : UIWebView

@property (nonatomic, retain) NSString *html;
@property (nonatomic, assign) BOOL sentBubble;
@property (nonatomic, retain) NSString *imgSrcPrefix;

@end
