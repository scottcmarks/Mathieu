//
//  RootViewController.h
//  Top-level view controller in the SporadicSporadicM12 application
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SporadicMViewController;
@class PreferencesViewController;
@class GameModel;

@interface RootViewController : UIViewController  <UIAccelerometerDelegate>
{
    SporadicMViewController *mainViewController;
    PreferencesViewController *preferencesViewController;
	UIAccelerationValue	myAccelerometer[3];
    CFTimeInterval		lastShakeTime;
    bool                nowHandlingShake;
}

@property (nonatomic, retain) SporadicMViewController *mainViewController;
@property (nonatomic, retain) PreferencesViewController *preferencesViewController;
@property (nonatomic        ) bool nowHandlingShake;

- (void)toggleView;
- (void) flipFrom:( UIViewController * )oldViewController to:( UIViewController * )newViewController;
- (void) setAnimationTransition:(UIViewAnimationTransition)transition;

@end
