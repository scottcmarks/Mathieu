//
//  SporadicMViewController.m
//  SporadicM
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#include "view.h"
#import "SporadicMAppDelegate.h"
#import "RootViewController.h"
#import "SporadicMViewController.h"
#import "SporadicMView.h"
#import "BallView.h"
#import "BallRingView.h"
#import "OKCancelAlertView.h"
#import "Constants.h"
#import "iPhoneUtilities.h"

@implementation SporadicMViewController

@synthesize rootViewController;
@synthesize alert;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }
- ( SporadicMView *) spview { return (SporadicMView *) self.view ; }
- ( BallRingView * ) ballRingView { return self.spview.ballRingView; }

- ( bool ) confirm { return self.appDelegate.confirm; }
- ( bool ) invert  { return self.appDelegate.invert; }
- ( void ) setInvert:(bool)inverted { [ self.spview setInvertibleButtonsInverted: ( self.appDelegate.invert = inverted ) ]; }

// Framework-generated messages
#if TARGET_OS_IPHONE

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [ super viewDidLoad ];
    haveNotedSuccess = [ self.gameModel isSolving ] && [ self.gameModel isIdentity ];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#endif /* TARGET_OS_IPHONE */

- (void)dealloc
{
    self.rootViewController = nil;
    self.alert = nil ;
    [super dealloc];
}



// Handlers for events from the SporadicMView


- (IBAction)toggleView:(id)sender
{
    [ rootViewController toggleView ];
}

- (IBAction)toggleInverted:(id)sender{
    self.invert = !self.invert ;
}

- ( CGFloat ) appropriateDurationForMove: ( HistoryElement ) e
{
    if ( History::is_left( e ) )
        return min( ( -e ) * SMALL_MOVE_DURATION, LARGE_MOVE_DURATION );
    if ( History::is_right( e ) )
        return min( ( +e ) * SMALL_MOVE_DURATION, LARGE_MOVE_DURATION );
    return LARGE_MOVE_DURATION;
}

- ( void )updateDuration: ( CGFloat ) duration
{
    [ self.spview showCurrentPermutationAtDuration: duration ];

    if ( [ self.gameModel isSolving ] && [ self.gameModel isIdentity ] && !haveNotedSuccess )
    {
        [ self.ballRingView playSuccessSound ];
        haveNotedSuccess = true ;
    }

}

- ( void ) showCurrentPermutationAfterMove: ( HistoryElement ) e
{
    [ self updateDuration: [ self appropriateDurationForMove: e ] ];
}

- ( void ) playAfterMove: ( HistoryElement ) e
{
    if ( History::is_left( e ) )
        [ self.ballRingView playLeftSound ];
    else if ( History::is_right( e ) )
        [ self.ballRingView playRightSound ];
    else if ( History::is_swap( e ) )
        [ self.ballRingView playSwapSound ];
    else
        [ self.ballRingView playComboSound ];
}


- (void)doSetCombo: ( id ) comboNameAsObject
{
    HistoryElement comboName = ( int ) comboNameAsObject ;
    self.invert = false;
    if ( [ self.gameModel historyIsEmpty ] )
        [ self.gameModel eraseCombo: comboName ];
    else
        [ self.gameModel setCombo: comboName ];
    [ self.spview setComboButton:comboName enabled: [ self.gameModel hasDefinedCombo:comboName ] ];
}

-(void) confirmSetCombo: ( id ) comboNameAsObject
{
    HistoryElement comboName = ( int ) comboNameAsObject ;
    if ( ! [ self.gameModel hasDefinedCombo:      comboName ]   // Don't confirm if no definition, or
        || [ self.gameModel historyIsSingleCombo: comboName ]  // if just setting to force expand
       )
    {
        [ self doSetCombo: comboNameAsObject ];
        return ;
    }
    const char * verb = [ self.gameModel historyIsEmpty ] ? "erase" : "change" ;
    NSString * alertFormat = @"This will %s the meaning of %c.\nPress OK if you want to do this." ;
    [ alert = [ OKCancelAlertView newAlertWithTitle: @"Combo Set!"
                                            message: [ NSString stringWithFormat:alertFormat, verb, comboName ]
                                             target: self
                                     cancelSelector: NULL
                                         OKSelector: @selector( doSetCombo: )
                                          parameter: comboNameAsObject ] show ];
}



- (void)comboSet: ( HistoryElement )comboName
{
    if ( [ self.gameModel historyIsEmpty ]
            && ! [ self.gameModel hasDefinedCombo:  comboName ] )
        return;

    if ( [ self.gameModel isSolving ] )
    {
        [ self.ballRingView playComboNotSetSound ];
        return;
    }

    [ self.ballRingView playComboSetSound ];
    if ( self.confirm )
        [ self confirmSetCombo: ( id ) comboName ];
    else
        [ self doSetCombo: ( id ) comboName ];
}


- ( void ) combo: ( HistoryElement ) comboName inverse: ( bool ) inverse ;
{
    if ( [ self.gameModel hasDefinedCombo: comboName ] )
    {
        [ self.ballRingView playComboSound ];
        [ self.gameModel runCombo: comboName inverted: inverse ];
        [ self updateDuration: LARGE_MOVE_DURATION ];
    }
    self.invert = false ;
}

- (IBAction) comboInvoked: ( HistoryElement ) comboName
{
    [ self combo: comboName inverse: false ] ;
}

- (IBAction) comboInverseInvoked: ( HistoryElement ) comboName
{
    [ self combo: comboName inverse: true  ] ;
}

-(IBAction) left: (id)sender{
    [ self.ballRingView playLeftSound ];
    [ self.gameModel left ];
    self.invert = false ;
    [ self updateDuration: SMALL_MOVE_DURATION ];
}

-(IBAction) swap: (id)sender{
    [ self.ballRingView playSwapSound ];
    [ self.gameModel swap ];
    self.invert = false ;
    [ self updateDuration: LARGE_MOVE_DURATION ];
}

-(IBAction) right: (id)sender{
    [ self.ballRingView playRightSound ];
    [ self.gameModel right ];
    self.invert = false ;
    [ self updateDuration: SMALL_MOVE_DURATION ];
}

-(void) spinInProgress: (int) wedges{
    self.invert = false ;
    [ self.gameModel spin: wedges ];
//      [ self.spview updateHistoryText ];
}

- (void) spinFinished: (int)wedges{
    self.invert = false ;
    [ self.gameModel spin: wedges ];
    [ self updateDuration: INSTANTANEOUS ];
}

- (void) swapped { [ self swap: nil ] ; }

-( void ) undo: ( bool ) move{
    HistoryElement e;
    if ( [ self.gameModel undo: move move: e ] )
    {
      // make the appropriate noise and use the appropriate duration
        [ self playAfterMove: -e ];
        [ self showCurrentPermutationAfterMove: e ];
    }
    if ( [ self.gameModel historyIsEmpty ] )
        self.invert = false ;
}


-(IBAction) undoMove: (id)sender { [ self undo: true  ] ; }


-(IBAction) undoStep: (id)sender { [ self undo: false ] ; }


-(void) doHome {
    self.invert = false ;
    [ self.gameModel reset ];
    [ self updateDuration: LARGE_MOVE_DURATION ];
}

-(void) confirmHome
{
    [ alert = [ OKCancelAlertView newAlertWithTitle: @"Home!"
                                         message: @"This will reset " applicationName @" to the home position.\n"
                                                  @"Press OK if you want to do this."
                                          target: self
                                  cancelSelector: NULL
                                      OKSelector: @selector( doHome ) ] show ];
}

-(IBAction) home: (id)sender{
    [ self.ballRingView playHomeSound ];
    if ( self.confirm && [self.gameModel isSolving ] )
        [ self confirmHome ];
    else
        [ self doHome ];
}


-(void) doShake{
    self.invert = false ;
    [ self.gameModel random ];
    [ self updateDuration: LARGE_MOVE_DURATION ];
#if TARGET_OS_IPHONE
    self.rootViewController.nowHandlingShake = false;
#endif /* TARGET_OS_IPHONE */
    haveNotedSuccess = false;
}


-(void) noShake{
#if TARGET_OS_IPHONE
    self.rootViewController.nowHandlingShake = false;
#endif /* TARGET_OS_IPHONE */
}


-(void) doRestart
{
    self.invert = false ;
    if ( [ self.gameModel isSolving ] )
        [ self.gameModel revert ];
    [ self updateDuration: LARGE_MOVE_DURATION ];
#if TARGET_OS_IPHONE
    self.rootViewController.nowHandlingShake = false;
#endif /* TARGET_OS_IPHONE */
}


-(void) noRestart
{
    self.invert = false ;
}



-(void) confirmShake
{
    [ alert = [ OKCancelAlertView newAlertWithTitle: @"Shake!"
                                            message: @"This will create a new " applicationName @" puzzle.\n"
               @"Press OK if you want to do this."
                                             target: self
                                     cancelSelector: @selector( noShake )
                                         OKSelector: @selector( doShake ) ] show ];
}

-(void) confirmRestart
{
    [ alert = [ OKCancelAlertView newAlertWithTitle: @"Restart!"
                                            message: @"This will restart solving this puzzle.\n"
               @"Press OK if you want to do this."
                                             target: self
                                     cancelSelector: @selector( noRestart )
                                         OKSelector: @selector( doRestart ) ] show ] ;
}


-(IBAction) shake: (id)sender
{
    [ self.ballRingView playShakeSound ];
    if ( self.confirm && [self.gameModel isSolving ] )
        [ self confirmShake ];
    else
        [ self doShake ];
}


-(IBAction) restart: (id)sender
{
    [ self.ballRingView playRestartSound ];
    if ( self.confirm && [self.gameModel isSolving ] )
        [ self confirmRestart ];
    else
        [ self doRestart ];
}



-( void ) doChangeSwap: (int) newSwapIndex
{
    self.gameModel.swapIndex = newSwapIndex;
    [ self.gameModel reset ];
    [ self.gameModel eraseAllCombos ];
    [ self.spview disableAllComboButtons ];
    [ self.ballRingView redraw ];
    [ self.spview showCurrentPermutationAtDuration:INSTANTANEOUS ];
    [ self.rootViewController toggleView ];
}


-( void ) dontChangeSwap: (int) newSwapIndex
{
    [ BallView setColorsForSwapPermutation: MathieuPermutation::swapPermutation ];
    [ self.rootViewController toggleView ];
}


-( void ) setSwapIndex: ( int ) newSwapIndex
{
    if ( newSwapIndex == self.gameModel.swapIndex )
        [ self dontChangeSwap: nil ];
    else
    {
        NSString * message = @"This will change the meaning of Swap.\n" ;
        if ( [ self.gameModel isSolving ] )
            message = [ message stringByAppendingString: @"The current puzzle will be discarded!\n" ];
        else if ( ! [ self.gameModel historyIsEmpty ] )
            message = [ message stringByAppendingString: @"The position will be reset.\n" ];
        if ( [ self.gameModel hasAnyDefinedCombo ] )
            message = [ message stringByAppendingString: @"All combo moves will be erased!\n" ];
        message = [ message stringByAppendingString: @"Press OK if you want to do this." ];
        [ alert = [ OKCancelAlertView newAlertWithTitle: @"New Swap!"
                                                message: message
                                                 target: self
                                         cancelSelector: @selector( dontChangeSwap: )
                                             OKSelector: @selector( doChangeSwap: )
                                              parameter: (id)newSwapIndex ] show ] ;
    }
}


@end
