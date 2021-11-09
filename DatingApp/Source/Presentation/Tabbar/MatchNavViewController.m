//
//  MatchNavViewController.m
//  DatingApp
//
//  Created by Smart Eye on 7/27/21.
//  Copyright © 2021 Cleveroad Inc. All rights reserved.
//

#import "MatchNavViewController.h"

@interface MatchNavViewController ()

@end

@implementation MatchNavViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITabBarItem *tabbarItem = [self tabBarItem];

    [tabbarItem setImage:[[UIImage imageNamed:@"t_match"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tabbarItem setSelectedImage:[[UIImage imageNamed:@"t_s_match"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
