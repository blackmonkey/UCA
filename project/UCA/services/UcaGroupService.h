/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@interface UcaGroupService : UcaService

@property (nonatomic, retain, readonly) NSMutableArray *groups;
@property (nonatomic, assign, readonly) BOOL fetchedData;

/**
 * 修改群组的公告。
 * @param group 群组实例。
 * @param ann 新公告。
 */
- (void)modifyGroup:(Group *)group withNewAnnunciate:(NSString *)newAnn;

/**
 * 将指定联系人添加到群组。
 * @param contacts 联系人。
 * @param group 群组实例。
 */
- (void)addContacts:(NSArray *)contacts toGroup:(Group *)group;

/**
 * 从群组中删除指定联系人。
 * @param contacts 联系人。
 * @param group 群组实例。
 */
- (void)removeMembers:(NSArray *)contacts fromGroup:(Group *)group;

/**
 * 获取指定数据库记录ID的群组。
 * @param gid 数据库记录ID。
 * @return 群组实例。
 */
- (Group *)groupOfId:(NSInteger)gid;

/**
 * 检测数据表UGroup中是否存在群组记录包含指定的SIP phone。若不存在，则向服务器获取群组信息，
 * 并保存至数据表UGroup中，并返回该群组实例。若存在，则查询记录，并返回该群组实例。
 *
 * 该接口可在以下情况下调用：
 * 收到IM时，有sipphone
 * @param sipPhone 群组相关sipPhone，sipPhone只能以“img-”开头。
 * @param date 需更新最近访问时间
 * @return 成功返回群组实例，失败返回nil。
 */
- (Group *)touchGroupBySipPhone:(NSString *)sipPhone withTimestamp:(NSDate *)date;

@end
