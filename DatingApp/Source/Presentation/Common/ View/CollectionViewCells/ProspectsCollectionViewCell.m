//
//  ProspectsCollectionViewCell.m
//  DatingApp
//
//  Created by Smart Eye on 8/19/21.
//  Copyright © 2021 Cleveroad Inc. All rights reserved.
//

#import "ProspectsCollectionViewCell.h"
#import "User.h"
#import "Location.h"
#import "User+Extension.h"

@interface ProspectsCollectionViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *userAvatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameAndAgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *userLocationLabel;

@end


@implementation ProspectsCollectionViewCell

- (void)configureWithUser:(User *)user {
    
    self.userAvatarImageView.layer.cornerRadius = 27.0f;
    self.userAvatarImageView.layer.borderWidth = 1.0f;
    self.userAvatarImageView.clipsToBounds = YES;
    self.userAvatarImageView.layer.borderColor = [colorCreamCan CGColor];
    
    NSArray *words = [user.firstName componentsSeparatedByString: @" "];
    NSString *firstName = [[NSString alloc] initWithString: words[0]];
    
    self.userNameAndAgeLabel.text = [NSString stringWithFormat:@"%@,", firstName];
    
    self.userLocationLabel.text = [NSString stringWithFormat:@"%li", (long)[user userAge]];

    [self.userAvatarImageView sd_setImageWithURL:[NSURL URLWithString:user.avatar] placeholderImage:[UIImage imageNamed:@"drefaultImage"] options:SDWebImageDelayPlaceholder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            self.userAvatarImageView.image = [UIImage imageNamed:@"drefaultImage"];
        }
    }];
}

@end
