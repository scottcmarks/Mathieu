//
//  PreferencesView.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "PreferencesView.h"
#import "mathieu.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"

@implementation PreferencesView

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }

@synthesize navigationBar;

@synthesize soundEffectsSwitch;

@synthesize animationSpeedSlider;
@dynamic animationSpeed;
- (void)setAnimationSpeed:(CGFloat)speed {
    if ( !( 0.0 <= speed ) )
        speed = 0.0;
    else if ( !( speed <= MAX_ANIMATION_DURATION_FACTOR ) )
        speed = MAX_ANIMATION_DURATION_FACTOR ;
    self.appDelegate.animationSpeed = animationSpeedSlider.value = speed;
}
- (CGFloat ) animationSpeed { return animationSpeedSlider.value; }

@synthesize confirmSwitch;
@synthesize confirmHelp;


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}
const CGFloat helpFontSize = 11.0;

@synthesize currentPermutation;

- (void) awakeFromNib{
    confirmHelp.font = [UIFont systemFontOfSize:helpFontSize ];
    // TODO: I18n
    confirmHelp.text = @"When solving, confirm Shake,\n"
                        "Restart and Home.  Confirm\n"
                        "combo set or erase of a\n"
                        "previously-set combo.";
    
    animationSpeedSlider.value = self.appDelegate.animationSpeed  ;
    soundEffectsSwitch.on      = self.appDelegate.soundEffects    ;
    confirmSwitch.on           = self.appDelegate.confirm         ;
	navigationBar.title        = appName                          ;
    currentPermutation.text    = self.appDelegate.gameModel.cycles;
}


- (void)dealloc {
    [super dealloc];
}


@end
