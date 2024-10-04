//
//  SporadicMView.h
//  SporadicM
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"
#import "BallView.h"
#import "BallRingView.h"

#import "UIDualButton.h"

@interface AppleLabelClearsBeforeWriting : AppleLabel
@end

@class SporadicMViewController;
@interface SporadicMView : UIView // TransitionView



@property ( nonatomic, assign   ) IBOutlet AppleLabelClearsBeforeWriting              * moves;
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
