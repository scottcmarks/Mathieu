//
//  SporadicMView.h
//  SporadicM
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"
#import "BallView.h"
#import "BallRingView.h"

#import "UIDualButton.h"

@class SporadicMViewController;
@interface SporadicMView : UIView // TransitionView
{

    SporadicMViewController * controller;
    AppleLabel * moves;
    AppleTextView * history;
    AppleToolbar  * toolbar;
    NSTimer * historyTextUpdatingTimer;
    BallRingView * ballRingView;

    NSString * historyTextCache;

    UIDualButton * shakeButton;
    UIDualButton * altButton;
    UIDualButton * undoButton;
    bool buttonsInverted;
}


@property ( nonatomic, assign   ) IBOutlet AppleLabel              * moves;
@property ( nonatomic, assign   ) IBOutlet AppleTextView * history;
@property ( nonatomic, assign   ) IBOutlet AppleToolbar  * toolbar;
@property ( nonatomic, assign   ) IBOutlet UIDualButton  * shakeButton;
@property ( nonatomic, assign   ) IBOutlet UIDualButton  * altButton;
@property ( nonatomic, assign   ) IBOutlet UIDualButton  * undoButton;
@property ( nonatomic, assign   ) IBOutlet SporadicMViewController * controller;
@property ( nonatomic, assign   ) IBOutlet BallRingView            * ballRingView;
@property ( nonatomic, retain   )          NSTimer                 * historyTextUpdatingTimer;
@property ( nonatomic, retain   )          NSString                * historyTextCache;

- (void) initializeViews;
-( void ) updateHistoryText;

-( void ) showCurrentPermutationAtDuration: ( CGFloat ) duration;
-( void ) setInvertibleButtonsInverted:( bool )inverted;
-( void ) setComboButton:( HistoryElement )c enabled:( const bool )enabled;
-( void ) disableAllComboButtons;


@end
