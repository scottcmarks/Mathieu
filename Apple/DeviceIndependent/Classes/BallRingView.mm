//
//  BallRingView.mm
//  Mathieu
//
//  Created by Scott Marks on 3/31/09.
//  Copyright © 2009, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#include "view.h"


#import "iPhoneUtilities.h"

#import "SporadicMAppDelegate.h"
#import "BallView.h"
#import "SoundEffect.h"

#import "BallRingView.h"

@interface BallRingView()
@property (nonatomic,assign) CGFloat   circleRadius;
@property (nonatomic,assign) CGPoint   circleCenter;
@property (nonatomic,assign) CGFloat   ballRadius;
@property (nonatomic,retain) NSMutableArray <BallView *> * ballViews /* [ nBalls ] */ ;
@property (nonatomic,retain) NSMutableArray <AppleLabel *> * ballLabels /* [ nBalls ] */ ;
@property (nonatomic,retain) NSMutableArray <AppleLabel *> * tagLabels /* [ nBalls ] */ ;
@property (nonatomic,retain) NSMutableArray <NSValue /*CGPoint*/ *> * nsv_ballCenters /* [ nBalls ] */ ;
@property (nonatomic,retain) SoundEffect * rightSound;
@property (nonatomic,retain) SoundEffect * leftSound;
@property (nonatomic,retain) SoundEffect * swapSound;
@property (nonatomic,retain) SoundEffect * homeSound;
@property (nonatomic,retain) SoundEffect * shakeSound;
@property (nonatomic,retain) SoundEffect * restartSound;
@property (nonatomic,retain) SoundEffect * comboSound;
@property (nonatomic,retain) SoundEffect * comboSetSound;
@property (nonatomic,retain) SoundEffect * comboNotSetSound;
@property (nonatomic,retain) SoundEffect * successSound;
@property (nonatomic,retain) SoundEffect * applauseSound;
@property (nonatomic,assign) int firstWedgeTouched;
@property (nonatomic,assign) bool swapGestureStarted;
@property (nonatomic,assign) int previousWedgeTouched;
@property (nonatomic,assign) int lastWedgeTouched;
@property (nonatomic,assign) double firstThetaTouched;
@property (nonatomic,assign) double lastThetaTouched;
@property (nonatomic,assign) void * /* PermArray */ v_spinStartingPosition;
@property (nonatomic,weak  ) id < BallRingViewDelegate > delegate;

// @property (nonatomic,assign) bool animateBallPops;


@end

@implementation BallRingView

@synthesize circleRadius;
@synthesize circleCenter;
@synthesize ballRadius;
@synthesize ballViews;
@synthesize ballLabels;
@synthesize tagLabels;
@synthesize nsv_ballCenters;
@synthesize rightSound;
@synthesize leftSound;
@synthesize swapSound;
@synthesize homeSound;
@synthesize shakeSound;
@synthesize restartSound;
@synthesize comboSound;
@synthesize comboSetSound;
@synthesize comboNotSetSound;
@synthesize successSound;
@synthesize applauseSound;
@synthesize firstWedgeTouched;
@synthesize swapGestureStarted;
@synthesize previousWedgeTouched;
@synthesize lastWedgeTouched;
@synthesize firstThetaTouched;
@synthesize lastThetaTouched;
@synthesize v_spinStartingPosition;
@synthesize delegate;

// @synthesize animateBallPops;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ AppleApplication sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }
- ( bool ) soundEffects { return self.appDelegate.soundEffects; }


+ ( instancetype ) ballRingViewWithFrame: ( CGRect ) frame
{
    return [ [ [ self alloc ] initWithFrame:frame ] autorelease ];
}

inline point CGPoint_to_point( CGPoint p ) { return point( p.x, p.y ); }
inline CGPoint CGPointMakeFromPoint( point p ) { return CGPointMake( p.x, p.y ) ; }

#define NOMINALBALLRADIUS 20

- (void ) createBallsAndLabels {
    CGRect ballFrame = CGRectMake ( 0.0, 0.0, NOMINALBALLRADIUS*2, NOMINALBALLRADIUS*2 );
    // Create and add all the balls
    self.ballViews = [NSMutableArray<BallView *> arrayWithCapacity:nBalls];
    forAllBalls(i)
    {
        BallView *ballView = [ BallView ballViewWithFrame: ballFrame ballNumber: i ] ;      //TODO: if we're allocating all of these don't we need to release them? (keep track?)
        assert(ballView);
        [ self addSubview: ballView ];
        self.ballViews[ (NSUInteger)i ] = ballView;
    }

#if !ICONIC_PICTURE_ONLY

    // Create and add all the labels (in front of the balls)
    self.ballLabels = [NSMutableArray<AppleLabel *> arrayWithCapacity:nBalls];
    forAllBalls(i)
    {
        AppleLabel * ballLabel = [ [ AppleLabel alloc ] initWithFrame: ballFrame ];
        assert(ballLabel );
        [self addSubview:ballLabel ];
        self.ballLabels[ (NSUInteger)i ] = ballLabel;                        //TODO retain count == 2?
    }
#endif // !ICONIC_PICTURE_ONLY



}

- (void ) layoutBallsAndLabelsForFrame: ( CGRect ) frame {
    CGFloat frameHalfWidth = CGRectGetWidth ( frame )/2;
    CGRect ballFrame = CGRectMake ( 0.0, 0.0, self.ballRadius*2, self.ballRadius*2 );
    self.circleRadius = frameHalfWidth - 2*self.ballRadius ;
    self.circleCenter = CGPointMake( CGRectGetMidX( frame ), CGRectGetMidY( frame )+ 0.5*self.ballRadius + tagFontSize );

    point ballCoordinates[ nBalls ];
    CalculateBallCoordinates( CGPoint_to_point( self.circleCenter ), self.circleRadius, self.ballRadius, ballCoordinates);   //fills array with coordinates for the center of the ball

    // Do all the geometry
    self.nsv_ballCenters = [NSMutableArray<NSValue /*CGPoint*/ *> arrayWithCapacity:nBalls];
    forAllBalls(i)
    {
        self.nsv_ballCenters[ (NSUInteger)i ] =
            [NSValue valueWithCGPoint:CGPointMake(round( ballCoordinates[ i ].x ),
                                                  round( ballCoordinates[ i ].y ))];
    }

    // Position all the balls
    forAllBalls(i)
    {
        BallView *ballView = self.ballViews[ (NSUInteger)i ];
        assert(ballView);
        ballView.frame = ballFrame;
        ballView.center = self.nsv_ballCenters[ (NSUInteger)i ].CGPointValue;
    }

#if ICONIC_PICTURE_ONLY

#if TARGET_IOS
    self.opaque = YES;
    self.userInteractionEnabled = NO;
#elif TARGET_MACOS
#else
#error Don't know this platform!
#endif

#else // !ICONIC_PICTURE_ONLY

    AppleFont * ballFont = [AppleFont systemFontOfSize:ballFontSize ];
    // Position the ball labels
    forAllBalls(i)
    {
        AppleLabel * ballLabel = self.ballLabels[ (NSUInteger)i ];
        assert(ballLabel );
        ballLabel.frame = ballFrame;
        ballLabel.center = self.nsv_ballCenters[ (NSUInteger)i ].CGPointValue;
        ballLabel.font = ballFont;
        ballLabel.textAlignment = NSTextAlignmentCenter;
        ballLabel.textColor = [ UIColor colorWithWhite:0.250 alpha:1.0 ];
        ballLabel.backgroundColor = [ UIColor clearColor ];
        ballLabel.text = [NSString stringWithFormat:@"%d", i ];
    }
#endif // !ICONIC_PICTURE_ONLY
}


- ( void ) createTags {
    // Create and add all the little gray labels (next to the balls)
    CGRect tagLabelFrame = CGRectMake(0, 0, NOMINALBALLRADIUS, NOMINALBALLRADIUS);
    self.tagLabels = [NSMutableArray<AppleLabel *> arrayWithCapacity:nBalls];
    forAllBalls(i)
    {
        AppleLabel * tagLabel = [ [ AppleLabel alloc ] initWithFrame: tagLabelFrame ];
        assert (tagLabel );
        self.tagLabels[(NSUInteger)i] = tagLabel;
        [self addSubview:tagLabel ];
    }
}

- ( void ) layoutTagsForFrame:(CGRect)frame {
    point tagCoordinates [ nBalls ];
    CalculateTagCoordinates( CGPoint_to_point( self.circleCenter ), self.circleRadius, self.ballRadius, tagCoordinates);   //fills array with coordinates for the center of the ball
    CGRect tagLabelFrame = CGRectMake(0, 0, self.ballRadius, self.ballRadius);
    AppleFont * tagFont = [AppleFont systemFontOfSize:tagFontSize ];
    forAllBalls(i)
    {
        AppleLabel * tagLabel = self.tagLabels[(NSUInteger)i];
        assert (tagLabel );
        tagLabel.frame = tagLabelFrame;
        tagLabel.center = CGPointMakeFromPoint( tagCoordinates[ i ] );
        tagLabel.font = tagFont;
        tagLabel.textAlignment = NSTextAlignmentCenter;
        tagLabel.backgroundColor = [ UIColor clearColor ];
        tagLabel.textColor = [ UIColor colorWithWhite:1.0 alpha:0.33 ];
        tagLabel.text = [NSString stringWithFormat:@"%d", i ];
    }
}

- (void) setupSounds {
    self.rightSound       = [[ SoundEffect newSoundEffectWithCaf: @"right"         ] autorelease];
    self.leftSound        = [[ SoundEffect newSoundEffectWithCaf: @"left"          ] autorelease];
    self.swapSound        = [[ SoundEffect newSoundEffectWithCaf: @"swap"          ] autorelease];
    self.homeSound        = [[ SoundEffect newSoundEffectWithCaf: @"home"          ] autorelease];
    self.shakeSound       = [[ SoundEffect newSoundEffectWithCaf: @"shake"         ] autorelease];
    //TODO:  make real sound for restart amd combo
    self.restartSound     = [[ SoundEffect newSoundEffectWithCaf: @"restart"       ] autorelease];
    self.comboSound       = [[ SoundEffect newSoundEffectWithCaf: @"combo"         ] autorelease];
    self.comboSetSound    = [[ SoundEffect newSoundEffectWithCaf: @"combo_set"     ] autorelease];
    self.comboNotSetSound = [[ SoundEffect newSoundEffectWithCaf: @"combo_not_set" ] autorelease];
    self.successSound     = [[ SoundEffect newSoundEffectWithCaf: @"success"       ] autorelease];
    self.applauseSound    = [[ SoundEffect newSoundEffectWithCaf: @"applause"      ] autorelease];
}

- (void) initializeInteraction {

    // Not currently spinning
    self.firstWedgeTouched = -1;

    // Not currently doing Swap gesture
    self.swapGestureStarted = false;
}

-(void) createSubviews {
    [self createBallsAndLabels ];

    if (self.delegate) {
        [self createTags];
        [self setupSounds];
        [self initializeInteraction];
    }
}

#pragma mark -  UIView method overrides

- ( id ) initWithFrame:         ( CGRect ) frame
{
#define INITWITHFRAME_TAGS_DELEGATE_DEBUG_LEVEL 1

#if INITWITHFRAME_TAGS_DELEGATE_DEBUG_LEVEL <= DEBUG_LEVEL
    __timestamp__ ;
#endif
    self = [ super initWithFrame: CGRect_to_NSRect( frame ) ];
    [self createSubviews];
    return self;
}

- ( void ) layoutSubviews {
    self.v_spinStartingPosition=new PermArray;
    CGFloat frameHalfWidth = CGRectGetWidth ( self.frame )/2;
    self.ballRadius = round( MBallRadiusRatio * frameHalfWidth );

#if INITWITHFRAME_TAGS_DELEGATE_DEBUG_LEVEL <= DEBUG_LEVEL
    NSLog( @"frameHalfWidth=%f self.ballRadius=%f ratio self.ballRadius/frameHalfWidth=%12f",
          (float)frameHalfWidth, (float)self.ballRadius, (float)((float)self.ballRadius/(float)frameHalfWidth ));
#endif

    [self layoutBallsAndLabelsForFrame: self.frame];
    if (self.delegate) {
        [self layoutTagsForFrame:self.frame];
    }
}

- ( void ) redraw
{
    forAllBalls( i ) [ self.ballViews[ (NSUInteger)i ] setNeedsDisplay ];
}


- ( void ) moveLabels
{
forAllBalls(i)
    {
        self.ballLabels[ (NSUInteger)[ self.gameModel at: i ] ].center = self.nsv_ballCenters[ (NSUInteger)i ].CGPointValue;
    }
}

#if TARGET_IOS

- (bool) findWedgeAtTouch:(UITouch *)touch tolerant: ( bool ) tolerant
                  asWedge: ( Index & ) wedge
                 andTheta: ( double & ) theta{
    CGPoint touchPoint = [ touch locationInView: self ];
    CGFloat annulusSemiWidth = tolerant ? self.circleRadius : TOUCH_SPOT_SIZE/2;
    return FindBallWedge( CGPoint_to_point( touchPoint ),
                          CGPoint_to_point( self.circleCenter ), self.circleRadius - annulusSemiWidth, self.circleRadius + annulusSemiWidth,
                         wedge, theta ) ;
}

- (bool) touch:(UITouch *)touch onBall:( Index )nBall{
    CGPoint ballCenter = self.nsv_ballCenters[ (NSUInteger) nBall ].CGPointValue;
    CGRect ballTouchRect = CGRectMake( ballCenter.x-TOUCH_SPOT_SIZE/2,
                                       ballCenter.y-TOUCH_SPOT_SIZE/2,
                                       TOUCH_SPOT_SIZE, TOUCH_SPOT_SIZE );
    CGPoint touchPoint = [ touch locationInView: self ];
    return CGRectContainsPoint(ballTouchRect, touchPoint );
}


- (bool) ballZeroAtTouch:( UITouch *)touch {
    return [ self touch: touch onBall: 0 ] ;
}

- (bool) innerWedgeOneContainsTouch: ( UITouch *)touch {
    CGPoint touchPoint = [ touch locationInView: self ];
    Index wedge;
    double theta;
    return FindBallWedge(CGPoint_to_point( touchPoint ),
                         CGPoint_to_point( self.circleCenter ), 0, self.circleRadius + TOUCH_SPOT_SIZE/2,
                         wedge, theta )
    && wedge == 1 ;
}


- (int) spinClicks
{
    int nWedgesSpun = self.lastWedgeTouched - self.previousWedgeTouched;
    if ( nWedgesSpun < -(nBalls/2 - 1 ) )
        nWedgesSpun += (nBalls - 1);
    else if ( +(nBalls/2 - 1) < nWedgesSpun )
        nWedgesSpun -= (nBalls - 1);

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
    if ( [ self touch:touch onBall: 0 ] )
    {
        self.swapGestureStarted = true;
        return ;
    }

    self.swapGestureStarted = false;
    Index wedgeAtTouch = 0 ;
    double thetaAtTouch = 0.0 ;
    if (! [ self findWedgeAtTouch:touch tolerant:NO
                          asWedge: wedgeAtTouch andTheta: thetaAtTouch ] )
        return ;
    if ( ! ( 1 <= wedgeAtTouch && wedgeAtTouch < nBalls ) )
        return;

    // Here we might consider whether ball 0 was touched, indicating a desire to swap.

    self.firstWedgeTouched = self.previousWedgeTouched = self.lastWedgeTouched = wedgeAtTouch;
    self.firstThetaTouched = thetaAtTouch;
    [ self.gameModel copyInto: *reinterpret_cast<PermArray *>(self.v_spinStartingPosition) ];
    //  if ( self.animateBallPops ) [ self animatePopBall:wedgeAtTouch first:YES ];
}


- (void)  finishedTouching
{
    assert( self.delegate );
    [ self.delegate spinFinished: self.spinClicks ];
    self.firstWedgeTouched = -1 ;
}

- (bool) recordTouch:(UITouch *)touch
{
    assert( self.delegate );

    Index wedgeAtTouch;
    double thetaAtTouch;
    if ( ! [ self findWedgeAtTouch:touch tolerant:YES
                           asWedge: wedgeAtTouch andTheta: thetaAtTouch ] )
    {
        [ self finishedTouching ] ;
        return false;
    }
    self.lastWedgeTouched = wedgeAtTouch;
    self.lastThetaTouched = thetaAtTouch ;
    for (Index i = 1; i < nBalls ; i++ )
    {
        AppleLabel * ballLabel = self.ballLabels[ (NSUInteger)(*reinterpret_cast<PermArray *>(self.v_spinStartingPosition))[i] ];
        /*
         ballLabel is currently who-knows-where.
         But where we want it to be is (lastThetaTouched-firstThetaTouched) from where it started.
         It started at _ballCenters[ i ].

         */
        point old_center = CGPoint_to_point( self.nsv_ballCenters[ (NSUInteger)i ].CGPointValue );
        point center = CGPoint_to_point( self.circleCenter );
        point spun = point( polar( old_center - center ).rotate( self.lastThetaTouched - self.firstThetaTouched ) ) + center;
        ballLabel.center = CGPointMakeFromPoint( spun );
    }

    [ self.delegate spinInProgress: self.spinClicks ];
    self.previousWedgeTouched = self.lastWedgeTouched ;
    return true;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self startedTouching: [ touches anyObject ] ];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *) event {
    if ( self.swapGestureStarted )
        return ;

    UITouch * touch = [ touches anyObject ];
    if ( self.firstWedgeTouched == - 1 )
    {
        [ self startedTouching: touch ];
        return;
    }
    [ self recordTouch: touch ];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *) event {
    UITouch * touch = [ touches anyObject ];
    if ( self.swapGestureStarted )
    {
        if ( [ self innerWedgeOneContainsTouch:touch ] )
            [ self.delegate swapped ];
        self.swapGestureStarted = false;
        return;
    }
    if ( self.firstWedgeTouched == -1 )
        return;
    if ( [ self recordTouch: touch ] )
        [ self finishedTouching ];
}

-( void ) playRightSound       { if ( self.soundEffects ) [ self.rightSound       play ]; }
-( void ) playLeftSound        { if ( self.soundEffects ) [ self.leftSound        play ]; }
-( void ) playSwapSound        { if ( self.soundEffects ) [ self.swapSound        play ]; }
-( void ) playHomeSound        { if ( self.soundEffects ) [ self.homeSound        play ]; }
-( void ) playShakeSound       { if ( self.soundEffects ) [ self.shakeSound       play ]; }
-( void ) playRestartSound     { if ( self.soundEffects ) [ self.restartSound     play ]; }
-( void ) playComboSound       { if ( self.soundEffects ) [ self.comboSound       play ]; }
-( void ) playComboSetSound    { if ( self.soundEffects ) [ self.comboSetSound    play ]; }
-( void ) playComboNotSetSound { if ( self.soundEffects ) [ self.comboNotSetSound play ]; }


-( void ) playSuccessSound
{
    if ( self.soundEffects )
    {
        if ( self.gameModel.historyLength <= APPLAUSE_THRESHOLD )
            [ self.applauseSound play ];
        else
            [ self.successSound  play ];
    }
}

#elif TARGET_MACOS
#else
#error Don't know this platform!
#endif


- (void)dealloc
{
    void * v = self.v_spinStartingPosition;
    if (v != NULL) {
        delete[] (PermArray *)v;
        self.v_spinStartingPosition = NULL;
    }
    self.ballViews        = nil ;
    self.ballLabels       = nil ;
    self.tagLabels        = nil ;
    self.nsv_ballCenters  = nil ;
    self.rightSound       = nil ;
    self.leftSound        = nil ;
    self.swapSound        = nil ;
    self.homeSound        = nil ;
    self.shakeSound       = nil ;
    self.restartSound     = nil ;
    self.comboSound       = nil ;
    self.comboSetSound    = nil ;
    self.comboNotSetSound = nil ;
    self.successSound     = nil ;
    self.applauseSound    = nil ;
    [ super dealloc ];
}


@end
