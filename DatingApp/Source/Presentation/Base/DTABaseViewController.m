//
//  DTABaseViewController.m
//  DatingApp
//
//  Created by VLADISLAV KIRIN on 8/3/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import "DTABaseViewController.h"

NSString * const kLSSocketEventConnect = @"connected";
NSString * const kLSSocketEventHistory = @"chatHistory";
NSString * const kLSSocketEventMessage = @"chatMessage";
NSString * const kLSSocketEventOpen = @"chatOpen";
NSString * const kLSSocketTyping = @"typing";
NSString * const kLSSocketEventClearHistory = @"chatClearHistory";
NSString * const kLSSocketEventProfileRemoved = @"profileRemoved";
NSString * const kLSSocketEventProfileBlocked = @"profileBlocked";
NSString * const kLSSocketEventRemoveChatBlocked = @"chatRemoved";
NSString * const kLSSocketEventLastReadAt = @"chatLastReadAt";

@interface DTABaseViewController ()

@end

@implementation DTABaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setupNavBar {
    self.navigationController.navigationBar.barTintColor =  colorCreamCan;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName :[UIColor whiteColor]};
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
}

- (void)setupNavBarInvert {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault]; //UIImageNamed:@"transparent.png"
    self.navigationController.navigationBar.shadowImage = [UIImage new];////UIImageNamed:@"transparent.png"
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName :colorCreamCan};
}

- (void)setupNavBarWithTitle:(NSString *)title; {
    [self setupNavBar];
    self.navigationItem.title = title;
}

- (void)setupNavBarInvertWithTitle:(NSString *)title; {
    [self setupNavBarInvert];
    self.navigationItem.title = title;
}

- (void)setupBackButton {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)setupBackButtonInvert {
    [self setupBackButton];
    self.navigationController.navigationBar.tintColor = colorCreamCan;
}

@end
