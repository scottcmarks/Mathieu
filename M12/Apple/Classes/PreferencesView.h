//
//  PreferencesView.h
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PreferencesView : UIView {
    UISlider * animationSpeedSlider;
    UISwitch * soundEffectsSwitch;
    UISwitch * confirmSwitch;
    UILabel  * confirmHelp;
    UISwitch * updatingSwitch;
    UILabel  * updatingHelp;
}
@property( nonatomic, retain) IBOutlet UISlider * animationSpeedSlider;
@property( nonatomic, retain) IBOutlet UISwitch * soundEffectsSwitch;
@property( nonatomic, retain) IBOutlet UISwitch * confirmSwitch;
@property( nonatomic, retain) IBOutlet UILabel  * confirmHelp;
@property( nonatomic, retain) IBOutlet UISwitch * updatingSwitch;
@property( nonatomic, retain) IBOutlet UILabel  * updatingHelp;

@property /* dynamic */           CGFloat animationSpeed;
@property /* dynamic */           bool soundEffects;
@property /* dynamic */           bool confirm;
@property /* dynamic */           bool updating;

@end
