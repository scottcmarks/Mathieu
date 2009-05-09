//
//  RootViewController.mm
//  Top-level view controller in the SporadicM application
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "SporadicMAppDelegate.h"
#import "RootViewController.h"
#import "SporadicMViewController.h"
#import "PreferencesViewController.h"
#import "Constants.h"

@implementation RootViewController

@synthesize mainViewController;
@synthesize preferencesViewController;
@synthesize nowHandlingShake;

// TODO:  Factor out common code.
// This might require invention of a common superclass for PV controller and mainview controller.
// If so, I'm thinking to change what is now call SporadicMView* to MainView* and use the names
// SporadicMView* for the common superclass.  Slightly too much C12H22O11 for $0.10 at the moment.
// Also, code might fork as MVC persistent state acquires things the PVC doesn't know about.

- (void)loadPreferencesViewController {
    PreferencesViewController *viewController = [[PreferencesViewController alloc] initWithNibName:@"PreferencesView" bundle:nil];
    self.preferencesViewController = viewController;
    viewController.rootViewController = self;
    [viewController release];
}


- (void)loadMainViewController {
    SporadicMViewController *viewController = [[SporadicMViewController alloc] initWithNibName:@"SporadicMView" bundle:nil];
    self.mainViewController = viewController;
    viewController.rootViewController = self;
    [viewController release];
}


- (id) init {
    if ( self = [super init] )
        [self loadMainViewController];
    return self;
}


- (void)viewDidLoad {
    [self.view addSubview:self.mainViewController.view];
	
	//Configure and enable the accelerometer
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
    self.nowHandlingShake = false;
	
}


- (void) flipFrom:( UIViewController * )oldViewController 
               to:( UIViewController * )newViewController
      transition: (RootViewControllerTransition) transition
{
#if TARGET_OS_IPHONE
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
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: 1.0 ];	
	[UIView setAnimationTransition:uitransition
                           forView:self.view 
                             cache:YES];
#endif /* TARGET_OS_IPHONE */
    [newViewController viewWillAppear:YES];
    [oldViewController viewWillDisappear:YES];
    [oldViewController.view removeFromSuperview];
    [self.view addSubview:newViewController.view];
    [oldViewController viewDidDisappear:YES];
    [newViewController viewDidAppear:YES];
#if TARGET_OS_IPHONE
    [UIView commitAnimations];
#endif /* TARGET_OS_IPHONE */
}    


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

// Called when the accelerometer detects motion; plays the erase sound and redraws the view if the motion is over a threshold.
- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	UIAccelerationValue				length,
    x,
    y,
    z;
	
	//Use a basic high-pass filter to remove the influence of the gravity
	myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
	myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
	myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
	// Compute values for the three axes of the acceleromater
	x = acceleration.x - myAccelerometer[0];
	y = acceleration.y - myAccelerometer[0];
	z = acceleration.z - myAccelerometer[0];
	
	//Compute the intensity of the current acceleration 
	length = sqrt(x * x + y * y + z * z);
	// If above a given threshold, send the shake message
	if ( ( kEraseAccelerationThreshold <= length) 
        && (lastShakeTime + kMinEraseInterval < CFAbsoluteTimeGetCurrent() ) 
        && [mainViewController.view superview] 
        && ! self.nowHandlingShake ) 
    {
        self.nowHandlingShake = true;
		lastShakeTime = CFAbsoluteTimeGetCurrent();
		[ mainViewController shake: nil ];
	}
}

- ( void ) setSwapIndex: ( int ) newSwapIndex
{
    [ mainViewController setSwapIndex: newSwapIndex ];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    self.mainViewController = nil;
    self.preferencesViewController = nil;
    [super dealloc];
}


@end
