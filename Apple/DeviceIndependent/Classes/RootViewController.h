//
//  RootViewController.h
//  Top-level view controller in the SporadicSporadicM12 application
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"

@class SporadicMViewController;
@class PreferencesViewController;
@class GameModel;

@interface RootViewController : AppleViewController
#if TARGET_IOS
                                                <UIAccelerometerDelegate>
#endif /* TARGET_IOS */
{
    SporadicMViewController *mainViewController;
    PreferencesViewController *preferencesViewController;

#if TARGET_IOS
	UIAccelerationValue	myAccelerometer[3];
    CFTimeInterval		lastShakeTime;
    bool                nowHandlingShake;
#elif TARGET_MACOS
#else
#error Don't know this platform!
#endif
}

@property ( nonatomic, retain ) SporadicMViewController *mainViewController;
@property ( nonatomic, retain ) PreferencesViewController *preferencesViewController;
#if TARGET_IOS
#elif TARGET_MACOS
#else
#error Don't know this platform!
#endif

#if TARGET_IOS
@property ( nonatomic         ) bool nowHandlingShake;
#endif /* TARGET_IOS */

- ( void ) setSwapIndex: ( int ) newSwapIndex;

- (void) toggleView;
typedef enum
{
    curl,
    flip,
    flop
} RootViewControllerTransition;
- (void) flipFrom: ( AppleViewController * ) oldViewController
               to: ( AppleViewController * ) newViewController
       transition: ( RootViewControllerTransition ) transition;

- ( void ) synchronizeView ;


@end
