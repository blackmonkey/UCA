/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#ifndef __HEADELEMENT_H__
#define __HEADELEMENT_H__

/**
 * 置顶列表项类型
 */
typedef enum {
    HeadType_Group,
    HeadType_SystemMessage,
    HeadType_Session,
    HeadType_Voicemail
} HeadType;

@interface HeadElement : QRootElement

@property (nonatomic, assign) HeadType type;
@property (nonatomic, retain) NSString *countInfo;   // 图标右侧的未读/总数信息。
@property (nonatomic, retain) NSString *name;        // 名称。
@property (nonatomic, retain) NSString *descript;    // 描述信息。
@property (nonatomic, assign) NSUInteger badgeCount; // 未读数量标记。

- (id)initWithSession:(Session *)session;

@end

#endif
