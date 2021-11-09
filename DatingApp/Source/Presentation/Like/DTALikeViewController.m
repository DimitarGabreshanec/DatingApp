//
//  DTAProspectsViewController.m
//  DatingApp
//
//  Created by VLADISLAV KIRIN on 8/3/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import "DTALikeViewController.h"
#import "ProspectsTableViewCell.h"
#import "DTAProspectsPage.h"
#import "User.h"
#import "UserDetailedInfoViewController.h"
#import <CCBottomRefreshControl/UIScrollView+BottomRefreshControl.h>
#import "User+Extension.h"
#import "Location.h"


static NSString * const kProspectsCellReuseIdentifier = @"prospectsCell";

@interface DTALikeViewController () <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *bgImageView;
//@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *people;
@property (strong, nonatomic) DTAProspectsPage *currentPage;
@property (assign, nonatomic) NSUInteger selectedUserIndex;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (nonatomic) UIScrollView *scrollviewTop;
@property (nonatomic) UIScrollView *scrollviewBottom;

@end

@implementation DTALikeViewController

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];

        [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    }
    
    return _refreshControl;
}

- (DTAProspectsPage *)currentPage {
    if (!_currentPage) {
        _currentPage = [[DTAProspectsPage alloc] init];
    }
    
    return _currentPage;
}

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    self.navigationController.navigationBar.barTintColor = colorCreamCan;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    self.currentPage.pageNumber = @0;
    self.currentPage.pageLimit = @50;
    
    self.isLikesYou = NO;
    
//    [self.tableView addSubview:self.refreshControl]; // self.tableView.bottomRefreshControl = self.refreshControl;
    
    if(self.isLikesYou) {
        [self setupNavBarWithTitle:NSLocalizedString(@"Likes You", nil)];
        self.bgImageView.image = [UIImage imageNamed:@"L_U"];
    }
    else {
        [self setupNavBarWithTitle:NSLocalizedString(@"Matches", nil)];
        self.bgImageView.image = [UIImage imageNamed:@"M_U"];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateContent) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.scrollviewTop = [[UIScrollView alloc] initWithFrame:CGRectMake(25, 0, self.view.frame.size.width - 25, self.topView.frame.size.height)];
    self.scrollviewTop.pagingEnabled = YES;
    self.scrollviewTop.showsHorizontalScrollIndicator = NO;
    self.scrollviewTop.showsVerticalScrollIndicator = NO;
    self.scrollviewTop.scrollsToTop = NO;
    self.scrollviewTop.delegate = self;
    self.scrollviewTop.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.topView addSubview: self.scrollviewTop];
    
    self.scrollviewBottom = [[UIScrollView alloc] initWithFrame:CGRectMake(25, 0, self.view.frame.size.width - 25, self.bottomView.frame.size.height)];
    self.scrollviewBottom.pagingEnabled = YES;
    self.scrollviewBottom.showsHorizontalScrollIndicator = NO;
    self.scrollviewBottom.showsVerticalScrollIndicator = NO;
    self.scrollviewBottom.scrollsToTop = NO;
    self.scrollviewBottom.delegate = self;
    self.scrollviewBottom.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.bottomView addSubview: self.scrollviewBottom];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateContent];
}

- (void)updateContent {
    if (!self.isLikesYou) {
        [self tapOnMatchesButton:nil];
    }
    else {
        [self tapOnLikesYouButton:nil];
    }
    
    [self badgeUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (APP_DELEGATE.firstRun) {
        UINavigationController *loginVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DTARegisterNavigationControllerID"];
        loginVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:loginVC animated:YES completion:nil];
        APP_DELEGATE.firstRun = NO;
    }
    
    [self badgeUpdate];
}


- (void)badgeUpdate {
    DTAPushType pushType = self.isLikesYou ? DTAPushNewLikes : DTAPushNewMatchs;
    
    [DTAAPI badgeUpdateWithPushType:pushType сompletion:^(NSError *error) {
        if (self.isLikesYou) {
            [User currentUser].likesBadge = @0;
        } else {
            [User currentUser].matchesBadge = @0;
        }
        [UIApplication sharedApplication].applicationIconBadgeNumber = [[User currentUser].messagesBadge integerValue];
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:toDetailedUserInfoSegue]) {
        
        UserDetailedInfoViewController *destVC = segue.destinationViewController;
        
        destVC.detailedUser = self.people[self.selectedUserIndex];

        if (!self.isLikesYou) {
            //if from Matches
            destVC.hideButtons = DTAButtonsHideStateDislike + DTAButtonsHideStateLike;
        }
        else {
            // if from Likes You
            destVC.hideButtons = DTAButtonsHideStateChat;
        }
    }
}

#pragma mark - UITableViewDelegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    self.selectedUserIndex = (NSUInteger) indexPath.row;
//    [self performSegueWithIdentifier:toDetailedUserInfoSegue sender:self];
//}
//
//#pragma mark - UITableViewDataSource
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return self.people.count;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    ProspectsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kProspectsCellReuseIdentifier forIndexPath:indexPath];
//
//    User *fetchedUser = self.people[(NSUInteger) indexPath.row];
//    [cell configureWithUser:fetchedUser];
//
//    return cell;
//}

#pragma mark - IBActions

- (IBAction)tapOnMatchesButton:(UIButton *)sender {
    self.currentPage.pageNumber = @0;
 
    __weak typeof(self) weakSelf = self;
    
    APP_DELEGATE.hud = [[SAMHUDView alloc] initWithTitle:nil];
    [APP_DELEGATE.hud show];
    
    [DTAAPI fetchMatchedUsersOnPage:self.currentPage completion:^(NSError *error, NSArray *results) {
        if (!error) {
            weakSelf.people = results;
//            [weakSelf.tableView reloadData];
            [weakSelf setupUsers];
        
            [weakSelf setBgImageToTable];
        }
        
        [APP_DELEGATE.hud dismiss];
    }];
}

- (IBAction)tapOnLikesYouButton:(UIButton *)sender {
    self.currentPage.pageNumber = @0;
    __weak typeof(self) weakSelf = self;
  
    APP_DELEGATE.hud = [[SAMHUDView alloc] initWithTitle:nil];
    [APP_DELEGATE.hud show];
    
    [DTAAPI fetchMatchesOnPage:self.currentPage completion:^(NSError *error, NSArray *results) {
        if (!error) {
            weakSelf.people = results;
//            [weakSelf.tableView reloadData];
            [weakSelf setupUsers];
            
            [weakSelf setBgImageToTable];
        }
        
        [APP_DELEGATE.hud dismiss];
    }];
}

- (IBAction)refresh {
    if (!self.isLikesYou) {
        int value = [self.currentPage.pageNumber intValue];
        self.currentPage.pageNumber = @(value + 1);

        __weak typeof(self) weakSelf = self;
        
        [DTAAPI fetchMatchedUsersOnPage:self.currentPage completion:^(NSError *error, NSArray *results) {
            if (!error) {
                NSMutableArray *newUsers = [weakSelf.people mutableCopy];
                [newUsers addObjectsFromArray:results];
                
                weakSelf.people = newUsers;
//                [weakSelf.tableView reloadData];
                [weakSelf setupUsers];
                
                [weakSelf setBgImageToTable];
            }
            
            [self.refreshControl endRefreshing];
        }];
    }
    else {
        int value = [self.currentPage.pageNumber intValue];
        self.currentPage.pageNumber = @(value + 1);

        __weak typeof(self) weakSelf = self;
  
        [DTAAPI fetchMatchedUsersOnPage:self.currentPage completion:^(NSError *error, NSArray *results) {
            if (!error) {
                NSMutableArray *newUsers = [weakSelf.people mutableCopy];
                [newUsers addObjectsFromArray:results];
                
                weakSelf.people = newUsers;
//                [weakSelf.tableView reloadData];
                [weakSelf setupUsers];
                
                [weakSelf setBgImageToTable];
            }
            
            [self.refreshControl endRefreshing];
        }];
    }
}

- (void) setupUsers {
    NSInteger count = self.people.count;
    CGFloat widthTop = self.scrollviewTop.frame.size.height * 11/16;
    CGFloat heightTop = self.topView.frame.size.height;
    self.scrollviewTop.contentSize = CGSizeMake(widthTop * count + 20 * (count - 1), heightTop);
    
    CGFloat widthBottom = self.bottomView.frame.size.height * 0.55;
    CGFloat heightBottom = self.bottomView.frame.size.height;
    self.scrollviewBottom.contentSize = CGSizeMake(widthBottom * count + 16 * (count - 1), heightBottom);

    for (int i = 0; i < count; i++) {
        User *fetchedUser = self.people[i];
        
        UIView *contentTop = [[UIView alloc] initWithFrame: CGRectMake(i * (widthTop + 20) , 0, widthTop, heightTop)];
        UIImageView *imageTop = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, widthTop, heightTop)];
        imageTop.layer.cornerRadius = 30.0f;
        imageTop.clipsToBounds = YES;
        imageTop.contentMode = UIViewContentModeScaleAspectFill;
        [imageTop sd_setImageWithURL:[NSURL URLWithString:fetchedUser.avatar] placeholderImage:[UIImage imageNamed:@"drefaultImage"] options:SDWebImageDelayPlaceholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (error) {
                imageTop.image = [UIImage imageNamed:@"drefaultImage"];
            }
        }];
        
        UILabel *nameTop = [[UILabel alloc] initWithFrame:CGRectMake(20, heightTop - 110 , widthTop - 20, 28)];
        NSArray *words = [fetchedUser.firstName componentsSeparatedByString: @" "];
        NSString *firstName = [[NSString alloc] initWithString: words[0]];

        nameTop.text = [NSString stringWithFormat:@"%@, %li", firstName, (long)[fetchedUser userAge]];
        nameTop.clipsToBounds = YES;
        nameTop.backgroundColor = [UIColor clearColor];
        nameTop.textColor = [UIColor whiteColor];
        nameTop.textAlignment = NSTextAlignmentLeft;
//        nameTop.font = [UIFont fontWithName:@"Futura-Medium" size:18];
        nameTop.font = [UIFont systemFontOfSize:22 weight:UIFontWeightMedium];
        
        UILabel *locationTop = [[UILabel alloc] initWithFrame:CGRectMake(20, heightTop - 60 , widthTop - 20, 28)];
        locationTop.text = fetchedUser.location.locationTitle;
        locationTop.clipsToBounds = YES;
        locationTop.backgroundColor = [UIColor clearColor];
        locationTop.textColor = [UIColor whiteColor];
        locationTop.textAlignment = NSTextAlignmentLeft;
//        locationTop.font = [UIFont fontWithName:@"Futura-Medium" size:15];
        locationTop.font = [UIFont systemFontOfSize:15];
        
        [contentTop addSubview:imageTop];
        [contentTop addSubview:nameTop];
        [contentTop addSubview:locationTop];
        [self.scrollviewTop addSubview:contentTop];
        
        UIView *contentBottom = [[UIView alloc] initWithFrame: CGRectMake(i * (widthBottom + 16) , 0, widthBottom, heightBottom)];
        
        UIImageView *imageBottom = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, widthBottom, widthBottom * 1.36)];
        imageBottom.layer.cornerRadius = 8.0f;
        imageBottom.clipsToBounds = YES;
        imageBottom.contentMode = UIViewContentModeScaleAspectFill;
        [imageBottom sd_setImageWithURL:[NSURL URLWithString:fetchedUser.avatar] placeholderImage:[UIImage imageNamed:@"drefaultImage"] options:SDWebImageDelayPlaceholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (error) {
                imageBottom.image = [UIImage imageNamed:@"drefaultImage"];
            }
        }];
        
        UILabel *nameBottom = [[UILabel alloc] initWithFrame:CGRectMake(0, widthBottom * 1.36 + 4 , widthBottom, 16)];        
        nameBottom.text = [NSString stringWithFormat:@"%@", firstName];
        nameBottom.clipsToBounds = YES;
        nameBottom.backgroundColor = [UIColor clearColor];
        nameBottom.textColor = [UIColor blackColor];
        nameBottom.textAlignment = NSTextAlignmentCenter;
//        nameBottom.font = [UIFont fontWithName:@"Futura-Medium" size:14];
        nameBottom.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        
        UILabel *locationBottom = [[UILabel alloc] initWithFrame:CGRectMake(0, widthBottom * 1.36 + 26 , widthBottom, 16)];
//        locationBottom.text = fetchedUser.location.locationTitle;
        locationBottom.text = @"16 miles";
        locationBottom.clipsToBounds = YES;
        locationBottom.backgroundColor = [UIColor clearColor];
        locationBottom.textColor = [UIColor lightGrayColor];
        locationBottom.textAlignment = NSTextAlignmentCenter;
//        locationBottom.font = [UIFont fontWithName:@"Futura-Medium" size:12];
        locationBottom.font = [UIFont systemFontOfSize:10];
        
        [contentBottom addSubview:imageBottom];
        [contentBottom addSubview:nameBottom];
        [contentBottom addSubview:locationBottom];
        [self.scrollviewBottom addSubview:contentBottom];
    }
}

- (void)setBgImageToTable {
    if(self.people.count == 0) {
        if(!self.isLikesYou) {
            self.bgImageView.image = [UIImage imageNamed:@"M_U"];
            self.infoLabel.text = @"no matches...";
        }
        else {
            self.bgImageView.image = [UIImage imageNamed:@"L_U"];
            self.infoLabel.text = @"no likes...";
        }
    }
    else {
        self.bgImageView.image = [UIImage imageNamed:@""];
        self.infoLabel.text = @"";
    }
}

@end
