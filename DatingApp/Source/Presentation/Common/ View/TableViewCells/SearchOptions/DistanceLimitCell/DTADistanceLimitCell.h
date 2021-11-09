//
//  DTADistanceLimitCell.h
//  DatingApp
//
//  Created by  Artem Kalinovsky on 9/15/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASValueTrackingSlider.h"
#import "NMRangeSlider.h"

@interface DTADistanceLimitCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *selectedDistaceLabel;
 
@property (weak, nonatomic) IBOutlet NMRangeSlider *distanceSlider;
@property (weak, nonatomic) IBOutlet UIButton *upperLabel;

+ (NSString *)reuseIdentifier;

- (void)configureCellWithInputView:(UIView *)inputView sender:(id)sender;

@end
