//
//  PreferencesView.h
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"

@interface PreferencesView : UIView
{
    AppleSlider * animationSpeedSlider;
    AppleSwitch * soundEffectsSwitch;
    AppleSwitch * confirmSwitch;
    AppleLabel  * currentPermutation;
    AppleLabel  * currentPermLabel;
    AppleButton * swapsButton;
#if TARGET_IOS
	UINavigationItem * navigationBar;
#endif
}
@property( nonatomic, assign ) IBOutlet AppleSlider * animationSpeedSlider;
@property( nonatomic, assign ) IBOutlet AppleSwitch * soundEffectsSwitch;
@property( nonatomic, assign ) IBOutlet AppleSwitch * confirmSwitch;
@property( nonatomic, assign ) IBOutlet AppleLabel  * currentPermutation;
@property( nonatomic, assign ) IBOutlet AppleLabel  * currentPermLabel;
@property( nonatomic, assign ) IBOutlet AppleButton * swapsButton;
#if TARGET_IOS
@property( nonatomic, assign ) IBOutlet UINavigationItem * navigationBar;
#endif
@property /* dynamic */           CGFloat animationSpeed;

@end
