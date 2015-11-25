/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#define UCA_NATIVE_LOGIN                        @"UCA_NATIVE_LOGIN"
#define UCA_NATIVE_KICK_OFF                     @"UCA_NATIVE_KICK_OFF"
#define UCA_NATIVE_ACCOUNT_PRESENTATION         @"UCA_NATIVE_ACCOUNT_PRESENTATION"
#define UCA_NATIVE_CONTACT_PRESENTATION         @"UCA_NATIVE_CONTACT_PRESENTATION"
#define UCA_NATIVE_CONTACTS_PRESENTATION        @"UCA_NATIVE_CONTACTS_PRESENTATION"
#define UCA_NATIVE_GROUP_PRESENTATION           @"UCA_NATIVE_GROUP_PRESENTATION"
#define UCA_NATIVE_SESSION_PRESENTATION         @"UCA_NATIVE_SESSION_PRESENTATION"
#define UCA_NATIVE_IM_RECEIVED                  @"UCA_NATIVE_IM_RECEIVED"
#define UCA_NATIVE_IM_IMG_RECEIVED              @"UCA_NATIVE_IM_IMG_RECEIVED"
#define UCA_NATIVE_IM_SENT_FAILED               @"UCA_NATIVE_IM_SENT_FAILED"
#define UCA_NATIVE_CALL_STATUS                  @"UCA_NATIVE_CALL_STATUS"
#define UCA_NATIVE_ADDRESSBOOK_CHANGED          @"UCA_NATIVE_ADDRESSBOOK_CHANGED"
#define UCA_NATIVE_GROUP_MEMBER_CHANGED         @"UCA_NATIVE_GROUP_MEMBER_CHANGED"
#define UCA_NATIVE_SESSION_MEMBER_CHANGED       @"UCA_NATIVE_SESSION_MEMBER_CHANGED"
#define UCA_NATIVE_SESSION_STATUS               @"UCA_NATIVE_SESSION_STATUS"

#define UCA_EVENT_ADD_MESSAGE                   @"UCA_EVENT_ADD_MESSAGE"
#define UCA_EVENT_UPDATE_MESSAGE                @"UCA_EVENT_UPDATE_MESSAGE"
#define UCA_EVENT_UPDATE_MESSAGES               @"UCA_EVENT_UPDATE_MESSAGES"
#define UCA_EVENT_DELETE_MESSAGES               @"UCA_EVENT_DELETE_MESSAGES"
#define UCA_EVENT_TYPING                        @"UCA_EVENT_TYPING"

#define UCA_EVENT_ADD_CONTACT                   @"UCA_EVENT_ADD_CONTACT"
#define UCA_EVENT_DELETE_CONTACT                @"UCA_EVENT_DELETE_CONTACT"
#define UCA_EVENT_UPDATE_CONTACT                @"UCA_EVENT_UPDATE_CONTACT"
#define UCA_EVENT_UPDATE_CONTACTS               @"UCA_EVENT_UPDATE_CONTACTS"

#define UCA_EVENT_DELETE_ACCOUNT                @"UCA_EVENT_DELETE_ACCOUNT"
#define UCA_EVENT_UPDATE_ACCOUNT                @"UCA_EVENT_UPDATE_ACCOUNT"

#define UCA_EVENT_UPDATE_LOGIN_STATUS           @"UCA_EVENT_UPDATE_LOGIN_STATUS"
#define UCA_EVENT_UPDATE_PRESENT_OK             @"UCA_EVENT_UPDATE_PRESENT_OK"
#define UCA_EVENT_UPDATE_PRESENT_FAIL           @"UCA_EVENT_UPDATE_PRESENT_FAIL"

#define UCA_EVENT_SHUTDOWN_TABS                 @"UCA_EVENT_SHUTDOWN_TABS"

#define UCA_EVENT_FETCHED_ORG_INFO_FAILED       @"UCA_EVENT_FETCHED_ORG_INFO_FAILED"
#define UCA_EVENT_SEARCHED_ORG_INFO_FAILED      @"UCA_EVENT_SEARCHED_ORG_INFO_FAILED"
#define UCA_EVENT_FETCHED_ORG_INFO              @"UCA_EVENT_FETCHED_ORG_INFO"
#define UCA_EVENT_SEARCHED_ORG_INFO             @"UCA_EVENT_SEARCHED_ORG_INFO"
#define KEY_CUR_DEPART                          @"KEY_CUR_DEPART"
#define KEY_TOTAL_COUNT                         @"KEY_TOTAL_COUNT"
#define KEY_DEPARTS                             @"KEY_DEPARTS"
#define KEY_USERINFOS                           @"KEY_USERINFOS"

#define UCA_EVENT_ADD_RECENT_LOG                @"UCA_EVENT_ADD_RECENT_LOG"
#define UCA_EVENT_DELETE_RECENT_LOGS            @"UCA_EVENT_DELETE_RECENT_LOGS"
#define UCA_EVENT_UPDATE_RECENT_LOGS            @"UCA_EVENT_UPDATE_RECENT_LOGS"

#define UCA_EVENT_EMOTE_SELECTED                @"UCA_EVENT_EMOTE_SELECTED"

#define UCA_REQUEST_FETCH_GROUP_INFO            @"UCA_REQUEST_FETCH_GROUP_INFO"
#define UCA_RESPOND_FETCH_GROUP_INFO_OKAY       @"UCA_RESPOND_FETCH_GROUP_INFO_OKAY"
#define UCA_RESPOND_FETCH_GROUP_INFO_FAIL       @"UCA_RESPOND_FETCH_GROUP_INFO_FAIL"

#define UCA_INDICATE_MODIFY_GROUP_OKAY          @"UCA_INDICATE_MODIFY_GROUP_OKAY"
#define UCA_INDICATE_MODIFY_GROUP_FAIL          @"UCA_INDICATE_MODIFY_GROUP_FAIL"

#define UCA_INDICATE_ADD_GROUP_MEMBERS_OKAY     @"UCA_INDICATE_ADD_GROUP_MEMBERS_OKAY"
#define UCA_INDICATE_ADD_GROUP_MEMBERS_FAIL     @"UCA_INDICATE_ADD_GROUP_MEMBERS_FAIL"
#define UCA_INDICATE_DELET_GROUP_MEMBERS_OKAY   @"UCA_INDICATE_DELET_GROUP_MEMBERS_OKAY"
#define UCA_INDICATE_DELET_GROUP_MEMBERS_FAIL   @"UCA_INDICATE_DELET_GROUP_MEMBERS_FAIL"
#define UCA_INDICATE_GROUP_UPDATED              @"UCA_INDICATE_GROUP_UPDATED"

#define UCA_INDICATE_SESSION_CREATED_OKAY       @"UCA_INDICATE_SESSION_CREATED_OKAY"
#define UCA_INDICATE_SESSION_CREATED_FAIL       @"UCA_INDICATE_SESSION_CREATED_FAIL"
#define UCA_INDICATE_SESSION_CLOSED_OKAY        @"UCA_INDICATE_SESSION_CLOSED_OKAY"
#define UCA_INDICATE_SESSION_CLOSED_FAIL        @"UCA_INDICATE_SESSION_CLOSED_FAIL"
#define UCA_INDICATE_SESSION_UPDATED            @"UCA_INDICATE_SESSION_UPDATED"
#define UCA_INDICATE_ADD_SESSION_MEMBERS_OKAY   @"UCA_INDICATE_ADD_SESSION_MEMBERS_OKAY"
#define UCA_INDICATE_ADD_SESSION_MEMBERS_FAIL   @"UCA_INDICATE_ADD_SESSION_MEMBERS_FAIL"
#define UCA_INDICATE_DELET_SESSION_MEMBERS_OKAY @"UCA_INDICATE_DELET_SESSION_MEMBERS_OKAY"
#define UCA_INDICATE_DELET_SESSION_MEMBERS_FAIL @"UCA_INDICATE_DELET_SESSION_MEMBERS_FAIL"

#define UCA_INDICATE_CALL_STATUS_TEXT           @"UCA_INDICATE_CALL_STATUS_TEXT"

/**
 * NotifyUtils提供通知相关的工具函数。
 */

@interface NotifyUtils : NSObject

/**
 * 发送事件通知。
 * @param notification 通知实例
 */
+ (void)postNotification:(NSNotification *)notification;

/**
 * 发送事件通知。
 * @param aName 事件名称
 * @param anObject 事件绑定对象实例
 * @param aUserInfo 事件绑定参数
 */
+ (void)postNotificationWithName:(NSString *)aName;
+ (void)postNotificationWithName:(NSString *)aName object:(id)anObject;
+ (void)postNotificationWithName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

/**
 * 延时发送事件通知。
 * @param aName 事件名称
 * @param anObject 事件绑定对象实例
 * @param aUserInfo 事件绑定参数
 * @param interval 延时秒数
 */
+ (void)postNotificationWithName:(NSString *)aName afterDelay:(NSTimeInterval)interval;
+ (void)postNotificationWithName:(NSString *)aName object:(id)anObject afterDelay:(NSTimeInterval)interval;
+ (void)postNotificationWithName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo afterDelay:(NSTimeInterval)interval;

/**
 * 取消发送事件通知，仅用于delayed Notification。
 * @param aName 事件名称
 * @param anObject 事件绑定对象实例
 * @param aUserInfo 事件绑定参数
 */
+ (void)cancelNotificationWithName:(NSString *)aName;
+ (void)cancelNotificationWithName:(NSString *)aName object:(id)anObject;
+ (void)cancelNotificationWithName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

/**
 * 弹出提醒对话框。
 * @param msg 提醒消息
 */
+ (void)alert:(NSString *)msg;

/**
 * 弹出提醒对话框。
 * @param msg 提醒消息
 * @param delegate 提醒对话框事件处理实例
 */
+ (void)alert:(NSString *)msg delegate:(id)delegate;

/**
 * 弹出确认对话框。
 * @param msg 确认提示消息
 * @param delegate 确认对话框事件处理实例
 */
+ (void)confirm:(NSString *)msg delegate:(id)delegate;

/**
 * UIProgressHud的替代。进度对话框。
 * @param msg 提醒消息
 */
+ (UIAlertView *)progressHud:(NSString *)msg;

@end
