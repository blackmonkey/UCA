/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@class Privilege;
@class Account;
@class Contact;

/**
 * 联系人管理操作类型
 */
typedef enum {
    ManageType_Add = 1, // 添加
    ManageType_Update,  // 修改
    ManageType_Delete   // 删除
} ManageType;

@interface XmlUtils : NSObject

/**
 * 解析指定XML内容，并初始化Privilege实例。
 * @param privilege Privilege实例。
 * @param xmlData XML内容。
 */
+ (void)initPrivilege:(Privilege *)privilege withXml:(const char *)xmlData;

/**
 * 解析指定UserInfo XML内容，并初始化Account实例。
 * @param account Account实例。
 * @param xmlData XML内容。
 */
+ (void)initAccount:(Account *)account withXml:(const char *)xmlData;

/**
 * 构建服务器用户修改自己的信息的XML编码格式。
 * @param account Account实例。
 * @return UserInfo XML内容。
 */
+ (NSString *)buildUserInfoWithAccount:(Account *)account;

/**
 * 解析制定XML内容，并获取联系人信息。
 * @param xmlData XML内容。
 * @return 解析出的所有联系人。
 */
+ (NSMutableArray *)fetchContactsFromXml:(const char *)xmlData forType:(ContactType)type;

/**
 * 构建添加/删除好友的输入XML。
 * @param contacts 要的一个或多个Contact实例。
 * @param type 操作类型，ManageType_Add或ManageType_Delete。
 * @return managerPrivateContact XML内容。
 */
+ (NSString *)buildManageFriendXml:(NSArray *)contacts manage:(ManageType)type;

/**
 * 构建添加/修改私有联系人的输入XML。
 * @param contact 要添加/修改的Contact实例。
 * @param type 操作类型，ManageType_Add或ManageType_Delete。
 * @return managerFriend XML内容。
 */
+ (NSString *)buildAddOrUpdatePrivateXml:(Contact *)contact manage:(ManageType)type;

/**
 * 构建批量删除私有联系人的输入XML。
 * @param contacts 要批量删除的Contact实例。
 * @return managerPrivateContact XML内容。
 */
+ (NSString *)buildDeletePrivateXml:(NSArray *)contacts;

/**
 * 解析制定XML内容，并获取联系人在线状态更新信息。
 * @param xmlData XML内容。
 * @return 解析出的所有联系人状态更新信息。
 */
+ (NSMutableArray *)parseMultiPresenceNotification:(const char *)xmlData;

/**
 * 构建通过部门ID搜索信息输入的XML编码格式。
 * @param departId 部门ID
 * @param count 总记录数，首次查询传入此参数值为0。
 * @param page 查询页
 * @param pageSize 每页显示记录数
 * @return 搜索信息输入XML内容。
 */
+ (NSString *)buildSearchDepartById:(NSInteger)departId totalCount:(NSInteger)count page:(NSInteger)page pageSize:(NSInteger)size;

/**
 * 构建搜索部门信息的输入XML编码格式。
 * @param keywords 搜索关键字
 * @param count 总记录数，首次查询传入此参数值为0。
 * @param page 查询页
 * @param pageSize 每页显示记录数
 * @return 搜索信息输入XML内容。
 */
+ (NSString *)buildSearchDepartByKeyword:(NSString *)keywords totalCount:(NSInteger)count page:(NSInteger)page pageSize:(NSInteger)size;

/**
 * 解析通过部门ID搜索信息的编码格式。
 * 解析搜索部门信息的输处XML编码格式。
 * @param xmlData XML内容。
 * @return 解析出的所有部门和联系人信息。
 */
+ (NSMutableDictionary *)parseDepartInfos:(const char *)xmlData;

/**
 * 构建“根据固定群组的ID获取群组成员的编码格式”。
 * @param groupId 固定群组的ID
 * @return 输入XML内容。
 */
+ (NSString *)buildGetGroupMembers:(NSInteger)gourpId;

/**
 * 解析XML内容，并获取固定群组列表。
 * @param xmlData XML内容。
 * @return 解析出的所有固定群组。
 */
+ (NSMutableArray *)parseGroupInfos:(const char *)xmlData;

/**
 * 构建修改固定群组公告的XML。
 * @param groupId 固定群组的ID
 * @param newAnn 新的公告
 * @return 输入XML内容。
 */
+ (NSString *)buildModifyGroup:(NSInteger)gourpId annunciate:(NSString *)newAnn;

/**
 * 构建XML以将指定联系人添加到群组。
 * @param contacts 联系人。
 * @param group 群组实例。
 * @return 输入XML内容。
 */
+ (NSString *)buildAddContacts:(NSArray *)contacts toGroup:(Group *)group;

/**
 * 构建XML以从群组中删除指定联系人。
 * @param contacts 联系人。
 * @param group 群组实例。
 * @return 输入XML内容。
 */
+ (NSString *)buildRemoveMembers:(NSArray *)contacts fromGroup:(Group *)group;

/**
 * 解析XML内容，并获取固定群组变更信息。
 * @param xmlData XML内容。
 * @return 解析出的固定群组变更信息。
 */
+ (GroupChangeInfo *)parseGroupChangeInfo:(const char *)xmlData;

/**
 * 构建XML以获取指定联系人信息。
 * @param sipPhones 一个或多个联系人的sipPhone。
 * @param usernames 一个或多个联系人的username。
 * @return 输入XML内容。
 */
+ (NSString *)buildGetPersonsInfo:(NSArray *)sipPhones;
+ (NSString *)buildGetPersonsInfo:(NSArray *)sipPhones orUsernames:(NSArray *)usernames;

@end
