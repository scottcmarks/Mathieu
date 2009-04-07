//
//  BallRingView.h
//  Mathieu
//
//  Created by scott on 3/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameModel.h"
#import "BallRingViewDelegate.h"

@class SoundEffect;
@class BallView;

@interface BallRingView : UIView 
{
    CGFloat   _circleRadius;
    CGPoint   _circleCenter;
    CGFloat   _ballRadius;
    BallView * _ballViews[ nBalls ];
    UILabel *_ballLabels[ nBalls ];
    CGPoint _ballCenters[ nBalls ];
    SoundEffect * _rightSound;
    SoundEffect * _leftSound;
    SoundEffect * _swapSound;
    SoundEffect * _homeSound;
    SoundEffect * _shakeSound;
    SoundEffect * _restartSound;
    SoundEffect * _comboSound;
    SoundEffect * _comboSetSound;
    SoundEffect * _comboNotSetSound;
    SoundEffect * _successSound;
    SoundEffect * _applauseSound;
    int firstWedgeTouched;
    bool swapGestureStarted ;
    int previousWedgeTouched;
    int lastWedgeTouched;
    double firstThetaTouched;
    double lastThetaTouched;
    PermArray spinStartingPosition;    
    id < BallRingViewDelegate > _delegate;
    //  bool animateBallPops;
}

+ ( id ) ballRingViewWithFrame: ( CGRect ) frame tags: ( BOOL ) tags delegate: ( id < BallRingViewDelegate > ) delegate ;
- ( id ) initWithFrame:         ( CGRect ) frame tags: ( BOOL ) tags delegate: ( id < BallRingViewDelegate > ) delegate ;

- ( void ) moveLabels;
- ( void ) redraw;
- ( void ) playRightSound       ;
- ( void ) playLeftSound        ;
- ( void ) playSwapSound        ;
- ( void ) playHomeSound        ;
- ( void ) playShakeSound       ;
- ( void ) playRestartSound     ;
- ( void ) playComboSound       ;
- ( void ) playComboSetSound    ;
- ( void ) playComboNotSetSound ;
- ( void ) playSuccessSound     ;

@end
