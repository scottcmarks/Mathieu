//
//  SporadicM12View.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import "view.h"
#import "Constants.h"
#import "Utilities.h"
#import "SporadicM12View.h"
#import "SporadicM12ViewController.h"
#import "SporadicM12AppDelegate.h"

const point circleCenter( 160.0, 196.0 );   // TODO: set using characteristics of the view
const CGFloat circleRadius = 130.0 ;

@implementation SporadicM12View

@synthesize toolbar;
@synthesize history;
@synthesize controller;
@synthesize tickSound;
@synthesize tockSound;
@synthesize swapSound;
@synthesize homeSound;
@synthesize shakeSound;
@synthesize restartSound;
@synthesize comboSound;
@synthesize comboSetSound;
@synthesize successSound;
@synthesize applauseSound;

@synthesize animateBallPops;

@synthesize historyTextCache;

- ( SporadicM12AppDelegate * ) appDelegate{ return ( SporadicM12AppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }
- ( bool ) soundEffects { return self.appDelegate.soundEffects; }
- ( bool ) invert { return self.appDelegate.invert; }
- ( bool ) useSpinMessages { return self.appDelegate.useSpinMessages; }
- (CGFloat ) animationSpeed { return self.appDelegate.animationSpeed ; }
- (GameModel * ) gameModel { return self.appDelegate.gameModel ; }

- (void ) updateHistoryText {  // Should cache in the controller?
    NSString * historyText = self.gameModel.history;
    NSUInteger historyLength = historyText.length;
    if ( historyTextCache.length == historyLength
      && [ historyTextCache compare:historyText options:NSLiteralSearch ] == NSOrderedSame )
        return;
    history.text = self.historyTextCache = historyText ;
    // I know of no good way to make the end of the string visible.
    //
    //    [ history scrollRangeToVisible: NSMakeRange( length, 0 ) ]
    //
    // causes awful bouncing text, as first the front and then the end
    // of the text is made visible.
    //
    //    history.selectedRange = NSMakeRange( length, 0 )
    //
    // is, amazingly, worse -- it brings up the keyboard!  To avoid that, the
    // history would need to be subclassed to respond NO to canBecomeFirstResponder.
    //    
}


- ( DualActionButton * ) createActionButtonAt: ( CGPoint    ) center
                                        width: ( CGFloat    ) width
                               normalSelector: ( SEL        ) normalSelector
                                  normalTitle: ( NSString * ) normalTitle
                            alternateSelector: ( SEL        ) alternateSelector
                               alternateTitle: ( NSString * ) alternateTitle
{	
    DualActionButton * button = 
        [ DualActionButton dualActionButtonWithFrame: CGRectMake( 0, 0, width, toolbarButtonHeight) 
                                              target: self.controller
                                      normalSelector: normalSelector
                                         normalTitle: normalTitle
                                   alternateSelector: alternateSelector
                                      alternateTitle: alternateTitle ] ;
    button.center = center ;
    return button ;
}


- (ComboButton *)createToolbarComboButtonWidth: ( CGFloat    ) width
                                     comboName: ( HistoryElement ) comboName
{
    return  [ ComboButton comboButtonWithFrame: CGRectMake( 0, 0, width, toolbarButtonHeight) 
                                        target: self.controller
                                     comboName: comboName ] ;
}

- (DualActionButton *)createToolbarAltButtonWidth: ( CGFloat    ) width
{
    return [ [ DualActionButton alloc ] 
            initWithFrame:     CGRectMake(0, 0, width, toolbarButtonHeight)   
            target:            self.controller
            normalSelector:    @selector( toggleInverted: )
            normalTitle:       @"Alt"
            alternateSelector: @selector( toggleInverted: )
            alternateTitle:    @"Alt"  ];
}

- ( ComboButton * ) createInfoButton
{
    ComboButton * button = [ UIButton buttonWithType:UIButtonTypeInfoDark ] ;
    [ button addTarget: self.controller
                action: @selector(toggleView:)
      forControlEvents: UIControlEventTouchUpInside ];
    button.center = INFO_BUTTON_CENTER;
    return button;
}


typedef enum{ flexibleSpace=1, comboButton=2, invButton=3 } ToolbarButtonType;

- (void) awakeFromNib
{

    self.tickSound     = [ [ SoundEffect alloc ] initWithResource:@"tick"      ofType:@"caf" ];
    self.tockSound     = [ [ SoundEffect alloc ] initWithResource:@"tock"      ofType:@"caf" ];
    self.swapSound     = [ [ SoundEffect alloc ] initWithResource:@"swap"      ofType:@"caf" ];
    self.homeSound     = [ [ SoundEffect alloc ] initWithResource:@"home"      ofType:@"caf" ];
    self.shakeSound    = [ [ SoundEffect alloc ] initWithResource:@"shake"     ofType:@"caf" ];
    //TODO: make real sound for restart amd combo 
    self.restartSound  = [ [ SoundEffect alloc ] initWithResource:@"restart"   ofType:@"caf" ];
    self.comboSound    = [ [ SoundEffect alloc ] initWithResource:@"combo"     ofType:@"caf" ];
    self.comboSetSound = [ [ SoundEffect alloc ] initWithResource:@"combo_set" ofType:@"caf" ];
    self.successSound  = [ [ SoundEffect alloc ] initWithResource:@"success"   ofType:@"caf" ];
    self.applauseSound = [ [ SoundEffect alloc ] initWithResource:@"applause"  ofType:@"caf" ];

    history.font = [UIFont systemFontOfSize:historyFontSize ];
    self.historyTextCache = @"";

    point ballCoordinates[ nBalls ];
    point tagCoordinates [ nBalls ];
    CalculateBallCoordinates( circleCenter, circleRadius, M12BallRadius, ballCoordinates, tagCoordinates);   //fills array with coordinates for the center of the ball
    CGRect frame = CGRectMake ( 0.0, 0.0, M12BallRadius*2, M12BallRadius*2 );

    // Do all the geometry
    forAllBalls(i)
    {
        ballCenters[ i ].x = round( ballCoordinates[ i ].x ) ;
        ballCenters[ i ].y = round( ballCoordinates[ i ].y );
    }

    // Create and add all the balls
    forAllBalls(i)
    {
        BallView *ballView = [ [BallView alloc] initWithFrame: frame ballNumber: i] ;      //TODO: if we're allocating all of these don't we need to release them? (keep track?)
        if (! ballView )
            return ;
        ballView.center = ballCenters[ i ];
        [self addSubview: ballView];
        ballViews[ i ] = ballView;
    }
    
    UIFont * ballFont = [UIFont systemFontOfSize:ballFontSize ];
    
    // Create and add all the labels (in front of the balls)
    forAllBalls(i)
    {
        UILabel * ballLabel = [ [ UILabel alloc ] initWithFrame: frame ];
        if (! ballLabel )
            return ;
        ballLabel.center = ballCenters[ i ];
        ballLabel.font = ballFont;
        ballLabel.textAlignment = UITextAlignmentCenter;
        ballLabel.backgroundColor = [ UIColor clearColor ];
        ballLabel.text = [NSString stringWithFormat:@"%d", i ];
        [self addSubview:ballLabel ];
        ballLabels[ i ] = ballLabel;                        //TODO retain count == 2?
    }
    
    UIFont * tagFont = [UIFont systemFontOfSize:tagFontSize ];
    
    // Create and add all the little gray labels (next to the balls)
    forAllBalls(i)
    {
        UILabel * tagLabel = [ [ UILabel alloc ] initWithFrame: frame ];
        if (! tagLabel )
            return ;
        tagLabel.center = CGPointMake( tagCoordinates[ i ].x, tagCoordinates[ i ].y );
        tagLabel.font = tagFont;
        tagLabel.textAlignment = UITextAlignmentCenter;
        tagLabel.backgroundColor = [ UIColor clearColor ];
        tagLabel.textColor = [ UIColor colorWithWhite:0.0 alpha:0.25 ];
        tagLabel.text = [NSString stringWithFormat:@"%d", i ];
        [self addSubview:tagLabel ];
    }
    
    // Create and add all the action buttons
    struct { NSString * normalTitle; SEL normalSelector; 
             NSString * alternateTitle; SEL alternateSelector; 
             CGPoint center; CGFloat width; UIButton * * variable; } dualActionButtons[ ] = {
                 { @"Shake", @selector(shake:)    , @"Restart", @selector(restart:)  , {  42,  34 }, largeActionButtonWidth , &shakeButton },
                 { @"Home" , @selector(home:)     , nil       , NULL                 , { 268,  34 }, largeActionButtonWidth , NULL         },
                 { @"Left" , @selector(left:)     , nil       , NULL                 , { 100, 190 }, mediumActionButtonWidth, NULL         },
                 { @"Swap" , @selector(swap:)     , nil       , NULL                 , { 160, 190 }, mediumActionButtonWidth, NULL         },
                 { @"Right", @selector(right:)    , nil       , NULL                 , { 220, 190 }, mediumActionButtonWidth, NULL         },
                 { @"Undo" , @selector(undoStep:) , @"Undo!"  , @selector(undoMove:) , { 289, 360 }, mediumActionButtonWidth, &undoButton  },
    };
    forArray( i, dualActionButtons )
    {
        DualActionButton * dualActionButton =  [ self createActionButtonAt: dualActionButtons[ i ].center
                                                                     width: dualActionButtons[ i ].width 
                                                            normalSelector: dualActionButtons[ i ].normalSelector
                                                               normalTitle: dualActionButtons[ i ].normalTitle
                                                         alternateSelector: dualActionButtons[ i ].alternateSelector
                                                            alternateTitle: dualActionButtons[ i ].alternateTitle ] ; // need this from table
        if ( dualActionButtons[ i ].variable != NULL )
            *(dualActionButtons[ i ].variable) = dualActionButton;
        [ self addSubview: dualActionButton ];
    }
    
    

    // Create and add the toolbar buttons
    struct { ToolbarButtonType type;
             NSString * title;
             CGFloat width;
           } toolbarButtons[ ] = {
               { flexibleSpace                            },
               { comboButton  ,  @"A"  , comboButtonWidth },
               { comboButton  ,  @"B"  , comboButtonWidth },
               { comboButton  ,  @"C"  , comboButtonWidth },
               { comboButton  ,  @"D"  , comboButtonWidth },
               { comboButton  ,  @"E"  , comboButtonWidth },
               { flexibleSpace                            },
               { invButton    ,  @"Alt", altButtonWidth   },
               { flexibleSpace                            },
           };


    NSMutableArray * toolbarArray = [ NSMutableArray array ];

    forArray( i, toolbarButtons )
    {
        ToolbarButtonType type = toolbarButtons[ i ].type;
        UIButton * toolbarButton ;
        UIBarButtonItem * theToolbarItem ;


        switch ( type )
        {
            case flexibleSpace:
                theToolbarItem = [ [ UIBarButtonItem alloc ]
                                    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                            target:nil
                                                            action:nil ] ;
                break;

            case comboButton:
                toolbarButton = [ self createToolbarComboButtonWidth: toolbarButtons[ i ].width
                                                           comboName: [ toolbarButtons[ i ].title characterAtIndex: 0] ];
                theToolbarItem = [ [UIBarButtonItem alloc] initWithCustomView: toolbarButton ];
                break;

            case invButton:
                toolbarButton = [ self createToolbarAltButtonWidth: toolbarButtons[ i ].width ];
                theToolbarItem = [ [UIBarButtonItem alloc] initWithCustomView: toolbarButton ];
                altButton = ( DualActionButton * )toolbarButton ;
                break;
        }
        theToolbarItem.tag = type;
        [ toolbarArray addObject: theToolbarItem ];
    }
    [ toolbar setItems:toolbarArray animated: false];
    
    [ self addSubview: [ self createInfoButton ] ];

    
    // Establish invariant between combo definednesses and combo buttons appearance
    for ( HistoryElement c='A'; c<=lastComboButton; c++ )
        [ self setComboButton:c enabled:[ self.gameModel hasDefinedCombo:c ] ];
    
    // Establish invariant between self.invert and the buttons appearance
    // as the buttons are created in the non-inverted state
    // Also, in the current hacked code, the buttons need to be correctly
    // pseudo-disabled (or not) to avoid being inverted while p-d.
    buttonsInverted = false;
    if ( self.invert ) [self setInvertibleButtonsInverted: true ];
    
    // Not currently spinning
    firstWedgeTouched = -1;
    
    // Not currently doing Swap gesture
    swapGestureStarted = false;

    // Let's see it
    [ self showCurrentPermutationAtDuration: INSTANTANEOUS ];

}





- (void) animatePopBall:(Index)nBall first:(bool) first {
    /*
     Create animation for the grow, which uses a delegate method to
     start an animation for the shrink operation.
     */
    [UIView beginAnimations:nil context:(void *)( first ? +nBall : -nBall )];
    [UIView setAnimationDuration: GROW_ANIMATION_DURATION_SECONDS];
    [UIView setAnimationDelegate: self ];
    [UIView setAnimationDidStopSelector:@selector(growAnimationDidStop:finished:context:) ];
    CGFloat ballBloom  = first ? FIRST_BALL_BLOOM_FACTOR  : SUBSEQUENT_BALL_BLOOM_FACTOR ;
    CGFloat labelBloom = first ? FIRST_LABEL_BLOOM_FACTOR : SUBSEQUENT_LABEL_BLOOM_FACTOR;
    ballViews [nBall].transform = CGAffineTransformMakeScale(ballBloom , ballBloom );
    ballLabels[nBall].transform = CGAffineTransformMakeScale(labelBloom, labelBloom);
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
    ballViews [ nBall ].transform = CGAffineTransformIdentity;
    ballLabels[ nBall ].transform = CGAffineTransformIdentity;
    [UIView commitAnimations];
}



-(void) animateButton:( DualActionButton *)button 
          normalTitle:( NSString * )normalTitle
        invertedTitle:( NSString *)invertedTitle
             inverted:( bool ) inverted
{
    [UIView beginAnimations:nil context:NULL ];
    [UIView setAnimationDuration: BUTTON_INVERSION_DURATION ];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:button 
                             cache:YES];
    button.alternate = inverted;
    [UIView commitAnimations];
}


-( void ) setActionButtonsInverted:(bool)inverted{
    if ( [ self.gameModel isSolving ] )
        [ self animateButton:shakeButton
                 normalTitle:@"Shake"
               invertedTitle:@"Restart"
                    inverted:inverted ];
    [ self animateButton:undoButton
             normalTitle:@"Undo"
           invertedTitle:@"Undo!"
                inverted:inverted ];
}

-( void ) setComboButtonsInverted:(bool)inverted
{
    NSEnumerator * toolbarItemsEnumerator = self.toolbar.items.objectEnumerator;
    UIBarButtonItem * item;
    while ( item = [ toolbarItemsEnumerator nextObject ] )
        if ( item.tag == (int)comboButton )
        {
            ComboButton * button = (ComboButton *)item.customView;
            NSString * comboName = [ [ button titleForState:UIControlStateNormal ] substringToIndex:1 ] ;
            [ self animateButton: button
                     normalTitle: comboName
                   invertedTitle: [ comboName stringByAppendingFormat:@"%C%C",
                                                                      superscriptMinus,
                                                                      superscriptOne ]
                        inverted: inverted ];
        }
}

-( void ) setAltButtonInverted:(bool)inverted{
//    This doesn't work, because the reversion happens later:
//      button.highlighted = inverted;
//    But I will not be denied a highlighted button!
    altButton.alternate = inverted;
}


- (void) setInvertibleButtonsInverted:(bool)inverted
{
    if ( buttonsInverted == inverted ) return;
    [ self setActionButtonsInverted: inverted ];
    [ self setComboButtonsInverted:  inverted ];
    [ self setAltButtonInverted:     inverted ];
    buttonsInverted = inverted;
}


-( void ) setComboButton:( HistoryElement )c enabled:( const bool )enabled
{
    NSEnumerator * toolbarItemsEnumerator = self.toolbar.items.objectEnumerator;
    UIBarButtonItem * item;
    while ( item = [ toolbarItemsEnumerator nextObject ] )
        if ( item.tag == (int)comboButton )
        {
            ComboButton * button = ( ComboButton * )item.customView;
            if ( c == button.comboName )
                button.disabled = !enabled;
        }
}


    
-(void) showCurrentPermutationAtDuration:(CGFloat)duration {
    duration *= ( MAX_ANIMATION_DURATION_FACTOR - self.animationSpeed ) ;
    if ( 0.0 < duration )
    {
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView beginAnimations:nil context:NULL ];
        [UIView setAnimationDuration: duration ];
    }
    forAllBalls(i)
    {
        ballLabels[ [ self.gameModel at: i ] ].center = ballCenters[ i ];
    }
    if ( 0.0 < duration )
        [UIView commitAnimations];
    
    [ self updateHistoryText ];
    
    undoButton.enabled = ! [ self.gameModel historyIsEmpty ] ;
}

- (bool) findWedgeAtTouch:(UITouch *)touch tolerant: ( bool ) tolerant
                  asWedge: ( Index & ) wedge
                 andTheta: ( double & ) theta{
    CGPoint touchPoint = [ touch locationInView: self ];
    CGFloat annulusSemiWidth = tolerant ? circleRadius : TOUCH_SPOT_SIZE/2;
    return FindBallWedge( point( touchPoint.x, touchPoint.y ),
                         circleCenter, circleRadius - annulusSemiWidth, circleRadius + annulusSemiWidth,
                         wedge, theta ) ;
}

- (bool) touch:(UITouch *)touch onBall:( Index )nBall{
    CGRect ballZeroRect = CGRectMake( ballCenters[ nBall ].x-TOUCH_SPOT_SIZE/2,
                                      ballCenters[ nBall ].y-TOUCH_SPOT_SIZE/2,
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
    return FindBallWedge( point( touchPoint.x, touchPoint.y ),
                          circleCenter, 0, circleRadius + TOUCH_SPOT_SIZE/2,
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [ touches anyObject ];
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
    if ( self.animateBallPops ) [ self animatePopBall:wedgeAtTouch first:YES ];
}




- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *) event {
    if ( swapGestureStarted )
    {
        UITouch * touch = [ touches anyObject ];
        if ( [ self innerWedgeOneContainsTouch:touch ] )
            [ self.controller swap: self ];
        swapGestureStarted = false;
        return;
    }
    if ( firstWedgeTouched == -1 ) return;
    [ self touchesMoved:touches withEvent: event ];
    if ( self.useSpinMessages )
        [ self.controller spinFinished: [ self spinClicks: wedgeDifference( lastWedgeTouched, previousWedgeTouched ) ] ];
    else
    {
        [ self spinClicks: wedgeDifference( lastWedgeTouched, previousWedgeTouched ) ] ;
        [ self.controller spinFinished: wedgeDifference( lastWedgeTouched, firstWedgeTouched ) ];
    }
    firstWedgeTouched = -1 ;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *) event {
    if ( swapGestureStarted )
        return ;
    if ( firstWedgeTouched == - 1 )
    {
        [ self touchesBegan:touches withEvent:event ] ;
        return;
    }

    UITouch * touch = [ touches anyObject ];
    Index wedgeAtTouch;
    double thetaAtTouch;
    if ( ! [ self findWedgeAtTouch:touch tolerant:YES
                           asWedge: wedgeAtTouch andTheta: thetaAtTouch ] )
    {
        [ self touchesEnded:touches withEvent:event ];
        return;
    }
    lastWedgeTouched = wedgeAtTouch;
    lastThetaTouched = thetaAtTouch ;
    for (Index i = 1; i < nBalls ; i++ )
    {
        UILabel * ballLabel = ballLabels[ spinStartingPosition[ i ] ];
        /*
         ballLabel is currently who-knows-where.
         But where we want it to be is (lastThetaTouched-firstThetaTouched) from where it started.
         It started at ballCenters[ i ].

         */
        CGPoint oldBallCenter = ballCenters[ i ];
        point spun = point( polar( point( oldBallCenter.x, oldBallCenter.y) 
                                   - circleCenter ).rotate( lastThetaTouched - firstThetaTouched ) ) 
                     + circleCenter;
        ballLabel.center = CGPointMake( spun.x, spun.y );
    }

    if ( self.useSpinMessages )
        [ self.controller spinInProgress: [ self spinClicks: wedgeDifference( lastWedgeTouched , previousWedgeTouched ) ] ];
    else
        [ self spinClicks: wedgeDifference( lastWedgeTouched , previousWedgeTouched ) ];
    previousWedgeTouched = lastWedgeTouched ;
}


- (void)dealloc {
    altButton = nil;
    forAllBalls( i )
    {
        [ ballLabels[ i ] release ];
        ballLabels[ i ] = nil;
        [ ballViews[ i ] release ];
        ballViews[ i ] = nil;
    }
    [ tickSound     release ] ;
    [ tockSound     release ] ;
    [ swapSound     release ] ;
    [ homeSound     release ] ;
    [ shakeSound    release ] ;
    [ restartSound  release  ] ;
    [ comboSound    release ] ;
    [ comboSetSound release ] ;
    [ successSound  release ] ;
    [ applauseSound release ] ;
    [ history release       ] ;
    [ super dealloc         ] ;
}


-( void ) playRightSound    { if ( self.soundEffects ) [ tickSound     play ]; }
-( void ) playLeftSound     { if ( self.soundEffects ) [ tockSound     play ]; }
-( void ) playSwapSound     { if ( self.soundEffects ) [ swapSound     play ]; }
-( void ) playHomeSound     { if ( self.soundEffects ) [ homeSound     play ]; }
-( void ) playShakeSound    { if ( self.soundEffects ) [ shakeSound    play ]; }
-( void ) playRestartSound  { if ( self.soundEffects ) [ restartSound  play ]; }
-( void ) playComboSound    { if ( self.soundEffects ) [ comboSound    play ]; }
-( void ) playComboSetSound { if ( self.soundEffects ) [ comboSetSound play ]; }
-( void ) playSuccessSound  
{ 
    if ( self.soundEffects ) 
    {
        if ( self.gameModel.historyLength <= APPLAUSE_THRESHOLD )
            [ applauseSound play ];
        else
            [ successSound  play ]; 
    }
}


@end
