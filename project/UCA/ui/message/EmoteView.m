/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "EmoteView.h"
#import "UcaToolButton.h"

#define EMOTE_COUNT      90
#define PAGE_COUNT       4
#define COL_PER_PAGE     5
#define ROW_PER_PAGE     5
#define PAGE_CTRL_HEIGHT 30

@implementation EmoteView {
    NSMutableArray *_emoteButtons;
    UIScrollView *_scrollView;
    UIPageControl *_pageCtrl;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.delegate = self;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_scrollView];

    NSDictionary *emotes = [UcaAppDelegate sharedInstance].configService.emotes;
    _emoteButtons = [[NSMutableArray alloc] initWithCapacity:EMOTE_COUNT];

    for (int i = 0; i < EMOTE_COUNT; i++) {
        NSString *fname = [NSString stringWithFormat:@"%d.gif", i];
        NSString *emCode = [emotes valueForKey:fname];

        UcaToolButton *emBtn = [[UcaToolButton alloc] initWithTitle:emCode
                                                          imageName:[NSString stringWithFormat:@"res/emoticons/%@", fname]
                                                        bgImageName:@"res/chat_tool_button_pressed_background"];
        [emBtn addTarget:self action:@selector(onEmoteSelected:) forControlEvents:UIControlEventTouchUpInside];
        [_emoteButtons addObject:emBtn];
        [_scrollView addSubview:emBtn];
    }

    _pageCtrl = [[UIPageControl alloc] init];
    _pageCtrl.numberOfPages = PAGE_COUNT;
    _pageCtrl.currentPage = 0;
    [_pageCtrl addTarget:self action:@selector(pageTurn:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_pageCtrl];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    CGRect bounds = self.view.frame;

    _scrollView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);;
    _scrollView.contentSize = CGSizeMake(bounds.size.width * PAGE_COUNT, bounds.size.height);

    _pageCtrl.frame = CGRectMake(0, bounds.size.height - PAGE_CTRL_HEIGHT, bounds.size.width, PAGE_CTRL_HEIGHT);

    int colCount = COL_PER_PAGE;
    int rowCount = ROW_PER_PAGE;
    if (bounds.size.width > bounds.size.height) {
        colCount = ROW_PER_PAGE;
        rowCount = COL_PER_PAGE;
    }

    CGRect btnRect = CGRectMake(0, 0, bounds.size.width / colCount, (bounds.size.height - PAGE_CTRL_HEIGHT) / rowCount);
    for (int p = 0, i = 0; p < PAGE_COUNT; p++) {
        CGFloat pageLeft = p * bounds.size.width;
        for (int r = 0; r < rowCount; r++) {
            CGFloat rowTop = r * btnRect.size.height;
            for (int c = 0; c < colCount && i < EMOTE_COUNT; c++) {
                UcaToolButton *btn = [_emoteButtons objectAtIndex:i++];
                btnRect.origin.x = pageLeft + c * btnRect.size.width;
                btnRect.origin.y = rowTop;
                btn.frame = btnRect;
            }
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.frame;
    [_pageCtrl setCurrentPage:(offset.x / bounds.size.width)];
}

- (void)pageTurn:(UIPageControl *)pageControl {
    CGSize viewSize = _scrollView.frame.size;
    CGRect rect = CGRectMake(pageControl.currentPage * viewSize.width, 0, viewSize.width, viewSize.height);
    [_scrollView scrollRectToVisible:rect animated:YES];
}

- (void)onEmoteSelected:(UIButton *)button {
    NSString *emCode = [button titleForState:UIControlStateNormal];
    [NotifyUtils postNotificationWithName:UCA_EVENT_EMOTE_SELECTED object:emCode];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
