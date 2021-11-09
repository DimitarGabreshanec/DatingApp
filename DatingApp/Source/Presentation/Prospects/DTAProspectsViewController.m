//
//  DTAProspectsViewController.m
//  DatingApp
//
//  Created by VLADISLAV KIRIN on 8/3/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import "DTAProspectsViewController.h"
#import "ProspectsCollectionViewCell.h"
#import "ProspectsTableViewCell.h"
#import "DTAProspectsPage.h"
#import "User.h"
#import "UserDetailedInfoViewController.h"
#import <CCBottomRefreshControl/UIScrollView+BottomRefreshControl.h>
#import "User+Extension.h"

static NSString * const kProspectsCollectionCellReuseIdentifier = @"ProspectsCollectionViewCellIdentifier";

@interface DTAProspectsViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UIImageView *bgImageView;
@property (weak, nonatomic) IBOutlet UILabel *matchesLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *people;
@property (strong, nonatomic) DTAProspectsPage *currentPage;
@property (assign, nonatomic) NSUInteger selectedUserIndex;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UILabel *infoLabel;

@end

@implementation DTAProspectsViewController

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

//    [self.collectionView addSubview:self.refreshControl];

    
    self.isLikesYou = NO;
    
    if(self.isLikesYou) {
        [self setupNavBarWithTitle:NSLocalizedString(@"Likes You", nil)];
        self.bgImageView.image = [UIImage imageNamed:@"L_U"];
    }
    else {
        [self setupNavBarWithTitle:NSLocalizedString(@"Matches", nil)];
        self.bgImageView.image = [UIImage imageNamed:@"M_U"];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateContent) name:UIApplicationWillEnterForegroundNotification object:nil];
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

#pragma mark - UICollectionViewDataSource
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedUserIndex = (NSUInteger) indexPath.row;
    [self performSegueWithIdentifier:toDetailedUserInfoSegue sender:self];
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.people.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ProspectsCollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:kProspectsCollectionCellReuseIdentifier forIndexPath:indexPath];

    User *fetchedUser = self.people[(NSUInteger) indexPath.row];
    [cell configureWithUser:fetchedUser];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((self.view.frame.size.width - 66)/2, (self.view.frame.size.width - 66)/2 * 245/172);
}

#pragma mark - IBActions

- (IBAction)tapOnMatchesButton:(UIButton *)sender {
    self.currentPage.pageNumber = @0;
 
    __weak typeof(self) weakSelf = self;
    
    APP_DELEGATE.hud = [[SAMHUDView alloc] initWithTitle:nil];
    [APP_DELEGATE.hud show];
    
    [DTAAPI fetchMatchedUsersOnPage:self.currentPage completion:^(NSError *error, NSArray *results) {
        if (!error) {
            weakSelf.people = results;
            [weakSelf.collectionView reloadData];
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
            [weakSelf.collectionView reloadData];
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
                [weakSelf.collectionView reloadData];
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
                [weakSelf.collectionView reloadData];
                [weakSelf setBgImageToTable];
            }
            [self.refreshControl endRefreshing];
        }];
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
        self.matchesLabel.text = [NSString stringWithFormat:@"%li matches", (long)self.people.count];
        self.bgImageView.image = [UIImage imageNamed:@""];
        self.infoLabel.text = @"";
    }
}

@end
