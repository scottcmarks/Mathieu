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

#if TARGET_OS_IPHONE
@synthesize navigationBar;
#endif

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


const CGFloat helpFontSize = 11.0;

@synthesize currentPermutation;
@synthesize currentPermLabel;
@synthesize swapsButton;

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
    swapsButton.hidden         = ( nBalls == 24 )                 ;
    currentPermutation.hidden  = ( nBalls == 24 )                 ;
    currentPermLabel.hidden    = ( nBalls == 24 )                 ;
#if TARGET_OS_IPHONE
	navigationBar.title        = fullAppName                      ;
#endif
}

- ( void ) willMoveToSuperview: ( UIView *) newSuperView
{
    if ( newSuperView ) 
    {
        NSString * cycles = self.appDelegate.gameModel.cycles;
        if ( nBalls == 24 )
        {
#if defined( SHOW_M24_CURRENT_PERMUTATION )
            NSRange brk = [ cycles rangeOfString:@") (" 
                                         options:NSLiteralSearch
                                           range:NSMakeRange( cycles.length/2 - 4, 9 ) ];
            cycles = [ cycles stringByReplacingCharactersInRange:brk withString:@")\n (" ];
            currentPermutation.font = [ UIFont systemFontOfSize:13.0 ];
#endif
        }
        currentPermutation.text = cycles;
        
    }
}

- (void)dealloc {
    [super dealloc];
}


@end
