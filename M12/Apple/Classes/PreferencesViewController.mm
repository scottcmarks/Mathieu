//
//  PreferencesViewController.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import "PreferencesViewController.h"
#import "SporadicM12AppDelegate.h"

@implementation PreferencesViewController

@synthesize rootViewController;
@synthesize preferencesView;
@synthesize helpViewController;

- ( SporadicM12AppDelegate * ) appDelegate{ return ( SporadicM12AppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // this will appear as the title in the navigation bar
        self.title = NSLocalizedString(@"M12 Preferences", @"");
    }
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
//  Never called because we are loaded from a Nib, not by the alloc/init dance
//  - ( void ) viewDidLoad {
//  [ super viewDidLoad ];
//  }

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//  - (void)didReceiveMemoryWarning {
//      [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
//      // Release anything that's not essential, such as cached data shadow?
//  }


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
