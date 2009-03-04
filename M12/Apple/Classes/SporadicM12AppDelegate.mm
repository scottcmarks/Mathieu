//
//  SporadicM12AppDelegate.m
//  SporadicM12
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright Magnolia Heights Research and Development. 2008. All rights reserved.
//

#include "rand_utils.h"    
#import "RootViewController.h"
#import "SporadicM12AppDelegate.h"
#import "GameModel.h"
#import "iPhoneUtilities.h"


static NSString *SporadicM12AnimationSpeedKey = @"SporadicM12AnimationSpeedKey" ;
static NSString *SporadicM12SoundEffectsKey   = @"SporadicM12SoundEffectsKey"   ;
static NSString *SporadicM12ConfirmKey        = @"SporadicM12ConfirmKey"        ;
static NSString *SporadicM12InvertKey         = @"SporadicM12InvertKey"         ;
static NSString *SporadicM12SpinMessagesKey   = @"SporadicM12SpinMessagesKey"   ;
static NSString *SporadicM12GameModelKey      = @"SporadicM12GameModelKey"      ;

@implementation SporadicM12AppDelegate

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
    if ( self == [SporadicM12AppDelegate class]) {
        
        __timestamp__;
        
        initialize_rand( );  //TODO: mach_time?
        
        // Register default values for the persistent state. 
        // This will be used when the app has never previously terminated.
        [ [ NSUserDefaults standardUserDefaults ]  
              registerDefaults: [ NSDictionary 
                                      dictionaryWithObjectsAndKeys: 
                                      [ NSNumber numberWithFloat: 2.0 ] , SporadicM12AnimationSpeedKey ,
                                      [ NSNumber numberWithBool:true  ] , SporadicM12SoundEffectsKey   ,
                                      [ NSNumber numberWithBool:true  ] , SporadicM12ConfirmKey        ,
                                      [ NSNumber numberWithBool:false ] , SporadicM12InvertKey         ,
                                      [ NSNumber numberWithBool:false ] , SporadicM12SpinMessagesKey   ,
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
    self.animationSpeed  = [ defaults floatForKey:SporadicM12AnimationSpeedKey ];
    self.soundEffects    = [ defaults boolForKey: SporadicM12SoundEffectsKey   ];
    self.confirm         = [ defaults boolForKey: SporadicM12ConfirmKey        ];
    self.invert          = [ defaults boolForKey: SporadicM12InvertKey         ];
    self.useSpinMessages = [ defaults boolForKey: SporadicM12SpinMessagesKey   ];

    __timestamp__;
    
    self.gameModel       = [ GameModel createFromData:[ defaults dataForKey:SporadicM12GameModelKey ] ];
    
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
    [ defaults setFloat:  self.animationSpeed       forKey:SporadicM12AnimationSpeedKey ];
    [ defaults setBool:   self.soundEffects         forKey:SporadicM12SoundEffectsKey   ];
    [ defaults setBool:   self.confirm              forKey:SporadicM12ConfirmKey        ];
    [ defaults setBool:   self.invert               forKey:SporadicM12InvertKey         ];
    [ defaults setBool:   self.useSpinMessages      forKey:SporadicM12SpinMessagesKey   ];
    [ defaults setObject: [ self.gameModel asData ] forKey:SporadicM12GameModelKey      ];
}


- (void)dealloc {
	self.rootViewController = nil ;
    self.window             = nil ;
    self.gameModel          = nil;
    [super dealloc];
}


@end
