/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import "MessageViewer.h"

@implementation MessageViewer {
    NSString *_html;
    UIWebView *_webView;
}

- (id)initWithHtml:(NSString *)html andTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _html = html;
        self.title = title;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];

    _webView = [[UIWebView alloc] init];
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    [_webView loadHTMLString:_html
                     baseURL:[UcaAppDelegate sharedInstance].configService.imBaseUrl];
    [self.view addSubview:_webView];
}

- (void)viewDidUnload {
    _html = nil;
    _webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [[UcaAppDelegate sharedInstance] shouldAutorotateToInterfaceOrientation:orientation];
}

@end
