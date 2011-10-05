//
//  PreferencesView.h
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"

@interface PreferencesView : UIView
{
    Slider * animationSpeedSlider;
    Switch * soundEffectsSwitch;
    Switch * confirmSwitch;
    Label  * currentPermutation;
    Label  * currentPermLabel;
    Button * swapsButton;
#if TARGET_OS_IPHONE
	UINavigationItem * navigationBar;
#endif
}
@property( nonatomic, assign ) IBOutlet UISlider * animationSpeedSlider;
@property( nonatomic, assign ) IBOutlet UISwitch * soundEffectsSwitch;
@property( nonatomic, assign ) IBOutlet UISwitch * confirmSwitch;
@property( nonatomic, assign ) IBOutlet UILabel  * currentPermutation;
@property( nonatomic, assign ) IBOutlet UILabel  * currentPermLabel;
@property( nonatomic, assign ) IBOutlet UIButton * swapsButton;
#if TARGET_OS_IPHONE
@property( nonatomic, assign ) IBOutlet UINavigationItem * navigationBar;
#endif
@property /* dynamic */           CGFloat animationSpeed;

@end
