/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <SenTestingKit/SenTestingKit.h>

@interface XmlUtilsTests : SenTestCase

- (void)testInitPrivilege;
- (void)testInitAccount;
- (void)testBuildUserInfoWithAccount;
- (void)testFetchContactsFromXml;
- (void)testBuildManageFriendInfo;
- (void)testBuildManagePrivateInfo;
- (void)testParseMultiPresenceNotification;

@end
