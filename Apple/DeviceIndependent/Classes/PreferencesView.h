//
//  PreferencesView.h
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"

@interface PreferencesView : UIView
@property( nonatomic, assign ) IBOutlet AppleSlider * animationSpeedSlider;
@property( nonatomic, assign ) IBOutlet AppleSwitch * soundEffectsSwitch;
@property( nonatomic, assign ) IBOutlet AppleSwitch * confirmSwitch;
@property( nonatomic, assign ) IBOutlet AppleLabel  * currentPermutation;
@property( nonatomic, assign ) IBOutlet AppleLabel  * currentPermLabel;
@property( nonatomic, assign ) IBOutlet AppleButton * swapsButton;
#if TARGET_IOS
@property( nonatomic, assign ) IBOutlet UINavigationItem * navigationBar;
#endif
@property( nonatomic, assign ) CGFloat animationSpeed;

-(void) synchronize;
@end
