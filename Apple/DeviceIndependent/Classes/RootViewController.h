//
//  RootViewController.h
//  Top-level view controller in the SporadicSporadicM12 application
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"

@class SporadicMViewController;
@class PreferencesViewController;
@class GameModel;

@interface RootViewController : ViewController
#if TARGET_OS_IPHONE
                                                <UIAccelerometerDelegate>
#endif /* TARGET_OS_IPHONE */
{
    SporadicMViewController *mainViewController;
    PreferencesViewController *preferencesViewController;

#if TARGET_OS_IPHONE
	UIAccelerationValue	myAccelerometer[3];
    CFTimeInterval		lastShakeTime;
    bool                nowHandlingShake;
#elif TARGET_OS_MAC
#else
#error Don't know this platform!
#endif
}

@property ( nonatomic, retain ) SporadicMViewController *mainViewController;
@property ( nonatomic, retain ) PreferencesViewController *preferencesViewController;
#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
#else
#error Don't know this platform!
#endif

#if TARGET_OS_IPHONE
@property ( nonatomic         ) bool nowHandlingShake;
#endif /* TARGET_OS_IPHONE */

- ( void ) setSwapIndex: ( int ) newSwapIndex;

- (void) toggleView;
typedef enum
{
    curl,
    flip,
    flop
} RootViewControllerTransition;
- (void) flipFrom: ( ViewController * ) oldViewController
               to: ( ViewController * ) newViewController
       transition: ( RootViewControllerTransition ) transition;

- ( void ) synchronizeView ;


@end
