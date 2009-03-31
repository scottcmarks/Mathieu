//
//  BallRingView.mm
//  Mathieu
//
//  Created by scott on 3/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#include "view.h"

#import "BallRingView.h"
#import "SporadicMAppDelegate.h"
#import "BallView.h"
#import "SoundEffect.h"


@implementation BallRingView

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }
- ( bool ) soundEffects { return self.appDelegate.soundEffects; }


+ ( id ) ballRingViewWithFrame: ( CGRect ) frame tags: ( BOOL ) tags delegate: ( id< BallRingViewDelegate > ) delegate
{
    return [ [ self alloc ] initWithFrame:frame tags:tags delegate: delegate ] ;
}

inline point CGPoint_to_point( CGPoint p ) { return point( p.x, p.y ); }
inline CGPoint CGPointMakeFromPoint( point p ) { return CGPointMake( p.x, p.y ) ; }

- ( id ) initWithFrame:         ( CGRect ) frame tags: ( BOOL ) tags delegate: ( id< BallRingViewDelegate > ) delegate
{
    if ( self = [ super initWithFrame: frame ] )
    {
        
        CGFloat frameHalfWidth = CGRectGetWidth ( frame )/2;
        _circleRadius = frameHalfWidth - 2*MBallRadius ;
        _circleCenter = CGPointMake( frameHalfWidth, frameHalfWidth + 1.5*MBallRadius + tagFontSize );
        
        point ballCoordinates[ nBalls ];
        point tagCoordinates [ nBalls ];
        CalculateBallCoordinates( CGPoint_to_point( _circleCenter ), _circleRadius, MBallRadius, ballCoordinates, tagCoordinates);   //fills array with coordinates for the center of the ball
        CGRect frame = CGRectMake ( 0.0, 0.0, MBallRadius*2, MBallRadius*2 );
        
        // Do all the geometry
        forAllBalls(i)
        {
            _ballCenters[ i ].x = round( ballCoordinates[ i ].x ) ;
            _ballCenters[ i ].y = round( ballCoordinates[ i ].y );
        }
        
        // Create and add all the balls
        forAllBalls(i)
        {
            BallView *ballView = [ BallView ballViewWithFrame: frame ballNumber: i ] ;      //TODO: if we're allocating all of these don't we need to release them? (keep track?)
            if (! ballView )
                return nil;
            ballView.center = _ballCenters[ i ];
            [self addSubview: ballView];
            _ballViews[ i ] = ballView;
        }
        
        UIFont * ballFont = [UIFont systemFontOfSize:ballFontSize ];
        
        // Create and add all the labels (in front of the balls)
        forAllBalls(i)
        {
            UILabel * ballLabel = [ [ UILabel alloc ] initWithFrame: frame ];
            if (! ballLabel )
                return nil;
            ballLabel.center = _ballCenters[ i ];
            ballLabel.font = ballFont;
            ballLabel.textAlignment = UITextAlignmentCenter;
            ballLabel.backgroundColor = [ UIColor clearColor ];
            ballLabel.text = [NSString stringWithFormat:@"%d", i ];
            [self addSubview:ballLabel ];
            _ballLabels[ i ] = ballLabel;                        //TODO retain count == 2?
        }
        
        if ( tags )
        {
            UIFont * tagFont = [UIFont systemFontOfSize:tagFontSize ];
            
            // Create and add all the little gray labels (next to the balls)
            forAllBalls(i)
            {
                UILabel * tagLabel = [ [ UILabel alloc ] initWithFrame: frame ];
                if (! tagLabel )
                    return nil;
                tagLabel.center = CGPointMakeFromPoint( tagCoordinates[ i ] );
                tagLabel.font = tagFont;
                tagLabel.textAlignment = UITextAlignmentCenter;
                tagLabel.backgroundColor = [ UIColor clearColor ];
                tagLabel.textColor = [ UIColor colorWithWhite:0.0 alpha:0.25 ];
                tagLabel.text = [NSString stringWithFormat:@"%d", i ];
                [self addSubview:tagLabel ];
            }
        }
        
        _delegate = delegate ;
        if ( delegate )  // only interactive if delegate provided
        {
            _rightSound    = [ SoundEffect soundEffectWithCaf: @"right"     ];
            _leftSound     = [ SoundEffect soundEffectWithCaf: @"left"      ];
            _swapSound     = [ SoundEffect soundEffectWithCaf: @"swap"      ];
            _homeSound     = [ SoundEffect soundEffectWithCaf: @"home"      ];
            _shakeSound    = [ SoundEffect soundEffectWithCaf: @"shake"     ];
            //TODO:  make real sound for restart amd combo 
            _restartSound  = [ SoundEffect soundEffectWithCaf: @"restart"   ];
            _comboSound    = [ SoundEffect soundEffectWithCaf: @"combo"     ];
            _comboSetSound = [ SoundEffect soundEffectWithCaf: @"combo_set" ];
            _successSound  = [ SoundEffect soundEffectWithCaf: @"success"   ];
            _applauseSound = [ SoundEffect soundEffectWithCaf: @"applause"  ];
            
            // Not currently spinning
            firstWedgeTouched = -1;
            
            // Not currently doing Swap gesture
            swapGestureStarted = false;
        }
        else
            self.userInteractionEnabled = NO;
    }
    return self;
}


- ( void ) moveLabels
{
forAllBalls(i)
    {
        _ballLabels[ [ self.gameModel at: i ] ].center = _ballCenters[ i ];
    }
}

- (bool) findWedgeAtTouch:(UITouch *)touch tolerant: ( bool ) tolerant
                  asWedge: ( Index & ) wedge
                 andTheta: ( double & ) theta{
    CGPoint touchPoint = [ touch locationInView: self ];
    CGFloat annulusSemiWidth = tolerant ? _circleRadius : TOUCH_SPOT_SIZE/2;
    return FindBallWedge( CGPoint_to_point( touchPoint ),
                          CGPoint_to_point( _circleCenter ), _circleRadius - annulusSemiWidth, _circleRadius + annulusSemiWidth,
                         wedge, theta ) ;
}

- (bool) touch:(UITouch *)touch onBall:( Index )nBall{
    CGRect ballZeroRect = CGRectMake( _ballCenters[ nBall ].x-TOUCH_SPOT_SIZE/2,
                                     _ballCenters[ nBall ].y-TOUCH_SPOT_SIZE/2,
                                     TOUCH_SPOT_SIZE, TOUCH_SPOT_SIZE );
    CGPoint touchPoint = [ touch locationInView: self ];
    return CGRectContainsPoint(ballZeroRect, touchPoint );
}


- (bool) ballZeroAtTouch:( UITouch *)touch {
    return [ self touch: touch onBall: 0 ] ;
}

- (bool) innerWedgeOneContainsTouch: ( UITouch *)touch {
    CGPoint touchPoint = [ touch locationInView: self ];
    Index wedge;
    double theta;
    return FindBallWedge(CGPoint_to_point( touchPoint ),
                         CGPoint_to_point( _circleCenter ), 0, _circleRadius + TOUCH_SPOT_SIZE/2,
                         wedge, theta )
    && wedge == 1 ;
}

int wedgeDifference( Index lastWedgeTouched, Index previousWedgeTouched )
{
    int nWedgesSpun = lastWedgeTouched - previousWedgeTouched;
    if ( nWedgesSpun < -(nBalls/2 - 1 ) )
        nWedgesSpun += (nBalls - 1);
    else if ( +(nBalls/2 - 1) < nWedgesSpun )
        nWedgesSpun -= (nBalls - 1);
    return nWedgesSpun;
}

- (int) spinClicks: (int) nWedgesSpun
{
    if ( 0 < nWedgesSpun )
        for ( int i = 0; i < +nWedgesSpun ; i ++ )
            [ self playRightSound ];
    else if ( nWedgesSpun < 0 )
        for ( int i = 0; i < -nWedgesSpun ; i ++ )
            [ self playLeftSound  ];
    return nWedgesSpun;
}

- (void)startedTouching: (UITouch *)touch
{
    Index wedgeAtTouch = 0 ;
    double thetaAtTouch = 0.0 ;
    if ( [ self touch:touch onBall: 0 ] )
    {
        swapGestureStarted = true;
        return ;
    }
    swapGestureStarted = false;
    if (! [ self findWedgeAtTouch:touch tolerant:NO
                          asWedge: wedgeAtTouch andTheta: thetaAtTouch ] )
        return ;
    
    if ( ! ( 1 <= wedgeAtTouch && wedgeAtTouch < nBalls ) )
        return;
    
    // Here we might consider whether ball 0 was touched, indicating a desire to swap.
    
    firstWedgeTouched = previousWedgeTouched = lastWedgeTouched = wedgeAtTouch;
    firstThetaTouched = thetaAtTouch;
    [ self.gameModel copyInto: spinStartingPosition ];
    //  if ( self.animateBallPops ) [ self animatePopBall:wedgeAtTouch first:YES ];
}


- (void)  finishedTouching 
{
    [ _delegate spinFinished: [ self spinClicks: wedgeDifference( lastWedgeTouched, previousWedgeTouched ) ] ];
    firstWedgeTouched = -1 ;
}

- (bool) recordTouch:(UITouch *)touch
{
    Index wedgeAtTouch;
    double thetaAtTouch;
    if ( ! [ self findWedgeAtTouch:touch tolerant:YES
                           asWedge: wedgeAtTouch andTheta: thetaAtTouch ] )
    {
        [ self finishedTouching ] ;
        return false;
    }
    lastWedgeTouched = wedgeAtTouch;
    lastThetaTouched = thetaAtTouch ;
    for (Index i = 1; i < nBalls ; i++ )
    {
        UILabel * ballLabel = _ballLabels[ spinStartingPosition[ i ] ];
        /*
         ballLabel is currently who-knows-where.
         But where we want it to be is (lastThetaTouched-firstThetaTouched) from where it started.
         It started at _ballCenters[ i ].
         
         */
        point old_center = CGPoint_to_point( _ballCenters[ i ] );
        point center = CGPoint_to_point( _circleCenter );
        point spun = point( polar( old_center - center ).rotate( lastThetaTouched - firstThetaTouched ) ) + center;
        ballLabel.center = CGPointMakeFromPoint( spun );
    }
    
    [ _delegate spinInProgress: [ self spinClicks: wedgeDifference( lastWedgeTouched , previousWedgeTouched ) ] ];
    previousWedgeTouched = lastWedgeTouched ;
    return true;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self startedTouching: [ touches anyObject ] ];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *) event {
    if ( swapGestureStarted )
        return ;
    UITouch * touch = [ touches anyObject ];
    if ( firstWedgeTouched == - 1 )
    {
        [ self startedTouching: touch ];
        return;
    }
    [ self recordTouch: touch ];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *) event {
    UITouch * touch = [ touches anyObject ];
    if ( swapGestureStarted )
    {
        if ( [ self innerWedgeOneContainsTouch:touch ] )
            [ _delegate swapped ];
        swapGestureStarted = false;
        return;
    }
    if ( firstWedgeTouched == -1 ) return;
    if ( [ self recordTouch: touch ] )
        [ self finishedTouching ];
}

-( void ) playRightSound    { if ( self.soundEffects ) [ _rightSound    play ]; }
-( void ) playLeftSound     { if ( self.soundEffects ) [ _leftSound     play ]; }
-( void ) playSwapSound     { if ( self.soundEffects ) [ _swapSound     play ]; }
-( void ) playHomeSound     { if ( self.soundEffects ) [ _homeSound     play ]; }
-( void ) playShakeSound    { if ( self.soundEffects ) [ _shakeSound    play ]; }
-( void ) playRestartSound  { if ( self.soundEffects ) [ _restartSound  play ]; }
-( void ) playComboSound    { if ( self.soundEffects ) [ _comboSound    play ]; }
-( void ) playComboSetSound { if ( self.soundEffects ) [ _comboSetSound play ]; }


-( void ) playSuccessSound  
{ 
    if ( self.soundEffects ) 
    {
        if ( self.gameModel.historyLength <= APPLAUSE_THRESHOLD )
            [ _applauseSound play ];
        else
            [ _successSound  play ]; 
    }
}    
/***
- (void) animatePopBall:(Index)nBall first:(bool) first {
    // Create animation for the grow, which uses a delegate method to
    // start an animation for the shrink operation.
    [UIView beginAnimations:nil context:(void *)( first ? +nBall : -nBall )];
    [UIView setAnimationDuration: GROW_ANIMATION_DURATION_SECONDS];
    [UIView setAnimationDelegate: self ];
    [UIView setAnimationDidStopSelector:@selector(growAnimationDidStop:finished:context:) ];
    CGFloat ballBloom  = first ? FIRST_BALL_BLOOM_FACTOR  : SUBSEQUENT_BALL_BLOOM_FACTOR ;
    CGFloat labelBloom = first ? FIRST_LABEL_BLOOM_FACTOR : SUBSEQUENT_LABEL_BLOOM_FACTOR;
    _ballViews [nBall].transform = CGAffineTransformMakeScale(ballBloom , ballBloom );
    _ballLabels[nBall].transform = CGAffineTransformMakeScale(labelBloom, labelBloom);
    [UIView commitAnimations];
}

- (void)growAnimationDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
    int nBall = (int)context;
    bool first = 0 < nBall;
    if ( ! first ) nBall = - nBall ;
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationDuration: SHRINK_ANIMATION_DURATION_SECONDS
                                  * ( first
                                      ? FIRST_ANIMATION_DURATION_FACTOR
                                     : SUBSEQUENT_ANIMATION_DURATION_FACTOR ) ];
    _ballViews [ nBall ].transform = CGAffineTransformIdentity;
    _ballLabels[ nBall ].transform = CGAffineTransformIdentity;
    [UIView commitAnimations];
}
***/


- (void)dealloc 
{
    forAllBalls( i )
    {
        [ _ballLabels[ i ] release ];
        _ballLabels[ i ] = nil;
        [ _ballViews[ i ] release ];
        _ballViews[ i ] = nil;
    }
    [ _rightSound    release ] ;
    [ _leftSound     release ] ;
    [ _swapSound     release ] ;
    [ _homeSound     release ] ;
    [ _shakeSound    release ] ;
    [ _restartSound  release ] ;
    [ _comboSound    release ] ;
    [ _comboSetSound release ] ;
    [ _successSound  release ] ;
    [ _applauseSound release ] ;
    [ super dealloc ];
}


@end
