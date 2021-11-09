//
//  DTAConversationsTableViewCell.m
//  DatingApp
//
//  Created by Maksim on 23.10.15.
//  Copyright © 2015 Cleveroad Inc. All rights reserved.
//

#import "DTAConversationsTableViewCell.h"
#include "DTAconversation.h"
#import "NSDate+ChatTimeFormat.h"

typedef NS_ENUM(NSUInteger, DTAChatEnum) {
    DTAChatEnumImage = 1,
    DTAChatEnumName,
    DTAChatEnumDate,
    DTAChatEnumMessage,
    DTAChatEnumUnReadView,
    DTAChatEnumUnReadCount
};

@implementation DTAConversationsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UIImageView *userPhoto = (UIImageView *)[self viewWithTag:DTAChatEnumImage];
    userPhoto.layer.cornerRadius = 8;
    [userPhoto.layer setMasksToBounds:YES];
//    [userPhoto.layer setBorderColor:colorCreamCan.CGColor];
//    [userPhoto.layer setBorderWidth:1.5];
}

- (void)configureWithUser:(DTAconversation *)conversation {
    
    UIImageView *userPhoto = (UIImageView *)[self viewWithTag:DTAChatEnumImage];
    
    UILabel *date = (UILabel *)[self viewWithTag:DTAChatEnumDate];
    NSInteger weekday = [[NSCalendar currentCalendar] component:NSCalendarUnitWeekday
                                                       fromDate: [NSDate dateWithTimeIntervalSince1970:conversation.date]];
    date.text = [NSArray arrayWithObjects: @"MON", @"THU", @"WED", @"THR", @"FRI", @"SAT", @"SUN", nil][weekday];

    UILabel *name = (UILabel *)[self viewWithTag:DTAChatEnumName];
    NSArray *words = [conversation.nameAge componentsSeparatedByString: @" "];
    NSString *firstName = [[NSString alloc] initWithString: words[0]];
    firstName = [firstName stringByReplacingOccurrencesOfString:@","
                                         withString:@""];    
    name.text = firstName;

    UILabel *message = (UILabel *)[self viewWithTag:DTAChatEnumMessage];
    message.text = conversation.lastTextMessage;
    
    UIView *unReadCountView = (UIView *)[self viewWithTag:DTAChatEnumUnReadView];
    
    // SmartEye
    NSInteger iUnreadCount = conversation.unreadMessages;
    
    if (iUnreadCount == 0) {
        [unReadCountView setHidden:YES];
    } else {
        [unReadCountView setHidden:false];
    }
    
    UILabel *indicator_badge = (UILabel *)[self viewWithTag:DTAChatEnumUnReadCount];
    indicator_badge.backgroundColor = [UIColor redColor];
    indicator_badge.clipsToBounds = true;
    indicator_badge.layer.masksToBounds = true;
    indicator_badge.layer.cornerRadius = 11;
    indicator_badge.textColor = [UIColor whiteColor];
    indicator_badge.textAlignment = NSTextAlignmentCenter;
        
    if (iUnreadCount < 100){
        indicator_badge.text = [NSString stringWithFormat: @"%ld", (long)iUnreadCount];
    } else {
        indicator_badge.text = [NSString stringWithFormat: @"99+"];
    }
    
    if (conversation.isFriendDeleted) {
        [userPhoto setImage:[UIImage imageNamed:@"deletedUser"]];
    }
    else if (conversation.avatarUrl) {
        [userPhoto sd_setImageWithURL:conversation.avatarUrl placeholderImage:[UIImage imageNamed:@"drefaultImage"] options:SDWebImageDelayPlaceholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL){
            
        }];
    }
    else {
        userPhoto.image = [UIImage imageNamed:@"drefaultImage"];
    }


}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
