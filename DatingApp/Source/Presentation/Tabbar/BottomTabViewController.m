//
//  BottomTabViewController.m
//  DatingApp
//
//  Created by Smart Eye on 7/27/21.
//  Copyright © 2021 Cleveroad Inc. All rights reserved.
//

#import "BottomTabViewController.h"
#import "LikeNavViewController.h"

@interface BottomTabViewController ()

@end

@implementation BottomTabViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITabBar *tabbar = self.tabBar;
    UITabBarItem *tabBarItem0 = [tabbar.items objectAtIndex:0];
    UITabBarItem *tabBarItem1 = [tabbar.items objectAtIndex:1];
    UITabBarItem *tabBarItem2 = [tabbar.items objectAtIndex:2];
    UITabBarItem *tabBarItem3 = [tabbar.items objectAtIndex:3];
    UITabBarItem *tabBarItem4 = [tabbar.items objectAtIndex:4];
    
    [tabBarItem0 setImage:[[UIImage imageNamed:@"t_like"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tabBarItem0 setSelectedImage:[[UIImage imageNamed:@"t_s_like"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    [tabBarItem1 setImage:[[UIImage imageNamed:@"t_match"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tabBarItem1 setSelectedImage:[[UIImage imageNamed:@"t_s_match"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    [tabBarItem2 setImage:[[UIImage imageNamed:@"t_browse"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tabBarItem2 setSelectedImage:[[UIImage imageNamed:@"t_s_browse"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    [tabBarItem3 setImage:[[UIImage imageNamed:@"t_conversation"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tabBarItem3 setSelectedImage:[[UIImage imageNamed:@"t_s_conversation"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    [tabBarItem4 setImage:[[UIImage imageNamed:@"t_setting"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [tabBarItem4 setSelectedImage:[[UIImage imageNamed:@"t_s_setting"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];

    [self setSelectedIndex: 2];
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
