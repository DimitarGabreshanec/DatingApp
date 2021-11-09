//
//  DTABrowseViewController.m
//  DatingApp
//
//  Created by VLADISLAV KIRIN on 8/3/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import "DTABrowseViewController.h"
#import "User+Extension.h"
#import "UserDetailedInfoViewController.h"
#import "DTAImageViewController.h"
#import "DTASearchOptionsManager.h"
#import "DTALocationManager.h"
#import "DTAAdditionalInfoViewController.h"
#import "DTAMenuViewController.h"
#import "NSString+Email.h"
#import "DTASwipeImages.h"
#import "DTABackView.h"
#import "DTAReportView.h"
#import "DTARegisterViewController.h"
#import "DTASearchOptionsViewController.h"
#import "Session+Extensions.h"
#import "SubscriptionVC.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "DTAEditProfileViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface DTABrowseViewController () <DTAAdditionalInfoDelgate, DTAReportViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userNameAndAgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *userLastActiveLabel;
@property (weak, nonatomic) IBOutlet UILabel *userPhotosCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *browseLikeSwipeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *browseDislikeSwipeImageView;

@property (nonatomic, weak) IBOutlet UIButton* infoButton;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *placeholderView;
@property (weak, nonatomic) IBOutlet UIView *noPhotosView;
@property (nonatomic, weak) IBOutlet DTASwipeImages *swipeImages;

@property (strong, nonatomic) NSArray *browsingUsers;
@property (nonatomic, strong) DTALocationManager *locationManager;
@property (nonatomic, strong) DTAAdditionalInfoViewController *containerInfo;
@property (nonatomic, assign) BOOL presentInfo;
@property (assign, nonatomic) NSUInteger currentUserIndex;
@property (assign, atomic, getter=isNetworkRequestProcessing) BOOL networkRequestProcessing;
@property (nonatomic, strong) NSDictionary *lastSearchParams;

@property (strong, nonatomic) DTAReportView *reportView;
@property (nonatomic, strong) UIView *hiddenView;
@property (nonatomic, strong) DTABackView *backItemView;
@property (nonatomic, strong) UIBarButtonItem *menuButton;
@property (nonatomic, strong) UIBarButtonItem *rightButton;

@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *unLikeButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *containerHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *containerViewTopSpacingConstraint;

// SmartEye 15/10/2020
@property (weak, nonatomic) IBOutlet UIButton *previewButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (nonatomic, strong) UIBarButtonItem *rewindButton;

@end

@implementation DTABrowseViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    self.navigationController.navigationBar.barTintColor = colorWhite;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName :[UIColor blackColor]};
//    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    self.menuButton = self.navigationItem.leftBarButtonItem;
    
    self.backItemView = [[[NSBundle mainBundle] loadNibNamed:@"DTABackView" owner:self options:nil] objectAtIndex:0];
    [self.backItemView addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    
    self.swipeImages.scrollEnabled = NO;
    [self.swipeImages hidePageControl];
    
    self.currentUserIndex = 0;
    self.containerHeight.constant = 0.0;
    
    [self.view layoutIfNeeded];
    
    self.containerInfo = self.childViewControllers.firstObject;
    self.containerInfo.delegate = self;
    
    self.placeholderView.hidden = NO;
    
    self.swipeImages.layer.cornerRadius = 20;
    self.swipeImages.layer.masksToBounds = true;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //DEV
    [self getUserSubscriptionStatus];
    
    if (APP_DELEGATE.firstRun) {
        
        APP_DELEGATE.firstRun = NO;
        if ([User currentUser].userId) {
            User *user = [User currentUser];
            
            NSLog(@"available");
            if([User currentUser].session.accessToken.length > 0) {
                APP_DELEGATE.accessToken = [NSString stringWithFormat:@"%@?accessToken=%@", DTAAPIServerHostname, [User currentUser].session.accessToken];
            }
            
            if (user.isFull){
                
            } else {
                NSLog(@"not Full available");
                
                DTAEditProfileViewController *editVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DTAEditProfileViewControllerID"];
                editVC.modalPresentationStyle = UIModalPresentationFullScreen;
                editVC.isFromRegisterVC = YES;
                [self presentViewController:editVC animated:YES completion:nil];
                
                APP_DELEGATE.firstRun = NO;
            }            
        } else {
            NSLog(@"not available");

            UINavigationController *loginVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DTARegisterNavigationControllerID"];
            loginVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:loginVC animated:YES completion:nil];
            APP_DELEGATE.firstRun = NO;
        }
    }
    
    if (!self.hiddenView) {
        self.hiddenView = [[UIView alloc] initWithFrame:self.view.frame];
        [self.hiddenView setBackgroundColor:[UIColor clearColor]];
    }
    
    //if ([self.lastSearchParams isEqualToDictionary:[[DTASearchOptionsManager sharedManager] browsingParameters]]) {
    //    [self navigateToUserAtIndex:self.currentUserIndex animated:NO];
    //}
    //else {
        self.currentUserIndex = 0;
        self.browsingUsers = nil;
        self.lastSearchParams = [[DTASearchOptionsManager sharedManager] browsingParameters];
        [self navigateToUserAtIndex:self.currentUserIndex animated:NO];
    //}
    
    if (self.containerHeight.constant == 0) {
        self.containerViewTopSpacingConstraint.constant = SCREEN_HEIGHT - STATUS_BAR_HEIGHT  - self.navigationController.navigationBar.frame.size.height - self.swipeImages.frame.size.height;
    }
    
    // SmartEye 15/10/2020
    [self showPrevForwardButtons];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].applicationIconBadgeNumber = [[User currentUser].messagesBadge integerValue];
}

- (NSArray *)browsingUsers {
    if (!_browsingUsers) {
        _browsingUsers = [[NSArray alloc] init];
    }
    
    return _browsingUsers;
}

- (void)blockUi {
    [self.view addSubview:self.hiddenView];
}

- (void)unblockUi {
    [self.hiddenView removeFromSuperview];
}

- (void)updateLocation {
    self.locationManager = nil;
    self.locationManager = [DTALocationManager new];

    [self.locationManager trackLocationWithCompletionBlock:^(CLLocation *location) {
        if(location) {
            [DTAAPI profileUpdateLocationWithLocation:location];
        }
    }];
}

// SmartEye 15/10/2020
- (void)showPrevForwardButtons {
//    __weak typeof(self) weakSelf = self;    
    if (self.currentUserIndex == 0) {
        self.previewButton.hidden = YES;
        self.forwardButton.hidden = NO;
    } else if (self.currentUserIndex == self.browsingUsers.count) {
        self.previewButton.hidden = NO;
        self.forwardButton.hidden = YES;
    } else {
        self.previewButton.hidden = NO;
        self.forwardButton.hidden = NO;
    }
    self.forwardButton.hidden = YES;
}

#pragma mark - IBActions

//220 320
- (IBAction)pressPhotoButton:(id)sender
{
    if (!IS_HOST_REACHABLE) {
        SHOWALLERT(NSLocalizedString(DTAInternetConnectionFailedTitle, nil), NSLocalizedString(DTAInternetConnectionFailed, nil));
    }
    else {
        [self performSegueWithIdentifier:@"presentImageViewController" sender:self];
    }
}

- (IBAction)pressSearchButton:(id)sender {
    self.rightButton = self.navigationItem.rightBarButtonItem;
    //[self back];
    
    DTASearchOptionsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DTASearchOptionsViewControllerID"];
    vc.fromHome = @"1";
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)tapOnLikeButton:(UIButton *)sender {
    dispatch_time_t highlightDelay = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    
    dispatch_after(highlightDelay, dispatch_get_main_queue(), ^(void) {
        [sender setHighlighted:YES];
    });
    
    dispatch_time_t highlightTime = dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC);
  
    dispatch_after(highlightTime, dispatch_get_main_queue(), ^(void) {
        [sender setHighlighted:NO];
    });
    
    [self swipeDislike:nil];
}

- (void)pressLikeButton {
    [self back];
    [self tapOnLikeButton:nil];
}

- (void)pressDislikeButton {
    [self back];
    [self tapOnDislikeButton:nil];
}

- (IBAction)tapOnInfoButton:(UIButton *)sender {
    
    self.rightButton = self.navigationItem.rightBarButtonItem;
       
    UIBarButtonItem *reportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bt_report"] style:UIBarButtonItemStylePlain target:self action:@selector(pressReportButton:)];
    self.navigationItem.rightBarButtonItem = reportButton;
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:self.backItemView];
    
    if (self.currentUserIndex == 0 ){
        self.navigationItem.leftBarButtonItem = backItem;
    } else {
        if (@available(iOS 13.0, *)) {
            self.rewindButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.backward.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(pressRewindButton:)];
        } else {
            self.rewindButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bt_back_circle_w"] style:UIBarButtonItemStylePlain target:self action:@selector(pressRewindButton:)];
        }
        self.navigationItem.leftBarButtonItems = @[backItem, self.rewindButton];
    }
        
    self.swipeImages.scrollEnabled = YES;
    [self.swipeImages showPageControl];
    self.title = @"Info";
    self.presentInfo = YES;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.infoButton.alpha = 0;
        self.likeButton.alpha = 0;
        self.unLikeButton.alpha = 0;
        self.nameView.alpha = 0;
        self.userLastActiveLabel.alpha = 0;
        
        // SmartEye
        self.previewButton.alpha = 0;
        self.forwardButton.alpha = 0;
    }];
    
    [self.containerInfo reloadUserDataFromUserModel:self.browsingUsers[self.currentUserIndex]];
    
    self.containerViewTopSpacingConstraint.constant = 15.0f;
    [self.view layoutSubviews];
    
    self.containerHeight.constant = self.containerInfo.rootScroll.contentSize.height + 20.0f;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
        [self.swipeImages layoutIfNeeded];
    }];
}

- (void)pressRewindButton:(id)sender {
    if (self.currentUserIndex > 0){
        [self navigateToUserAtIndex:--self.currentUserIndex animated:YES];

        [self.containerInfo reloadUserDataFromUserModel:self.browsingUsers[self.currentUserIndex]];
        
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:self.backItemView];
        
        if (self.currentUserIndex == 0 ){
            self.navigationItem.leftBarButtonItems = @[backItem];
        }
    } else {
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:self.backItemView];
        self.navigationItem.leftBarButtonItems = @[backItem];
    }
}

- (IBAction)tapOnDislikeButton:(UIButton *)sender {
    dispatch_time_t highlightDelay = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    
    dispatch_after(highlightDelay, dispatch_get_main_queue(), ^(void) {
        [sender setHighlighted:YES];
    });
    
    dispatch_time_t highlightTime = dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC);
   
    dispatch_after(highlightTime, dispatch_get_main_queue(), ^(void) {
        [sender setHighlighted:NO];
    });
    
    [self swipeLike:nil];
}

- (IBAction)onUserProfilePhotoTap:(UITapGestureRecognizer *)sender {
    [self pressPhotoButton:nil];
}

- (IBAction)swipeLike:(id)sender {
    if(!self.presentInfo) {
        [self onUserPhotoLeftSwipe:nil];
    }
}

- (IBAction)swipeDislike:(id)sender {
    if(!self.presentInfo) {
        [self onUserPhotoRightSwipe:nil];
        
    }
}

- (IBAction)onUserPhotoLeftSwipe:(UISwipeGestureRecognizer *)sender {
    static const NSUInteger xOffset = 40;
    
    if (!self.isNetworkRequestProcessing) {
        CGRect beforeAnimationsFrame = self.browseDislikeSwipeImageView.frame;
        
        self.networkRequestProcessing = YES;
        __weak typeof(self) weakSelf = self;
     
        [UIView animateWithDuration:0.3 delay:0.1 options:(UIViewAnimationOptions) UIViewAnimationCurveEaseInOut animations:^{
             weakSelf.browseDislikeSwipeImageView.alpha = 1;
       
             weakSelf.browseDislikeSwipeImageView.frame = CGRectMake(weakSelf.view.center.x - xOffset, beforeAnimationsFrame.origin.y, beforeAnimationsFrame.size.width, beforeAnimationsFrame.size.height);
             
         } completion:^(BOOL finished) {
             if (finished) {
                 [UIView animateWithDuration:0.3 animations:^{
                      weakSelf.browseDislikeSwipeImageView.alpha = 0.5;
                      weakSelf.browseDislikeSwipeImageView.alpha = 0.1;
                      
                  } completion:^(BOOL finished) {
                      weakSelf.browseDislikeSwipeImageView.alpha = 0;
                      weakSelf.browseDislikeSwipeImageView.frame = beforeAnimationsFrame;
                      
                      [weakSelf dislikeUserAtIndex:weakSelf.currentUserIndex withCompletion:^{
                           weakSelf.networkRequestProcessing = NO;
                           [weakSelf navigateToUserAtIndex:++weakSelf.currentUserIndex animated:YES];
                       }];
                  }];
             }
         }];
    }
}

- (IBAction)onUserPhotoRightSwipe:(UISwipeGestureRecognizer *)sender {
    static const NSUInteger xOffset = 40;
    if (!self.isNetworkRequestProcessing) {
        CGRect beforeAnimationsFrame = self.browseLikeSwipeImageView.frame;
    
        self.networkRequestProcessing = YES;
        __weak typeof(self) weakSelf = self;
        
        [UIView animateWithDuration:0.3 delay:0.3 options:(UIViewAnimationOptions) UIViewAnimationCurveEaseInOut animations:^{
             weakSelf.browseLikeSwipeImageView.alpha = 1;
             weakSelf.browseLikeSwipeImageView.frame = CGRectMake(weakSelf.view.center.x - xOffset, beforeAnimationsFrame.origin.y, beforeAnimationsFrame.size.width, beforeAnimationsFrame.size.height);
            
         } completion:^(BOOL finished) {
             if (finished) {
                 [UIView animateWithDuration:0.3 animations:^{
                      weakSelf.browseLikeSwipeImageView.alpha = 0.5;
                      weakSelf.browseLikeSwipeImageView.alpha = 0.1;
                      
                  } completion:^(BOOL finished) {
                      weakSelf.browseLikeSwipeImageView.alpha = 0;
                      weakSelf.browseLikeSwipeImageView.frame = beforeAnimationsFrame;
                      
                      [weakSelf likeUserAtIndex:weakSelf.currentUserIndex withCompletion:^{
                           weakSelf.networkRequestProcessing = NO;
                           [weakSelf navigateToUserAtIndex:++weakSelf.currentUserIndex animated:YES];
                       }];
                  }];
             }
         }];
    }
}

// SmartEye 15/10/2020
- (IBAction)tapPreviewButton:(UIButton *)sender {
    dispatch_time_t highlightDelay = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
      
      dispatch_after(highlightDelay, dispatch_get_main_queue(), ^(void) {
          [sender setHighlighted:YES];
      });
      
      dispatch_time_t highlightTime = dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC);
    
      dispatch_after(highlightTime, dispatch_get_main_queue(), ^(void) {
          [sender setHighlighted:NO];
      });
    
    [self navigateToUserAtIndex:--self.currentUserIndex animated:YES];
}

- (IBAction)tapForwardButton:(UIButton *)sender {
    dispatch_time_t highlightDelay = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(highlightDelay, dispatch_get_main_queue(), ^(void) {
          [sender setHighlighted:YES];
      });
      
    dispatch_time_t highlightTime = dispatch_time(DISPATCH_TIME_NOW, 0.6 * NSEC_PER_SEC);
    dispatch_after(highlightTime, dispatch_get_main_queue(), ^(void) {
          [sender setHighlighted:NO];
      });
    
    [self navigateToUserAtIndex:++self.currentUserIndex animated:YES];
}

#pragma mark - DTABackViewDelegate methods

- (void)didTapOnBackView:(DTABackView *)backView {
    [self back];
}

#pragma mark - DTAReportView Delegate

- (void)proceedReportWithText:(NSString *)text image:(UIImage *)image {
    APP_DELEGATE.hud = [[SAMHUDView alloc] init];
    [APP_DELEGATE.hud show];
    
    __weak typeof(self) weakSelf = self;
    
    [DTAAPI reportUser:self.browsingUsers[self.currentUserIndex] reportText:text attachedImage:image completion:^(NSError *error) {
        if (!error) {
            [self.reportView dismissReportView];
            self.reportView = nil;
            
            [APP_DELEGATE.hud completeAndDismissWithTitle:nil];
        }
        else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"error" message:error.userInfo[@"message"] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
            
            [alert addAction:okAction];
            
            [weakSelf presentViewController:alert animated:YES completion:nil];
            
            [APP_DELEGATE.hud dismiss];
        }
    }];
}

- (void)cancelButtonPressed:(id)sender {
    self.reportView = nil;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:toDetailedUserInfoSegue]) {
        UserDetailedInfoViewController *destVC = segue.destinationViewController;
        
        if (self.currentUserIndex < self.browsingUsers.count) {
            destVC.detailedUser = self.browsingUsers[self.currentUserIndex];
        }
    }
    
    if ([segue.identifier isEqualToString:@"presentImageViewController"]) {
        DTAImageViewController *destVC = segue.destinationViewController;
    
        if (self.currentUserIndex < self.browsingUsers.count) {
            destVC.imageArray = (NSArray *)[self.browsingUsers[self.currentUserIndex] image];
            destVC.startImageIndex = self.swipeImages.currentImageIndex;
        }
    }
}

#pragma mark - Private

- (void)back {
    self.navigationItem.rightBarButtonItem = self.rightButton;
    
    [self.reportView dismissReportView];
    self.reportView = nil;
    
    self.swipeImages.scrollEnabled = NO;
    
    [self.swipeImages hidePageControl];
    self.presentInfo = NO;

//    self.navigationItem.leftBarButtonItem = self.menuButton;
    self.navigationItem.leftBarButtonItems = @[self.menuButton];
    self.title = @"Discover";
    
//   [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    __weak typeof(self) weakSelf = self;
    
    float duration = 0.0f;
    
    if(self.scrollView.contentOffset.y > 0) {
        duration = 0.2;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^ {
        
        weakSelf.containerViewTopSpacingConstraint.constant = SCREEN_HEIGHT - STATUS_BAR_HEIGHT - weakSelf.navigationController.navigationBar.frame.size.height - weakSelf.swipeImages.frame.size.height;
        
        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.infoButton.alpha = 1.0;
            weakSelf.likeButton.alpha = 1.0;
            weakSelf.unLikeButton.alpha = 1.0;
            weakSelf.nameView.alpha = 1.0;
            weakSelf.userLastActiveLabel.alpha = 1.0;
            
            // SmartEye
            weakSelf.previewButton.alpha = 1.0;
            weakSelf.forwardButton.alpha = 1.0;
            
            [weakSelf.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            weakSelf.containerHeight.constant = 0.0;
            [weakSelf.view layoutSubviews];
        }];
    });
}

- (void)pressReportButton:(id)sender {
    if (!self.reportView) {
        self.reportView = [DTAReportView showInView:self.view delegate:self];
    }
}

-(void)presentIAPView {
    SubscriptionVC *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SubscriptionVC"];
    [self presentViewController:vc animated:YES completion:nil];
}
-(void)getUserSubscriptionStatus {

    if ([User currentUser].userId) {
        [DTAAPI getUserSubscriptonStaus:[User currentUser].userId completion:^(NSError *error, NSArray *dataArr) {
            if (!error) {
            }
        }];
    }
    
}

- (void)likeUserAtIndex:(NSUInteger)index withCompletion:(void (^)(void))completion {
    
    NSLog(@"like user");
    NSInteger count = [[NSUserDefaults standardUserDefaults]integerForKey:@"matchCount"];
//    BOOL isSubsribed = [[NSUserDefaults standardUserDefaults]boolForKey:@"isSubsribed"];
//    if (!isSubsribed) {
//        if (count < 10) {
//            if (index < self.browsingUsers.count) {
//
//                [self blockUi];
//                User *user = self.browsingUsers[index];
//
//                [DTAAPI matchUser:user completion:^(NSError *error, NSArray *responseArr) {
//
//                    [[NSUserDefaults standardUserDefaults]setObject:[responseArr objectAtIndex:0] forKey:@"matchCount"];
//                    [[NSUserDefaults standardUserDefaults]synchronize];
//
//                    NSLog(@"browse matched count value in match user =====>> %@", responseArr);
//
//                    if (!error) {
//                        completion();
//                    }
//
//                    [self unblockUi];
//                }];
//            }
//        }
//        else {
//            [self presentIAPView];
//        }
//    }
//    else {
        NSLog(@"user now have the plan and count restrriction removed");
        if (index < self.browsingUsers.count) {
            [self blockUi];
            User *user = self.browsingUsers[index];
            
            [DTAAPI matchUser:user completion:^(NSError *error, NSArray *responseArr) {
                
                [[NSUserDefaults standardUserDefaults]setObject:[responseArr objectAtIndex:0] forKey:@"matchCount"];
                [[NSUserDefaults standardUserDefaults]synchronize];
                                
                if (!error) {
                    completion();
                }
                
                [self unblockUi];
            }];
        }
//    }
    
}

- (void)dislikeUserAtIndex:(NSUInteger)index withCompletion:(void (^)(void))completion {
    
    NSLog(@"dislike user");
    
    NSInteger count = [[NSUserDefaults standardUserDefaults]integerForKey:@"matchCount"];
//    BOOL isSubsribed = [[NSUserDefaults standardUserDefaults]boolForKey:@"isSubsribed"];
//    if (!isSubsribed) {
//        if (count <= 10) {
//            if (index < self.browsingUsers.count) {
//                [self blockUi];
//                User *user = self.browsingUsers[index];
//
//                [DTAAPI deleteMatchForUser:user completion:^(NSError *error, NSArray *responseArr) {
//
//                    [[NSUserDefaults standardUserDefaults]setObject:[responseArr objectAtIndex:0] forKey:@"matchCount"];
//                    [[NSUserDefaults standardUserDefaults]synchronize];
//
//                    if (!error) {
//                        completion();
//                    }
//
//                    [self unblockUi];
//                }];
//            }
//        }else {
//            [self presentIAPView];
//        }
//    }else {
        if (index < self.browsingUsers.count) {
            [self blockUi];
            User *user = self.browsingUsers[index];
            
            [DTAAPI deleteMatchForUser:user completion:^(NSError *error, NSArray *responseArr) {
                
                [[NSUserDefaults standardUserDefaults]setObject:[responseArr objectAtIndex:0] forKey:@"matchCount"];
                [[NSUserDefaults standardUserDefaults]synchronize];
                
                if (!error) {
                    completion();
                }
                
                [self unblockUi];
            }];
        }
//    }
}

- (void)navigateToUserAtIndex:(NSUInteger)index animated:(BOOL)animated {
    
    __weak typeof(self) weakSelf = self;
    
    NSLog(@"self.browsingUsers.count = %lu", (unsigned long)self.browsingUsers.count);
    
    if (index < self.browsingUsers.count) {
        
        User *user = self.browsingUsers[index];
        
        NSString *name = [NSString stringWithFormat:@"%@, %li", user.firstName, (long) user.userAge];
        //DEV
//        NSString *location = [NSString stringWithFormat:@"(%@)", [user fetchCityNameFromLocation]];
        NSString *location = [NSString stringWithFormat:@"%@", [user fetchCityNameFromLocation]];
        if ([user fetchCityNameFromLocation].length > 0) {
            location = [NSString stringWithFormat:@"(%@)", [user fetchCityNameFromLocation]];
        }        
        
//        self.userNameAndAgeLabel.attributedText = [NSString generateStringFormName:name location:location];
        self.userLastActiveLabel.text =[NSString stringWithFormat:@"Last active: %@", [self timeStringAgoSinceDate:user.lastActivity]];
        self.userPhotosCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)user.image.count];
        
         if ([user.image allObjects].count > 0) {
            [self.swipeImages setHidden:NO];
            [self.noPhotosView setHidden:YES];
            
            [self.swipeImages cleanImagesWithAnimation:animated onComplete:^(NSError *error)
             {
                 [weakSelf.swipeImages addImages:[user.image allObjects] animated:animated];
             }];
        }
        else {
            [self.swipeImages setHidden:YES];
            [self.noPhotosView setHidden:NO];
        }
    }
    else {
        if (![User currentUser]) {
            return;
        }
        
        [self.swipeImages cleanImagesWithAnimation:animated onComplete:nil];
   
        [self blockUi];
        
        [DTAAPI fetchBrowsingUsersWithParameters:[[DTASearchOptionsManager sharedManager] browsingParameters] completion:^(NSError *error, NSArray *users) {
             
             self.networkRequestProcessing = NO;
            
            NSInteger count = [[NSUserDefaults standardUserDefaults]integerForKey:@"matchCount"];
            
            if (count > 10) {
                
            }
             if (!error) {
                 
                 weakSelf.browsingUsers = users;
                 
                 if (weakSelf.browsingUsers.count > 0) {
                     weakSelf.placeholderView.hidden = YES;
                     weakSelf.currentUserIndex = 0;
                     [weakSelf navigateToUserAtIndex:weakSelf.currentUserIndex animated:animated];
                 }
                 else {
                     weakSelf.placeholderView.hidden = NO;
                 }
             }
             else {
                 NSLog(@"error avaialble");
                 self.currentUserIndex = 0;
                 self.browsingUsers = nil;
                 self.lastSearchParams = [[DTASearchOptionsManager sharedManager] browsingParameters];
                 //[self navigateToUserAtIndex:self.currentUserIndex animated:NO];
                 
                 weakSelf.placeholderView.hidden = NO;
             }
             
             [weakSelf unblockUi];
         }];
    }
    
    // SmartEye 15/10/2020
    [self showPrevForwardButtons];
}
-(void)showAlertWithTitle:(NSString *)atitle withMessage:(NSString *)message {
    UIAlertController *alertController  = [UIAlertController alertControllerWithTitle:atitle message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction =[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (NSString *)timeStringAgoSinceDate:(double)msFrom {
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:msFrom];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    NSDate *earliest = [now earlierDate:date];
    NSDate *latest = (earliest == now) ? date : now;
    NSDateComponents *components = [calendar components:(NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitSecond) fromDate:earliest toDate:latest options:NSCalendarMatchStrictly];
    
    if (components.year >= 2) {
        return [NSString stringWithFormat:@"%ld years ago", (long)components.year];
    } else if (components.year >= 1) {
        return @"Last year";
    } else if (components.month >= 2) {
        return [NSString stringWithFormat:@"%ld months ago", (long)components.month];
    } else if (components.month >= 1) {
        return @"Last month";
    } else if (components.weekOfYear >= 2) {
        return [NSString stringWithFormat:@"%ld weeks ago", (long)components.weekOfYear];
    } else if (components.weekOfYear >= 1) {
        return @"Last week";
    } else if (components.day >= 2) {
        return [NSString stringWithFormat:@"%ld days ago", (long)components.day];
    } else if (components.day >= 1) {
        return @"Yesterday";
    } else if (components.hour >= 2) {
        return [NSString stringWithFormat:@"%ld hours ago", (long)components.hour];
    } else if (components.hour >= 1) {
        return @"An hour ago";
    } else if (components.minute >= 2) {
        return [NSString stringWithFormat:@"%ld minutes ago", (long)components.minute];
    } else if (components.minute >= 1) {
        return @"A minute ago";
    } else if (components.second >= 3) {
        return [NSString stringWithFormat:@"%ld seconds ago", (long)components.second];
    } else {
        return @"Just now";
    }
}

@end

