/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "GroupDetailsView.h"
#import "UcaDetailButton.h"

#define ITEM_MAX_WIDTH       260
#define ITEM_PADDING         5
#define SECTION_PADDING      10
#define SEC_ITEM_PADDING     2
#define BTN_WIDTH            ITEM_MAX_WIDTH
#define BTN_HEIGHT           32
#define MAX_MULTILINE_HEIGHT 200
#define MIN_MULTILINE_HEIGHT 50

@implementation GroupDetailsView {
    Group *_group;

    UIScrollView *_scrollView;
    UIImageView *_bgView;

    UIImageView *_headerBgView;
    UIImageView *_avatarView;
    UILabel *_lbName;
    UILabel *_lbNameVal;
    UILabel *_lbCreator;
    UILabel *_lbCreatorVal;
    UILabel *_lbUserCount;
    UILabel *_lbUserCountVal;

    UIImageView *_annunciateBgView;
    UILabel *_lbAnnunciate;
    UIView *_lbAnnunciateVal; // Could be UILabel or UITextView

    UIImageView *_descripBgView;
    UILabel *_lbDescrip;
    UILabel *_lbDescripVal;

    UIImageView *_otherBgView;
    UILabel *_lbCreateTime;
    UILabel *_lbCreateTimeVal;
    UILabel *_lbUserMaxCount;
    UILabel *_lbUserMaxCountVal;
    UILabel *_lbFileSpaceSize;
    UILabel *_lbFileSpaceSizeVal;
    UILabel *_lbType;
    UILabel *_lbTypeVal;

    UIBarButtonItem *_btnCommit;
    UIAlertView *_progressHud;
}

- (id)initWithGroup:(Group *)group {
    self = [super init];
    if (self) {
        _group = group;
        self.title = I18nString(@"群资料");
    }
    return self;
}

#pragma mark - View lifecycle

- (UIImageView *)setupBgView {
    UIImageView *v = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"res/detail_cell_background"] resizeFromCenter]];
    [_scrollView addSubview:v];
    return v;
}

- (void)setupSizeOfBgView:(UIImageView *)bgView bySubViewHeight:(CGFloat)height {
    CGRect rect = bgView.frame;
    rect.size = CGSizeMake(ITEM_MAX_WIDTH, height + ITEM_PADDING * 2);
    bgView.frame = rect;
}

- (void)setupSizeOfBgView:(UIImageView *)bgView bySubView:(UIView *)subView {
    [self setupSizeOfBgView:bgView bySubViewHeight:subView.frame.size.height];
}

- (UILabel *)setupInlineLabelViewWithTitle:(NSString *)txt {
    UILabel *v = [[UILabel alloc] init];
    v.backgroundColor = [UIColor clearColor];
    v.text = txt;
    v.font = [UIFont systemFontOfSize:16];
    v.textColor = [UIColor colorFromHex:0xFF96AC88];
    [v sizeToFit];
    [_scrollView addSubview:v];
    return v;
}

- (UILabel *)setupInlineValueViewWithTitle:(NSString *)txt {
    UILabel *v = [[UILabel alloc] init];
    v.backgroundColor = [UIColor clearColor];
    v.text = txt;
    v.font = [UIFont boldSystemFontOfSize:16];
    v.textColor = [UIColor colorFromHex:0xFF87A86B];
    [v sizeToFit];
    [_scrollView addSubview:v];
    return v;
}

- (UILabel *)setupOutLabelViewWithTitle:(NSString *)txt {
    return [self setupInlineValueViewWithTitle:txt];
}

- (void)setupMultilineViewHeight:(UIView *)v withFont:(UIFont *)font andTitle:(NSString *)txt {
    CGRect rect = v.frame;
    rect.size = [txt sizeWithFont:font constrainedToSize:CGSizeMake(ITEM_MAX_WIDTH - ITEM_PADDING * 2, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    if (rect.size.height > MAX_MULTILINE_HEIGHT) {
        rect.size.height = MAX_MULTILINE_HEIGHT;
    }
    if (rect.size.height < MIN_MULTILINE_HEIGHT) {
        rect.size.height = MIN_MULTILINE_HEIGHT;
    }
    v.frame = rect;
}

- (UILabel *)setupMultilineValueViewWithTitle:(NSString *)txt {
    UILabel *v = [[UILabel alloc] init];
    v.backgroundColor = [UIColor clearColor];
    v.text = txt;
    v.font = [UIFont systemFontOfSize:16];
    v.textColor = [UIColor colorFromHex:0xFF96AC88];
    v.numberOfLines = 0;

    [self setupMultilineViewHeight:v withFont:v.font andTitle:txt];
    [_scrollView addSubview:v];
    return v;
}

- (void)resizeScrollContent {
    CGRect rect = _bgView.frame;
    rect.size.height = CGRectGetMaxY(_otherBgView.frame) + (_bgView.frame.size.width - _headerBgView.frame.size.width) / 2 - rect.origin.y;
    _bgView.frame = rect;

    rect = _scrollView.frame;
    _scrollView.contentSize = CGSizeMake(rect.size.width, _bgView.frame.size.height + _bgView.frame.origin.y * 2);
}

-(UIToolbar *)createActionBar {
    UIToolbar *actionBar = [[UIToolbar alloc] init];
    actionBar.translucent = YES;
    [actionBar sizeToFit];
    actionBar.barStyle = UIBarStyleBlackTranslucent;

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:I18nString(@"隐藏键盘")
                                                                   style:UIBarButtonItemStyleDone target:self
                                                                  action:@selector(hideKeyboard:)];

    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [actionBar setItems:[NSArray arrayWithObjects:flexible, doneButton, nil]];
    return actionBar;
}

- (void)loadView {
    [super loadView];
    _btnCommit = [[UIBarButtonItem alloc] initWithTitle:I18nString(@"提交修改")
                                                  style:UIBarButtonItemStyleDone
                                                 target:self
                                                 action:@selector(commitModify:)];
    _progressHud = [NotifyUtils progressHud:I18nString(@"正在提交，请稍等⋯⋯")];

    CGRect rect;
    self.view.backgroundColor = [UIColor clearColor];

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.pagingEnabled = NO;
    _scrollView.bounces = NO;
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_scrollView];

    _bgView = [[UIImageView alloc] initWithImage:[UIImage detailBackground]];
    [_scrollView addSubview:_bgView];

    _headerBgView = [self setupBgView];
    UIImage *defaultAvatar = [UIImage imageNamed:@"res/group_info_default_avatar_small"];
    _avatarView = [[UIImageView alloc] initWithImage:defaultAvatar];
    if (_group.photo) {
        _avatarView.image = _group.photo;
    }
    rect = _avatarView.frame;
    rect.size = defaultAvatar.size;
    _avatarView.frame = rect;
    [self setupSizeOfBgView:_headerBgView bySubView:_avatarView];
    [_scrollView addSubview:_avatarView];

    _lbName = [self setupInlineLabelViewWithTitle:I18nString(@"群名称")];
    _lbNameVal = [self setupInlineValueViewWithTitle:_group.name];
    _lbCreator = [self setupInlineLabelViewWithTitle:I18nString(@"创建人")];
    _lbCreatorVal = [self setupInlineValueViewWithTitle:_group.creator];
    _lbUserCount = [self setupInlineLabelViewWithTitle:I18nString(@"总人数")];
    _lbUserCountVal = [self setupInlineValueViewWithTitle:[NSString stringWithFormat:@"%d", _group.userMaxAmount]];

    if ([_group canAdmin]) {
        _annunciateBgView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"res/detail_editor_background"] resizeFromCenter]];
        [_scrollView addSubview:_annunciateBgView];
    } else {
        _annunciateBgView = [self setupBgView];
    }
    _lbAnnunciate = [self setupOutLabelViewWithTitle:I18nString(@"群公告")];
    if ([_group canAdmin]) {
        UITextView *v = [[UITextView alloc] init];
        v.backgroundColor = [UIColor clearColor];
        v.text = _group.annunciate;
        v.font = [UIFont systemFontOfSize:16];
        v.textColor = [UIColor colorFromHex:0xFF96AC88];
        v.editable = YES;
        v.delegate = self;
        v.inputAccessoryView = [self createActionBar];

        [self setupMultilineViewHeight:v withFont:v.font andTitle:_group.annunciate];
        _lbAnnunciateVal = v;
        [_scrollView addSubview:v];
    } else {
        _lbAnnunciateVal = [self setupMultilineValueViewWithTitle:_group.annunciate];
    }
    [self setupSizeOfBgView:_annunciateBgView bySubView:_lbAnnunciateVal];

    _descripBgView = [self setupBgView];
    _lbDescrip = [self setupOutLabelViewWithTitle:I18nString(@"群简介")];
    _lbDescripVal = [self setupMultilineValueViewWithTitle:_group.descrip];
    [self setupSizeOfBgView:_descripBgView bySubView:_lbDescripVal];

    _otherBgView = [self setupBgView];
    _lbCreateTime = [self setupInlineLabelViewWithTitle:I18nString(@"创建时间")];
    _lbCreateTimeVal = [self setupInlineValueViewWithTitle:_group.createTime];
    _lbUserMaxCount = [self setupInlineLabelViewWithTitle:I18nString(@"最大人数")];
    _lbUserMaxCountVal = [self setupInlineValueViewWithTitle:[NSString stringWithFormat:@"%d", _group.userMaxAmount]];
    _lbFileSpaceSize = [self setupInlineLabelViewWithTitle:I18nString(@"文件空间大小")];
    _lbFileSpaceSizeVal = [self setupInlineValueViewWithTitle:[NSString stringWithFormat:@"%d", _group.fileSpaceSize]];
    _lbType = [self setupInlineLabelViewWithTitle:I18nString(@"类型")];
    _lbTypeVal = [self setupInlineValueViewWithTitle:_group.type];

    CGFloat height = MAX(_lbCreateTime.frame.size.height + _lbUserMaxCount.frame.size.height + _lbFileSpaceSize.frame.size.height + _lbType.frame.size.height,
                         _lbCreateTimeVal.frame.size.height + _lbUserMaxCountVal.frame.size.height + _lbFileSpaceSizeVal.frame.size.height + _lbTypeVal.frame.size.height)
                        + ITEM_PADDING * 3;
    [self setupSizeOfBgView:_otherBgView bySubViewHeight:height];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    CGRect rect = self.view.frame;

    _scrollView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);;

    rect = _bgView.frame;
    rect.origin.x = (_scrollView.frame.size.width - rect.size.width) / 2;
    rect.origin.y = rect.origin.x;
    _bgView.frame = rect;

    rect = _headerBgView.frame;
    rect.origin.x = _bgView.frame.origin.x + (_bgView.frame.size.width - rect.size.width) / 2;
    rect.origin.y = rect.origin.x;
    _headerBgView.frame = rect;

    rect = _avatarView.frame;
    rect.origin.x = _headerBgView.frame.origin.x + ITEM_PADDING;
    rect.origin.y = _headerBgView.frame.origin.y + (_headerBgView.frame.size.height - rect.size.height) / 2;
    _avatarView.frame = rect;

    rect = _lbName.frame;
    rect.origin.x = CGRectGetMaxX(_avatarView.frame) + ITEM_PADDING;
    rect.origin.y = _avatarView.frame.origin.y;
    _lbName.frame = rect;

    rect = _lbNameVal.frame;
    rect.origin.x = CGRectGetMaxX(_lbName.frame) + ITEM_PADDING;
    rect.origin.y = _lbName.frame.origin.y + (_lbName.frame.size.height - rect.size.height) / 2;
    rect.size.width = ITEM_MAX_WIDTH - (rect.origin.x - _headerBgView.frame.origin.x) - ITEM_PADDING;
    _lbNameVal.frame = rect;

    rect = _lbUserCount.frame;
    rect.origin.x = _lbName.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_avatarView.frame) - rect.size.height;
    _lbUserCount.frame = rect;

    rect = _lbUserCountVal.frame;
    rect.origin.x = _lbNameVal.frame.origin.x;
    rect.origin.y = _lbUserCount.frame.origin.y + (_lbUserCount.frame.size.height - rect.size.height) / 2;
    rect.size.width = _lbNameVal.frame.size.width;
    _lbUserCountVal.frame = rect;

    rect = _lbCreator.frame;
    rect.origin.x = _lbName.frame.origin.x;
    rect.origin.y = (_lbName.frame.origin.y + _lbUserCount.frame.origin.y) / 2;
    _lbCreator.frame = rect;

    rect = _lbCreatorVal.frame;
    rect.origin.x = _lbNameVal.frame.origin.x;
    rect.origin.y = _lbCreator.frame.origin.y + (_lbCreator.frame.size.height - rect.size.height) / 2;
    _lbCreatorVal.frame = rect;

    rect = _lbAnnunciate.frame;
    rect.origin.x = _headerBgView.frame.origin.x + ITEM_PADDING;
    rect.origin.y = CGRectGetMaxY(_headerBgView.frame) + SECTION_PADDING;
    _lbAnnunciate.frame = rect;

    rect = _annunciateBgView.frame;
    rect.origin.x = _headerBgView.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_lbAnnunciate.frame) + SEC_ITEM_PADDING;
    _annunciateBgView.frame = rect;

    rect = _lbAnnunciateVal.frame;
    rect.origin.x = _lbAnnunciate.frame.origin.x;
    rect.origin.y = _annunciateBgView.frame.origin.y + ITEM_PADDING;
    _lbAnnunciateVal.frame = rect;

    rect = _lbDescrip.frame;
    rect.origin.x = _lbAnnunciate.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_annunciateBgView.frame) + SECTION_PADDING;
    _lbDescrip.frame = rect;

    rect = _descripBgView.frame;
    rect.origin.x = _headerBgView.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_lbDescrip.frame) + SEC_ITEM_PADDING;
    _descripBgView.frame = rect;

    rect = _lbDescripVal.frame;
    rect.origin.x = _lbDescrip.frame.origin.x;
    rect.origin.y = _descripBgView.frame.origin.y + ITEM_PADDING;
    _lbDescripVal.frame = rect;

    rect = _otherBgView.frame;
    rect.origin.x = _headerBgView.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_descripBgView.frame) + SECTION_PADDING;
    _otherBgView.frame = rect;

    rect = _lbCreateTime.frame;
    rect.origin.x = _lbDescrip.frame.origin.x;
    rect.origin.y = _otherBgView.frame.origin.y + ITEM_PADDING;
    _lbCreateTime.frame = rect;

    rect = _lbUserMaxCount.frame;
    rect.origin.x = _lbDescrip.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_lbCreateTime.frame) + ITEM_PADDING;
    _lbUserMaxCount.frame = rect;

    rect = _lbFileSpaceSize.frame;
    rect.origin.x = _lbDescrip.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_lbUserMaxCount.frame) + ITEM_PADDING;
    _lbFileSpaceSize.frame = rect;

    rect = _lbType.frame;
    rect.origin.x = _lbDescrip.frame.origin.x;
    rect.origin.y = CGRectGetMaxY(_lbFileSpaceSize.frame) + ITEM_PADDING;
    _lbType.frame = rect;

    rect = _lbCreateTimeVal.frame;
    rect.origin.x = MAX(MAX(CGRectGetMaxX(_lbCreateTime.frame), CGRectGetMaxX(_lbUserMaxCount.frame)), MAX(CGRectGetMaxX(_lbFileSpaceSize.frame), CGRectGetMaxX(_lbType.frame))) + ITEM_PADDING;
    rect.origin.y = _lbCreateTime.frame.origin.y + (_lbCreateTime.frame.size.height - rect.size.height) / 2;
    _lbCreateTimeVal.frame = rect;

    rect = _lbUserMaxCountVal.frame;
    rect.origin.x = _lbCreateTimeVal.frame.origin.x;
    rect.origin.y = _lbUserMaxCount.frame.origin.y + (_lbUserMaxCount.frame.size.height - rect.size.height) / 2;
    _lbUserMaxCountVal.frame = rect;

    rect = _lbFileSpaceSizeVal.frame;
    rect.origin.x = _lbCreateTimeVal.frame.origin.x;
    rect.origin.y = _lbFileSpaceSize.frame.origin.y + (_lbFileSpaceSize.frame.size.height - rect.size.height) / 2;
    _lbFileSpaceSizeVal.frame = rect;

    rect = _lbTypeVal.frame;
    rect.origin.x = _lbCreateTimeVal.frame.origin.x;
    rect.origin.y = _lbType.frame.origin.y + (_lbType.frame.size.height - rect.size.height) / 2;
    _lbTypeVal.frame = rect;

    rect = _bgView.frame;
    rect.size.height = CGRectGetMaxY(_otherBgView.frame) + (_bgView.frame.size.width - _headerBgView.frame.size.width) / 2 - rect.origin.y;
    _bgView.frame = rect;

    rect = _scrollView.frame;
    _scrollView.contentSize = CGSizeMake(rect.size.width, _bgView.frame.size.height + _bgView.frame.origin.y * 2);
}

- (void)regesiterModifyListener {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onModifyOkay:)
                                                 name:UCA_INDICATE_MODIFY_GROUP_OKAY
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onModifyFail:)
                                                 name:UCA_INDICATE_MODIFY_GROUP_FAIL
                                               object:nil];
}

- (void)deregesiterModifyListener {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_MODIFY_GROUP_OKAY
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UCA_INDICATE_MODIFY_GROUP_FAIL
                                                  object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUserCount:)
                                                 name:UCA_INDICATE_GROUP_UPDATED
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (IBAction)commitModify:(id)btn {
    [_progressHud show];
    [self regesiterModifyListener];
    [[UcaAppDelegate sharedInstance].groupService modifyGroup:_group
                                            withNewAnnunciate:[(UITextView *)_lbAnnunciateVal text]];
}

- (IBAction)hideKeyboard:(id)btn {
    [(UITextView *)_lbAnnunciateVal resignFirstResponder];
}

- (void)onKeyboardWillShow:(NSNotification *)note {
    [_scrollView setContentOffset:CGPointMake(0, _lbAnnunciateVal.frame.origin.y) animated:YES];
}

- (void)updateUserCount:(NSNotification *)note {
    UcaGroupService *service = [UcaAppDelegate sharedInstance].groupService;
    _group = [service groupOfId:_group.id];
    _lbUserCountVal.text = [NSString stringWithFormat:@"%d", _group.userCount];
}

- (void)onModifyOkay:(NSNotification *)note {
    [self deregesiterModifyListener];
    [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
    [NotifyUtils alert:I18nString(@"修改成功！")];
    _group.annunciate = [(UITextView *)_lbAnnunciateVal text];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)onModifyFail:(NSNotification *)note {
    [self deregesiterModifyListener];
    [_progressHud dismissWithClickedButtonIndex:0 animated:YES];
    [NotifyUtils alert:I18nString(@"修改失败！请稍后重试。")];
}

#pragma UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem = ([textView.text isEqualToString:_group.annunciate] ? nil : _btnCommit);
}

@end
