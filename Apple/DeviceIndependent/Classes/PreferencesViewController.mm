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

@implementation PreferencesViewController

@synthesize rootViewController;
@synthesize preferencesView;
@synthesize helpViewController;
@synthesize swapPermutationsViewController;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }


#if TARGET_OS_IPHONE
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#endif

- (void)dealloc {
    self.rootViewController = nil;
    self.helpViewController = nil;
    self.preferencesView = nil;
    [super dealloc];
}

- (void)loadHelpViewController {
    HelpViewController *viewController = [[HelpViewController alloc] initWithNibName:@"HelpView" bundle:nil];
    self.helpViewController = viewController;
    viewController.rootViewController = rootViewController;
    [viewController release];
}

- (void)loadSwapPermutationsViewController {
    SwapPermutationsViewController *viewController = [[SwapPermutationsViewController alloc] initWithNibName:@"SwapPermutationsView" bundle:nil];
    self.swapPermutationsViewController = viewController;
    viewController.rootViewController = rootViewController;
    viewController.preferencesViewController = self;
    [ viewController release ];
}

- (IBAction)toggleView:(id)sender 
{
    [ self.rootViewController toggleView ];
}


- (IBAction)showHelp:(id)sender {
    if ( self.helpViewController == nil )
        [ self loadHelpViewController ];
    
    [self.rootViewController flipFrom: self to: helpViewController transition: curl ];
    
}


- (IBAction)showSwapPermutations:(id)sender {
    if ( self.swapPermutationsViewController == nil )
        [ self loadSwapPermutationsViewController ];
    
    [self.rootViewController flipFrom: self to: swapPermutationsViewController transition: curl];
    
}


- (IBAction)animationSpeedChanged:(id)sender {
    self.appDelegate.animationSpeed = preferencesView.animationSpeed ;
}

- (IBAction)soundEffectsSwitchChanged:(id)sender {
    self.appDelegate.soundEffects =
#if TARGET_OS_IPHONE
                                    preferencesView.soundEffectsSwitch.on ;
#elif TARGET_OS_MAC
                                    preferencesView.soundEffectsSwitch.state != 0 ;
#else
#error Don't know this platform!
#endif
}

- (IBAction)confirmSwitchChanged:(id)sender {
    self.appDelegate.confirm =
#if TARGET_OS_IPHONE
                                preferencesView.confirmSwitch.on ;
#elif TARGET_OS_MAC
                                preferencesView.confirmSwitch.state != 0 ;
#else
#error Don't know this platform!
#endif
}



@end
