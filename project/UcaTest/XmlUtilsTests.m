/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "XmlUtilsTests.h"
#import "XmlUtils.h"
#import "ucalib.h"

@implementation XmlUtilsTests

- (void)testInitPrivilege {
    STFail(@"not implemented");
}

- (void)testInitAccount {
    STFail(@"not implemented");
}

- (void)testBuildUserInfoWithAccount {
    STFail(@"not implemented");
}

- (void)testFetchContactsFromXml {
    STFail(@"not implemented");
}

- (void)testBuildManageFriendInfo {
    STFail(@"not implemented");
}

- (void)testBuildManagePrivateInfo {
    STFail(@"not implemented");
}

- (void)testParseMultiPresenceNotification {
    const char *xmlData = "<list uri=\"sip:list-5004752@sipserver.maipu.com\" version=\"7501002\" fullState=\"true\">"
                              "<users domainuri=\"sipserver.maipu.com\" usercount=\"15\">"
                                  "<user userid=\"5002717\" state=\"active\">"
                                      "<presence basic=\"open\" im=\"Online\"/>"
                                      "<camera basic=\"close\"/>"
                                      "<mailbox basic=\"open\"/>"
                                  "</user>"
                                  "<user userid=\"5003166\" state=\"terminate\">"
                                      "<mailbox basic=\"open\"/>"
                                  "</user>"
                                  "<user userid=\"5003878\" state=\"active\">"
                                      "<presence basic=\"open\" im=\"Away\"/>"
                                      "<camera basic=\"close\"/>"
                                      "<mailbox basic=\"open\"/>"
                                  "</user>"
                              "</users>"
                          "</list>";
    NSMutableArray *notifications = [XmlUtils parseMultiPresenceNotification:xmlData];
    STAssertEquals(notifications.count, 3, nil);

    ContactPresence *note;

    note = [notifications objectAtIndex:0];
    STAssertEquals(note.userId, 5002717, nil);
    STAssertEquals(note.state, UCALIB_PRESENTATIONSTATE_ONLINE, nil);
    STAssertEquals(note.cameraOn, NO, nil);

    note = [notifications objectAtIndex:1];
    STAssertEquals(note.userId, 5003166, nil);
    STAssertEquals(note.state, UCALIB_PRESENTATIONSTATE_OFFLINE, nil);
    STAssertEquals(note.cameraOn, NO, nil);

    note = [notifications objectAtIndex:2];
    STAssertEquals(note.userId, 5003878, nil);
    STAssertEquals(note.state, UCALIB_PRESENTATIONSTATE_AWAY, nil);
    STAssertEquals(note.cameraOn, NO, nil);
}

@end
