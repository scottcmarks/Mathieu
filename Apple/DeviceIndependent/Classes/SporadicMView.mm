//
//  SporadicMView.mm
//  SporadicM
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "view.h"
#import "Constants.h"
#import "Utilities.h"
#import "iPhoneUtilities.h"
#import "SporadicMView.h"
#import "SporadicMViewController.h"
#import "SporadicMAppDelegate.h"
#import "ComboButton.h"
#import "BallRingView.h"

@implementation SporadicMView

@synthesize toolbar;
@synthesize history;
@synthesize moves;
@synthesize controller;
@synthesize historyTextUpdatingTimer;
@synthesize ballRingView;

//  @synthesize animateBallPops;

@synthesize historyTextCache;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }
- ( bool ) invert { return self.appDelegate.invert; }
- (CGFloat ) animationSpeed { return self.appDelegate.animationSpeed ; }
- (GameModel * ) gameModel { return self.appDelegate.gameModel ; }

- (void ) updateHistoryText {  // Should cache in the controller?
    NSString * historyText = self.gameModel.history;
    NSUInteger historyLength = historyText.length;
    if ( historyTextCache.length == historyLength
      && [ historyTextCache compare:historyText options:NSLiteralSearch ] == NSOrderedSame )
        return;
    history.text = self.historyTextCache = historyText ;
    moves.text = [ NSString stringWithFormat:@"%d\n%d", self.gameModel.moves, self.gameModel.steps ];
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

- ( void ) historyUpdatingTimerFired: (NSTimer *) theTimer
{
    [ self updateHistoryText ];
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
    CGFloat ballRingFrameSize = min ( CGRectGetWidth( self.frame ), CGRectGetHeight( self.frame ) );
    ballRingView = [ BallRingView ballRingViewWithFrame: CGRectMake( CGRectGetMinX( self.frame ), CGRectGetMinY( self.frame ), 
                                                                    ballRingFrameSize, ballRingFrameSize ) 
                                                   tags: YES 
                                               delegate: self.controller ];
    [ self addSubview: ( UIView *) ballRingView ];
    
#if !ICONIC_PICTURE_ONLY        

	history.font = [UIFont systemFontOfSize:historyFontSize ];
    self.historyTextCache = @"";
    moves.font = [ UIFont systemFontOfSize:movesFontSize ];
    moves.text = [ NSString stringWithFormat:@"%d\n%d", self.gameModel.moves, self.gameModel.steps ];
    
     // Create and add all the action buttons
    struct { NSString * normalTitle; SEL normalSelector; 
             NSString * alternateTitle; SEL alternateSelector; 
             CGPoint center; CGFloat width; UIButton * * variable; } dualActionButtons[ ] = {
                 { @"Shake", @selector(shake:)    , @"Restart", @selector(restart:)  , {  42,  34 }, largeActionButtonWidth , &shakeButton },
                 { @"Home" , @selector(home:)     , nil       , NULL                 , { 268,  34 }, largeActionButtonWidth , NULL         },
                 { @"Left" , @selector(left:)     , nil       , NULL                 , { 130, 220 }, mediumActionButtonWidth, NULL         },
                 { @"Swap" , @selector(swap:)     , nil       , NULL                 , { 160, 175 }, mediumActionButtonWidth, NULL         },
                 { @"Right", @selector(right:)    , nil       , NULL                 , { 190, 220 }, mediumActionButtonWidth, NULL         },
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
           } toolbarButtons[ ] = 
           {
               { flexibleSpace                            },
               { comboButton  ,  @"A"  , comboButtonWidth },
#if FREE               
               { flexibleSpace                            },
#endif               
               
               { comboButton  ,  @"B"  , comboButtonWidth },
#if !FREE               
               { comboButton  ,  @"C"  , comboButtonWidth },
               { comboButton  ,  @"D"  , comboButtonWidth },
    #if !defined( infoInToolbar )               
               { comboButton  ,  @"E"  , comboButtonWidth },
    #endif               
#endif               
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
    

    // Let's see it
    [ self showCurrentPermutationAtDuration: INSTANTANEOUS ];
    
    // Start history text updating timer
    self.historyTextUpdatingTimer = [ NSTimer timerWithTimeInterval:(NSTimeInterval)0.2 
                                                             target:self 
                                                           selector:@selector(historyUpdatingTimerFired:) 
                                                           userInfo:nil 
                                                            repeats:YES ];
    [ [ NSRunLoop currentRunLoop ] addTimer:self.historyTextUpdatingTimer forMode: NSDefaultRunLoopMode];

#else
    
    history.hidden = YES;
    moves.hidden = YES;
    toolbar.hidden = YES;
    self.backgroundColor = [ UIColor blackColor ];
    
#endif

}


-( void ) setActionButtonsInverted: ( bool ) inverted
{
    if ( [ self.gameModel isSolving ] )
        shakeButton.alternate = inverted;
    undoButton.alternate = inverted;
}

-( void ) setComboButtonsInverted: ( bool ) inverted
{
    NSEnumerator * toolbarItemsEnumerator = self.toolbar.items.objectEnumerator;
    UIBarButtonItem * item;
    while ( item = [ toolbarItemsEnumerator nextObject ] )
        if ( item.tag == (int)comboButton )
        {
            ComboButton * button = (ComboButton *)item.customView;
            button.alternate = inverted;
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

-( void ) disableAllComboButtons
{
    NSEnumerator * toolbarItemsEnumerator = self.toolbar.items.objectEnumerator;
    UIBarButtonItem * item;
    while ( item = [ toolbarItemsEnumerator nextObject ] )
        if ( item.tag == (int)comboButton )
        {
            ComboButton * button = ( ComboButton * )item.customView;
            button.disabled = true;
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
    
    [ ballRingView moveLabels ];

    if ( 0.0 < duration )
        [UIView commitAnimations];
    
    [ self updateHistoryText ];
    
    undoButton.enabled = ! [ self.gameModel historyIsEmpty ] ;
}


- (void)dealloc {
    altButton = nil;
    [ history release       ] ;
    [ historyTextUpdatingTimer invalidate ];
    [ historyTextUpdatingTimer release ];
    [ super dealloc         ] ;
}


@end
