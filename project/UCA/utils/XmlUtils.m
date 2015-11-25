/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <libxml/tree.h>

#undef TAG
#define TAG @"XmlUtils"

#define XML_HEAD @"<?xml version='1.0' encoding='UTF-8'?>"

static char encodingTable[64] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

@implementation XmlUtils

+ (NSString *)xmlTypeName:(int)type {
    switch (type) {
    case XML_ELEMENT_NODE       : return @"XML_ELEMENT_NODE";
    case XML_ATTRIBUTE_NODE     : return @"XML_ATTRIBUTE_NODE";
    case XML_TEXT_NODE          : return @"XML_TEXT_NODE";
    case XML_CDATA_SECTION_NODE : return @"XML_CDATA_SECTION_NODE";
    case XML_ENTITY_REF_NODE    : return @"XML_ENTITY_REF_NODE";
    case XML_ENTITY_NODE        : return @"XML_ENTITY_NODE";
    case XML_PI_NODE            : return @"XML_PI_NODE";
    case XML_COMMENT_NODE       : return @"XML_COMMENT_NODE";
    case XML_DOCUMENT_NODE      : return @"XML_DOCUMENT_NODE";
    case XML_DOCUMENT_TYPE_NODE : return @"XML_DOCUMENT_TYPE_NODE";
    case XML_DOCUMENT_FRAG_NODE : return @"XML_DOCUMENT_FRAG_NODE";
    case XML_NOTATION_NODE      : return @"XML_NOTATION_NODE";
    case XML_HTML_DOCUMENT_NODE : return @"XML_HTML_DOCUMENT_NODE";
    case XML_DTD_NODE           : return @"XML_DTD_NODE";
    case XML_ELEMENT_DECL       : return @"XML_ELEMENT_DECL";
    case XML_ATTRIBUTE_DECL     : return @"XML_ATTRIBUTE_DECL";
    case XML_ENTITY_DECL        : return @"XML_ENTITY_DECL";
    case XML_NAMESPACE_DECL     : return @"XML_NAMESPACE_DECL";
    case XML_XINCLUDE_START     : return @"XML_XINCLUDE_START";
    case XML_XINCLUDE_END       : return @"XML_XINCLUDE_END";
#ifdef LIBXML_DOCB_ENABLED
    case XML_DOCB_DOCUMENT_NODE : return @"XML_DOCB_DOCUMENT_NODE";
#endif
    }
    return @"";
}

+ (void)dumpXmlRoot:(xmlNodePtr)pRoot indent:(NSString *)indent {
    NSMutableString *log = [[NSMutableString alloc] init];

    [log appendFormat:@"%@--------------------\n", indent];
    [log appendFormat:@"%@node->name = %@\n", indent, [NSString stringOfUTF8String:(const char *)pRoot->name]];
    [log appendFormat:@"%@node->type = %@\n", indent, [XmlUtils xmlTypeName:pRoot->type]];
    [log appendFormat:@"%@node->content = %@\n", indent, [NSString stringOfUTF8String:(const char *)pRoot->content]];
    NSLog(@"%@", log);

    indent = [@"    " stringByAppendingString:indent];
    for (xmlNodePtr pSubRoot = pRoot->children; pSubRoot; pSubRoot = pSubRoot->next) {
        [XmlUtils dumpXmlRoot:pSubRoot indent:indent];
    }
}

+ (NSString *)encodePhoto:(UIImage *)photo {
#ifdef ENABLE_DECODE_ENCODE_AVATAR
    if (!photo) {
        return @"";
    }

    NSData *data = UIImagePNGRepresentation(photo);
    const unsigned char *bytes = data.bytes;
    NSMutableString *result = [NSMutableString stringWithCapacity:data.length];
    unsigned long ixtext = 0;
    unsigned long lentext = data.length;
    long ctremaining = 0;
    unsigned char inbuf[3], outbuf[4];
    unsigned short i = 0;
    unsigned short charsonline = 0, ctcopy = 0;
    unsigned long ix = 0;

    while (YES) {
        ctremaining = lentext - ixtext;
        if (ctremaining <= 0) break;

        for (i = 0; i < 3; i++) {
            ix = ixtext + i;
            inbuf[i] = (ix < lentext) ? bytes[ix] : 0;
        }

        outbuf[0] = (inbuf[0] & 0xFC) >> 2;
        outbuf[1] = ((inbuf[0] & 0x03) << 4) | ((inbuf[1] & 0xF0) >> 4);
        outbuf[2] = ((inbuf[1] & 0x0F) << 2) | ((inbuf[2] & 0xC0) >> 6);
        outbuf[3] = inbuf[2] & 0x3F;
        ctcopy = 4;

        switch (ctremaining) {
        case 1:
            ctcopy = 2;
            break;
        case 2:
            ctcopy = 3;
            break;
        }

        for (i = 0; i < ctcopy; i++)
            [result appendFormat:@"%c", encodingTable[outbuf[i]]];

        for (i = ctcopy; i < 4; i++)
            [result appendString:@"="];

        ixtext += 3;
        charsonline += 4;
    }

    return result;
#else
    return @"";
#endif
}

+ (UIImage *)decodePhoto:(NSString *)photoCode {
#ifdef ENABLE_DECODE_ENCODE_AVATAR
    if (!photoCode) {
        return nil;
    }

    NSMutableData *mutableData = nil;
    unsigned long ixtext = 0;
    unsigned long lentext = 0;
    unsigned char ch = 0;
    unsigned char inbuf[4] = {0, 0, 0, 0}, outbuf[3] = {0, 0, 0};
    short i = 0, ixinbuf = 0;
    BOOL flignore = NO;
    BOOL flendtext = NO;
    NSData *base64Data = nil;
    const unsigned char *base64Bytes = nil;

    // Convert the string to ASCII data.
    base64Data = [photoCode dataUsingEncoding:NSASCIIStringEncoding];
    base64Bytes = [base64Data bytes];
    mutableData = [NSMutableData dataWithCapacity:base64Data.length];
    lentext = base64Data.length;

    while (YES) {
        if (ixtext >= lentext) break;
        ch = base64Bytes[ixtext++];
        flignore = NO;

        if ((ch >= 'A') && (ch <= 'Z')) ch = ch - 'A';
        else if((ch >= 'a') && (ch <= 'z')) ch = ch - 'a' + 26;
        else if((ch >= '0') && (ch <= '9')) ch = ch - '0' + 52;
        else if(ch == '+') ch = 62;
        else if(ch == '=') flendtext = YES;
        else if(ch == '/') ch = 63;
        else flignore = YES;

        if (!flignore) {
            short ctcharsinbuf = 3;
            BOOL flbreak = NO;

            if (flendtext) {
                if(!ixinbuf) break;
                if((ixinbuf == 1) || (ixinbuf == 2)) ctcharsinbuf = 1;
                else ctcharsinbuf = 2;
                ixinbuf = 3;
                flbreak = YES;
            }

            inbuf[ixinbuf++] = ch;

            if (ixinbuf == 4) {
                ixinbuf = 0;
                outbuf[0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
                outbuf[1] = ((inbuf[1] & 0x0F) << 4) | ((inbuf[2] & 0x3C) >> 2);
                outbuf[2] = ((inbuf[2] & 0x03) << 6) | (inbuf[3] & 0x3F);

                for (i = 0; i < ctcharsinbuf; i++)
                    [mutableData appendBytes:&outbuf[i] length:1];
            }

            if (flbreak) break;
        }
    }

    return [UIImage imageWithData:mutableData];
#else
    return nil;
#endif
}

/**
 * 判断指定XML node是否符合以下形式：
 * <tag>foo</tag>
 */
+ (BOOL)isValidPropNode:(xmlNodePtr)pNode {
    return pNode && (pNode->type == XML_ELEMENT_NODE)
            && pNode->children && (pNode->children->type == XML_TEXT_NODE)
            && pNode->children->content;
}

+ (void)initPrivilege:(Privilege *)privilege withXml:(const char *)xmlData {
    if (xmlData == NULL) {
        return;
    }
    xmlDocPtr pXmlDoc = xmlParseDoc((const xmlChar *)xmlData);
    if (pXmlDoc == NULL) {
        return;
    }
    xmlNodePtr pRootNode = xmlDocGetRootElement(pXmlDoc); // permissions node
    if (pRootNode == NULL) {
        xmlFreeDoc(pXmlDoc);
        return;
    }

//    UcaLog(TAG, @"[initPrivilege]");
//    [XmlUtils dumpXmlRoot:pRootNode indent:@""];

    xmlNodePtr pNode = NULL;
    xmlNodePtr pSubNode = NULL;
    NSString *nodeName = nil;
    NSString *permName = nil;
    NSString *permVal = nil;
    NSInteger permIntVal = 0;
    BOOL permBoolVal = NO;

    for (pNode = pRootNode->children; pNode; pNode = pNode->next) {
        nodeName = [NSString stringOfUTF8String:(const char*)pNode->name];
        if (pNode->type != XML_ELEMENT_NODE || ![nodeName isEqualToString:@"setting"]) {
            continue;
        }

        /* setting node */
        permName = nil;
        permVal = nil;
        permIntVal = 0;
        permBoolVal = NO;
        for (pSubNode = pNode->children; pSubNode; pSubNode = pSubNode->next) {
            if (![XmlUtils isValidPropNode:pSubNode]) {
                continue;
            }

            /* valid property node of setting node */
            nodeName = [NSString stringOfUTF8String:(const char*)pSubNode->name];
            if ([nodeName isEqualToString:@"name"]) {
                permName = [NSString stringOfUTF8String:(const char*)pSubNode->children->content];
            } else if ([nodeName isEqualToString:@"value"]) {
                permVal = [NSString stringOfUTF8String:(const char*)pSubNode->children->content];
                permIntVal = [permVal integerValue];
                permBoolVal = [permVal isEqualToString:@"ENABLE"];
            }
        }

        UcaLog(TAG, @"initPrivilege() get %@ = %@", permName, permVal);

        if ([permName isEqualToString:@"sendfilesize"]) {
            if (permIntVal > 0) {
                privilege.sendFileSize = permIntVal;
            }
        } else if ([permName isEqualToString:@"sendfilespeed"]) {
            if (permIntVal > 0) {
                privilege.sendFileSpeed = permIntVal;
            }
        } else if ([permName isEqualToString:@"superadmin"]) {
            privilege.superAdmin = permBoolVal;
        } else if ([permName isEqualToString:@"tui-change-pin"]) {
            privilege.tuiChangePin = permBoolVal;
        } else if ([permName isEqualToString:@"AutoAttendant"]) {
            privilege.autoAttendant = permBoolVal;
        } else if ([permName isEqualToString:@"Voicemail"]) {
            privilege.voicemail = permBoolVal;
        } else if ([permName isEqualToString:@"ForwardCallsExternal"]) {
            privilege.forwardCallsExternal = permBoolVal;
        } else if ([permName isEqualToString:@"RecordSystemPrompts"]) {
            privilege.recordSystemPrompts = permBoolVal;
        } else if ([permName isEqualToString:@"InstantMessage"]) {
            privilege.instantMessage = permBoolVal;
        } else if ([permName isEqualToString:@"FileTransfers"]) {
            privilege.fileTransfers = permBoolVal;
        } else if ([permName isEqualToString:@"MeetingCreate"]) {
            privilege.meetingCreate = permBoolVal;
        } else if ([permName isEqualToString:@"CooperateWith"]) {
            privilege.cooperateWith = permBoolVal;
        } else if ([permName isEqualToString:@"IntrusionBreakdown"]) {
            privilege.intrusionBreakdown = permBoolVal;
        }
    }
    xmlFreeDoc(pXmlDoc);
}

/**
 * 解析指定XML内容，并初始化Person实例。
 * @param person Person实例
 * @param pRootNode XML根节点
 * @return 没有设置的key-value
 */
+ (NSMutableDictionary *)initPerson:(Person *)person withRoot:(xmlNodePtr)pRootNode {
    NSMutableDictionary *remain = [[NSMutableDictionary alloc] init];

    xmlNodePtr pNode = NULL;
    xmlNodePtr pMultiItemNode = NULL;
    xmlNodePtr pNumberSubNode = NULL;
    NSString *nodeName = nil;
    NSString *propName = nil;
    NSString *propVal = nil;
    NSMutableArray *multiVal = nil;

//    UcaLog(TAG, @"[initPerson]");
//    [XmlUtils dumpXmlRoot:pRootNode indent:@""];

    for (pNode = pRootNode->children; pNode; pNode = pNode->next) { // sub nodes of userinfo
        nodeName = [NSString stringOfUTF8String:(const char*)pNode->name];
        if ([XmlUtils isValidPropNode:pNode]) {
            propVal = [NSString stringOfUTF8String:(const char*)pNode->children->content];

            UcaLog(TAG, @"[initPerson] get %@ = %@", nodeName, propVal);

            if ([nodeName isEqualToString:@"userId"]) {
                person.userId = [propVal integerValue];
            } else if ([nodeName isEqualToString:@"userName"]) {
                person.username = propVal;
            } else if ([nodeName isEqualToString:@"pin"]) {
                person.pin = propVal;
            } else if ([nodeName isEqualToString:@"sipPhone"]) {
                person.sipPhone = propVal;
            } else if ([nodeName isEqualToString:@"sipPassword"]) {
                [remain setObject:propVal forKey:nodeName];
            } else if ([nodeName isEqualToString:@"callMode"]) {
                person.callMode = [propVal integerValue];
            } else if ([nodeName isEqualToString:@"status"]) {
                person.presentation = [UcaConstants presentationFromDescription:propVal];
            } else if ([nodeName isEqualToString:@"firstName"]) {
                person.firstname = propVal;
            } else if ([nodeName isEqualToString:@"lastName"]) {
                person.lastname = propVal;
            } else if ([nodeName isEqualToString:@"nickName"]) {
                person.nickname = propVal;
            } else if ([nodeName isEqualToString:@"groupId"]) {
                person.groupId = [propVal integerValue];
            } else if ([nodeName isEqualToString:@"departId"]) {
                person.departId = [propVal integerValue];
            } else if ([nodeName isEqualToString:@"departName"]) {
                person.departName = propVal;
            } else if ([nodeName isEqualToString:@"email"]) {
                person.email = propVal;
            } else if ([nodeName isEqualToString:@"description"]) {
                person.descrip = propVal;
            } else if ([nodeName isEqualToString:@"photo"]) {
                UIImage *pic = [XmlUtils decodePhoto:propVal];
                if (pic) {
                    person.photo = pic;
                }
            } else if ([nodeName isEqualToString:@"sex"]) {
                person.isFemale = [propVal isEqualToString:@"1"];
            } else if ([nodeName isEqualToString:@"position"]) {
                person.position = propVal;
            } else if ([nodeName isEqualToString:@"familyAddr"]) {
                person.familyAddress = propVal;
            } else if ([nodeName isEqualToString:@"companyName"]) {
                person.company = propVal;
            } else if ([nodeName isEqualToString:@"companyAddr"]) {
                person.companyAddress = propVal;
            } else if ([nodeName isEqualToString:@"voiceMailNumber"]) {
                person.voicemail = propVal;
            } else if ([nodeName isEqualToString:@"isShowPrivateInfo"]) {
                person.showPersonalInfo = [propVal isEqualToString:@"true"];
            }
        } else {
            if ([nodeName isEqualToString:@"numbers"]) {
                for (pMultiItemNode = pNode->children; pMultiItemNode; pMultiItemNode = pMultiItemNode->next) { // number node
                    propName = nil;
                    propVal = @"";
                    for (pNumberSubNode = pMultiItemNode->children; pNumberSubNode; pNumberSubNode = pNumberSubNode->next) {
                        nodeName = [NSString stringOfUTF8String:(const char*)pNumberSubNode->name];
                        if ([XmlUtils isValidPropNode:pNumberSubNode]) {
                            if ([nodeName isEqualToString:@"name"]) {
                                propName = [NSString stringOfUTF8String:(const char*)pNumberSubNode->children->content];
                            } else if ([nodeName isEqualToString:@"value"]) {
                                propVal = [NSString stringOfUTF8String:(const char*)pNumberSubNode->children->content];
                            }
                        }
                    }

                    UcaLog(TAG, @"[initPerson] get %@ = %@", propName, propVal);

                    if ([propName isEqualToString:@"mobilePhone1"]) {
                        person.mobilePhone = propVal;
                    } else if ([propName isEqualToString:@"mobilePhone2"]) {
                        person.mobilePhone2 = propVal;
                    } else if ([propName isEqualToString:@"workPhone"]) {
                        person.workPhone = propVal;
                    } else if ([propName isEqualToString:@"familyPhone"]) {
                        person.familyPhone = propVal;
                    } else if ([propName isEqualToString:@"otherPhone"]) {
                        person.otherPhone = propVal;
                    }
                }
            } else if ([nodeName isEqualToString:@"groups"]) {
                multiVal = [NSMutableArray array];
                for (pMultiItemNode = pNode->children; pMultiItemNode; pMultiItemNode = pMultiItemNode->next) {
                    if ([XmlUtils isValidPropNode:pMultiItemNode]) {
                        propVal = [NSString stringOfUTF8String:(const char*)pMultiItemNode->children->content];
                        UcaLog(TAG, @"[initPerson] get groups <- %@", propVal);
                        [multiVal addObject:propVal];
                    }
                }
                person.groups = multiVal;
            } else if ([nodeName isEqualToString:@"aliases"]) {
                multiVal = [NSMutableArray array];
                for (pMultiItemNode = pNode->children; pMultiItemNode; pMultiItemNode = pMultiItemNode->next) {
                    if ([XmlUtils isValidPropNode:pMultiItemNode]) {
                        propVal = [NSString stringOfUTF8String:(const char*)pMultiItemNode->children->content];
                        UcaLog(TAG, @"[initPerson] get aliases <- %@", propVal);
                        [multiVal addObject:propVal];
                    }
                }
                person.aliases = multiVal;
            }
        }
    }

    return remain;
}

+ (void)initAccount:(Account *)account withXml:(const char *)xmlData {
    if (xmlData == NULL) {
        return;
    }
    xmlDocPtr pXmlDoc = xmlParseDoc((const xmlChar *)xmlData);
    if (pXmlDoc == NULL) {
        return;
    }
    xmlNodePtr pRootNode = xmlDocGetRootElement(pXmlDoc); // userInfo node
    if (pRootNode == NULL) {
        xmlFreeDoc(pXmlDoc);
        return;
    }

    UcaLog(TAG, @"[initAccount]account:%@ withXml:%s", account, xmlData);
//    [XmlUtils dumpXmlRoot:pRootNode indent:@""];

    NSMutableDictionary *remain = [XmlUtils initPerson:(Person *)account withRoot:pRootNode];
    NSArray *keys = [remain allKeys];
    for (NSString *key in keys) {
        if ([key isEqualToString:@"sipPassword"]) {
            account.password = [remain objectForKey:key];
        }
    }
    xmlFreeDoc(pXmlDoc);
}

+ (NSString *)buildUserInfoWithAccount:(Account *)account {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendFormat:@"<userInfo>"
                           "<userId>%d</userId>"
                           "<userName>%@</userName>"
                           "<sipPhone>%@</sipPhone>"
                           "<callMode>%d</callMode>"
                           "<firstName>%@</firstName>"
                           "<lastName>%@</lastName>"
                           "<nickName>%@</nickName>"
                           "<groupId>%d</groupId>"
                           "<departId>%d</departId>"
                           "<departName>%@</departName>"
                           "<email>%@</email>"
                           "<description>%@</description>"
                           "<photo>%@</photo>"
                           "<sex>%d</sex>"
                           "<position>%@</position>"
                           "<familyAddr>%@</familyAddr>"
                           "<companyName>%@</companyName>"
                           "<companyAddr>%@</companyAddr>"
                           "<voiceMailNumber>%@</voiceMailNumber>"
                           "<isShowPrivateInfo>%@</isShowPrivateInfo>"
                           "<numbers>"
                               "<number>"
                                   "<name>mobilePhone1</name>"
                                   "<value>%@</value>"
                               "</number>"
                               "<number>"
                                   "<name>mobilePhone2</name>"
                                   "<value>%@</value>"
                               "</number>"
                               "<number>"
                                   "<name>workPhone</name>"
                                   "<value>%@</value>"
                               "</number>"
                               "<number>"
                                   "<name>familyPhone</name>"
                                   "<value>%@</value>"
                               "</number>"
                               "<number>"
                                   "<name>otherPhone</name>"
                                   "<value>%@</value>"
                               "</number>"
                           "</numbers>"
                       "</userInfo>",
                       account.userId, account.username, account.sipPhone, account.callMode,
                       account.firstname, account.lastname, account.nickname,
                       account.groupId, account.departId, account.departName,
                       account.email, account.descrip, [XmlUtils encodePhoto:account.photo],
                       account.isFemale ? 1 : 0, account.position, account.familyAddress,
                       account.company, account.companyAddress, account.voicemail,
                       account.showPersonalInfo ? @"true" : @"false",
                       account.mobilePhone, account.mobilePhone2, account.workPhone,
                       account.familyPhone, account.otherPhone];
    return xml;
}

+ (NSMutableArray *)parseUserinfos:(xmlNodePtr)pRootNode forType:(ContactType)type {
    if (pRootNode == NULL) {
        return nil;
    }

    NSMutableArray *contacts = [NSMutableArray array];
    Contact *contact = nil;

    for (xmlNodePtr pNode = pRootNode->children; pNode; pNode = pNode->next) {
        if (pNode->type != XML_ELEMENT_NODE) {
            continue;
        }

        // userInfo node
        contact = [[Contact alloc] init];
#ifdef UCA_TEST_TARGET
        contact.accountId = TEST_ACCOUNT_ID;
#endif
        contact.contactType = type;
        [XmlUtils initPerson:(Person *)contact withRoot:pNode];
        [contacts addObject:contact];
    }
    return contacts;
}

+ (NSMutableArray *)fetchContactsFromXml:(const char *)xmlData forType:(ContactType)type {
    if (xmlData == NULL) {
        return nil;
    }
    xmlDocPtr pXmlDoc = xmlParseDoc((const xmlChar *)xmlData);
    if (pXmlDoc == NULL) {
        return nil;
    }
    xmlNodePtr pRootNode = xmlDocGetRootElement(pXmlDoc); // userInfos node
    if (pRootNode == NULL) {
        xmlFreeDoc(pXmlDoc);
        return nil;
    }

    UcaLog(TAG, @"[fetchContactsFromXml]xml:%s type:%d", xmlData, type);
//    [XmlUtils dumpXmlRoot:pRootNode indent:@""];

    NSMutableArray *contacts = [XmlUtils parseUserinfos:pRootNode forType:type];
    xmlFreeDoc(pXmlDoc);
    return contacts;
}

+ (NSString *)buildManageFriendXml:(NSArray *)contacts manage:(ManageType)type {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendString:@"<managerFriend>"
                           "<userInfos>"];

    for (Contact *contact in contacts) {
        [xml appendFormat:@"<userInfo>"
                               "<userId>%d</userId>"
                           "</userInfo>", contact.userId];
    }

    [xml appendFormat:@"</userInfos>"
                       "<optType>%d</optType>"
                   "</managerFriend>", type];
    return xml;
}

+ (NSString *)buildAddOrUpdatePrivateXml:(Contact *)contact manage:(ManageType)type {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendString:@"<managerPrivateContact>"
                           "<userInfos>"
                               "<userInfo>"];

    if (type == ManageType_Update) {
        [xml appendFormat:@"<userId>%d</userId>", contact.userId];
    }

    [xml appendFormat:@"<userName>%@</userName>"
                       "<sipPhone>%@</sipPhone>"
                       "<callMode>%d</callMode>"
                       "<firstName>%@</firstName>"
                       "<lastName>%@</lastName>"
                       "<nickName>%@</nickName>"
                       "<groupId>-9999</groupId>"
                       "<departName>%@</departName>"
                       "<email>%@</email>"
                       "<description>%@</description>"
                       "<photo>%@</photo>"
                       "<sex>%d</sex>"
                       "<position>%@</position>"
                       "<familyAddr>%@</familyAddr>"
                       "<companyName>%@</companyName>"
                       "<companyAddr>%@</companyAddr>"
                       "<firstCallNumber>1</firstCallNumber>"
                       "<numbers>"
                           "<number>"
                               "<name>mobilePhone1</name>"
                               "<value>%@</value>"
                           "</number>"
                           "<number>"
                               "<name>mobilePhone2</name>"
                               "<value>%@</value>"
                           "</number>"
                           "<number>"
                               "<name>workPhone</name>"
                               "<value>%@</value>"
                           "</number>"
                           "<number>"
                               "<name>familyPhone</name>"
                               "<value>%@</value>"
                           "</number>"
                           "<number>"
                               "<name>otherPhone</name>"
                               "<value>%@</value>"
                           "</number>"
                       "</numbers>",
                       contact.username, contact.sipPhone, contact.callMode,
                       contact.firstname, contact.lastname, contact.nickname,
                       contact.departName, contact.email, contact.descrip,
                       [XmlUtils encodePhoto:contact.photo], contact.isFemale ? 1 : 0,
                       contact.position, contact.familyAddress,
                       contact.company, contact.companyAddress,
                       contact.mobilePhone, contact.mobilePhone2, contact.workPhone,
                       contact.familyPhone, contact.otherPhone];

    [xml appendString:@"<aliases>"];
    for (NSString *alias in contact.aliases) {
        [xml appendFormat:@"<alias>%@</alias>", alias];
    }
    [xml appendFormat:@"</aliases>"
                   "</userInfo>"
               "</userInfos>"
               "<optType>%d</optType>"
           "</managerPrivateContact>", type];
    return xml;
}

+ (NSString *)buildDeletePrivateXml:(NSArray *)contacts {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendString:@"<managerPrivateContact>"
                           "<userInfos>"];
    for (Contact *contact in contacts) {
        [xml appendFormat:@"<userInfo>"
                               "<userId>%d</userId>"
                           "</userInfo>", contact.userId];
    }
    [xml appendString:@"</userInfos>"
                       "<optType>3</optType>"
                   "</managerPrivateContact>"];
    return xml;
}

+ (NSMutableDictionary *)parseNodeProperties:(xmlNodePtr)pNode {
    if (!pNode) {
        return nil;
    }

    NSMutableDictionary *attrs = [[NSMutableDictionary alloc] init];
    xmlAttrPtr pAttr = NULL;
    NSString *attrName = nil;
    NSString *attrVal = nil;

    for (pAttr = pNode->properties; pAttr; pAttr = pAttr->next) {
        if (pAttr->type != XML_ATTRIBUTE_NODE) {
            continue;
        }
        attrName = [NSString stringOfUTF8String:(const char*)pAttr->name];
        attrVal = [NSString stringOfUTF8String:(const char*)pAttr->children->content];
        [attrs setObject:attrVal forKey:attrName];
    }

    return attrs;
}

+ (NSMutableArray *)parseMultiPresenceNotification:(const char *)xmlData {
    if (xmlData == NULL) {
        return nil;
    }
    xmlDocPtr pXmlDoc = xmlParseDoc((const xmlChar *)xmlData);
    if (pXmlDoc == NULL) {
        return nil;
    }
    xmlNodePtr pRootNode = xmlDocGetRootElement(pXmlDoc); // list node
    if (pRootNode == NULL) {
        xmlFreeDoc(pXmlDoc);
        return nil;
    }

//    UcaLog(TAG, @"[parseMultiPresenceNotification]");
//    [XmlUtils dumpXmlRoot:pRootNode indent:@""];

    pRootNode = pRootNode->children; // users node
    if (pRootNode == NULL) {
        xmlFreeDoc(pXmlDoc);
        return nil;
    }

    NSMutableArray *notifications = [NSMutableArray array];
    ContactPresence *note = nil;
    NSString *nodeName = nil;
    NSString *tmpStr = nil;
    xmlNodePtr pNode = NULL;
    xmlNodePtr pSubNode = NULL;
    NSMutableDictionary *attrs = nil;

    attrs = [XmlUtils parseNodeProperties:pRootNode];
    NSString *domain = [attrs objectForKey:@"domainuri"];

    for (pNode = pRootNode->children; pNode; pNode = pNode->next) {
        if (pNode->type != XML_ELEMENT_NODE) {
            continue;
        }

        /* meet user node */

        note = [[ContactPresence alloc] init];
        note.domain = domain;

        attrs = [XmlUtils parseNodeProperties:pNode];
        tmpStr = [attrs objectForKey:@"userid"];
        note.userId = tmpStr.intValue;
        tmpStr = [attrs objectForKey:@"state"];
        if ([tmpStr isEqualToString:@"terminate"]) {
            note.state = UCALIB_PRESENTATIONSTATE_OFFLINE;
        } else if ([tmpStr isEqualToString:@"active"]) {
            note.state = UCALIB_PRESENTATIONSTATE_ONLINE;
        }

        for (pSubNode = pNode->children; pSubNode; pSubNode = pSubNode->next) {
            if (pSubNode->type != XML_ELEMENT_NODE) {
                continue;
            }
            nodeName = [NSString stringOfUTF8String:(const char*)pSubNode->name];
            if ([nodeName isEqualToString:@"presence"]) {
                attrs = [XmlUtils parseNodeProperties:pSubNode];
                tmpStr = [attrs objectForKey:@"im"];
                if ([tmpStr isEqualToString:@"Online"]) {
                    note.state = UCALIB_PRESENTATIONSTATE_ONLINE;
                } else if ([tmpStr isEqualToString:@"Busy"]) {
                    note.state = UCALIB_PRESENTATIONSTATE_BUSY;
                } else if ([tmpStr isEqualToString:@"Onconference"]) {
                    note.state = UCALIB_PRESENTATIONSTATE_MEETING;
                } else if ([tmpStr isEqualToString:@"Away"]) {
                    note.state = UCALIB_PRESENTATIONSTATE_AWAY;
                }
            } else if ([nodeName isEqualToString:@"camera"]) {
                attrs = [XmlUtils parseNodeProperties:pSubNode];
                tmpStr = [attrs objectForKey:@"basic"];
                note.cameraOn = [tmpStr isEqualToString:@"open"];
            } else if ([nodeName isEqualToString:@"mailbox"]) {
                attrs = [XmlUtils parseNodeProperties:pSubNode];
                tmpStr = [attrs objectForKey:@"basic"];
                note.mailboxOn = [tmpStr isEqualToString:@"open"];
            }
        }

        [notifications addObject:note];
    }

    xmlFreeDoc(pXmlDoc);
    return notifications;
}

+ (NSString *)buildSearchDepartById:(NSInteger)departId totalCount:(NSInteger)count page:(NSInteger)page pageSize:(NSInteger)size {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendFormat:@"<getOrgInfoById>"
                           "<departId>%d</departId>"
                           "<pagination>"
                               "<count>%d</count>"
                               "<serchPage>%d</serchPage>"
                               "<pageSize>%d</pageSize>"
                           "</pagination>"
                       "</getOrgInfoById>",
                       departId, count, page, size];
    return xml;
}

+ (NSString *)buildSearchDepartByKeyword:(NSString *)keywords totalCount:(NSInteger)count page:(NSInteger)page pageSize:(NSInteger)size {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendFormat:@"<getOrgInfo>"
                           "<findKey>%@</findKey>"
                           "<isExact>false</isExact>"
                           "<findSipNum>true</findSipNum>"
                           "<findName>true</findName>"
                           "<findSipAlias>true</findSipAlias>"
                           "<findOfficePhone>true</findOfficePhone>"
                           "<findFamilyPhone>true</findFamilyPhone>"
                           "<findMobilePhone>true</findMobilePhone>"
                           "<findOtherPhone>true</findOtherPhone>"
                           "<pagination>"
                               "<count>%d</count>"
                               "<serchPage>%d</serchPage>"
                               "<pageSize>%d</pageSize>"
                           "</pagination>"
                       "</getOrgInfo>",
                       keywords, count, page, size];
    return xml;
}

+ (Department *)parseDepartment:(xmlNodePtr)pNode {
    if (!pNode || !pNode->children) {
        return nil;
    }

    Department *depart = [[Department alloc] init];
    NSString *nodeName = nil;
    NSString *nodeVal = nil;

    for (xmlNodePtr pSubNode = pNode->children; pSubNode; pSubNode = pSubNode->next) {
        if (![XmlUtils isValidPropNode:pSubNode]) {
            continue;
        }
        nodeName = [NSString stringOfUTF8String:(const char*)pSubNode->name];
        nodeVal = [NSString stringOfUTF8String:(const char*)pSubNode->children->content];
        if ([nodeName isEqualToString:@"url"]) {
            depart.url = nodeVal;
        } else if ([nodeName isEqualToString:@"urlName"]) {
            depart.urlName = nodeVal;
        } else if ([nodeName isEqualToString:@"departId"]) {
            depart.id = [nodeVal integerValue];
        } else if ([nodeName isEqualToString:@"departmentParentId"]) {
            depart.parent = [[Department alloc] init];
            depart.parent.id = [nodeVal integerValue];
        } else if ([nodeName isEqualToString:@"departName"]) {
            depart.name = nodeVal;
        } else if ([nodeName isEqualToString:@"departmentOffice"]) {
            depart.office = nodeVal;
        }
    }

    return depart;
}

+ (NSMutableDictionary *)parseDepartInfos:(const char *)xmlData {
    if (xmlData == NULL) {
        return nil;
    }
    xmlDocPtr pXmlDoc = xmlParseDoc((const xmlChar *)xmlData);
    if (pXmlDoc == NULL) {
        return nil;
    }
    xmlNodePtr pRootNode = xmlDocGetRootElement(pXmlDoc); // orgInfo node
    if (pRootNode == NULL) {
        xmlFreeDoc(pXmlDoc);
        return nil;
    }

    NSMutableDictionary *infos = [[NSMutableDictionary alloc] init];
    NSMutableArray *data = nil;
    NSString *nodeName = nil;
    NSString *nodeVal = nil;
    Department *depart = nil;

    for (xmlNodePtr pNode = pRootNode->children; pNode; pNode = pNode->next) {
        if (pNode->type != XML_ELEMENT_NODE) {
            continue;
        }
        nodeName = [NSString stringOfUTF8String:(const char*)pNode->name];
        if ([nodeName isEqualToString:@"totalCount"]) {
            nodeVal = @"0";
            if ([XmlUtils isValidPropNode:pNode]) {
                nodeVal = [NSString stringOfUTF8String:(const char*)pNode->children->content];
            }
            [infos setObject:[NSNumber numberWithInteger:[nodeVal integerValue]] forKey:KEY_TOTAL_COUNT];
        } else if ([nodeName isEqualToString:@"currentDepartment"]) {
            depart = [XmlUtils parseDepartment:pNode];
            if (depart) {
                [infos setObject:depart forKey:KEY_CUR_DEPART];
            }
        } else if ([nodeName isEqualToString:@"departments"]) {
            for (xmlNodePtr pSubNode = pNode->children; pSubNode; pSubNode = pSubNode->next) {
                if (pSubNode->type != XML_ELEMENT_NODE) {
                    continue;
                }
                nodeName = [NSString stringOfUTF8String:(const char*)pSubNode->name];
                if (![nodeName isEqualToString:@"department"]) {
                    continue;
                }
                depart = [XmlUtils parseDepartment:pSubNode];
                if (depart) {
                    data = [infos objectForKey:KEY_DEPARTS];
                    if (data == nil) {
                        data = [NSMutableArray array];
                    }
                    [data addObject:depart];
                    [infos setObject:data forKey:KEY_DEPARTS];
                }
            }
        } else if ([nodeName isEqualToString:@"userInfos"]) {
            NSMutableArray *contacts = [XmlUtils parseUserinfos:pNode forType:ContactType_Friend];
            for (Contact *contact in contacts) {
                contact.id = ORG_CONTACT_ID;
            }
            if (contacts) {
                [infos setObject:contacts forKey:KEY_USERINFOS];
            }
        }
    }

    xmlFreeDoc(pXmlDoc);
    return infos;
}

+ (NSString *)buildGetGroupMembers:(NSInteger)gourpId {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendFormat:@"<imGroup>"
                       "<imGroupId>%d</imGroupId>"
                       "</imGroup>",
                       gourpId];
    return xml;
}

+ (NSMutableArray *)parseGroupInfos:(const char *)xmlData {
    if (xmlData == NULL) {
        return nil;
    }
    xmlDocPtr pXmlDoc = xmlParseDoc((const xmlChar *)xmlData);
    if (pXmlDoc == NULL) {
        return nil;
    }
    xmlNodePtr pRootNode = xmlDocGetRootElement(pXmlDoc); // imGroups node
    if (pRootNode == NULL) {
        xmlFreeDoc(pXmlDoc);
        return nil;
    }

    NSMutableArray *infos = [NSMutableArray array];
    NSString *nodeName = nil;
    NSString *nodeVal = nil;
    Group *group = nil;

    for (xmlNodePtr pNode = pRootNode->children; pNode; pNode = pNode->next) {
        if (pNode->type != XML_ELEMENT_NODE) {
            continue;
        }

        nodeName = [NSString stringOfUTF8String:(const char*)pNode->name];
        if (![nodeName isEqualToString:@"imGroup"]) {
            continue;
        }

        group = [[Group alloc] init];
        for (xmlNodePtr pSubNode = pNode->children; pSubNode; pSubNode = pSubNode->next) {
            if (pSubNode->type != XML_ELEMENT_NODE) {
                continue;
            }
            nodeName = [NSString stringOfUTF8String:(const char*)pSubNode->name];
            if ([nodeName isEqualToString:@"groupAdminNames"]) {
                for (xmlNodePtr pAdminNode = pSubNode->children; pAdminNode; pAdminNode = pAdminNode->next) {
                    if (pAdminNode->type != XML_ELEMENT_NODE) {
                        continue;
                    }
                    nodeName = [NSString stringOfUTF8String:(const char*)pAdminNode->name];
                    if (![nodeName isEqualToString:@"groupAdminName"] || ![XmlUtils isValidPropNode:pAdminNode]) {
                        continue;
                    }

                    nodeVal = [NSString stringOfUTF8String:(const char*)pAdminNode->children->content];
                    [group.administrators addObject:nodeVal];
                }
            } else if ([XmlUtils isValidPropNode:pSubNode]) {
                nodeVal = [NSString stringOfUTF8String:(const char*)pSubNode->children->content];

                if ([nodeName isEqualToString:@"imGroupId"]) {
                    group.userId = [nodeVal integerValue];
                } else if ([nodeName isEqualToString:@"groupName"]) {
                    group.name = nodeVal;
                } else if ([nodeName isEqualToString:@"fileSpaceSize"]) {
                    group.fileSpaceSize = [nodeVal integerValue];
                } else if ([nodeName isEqualToString:@"createTime"]) {
                    group.createTime = nodeVal;
                } else if ([nodeName isEqualToString:@"userMaxAmount"]) {
                    group.userMaxAmount = [nodeVal integerValue];
                } else if ([nodeName isEqualToString:@"createUserName"]) {
                    group.creator = nodeVal;
                } else if ([nodeName isEqualToString:@"userCount"]) {
                    group.userCount = [nodeVal integerValue];
                } else if ([nodeName isEqualToString:@"groupTypeName"]) {
                    group.type = nodeVal;
                } else if ([nodeName isEqualToString:@"groupAdmin"]) {
                    group.canAdmin = [nodeVal boolValue];
                } else if ([nodeName isEqualToString:@"upLoad"]) {
                    group.canUpload = [nodeVal boolValue];
                } else if ([nodeName isEqualToString:@"photo"]) {
                    UIImage *pic = [XmlUtils decodePhoto:nodeVal];
                    if (pic) {
                        group.photo = pic;
                    }
                } else if ([nodeName isEqualToString:@"annunciate"]) {
                    group.annunciate = nodeVal;
                } else if ([nodeName isEqualToString:@"description"]) {
                    group.descrip = nodeVal;
                }
            }
        }

        [infos addObject:group];
    }

    xmlFreeDoc(pXmlDoc);
    return infos;
}

+ (NSString *)buildModifyGroup:(NSInteger)gourpId annunciate:(NSString *)newAnn {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendFormat:@"<managerImGroup>"
                           "<optType>2</optType>"
                           "<imGroups>"
                               "<imGroup>"
                                   "<imGroupId>%d</imGroupId>"
                                   "<annunciate>%@</annunciate>"
                               "</imGroup>"
                           "</imGroups>"
                       "</managerImGroup>",
         gourpId, newAnn];
    return xml;
}

+ (NSString *)buildAddContacts:(NSArray *)contacts toGroup:(Group *)group {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendFormat:@"<managerUserImGroup>"
                           "<optType>1</optType>"
                           "<imGroupId>%d</imGroupId>"
                           "<userInfos>", group.userId];

    for (Contact *contact in contacts) {
        [xml appendFormat:@"<userInfo>"
                               "<userId>%d</userId>"
                               "<userName>%@</userName>"
                           "</userInfo>", contact.userId, contact.username];
    }

    [xml appendString:@"</userInfos>"
                   "</managerUserImGroup>"];
    return xml;
}

+ (NSString *)buildRemoveMembers:(NSArray *)contacts fromGroup:(Group *)group {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendFormat:@"<managerUserImGroup>"
                           "<optType>3</optType>"
                           "<imGroupId>%d</imGroupId>"
                           "<userInfos>", group.userId];

    for (Contact *contact in contacts) {
        [xml appendFormat:@"<userInfo>"
                               "<userId>%d</userId>"
                           "</userInfo>", contact.userId];
    }

    [xml appendString:@"</userInfos>"
                   "</managerUserImGroup>"];
    return xml;
}

+ (GroupChangeInfo *)parseGroupChangeInfo:(const char *)xmlData {
    if (xmlData == NULL) {
        return nil;
    }
    xmlDocPtr pXmlDoc = xmlParseDoc((const xmlChar *)xmlData);
    if (pXmlDoc == NULL) {
        return nil;
    }
    xmlNodePtr pRootNode = xmlDocGetRootElement(pXmlDoc); // conference-info node
    if (pRootNode == NULL) {
        xmlFreeDoc(pXmlDoc);
        return nil;
    }

    NSString *nodeName = nil;
    NSString *nodeVal = nil;
    NSString *userSip = nil;
    BOOL isUserKicked = NO;
    GroupChangeInfo *info = [[GroupChangeInfo alloc] init];

    for (xmlNodePtr pNode = pRootNode->children; pNode; pNode = pNode->next) {
        nodeName = [NSString stringOfUTF8String:(const char*)pNode->name];

        if (pNode->type == XML_ATTRIBUTE_NODE) {
            if ([nodeName isEqualToString:@"entity"]) {
                nodeVal = [NSString stringOfUTF8String:(const char*)pNode->content];    // "img-1096@sipserver.maipu.com"
                info.groupSipPhone = nodeVal;
                nodeVal = [[nodeVal componentsSeparatedByString:@"@"] objectAtIndex:0]; // "img-1096"
                nodeVal = [nodeVal substringFromIndex:4];                               // "1096"
                info.groupId = [nodeVal integerValue];
            }
        } else if (pNode->type == XML_ELEMENT_NODE) {
            if ([nodeName isEqualToString:@"conference-state"]) {
                for (xmlNodePtr pSubNode = pNode->children; pSubNode; pSubNode = pSubNode->next) {
                    if (pSubNode->type != XML_ELEMENT_NODE) {
                        continue;
                    }
                    nodeName = [NSString stringOfUTF8String:(const char*)pSubNode->name];
                    if (![nodeName isEqualToString:@"user-count"] || ![XmlUtils isValidPropNode:pSubNode]) {
                        continue;
                    }

                    nodeVal = [NSString stringOfUTF8String:(const char*)pSubNode->children->content];
                    info.userCount = [nodeVal integerValue];
                }
            } else if ([nodeName isEqualToString:@"users"]) {
                for (xmlNodePtr pSubNode = pNode->children; pSubNode; pSubNode = pSubNode->next) {
                    if (pSubNode->type != XML_ELEMENT_NODE) {
                        continue;
                    }
                    nodeName = [NSString stringOfUTF8String:(const char*)pSubNode->name];
                    if (![nodeName isEqualToString:@"user"]) {
                        continue;
                    }

                    userSip = nil;
                    isUserKicked = NO;

                    for (xmlNodePtr pAttrNode = pSubNode->children; pAttrNode; pAttrNode = pAttrNode->next) {
                        if (pAttrNode->type != XML_ATTRIBUTE_NODE) {
                            continue;
                        }
                        nodeName = [NSString stringOfUTF8String:(const char*)pAttrNode->name];
                        nodeVal = [NSString stringOfUTF8String:(const char*)pAttrNode->content];
                        if ([nodeName isEqualToString:@"entity"]) {
                            NSRange r = [nodeVal rangeOfString:@"(?<=&lt;|<)(.*)(?=&gt;|>)" options:NSCaseInsensitiveSearch|NSRegularExpressionSearch];
                            if (r.location == NSNotFound) {
                                userSip = nodeVal;
                            } else {
                                userSip = [nodeVal substringWithRange:r];
                            }
                        } else if ([nodeName isEqualToString:@"state"]) {
                            isUserKicked = [nodeVal isEqualToString:@"delete"];
                        }
                    }

                    if (isUserKicked) {
                        [info.kickedUserSip addObject:userSip];
                    } else {
                        [info.presentUserSip addObject:userSip];
                    }
                }
            }
        }
    }

    xmlFreeDoc(pXmlDoc);
    return info;
}

+ (NSString *)buildGetPersonsInfo:(NSArray *)sipPhones {
    return [XmlUtils buildGetPersonsInfo:sipPhones orUsernames:nil];
}

+ (NSString *)buildGetPersonsInfo:(NSArray *)sipPhones orUsernames:(NSArray *)usernames {
    NSMutableString *xml = [NSMutableString stringWithString:XML_HEAD];
    [xml appendString:@"<userInfo>"];

    if ([usernames count] > 0) {
        [xml appendString:@"<userNames>"];
        for (NSString *username in usernames) {
            [xml appendFormat:@"<userName>%@</userName>", username];
        }
        [xml appendString:@"</userNames>"];
    }

    if ([sipPhones count] > 0) {
        [xml appendString:@"<sipPhones>"];
        for (NSString *sipPhone in sipPhones) {
            [xml appendFormat:@"<sipPhone>%@</sipPhone>", sipPhone];
        }
        [xml appendString:@"</sipPhones>"];
    }

    [xml appendString:@"</userInfo>"];
    return xml;
}

@end
