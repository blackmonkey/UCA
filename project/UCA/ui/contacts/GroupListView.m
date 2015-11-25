/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "GroupListView.h"
#import "ContactOperationListView.h"
#import "GroupElement.h"

#undef TAG
#define TAG @"GroupListView"

@implementation GroupListView {
    NSArray *_allGroups;
    Group *_dstGroup;
    BOOL _refreshing;
    BOOL _toRefresh;
}

- (void)refreshDataAndReload {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
#endif

    @synchronized (_allGroups) {
        _refreshing = YES;

        QSection *section = [self.root getSectionForIndex:0];
        [section.elements removeAllObjects];

        for (Group *g in _allGroups) {
            if ([g isEqual:_dstGroup]) {
                continue;
            }
            GroupElement *groupElement = [[GroupElement alloc] initWithGroup:g];
            groupElement.controllerAction = @"showGroupMember:";
            [section addElement:groupElement];
        }

        if ([section.elements count] == 0) {
            QEmptyListElement *element = [[QEmptyListElement alloc] initWithTitle:I18nString(@"没有其他群组") Value:nil];
            [section addElement:element];
        }

        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];

        _refreshing = NO;

        if (_toRefresh) {
            _toRefresh = NO;
            [self refreshDataAndReload];
        }
    }
}

- (void)tryRefreshDataAndReload {
    if (_refreshing) {
        _toRefresh = YES;
    } else {
        [self refreshDataAndReload];
    }
}

- (QRootElement *)createForm {
    QRootElement *form = [[QRootElement alloc] init];
    form.title = I18nString(@"添加群成员");

    QSection *section = [[QSection alloc] init];
    section.key = nil;
    [form addSection:section];

    [section addElement:[[QLoadingElement alloc] init]];
    return form;
}

- (id)initWithGroups:(NSArray *)groups exceptGroup:(Group *)group {
    QRootElement *form = [self createForm];
    self = [super initWithRoot:form];
    if (self) {
        _allGroups = groups;
        _dstGroup = group;
        _refreshing = NO;
        _toRefresh = NO;
    }

    return self;
}

- (void)showGroupMember:(GroupElement *)element {
    ContactOperationListView *view = [[ContactOperationListView alloc] initAddMemberFromGroup:element.group
                                                                                      toGroup:_dstGroup];
    [self displayViewController:view];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.quickDialogTableView.backgroundColor = [UIColor clearColor];
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_INDICATE_GROUP_UPDATED
                                               object:nil];
    [self tryRefreshDataAndReload];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

@end
