//
//  SporadicMView.h
//  SporadicM
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BallRingView;
@class ComboButton;
@class SporadicMViewController;
@class DualActionButton;
@class GameModel;
@interface SporadicMView : UIView // TransitionView 
{

    SporadicMViewController * controller;
    UIToolbar * toolbar;
    UITextView *history;
    NSTimer * historyTextUpdatingTimer;
    BallRingView * ballRingView;    
    
    NSString * historyTextCache;
    
    DualActionButton * shakeButton;
    DualActionButton * altButton;
    DualActionButton * undoButton;
    bool buttonsInverted;
}


@property ( nonatomic, assign   ) IBOutlet UIToolbar * toolbar;
@property ( nonatomic, assign   ) IBOutlet UITextView *history;
@property ( nonatomic, assign   ) IBOutlet SporadicMViewController * controller;
@property ( nonatomic, assign   ) IBOutlet BallRingView * ballRingView;
@property ( nonatomic, retain   ) NSTimer * historyTextUpdatingTimer;
@property ( nonatomic, retain   ) NSString * historyTextCache;

-( void ) updateHistoryText;    

-( void ) showCurrentPermutationAtDuration: ( CGFloat ) duration;
-( void ) setInvertibleButtonsInverted:( bool )inverted;
-( void ) setComboButton:( HistoryElement )c enabled:( const bool )enabled;
-( void ) disableAllComboButtons;


@end
