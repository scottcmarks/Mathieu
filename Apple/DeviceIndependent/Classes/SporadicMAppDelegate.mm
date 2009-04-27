//
//  SporadicMAppDelegate.m
//  SporadicM
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright Magnolia Heights Research and Development. 2008. All rights reserved.
//

#include "rand_utils.h"    
#import "RootViewController.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"
#import "iPhoneUtilities.h"


static NSString *SporadicMAnimationSpeedKey = @"SporadicMAnimationSpeedKey" ;
static NSString *SporadicMSoundEffectsKey   = @"SporadicMSoundEffectsKey"   ;
static NSString *SporadicMConfirmKey        = @"SporadicMConfirmKey"        ;
static NSString *SporadicMInvertKey         = @"SporadicMInvertKey"         ;
static NSString *SporadicMSpinMessagesKey   = @"SporadicMSpinMessagesKey"   ;
static NSString *SporadicMGameModelKey      = @"SporadicMGameModelKey"      ;

@implementation SporadicMAppDelegate

@synthesize window;
@synthesize rootViewController;
@synthesize animationSpeed;
@synthesize soundEffects;
@synthesize confirm;
@synthesize invert;
@synthesize gameModel;

// +initialize is invoked before the class receives any other messages, so it
// is a good place to set up application defaults
+ (void)initialize {
    if ( self == [SporadicMAppDelegate class]) {
        
        __timestamp__;
        
        initialize_rand( );  //TODO: mach_time?
        
        // Register default values for the persistent state. 
        // This will be used when the app has never previously terminated.
        [ [ NSUserDefaults standardUserDefaults ]  
              registerDefaults: [ NSDictionary 
                                      dictionaryWithObjectsAndKeys: 
                                      [ NSNumber numberWithFloat: 2.0 ] , SporadicMAnimationSpeedKey ,
                                      [ NSNumber numberWithBool:true  ] , SporadicMSoundEffectsKey   ,
                                      [ NSNumber numberWithBool:true  ] , SporadicMConfirmKey        ,
                                      [ NSNumber numberWithBool:false ] , SporadicMInvertKey         ,
                                      [ NSNumber numberWithBool:false ] , SporadicMSpinMessagesKey   ,
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
    self.animationSpeed  = [ defaults floatForKey:SporadicMAnimationSpeedKey ];
    self.soundEffects    = [ defaults boolForKey: SporadicMSoundEffectsKey   ];
    self.confirm         = [ defaults boolForKey: SporadicMConfirmKey        ];
    self.invert          = [ defaults boolForKey: SporadicMInvertKey         ];

    __timestamp__;
    
    self.gameModel       = [ GameModel createFromData:[ defaults dataForKey:SporadicMGameModelKey ] ];
    
    __timestamp__;
    
    // Set up root view controller 
    RootViewController *viewController = [[RootViewController alloc] init];
    self.rootViewController = viewController;
    [viewController release];
    
    __timestamp__;
    
    // Add the root view controller's view to the window
    [window addSubview:[rootViewController view]];
    __timestamp__;
    
}

// Invoked immediately before the application terminates.
- (void)applicationWillTerminate:(UIApplication *)application {
    // Store user's time signature preference, so that it is used the next time the app is launched
    NSUserDefaults * defaults = [ NSUserDefaults standardUserDefaults ] ;
    [ defaults setFloat:  self.animationSpeed       forKey:SporadicMAnimationSpeedKey ];
    [ defaults setBool:   self.soundEffects         forKey:SporadicMSoundEffectsKey   ];
    [ defaults setBool:   self.confirm              forKey:SporadicMConfirmKey        ];
    [ defaults setBool:   self.invert               forKey:SporadicMInvertKey         ];
    [ defaults setObject: [ self.gameModel asData ] forKey:SporadicMGameModelKey      ];
}


- (void)dealloc {
	self.rootViewController = nil ;
    self.window             = nil ;
    self.gameModel          = nil;
    [super dealloc];
}


@end
