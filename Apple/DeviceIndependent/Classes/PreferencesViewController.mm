//
//  PreferencesViewController.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "PreferencesViewController.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"
#import "RootViewController.h"
#import "PreferencesView.h"
#import "HelpViewController.h"
#import "SwapPermutationsView.h"
#import "SwapPermutationsViewController.h"

#import "NSBundle+VersionString.h"
#import "iPhoneUtilities.h"

@implementation PreferencesViewController

@synthesize rootViewController;
@synthesize preferencesView;
@synthesize helpViewController;
@synthesize swapPermutationsViewController;
@synthesize versionStringLabel ;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }


-(IBAction) done:(id)sender
{
#pragma unused(sender)
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadHelpViewController
{
    NSString * nibName = DEVICE_IS_IPAD ? @"HelpView-iPad" : @"HelpView" ;
    HelpViewController *viewController = [[HelpViewController alloc] initWithNibName: nibName bundle:nil];
    self.helpViewController = viewController;
    viewController.rootViewController = rootViewController;
    [ viewController release ];
}

- (void)loadSwapPermutationsViewController
{
    SwapPermutationsViewController *viewController = [[SwapPermutationsViewController alloc] initWithNibName:@"SwapPermutationsView" bundle:nil];
    self.swapPermutationsViewController = viewController;
    viewController.rootViewController = rootViewController;
    viewController.preferencesViewController = self;
    [ viewController release ];
}

- ( IBAction )toggleView
{
    [ self.rootViewController toggleView ];
}


- (IBAction)showHelp
{
    if ( self.helpViewController == nil )
        [ self loadHelpViewController ];

    [self.rootViewController flipFrom: self to: helpViewController transition: curl ];

}


- (IBAction)showSwapPermutations
{
    if ( self.swapPermutationsViewController == nil )
        [ self loadSwapPermutationsViewController ];

    [self.rootViewController flipFrom: self to: swapPermutationsViewController transition: curl];

}


- (IBAction)animationSpeedChanged
{
    self.appDelegate.animationSpeed = preferencesView.animationSpeed ;
}

- (IBAction)soundEffectsSwitchChanged
{
    self.appDelegate.soundEffects =
#if TARGET_IOS
                                    preferencesView.soundEffectsSwitch.on ;
#elif TARGET_MACOS
                                    preferencesView.soundEffectsSwitch.state != 0 ;
#else
#error Don't know this platform!
#endif
}

- (IBAction)confirmSwitchChanged
{
    self.appDelegate.confirm =
#if TARGET_IOS
                                preferencesView.confirmSwitch.on ;
#elif TARGET_MACOS
                                preferencesView.confirmSwitch.state != 0 ;
#else
#error Don't know this platform!
#endif
}



- ( void ) viewDidLoad
{
    [ super viewDidLoad ] ;
    self.versionStringLabel.text = [ NSBundle versionString ] ;
}

#if TARGET_IOS && OVERRIDE_DEPRECATED
// Override to allow orientations other than the default portrait orientation.
- ( BOOL ) shouldAutorotateToInterfaceOrientation: ( UIInterfaceOrientation ) interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsPortrait(interfaceOrientation ) ;
}
#endif

- ( void ) dealloc
{
    self.rootViewController = nil;
    self.helpViewController = nil;
    self.preferencesView = nil;
    self.swapPermutationsViewController = nil;
    [ super dealloc ] ;
}

@end
