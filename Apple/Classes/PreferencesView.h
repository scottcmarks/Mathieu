//
//  PreferencesView.h
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreferencesView : UIView {
    UISlider * animationSpeedSlider;
    UISwitch * soundEffectsSwitch;
    UISwitch * confirmSwitch;
    UILabel  * confirmHelp;
	UINavigationItem * navigationBar;
    UILabel *currentPermutation;
    UILabel *currentPermLabel;
    UIButton * swapsButton;
}
@property( nonatomic, assign ) IBOutlet UISlider * animationSpeedSlider;
@property( nonatomic, assign ) IBOutlet UISwitch * soundEffectsSwitch;
@property( nonatomic, assign ) IBOutlet UISwitch * confirmSwitch;
@property( nonatomic, assign ) IBOutlet UILabel  * confirmHelp;
@property( nonatomic, assign ) IBOutlet UINavigationItem * navigationBar;
@property( nonatomic, assign ) IBOutlet UILabel *currentPermutation;
@property( nonatomic, assign ) IBOutlet UILabel *currentPermLabel;
@property( nonatomic, assign ) IBOutlet UIButton * swapsButton;

@property /* dynamic */           CGFloat animationSpeed;

@end
