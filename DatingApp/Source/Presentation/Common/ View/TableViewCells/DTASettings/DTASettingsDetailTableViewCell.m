//
//  DTASettingsDetailTableViewCell.m
//  DatingApp
//
//  Created by VLADISLAV KIRIN on 10/28/15.
//  Copyright © 2015 Cleveroad Inc. All rights reserved.
//

#import "DTASettingsDetailTableViewCell.h"
#import "User+Extension.h"

NSString * const kDTASettingsDetailTableViewCell = @"DTASettingsDetailTableViewCell";
const NSUInteger kDTASettingsDetailCellsCount = 4;
const CGFloat kDTASettingsDetailCellsHeight = 52.f;

@interface DTASettingsDetailTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageIcon;
@property (weak, nonatomic) IBOutlet UILabel *labelText;
@property (weak, nonatomic) IBOutlet UISwitch *switcher;
@property (weak, nonatomic) IBOutlet UIImageView *imageDetailArrow;
@property (weak, nonatomic) IBOutlet UIView *viewSeparator;

@end

@implementation DTASettingsDetailTableViewCell
@synthesize delegate;

#pragma mark - Public 

- (IBAction)onSwitchValueChanged:(id)sender {
    [self.delegate swichValueChanged:sender];
}

- (void)configureCellWithType:(DTASettingsDetailCell)type {
    self.imageIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.switcher.hidden = YES;
    self.viewSeparator.hidden = NO;
    self.switcher.onTintColor = colorSwitchCan;
    
    switch (type) {
            
        case DTASettingsDetailCellPushNewMessages:
            self.imageIcon.image = [UIImage imageNamed: @"icon_newmessages"];
            self.labelText.text = @"New messages";
            [self UISetupForSwitchersWithType:type];
            break;
    
        case DTASettingsDetailCellPushNewMatchs:
            self.imageIcon.image = [UIImage imageNamed: @"icon_newmatches"];
            self.labelText.text = @"New matches";
            [self UISetupForSwitchersWithType:type];
            break;
        
        case DTASettingsDetailCellPushNewLikes:
            self.imageIcon.image = [UIImage imageNamed: @"icon_newlikes"];
            self.labelText.text = @"New likes";
            [self UISetupForSwitchersWithType:type];
            break;
                   
        case DTASettingsDetailCellBlockedUsers:
            self.imageIcon.image = [UIImage imageNamed: @"icon_blcoked"];
            self.labelText.text = @"Blocked Users";
            break;
            
        case DTASettingsDetailCellPrivacyPolicy:
            self.imageIcon.image = [UIImage imageNamed: @"icon_privacy"];
            self.labelText.text = @"Privacy Policy";
            break;
        
        case DTASettingsDetailCellTerms:
            self.imageIcon.image = [UIImage imageNamed: @"icon_terms"];
            self.labelText.text = @"Terms of use";
            break;
        
        case DTASettingsDetailCellEmailUs:
            self.imageIcon.image = [UIImage imageNamed: @"icon_emailus"];
            self.labelText.text = @"Email us";
            break;
        
        default:
            NSLog(@"Wrong cell type number");
            break;
    }
}

- (NSInteger)switcherState
{
    return [@(self.switcher.isOn) integerValue];
}

#pragma mark -

- (void)prepareForReuse {
    
    [super prepareForReuse];
    
    self.switcher.hidden = YES;
    self.imageDetailArrow.hidden = YES;
    self.viewSeparator.hidden = YES;
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

#pragma mark - private

- (void)UISetupForSwitchersWithType:(DTASettingsDetailCell)type {
    
    User *user = [User currentUser];
    
    switch (type) {
            
        case DTASettingsDetailCellPushNewMessages:
            self.switcher.on = [user.messagesNotifications boolValue];
            break;
    
        case DTASettingsDetailCellPushNewMatchs:
            self.switcher.on = [user.matchesNotifications boolValue];
            break;
        
        case DTASettingsDetailCellPushNewLikes:
            self.switcher.on = [user.likesNotifications boolValue];
            break;
        
        default:
            break;
    }
    
    self.switcher.hidden = NO;
    self.imageDetailArrow.hidden = YES;
    self.viewSeparator.hidden = NO;
}

@end
