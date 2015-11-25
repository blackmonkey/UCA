/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "UcaOrgService.h"

#undef TAG
#define TAG @"UcaOrgService"

#define KEY_SEARCH_KEY        @"KEY_SEARCH_KEY"
#define KEY_SEARCH_BY         @"KEY_SEARCH_BY"
#define KEY_REQUEST_XML       @"KEY_REQUEST_XML"
#define VAL_SEARCH_BY_ID      @"VAL_SEARCH_BY_ID"
#define VAL_SEARCH_BY_KEYWORD @"VAL_SEARCH_BY_KEYWORD"

@implementation UcaOrgService {
    Department *_topRootDepart;
}

@synthesize addTarget;

- (id)init {
    self = [super init];
    if (self) {
        _topRootDepart = [[Department alloc] init];
        _topRootDepart.id = TOP_ROOT_DEPART_ID;
    }
    return self;
}

- (BOOL)start {
    UcaLog(TAG, @"Start()");
    if (![super start]) {
        return NO;
    }
    return YES;
}

- (BOOL)stop {
    UcaLog(TAG, @"Stop()");
    if (![super stop]) {
        return NO;
    }
    return YES;
}

/**
 * 根据搜索结果，补充组织架构信息树。
 * @param infos 搜索结果，包含如下键值对：
 *     {
 *         KEY_TOTAL_COUNT : 子部门和联系人记录总数
 *         KEY_CUR_DEPART  : 当前查询的部门
 *         KEY_DEPARTS     : 子部门
 *         KEY_USERINFOS   : 联系人
 *     }
 * @return attached node.
 */
- (void)attachSearchResult:(NSDictionary *)infos {
    NSNumber *count = [infos objectForKey:KEY_TOTAL_COUNT];
    NSArray *subDeparts = [infos objectForKey:KEY_DEPARTS];
    NSArray *userInfos = [infos objectForKey:KEY_USERINFOS];
    Department *curDepart = [infos objectForKey:KEY_CUR_DEPART];
    Department *dp = nil;

    NSUInteger totalCount = [count unsignedIntegerValue];
    if (count == nil) {
        totalCount = subDeparts.count + userInfos.count;
    }

    if (curDepart == nil) {
        curDepart = _topRootDepart;
    } else {
        NSArray *ids = [curDepart.url componentsSeparatedByString:@"/"];
        NSInteger dpId;
        Department *parentDp = _topRootDepart;

        /**
         * 检查当前查询部门的所有层次上级部门，如果某层上级部门不在
         * 部门树中，则创建相应节点。
         */
        for (int i = 0; i < ids.count - 1; i++) {
            dpId = [(NSString *)[ids objectAtIndex:i] integerValue];
            dp = [parentDp getSubDepartById:dpId];
            if (dp == nil) {
                dp = [[Department alloc] init];
                dp.id = dpId;
                [parentDp addSubDepart:dp];
            }
            parentDp = dp;
        }

        /**
         * 如果当前查询部门不在部门树中，则加入相应节点。
         * 此时，parentDp指向curDepart直接父节点。
         */
        dp = [parentDp getSubDepartById:curDepart.id];
        if (dp == nil) {
            [parentDp addSubDepart:curDepart];
        } else {
            [dp copyBaseInfo:curDepart];
            curDepart = dp;
        }
    }

    /* 更新当前查询部门对应的树节点信息 */
    curDepart.fetchedInfos = YES;
    curDepart.totalCount = totalCount;

    for (Department *depart in subDeparts) {
        dp = [curDepart getSubDepartById:depart.id];
        if (dp == nil) {
            [curDepart addSubDepart:depart];
        } else {
            [dp copyBaseInfo:depart];
        }
    }

    for (Contact *contact in userInfos) {
        if (NSNotFound == [curDepart.userInfos indexOfObject:contact]) {
            [curDepart.userInfos addObject:contact];
        }
    }
}

/**
 * 根据搜索条件，获取组织架构信息。
 * @param searchParam 搜索条件，包含如下键值对：
 *     {
 *         KEY_SEARCH_BY   : VAL_SEARCH_BY_ID | VAL_SEARCH_BY_KEYWORD,
 *         KEY_SEARCH_KEY  : 部门ID或搜索关键字
 *         KEY_REQUEST_XML : 搜索输入XML
 *     }
 */
- (void)getSearchInfo:(NSDictionary *)searchParam {
    UCALIB_LOGIN_HANDLE curLoginHandle = [UcaAppDelegate sharedInstance].accountService.curLoginHandle;
    NSString *requestXml = [searchParam objectForKey:KEY_REQUEST_XML];
    NSString *searchBy = [searchParam objectForKey:KEY_SEARCH_BY];
    id searchKey = [searchParam objectForKey:KEY_SEARCH_KEY];
    NSString *okEvtName = nil;
    NSString *nokEvtName = nil;
    char *outXml = NULL;
    UCALIB_ERRCODE res = UCALIB_ERR_OK;

    if ([searchBy isEqualToString:VAL_SEARCH_BY_ID]) {
        okEvtName = UCA_EVENT_FETCHED_ORG_INFO;
        nokEvtName = UCA_EVENT_FETCHED_ORG_INFO_FAILED;
        res = ucaLib_SearchInfoById(curLoginHandle, [requestXml UTF8String], &outXml);
        UcaLog(TAG, @"getSearchInfo() ucaLib_SearchInfoById res=%d, out=%s", res, outXml);
    } else {
        okEvtName = UCA_EVENT_SEARCHED_ORG_INFO;
        nokEvtName = UCA_EVENT_SEARCHED_ORG_INFO_FAILED;
        res = ucaLib_SearchInfo(curLoginHandle, [requestXml UTF8String], &outXml);
        UcaLog(TAG, @"getSearchInfo() ucaLib_SearchInfo res=%d, out=%s", res, outXml);
    }

    if (res != UCALIB_ERR_OK) {
        UcaLibRelease(outXml);
        [NotifyUtils postNotificationWithName:nokEvtName object:searchKey];
        return;
    }

    NSDictionary *infos = [XmlUtils parseDepartInfos:(const char *)outXml];
    UcaLibRelease(outXml);
    if ([searchBy isEqualToString:VAL_SEARCH_BY_ID]) {
        [self attachSearchResult:infos];
        [NotifyUtils postNotificationWithName:okEvtName object:searchKey];
    } else {
        [NotifyUtils postNotificationWithName:okEvtName object:searchKey userInfo:infos];
    }
}

- (void)fetchOrgInfoByDepartId:(NSInteger)departId {
    NSString *request = [XmlUtils buildSearchDepartById:departId totalCount:0 page:1 pageSize:INT32_MAX];
    NSDictionary *searchParam = [NSDictionary dictionaryWithObjectsAndKeys:VAL_SEARCH_BY_ID, KEY_SEARCH_BY, [NSNumber numberWithInteger:departId], KEY_SEARCH_KEY, request, KEY_REQUEST_XML, nil];
    [self performSelectorInBackground:@selector(getSearchInfo:) withObject:searchParam];
}

- (void)searchOrgInfo:(NSString *)keywords {
    NSString *request = [XmlUtils buildSearchDepartByKeyword:keywords totalCount:0 page:1 pageSize:INT32_MAX];
    NSDictionary *searchParam = [NSDictionary dictionaryWithObjectsAndKeys:VAL_SEARCH_BY_KEYWORD, KEY_SEARCH_BY, keywords, KEY_SEARCH_KEY, request, KEY_REQUEST_XML, nil];
    [self performSelectorInBackground:@selector(getSearchInfo:) withObject:searchParam];
}

- (Department *)getTopRootDepartment {
    return _topRootDepart;
}

@end
