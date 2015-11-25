/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#define CONTACT_CELL_REUSE_IDENTIFIER @"CONTACT_CELL_REUSE_IDENTIFIER"

/**
 * ContactCell用于显示联系人列表项，可用于联系人列表、最近联系人列表和组织架构列表。
 */

@interface ContactCell : UITableViewCell

/**
 * 获取ContactCell的高度。
 * @return ContactCell的高度
 */
+ (CGFloat)height;

/**
 * 初始化ContactCell实例。
 * @param target 响应按钮事件的实例，该实例必须实现以下方法：
 *      - (void)onAvatarBtnClicked;
 *      - (void)onImBtnClicked;
 *      - (void)onCameraBtnClicked;
 *      - (void)onPhoneBtnClicked;
 * @return ContactCell实例。
 */
- (id)initWithTarget:(id)target;

/**
 * 为ContactCell实例绑定信息。
 * @param target 响应按钮事件的实例，该实例必须实现以下方法：
 *      - (void)onAvatarBtnClicked;
 *      - (void)onImBtnClicked;
 *      - (void)onCameraBtnClicked;
 *      - (void)onPhoneBtnClicked;
 * @param contact 相应的联系人。
 * @param isOwnContact 该联系人是否等同于登录帐号，若是则不显示IM、音视频电话按钮；否则显示。
 */
- (void)bindWithTarget:(id)target andContact:(Contact *)contact isOwnContact:(BOOL)isOwnContact;

@end
