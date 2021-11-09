//
//  IntroViewController.m
//  DatingApp
//
//  Created by Smart Eye on 7/29/21.
//  Copyright © 2021 Cleveroad Inc. All rights reserved.
//

#import "IntroViewController.h"


@interface IntroViewController ()<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIPageControl *pagecontrol;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (nonatomic) UIScrollView *scrollview;
@end

@implementation IntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL bfirstRun = [[NSUserDefaults standardUserDefaults] boolForKey:@"appfirstRun"];
    
    if (bfirstRun) {
        [self performSegueWithIdentifier:@"goMainViewController" sender:self];
    }
    // Do any additional setup after loading the view.
    self.scrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.contentView.frame.size.height)];
    
    self.scrollview.pagingEnabled = YES;
    self.scrollview.contentSize = CGSizeMake(self.view.frame.size.width * 3, self.contentView.frame.size.height);
    self.scrollview.showsHorizontalScrollIndicator = NO;
    self.scrollview.showsVerticalScrollIndicator = NO;
    self.scrollview.scrollsToTop = NO;
    self.scrollview.delegate = self;
    self.scrollview.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    [self.contentView addSubview:self.scrollview];

    self.pagecontrol.userInteractionEnabled = NO;
    self.pagecontrol.numberOfPages = 3;
    self.pagecontrol.currentPage = 0;
    
    [self.btnNext setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupImages];
}
- (IBAction)goNext:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"appfirstRun"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self performSegueWithIdentifier:@"goMainViewController" sender:self];
}

- (void)setupImages {
    NSMutableArray *wordsArray = [NSMutableArray arrayWithObjects:@"Intro", @"Intro", @"Intro", nil];

    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.scrollview.frame.size.height;

    for (int i = 0; i < wordsArray.count; i++) {
        UIImageView *imageView;
        imageView = [[UIImageView alloc] initWithFrame: CGRectMake(i * width, 0, width, height)];
        imageView.image = [UIImage imageNamed: wordsArray[i]];
        imageView.backgroundColor = [UIColor redColor];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;

        [self.scrollview addSubview: imageView];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger pageindex = lround(self.scrollview.contentOffset.x / self.view.frame.size.width);
    
    self.pagecontrol.currentPage = pageindex;
    if (pageindex == 2) {
        [self.btnNext setHidden:NO];
    } else {
        [self.btnNext setHidden:YES];
    }    
}
@end

