/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

/**
 * NSString(Utils)提供字符串相关的工具函数。
 */

#define IM_WRAPPER_ID @"IM_WRAPPER"

@interface NSString(Utils)

/*****************************************************************************
 * 日期相关的工具函数
 *****************************************************************************/

/**
 * 获取指定日期的文字描述。
 * @param datetime 指定的日期
 */
+ (NSString *)getDate:(NSDate *)datetime;

/**
 * 获取指定时间的文字描述。
 * @param datetime 指定的时间
 */
+ (NSString *)getTime:(NSDate *)datetime;

/**
 * 获取指定日期时间的文字描述。
 * @param datetime 指定的日期时间
 */
+ (NSString *)getDateTime:(NSDate *)datetime;

/**
 * 获取指定时长的文字描述。
 * @param datetime 指定的时长
 */
+ (NSString *)getDuration:(NSTimeInterval)duration;

/*****************************************************************************
 * 字符串相关的工具函数
 *****************************************************************************/

/**
 * 判断指定字符串是否为空。
 * @param string 指定的字符串
 * @return 如果指定字符串为""或者nil，则返回YES，否则返回NO。
 */
+ (BOOL)isNullOrEmpty:(NSString *)string;

/**
 * 将指定UTF8编码的C字符串转换成NSString实例。
 * @param cstring 指定UTF8编码的C字符串
 * @return 如果cstring不为NULL，则返回转换后的NSString实例；如果cstring为NULL，则返回nil。
 */
+ (NSString *)stringOfUTF8String:(const char *)cstring;

/*****************************************************************************
 * IP相关的工具函数
 *****************************************************************************/

/**
 * 将指定的IP地址转换成文字表述。
 * @param ip 指定的IP地址，大端表述的整数。
 * @return IP地址的文字表述。
 */
+ (NSString *)stringWithIp:(NSUInteger)ip;

/**
 * 将指定的IP地址文字表述换成相应的大端整数。
 * @param ipStr 指定的IP地址文字表述。
 * @return IP地址的大端整数表述。
 */
+ (NSUInteger)ipWithString:(NSString *)ipStr;

/**
 * 检测指定的IP地址是否有效。
 * @param ipStr 指定的IP地址文字表述。
 * @return IP地址的大端整数表述。
 */
+ (BOOL)isValidIp:(NSString *)ipStr;

/*****************************************************************************
 * IM消息相关的工具函数
 *****************************************************************************/

/**
 * 将UCA表情编码转换为表情图片。
 */
- (NSString *)replaceEmoteCodeToIcon;

/**
 * 提取Maipu VoIP的IM消息中的纯文本。
 */
- (NSString *)plainText;

/**
 * 按MAX_LENGTH_SHOWN_IM截取HTML，如果HTML超长，则在其末尾加“...”。
 */
- (NSString *)truncatedHtmlOfOutIm:(BOOL)isOutIm;

/**
 * 按内置样式wrap HTML。
 */
- (NSString *)wrappedHtml;

/**
 * 将HTML中所有IMG标签的src属性更改为本地图片地址。
 * @param prefix 要加在src前的前缀。
 */
- (NSString *)replaceImgSrc:(NSString *)prefix;

/**
 * 获取字符串的首字母。
 * @return 如果首字符是汉字，则返回其拼音首字母；否则返回首字符。
 */
- (NSString *)initial;

/**
 * 判断字符串中是否含有中文字符。
 * @return 判断结果。
 */
- (BOOL)containsChinese;

/**
 * 判断字符串中是否含有指定子字符串。
 * @return 判断结果。
 */
- (BOOL)containsSubstring:(NSString *)substr;

/**
 * 去除可能的“sip:”开头，及sipPhone两头的单/双引号。
 * @return 去除结果。
 */
- (NSString *)strimmedSipPhone;

@end
