/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@class Contact;

@interface Session : NSObject

@property (nonatomic, assign) NSInteger id;
@property (nonatomic, retain) NSString *sipPhone;
@property (nonatomic, retain) NSMutableArray *contacts;

@property (readonly, assign) NSUInteger unreadCount;
@property (readonly, retain) NSString *descrip;
@property (readonly, retain) NSString *name;
@property (readonly, retain) NSString *countInfo;

- (id)initWithContact:(Contact *)contact;
- (void)addContacts:(NSArray *)otherContacts;
- (void)removeContacts:(NSArray *)otherContacts;

@end
