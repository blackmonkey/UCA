/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@class MessageElement;

@protocol MessageElementDelegate <NSObject>

@optional
- (void)messageElement:(MessageElement *)element clickedAccount:(NSInteger)accountId;
- (void)messageElement:(MessageElement *)element clickedContact:(NSInteger)contactId;

@end

@interface MessageElement : QElement<UIWebViewDelegate>

@property (nonatomic, assign/*unsafe_unretained*/) id<MessageElementDelegate> delegate;
@property (nonatomic, retain) Message *message;

- (MessageElement *)initWithMessage:(Message *)msg;

- (NSString *)fullHtml;
- (NSString *)senderAndTimeInfo;

@end
