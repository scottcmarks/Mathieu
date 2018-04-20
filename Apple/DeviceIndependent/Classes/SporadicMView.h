//
//  SporadicMView.h
//  SporadicM
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"

@class BallRingView;
@class ComboButton;
@class SporadicMViewController;
@class DualActionButton;
@class GameModel;
@interface SporadicMView : UIView // TransitionView
{

    SporadicMViewController * controller;
    AppleLabel * moves;
    NSTimer * historyTextUpdatingTimer;
    BallRingView * ballRingView;

    NSString * historyTextCache;

    DualActionButton * shakeButton;
    DualActionButton * altButton;
    DualActionButton * undoButton;
    bool buttonsInverted;
    AppleTextView * history;
    AppleToolbar  * toolbar;
}


@property ( nonatomic, assign   ) IBOutlet AppleToolbar  * toolbar;
@property ( nonatomic, assign   ) IBOutlet AppleTextView * history;
@property ( nonatomic, assign   ) IBOutlet AppleLabel              * moves;
@property ( nonatomic, assign   ) IBOutlet SporadicMViewController * controller;
@property ( nonatomic, assign   ) IBOutlet BallRingView            * ballRingView;
@property ( nonatomic, retain   )          NSTimer                 * historyTextUpdatingTimer;
@property ( nonatomic, retain   )          NSString                * historyTextCache;

-( void ) updateHistoryText;

-( void ) showCurrentPermutationAtDuration: ( CGFloat ) duration;
-( void ) setInvertibleButtonsInverted:( bool )inverted;
-( void ) setComboButton:( HistoryElement )c enabled:( const bool )enabled;
-( void ) disableAllComboButtons;


@end
