//
//  DTABaseViewController.h
//  DatingApp
//
//  Created by VLADISLAV KIRIN on 8/3/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

extern NSString * const kLSSocketTyping;
extern NSString * const kLSSocketEventConnect;
extern NSString * const kLSSocketEventHistory;
extern NSString * const kLSSocketEventMessage;
extern NSString * const kLSSocketEventOpen;
extern NSString * const kLSSocketEventClearHistory;
extern NSString * const kLSSocketEventProfileRemoved;
extern NSString * const kLSSocketEventProfileBlocked;
extern NSString * const kLSSocketEventRemoveChatBlocked;
extern NSString * const kLSSocketEventLastReadAt;

@interface DTABaseViewController : UIViewController

- (void)setupNavBar;
- (void)setupNavBarInvert;

- (void)setupNavBarWithTitle:(NSString *)title;
- (void)setupNavBarInvertWithTitle:(NSString *)title;

- (void)setupBackButton;
- (void)setupBackButtonInvert;

@end
