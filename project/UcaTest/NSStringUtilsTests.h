/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <SenTestingKit/SenTestingKit.h>

@interface NSStringUtilsTests : SenTestCase {
    NSDate *today;
    NSDate *yesterday;
    NSDate *date1970;
    NSString *todayTime;
    NSString *dateText;
}

- (void)testGetDate;
- (void)testGetTime;
- (void)testGetDateTime;
- (void)testGetDuration;
- (void)testIsNullOrEmpty;
- (void)testConvertUtf8String;
- (void)testConvertCFString;
- (void)testIpToString;
- (void)testStringToIp;
- (void)testCheckIp;
- (void)testConvertEmoticons;
- (void)testConvertEmojiAlerts;
- (void)testFetchPlainText;

@end
