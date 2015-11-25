/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * 添加联系人结果
 */
typedef enum {
    AddContact_Success,  // 添加成功
    AddContact_Failure,  // 添加失败
    AddContact_Account,  // 不能添加当前帐号为其好友
    AddContact_Duplicate // 重复添加
} AddContactResult;

/* 系统消息对应的联系人ID */
#undef SYSTEM_MESSAGE_CONTACT_ID
#define SYSTEM_MESSAGE_CONTACT_ID (-100)

/* 语音邮箱对应的联系人ID */
#undef VOICEMAIL_CONTACT_ID
#define VOICEMAIL_CONTACT_ID (-101)

@interface UcaContactService : UcaService

/**
 * 检测数据表Contact中是否存在联系人记录包含指定的SIP phone。若不存在，则向服务器获取联系人信息，
 * 并保存至数据表Contact中，并返回该联系人实例。若存在，则查询记录，并返回该联系人实例。
 *
 * 该接口可在以下情况下调用：
 * 收到IM时，有sipphone
 * 收到来电时，有sipphone
 * 拨出电话时，有sipphone
 * 收到固定群组成员变化时，有sipphone
 * 收到多人会话成员变化时，有sipphone
 * @param sipPhone 联系人相关sipPhone，sipPhone不能以“img-”开头。
 * @param date 需更新最近访问时间
 * @return 成功返回联系人实例，失败返回nil。
 */
- (Contact *)touchContactBySipPhone:(NSString *)sipPhone;
- (Contact *)touchContactBySipPhone:(NSString *)sipPhone withTimestamp:(NSDate *)date;

/**
 * 检测数据表Contact中是否存在联系人记录与指定联系人实例相等。若不存在，则创建相关数据表记录，
 * 并将记录ID存入联系人实例。若存在，则查询记录，并将记录ID存入联系人实例。
 *
 * 该接口可在以下情况下调用：
 * 获取到组织架构联系人时，有userinfo
 * 获取到固定群组联系人时，有userinfo
 * 获取到多人会话联系人时，有userinfo
 * @param contact 联系人实例，其中，作为判断标准，userId和contactType必须有效，contactType不能是ContactType_Group。
 * @return 成功返回YES，失败返回NO。
 */
- (BOOL)touchContact:(Contact *)contact;

/**
 * 从最近联系人添加好友。
 * @param contact 最近联系人信息。
 * @return 参见AddContactResult。
 */
- (AddContactResult)addFriendWithRecentContact:(Contact *)contact;

/**
 * 从地址簿添加好友。
 * @param contact 地址簿联系人信息。
 * @return 参见AddContactResult。
 */
- (AddContactResult)addAddressBookContact:(Contact *)contact;

/**
 * 自己输入添加私有联系人。
 * @param contact 私有联系人信息。
 * @return 参见AddContactResult。
 */
- (AddContactResult)addPrivateContact:(Contact *)contact;

/**
 * 从固定群组、多人会话、组织架构添加好友。
 * @param contact 列表联系人的信息。
 * @return 参见AddContactResult。
 */
- (AddContactResult)addFriendWithContact:(Contact *)contact;

/**
 * 添加群组联系人
 * @param group 群组联系人的信息。
 * @return 参见AddContactResult。
 */
- (AddContactResult)addRelationWithGroup:(Group *)group;

/**
 * 更新联系人的最近访问时间。
 * @param contact 指定联系人。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateAccessOfContact:(Contact *)contact;

/**
 * 更新地址簿联系人。
 * @param contact 地址簿联系人信息。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateAddressBookContact:(Contact *)contact;

/**
 * 更新私有联系人。
 * @param contact 私有联系人信息。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updatePrivateContact:(Contact *)contact;

/**
 * 更新联系人状态
 * @param userId 联系人的user id。
 * @param presentation 联系人的在线装态。
 * @param cameraOn 联系人的摄像头状态。
 * @return 如果更新成功则返回YES；否则返回NO。
 */
- (BOOL)updateContact:(NSInteger)userId
         presentation:(UCALIB_PRESENTATIONSTATE)presentation
             cameraOn:(BOOL)cameraOn;

/**
 * 删除单个联系人。
 * @param contact 指定联系人。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteContact:(Contact *)contact;

/**
 * 删除多个联系人。
 * @param contacts 指定的多个联系人。
 * @return 如果删除成功则返回YES；否则返回NO。
 */
- (BOOL)deleteContacts:(NSArray *)contacts;

/**
 * 获取含有指定电话号码的联系人。
 * @param number 全部或部分电话号码。
 * @return 满足要求的联系人。
 */
- (NSArray *)getContactsByPhoneNumber:(NSString *)number;

/**
 * 获取指定记录号的联系人。
 * @param addr 联系人的软终端号码。
 * @return 满足要求的联系人。
 */
- (Contact *)getContactBySipPhone:(NSString *)addr;

/**
 * 获取指定记录号的联系人。
 * @param contactId 联系人记录号。
 * @return 满足要求的联系人。
 */
- (Contact *)getContactById:(NSInteger)contactId;

/**
 * 获取最近联系人。
 * @return 最近联系人。
 */
- (NSArray *)getRecentContacts;

/**
 * 获取好友、私有联系人和通讯录联系人。
 * @return 联系人。
 */
- (NSArray *)getNormalContacts;

/**
 * 获取好友。
 * @return 联系人。
 */
- (NSArray *)getFriends;

/**
 * 获取最近联系的好友。
 * @return 最近联系人。
 */
- (NSArray *)getRecentFriends;

/**
 * 登录时更新联系人状态
 */
- (void)updatePresentationWhenLogin:(UcaContactPresentationEvent *)event;

/**
 * 登录时更新联系人状态
 */
- (void)updatePresentationsWhenLogin:(NSString *)xmlMsg;

@end