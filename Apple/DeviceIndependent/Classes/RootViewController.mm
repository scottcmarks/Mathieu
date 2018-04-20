//
//  RootViewController.mm
//  Top-level view controller in the SporadicM application
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "SporadicMAppDelegate.h"
#import "RootViewController.h"
#import "SporadicMViewController.h"
#import "PreferencesViewController.h"
#import "Constants.h"
#import "iPhoneUtilities.h"

@implementation RootViewController

@synthesize mainViewController;
@synthesize preferencesViewController;
#if TARGET_IOS
@synthesize nowHandlingShake;
#endif /* TARGET_IOS */

// TODO:  Factor out common code.
// This might require invention of a common superclass for PV controller and mainview controller.
// If so, I'm thinking to change what is now call SporadicMView* to MainView* and use the names
// SporadicMView* for the common superclass.  Slightly too much C12H22O11 for $0.10 at the moment.
// Also, code might fork as MVC persistent state acquires things the PVC doesn't know about.

- (void)loadPreferencesViewController
{
    NSString * nibName = DEVICE_IS_IPAD ? @"PreferencesView-iPad" : @"PreferencesView" ;
    PreferencesViewController *viewController = [[PreferencesViewController alloc] initWithNibName: nibName bundle:nil];
    self.preferencesViewController = viewController;
    viewController.rootViewController = self;
    [viewController release];
}


- (void)loadMainViewController
{
    NSString * nibName = DEVICE_IS_IPAD ? @"SporadicMView-iPad" : @"SporadicMView" ;
    SporadicMViewController *viewController = [[SporadicMViewController alloc] initWithNibName: nibName bundle:nil];
    self.mainViewController = viewController;
    viewController.rootViewController = self;
    [viewController release];
}


- (id) init {
    if ( self = [super init] )
        [self loadMainViewController];
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.mainViewController.view];
	
#if TARGET_IOS && USE_DEPRECATED_ACCELEROMETER_METHODS
	//Configure and enable the accelerometer
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
    self.nowHandlingShake = false;
#endif /* TARGET_IOS */
	
}


- (void) flipFrom:( ViewController * )oldViewController
               to:( ViewController * )newViewController
      transition: (RootViewControllerTransition) transition
{
#if TARGET_IOS
    UIViewAnimationTransition uitransition;
    switch ( transition )
    {
        case curl:
            uitransition = UIViewAnimationTransitionCurlUp;
            break;
        case flip:
            uitransition = UIViewAnimationTransitionFlipFromLeft;
            break;
        case flop:
            uitransition = UIViewAnimationTransitionFlipFromRight;
            break;
        default:
            uitransition = UIViewAnimationTransitionNone;
    }
	[View beginAnimations:nil context:NULL];
	[View setAnimationDuration: 1.0 ];	
	[View setAnimationTransition:uitransition
                           forView:self.view
                             cache:YES];
    [newViewController viewWillAppear:YES];
    [oldViewController viewWillDisappear:YES];
#endif /* TARGET_IOS */
    [oldViewController.view removeFromSuperview];
    [self.view addSubview:newViewController.view];
#if TARGET_IOS
    [oldViewController viewDidDisappear:YES];
    [newViewController viewDidAppear:YES];
    [View commitAnimations];
#endif /* TARGET_IOS */
}


- ( void ) synchronizeView { [ self.mainViewController synchronizeView ] ; }


- (void)toggleView
{	
    // This method is called when the info or Done button is pressed.
    // It flips the displayed view from the main view to the flipside view and vice-versa.

	if (preferencesViewController == nil)
		[self loadPreferencesViewController];
	
	if ( [mainViewController.view superview] )
        [self flipFrom: mainViewController to: preferencesViewController transition: flop];
    else
        [self flipFrom: preferencesViewController to: mainViewController transition: flip];
}

- ( void ) setSwapIndex: ( int ) newSwapIndex
{
    [ mainViewController setSwapIndex: newSwapIndex ];
}


- (void)dealloc {
    self.mainViewController = nil;
    self.preferencesViewController = nil;
    [super dealloc];
}


#if TARGET_IOS
// Called when the accelerometer detects motion; plays the erase sound and redraws the view if the motion is over a threshold.
#if USE_DEPRECATED_ACCELEROMETER_METHODS
- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate: ( UIAcceleration * ) acceleration
{
	UIAccelerationValue	length ;
    UIAccelerationValue	x      ;
    UIAccelerationValue	y      ;
    UIAccelerationValue	z      ;
	
	//Use a basic high-pass filter to remove the influence of the gravity
	myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
	myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
	myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
	// Compute values for the three axes of the acceleromater
	x = acceleration.x - myAccelerometer[ 0 ];
	y = acceleration.y - myAccelerometer[ 0 ];
	z = acceleration.z - myAccelerometer[ 0 ];
	
	//Compute the intensity of the current acceleration
	length = sqrt(x * x + y * y + z * z);
	// If above a given threshold, send the shake message
	if ( ( kEraseAccelerationThreshold <= length)
        && (lastShakeTime + kMinEraseInterval < CFAbsoluteTimeGetCurrent( ) )
        && [mainViewController.view superview]
        && ! self.nowHandlingShake )
    {
        self.nowHandlingShake = true;
		lastShakeTime = CFAbsoluteTimeGetCurrent( ) ;
		[ mainViewController shake ];
	}
}
#endif // USE_DEPRECATED_ACCELEROMETER_METHODS

- ( void ) motionEnded: ( UIEventSubtype ) motion withEvent: ( UIEvent * ) event {
    if ( motion == UIEventSubtypeMotionShake ) {
        [ mainViewController shake ];
    }
}


#if TARGET_IOS && OVERRIDE_DEPRECATED
- ( BOOL ) shouldAutorotateToInterfaceOrientation: ( UIInterfaceOrientation ) interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsPortrait(interfaceOrientation ) ;
}
#endif // TARGET_IOS && OVERRIDE_DEPRECATED


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#endif /* TARGET_IOS */



@end
