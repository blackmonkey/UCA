/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

@implementation NSString(Utils)

+ (int)getDateIntervalSince1970:(NSDate *)datetime {
    return [datetime timeIntervalSince1970] / 86400;
}

+ (BOOL)isToday:(NSDate *)datetime {
    int today = [NSString getDateIntervalSince1970:[NSDate date]];
    int dt = [NSString getDateIntervalSince1970:datetime];
    return dt == today;
}

+ (BOOL)isYesterday:(NSDate *)datetime {
    int yesterday = [NSString getDateIntervalSince1970:[NSDate date]] - 1;
    int dt = [NSString getDateIntervalSince1970:datetime];
    return dt == yesterday;
}

+ (NSString *)getDate:(NSDate *)datetime {
    static NSDateFormatter *sDateFormatter = nil;
    if (!sDateFormatter) {
        sDateFormatter = [[NSDateFormatter alloc] init];
        [sDateFormatter setDateFormat:@"yyyy-MM-dd"];
    }

    if ([NSString isToday:datetime]) {
        return I18nString(@"今天");
    } else if ([NSString isYesterday:datetime]) {
        return I18nString(@"昨天");
    }
    return [sDateFormatter stringFromDate:datetime];
}

+ (NSString *)getTime:(NSDate *)datetime {
    static NSDateFormatter *sTimeFormatter = nil;
    if (!sTimeFormatter) {
        sTimeFormatter = [[NSDateFormatter alloc] init];
        [sTimeFormatter setDateFormat:@"HH:mm"];
    }
    return [sTimeFormatter stringFromDate:datetime];
}

+ (NSString *)getDateTime:(NSDate *)datetime {
    NSString *dateStr = [NSString getDate:datetime];
    NSString *timeStr = [NSString getTime:datetime];
    return [[dateStr stringByAppendingString:@" "] stringByAppendingString:timeStr];
}

+ (NSString *)getDuration:(NSTimeInterval)duration {
    static NSDateFormatter* sDurationFormatter = nil;
    if (!sDurationFormatter) {
        sDurationFormatter = [[NSDateFormatter alloc] init];
        [sDurationFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [sDurationFormatter setDateFormat:@"HH:mm:ss"];
    }

    NSDate *dt = [NSDate dateWithTimeIntervalSinceReferenceDate:duration];
    return [sDurationFormatter stringFromDate:dt];
}

+ (BOOL)isNullOrEmpty:(NSString *)string {
    return string == nil || string == (id)[NSNull null] || [string isEqualToString:@""];
}

+ (NSString *)stringOfUTF8String:(const char *)cstring {
    if (cstring == NULL) {
        return nil;
    }
    return [NSString stringWithUTF8String:(const char *)cstring];
}

+ (NSString *)stringWithIp:(NSUInteger)ip {
    // return big endian ip text expression
    return [NSString stringWithFormat:@"%d.%d.%d.%d", (ip & 0xFF000000) >> 24,
            (ip & 0xFF0000) >> 16,
            (ip & 0xFF00) >> 8,
            (ip & 0xFF)];
}

+ (NSUInteger)ipWithString:(NSString *)ipStr {
    if (![NSString isValidIp:ipStr]) {
        return 0;
    }

    NSArray *segs = [ipStr componentsSeparatedByString:@"."];
    NSUInteger seg1 = [((NSString *)[segs objectAtIndex:0]) integerValue];
    NSUInteger seg2 = [((NSString *)[segs objectAtIndex:1]) integerValue];
    NSUInteger seg3 = [((NSString *)[segs objectAtIndex:2]) integerValue];
    NSUInteger seg4 = [((NSString *)[segs objectAtIndex:3]) integerValue];

    // return big endian ip integer value
    return (seg1 << 24) | (seg2 << 16) | (seg3 << 8) | (seg4);
}

+ (BOOL)isValidIp:(NSString *)ipStr {
    if ([ipStr length] < 7 || [ipStr length] > 15) {
        return NO;
    }

    NSArray *segs = [ipStr componentsSeparatedByString:@"."];
    if ([segs count] != 4) {
        return NO;
    }

    NSInteger segValue = [((NSString *)[segs objectAtIndex:0]) integerValue];
    if (segValue < 1 || segValue > 255) {
        return NO;
    }

    for (NSInteger i = 1; i < [segs count]; i++) {
        segValue = [((NSString *)[segs objectAtIndex:0]) integerValue];
        if (segValue < 0 || segValue > 255) {
            return NO;
        }
    }

    return YES;
}

- (NSString *)replaceEmoteCodeToIcon {
    NSDictionary *emotes = [UcaAppDelegate sharedInstance].configService.emotes;
    NSRange r;
    NSString *s = [self copy];
    NSString *code, *iconName, *imgCode;
    NSArray *iconNames;

    while ((r = [s rangeOfString:@"/\\[[^]]+\\]" options:NSRegularExpressionSearch]).location != NSNotFound) {
        code = [s substringWithRange:r];
        iconNames = [emotes allKeysForObject:code];
        if (iconNames.count == 0) {
            continue;
        }
        iconName = [iconNames objectAtIndex:0];
        imgCode = [NSString stringWithFormat:@"<img src='emoticons/%@'>", iconName];
        s = [s stringByReplacingCharactersInRange:r withString:imgCode];
    }

    return s;
}

- (NSString *)plainText {
    NSString *s = [self copy];
    return [s stringByReplacingOccurrencesOfString:@"<[^>]+>"
                                        withString:@""
                                           options:NSRegularExpressionSearch
                                             range:NSMakeRange(0, s.length)];
}

- (NSRange)htmlBodyRange {
    NSUInteger start = 0;
    NSUInteger end = [self length];

    NSRange r = [self rangeOfString:@"<body" options:NSCaseInsensitiveSearch];
    if (r.location != NSNotFound) {
        start = r.location + r.length;
        r = [self rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(start, end - start)];
        if (r.location != NSNotFound) {
            start = r.location + r.length;
        } else {
            return NSMakeRange(NSNotFound, 0);
        }
    }

    r = [self rangeOfString:@"</body>" options:NSCaseInsensitiveSearch];
    if (r.location != NSNotFound) {
        end = r.location;
    }

    return NSMakeRange(start, end - start);
}

- (NSString *)truncatedHtmlOfOutIm:(BOOL)isOutIm {
    NSRange bodyRange = [self htmlBodyRange];

    NSMutableString *res = [[NSMutableString alloc] initWithFormat:@"<html><style>IMG {max-width:150;}</style>"
                            "<body>"
                            "<table id='%@' border=0 cellspacing=0 cellpadding=0>"
                            "<tr><td style='color:white;font:15pt Helvetica;padding-%@:10px'>",
                            IM_WRAPPER_ID, (isOutIm ? @"right" : @"left")];

    /**
     * 将原HTML按最大长度截断，并在每一个TextNode的字符后插入一个zero width space（&#8203;），以便
     * HTML能在每个字符边缘换行。
     */
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"(<[^>]+>)|(&[a-zA-Z0-9#]+;)"
                                                                        options:NSRegularExpressionCaseInsensitive
                                                                          error:nil];
    NSArray *matches = [re matchesInString:self options:0 range:bodyRange];
    NSTextCheckingResult *match = nil;
    NSRange r;
    NSUInteger lastPos = bodyRange.location;
    NSUInteger len = 0;
    NSUInteger i, j;
    NSUInteger maxLen = [UcaAppDelegate sharedInstance].configService.maxShowImLength;
    NSString *subStr = nil;
    unichar c;
    BOOL truncated = NO;

    for (i = 0; i < [matches count] && len < maxLen; i++) {
        match = [matches objectAtIndex:i];
        r = [match range];
        if (r.location == NSNotFound) {
            continue;
        }

        subStr = [self substringWithRange:NSMakeRange(lastPos, r.location - lastPos)];
        for (j = 0; j < [subStr length] && len < maxLen; j++) {
            c = [subStr characterAtIndex:j];

            if (c > 255) {
                len += 2; // 双字节字符占两个单字节字符的宽度。
            } else {
                len++;
            }

            if (c == '\n' || c == '\r' || c == '\t' || c == '\v' || c == ' ') {
                [res appendFormat:@"%C", c];
            } else {
                [res appendFormat:@"%C&#8203;", c];
            }
        }
        truncated = j < [subStr length];
        [res appendString:[self substringWithRange:r]];
        lastPos = r.location + r.length;
    }

    if (!truncated) {
        NSUInteger remain = bodyRange.location + bodyRange.length - lastPos;
        if (remain > 0) {
            if (len >= maxLen) {
                [res appendString:@" &hellip;"];
            } else {
                subStr = [self substringWithRange:NSMakeRange(lastPos, MIN(maxLen - len, remain))];
                for (i = 0; i < [subStr length]; i++) {
                    c = [subStr characterAtIndex:i];
                    if (c == '\n' || c == '\r' || c == '\t' || c == '\v' || c == ' ') {
                        [res appendFormat:@"%C", c];
                    } else {
                        [res appendFormat:@"%C&#8203;", c];
                    }
                }
                if (remain > maxLen - len) {
                    [res appendString:@" &hellip;"];
                }
            }
        }
    } else {
        [res appendString:@" &hellip;"];
    }

    [res appendString:@"</td></tr></table></body></html>"];

    return res;
}

- (NSString *)wrappedHtml {
    NSMutableString *res = [[NSMutableString alloc] initWithString:@"<html><style>BODY, TD {color:white;font:15pt Helvetica;}</style><body>"];
    NSRange r = [self htmlBodyRange];
    if (r.location != NSNotFound) {
        [res appendString:[self substringWithRange:r]];
    }
    [res appendString:@"</body></html>"];
    return res;
}

- (NSString *)replaceImgSrc:(NSString *)prefix {
    NSRange r;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"<img +jt=['\"]?true['\"]? +src=['\"]?+([^'\"]+)['\"]?+"
                                                                        options:NSRegularExpressionCaseInsensitive
                                                                          error:nil];
    NSArray *matches = [re matchesInString:self options:0 range:NSMakeRange(0, [self length])];

    NSUInteger lastPos = 0;
    NSMutableString *res = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < [matches count]; i++) {
        NSTextCheckingResult *match = [matches objectAtIndex:i];
        if ([match numberOfRanges] < 1) {
            continue;
        }

        r = [match rangeAtIndex:1];
        NSString *src = [self substringWithRange:r];
        NSString *imgName = [[src componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]] lastObject];
        imgName = [prefix stringByAppendingString:imgName];

        [res appendString:[self substringWithRange:NSMakeRange(lastPos, r.location - lastPos)]];
        [res appendString:imgName];
        lastPos = r.location + r.length;
    }

    [res appendString:[self substringWithRange:NSMakeRange(lastPos, [self length] - lastPos)]];

    return res;
}

- (NSString *)initial {
    if (self.length == 0) {
        return nil;
    }
    NSString *initialChr = [self substringToIndex:1];
#ifdef UCA_TEST_TARGET
    NSString *path = [[NSBundle mainBundle] pathForResource:@"initialOfCnChrs" ofType:@"plist"];
    NSDictionary *initialOfCnChrs = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSString *res = [initialOfCnChrs objectForKey:initialChr];
#else
    NSString *res = [[UcaAppDelegate sharedInstance].configService getInitialOfCnChr:initialChr];
#endif
    if ([NSString isNullOrEmpty:res]) {
        return initialChr;
    }
    return res;
}

- (BOOL)containsChinese {
    /**
     * \u4E00-\u9FFF只是常用的中文字符范围，并不是全部的，不过一般也够用了。
     */
    NSRange r = [self rangeOfString:@"[\\x{4E00}-\\x{9FFF}]" options:NSRegularExpressionSearch];
    return (r.location != NSNotFound);
}

- (BOOL)containsSubstring:(NSString *)substr {
    NSRange r = [self rangeOfString:substr];
    return (r.location != NSNotFound);
}

- (NSString *)strimmedSipPhone {
    NSString *res = [self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    if ([res hasPrefix:@"sip:"]) {
        res = [res substringFromIndex:4];
    }
    return [res stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
}

@end
