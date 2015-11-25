/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <libxml/tree.h>

#ifndef __UCA_CONFIG_H__
#define __UCA_CONFIG_H__

#define ENABLE_DECODE_ENCODE_AVATAR

// 7月底之后实现、修正以下功能
#undef ENABLE_VOICE_MAIL
#undef ENABLE_VIDEO_TUTORIAL

#define DEBUG_SQL
#define SHOW_BUILD_INFO

#ifdef DEBUG
#define UcaLog(TAG, FMT, ...) NSLog(@"[%@]" FMT "\n", TAG, ##__VA_ARGS__)
#else
#define UcaLog(TAG, FMT, ...)
#endif

#undef UcaCFRelease
// DEBUG CFRelease
//#define UcaCFRelease(x) \
//    do { \
//        UcaLog(@"UcaCFRelease", @"%s %d, %p, retain count: %d", __FILE__, __LINE__, (x), CFGetRetainCount(x)); \
//        if (x) { \
//            CFRelease(x); \
//            (x) = NULL; \
//        } \
//    } while (0)

// FIXME: 调用CFRelease会引起重复释放，导致在方法[Contact copyDataFromABRecord]中crash，
// 需要花很多事件来DEBUG。暂时不调用，虽然可能会导致内存泄漏，但应用不会crash。7月7日后再来DEBUG。
//#define UcaCFRelease(x) if ((x) && CFGetRetainCount(x) > 0) CFRelease(x), (x) = NULL
#define UcaCFRelease(x) (x) = NULL

#undef UcaLibRelease
#define UcaLibRelease(x) if (x) ucaLib_Free(x), (x) = NULL

#undef I18nString
#define I18nString(x) NSLocalizedString(x, nil)

#undef CFTYPEREF_TO_ID
// NOTE: 当release到MAIPU时，使用第一个定义
#define CFTYPEREF_TO_ID(x) ((__bridge_transfer id)(x))
//#define CFTYPEREF_TO_ID(x) NSMakeCollectable(x)

#undef ID_TO_CFTYPEREF
#define ID_TO_CFTYPEREF(x) (((x) == nil) ? NULL : objc_unretainedPointer(x))

#undef SQL_ENTER_MUTEX
#define SQL_ENTER_MUTEX(db) sqlite3_mutex_enter(sqlite3_db_mutex(db))

#undef SQL_EXIT_MUTEX
#define SQL_EXIT_MUTEX(db) sqlite3_mutex_leave(sqlite3_db_mutex(db))

#endif /* __UCA_CONFIG_H__ */
