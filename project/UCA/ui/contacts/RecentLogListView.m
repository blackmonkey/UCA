/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "RecentLogListView.h"
#import "ContactsListView.h"
#import "RecentLogElement.h"

@implementation RecentLogListView {
    UIBarButtonItem *_deleteButton;
    UIBarButtonItem *_confirmButton;
    UIBarButtonItem *_selectAllButton;
    UIBarButtonItem *_cancelButton;

    QRootElement *_rootEntry;
    BOOL _showOnlyMissed;
    NSUInteger _recentLogCount;
    BOOL _refreshing;
    BOOL _toRefresh;
}

- (void)refreshTitleBarButtons {
    if (_recentLogCount <= 0) {
        self.navigationItem.rightBarButtonItems = nil;
        return;
    }

    NSMutableArray *buttons = [NSMutableArray array];
    if (self.quickDialogTableView.editing) {
        [buttons addObject:_confirmButton];
        [buttons addObject:_selectAllButton];
        [buttons addObject:_cancelButton];
    } else {
        [buttons addObject:_deleteButton];
    }
    self.navigationItem.rightBarButtonItems = buttons;
}

- (void)setupFormWithEntry:(QRootElement *)entry onlyMissed:(BOOL)missed atRoot:(QRootElement *)formRoot {
    if (entry == nil) {
        return;
    }

    if (formRoot == nil) {
        formRoot = self.root;
    }

    formRoot.title = entry.title;
    self.title = entry.title;

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    NSArray *records = nil;
    NSDate *lastImDate = nil;

    if ([entry.key isEqualToString:KEY_VOICE_MAIL_ENTRY]) {
        // TODO: implement
    } else if ([entry.key isEqualToString:KEY_GROUP_ENTRY]) {
        // TODO: implement
    } else if ([entry.key isEqualToString:KEY_SESSION_ENTRY]) {
        // TODO: implement
    } else if ([entry isKindOfClass:[ContactElement class]]) {
        Contact *contact = [(ContactElement *)entry contact];
        NSArray *msgs = [app.messageService messagesWithContact:contact];
        if ([msgs count] > 0) {
            Message *msg = [msgs lastObject];
            lastImDate = msg.datetime;
        }

        if (missed) {
            records = [app.recentService getMissedCallsOfContact:contact];
        } else {
            records = [app.recentService getRecentLogsOfContact:contact];
        }
    }

    QSection *section = [formRoot.sections objectAtIndex:0];
    [section.elements removeAllObjects];
    if (lastImDate) {
        RecentLogElement *rle = [[RecentLogElement alloc] initWithLastImDate:lastImDate];
        rle.allowSelectInEditMode = NO;
        [section addElement:rle];
    }

    section = [formRoot.sections objectAtIndex:1];
    [section.elements removeAllObjects];

    _recentLogCount = records.count;

    if (records.count > 0) {
        for (RecentLog *log in records) {
            RecentLogElement *rle = [[RecentLogElement alloc] initWithRecentLog:log];
            [section addElement:rle];
        }
    } else {
        QEmptyListElement *emptyElement = [[QEmptyListElement alloc] initWithTitle:I18nString(@"没有通话记录。") Value:nil];
        emptyElement.allowSelectInEditMode = NO;
        [section addElement:emptyElement];
    }
}

- (void)tryClearMissedCall:(QRootElement *)entry {
    if ([entry isKindOfClass:[ContactElement class]]) {
        Contact *contact = [(ContactElement *)entry contact];
        UcaRecentService *service = [UcaAppDelegate sharedInstance].recentService;
        NSArray *calls = [service getMissedCallsOfContact:contact];
        if (calls != nil && [calls count] > 0) {
            [service clearMissedCallsOfContact:contact];
        }
    }
}

- (void)refreshDataAndReload {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
#endif

    @synchronized (self) {
        _refreshing = YES;

        [self setupFormWithEntry:_rootEntry onlyMissed:_showOnlyMissed atRoot:self.root];
        [self refreshTitleBarButtons];
        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        [self tryClearMissedCall:_rootEntry];

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

- (QRootElement *)createFormWithEntry:(QRootElement *)entry onlyMissed:(BOOL)missed {
    QRootElement *form = [[QRootElement alloc] init];
    form.title = entry.title;

    // section for recent messages
    QSection *section = [[QSection alloc] init];
    section.key = nil;
    [form addSection:section];

    // section for recent calls
    section = [[QSection alloc] init];
    section.key = nil;
    [form addSection:section];

    [self setupFormWithEntry:entry onlyMissed:missed atRoot:form];

    return form;
}

- (id)initWithEntry:(QRootElement *)entry onlyMissed:(BOOL)missed {
    QRootElement *root = [self createFormWithEntry:entry onlyMissed:missed];
    self = [super initWithRoot:root];
    if (self) {
        _rootEntry = entry;
        _showOnlyMissed = missed;
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(exitEditingMode)];
        _confirmButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(confirmDeleteLogs)];
        _selectAllButton = [[UIBarButtonItem alloc] initWithTitle:I18nString(@"全选")
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(selectAllRecentLogs)];
        _deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                      target:self
                                                                      action:@selector(enterEditingMode)];
        _refreshing = NO;
        _toRefresh = NO;
        [self refreshTitleBarButtons];
    }

    return self;
}

- (void)enterEditingMode {
    if (!self.quickDialogTableView.editing) {
        self.quickDialogTableView.editing = YES;
        [self refreshTitleBarButtons];
    }
}

- (void)exitEditingMode {
    if (self.quickDialogTableView.editing) {
        self.quickDialogTableView.editing = NO;
        [self refreshTitleBarButtons];
    }
}

- (void)selectAllRecentLogs {
    for (NSInteger sec = 1; sec < [self.quickDialogTableView numberOfSections]; sec++) {
        for (NSInteger row = 0; row < [self.quickDialogTableView numberOfRowsInSection:sec]; row++) {
            [self.quickDialogTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:sec]
                                                   animated:NO
                                             scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (void)confirmDeleteLogs {
    NSArray *selectedPath = self.quickDialogTableView.indexPathsForSelectedRows;
    if (selectedPath.count > 0) {
        [NotifyUtils confirm:I18nString(@"是否删除选中通讯记录？") delegate:self];
    } else {
        [self exitEditingMode];
    }
}

- (NSArray *)getSelectedRecentLogs {
    @synchronized (self) {
        RecentLogElement *element = nil;
        NSMutableArray *selectedLogs = [NSMutableArray array];
        for (NSIndexPath *indexPath in self.quickDialogTableView.indexPathsForSelectedRows) {
            element = (RecentLogElement *)[self.root getElementAtIndexPath:indexPath];
            [selectedLogs addObject:element.recentLog];
        }
        return selectedLogs;
    }
}

- (void)deleteLogs {
    @synchronized (self) {
        NSArray *logs = [self getSelectedRecentLogs];
        [self exitEditingMode];

        UcaRecentService *service = [UcaAppDelegate sharedInstance].recentService;
        [service performSelectorInBackground:@selector(deleteRecentLogs:) withObject:logs];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.quickDialogTableView.backgroundColor = APP_BGCOLOR;
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.quickDialogTableView.allowsMultipleSelectionDuringEditing = YES;

    [self exitEditingMode];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_ADD_RECENT_LOG
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_DELETE_RECENT_LOGS
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_UPDATE_RECENT_LOGS
                                               object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self tryRefreshDataAndReload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - UIAlertView delegate methods

/**
 * 确认或取消删除选中通讯记录。
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // confirm
        [self deleteLogs];
    } else { // cancel
        [self exitEditingMode];
    }
}

@end
