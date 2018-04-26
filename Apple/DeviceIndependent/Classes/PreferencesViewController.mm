//
//  PreferencesViewController.mm
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "PreferencesViewController.h"
#import "SporadicMAppDelegate.h"
#import "SporadicMViewController.h"
#import "GameModel.h"
#import "PreferencesView.h"
#import "HelpViewController.h"
#import "SwapPermutationsView.h"
#import "SwapPermutationsViewController.h"

#import "NSBundle+VersionString.h"
#import "iPhoneUtilities.h"

@implementation PreferencesViewController

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
    [ viewController release ];
}

- (void)loadSwapPermutationsViewController
{
    SwapPermutationsViewController *viewController = [[SwapPermutationsViewController alloc] initWithNibName:@"SwapPermutationsView" bundle:nil];
    self.swapPermutationsViewController = viewController;
    viewController.preferencesViewController = self;
    [ viewController release ];
}

- ( IBAction )toggleView
{
    abort();
}


- (IBAction)showHelp
{
    if ( self.helpViewController == nil )
        [ self loadHelpViewController ];
    abort();
}


- (IBAction)showSwapPermutations
{
    if ( self.swapPermutationsViewController == nil )
        [ self loadSwapPermutationsViewController ];
    abort();
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
    [preferencesView synchronize];
}

#if TARGET_IOS && OVERRIDE_DEPRECATED
// Override to allow orientations other than the default portrait orientation.
- ( BOOL ) shouldAutorotateToInterfaceOrientation: ( UIInterfaceOrientation ) interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsPortrait(interfaceOrientation ) ;
}
#endif




//- (BOOL)canPerformUnwindSegueAction:(SEL)action
//                 fromViewController:(UIViewController *)fromViewController
//                         withSender:(id)sender {
//    return YES;
//}


-(IBAction)prepareForUnwindToPreferences:(UIStoryboardSegue *)segue {
    return;
}



- ( void ) dealloc
{
    self.helpViewController = nil;
    self.preferencesView = nil;
    self.swapPermutationsViewController = nil;
    [ super dealloc ] ;
}

@end
