//
//  RageIAPHelper.m
//  In App Rage
//
//  Created by Ray Wenderlich on 9/5/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import "RageIAPHelper.h"

@implementation RageIAPHelper

+ (RageIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static RageIAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet *sets = [NSSet setWithArray:APP_DELEGATE.inAppIdentifireArr];
        sharedInstance = [[self alloc] initWithProductIdentifiers:sets];
    });
    return sharedInstance;
}

@end
