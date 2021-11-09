//
//  DTADistanceLimitCell.m
//  DatingApp
//
//  Created by  Artem Kalinovsky on 9/15/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import "DTADistanceLimitCell.h"
#import "DTASearchOptionsManager.h"
#import "SearchOptions.h"

@interface DTADistanceLimitCell()

@end

@implementation DTADistanceLimitCell

+ (NSString *)reuseIdentifier {
    return  @"searchDistanceLimitCellIdentifier";
}

- (void)awakeFromNib {
    [super awakeFromNib];
   
    self.selectedDistaceLabel.text = @"1 miles";
    
    self.distanceSlider.lowerHandleImageNormal = [UIImage imageNamed:@"sliderSpot"];

    self.distanceSlider.upperHandleImageNormal = [UIImage imageNamed:@"sliderSpot"];

    self.distanceSlider.trackBackgroundImage = [[UIImage imageNamed:@"line_light_track_empty"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5.0, 0.0, 5.0)];

    self.distanceSlider.trackImage = [[UIImage imageNamed:@"ico_slider_track_filled"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 7.0, 0.0, 7.0)];
     

    self.distanceSlider.minimumValue = 0;
    self.distanceSlider.maximumValue = 301;
     
    self.distanceSlider.lowerHandleHidden = YES;
    self.distanceSlider.lowerValue = 1;
    self.distanceSlider.upperValue = 300;
    
    self.distanceSlider.minimumRange = 1;
     
    int maximalAge = (int) self.distanceSlider.maximumValue;
    self.selectedDistaceLabel.text = [NSString stringWithFormat:@"%i miles", maximalAge];
    
    [self.distanceSlider addTarget:self action:@selector(changeValueOfDistanceSlider:) forControlEvents:UIControlEventValueChanged];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)configureCellWithInputView:(UIView *)inputView sender:(id)sender {

}
- (IBAction)changeValueOfDistanceSlider:(id)sender {
    self.upperLabel.hidden = false;
    int curDistance = (int) self.distanceSlider.upperValue;
    
    CGPoint upperCenter;
    upperCenter.x = (self.distanceSlider.upperCenter.x + self.distanceSlider.frame.origin.x);
    upperCenter.y = (self.distanceSlider.center.y - 30.0f);
    self.upperLabel.center = upperCenter;
    if (curDistance <= 300) {
        self.selectedDistaceLabel.text = [NSString stringWithFormat:@"%i miles", curDistance];
        [self.upperLabel setTitle:[NSString stringWithFormat:@"%d", curDistance] forState:UIControlStateNormal];
    }
    else {
        self.selectedDistaceLabel.text = @"300+ miles";
        [self.upperLabel setTitle:[NSString stringWithFormat:@"300+"] forState:UIControlStateNormal];
    }
    
    
    [DTASearchOptionsManager sharedManager].searchOptions.nearbyRadius = @(curDistance);
}
 

@end
