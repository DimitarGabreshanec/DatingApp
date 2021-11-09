//
//  DTAAgesLimitCell.m
//  DatingApp
//
//  Created by  Artem Kalinovsky on 9/15/15.
//  Copyright (c) 2015 Cleveroad Inc. All rights reserved.
//

#import "DTAAgesLimitCell.h"
#import "REDRangeSlider.h"
#import "DTASearchOptionsManager.h"
#import "SearchOptions.h"

@interface DTAAgesLimitCell()

@end

static float kMaxAgeValue = 80.0f;

@implementation DTAAgesLimitCell

+ (NSString *)reuseIdentifier {
    return  @"searchAgeBoundsCellIdentifier";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.agesIntervalSlider.lowerHandleImageNormal = [UIImage imageNamed:@"sliderSpot"];

    self.agesIntervalSlider.upperHandleImageNormal = [UIImage imageNamed:@"sliderSpot"];

    self.agesIntervalSlider.trackBackgroundImage = [[UIImage imageNamed:@"line_light_track_empty"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5.0, 0.0, 5.0)];

    self.agesIntervalSlider.trackImage = [[UIImage imageNamed:@"ico_slider_track_filled"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 7.0, 0.0, 7.0)];
     

    self.agesIntervalSlider.minimumValue = DTAMinAgeValue;
    self.agesIntervalSlider.maximumValue = kMaxAgeValue;
    //self.agesIntervalSlider.minimumSpacing = 0.0f;
    
    self.selectedAgeRangeLabel.text = @"18-80";
    self.agesIntervalSlider.lowerHandleHidden = NO;
    self.agesIntervalSlider.minimumValue = 0;
    self.agesIntervalSlider.maximumValue = 80;
    self.agesIntervalSlider.lowerValue = 18;
    self.agesIntervalSlider.upperValue = 80;
    
    self.agesIntervalSlider.minimumRange = 1;
     
    
    [self.agesIntervalSlider addTarget:self action:@selector(rangeSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureCellWithInputView:(UIView *)inputView sender:(id)sender {
//    self.agesIntervalSlider.rightValue = kMaxAgeValue;
//    self.agesIntervalSlider.leftValue = DTAMinAgeValue;
}

- (IBAction)rangeSliderValueChanged:(id)sender {
    self.lowerLabel.hidden = false;
    self.upperLabel.hidden = false;
    int minimalAge = (int) self.agesIntervalSlider.lowerValue;
    int maximalAge = (int) self.agesIntervalSlider.upperValue;
    self.selectedAgeRangeLabel.text = [NSString stringWithFormat:@"%i-%i", minimalAge, maximalAge];
    
    CGPoint lowerCenter;
    lowerCenter.x = (self.agesIntervalSlider.lowerCenter.x + self.agesIntervalSlider.frame.origin.x);
    lowerCenter.y = (self.agesIntervalSlider.center.y - 30.0f);
    self.lowerLabel.center = lowerCenter;
    [self.lowerLabel setTitle:[NSString stringWithFormat:@"%d", (int)self.agesIntervalSlider.lowerValue] forState:UIControlStateNormal];
    
    
    CGPoint upperCenter;
    upperCenter.x = (self.agesIntervalSlider.upperCenter.x + self.agesIntervalSlider.frame.origin.x);
    upperCenter.y = (self.agesIntervalSlider.center.y - 30.0f);
    self.upperLabel.center = upperCenter;
    [self.upperLabel setTitle:[NSString stringWithFormat:@"%d", (int)self.agesIntervalSlider.upperValue] forState:UIControlStateNormal];
   
    [DTASearchOptionsManager sharedManager].searchOptions.ageFrom = @(minimalAge);
    [DTASearchOptionsManager sharedManager].searchOptions.ageTo = @(maximalAge);
}

@end
