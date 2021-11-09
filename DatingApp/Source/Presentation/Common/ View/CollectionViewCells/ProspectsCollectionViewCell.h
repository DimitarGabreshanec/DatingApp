//
//  ProspectsCollectionViewCell.h
//  DatingApp
//
//  Created by Smart Eye on 8/19/21.
//  Copyright © 2021 Cleveroad Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

//NS_ASSUME_NONNULL_BEGIN

@interface ProspectsCollectionViewCell : UICollectionViewCell

- (void)configureWithUser:(User *)user;

@end

//NS_ASSUME_NONNULL_END
