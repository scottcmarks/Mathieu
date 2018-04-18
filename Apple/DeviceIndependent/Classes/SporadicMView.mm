//
//  SporadicMView.mm
//  SporadicM
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"
#import "view.h"
#import "Constants.h"
#import "Utilities.h"
#import "iPhoneUtilities.h"
#import "SporadicMView.h"
#import "SporadicMViewController.h"
#import "SporadicMAppDelegate.h"
#import "ComboButton.h"
#import "BallRingView.h"

#if TARGET_MACOS & ! TARGET_IOS

@interface NSTextField(UILabelCompatibility)
-(NSString *) text;
-(void) setText: (NSString *) text;
@end

@implementation NSTextField(UILabelCompatibility)
-(NSString *) text
{
    return [ self stringValue ];
};
-(void) setText: (NSString *) text
{
    [ self setStringValue: text ];
};
@end

@interface NSToolbarItem(UIBarButtonItemCompatibility)
-(NSView *) customView;
-(void) setCustomView: (NSView *) customView;
@end

@implementation NSToolbarItem(UIBarButtonItemCompatibility)
-(NSView *) customView
{
    return [ self view ];
};
-(void) setCustomView: (NSView *) customView
{
    [ self setView: customView ];
};
@end

#endif

@interface SporadicMView ()
@property ( nonatomic, strong, readwrite ) IBOutlet UIView * ballRingViewContainerView;
@end

@implementation SporadicMView
@synthesize toolbar;
@synthesize history;
@synthesize moves;
@synthesize controller;
@synthesize historyTextUpdatingTimer;
@synthesize ballRingViewContainerView;
@synthesize ballRingView;

//  @synthesize animateBallPops;

@synthesize historyTextCache;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }
- ( bool ) invert { return self.appDelegate.invert; }
- (CGFloat ) animationSpeed { return self.appDelegate.animationSpeed ; }
- (GameModel * ) gameModel { return self.appDelegate.gameModel ; }


- (void ) updateHistoryText {  // Should cache in the controller?
    NSString * historyText = self.gameModel.history;
    NSUInteger historyLength = historyText.length;
    if ( historyTextCache.length == historyLength
      && [ historyTextCache compare: historyText options: NSLiteralSearch ] == NSOrderedSame )
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
#if TARGET_IOS
    DualActionButton * button =
        [ DualActionButton dualActionButtonWithFrame: CGRectMake( center.x - width/2,
                                                                  center.y - toolbarButtonHeight/2,
                                                                  width,
                                                                  toolbarButtonHeight)
                                              target: self.controller
                                      normalSelector: normalSelector
                                         normalTitle: normalTitle
                                   alternateSelector: alternateSelector
                                      alternateTitle: alternateTitle ] ;
    return button ;
#elif TARGET_MACOS
    return nil;
#else
#error Don't know this platform!
#endif
}


- (ComboButton *)createToolbarComboButtonWidth: ( CGFloat    ) width
                                     comboName: ( HistoryElement ) comboName
{
#if TARGET_IOS
    return  [ ComboButton comboButtonWithFrame: CGRectMake( 0, 0, width, toolbarButtonHeight)
                                        target: self.controller
                                     comboName: comboName ] ;
#elif TARGET_MACOS
    return nil;
#else
#error Don't know this platform!
#endif
}

- (DualActionButton *)createToolbarAltButtonWidth: ( CGFloat    ) width
{
#if TARGET_IOS
    return [ [ DualActionButton alloc ]
            initWithFrame:     CGRectMake(0, 0, width, toolbarButtonHeight)
            target:            self.controller
            normalSelector:    @selector( toggleInverted )
            normalTitle:       @"Alt"
            alternateSelector: @selector( toggleInverted )
            alternateTitle:    @"Alt"  ];
#elif TARGET_MACOS
    return nil;
#else
#error Don't know this platform!
#endif
}

- ( Button * ) createInfoButton
{
    Button * button;
#define INFO_BUTTON_CENTER ( DEVICE_IS_IPAD ? CGPointMake( 76.8 , 848 ) : CGPointMake( 32.0 , 382 ) )

#if TARGET_IOS
    button = [ Button buttonWithType:UIButtonTypeInfoDark ] ;
    [ button addTarget: self.controller
                action: @selector(toggleView)
      forControlEvents: UIControlEventTouchUpInside ];
    button.center = INFO_BUTTON_CENTER;
#elif TARGET_MACOS
#else
    button = [ [ Button alloc ] init ];
    [ button setButtonType: NSMomentaryLightButton ];
    [ button addTarget: self.controller
                action: @selector(toggleView)
      forControlEvents: UIControlEventTouchUpInside ];
    button.center = INFO_BUTTON_CENTER;
#error Don't know this platform!
#endif

    return button;
}


typedef enum{ flexibleSpace=1, comboButton=2, invButton=3 } ToolbarButtonType;

typedef struct { NSString * normalTitle; SEL normalSelector;
                NSString * alternateTitle; SEL alternateSelector;
                CGPoint center; CGFloat width; DualActionButton * * variable; } ButtonDescription ;

- (void) awakeFromNib
{
    [super awakeFromNib];
    
#if CONSTRUCT_PROGRAMMATICALLY
    ButtonDescription dualActionButtons_iPhone[ ] =
    {
        { @"Shake", @selector(shake)    , @"Restart", @selector(restart)  , {  42,  54 }, largeActionButtonWidth , &shakeButton },
        { @"Home" , @selector(home)     , nil       , NULL                , { 268,  54 }, largeActionButtonWidth , NULL         },
        { @"Left" , @selector(left)     , nil       , NULL                , { 130, 240 }, mediumActionButtonWidth, NULL         },
        { @"Swap" , @selector(swap)     , nil       , NULL                , { 160, 195 }, mediumActionButtonWidth, NULL         },
        { @"Right", @selector(right)    , nil       , NULL                , { 190, 240 }, mediumActionButtonWidth, NULL         },
        { @"Undo" , @selector(undoStep) , @"Undo!"  , @selector(undoMove) , { 289, 380 }, mediumActionButtonWidth, &undoButton  },
    } ;
    
    ButtonDescription dualActionButtons_iPad[ ] =-
    {
        { @"Shake", @selector(shake)    , @"Restart", @selector(restart)  , { 100,  94 }, largeActionButtonWidth , &shakeButton },
        { @"Home" , @selector(home)     , nil       , NULL                , { 634,  94 }, largeActionButtonWidth , NULL         },
        { @"Left" , @selector(left)     , nil       , NULL                , { 312, 500 }, mediumActionButtonWidth, NULL         },
        { @"Swap" , @selector(swap)     , nil       , NULL                , { 384, 402 }, mediumActionButtonWidth, NULL         },
        { @"Right", @selector(right)    , nil       , NULL                , { 456, 500 }, mediumActionButtonWidth, NULL         },
        { @"Undo" , @selector(undoStep) , @"Undo!"  , @selector(undoMove) , { 694, 806 }, mediumActionButtonWidth, &undoButton  },
    } ;
    
    #if TARGET_IOS
        ButtonDescription dualActionButtons[ 6 ] ;
        if ( DEVICE_IS_IPAD )
            forArray( i , dualActionButtons_iPad )
                dualActionButtons[ i ] = dualActionButtons_iPad[ i ] ;
        else
            forArray( i , dualActionButtons_iPhone )
                dualActionButtons[ i ] = dualActionButtons_iPhone[ i ] ;
    #elif TARGET_MACOS
        #error Haven't defined action button description array!
    #else
        #error Don't know this platform!
    #endif
#endif // -CONSTRUCT_PROGRAMMATICALLY

    //DEBUG  [self.ballRingView createEverythingButDontWorryAboutLayout];
    self.ballRingView.delegate = self.controller;

#if CONSTRUCT_PROGRAMMATICALLY
#if !ICONIC_PICTURE_ONLY

	history.font = [ Font systemFontOfSize: historyFontSize ];
    self.historyTextCache = @"";
    moves.font = [ Font systemFontOfSize: movesFontSize ];
    moves.text = [ NSString stringWithFormat: @"%d\n%d", self.gameModel.moves, self.gameModel.steps ];

     // Create and add all the action buttons
    forArray( i, dualActionButtons )
    {
#if TARGET_IOS
        DualActionButton * dualActionButton =  [ self createActionButtonAt: dualActionButtons[ i ].center
                                                                     width: dualActionButtons[ i ].width
                                                            normalSelector: dualActionButtons[ i ].normalSelector
                                                               normalTitle: dualActionButtons[ i ].normalTitle
                                                         alternateSelector: dualActionButtons[ i ].alternateSelector
                                                            alternateTitle: dualActionButtons[ i ].alternateTitle ] ; // need this from table
        if ( dualActionButtons[ i ].variable != NULL )
            *(dualActionButtons[ i ].variable) = dualActionButton;
        [ self addSubview: dualActionButton ];
#elif TARGET_MACOS
#error Haven't coded setup of action buttons!
#else
#error Don't know this platform!
#endif
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
        ToolbarButtonItem * theToolbarItem ;


        switch ( type )
        {
            case flexibleSpace:
                theToolbarItem = [ ToolbarButtonItem alloc ];
#if TARGET_IOS
                theToolbarItem = [ theToolbarItem initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                       target:nil
                                                                       action:nil ] ;
#elif TARGET_MACOS
                theToolbarItem = [ theToolbarItem initWithItemIdentifier: NSToolbarFlexibleSpaceItemIdentifier ];
#else
#error Don't know this platform!
#endif
                break;

            case comboButton: {
                ComboButton * toolbarButton = [ self createToolbarComboButtonWidth: toolbarButtons[ i ].width
                                                                         comboName: [ toolbarButtons[ i ].title characterAtIndex: 0] ];
                theToolbarItem = [ToolbarButtonItem alloc];
#if TARGET_IOS
                theToolbarItem = [ theToolbarItem initWithCustomView: toolbarButton ];
#elif TARGET_MACOS
                theToolbarItem = [ theToolbarItem init ];
                [ theToolbarItem setView: toolbarButton ];
#else
#error Don't know this platform!
#endif
                break;
            }
            case invButton: {
                DualActionButton * toolbarButton = [ self createToolbarAltButtonWidth: toolbarButtons[ i ].width ];
                theToolbarItem = [ToolbarButtonItem alloc];
#if TARGET_IOS
                theToolbarItem = [ theToolbarItem initWithCustomView: toolbarButton ];
#elif TARGET_MACOS
                theToolbarItem = [ theToolbarItem init ];
                [ theToolbarItem setView: toolbarButton ];
#else
#error Don't know this platform!
#endif
                altButton = toolbarButton ;
                break;
            }
        }
        theToolbarItem.tag = type;
        [ toolbarArray addObject: theToolbarItem ];
    }

#if TARGET_IOS
    [ toolbar setItems:toolbarArray animated: false];
#elif TARGET_MACOS
    NSLog(@"Don't yet build the toolbar");
#else
#error Don't know this platform!
#endif

    [ self addSubview: [ self createInfoButton ] ];
#endif // CONSTRUCT_PROGRAMMATICALLY


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
    #if TARGET_IOS
        history.hidden = NO;
        moves.hidden = NO;
        toolbar.hidden = NO;
        #if CONSTRUCT_PROGRAMMATICALLY
            self.backgroundColor = [ UIColor blackColor ];
        #endif // CONSTRUCT_PROGRAMMATICALLY
    #elif TARGET_MACOS
    #else
        #error Don't know this platform!
    #endif

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
    ToolbarButtonItem * item;
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
    ToolbarButtonItem * item;
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
    ToolbarButtonItem * item;
    while ( item = [ toolbarItemsEnumerator nextObject ] )
        if ( item.tag == (int)comboButton )
        {
            ComboButton * button = ( ComboButton * )item.customView;
            button.disabled = true;
        }
}

-(void) showCurrentPermutationAtDuration:(CGFloat)duration
{
#if TARGET_IOS
    duration *= ( MAX_ANIMATION_DURATION_FACTOR - self.animationSpeed ) ;
    if ( 0.0 < duration )
    {
        [View setAnimationBeginsFromCurrentState:YES];
        [View beginAnimations:nil context:NULL ];
        [View setAnimationDuration: duration ];
    }
#endif

    [ ballRingView moveLabels ];

#if TARGET_IOS
    if ( 0.0 < duration )
        [View commitAnimations];
#endif

    [ self updateHistoryText ];

    [ undoButton setEnabled: ! [ self.gameModel historyIsEmpty ] ] ;
}


- (void)dealloc {
    altButton = nil;
    self.history = nil;
    [ historyTextUpdatingTimer invalidate ];
    self.historyTextUpdatingTimer = nil;
    self.historyTextCache = nil;
    self.ballRingViewContainerView = nil;
    [ super dealloc         ] ;
}


@end
