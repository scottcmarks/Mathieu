//
//  SwapPermutationsViewController.mm
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
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

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ AppleApplication sharedApplication ] delegate ] ; }
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



- (void)dealloc {
    self.swapPermutationsView = nil;
    [super dealloc];
}

@end
