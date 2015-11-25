/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#ifndef SYSTEM_SIPPHONE
#define SYSTEM_SIPPHONE @"SYSTEM_SIPPHONE"
#endif

/**
 * IM消息发送状态
 */
typedef enum {
    Message_Received_Unread, // IM消息已接收且未读
    Message_Received_Read,   // IM消息已接收且已读
    Message_Sending,         // IM消息发送中
    Message_Sent,            // IM消息发送成功
    Message_SendFailed       // IM消息发送失败
} MessageStatus;

/**
 * Message记录消息相关信息
 */
@interface Message : NSObject

/** 用于发送图片时，记录临时数据，不记录于数据表Message中 */
@property (nonatomic, retain) UIImage *image;      // 发送单张图片时，图片数据。
@property (nonatomic, retain) NSString *imageName; // 发送单张图片时，图片文件名。

/** 不记录于数据表Message中的属性 */
@property (readonly, retain) NSString *senderName;                 // 发送者姓名
@property (readonly, retain) Person *sender;                       // 发送者信息
@property (readonly, retain) Person *receiver;                     // 接收者信息
@property (readonly, retain) Person *toWhom;                       // 群组中，私聊消息接收者信息
@property (nonatomic, assign, getter=isRead) BOOL read;            // 是否已读
@property (readonly, assign, getter=isReceived) BOOL received;     // 是否为接收IM
@property (readonly, assign, getter=isSending) BOOL sending;       // 是否正在发送
@property (readonly, assign, getter=isSent) BOOL sent;             // 是否发送成功
@property (readonly, assign, getter=isSentFailed) BOOL sentFailed; // 是否发送失败

/** 记录于数据表Message中的属性 */
@property (nonatomic, assign) NSInteger id;          // 数据库记录ID
@property (nonatomic, assign) NSInteger accountId;   // IM消息关联的帐号的数据库记录ID
@property (nonatomic, assign) MessageStatus status;  // 发送状态
@property (nonatomic, retain) NSString *senderSip;   // 消息发送者地址
@property (nonatomic, retain) NSString *receiverSip; // 消息接收者地址
@property (nonatomic, retain) NSString *toWhomSip;   // 群组中，私聊消息接收者地址
@property (nonatomic, retain) NSDate *datetime;      // 发送/接收时间
@property (nonatomic, retain) NSString *html;        // IM消息内容(HTML)

- (id)initWithReceiverSipPhone:(NSString *)sipPhone;
- (BOOL)hasToWhom;

@end
