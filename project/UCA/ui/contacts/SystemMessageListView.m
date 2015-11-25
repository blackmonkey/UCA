/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "SystemMessageListView.h"
#import "ContactsListView.h"

@interface SystemMessageListView()
- (void)registerListener;
- (void)deregisterListener;
@end

@implementation SystemMessageListView {
    UIBarButtonItem *_deleteButton;
    UIBarButtonItem *_confirmButton;
    UIBarButtonItem *_selectAllButton;
    UIBarButtonItem *_cancelButton;

    NSArray *_sysMessages;
    BOOL _refreshing;
    BOOL _toRefresh;
}

- (void)refreshTitleBarButtons {
    if ([_sysMessages count] <= 0) {
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

- (void)refreshDataAndReload {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
#endif

    UcaMessageService *service = [UcaAppDelegate sharedInstance].messageService;
    @synchronized (_sysMessages) {
        _refreshing = YES;

//        [self deregisterListener];

        QSection *section = [self.root getSectionForIndex:0];
        [section.elements removeAllObjects];

        _sysMessages = [service systemMessages];
        if (_sysMessages.count > 0) {
            QTextElement *element;
            for (Message *msg in _sysMessages) {
                element = [[QTextElement alloc] initWithText:[msg.html plainText]];
                element.title = [NSString getDate:msg.datetime];
                [section addElement:element];

                if (![msg isRead]) {
                    [service performSelectorInBackground:@selector(markMessageAsRead:)
                                              withObject:[NSNumber numberWithInteger:msg.id]];
                }
            }
        } else {
            QEmptyListElement *emptyElement = [[QEmptyListElement alloc] initWithTitle:I18nString(@"没有系统消息") Value:nil];
            emptyElement.allowSelectInEditMode = NO;
            [section addElement:emptyElement];
        }

        [self refreshTitleBarButtons];
        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//        [self registerListener];

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
    form.title = I18nString(@"系统消息");

    QSection *section = [[QSection alloc] init];
    section.key = nil;
    [form addSection:section];

    QLoadingElement *element = [[QLoadingElement alloc] init];
    element.allowSelectInEditMode = NO;
    [section addElement:element];

    return form;
}

- (id)init {
    QRootElement *root = [self createForm];
    self = [super initWithRoot:root];
    if (self) {
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(exitEditingMode)];
        _confirmButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(confirmDelete)];
        _selectAllButton = [[UIBarButtonItem alloc] initWithTitle:I18nString(@"全选")
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(selectAllSysMessages)];
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

- (void)selectAllSysMessages {
    for (NSInteger row = 0; row < [_sysMessages count]; row++) {
        [self.quickDialogTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
                                               animated:NO
                                         scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)confirmDelete {
    NSArray *selectedPath = self.quickDialogTableView.indexPathsForSelectedRows;
    if (selectedPath.count > 0) {
        [NotifyUtils confirm:I18nString(@"是否删除选中系统消息？") delegate:self];
    } else {
        [self exitEditingMode];
    }
}

- (NSArray *)getSelectedSysMessages {
    @synchronized (_sysMessages) {
        NSMutableArray *selectedMsgs = [NSMutableArray array];
        for (NSIndexPath *indexPath in self.quickDialogTableView.indexPathsForSelectedRows) {
            [selectedMsgs addObject:[_sysMessages objectAtIndex:indexPath.row]];
        }
        return selectedMsgs;
    }
}

- (void)deleteSysMessages {
    @synchronized (self) {
        NSArray *sysMsgs = [self getSelectedSysMessages];
        [self exitEditingMode];

        UcaMessageService *service = [UcaAppDelegate sharedInstance].messageService;
        [service performSelectorInBackground:@selector(deleteMessages:) withObject:sysMsgs];
    }
}

- (void)registerListener {
    // TODO: 为稳定起见，目前任何Message的变动，都全部刷新整个UITableView。后期再优化。
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_ADD_MESSAGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_UPDATE_MESSAGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_UPDATE_MESSAGES
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tryRefreshDataAndReload)
                                                 name:UCA_EVENT_DELETE_MESSAGES
                                               object:nil];
}

- (void)deregisterListener {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.quickDialogTableView.backgroundColor = APP_BGCOLOR;
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.quickDialogTableView.allowsMultipleSelectionDuringEditing = YES;

    [self exitEditingMode];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerListener];
    [self tryRefreshDataAndReload];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self deregisterListener];
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
        [self deleteSysMessages];
    } else { // cancel
        [self exitEditingMode];
    }
}

@end
