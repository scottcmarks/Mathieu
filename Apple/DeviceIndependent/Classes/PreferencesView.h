//
//  PreferencesView.h
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"

@interface PreferencesView : View 
{
    Slider * animationSpeedSlider;
    Switch * soundEffectsSwitch;
    Switch * confirmSwitch;
    Label  * confirmHelp;
    Label *currentPermutation;
    Label *currentPermLabel;
    Button * swapsButton;
#if TARGET_OS_IPHONE
	UINavigationItem * navigationBar;
#endif
}    
@property( nonatomic, assign ) IBOutlet Slider * animationSpeedSlider;
@property( nonatomic, assign ) IBOutlet Switch * soundEffectsSwitch;
@property( nonatomic, assign ) IBOutlet Switch * confirmSwitch;
@property( nonatomic, assign ) IBOutlet Label  * confirmHelp;
@property( nonatomic, assign ) IBOutlet Label *currentPermutation;
@property( nonatomic, assign ) IBOutlet Label *currentPermLabel;
@property( nonatomic, assign ) IBOutlet Button * swapsButton;
#if TARGET_OS_IPHONE
@property( nonatomic, assign ) IBOutlet UINavigationItem * navigationBar;
#endif
@property /* dynamic */           CGFloat animationSpeed;

@end
