//
//  SporadicMViewController.m
//  SporadicM
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#include "view.h"
#import <UIKit/UIFont.h>
#import "SporadicMAppDelegate.h"
#import "RootViewController.h"
#import "SporadicMViewController.h"
#import "SporadicMView.h"
#import "BallRingView.h"
#import "OKCancelAlertView.h"
#import "Constants.h"
#import "iPhoneUtilities.h"

@implementation SporadicMViewController

@synthesize rootViewController;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }
- ( SporadicMView *) spview { return (SporadicMView *) self.view ; }
- ( BallRingView * ) ballRingView { return self.spview.ballRingView; }

- ( bool ) confirm { return self.appDelegate.confirm; }
- ( bool ) invert  { return self.appDelegate.invert; }
- ( void ) setInvert:(bool)inverted { [ self.spview setInvertibleButtonsInverted: ( self.appDelegate.invert = inverted ) ]; }

// Framework-generated messages

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

- (void)dealloc {
    self.rootViewController = nil;
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


- (void)doSetCombo: ( NSNumber * ) comboNameAsObject
{
    HistoryElement comboName = [ comboNameAsObject charValue ] ;
    self.invert = false;
    if ( [ self.gameModel historyIsEmpty ] )
        [ self.gameModel eraseCombo: comboName ];
    else
        [ self.gameModel setCombo: comboName ];
    [ self.spview setComboButton:comboName enabled: [ self.gameModel hasDefinedCombo:comboName ] ];
//      [ self.spview updateHistoryText ];
}

-(void) confirmSetCombo: ( NSNumber * ) comboNameAsObject
{
    HistoryElement comboName = [ comboNameAsObject charValue ];
    if ( ! [ self.gameModel hasDefinedCombo:      comboName ]   // Don't confirm if no definition, or
        || [ self.gameModel historyIsSingleCombo: comboName ]  // if just setting to force expand
       )
    {
        [ self doSetCombo: comboNameAsObject ];
        return ;
    }
    const char * verb = [ self.gameModel historyIsEmpty ] ? "erase" : "change" ;
    NSString * alertFormat = @"This will %s the meaning of %c.\nPress OK if you want to do this." ;
    [ OKCancelAlertView OKCancelAlertWithTitle: @"Combo Set!"
                                       message: [ NSString stringWithFormat:alertFormat, verb, comboName ]
                                        target: self
                                cancelSelector: NULL
                                    OKSelector: @selector( doSetCombo: ) 
                                     parameter: comboNameAsObject ];
}



- (void)comboSet: ( HistoryElement )comboName
{
    if ( [ self.gameModel historyIsEmpty ] 
            && ! [ self.gameModel hasDefinedCombo:  comboName ] )
        return;
        
    [ self.ballRingView playComboSetSound ];
    NSNumber * comboNameAsObject = [ NSNumber numberWithChar: comboName ] ;
    if ( self.confirm ) 
        [ self confirmSetCombo: comboNameAsObject ];
    else
        [ self doSetCombo: comboNameAsObject ];
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
    [ self updateDuration: SMALL_MOVE_DURATION ];
}

-(IBAction) swap: (id)sender{
    [ self.ballRingView playSwapSound ];
    [ self.gameModel swap ];
    [ self updateDuration: LARGE_MOVE_DURATION ];
}

-(IBAction) right: (id)sender{
    [ self.ballRingView playRightSound ];
    [ self.gameModel right ];
    [ self updateDuration: SMALL_MOVE_DURATION ];
}

-(void) spinInProgress: (int) wedges{
    [ self.gameModel spin: wedges ];
//      [ self.spview updateHistoryText ];
}

- (void) spinFinished: (int)wedges{
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
    [ OKCancelAlertView OKCancelAlertWithTitle: @"Home!"
                                       message: @"This will reset " appName @" to the home position.\n" 
                                                @"Press OK if you want to do this."
                                        target: self
                                cancelSelector: NULL
                                    OKSelector: @selector( doHome ) ];
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
    self.rootViewController.nowHandlingShake = false;
    haveNotedSuccess = false;
}


-(void) noShake{
    self.rootViewController.nowHandlingShake = false;
}


-(void) doRestart{
    self.invert = false ;
    if ( [ self.gameModel isSolving ] )
    {
        [ self.gameModel revert ];
    }
    [ self updateDuration: LARGE_MOVE_DURATION ];
    self.rootViewController.nowHandlingShake = false;
}



-(void) confirmShake{
    [ OKCancelAlertView OKCancelAlertWithTitle: @"Shake!"
                                       message: @"This will create a new " appName @" puzzle.\n" 
                                                @"Press OK if you want to do this."
                                        target: self
                                cancelSelector: @selector( noShake )
                                    OKSelector: @selector( doShake ) ];
}

-(void) confirmRestart
{
    [ OKCancelAlertView OKCancelAlertWithTitle: @"Restart!" 
                                       message: @"This will restart solving this puzzle.\n" 
                                                @"Press OK if you want to do this."
                                        target: self
                                cancelSelector: NULL
                                    OKSelector: @selector( doRestart ) ];
}


-(IBAction) shake: (id)sender{
    [ self.ballRingView playShakeSound ]; 
    if ( self.confirm && [self.gameModel isSolving ] )
        [ self confirmShake ];
    else
        [ self doShake ];
}


-(IBAction) restart: (id)sender{
    [ self.ballRingView playRestartSound ];
    if ( self.confirm && [self.gameModel isSolving ] )
        [ self confirmRestart ];
    else
        [ self doRestart ];
}


@end
