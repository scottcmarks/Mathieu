//
//  SporadicMAppDelegate.m
//  SporadicM
//
//  Created by Scott Marks on 10/14/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#include "rand_utils.h"
#import "SporadicMViewController.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"
#import "iPhoneUtilities.h"


static NSString * const SporadicMAnimationSpeedKey = @"SporadicMAnimationSpeedKey" ;
static NSString * const SporadicMSoundEffectsKey   = @"SporadicMSoundEffectsKey"   ;
static NSString * const SporadicMConfirmKey        = @"SporadicMConfirmKey"        ;
static NSString * const SporadicMInvertKey         = @"SporadicMInvertKey"         ;
static NSString * const SporadicMGameModelKey      = @"SporadicMGameModelKey"      ;

@implementation SporadicMAppDelegate

@synthesize window;
@synthesize animationSpeed;
@synthesize soundEffects;
@synthesize confirm;
@synthesize invert;
@synthesize gameModel;


// Invoked after the application has been launched and initialized but before it has received its first event.
- ( BOOL ) application: ( AppleApplication * ) application didFinishLaunchingWithOptions: ( NSDictionary * ) launchOptions
{
#define APPLICATIONDIDFINISHLAUNCHING_DEBUG_LEVEL 1
    
#if APPLICATIONDIDFINISHLAUNCHING_DEBUG_LEVEL <= DEBUG_LEVEL
    __timestamp__;
#endif
    
    initialize_rand( ) ;
    
    // Register default values for the persistent state.
    // This will be used when the app has never previously terminated.
    NSDictionary * defaults = @{SporadicMAnimationSpeedKey : @2.0,
                                SporadicMSoundEffectsKey   : @YES,
                                SporadicMConfirmKey        : @YES,
                                SporadicMInvertKey         : @NO,
                               };
    [ [ NSUserDefaults standardUserDefaults ] registerDefaults: defaults ];
    return YES ;
}

// Invoked after the application has been launched and initialized but before it has received its first event.
- ( void ) applicationDidBecomeActive: ( AppleApplication * ) application
{
#define APPLICATIONDIDBECOMEACTIVE_DEBUG_LEVEL 1

   // Restore application settings
    NSUserDefaults * defaults = [ NSUserDefaults standardUserDefaults ] ;
    self.animationSpeed  = [ defaults floatForKey:SporadicMAnimationSpeedKey ];
    self.soundEffects    = [ defaults boolForKey: SporadicMSoundEffectsKey   ];
    self.confirm         = [ defaults boolForKey: SporadicMConfirmKey        ];
    self.invert          = [ defaults boolForKey: SporadicMInvertKey         ];

#if APPLICATIONDIDBECOMEACTIVE_DEBUG_LEVEL <= DEBUG_LEVEL
    __timestamp__;
#endif

    self.gameModel       = [ GameModel gameFromData:[ defaults dataForKey:SporadicMGameModelKey ] ];
    
    [ ((SporadicMViewController *)self.window.rootViewController) initializeView ] ;

#if APPLICATIONDIDBECOMEACTIVE_DEBUG_LEVEL <= DEBUG_LEVEL
    __timestamp__;
#endif

}

#if TARGET_MACOS
- ( BOOL ) applicationShouldTerminateAfterLastWindowClosed: ( AppleApplication * ) sender
{
    // return YES to allow the application to terminate when the user closes the last window the application has open
    return YES;
}
#endif


// - ( void ) applicationDidEnterBackground: ( AppleApplication * ) application
//
// Tells the delegate that the application is now in the background.
//
// Parameters
//   application
//     The singleton application instance.
//
- ( void ) applicationDidEnterBackground: ( AppleApplication * ) application
{
    NSUserDefaults * defaults = [ NSUserDefaults standardUserDefaults ] ;
    [ defaults setFloat:  self.animationSpeed       forKey: SporadicMAnimationSpeedKey ] ;
    [ defaults setBool:   self.soundEffects         forKey: SporadicMSoundEffectsKey   ] ;
    [ defaults setBool:   self.confirm              forKey: SporadicMConfirmKey        ] ;
    [ defaults setBool:   self.invert               forKey: SporadicMInvertKey         ] ;
    [ defaults setObject: [ self.gameModel data ]   forKey: SporadicMGameModelKey      ] ;
    [ defaults synchronize ] ;
}


// Invoked immediately before the application terminates.
- ( void ) applicationWillTerminate: ( AppleApplication * ) application
{
    [ self applicationDidEnterBackground: application ] ;
}


- ( void ) dealloc
{
    self.window             = nil ;
    self.gameModel          = nil;
    [ super dealloc ] ;
}


@end
