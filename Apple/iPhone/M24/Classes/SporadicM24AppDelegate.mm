//
//  SporadicM24AppDelegate.m
//  SporadicM24
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright Magnolia Heights Research and Development. 2008. All rights reserved.
//

#include "rand_utils.h"
#import "RootViewController.h"
#import "SporadicM24AppDelegate.h"
#import "GameModel.h"
#import "iPhoneUtilities.h"


static NSString *SporadicM24AnimationSpeedKey = @"SporadicM24AnimationSpeedKey" ;
static NSString *SporadicM24SoundEffectsKey   = @"SporadicM24SoundEffectsKey"   ;
static NSString *SporadicM24ConfirmKey        = @"SporadicM24ConfirmKey"        ;
static NSString *SporadicM24InvertKey         = @"SporadicM24InvertKey"         ;
static NSString *SporadicM24SpinMessagesKey   = @"SporadicM24SpinMessagesKey"   ;
static NSString *SporadicM24GameModelKey      = @"SporadicM24GameModelKey"      ;

@implementation SporadicM24AppDelegate

@synthesize window;
@synthesize rootViewController;
@synthesize animationSpeed;
@synthesize soundEffects;
@synthesize confirm;
@synthesize invert;
@synthesize useSpinMessages;
@synthesize gameModel;

// +initialize is invoked before the class receives any other messages, so it
// is a good place to set up application defaults
+ (void)initialize {
    if ( self == [SporadicM24AppDelegate class]) {

        __timestamp__;

        initialize_rand( );  //TODO: mach_time?

        // Register default values for the persistent state.
        // This will be used when the app has never previously terminated.
        [ [ NSUserDefaults standardUserDefaults ]
              registerDefaults: [ NSDictionary
                                      dictionaryWithObjectsAndKeys:
                                      [ NSNumber numberWithFloat: 2.0 ] , SporadicM24AnimationSpeedKey ,
                                      [ NSNumber numberWithBool:true  ] , SporadicM24SoundEffectsKey   ,
                                      [ NSNumber numberWithBool:true  ] , SporadicM24ConfirmKey        ,
                                      [ NSNumber numberWithBool:false ] , SporadicM24InvertKey         ,
                                      [ NSNumber numberWithBool:false ] , SporadicM24SpinMessagesKey   ,
                                      // no default gameModel -- nil will map to new game
                                      nil // sentinel for brain-dead C varargs
                                 ]
        ];

        __timestamp__;

    }
}

// Invoked after the application has been launched and initialized but before it has received its first event.
- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    __timestamp__;

   // Restore application settings
    NSUserDefaults * defaults = [ NSUserDefaults standardUserDefaults ] ;
    self.animationSpeed  = [ defaults floatForKey:SporadicM24AnimationSpeedKey ];
    self.soundEffects    = [ defaults boolForKey: SporadicM24SoundEffectsKey   ];
    self.confirm         = [ defaults boolForKey: SporadicM24ConfirmKey        ];
    self.invert          = [ defaults boolForKey: SporadicM24InvertKey         ];
    self.useSpinMessages = [ defaults boolForKey: SporadicM24SpinMessagesKey   ];

    __timestamp__;

    self.gameModel       = [ GameModel createFromData:[ defaults dataForKey:SporadicM24GameModelKey ] ];

    __timestamp__;

    // Set up root view controller
    rootViewController = [[RootViewController alloc] init];

    __timestamp__;

    // Add the root view controller's view to the window.
    // This is a little sneaky, as the view property will
    // create a view on demand, and even call viewDidLoad on it.
    [ window addSubview: [ rootViewController view ] ];
    __timestamp__;

}

// Invoked immediately before the application terminates.
- (void)applicationWillTerminate:(UIApplication *)application {
    // Store user's time signature preference, so that it is used the next time the app is launched
    NSUserDefaults * defaults = [ NSUserDefaults standardUserDefaults ] ;
    [ defaults setFloat:  self.animationSpeed       forKey:SporadicM24AnimationSpeedKey ];
    [ defaults setBool:   self.soundEffects         forKey:SporadicM24SoundEffectsKey   ];
    [ defaults setBool:   self.confirm              forKey:SporadicM24ConfirmKey        ];
    [ defaults setBool:   self.invert               forKey:SporadicM24InvertKey         ];
    [ defaults setBool:   self.useSpinMessages      forKey:SporadicM24SpinMessagesKey   ];
    [ defaults setObject: [ self.gameModel asData ] forKey:SporadicM24GameModelKey      ];
}


- (void)dealloc {
	self.rootViewController = nil ;
    self.window             = nil ;
    self.gameModel          = nil;
    [super dealloc];
}


@end
