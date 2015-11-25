/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "NSStringUtilsTests.h"
#import "NSString+Utils.h"
#import "UcaConfig.h"

@implementation NSStringUtilsTests

- (void)setUp {
    [super setUp];

    // Set-up code here.
    today = [NSDate date];
    yesterday = [NSDate dateWithTimeInterval:-86400 sinceDate:today];
    date1970 = [NSDate dateWithTimeIntervalSince1970:0];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [formatter setDateFormat:@"HH:mm"];
    todayTime = [formatter stringFromDate:today];
}

- (void)tearDown {
    // Tear-down code here.

    [super tearDown];
}

- (void)testGetDate {
    dateText = [NSString getDate:today];
    STAssertEqualObjects(dateText, @"今天", nil);

    dateText = [NSString getDate:yesterday];
    STAssertEqualObjects(dateText, @"昨天", nil);

    dateText = [NSString getDate:date1970];
    STAssertEqualObjects(dateText, @"1970-01-01", nil);
}

- (void)testGetTime {
    dateText = [NSString getTime:date1970];
    STAssertEqualObjects(dateText, @"00:00", nil);

    NSDate *date = [NSDate dateWithTimeInterval:-1 sinceDate:date1970];
    dateText = [NSString getTime:date];
    STAssertEqualObjects(dateText, @"07:59", nil);

    date = [NSDate dateWithTimeInterval:120 sinceDate:date1970];
    dateText = [NSString getTime:date];
    STAssertEqualObjects(dateText, @"08:02", nil);

    date = [NSDate dateWithTimeInterval:86399 sinceDate:date1970];
    dateText = [NSString getTime:date];
    STAssertEqualObjects(dateText, @"07:59", nil);

    date = [NSDate dateWithTimeInterval:86400 sinceDate:date1970];
    dateText = [NSString getTime:date];
    STAssertEqualObjects(dateText, @"08:00", nil);
}

- (void)testGetDateTime {
    dateText = [NSString getDateTime:today];
    STAssertEqualObjects(dateText, ([NSString stringWithFormat:@"今天 %@", todayTime]), nil);

    dateText = [NSString getDateTime:yesterday];
    STAssertEqualObjects(dateText, ([NSString stringWithFormat:@"昨天 %@", todayTime]), nil);

    dateText = [NSString getDateTime:date1970];
    STAssertEqualObjects(dateText, @"1970-01-01 08:00", nil);
}

- (void)testGetDuration {
    dateText = [NSString getDuration:-1];
    STAssertEqualObjects(dateText, @"23:59:59", nil);

    dateText = [NSString getDuration:0];
    STAssertEqualObjects(dateText, @"00:00:00", nil);

    dateText = [NSString getDuration:12345];
    STAssertEqualObjects(dateText, @"03:25:45", nil);

    dateText = [NSString getDuration:86399];
    STAssertEqualObjects(dateText, @"23:59:59", nil);

    dateText = [NSString getDuration:86400];
    STAssertEqualObjects(dateText, @"00:00:00", nil);

    dateText = [NSString getDuration:86401];
    STAssertEqualObjects(dateText, @"00:00:01", nil);
}

- (void)testIsNullOrEmpty {
    STAssertTrue([NSString isNullOrEmpty:nil], nil);
    STAssertTrue([NSString isNullOrEmpty:@""], nil);
    STAssertFalse([NSString isNullOrEmpty:@" "], nil);
    STAssertFalse([NSString isNullOrEmpty:@"hello world"], nil);
}

- (void)testConvertUtf8String {
    STAssertEqualObjects([NSString stringOfUTF8String:"hello world"], @"hello world", nil);
    STAssertEqualObjects([NSString stringOfUTF8String:"\xE4\xBD\xA0\xE5\xA5\xBD\xEF\xBC\x81"], @"你好！", nil);
}

- (void)testIpToString {
    STAssertEqualObjects([NSString stringWithIp:0], @"0.0.0.0", nil);
    STAssertEqualObjects([NSString stringWithIp:-1], @"255.255.255.255", nil);
    STAssertEqualObjects([NSString stringWithIp:0x80808080], @"128.128.128.128", nil);
}

- (void)testStringToIp {
    STAssertEquals([NSString ipWithString:@"0.0.0.0"], 0, nil);
    STAssertEquals([NSString ipWithString:@"255.255.255.255"], 0xFFFFFFFF, nil);
    STAssertEquals([NSString ipWithString:@"128.128.128.128"], 0x80808080, nil);
}

- (void)testCheckIp {
    STAssertFalse([NSString isValidIp:@"0.0.0."], nil);
    STAssertFalse([NSString isValidIp:@"0.0.0.0.0"], nil);
    STAssertFalse([NSString isValidIp:@"0.0.0.0"], nil);
    STAssertFalse([NSString isValidIp:@"256.0.0.0"], nil);
    STAssertFalse([NSString isValidIp:@"0.256.0.0"], nil);
    STAssertFalse([NSString isValidIp:@"0.0.256.0"], nil);
    STAssertFalse([NSString isValidIp:@"0.0.0.256"], nil);
    STAssertFalse([NSString isValidIp:@"256.256.256.256"], nil);
    STAssertTrue([NSString isValidIp:@"1.0.0.0"], nil);
    STAssertTrue([NSString isValidIp:@"255.255.255.255"], nil);
}

- (void)testConvertEmoticons {
    NSString *testText = @"/[微笑]/[撇嘴]";
    STAssertEqualObjects([testText replaceEmoteCodeToIcon], @"<img src='emoticons/0.gif'><img src='emoticons/1.gif'>", nil);
}

- (void)testFetchPlainText {
    NSString *testText = @"";
    STAssertEqualObjects([testText plainText], @"", nil);

    testText = @"<body><p><span>hello</span></p><p> world</p></body>";
    STAssertEqualObjects([testText plainText], @"hello\n world\n", nil);
}

@end
