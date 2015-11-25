/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@class Contact;

@interface Group : NSObject

/** 记录于数据表Contact中的属性 */
@property (nonatomic, assign) NSInteger id;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *sipPhone;
@property (nonatomic, assign) NSInteger fileSpaceSize;
@property (nonatomic, retain) NSString *creator;
@property (nonatomic, retain) NSString *createTime;
@property (nonatomic, retain) NSMutableArray *administrators;
@property (nonatomic, assign) NSInteger userCount;
@property (nonatomic, assign) NSInteger userMaxAmount;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) UIImage *photo;
@property (nonatomic, retain) NSString *annunciate;
@property (nonatomic, retain) NSString *descrip;
@property (nonatomic, assign) BOOL canAdmin;
@property (nonatomic, assign) BOOL canUpload;

/** 不记录于数据表Contact中的属性 */
@property (readonly, assign) NSUInteger unreadCount;
@property (readonly, retain) NSString *countInfo;
@property (nonatomic, retain) NSMutableArray *contacts;

- (id)initWithContact:(Contact *)contact;
- (void)addContact:(Contact *)contact;
- (void)addContacts:(NSArray *)otherContacts;
- (void)removeContacts:(NSArray *)otherContacts;

@end
