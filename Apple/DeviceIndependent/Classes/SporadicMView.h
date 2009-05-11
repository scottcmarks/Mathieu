//
//  SporadicMView.h
//  SporadicM
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"

@class BallRingView;
@class ComboButton;
@class SporadicMViewController;
@class DualActionButton;
@class GameModel;
@interface SporadicMView : View // TransitionView 
{

    SporadicMViewController * controller;
    Toolbar * toolbar;
    Label * moves;
    TextView *history;
    NSTimer * historyTextUpdatingTimer;
    BallRingView * ballRingView;    
    
    NSString * historyTextCache;
    
    DualActionButton * shakeButton;
    DualActionButton * altButton;
    DualActionButton * undoButton;
    bool buttonsInverted;
}


@property ( nonatomic, assign   ) IBOutlet Toolbar * toolbar;
@property ( nonatomic, assign   ) IBOutlet Label * moves;
@property ( nonatomic, assign   ) IBOutlet TextView *history;
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
