//
//  DTAAgesLimitCell.h
//  DatingApp
//
//  Created by  Artem Kalinovsky on 9/15/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMRangeSlider.h" 

@interface DTAAgesLimitCell : UITableViewCell
 
@property (weak, nonatomic) IBOutlet UILabel *selectedAgeRangeLabel;
@property (weak, nonatomic) IBOutlet NMRangeSlider *agesIntervalSlider;
@property (weak, nonatomic) IBOutlet UIButton *lowerLabel;
@property (weak, nonatomic) IBOutlet UIButton *upperLabel;

+ (NSString *)reuseIdentifier;

- (void)configureCellWithInputView:(UIView *)inputView sender:(id)sender;

@end
