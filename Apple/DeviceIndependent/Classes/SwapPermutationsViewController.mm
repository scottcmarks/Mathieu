//
//  SwapPermutationsViewController.mm
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "mathieu.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"
#import "BallView.h"
#import "PreferencesViewController.h"
#import "AppleModalAlert.h"
#import "SwapPermutationsView.h"
#import "SwapPermutationsViewController.h"

@implementation SwapPermutationsViewController

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }

@synthesize swapPermutationsView;
@synthesize preferencesViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // this will appear as the title in the navigation bar
        self.title = NSLocalizedString(applicationName, @"");
    }
    return self;
}


- (void) showHelp { [ self.preferencesViewController showHelp ] ; }


#if TARGET_IOS && OVERRIDE_DEPRECATED

// Override to allow orientations other than the default portrait orientation.
- ( BOOL ) shouldAutorotateToInterfaceOrientation: ( UIInterfaceOrientation ) interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsPortrait(interfaceOrientation ) ;
}

//  - (void)didReceiveMemoryWarning {
//      [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
//      // Release anything that's not essential, such as cached data shadow?
//  }

#endif


- (void)dealloc {
    self.swapPermutationsView = nil;
    [super dealloc];
}



- (IBAction)dismissSwapPermutations
{
    int newSwapIndex = swapPermutationsView.pickedSwapIndex ;
    if ( newSwapIndex != self.gameModel.swapIndex )
        abort(); // [ rootViewController setSwapIndex: newSwapIndex ];
    else
        abort(); // [ rootViewController toggleView ];
}


//- (IBAction)unwindToPreferences:(UIStoryboardSegue*)sender
//{
//    UIViewController *sourceViewController = sender.sourceViewController;
//    assert([sourceViewController isKindOfClass:PreferencesViewController.class]);
//    int newSwapIndex = swapPermutationsView.pickedSwapIndex ;
//    if ( newSwapIndex != self.gameModel.swapIndex )
//        abort(); // [ rootViewController setSwapIndex: newSwapIndex ];
//    else
//        abort(); // [ rootViewController toggleView ];
//    
//    // Pull any data from the view controller which initiated the unwind segue.
//}

//- (BOOL)canPerformUnwindSegueAction:(SEL)action
//                 fromViewController:(UIViewController *)fromViewController
//                         withSender:(id)sender {
//    return YES;
//}


- (void) unwindToSporadicM {
    [self performSegueWithIdentifier:@"unwindToSporadicM" sender:nil];
}

-(void) setNewSwapIf:(bool)confirmed {
    if (confirmed) {
        [self unwindToSporadicM];
    } else {
        [swapPermutationsView synchronize];
    }
}

- (void) confirmNewSwapIndex: ( int ) newSwapIndex  {
    return;
}

- (IBAction) done: (id)sender
{
    int newSwapIndex = swapPermutationsView.pickedSwapIndex ;
    if ( newSwapIndex == self.gameModel.swapIndex ) {
        [self unwindToSporadicM];
        return;
    }
    NSString * message = @"This will change the meaning of Swap.\n" ;
    if ( [ self.gameModel isSolving ] )
        message = [ message stringByAppendingString: @"The current puzzle will be discarded!\n" ];
    else if ( ! [ self.gameModel historyIsEmpty ] )
        message = [ message stringByAppendingString: @"The position will be reset.\n" ];
    if ( [ self.gameModel hasAnyDefinedCombo ] )
        message = [ message stringByAppendingString: @"All combo moves will be erased!\n" ];
    message = [ message stringByAppendingString: @"Press OK if you want to do this." ];
    [ AppleModalAlert alertOKCancel:message
                              title:@"New Swap!"
                       continuation:^(bool confirmed) {[self setNewSwapIf:confirmed];}
                                 on:self];
}

-(IBAction)prepareForUnwindToSwapPermutations:(UIStoryboardSegue *)segue {
    return;
}


@end
