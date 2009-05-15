//
//  SwapPermutationsViewController.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "mathieu.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"
#import "BallView.h"
#import "SwapPermutationsView.h"
#import "SwapPermutationsViewController.h"
#import "RootViewController.h"

@implementation SwapPermutationsViewController

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }

@synthesize rootViewController;
@synthesize swapPermutationsView;
@synthesize preferencesViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // this will appear as the title in the navigation bar
        self.title = NSLocalizedString(applicationName, @"");
    }
    return self;
}


- (void) showHelp: (id) sender { [ self.preferencesViewController showHelp: sender ] ; }


#if TARGET_OS_IPHONE

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

//  - (void)didReceiveMemoryWarning {
//      [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
//      // Release anything that's not essential, such as cached data shadow?
//  }

#endif


- (void)dealloc {
    self.rootViewController = nil;
    self.swapPermutationsView = nil;
    [super dealloc];
}

- (IBAction)dismissSwapPermutations:(id)sender 
{
    int newSwapIndex = swapPermutationsView.pickedSwapIndex ;
    if ( newSwapIndex != self.gameModel.swapIndex )
        [ rootViewController setSwapIndex: newSwapIndex ]; 
    else
        [ rootViewController toggleView ];
}

@end
