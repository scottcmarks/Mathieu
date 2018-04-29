//
//  PreferencesView.mm
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "PreferencesView.h"
#import "mathieu.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"

@implementation PreferencesView

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ AppleApplication sharedApplication ] delegate ] ; }

#if TARGET_IOS
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

@synthesize currentPermutation;
@synthesize currentPermLabel;
@synthesize swapsButton;

- (void) awakeFromNib
{
    [super awakeFromNib];
    animationSpeedSlider.value = self.appDelegate.animationSpeed  ;
    soundEffectsSwitch.on      = self.appDelegate.soundEffects    ;
    confirmSwitch.on           = self.appDelegate.confirm         ;
    BOOL bigBalls              = ( nBalls == 24 )                 ;
    swapsButton.hidden         = bigBalls                         ;
    currentPermutation.hidden  = bigBalls                         ;
    currentPermLabel.hidden    = bigBalls                         ;
#if TARGET_IOS
	navigationBar.title        = fullAppName                      ;
#endif
}

- ( void ) synchronize {
    NSString * cycles = self.appDelegate.gameModel.cycles;
#if ( nBalls == 24 )  && defined( SHOW_M24_CURRENT_PERMUTATION )
    NSRange brk = [ cycles rangeOfString:@") ("
                                 options:NSLiteralSearch
                                   range:NSMakeRange( cycles.length/2 - 4, 9 ) ];
    cycles = [ cycles stringByReplacingCharactersInRange:brk withString:@")\n (" ];
    currentPermutation.font = [ AppleFont systemFontOfSize:13.0 ];
#endif
    currentPermutation.text = cycles;
    
}


@end
