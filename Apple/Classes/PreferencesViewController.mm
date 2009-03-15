//
//  PreferencesViewController.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import "PreferencesViewController.h"
#import "SporadicMAppDelegate.h"
#import "RootViewController.h"
#import "PreferencesView.h"
#import "HelpViewController.h"

@implementation PreferencesViewController

@synthesize rootViewController;
@synthesize preferencesView;
@synthesize helpViewController;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

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

- (IBAction)toggleView:(id)sender {
    [self.rootViewController toggleView:self];
}


- (IBAction)showHelp:(id)sender {
    if ( self.helpViewController == nil )
        [ self loadHelpViewController ];
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: 1.0 ];	
	[self.rootViewController setAnimationTransition: UIViewAnimationTransitionCurlUp ];
    [self.rootViewController flipFrom: self to: helpViewController];
	[UIView commitAnimations];

}


- (IBAction)animationSpeedChanged:(id)sender {
    self.appDelegate.animationSpeed = preferencesView.animationSpeed ;
}

- (IBAction)soundEffectsSwitchChanged:(id)sender {
    self.appDelegate.soundEffects = preferencesView.soundEffectsSwitch.on ;
}

- (IBAction)confirmSwitchChanged:(id)sender {
    self.appDelegate.confirm = preferencesView.confirmSwitch.on ;
}

- (IBAction)updatingSwitchChanged:(id)sender {
    self.appDelegate.useSpinMessages = preferencesView.updatingSwitch.on ;
}


@end
