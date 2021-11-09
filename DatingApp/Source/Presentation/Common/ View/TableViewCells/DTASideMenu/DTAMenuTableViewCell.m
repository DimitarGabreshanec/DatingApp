//
//  DTAMenuTableViewCell.m
//  DatingApp
//
//  Created by VLADISLAV KIRIN on 8/3/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import "DTAMenuTableViewCell.h"
#import "User+Extension.h"

@interface DTAMenuTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *labelMenuItem;
@property (weak, nonatomic) IBOutlet UIImageView *imageLeftIco;

@property (strong, nonatomic) UIView *indicator;

// SmartEye 20/10/2020
@property (strong, nonatomic) UILabel *indicator_badge;

@end

@implementation DTAMenuTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.labelMenuItem.font = [UIFont fontWithName:self.labelMenuItem.font.fontName size:self.labelMenuItem.font.pointSize * scaleCoefficient];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.labelMenuItem.text = @"";
}

- (void)configureCellForType:(DTAMenuItems)type isCurrent:(BOOL)isCurrent {
    BOOL isHaveIndicator = NO;
    NSInteger badgeCount = 0;
    
    NSString *imageName;
    
    switch (type) {
        case DTAMenuItemSearchOptions:
            self.labelMenuItem.text = @"Filter";
            imageName = @"sb_search";
            break;
            
        case DTAMenuItemBrowse:
            self.labelMenuItem.text = @"Discover";
            imageName = @"sb_browse";
            break;
     
        case DTAMenuItemLikesYou:
            self.labelMenuItem.text = @"Likes You";
            imageName = @"sb_matches";
            
            if ([[User currentUser].likesBadge integerValue]) {
                isHaveIndicator = YES;
            }
            
            break;
        
        case DtaMenuItemMatches:
            self.labelMenuItem.text = @"Matches";
            imageName = @"sb_prospects";
            
            if ([[User currentUser].matchesBadge integerValue]) {
                isHaveIndicator = YES;
            }
            
            break;
        
        case DTAMenuItemConversations:
            self.labelMenuItem.text = @"Conversations";
            imageName = @"sb_conversations";
            
            if ([[User currentUser].messagesBadge integerValue]) {
                isHaveIndicator = YES;
                // SmartEye 20/10/2020
                badgeCount = [[User currentUser].messagesBadge integerValue];
            }
            break;
        
        case DTAMenuItemNearby:
            self.labelMenuItem.text = @"Nearby";
            imageName = @"sb_nearby";
            break;
        
        case DTAMenuItemSettings:
            self.labelMenuItem.text = @"Settings";
            imageName = @"sb_settings";
            break;
            
        default:
            NSLog(@"Wrong DTAMenuITEM index");
            break;
    }
    
    // SmartEye 20/10/2020
    if (type != DTAMenuItemConversations) {
        if (isHaveIndicator) {
            [self.labelMenuItem sizeToFit];
            CGFloat x = self.labelMenuItem.frame.origin.x + self.labelMenuItem.frame.size.width;            
            if ( !self.indicator ) {
                self.indicator = [[UIView alloc] initWithFrame:CGRectMake(x, 16.0, 8.0, 8.0)];
                self.indicator.backgroundColor = [UIColor redColor];
                self.indicator.layer.cornerRadius = 4.0;
                [self addSubview:self.indicator];
            }
        } else {
            if (self.indicator) {
                [self.indicator removeFromSuperview];
                self.indicator = nil;
            }
        }
    } else {
        if (isHaveIndicator) {
            [self.labelMenuItem sizeToFit];
            CGFloat x = self.labelMenuItem.frame.origin.x + self.labelMenuItem.frame.size.width;
            if ( !self.indicator_badge ) {
                self.indicator_badge = [[UILabel alloc] initWithFrame:CGRectMake(x - 1, 10.0, 15.0, 15.0)];
                self.indicator_badge.backgroundColor = [UIColor redColor];
                self.indicator_badge.clipsToBounds = true;
                self.indicator_badge.layer.masksToBounds = true;
                self.indicator_badge.layer.cornerRadius = 7.5;
                self.indicator_badge.textColor = [UIColor whiteColor];
                self.indicator_badge.font = [UIFont fontWithName:self.labelMenuItem.font.fontName size:9.0];
                self.indicator_badge.textAlignment = NSTextAlignmentCenter;
                self.indicator_badge.text = [NSString stringWithFormat: @"%ld", (long)badgeCount];
                [self addSubview:self.indicator_badge];
            } else {
                self.indicator_badge.text = [NSString stringWithFormat: @"%ld", (long)badgeCount];
            }
        } else {
            if (self.indicator_badge) {
                [self.indicator_badge removeFromSuperview];
                self.indicator_badge = nil;
            }
        }
    }
    
    if(imageName) {
        if(isCurrent) {
            imageName = [imageName stringByAppendingString:@"_a"];
        }
        
        self.imageView.image = [UIImage imageNamed:imageName];
    }
    
    if(isCurrent) {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:0.96 green:0.83 blue:0.44 alpha:1]];
        self.labelMenuItem.textColor = [UIColor whiteColor];
    }
    else {
        [self.contentView setBackgroundColor:[UIColor whiteColor]];
        self.labelMenuItem.textColor = [UIColor colorWithRed:0.57 green:0.57 blue:0.57 alpha:1];
    }
}

@end
