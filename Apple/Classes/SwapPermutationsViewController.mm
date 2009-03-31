//
//  SwapPermutationsViewController.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "mathieu.h"
#import "SwapPermutationsViewController.h"
#import "RootViewController.h"

@implementation SwapPermutationsViewController
@synthesize rootViewController;
@synthesize swapPermutationsView;
@synthesize preferencesViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // this will appear as the title in the navigation bar
        self.title = NSLocalizedString(appName, @"");
    }
    return self;
}


- (void) showHelp: (id) sender { [ self.preferencesViewController showHelp: sender ] ; }

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

//  - (void)didReceiveMemoryWarning {
//      [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
//      // Release anything that's not essential, such as cached data shadow?
//  }


- (void)dealloc {
    self.rootViewController = nil;
    self.swapPermutationsView = nil;
    [super dealloc];
}

- (IBAction)dismissSwapPermutations:(id)sender 
{
    [ self.rootViewController toggleView ];
}

@end
