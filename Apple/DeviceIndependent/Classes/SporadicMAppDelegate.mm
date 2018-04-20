//
//  SporadicMAppDelegate.m
//  SporadicM
//
//  Created by Scott Marks on 10/14/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#include "rand_utils.h"
#import "RootViewController.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"
#import "iPhoneUtilities.h"


static NSString * const SporadicMAnimationSpeedKey = @"SporadicMAnimationSpeedKey" ;
static NSString * const SporadicMSoundEffectsKey   = @"SporadicMSoundEffectsKey"   ;
static NSString * const SporadicMConfirmKey        = @"SporadicMConfirmKey"        ;
static NSString * const SporadicMInvertKey         = @"SporadicMInvertKey"         ;
static NSString * const SporadicMSpinMessagesKey   = @"SporadicMSpinMessagesKey"   ;
static NSString * const SporadicMGameModelKey      = @"SporadicMGameModelKey"      ;

@implementation SporadicMAppDelegate

@synthesize window;
@synthesize animationSpeed;
@synthesize soundEffects;
@synthesize confirm;
@synthesize invert;
@synthesize gameModel;

// +initialize is invoked before the class receives any other messages, so it
// is a good place to set up application defaults

+ ( void ) initialize
{
#define INITIALIZE_DEBUG_LEVEL 1
    if ( self == [ SporadicMAppDelegate class ] )
    {
#if INITIALIZE_DEBUG_LEVEL <= DEBUG_LEVEL
        __timestamp__;
#endif

        initialize_rand( ) ;

        // Register default values for the persistent state.
        // This will be used when the app has never previously terminated.
        [ [ NSUserDefaults standardUserDefaults ] registerDefaults: @{SporadicMAnimationSpeedKey : @2.0,
                                                                      SporadicMSoundEffectsKey   : @YES,
                                                                      SporadicMConfirmKey        : @NO, // @YES, // DEBUG  // TODO
                                                                      SporadicMInvertKey         : @NO,
                                                                      SporadicMSpinMessagesKey   : @NO
                                                                     } ];
    }
}

// Invoked after the application has been launched and initialized but before it has received its first event.
- ( BOOL ) application: ( Application * ) application didFinishLaunchingWithOptions: ( NSDictionary * ) launchOptions
{
#define APPLICATIONDIDFINISHLAUNCHING_DEBUG_LEVEL 1

#if OLD_PRESENTATION_LAYER
#if APPLICATIONDIDFINISHLAUNCHING_DEBUG_LEVEL <= DEBUG_LEVEL
    __timestamp__;
#endif
    // Set up root view controller
    RootViewController *viewController = [ RootViewController new ];
    self.window.rootViewController = viewController;
    [ viewController release ] ;
#if APPLICATIONDIDFINISHLAUNCHING_DEBUG_LEVEL <= DEBUG_LEVEL
    __timestamp__;
#endif
    
    // Add the root view controller's view to the window
#if TARGET_IOS
    View * rootView = [ viewController view ];
    [ window_view( window ) addSubview: rootView ];
#elif TARGET_MACOS
    viewController.view = window_view( window );
    [ viewController viewDidLoad ];  // tacky to call this directly?
#else
#error Don't know this platform!
#endif

#else // OLD_PRESENTATION_LAYER
#endif // OLD_PRESENTATION_LAYER
    

    
#if APPLICATIONDIDFINISHLAUNCHING_DEBUG_LEVEL <= DEBUG_LEVEL
    __timestamp__;
#endif
    return YES ;
}

// Invoked after the application has been launched and initialized but before it has received its first event.
- ( void ) applicationDidBecomeActive: ( Application * ) application
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
    
#if OLD_PRESENTATION_LAYER
    [ ((RootViewController *)self.window.rootViewController) synchronizeView ] ;
#else // OLD_PRESENTATION_LAYER
#endif // OLD_PRESENTATION_LAYER

#if APPLICATIONDIDBECOMEACTIVE_DEBUG_LEVEL <= DEBUG_LEVEL
    __timestamp__;
#endif

}

#if TARGET_MACOS
- ( BOOL ) applicationShouldTerminateAfterLastWindowClosed: ( Application * ) sender
{
    // return YES to allow the application to terminate when the user closes the last window the application has open
    return YES;
}
#endif


// - ( void ) applicationDidEnterBackground: ( Application * ) application
//
// Tells the delegate that the application is now in the background.
//
// Parameters
//   application
//     The singleton application instance.
//
- ( void ) applicationDidEnterBackground: ( Application * ) application
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
- ( void ) applicationWillTerminate: ( Application * ) application
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
