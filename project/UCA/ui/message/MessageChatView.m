/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <MobileCoreServices/UTCoreTypes.h>
#import "MessageChatView.h"
#import "MessageViewer.h"
#import "EmoteView.h"
#import "ContactOperationListView.h"

#undef TAG
#define TAG @"MessageChatView"

// 因为加载数据有一定延时，所以等一会儿再翻滚页面到最近的即时消息。
#define SCROLL_DELAY (0.8)

#define MENU_ADD_MEMBER_FROM_ORG         I18nString(@"从组织架构添加成员")
#define MENU_ADD_MEMBER_FROM_FRIEND      I18nString(@"从好友添加成员")
#define MENU_ADD_MEMBER_FROM_RECENTS     I18nString(@"从最近联系人添加成员")
#define MENU_CLOSE_SESSION               I18nString(@"退出多人会话")
#define MENU_DELETE_MESSAGE              I18nString(@"删除消息")

@interface MessageChatView()
- (void)registerRefreshListener;
- (void)deregisterRefreshListener;
@end

@implementation MessageChatView {
    BOOL _resizeWhenKeyboardPresented;
    CGFloat _expectedViewHeight;
    id _contactObj;
    NSArray *_messages;
    NSDate *_historyStamp;
    BOOL _refreshing;
    BOOL _toRefresh;

    UIBarButtonItem *_deleteButton;
    UIBarButtonItem *_deleteDoneButton;
    UIBarButtonItem *_menuButton;

    UIImagePickerController *_imagePicker;
    UIImagePickerController *_photoTaker;

    UIView *_toolPanel;
    UIImageView *_panelBg;
    UIButton *_emotBtn;
    UIButton *_attachImgBtn;
    UIButton *_takePhotoBtn;
    UIButton *_sendBtn;
    UITextField *_msgEditor;
}

#pragma mark - private methods

- (void)reloadTableView {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
#endif

    @synchronized (_messages) {
        _refreshing = YES;

        if (_messages.count > 0 && self.quickDialogTableView.editing) {
            self.navigationItem.rightBarButtonItem = _deleteDoneButton;
        } else if ([_contactObj isKindOfClass:[Session class]]) {
            self.navigationItem.rightBarButtonItem = _menuButton;
        } else {
            if (_messages.count == 0) {
                self.navigationItem.rightBarButtonItem = nil;
            } else {
                self.navigationItem.rightBarButtonItem = _deleteButton;
            }
        }

        [self.quickDialogTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        [self performSelector:@selector(scrollListToBottom) withObject:nil afterDelay:SCROLL_DELAY];
    }
}

- (void)refreshDataAndReload {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
#endif

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    UcaMessageService *service = app.messageService;

    @synchronized (_messages) {
        _refreshing = YES;

//        [self deregisterRefreshListener];

        /* 清空当前IM消息列表 */
        QSection *section = [self.root getSectionForIndex:0];
        if (!section) {
            section = [[QSection alloc] init];
            section.key = nil;
            [self.root addSection:section];
        }
        [section.elements removeAllObjects];

        Contact *contact = nil;
        if ([_contactObj isKindOfClass:[Contact class]]) {
            contact = (Contact *)_contactObj;
        } else if ([_contactObj isKindOfClass:[Group class]]) {
            contact = [[Contact alloc] initWithGroup:_contactObj];
        } else if ([_contactObj isKindOfClass:[Session class]]) {
            contact = [[Contact alloc] initWithSession:_contactObj];
        }

        /* 获取最新的IM消息 */
        if (_historyStamp != nil) {
            _messages = [service messagesWithContact:contact excludeBefore:_historyStamp];
        } else {
            _messages = [service messagesWithContact:contact];
        }

        /* 更新IM消息列表 */
        if (_messages.count == 0) {
            QEmptyListElement *element = [[QEmptyListElement alloc] initWithTitle:I18nString(@"没有即时消息") Value:nil];
            [section addElement:element];
        } else {
            MessageElement *element = nil;
            for (Message *msg in _messages) {
                if (![msg isRead]) {
                    [service performSelectorInBackground:@selector(markMessageAsRead:)
                                              withObject:[NSNumber numberWithInteger:msg.id]];
                }

                element = [[MessageElement alloc] initWithMessage:msg];
                element.delegate = self;
                element.controllerAction = @"showFullHtml:";
                [section addElement:element];
            }
        }

        UcaLog(TAG, @"refreshDataAndReload() messages count:%d", _messages.count);
        [self reloadTableView];

//        [self registerRefreshListener];

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

- (QRootElement *)createForm:(NSString *)name {
    QRootElement *form = [[QRootElement alloc] init];
    form.title = name;

    QSection *section = [[QSection alloc] init];
    section.key = nil;

    QLoadingElement *element = [[QLoadingElement alloc] init];
    [section addElement:element];

    [form addSection:section];

    return form;
}

- (void)initTitleBarButtons {
    _menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"res/titlebar_menu_button"]
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(showMenu:)];
    _deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                  target:self
                                                                  action:@selector(markDeleting)];
    _deleteDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                      target:self
                                                                      action:@selector(confirmDeleting)];
}

- (id)initWithContact:(Contact *)contact {
    NSString *_name = contact.displayName;

    QRootElement *root = [self createForm:_name];
    self = [super initWithRoot:root];

    if (self) {
        _refreshing = NO;
        _toRefresh = NO;
        _contactObj = contact;

        if (contact.id == ORG_CONTACT_ID && ![NSString isNullOrEmpty:contact.sipPhone]) {
            Contact *cachedContact = [[UcaAppDelegate sharedInstance].contactService getContactBySipPhone:contact.sipPhone];
            if (cachedContact != nil) {
                _contactObj = cachedContact;
            }
        }

        [self initTitleBarButtons];

        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.delegate = self;
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _imagePicker.allowsEditing = YES;
        _imagePicker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];

        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            _photoTaker = [[UIImagePickerController alloc] init];
            _photoTaker.delegate = self;
            _photoTaker.sourceType = UIImagePickerControllerSourceTypeCamera;
            _photoTaker.allowsEditing = YES;
            _photoTaker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        }

        self.title = _name;
    }
    return self;
}

- (id)initWithGroup:(Group *)group showHistory:(BOOL)show {
    NSString *_name = group.name;

    QRootElement *root = [self createForm:_name];
    self = [super initWithRoot:root];

    if (self) {
        _refreshing = NO;
        _toRefresh = NO;
        _contactObj = group;

        if (!show) {
            _historyStamp = [NSDate date];
        }

        [self initTitleBarButtons];

        self.title = _name;
    }
    return self;
}

- (id)initWithSession:(Session *)session {
    NSString *_name = session.name;

    QRootElement *root = [self createForm:_name];
    self = [super initWithRoot:root];
    if (self) {
        _refreshing = NO;
        _toRefresh = NO;
        _contactObj = session;

        [self initTitleBarButtons];

        self.title = _name;
    }
    return self;
}

- (IBAction)showMenu:(id)button {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    [sheet addButtonWithTitle:MENU_ADD_MEMBER_FROM_ORG];
    [sheet addButtonWithTitle:MENU_ADD_MEMBER_FROM_FRIEND];
    [sheet addButtonWithTitle:MENU_ADD_MEMBER_FROM_RECENTS];
    [sheet addButtonWithTitle:MENU_CLOSE_SESSION];
    if (_messages.count > 0) {
        [sheet addButtonWithTitle:MENU_DELETE_MESSAGE];
    }
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:I18nString(@"取消")];
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark - override parent methods

- (void)setResizeWhenKeyboardPresented:(BOOL)observesKeyboard {
    if (observesKeyboard != _resizeWhenKeyboardPresented) {
        _resizeWhenKeyboardPresented = observesKeyboard;

        if (_resizeWhenKeyboardPresented) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeForKeyboard:) name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeForKeyboard:) name:UIKeyboardWillHideNotification object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        }
    }
}

- (BOOL)resizeWhenKeyboardPresented {
    return _resizeWhenKeyboardPresented;
}

#pragma mark - View lifecycle

- (void)layoutToolPanel {
    CGRect rect = _toolPanel.frame;
    rect.origin.y = self.view.frame.size.height - rect.size.height;
    rect.size.width = self.view.frame.size.width - 10;
    _toolPanel.frame = rect;

    rect.origin.x = rect.origin.y = 0;
    _panelBg.frame = rect;
    _panelBg.image = [_panelBg.image resizeFromCenter];

    rect = _sendBtn.frame;
    rect.origin.x = _toolPanel.frame.size.width - rect.size.width - 5;
    _sendBtn.frame = rect;

    rect = _msgEditor.frame;
    rect.origin.x = 5;
    rect.size.width = _sendBtn.frame.origin.x - 10;
    _msgEditor.frame = rect;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    CGRect rect = self.view.frame;
    if (_expectedViewHeight != 0 && _expectedViewHeight != rect.size.height) {
        rect.size.height = _expectedViewHeight;
        self.view.frame = rect;
    }

    [self layoutToolPanel];

    rect = self.quickDialogTableView.frame;
    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size.height = self.view.frame.size.height - _toolPanel.frame.size.height;
    self.quickDialogTableView.frame = rect;
}

- (void)createToolPanel {
    CGRect rect;

    UIImage *panelBg = [UIImage imageNamed:@"res/chat_tool_panel_background"];
    UIImage *toolBtnPressedBg = [UIImage imageNamed:@"res/chat_tool_button_pressed_background"];

    _toolPanel = [[UIView alloc] initWithFrame:CGRectMake(5, 0, self.view.frame.size.width - 10, 0)];

    _panelBg = [[UIImageView alloc] initWithImage:panelBg];

    _emotBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_emotBtn setBackgroundImage:toolBtnPressedBg forState:UIControlStateHighlighted];
    [_emotBtn setImage:[UIImage imageNamed:@"res/chat_emote_button"] forState:UIControlStateNormal];
    [_emotBtn addTarget:self action:@selector(showEmotes) forControlEvents:UIControlEventTouchUpInside];
    _emotBtn.frame = CGRectMake(5, 3, toolBtnPressedBg.size.width, toolBtnPressedBg.size.height);

    _attachImgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _attachImgBtn.hidden = (_imagePicker == nil);
    if (_imagePicker) {
        [_attachImgBtn setBackgroundImage:toolBtnPressedBg forState:UIControlStateHighlighted];
        [_attachImgBtn setImage:[UIImage imageNamed:@"res/chat_attach_button"] forState:UIControlStateNormal];
        [_attachImgBtn addTarget:self action:@selector(attachImage) forControlEvents:UIControlEventTouchUpInside];
        [_attachImgBtn sizeToFit];
        _attachImgBtn.frame = CGRectMake(_emotBtn.frame.origin.x + _emotBtn.frame.size.width,
                                         _emotBtn.frame.origin.y,
                                         _emotBtn.frame.size.width,
                                         _emotBtn.frame.size.height);
    }

    _takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _takePhotoBtn.hidden = (_photoTaker == nil);
    if (_photoTaker) {
        [_takePhotoBtn setBackgroundImage:toolBtnPressedBg forState:UIControlStateHighlighted];
        [_takePhotoBtn setImage:[UIImage imageNamed:@"res/chat_take_photo_button"] forState:UIControlStateNormal];
        [_takePhotoBtn addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        [_takePhotoBtn sizeToFit];
        _takePhotoBtn.frame = CGRectMake(_attachImgBtn.frame.origin.x + _attachImgBtn.frame.size.width,
                                         _attachImgBtn.frame.origin.y,
                                         _attachImgBtn.frame.size.width,
                                         _attachImgBtn.frame.size.height);
    }

    _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendBtn.contentMode = UIViewContentModeScaleToFill;
    _sendBtn.enabled = NO;
    _sendBtn.frame = CGRectMake(_toolPanel.frame.size.width - 69,
                                _emotBtn.frame.origin.y + _emotBtn.frame.size.height,
                                64, 33);
    _sendBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [_sendBtn setTitle:I18nString(@"发送") forState:UIControlStateNormal];
    [_sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_sendBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [_sendBtn setBackgroundImage:[UIImage imageNamed:@"res/button_pressed_background"] forState:UIControlStateHighlighted];
    [_sendBtn setBackgroundImage:[UIImage imageNamed:@"res/button_background"] forState:UIControlStateNormal];
    [_sendBtn addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];

    _msgEditor = [[UITextField alloc] init];
    _msgEditor.clearButtonMode = UITextFieldViewModeWhileEditing;
    _msgEditor.returnKeyType = UIReturnKeyDone;
    _msgEditor.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _msgEditor.borderStyle = UITextBorderStyleRoundedRect;
    _msgEditor.textColor = [UIColor whiteColor];
    _msgEditor.font = [UIFont systemFontOfSize:15];
    _msgEditor.backgroundColor = [UIColor colorFromHex:0xFF58CAB3];
    _msgEditor.frame = CGRectMake(5, _sendBtn.frame.origin.y,
                                  _sendBtn.frame.origin.x - 10,
                                  _sendBtn.frame.size.height);
    _msgEditor.delegate = self;
    [_msgEditor addTarget:self action:@selector(onMessageChanged) forControlEvents:UIControlEventEditingChanged];

    [_toolPanel addSubview:_panelBg];
    [_toolPanel addSubview:_emotBtn];
    if (![_attachImgBtn isHidden]) {
        [_toolPanel addSubview:_attachImgBtn];
    }
    if (![_takePhotoBtn isHidden]) {
        [_toolPanel addSubview:_takePhotoBtn];
    }
    [_toolPanel addSubview:_msgEditor];
    [_toolPanel addSubview:_sendBtn];

    rect = _toolPanel.frame;
    rect.size.height = _msgEditor.frame.origin.y + _msgEditor.frame.size.height + 5;
    rect.origin.y = self.view.frame.size.height - rect.size.height;
    _toolPanel.frame = rect;

    [self.view addSubview:_toolPanel];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _expectedViewHeight = 0;

    UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
    view.backgroundColor = [UIColor clearColor];
    self.view = view;

    self.resizeWhenKeyboardPresented = YES;

    self.quickDialogTableView.backgroundColor = [UIColor clearColor];
    self.quickDialogTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.quickDialogTableView.allowsMultipleSelectionDuringEditing = YES;
    [self.view addSubview:self.quickDialogTableView];

    [self createToolPanel];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onEmoteSelected:)
                                                 name:UCA_EVENT_EMOTE_SELECTED
                                               object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _imagePicker.delegate = nil;
    _photoTaker.delegate = nil;
}

- (void)registerRefreshListener {
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

- (void)deregisterRefreshListener {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_EVENT_ADD_MESSAGE
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_EVENT_UPDATE_MESSAGE
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_EVENT_UPDATE_MESSAGES
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_EVENT_DELETE_MESSAGES
                                                  object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerRefreshListener];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDetectedTyping:)
                                                 name:UCA_EVENT_TYPING
                                               object:nil];
    [self tryRefreshDataAndReload];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self deregisterRefreshListener];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_EVENT_TYPING
                                                  object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - selector methods

- (void)onDetectedTyping:(NSNotification *)note {
    Contact *contact = note.object;
    if (contact.id == [(Contact *)_contactObj id]) {
        // TODO: 显示typing提示动画，当收到对方下一条消息时，隐藏提示。
    } else if (contact.id == NOT_SAVED) {
        NSString *tip = [contact.displayName stringByAppendingString:I18nString(@"正在输入⋯⋯")];
        // TODO: show tip
    }
}

- (void)onEmoteSelected:(NSNotification *)note {
    NSString *emCode = note.object;
    NSString *text = _msgEditor.text;

    if ([_msgEditor isFirstResponder]) {
        [_msgEditor insertText:emCode];
    } else {
        _msgEditor.text = [text stringByAppendingString:emCode];
    }

    _sendBtn.enabled = YES;
}

- (void)scrollListToBottom {
    NSIndexPath *indexPath = nil;

    @synchronized (_messages) {
        if (_messages.count > 0) {
            indexPath = [NSIndexPath indexPathForRow:(_messages.count - 1)
                                           inSection:0];
        }
    }

    if (indexPath.row >= 0 && indexPath.row < [self.quickDialogTableView numberOfRowsInSection:indexPath.section]) {
        [self.quickDialogTableView scrollToRowAtIndexPath:indexPath
                                         atScrollPosition:UITableViewScrollPositionMiddle
                                                 animated:NO];
    }
}

- (void)resizeForKeyboard:(NSNotification *)note {
    NSDictionary *userInfo = [note userInfo];

    // get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;

    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    CGRect tabBarFrame = self.tabBarController.tabBar.frame;
    _expectedViewHeight = keyboardEndFrame.origin.y - self.navigationController.navigationBar.frame.size.height - statusBarFrame.size.height;
    if (keyboardEndFrame.origin.y > tabBarFrame.origin.y) {
        _expectedViewHeight -= tabBarFrame.size.height;
    }

    [UIView animateWithDuration:animationDuration delay:0 options:animationCurve
                     animations:^{
                         const CGRect rect = self.view.frame;
                         self.view.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, _expectedViewHeight);
                         [self performSelector:@selector(scrollListToBottom) withObject:nil afterDelay:SCROLL_DELAY];
                     }
                     completion:NULL];
}

- (void)markDeleting {
    self.quickDialogTableView.editing = YES;
    [self reloadTableView];
}

- (void)confirmDeleting {
    NSMutableArray *msgs = [NSMutableArray array];

    @synchronized (_messages) {
        NSArray *indexPathes = [self.quickDialogTableView indexPathsForSelectedRows];
        Message *msg;
        for (NSIndexPath *indexPath in indexPathes) {
            if (indexPath.row >= 0 && indexPath.row < _messages.count) {
                msg = [_messages objectAtIndex:indexPath.row];
                if (msg) {
                    [msgs addObject:msg];
                }
            }
        }
        self.quickDialogTableView.editing = NO;
    }

    if (msgs.count > 0) {
        [[UcaAppDelegate sharedInstance].messageService performSelectorInBackground:@selector(deleteMessages:) withObject:msgs];
    } else {
        [self reloadTableView];
    }
}

- (void)showEmotes {
    EmoteView *view = [[EmoteView alloc] init];
    [self.navigationController pushViewController:view animated:YES];
}

- (void)attachImage {
    [self.navigationController presentModalViewController:_imagePicker animated:YES];
}

- (void)takePhoto {
    [self.navigationController presentModalViewController:_photoTaker animated:YES];
}

- (Message *)buildOutMessage {
    NSString *sipPhone = nil;
    if ([_contactObj isKindOfClass:[Contact class]]) {
        sipPhone = [(Contact *)_contactObj sipPhone];
    } else if ([_contactObj isKindOfClass:[Group class]]) {
        sipPhone = [(Group *)_contactObj sipPhone];
    } else if ([_contactObj isKindOfClass:[Session class]]) {
        sipPhone = [(Session *)_contactObj sipPhone];
    }
    if ([NSString isNullOrEmpty:sipPhone]) {
        [NotifyUtils alert:I18nString(@"该联条人没有SIP电话，无法进行即时消息！")];
        return nil;
    }
    return [[Message alloc] initWithReceiverSipPhone:sipPhone];
}

- (void)sendMessage {
    if (_msgEditor.text.length > 0) {
        UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
        Message *msg = [self buildOutMessage];
        if (msg) {
            msg.html = _msgEditor.text;

            _msgEditor.text = nil;
            [_msgEditor resignFirstResponder];

            [app.messageService performSelectorInBackground:@selector(sendMessage:) withObject:msg];
        }
    }
}

- (void)onMessageChanged {
    [_sendBtn setEnabled:![NSString isNullOrEmpty:_msgEditor.text]];
}

- (void)showFullHtml:(MessageElement *)element {
    NSString *imgSrcPrefix = [NSString stringWithFormat:@"msg%d_", element.message.id];
    MessageViewer *viewer = [[MessageViewer alloc] initWithHtml:[[[[element fullHtml]
                                                                   replaceImgSrc:imgSrcPrefix]
                                                                  wrappedHtml]
                                                                 replaceEmoteCodeToIcon]
                                                       andTitle:[element senderAndTimeInfo]];
    [self.navigationController pushViewController:viewer animated:YES];
}

#pragma mark - MessageElementDelegate methods

- (void)messageElement:(MessageElement *)element clickedAccount:(NSInteger)accountId {
    // TODO: show account details
    UcaLog(TAG, @"messageElement %@ clickedAccount %d", element, accountId);
}

- (void)messageElement:(MessageElement *)element clickedContact:(NSInteger)contactId {
    // TODO: show contact details
    UcaLog(TAG, @"messageElement %@ clickedContact %d", element, contactId);
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.navigationController dismissModalViewControllerAnimated:YES];

    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];

    if (![NSString isNullOrEmpty:mediaType] && ![mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UcaLog(TAG, @"don't support send %@", mediaType);
        return;
    }

    Message *msg = [self buildOutMessage];
    if (msg) {
        msg.image = [info valueForKey:UIImagePickerControllerEditedImage];
        msg.imageName = [[info objectForKey:UIImagePickerControllerReferenceURL] lastPathComponent];
        msg.html = [NSString stringWithFormat:@"<img jt='true' src='%@'>", msg.imageName];

        [[UcaAppDelegate sharedInstance].messageService performSelectorInBackground:@selector(sendImageMessage:) withObject:msg];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    UcaAppDelegate *app = [UcaAppDelegate sharedInstance];
    UIViewController *view = nil;
    NSString *menuTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([menuTitle isEqualToString:MENU_ADD_MEMBER_FROM_ORG]) {
        app.orgService.addTarget = _contactObj;
        app.tabBarController.selectedIndex = 0; // 显示组织架构界面
    } else if ([menuTitle isEqualToString:MENU_ADD_MEMBER_FROM_FRIEND]) {
        view = [[ContactOperationListView alloc] initWithOperation:ContactListOperation_AddSessionMemberFromFriends
                                                        andSession:_contactObj];
    } else if ([menuTitle isEqualToString:MENU_ADD_MEMBER_FROM_RECENTS]) {
        view = [[ContactOperationListView alloc] initWithOperation:ContactListOperation_AddSessionMemberFromRecents
                                                        andSession:_contactObj];
    } else if ([menuTitle isEqualToString:MENU_CLOSE_SESSION]) {
        [app.sessionService performSelectorInBackground:@selector(closeSession:) withObject:[NSNumber numberWithInteger:[(Session *)_contactObj id]]];
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([menuTitle isEqualToString:MENU_DELETE_MESSAGE]) {
        [self markDeleting];
    }
    if (view) {
        [self.navigationController pushViewController:view animated:YES];
    }
}

@end
