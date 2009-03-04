//
//  PreferencesView.mm
//  SporadicM24
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import "PreferencesView.h"
#import "SporadicM24AppDelegate.h"
#import "Constants.h"

@implementation PreferencesView

- ( SporadicM24AppDelegate * ) appDelegate{ return ( SporadicM24AppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }

@synthesize soundEffectsSwitch;

@dynamic soundEffects;
- ( void )setSoundEffects:(bool)sounds {
    self.appDelegate.soundEffects = soundEffectsSwitch.on = sounds;
}
- ( bool ) soundEffects { return soundEffectsSwitch.on; }

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
@dynamic confirm;
- ( void )setConfirm:(bool)conf {
    self.appDelegate.confirm = confirmSwitch.on = conf;
}
- ( bool ) confirm { return confirmSwitch.on; }

@synthesize updatingSwitch;
@synthesize updatingHelp;
@dynamic updating;
- ( void )setUpdating:(bool)upd {
    self.appDelegate.useSpinMessages = updatingSwitch.on = upd;
}
- ( bool ) updating { return updatingSwitch.on; }


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}
const CGFloat helpFontSize = 11.0;

- (void) awakeFromNib{
    confirmHelp.font = [UIFont systemFontOfSize:helpFontSize ];
    // TODO: I18n
    confirmHelp.text = @"When solving, confirm Shake,\n"
                        "Restart and Home.  Confirm\n"
                        "combo set or erase of a\n"
                        "previously-set combo.";
    updatingHelp.font = [UIFont systemFontOfSize:helpFontSize ];
    // TODO: I18n
    updatingHelp.text = @"Update the history text while\n"
                         "spinning the ball ring.  This\n"
                         "makes it easier to position\n"
                         "but with much rougher spinning.";
    
    animationSpeedSlider.value = self.appDelegate.animationSpeed  ;
    soundEffectsSwitch.on      = self.appDelegate.soundEffects    ;
    confirmSwitch.on           = self.appDelegate.confirm         ;
    updatingSwitch.on          = self.appDelegate.useSpinMessages ;
}


- (void)dealloc {
    [super dealloc];
}


@end
