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
@interface SporadicMView : UIView // TransitionView
{

    SporadicMViewController * controller;
    Label * moves;
    NSTimer * historyTextUpdatingTimer;
    BallRingView * ballRingView;

    NSString * historyTextCache;

    DualActionButton * shakeButton;
    DualActionButton * altButton;
    DualActionButton * undoButton;
    bool buttonsInverted;
#if TARGET_OS_IPHONE
    UITextView * history;
    UIToolbar  * toolbar;
#elif TARGET_OS_MAC
    NSTextField * history;
    NSToolbar   * toolbar;
#else
#error Don't know this platform!
#endif
}


#if TARGET_OS_IPHONE
@property ( nonatomic, assign   ) IBOutlet UIToolbar  * toolbar;
@property ( nonatomic, assign   ) IBOutlet UITextView * history;
#elif TARGET_OS_MAC
@property ( nonatomic, assign   )          NSToolbar   * toolbar;
@property ( nonatomic, assign   )          NSTextField * history;
#else
#error Don't know this platform!
#endif
@property ( nonatomic, assign   ) IBOutlet Label                   * moves;
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
