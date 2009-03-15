//
//  SporadicMView.h
//  SporadicM
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameModel.h"

@class BallView;
@class SoundEffect;
@class ComboButton;
@class SporadicMViewController;
@class DualActionButton;

@interface SporadicMView : UIView // TransitionView 
{

    SporadicMViewController * controller;
    UIToolbar * toolbar;
    UITextView *history;
    
    BallView *ballViews[ nBalls ];
    UILabel *ballLabels[ nBalls ];
    CGPoint ballCenters[ nBalls ];
    SoundEffect *tickSound;
    SoundEffect *tockSound;
    SoundEffect *swapSound;
    SoundEffect *homeSound;
    SoundEffect *shakeSound;
    SoundEffect *restartSound;
    SoundEffect *comboSound;
    SoundEffect *comboSetSound;
    SoundEffect *successSound;
    SoundEffect *applauseSound;
    
    bool animateBallPops;
    int firstWedgeTouched;
    bool swapGestureStarted ;
    int previousWedgeTouched;
    int lastWedgeTouched;
    double firstThetaTouched;
    double lastThetaTouched;
    PermArray spinStartingPosition;
    NSString * historyTextCache;
    
    DualActionButton * shakeButton;
    DualActionButton * altButton;
    DualActionButton * undoButton;
    bool buttonsInverted;
}


@property ( nonatomic, assign   ) IBOutlet UIToolbar * toolbar;
@property ( nonatomic, assign   ) IBOutlet UITextView *history;
@property ( nonatomic, assign   ) IBOutlet SporadicMViewController * controller;

@property ( nonatomic, retain   ) SoundEffect *tickSound;
@property ( nonatomic, retain   ) SoundEffect *tockSound;
@property ( nonatomic, retain   ) SoundEffect *swapSound;
@property ( nonatomic, retain   ) SoundEffect *homeSound;
@property ( nonatomic, retain   ) SoundEffect *shakeSound;
@property ( nonatomic, retain   ) SoundEffect *restartSound;
@property ( nonatomic, retain   ) SoundEffect *comboSound;
@property ( nonatomic, retain   ) SoundEffect *comboSetSound;
@property ( nonatomic, retain   ) SoundEffect *successSound;
@property ( nonatomic, retain   ) SoundEffect *applauseSound;
@property ( nonatomic           ) bool animateBallPops;

@property ( nonatomic, retain   ) NSString * historyTextCache;

-( void ) updateHistoryText;    

-( bool ) findWedgeAtTouch:( UITouch * )touch tolerant: ( bool ) tolerant 
                                               asWedge: ( Index & ) wedge
                                              andTheta: ( double & ) theta;
-( void ) animatePopBall:( Index )nBall first:( bool ) first;
-( void ) showCurrentPermutationAtDuration: ( CGFloat ) duration;
-( void ) setInvertibleButtonsInverted:( bool )inverted;
-( void ) setComboButton:( HistoryElement )c enabled:( const bool )enabled;

-( void ) playRightSound    ;
-( void ) playLeftSound     ;
-( void ) playSwapSound     ;
-( void ) playHomeSound     ;
-( void ) playShakeSound    ;
-( void ) playRestartSound  ;
-( void ) playComboSound    ;
-( void ) playComboSetSound ;
-( void ) playSuccessSound  ;

@end
