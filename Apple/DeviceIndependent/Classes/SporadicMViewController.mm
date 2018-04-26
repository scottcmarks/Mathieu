//
//  SporadicMViewController.m
//  SporadicM
//
//  Created by Scott Marks on 10/14/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#include "view.h"
#import "SporadicMAppDelegate.h"
#import "AppleModalAlert.h"
#import "SporadicMViewController.h"
#import "SporadicMView.h"
#import "BallView.h"
#import "BallRingView.h"
#import "Constants.h"
#import "iPhoneUtilities.h"
#import "SwapPermutationsView.h"
#import "SwapPermutationsViewController.h"

@interface SporadicMViewController()
@property (nonatomic, strong, readonly) SporadicMView * sporadicMView;
@end

@implementation SporadicMViewController

- (SporadicMView *)sporadicMView {
    assert([self.view isKindOfClass:SporadicMView.class]);
    return (SporadicMView *)self.view;
}

- ( BallRingView * ) ballRingView { return self.sporadicMView.ballRingView; }

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }

- ( bool ) confirm { return self.appDelegate.confirm; }
- ( bool ) invert  { return self.appDelegate.invert; }
- ( void ) setInvert:(bool)inverted {
    self.appDelegate.invert = inverted ;
    [ self.sporadicMView setInvertibleButtonsInverted: inverted];
}

// Framework-generated messages
#if TARGET_IOS

// Implement viewDidLoad to do additional setup after loading the view.
- (void)initializeView {
    haveNotedSuccess = [ self.gameModel isSolving ] && [ self.gameModel isIdentity ];
    [self.sporadicMView initializeViews];
}

#if TARGET_IOS && OVERRIDE_DEPRECATED
- ( BOOL ) shouldAutorotateToInterfaceOrientation: ( UIInterfaceOrientation ) interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsPortrait(interfaceOrientation ) ;
}
#endif // TARGET_IOS && OVERRIDE_DEPRECATED

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#endif /* TARGET_IOS */



// Handlers for events from the SporadicMView


- (IBAction)toggleView
{
    abort(); // [ rootViewController toggleView ];
}

- (IBAction)toggleInverted {
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
    [ self.sporadicMView showCurrentPermutationAtDuration: duration ];

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


- (void)doSetCombo: ( HistoryElement ) comboName
{
    self.invert = false;
    if ( [ self.gameModel historyIsEmpty ] )
        [ self.gameModel eraseCombo: comboName ];
    else
        [ self.gameModel setCombo: comboName ];
    [ self.sporadicMView setComboButton:comboName enabled: [ self.gameModel hasDefinedCombo:comboName ] ];
}

-(void) confirmSetCombo: ( HistoryElement ) comboName
{
    if ( ! [ self.gameModel hasDefinedCombo:      comboName ]   // Don't confirm if no definition, or
        || [ self.gameModel historyIsSingleCombo: comboName ]  // if just setting to force expand
       )
    {
        [ self doSetCombo: comboName ];
        return ;
    }
    NSString * verb = self.gameModel.historyIsEmpty ? @"erase" : @"change" ;
    NSString * alertFormat = @"This will %@ the meaning of %c.\nPress OK if you want to do this." ;
    [ AppleModalAlert alertOKCancel:[ NSString stringWithFormat:alertFormat, verb, (char)comboName ]
                              title:@"Combo Set!"
                       continuation:^(bool confirmed) { if (confirmed) [self doSetCombo: comboName]; }];
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
        [ self confirmSetCombo:comboName ];
    else
        [ self doSetCombo:comboName ];
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

-(IBAction) left
{
    [ self.ballRingView playLeftSound ];
    [ self.gameModel left ];
    self.invert = false ;
    [ self updateDuration: SMALL_MOVE_DURATION ];
}

-( IBAction ) swap
{
    [ self.ballRingView playSwapSound ];
    [ self.gameModel swap ];
    self.invert = false ;
    [ self updateDuration: LARGE_MOVE_DURATION ];
}

-(IBAction) right
{
    [ self.ballRingView playRightSound ];
    [ self.gameModel right ];
    self.invert = false ;
    [ self updateDuration: SMALL_MOVE_DURATION ];
}

-(void) spinInProgress: (int) wedges{
    self.invert = false ;
    [ self.gameModel spin: wedges ];
//      [ self.sporadicMView updateHistoryText ];
}

- (void) spinFinished: (int)wedges{
    self.invert = false ;
    [ self.gameModel spin: wedges ];
    [ self updateDuration: INSTANTANEOUS ];
}

- (void) swapped { [ self swap ] ; }

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

-(IBAction) undoMove  { [ self undo: true  ] ; }

-(IBAction) undoStep  { [ self undo: false ] ; }

-(IBAction) undoStepOrMove { [self undo: self.invert];}


- ( void ) doHome
{
    self.invert = false ;
    [ self.gameModel reset ];
    [ self updateDuration: LARGE_MOVE_DURATION ];
}

-(void) confirmHome
{
    [ AppleModalAlert alertOKCancel:@"This will reset " applicationName @" to the home position.\n"
     @"Press OK if you want to do this." title:@"Home!" continuation:^(bool confirmed) {
         if (confirmed) [self doHome];
     }];
}

-(IBAction) home
{
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
    haveNotedSuccess = false;
}


-(void) doRestart
{
    self.invert = false ;
    if ( [ self.gameModel isSolving ] )
        [ self.gameModel revert ];
    [ self updateDuration: LARGE_MOVE_DURATION ];
}


-(void) noRestart { self.invert = false ; }



-(void) confirmShake
{
    [ AppleModalAlert alertOKCancel:@"This will create a new " applicationName @" puzzle.\n"
                                    @"Press OK if you want to do this."
                              title:@"Shake!"
                       continuation:^(bool confirmed) { if (confirmed) [self doShake]; }] ;
}

-(void) confirmRestart
{
    [ AppleModalAlert alertOKCancel:(NSString *)@"This will restart solving this puzzle.\n"
                                                @"Press OK if you want to do this."
                              title:@"Restart!"
                       continuation:^(bool confirmed) {
                           if (confirmed) [self doRestart] ; else [self noRestart ];
                       }];
}


-(IBAction) shake
{
    [ self.ballRingView playShakeSound ];
    if ( self.confirm && self.gameModel.isSolving )
        [ self confirmShake ];
    else
        [ self doShake ];
}


-(IBAction) restart
{
    [ self.ballRingView playRestartSound ];
    if ( self.confirm && self.gameModel.isSolving )
        [ self confirmRestart ];
    else
        [ self doRestart ];
}

-(IBAction) shakeOrRestart { if (self.invert) [self restart]; else [self shake]; }

-( void ) doChangeSwap:(int) newSwapIndex
{
    self.gameModel.swapIndex = newSwapIndex;
    [ self.gameModel reset ];
    [ self.gameModel eraseAllCombos ];
    [ self.sporadicMView disableAllComboButtons ];
    [ self.ballRingView redraw ];
    [ self.sporadicMView showCurrentPermutationAtDuration:INSTANTANEOUS ];
//    abort(); // [ self.rootViewController toggleView ];
}


-( void ) dontChangeSwap
{
    [ BallView setColorsForSwapPermutation: MathieuPermutation::swapPermutation ];
//    abort(); // [ self.rootViewController toggleView ];
}


-( void ) setSwapIndex: ( int ) newSwapIndex
{
    if ( newSwapIndex == self.gameModel.swapIndex )
        [ self dontChangeSwap ];
    else
        [ self doChangeSwap:newSwapIndex];
 }


- ( void     ) synchronize
{
    [ self.sporadicMView showCurrentPermutationAtDuration: INSTANTANEOUS ] ;
}


-(IBAction)prepareForUnwindToSporadicM:(UIStoryboardSegue *)segue {
    if ([segue.sourceViewController isKindOfClass: SwapPermutationsViewController.class]) {
        SwapPermutationsViewController * source = segue.sourceViewController;
        SwapPermutationsView * swapPermutationsView=(SwapPermutationsView *)(source.view);
        assert([swapPermutationsView isKindOfClass:SwapPermutationsView.class]);
        int newSwapIndex = swapPermutationsView.pickedSwapIndex ;
        [self setSwapIndex:newSwapIndex];
    }
}

@end
