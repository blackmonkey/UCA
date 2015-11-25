/**
 * Copyright (C) 2012, Bohao Technology Ltd. All rights reserved.
 * Copyright (C) 2012, Maipu Communication Technology Co., Ltd. All rights reserved
 */

#import <Foundation/Foundation.h>

@class ContactElement;

@protocol ContactElementDelegate <NSObject>

@optional
- (void)contactElementOnClicked:(ContactElement *)element;
- (void)contactElementAvatarOnClicked:(Contact *)contact;
- (void)contactElementImOnClicked:(Contact *)contact;
- (void)contactElementCamOnClicked:(Contact *)contact;
- (void)contactElementPhoneOnClicked:(ContactElement *)element;

@end

@interface ContactElement : QRootElement

@property (nonatomic, retain) Contact *contact;

- (id)initWithContact:(Contact *)_contact andDelegate:(id<ContactElementDelegate>)delegate;

@end
