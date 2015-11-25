/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <AddressBook/AddressBook.h>

/**
 * Contact记录所有联系人的信息。
 *
 * 对于ContactType_AddressBook类型的联系人，userId保存的是手机联系人的record id
 * (由函数ABRecordGetRecordID获取)。该类型联系人不保存在UCA服务器上，可以添加(通
 * 过手机地址簿)、修改(同步更新至手机地址簿)、删除(仅删除本应用的数据库中的记录)，
 * 无论当前帐号已登录或处于离线状态。
 *
 * 对于ContactType_Friend类型的联系人，即“好友”，是UCA服务器上其他的用户帐号，所以
 * userId保存的是其他用户帐号的Account.userId。该类型联系人只可以添加(通过搜索服务
 * 器功能)和删除(同步删除服务器上的记录)，而且只能在当前帐号已登录的状态下。
 *
 * 对于ContactType_Private类型的联系人，即“私有联系人”，是保存于UCA服务器上、本帐号
 * 的通讯录，userId保存的是服务器的XML里contactId节点的值。该类型联系人只可以添加、
 * 修改、删除，同时将改动同步至服务器，但只能在当前帐号已登录的状态下。
 */
@interface Contact : Person

/** 记录于数据表Contact中的属性 */
@property (nonatomic, assign) NSInteger accountId;     // 联系人关联的帐号的数据库记录ID
@property (nonatomic, assign) ContactType contactType; // 联系人类型
@property (nonatomic, retain) NSDate *accessed;        // 最近联系时间
@property (nonatomic, assign) BOOL cameraOn;           // 是否激活了摄像头
@property (nonatomic, assign) BOOL voicemailOn;        // 是否激活了语音邮箱

/** 不记录于数据表Contact中的属性 */
@property (readonly, retain) id accessedDbVal;               // 用于更新数据库的最近联系时间的值
@property (readonly, assign) NSUInteger unreadMessageCount;  // 未读消息总数
@property (readonly, retain) NSString *listDescription;      // 显示于列表界面的联系人描述信息

/**
 * 从指定Group实例中初始化数据。
 * @param group 指定Group实例。
 */
- (id)initWithGroup:(Group *)group;

/**
 * 从指定Session实例中初始化数据。
 * @param session 指定Session实例。
 */
- (id)initWithSession:(Session *)session;

/**
 * 从指定Person实例中复制数据。
 * @param person 指定Person实例。
 */
- (void)copyDataFromPerson:(Person *)person;

/**
 * 从指定手机地址簿联系人中复制数据。
 * @param person 指定手机地址簿联系人。
 */
- (void)copyDataFromABRecord:(ABRecordRef)person;

/**
 * 将数据复制到指定手机地址簿联系人。
 * @param person 指定手机地址簿联系人。
 */
- (void)copyDataToABRecord:(ABRecordRef)person;

/**
 * 比较两个联系人以决定在列表中的顺序。
 * @param theOther 另一个联系人
 * @return NSComparisonResult
 */
- (NSComparisonResult)compareWithContact:(Contact *)theOther;

/**
 * 获取第一个包含指定字符串的电话号码。
 * @param pattern 部分电话号码
 * @return 找到的电话号码，或者nil;
 */
- (NSString *)numberMatched:(NSString *)pattern;

/**
 * 获取第一个有效的电话号码。
 * @return 找到的电话号码，或者nil;
 */
- (NSString *)firstValidPhonenumber;

@end
