//
//  SporadicMView.mm
//  SporadicM
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#import "Apple Cross-platform.h"
#import "view.h"
#import "Constants.h"
#import "Utilities.h"
#import "iPhoneUtilities.h"
#import "SporadicMViewController.h"
#import "SporadicMAppDelegate.h"
#import "ComboBarButton.h"
#import "SporadicMView.h"

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

#endif //  TARGET_MACOS & ! TARGET_IOS

@implementation AppleLabelClearsBeforeWriting
-(void) drawTextInRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextFillRect(context, rect);
    [super drawTextInRect:rect];
}
@end

@interface SporadicMView ()
@property ( nonatomic, strong, readwrite ) IBOutlet UIView * ballRingViewContainerView;
@property ( nonatomic, readwrite ) bool buttonsInverted;
@end

@implementation SporadicMView
@synthesize moves;
@synthesize history;
@synthesize toolbar;
@synthesize shakeButton;
@synthesize altButton;
@synthesize undoButton;
@synthesize controller;
@synthesize historyTextUpdatingTimer;
@synthesize ballRingViewContainerView;
@synthesize ballRingView;
@synthesize buttonsInverted;

//  @synthesize animateBallPops;

@synthesize historyTextCache;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ AppleApplication sharedApplication ] delegate ] ; }
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

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    //DEBUG  [self.ballRingView createEverythingButDontWorryAboutLayout];
    self.ballRingView.delegate = self.controller;
    [self.ballRingView createSubviews];
}

- (void) forComboButtons:(void(^)(ComboBarButton *, BOOL *_Nonnull ))block {
    NSArray<AppleToolbarButtonItem *> * items = self.toolbar.items;
    [items enumerateObjectsUsingBlock:^(AppleToolbarButtonItem * item, NSUInteger __unused idx, BOOL * _Nonnull stop) {
        if ( [ item.customView isKindOfClass:ComboBarButton.class ] ) block(item.customView, stop);
    }];
}

- (void) forValidComboButtons:(void(^)(ComboBarButton *, BOOL *_Nonnull ))block {
    [self forComboButtons:^(ComboBarButton * button, BOOL * _Nonnull stop) {
        HistoryElement c = button.comboName;
        if (c <= lastComboButtonForThisVersion) block(button, stop);
    }];
}



- (void) initializeViews
{
#if !ICONIC_PICTURE_ONLY

    // Establish invariant between combo definednesses and combo buttons appearance
    [BallView setColorsForCurrentSwapPermutation];
    
    [self forComboButtons:^(ComboBarButton * button, BOOL * _Nonnull ) {
        HistoryElement c = button.comboName;
        if (c <= lastComboButtonForThisVersion) {
            button.enabled = YES;
            button.hidden = NO;
            button.disabled = ![ self.gameModel hasDefinedCombo:c ];
        } else {
            button.enabled = NO;
            button.hidden = YES;
        }
    }];
    // Establish invariant between self.invert and the buttons appearance
    // as the buttons are created in the non-inverted state
    // Also, in the current hacked code, the buttons need to be correctly
    // pseudo-disabled (or not) to avoid being inverted while p-d.
    buttonsInverted = false;
    if ( self.invert ) [self setInvertibleButtonsInverted: true ];

    [ BallView setColorsForSwapPermutation: MathieuPermutation::swapPermutation ] ;
    [self.ballRingView redraw];

    // Let's see it
    [ self showCurrentPermutationAtDuration: INSTANTANEOUS ];

    // Start history text updating timer
    self.historyTextUpdatingTimer = [ NSTimer timerWithTimeInterval:(NSTimeInterval)0.2
                                                             target:self
                                                           selector:@selector(historyUpdatingTimerFired:)
                                                           userInfo:nil
                                                            repeats:YES ];
    [ [ NSRunLoop currentRunLoop ] addTimer:self.historyTextUpdatingTimer forMode: NSDefaultRunLoopMode];

#else // !ICONIC_PICTURE_ONLY

    #if TARGET_IOS
        history.hidden = NO;
        moves.hidden = NO;
        toolbar.hidden = NO;
    #elif TARGET_MACOS
    #else
        #error Don't know this platform!
    #endif // TARGET_IOS or TARGET_MACOS

#endif // !ICONIC_PICTURE_ONLY

}


-( void ) setActionButtonsInverted: ( bool ) inverted
{
    if ( [ self.gameModel isSolving ] )
        shakeButton.alternate = inverted;
    undoButton.alternate = inverted;
}

-( void ) setComboBarButtonsInverted: ( bool ) inverted
{
    [self forComboButtons:^(ComboBarButton * button, BOOL * _Nonnull ) {
        if (!button.disabled) button.alternate = inverted;
    }];
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
    [ self setComboBarButtonsInverted:  inverted ];
    [ self setAltButtonInverted:     inverted ];
    buttonsInverted = inverted;
}


-( void ) setComboButton:( HistoryElement )c enabled:( const bool )enabled
{
    [self forComboButtons:^(ComboBarButton * button, BOOL * _Nonnull stop) {
        if ( c == button.comboName ) {
                button.disabled = !enabled;
                *stop=YES;
            }
        }];
}

-( void ) disableAllComboButtons
{
    [self forComboButtons:^(ComboBarButton * button, BOOL * _Nonnull ) { button.disabled = YES; }];
}

-(void) showCurrentPermutationAtDuration:(CGFloat)duration
{

#if TARGET_IOS
    duration *= ( MAX_ANIMATION_DURATION_FACTOR - self.animationSpeed ) ;
    if (duration <= 0.0) duration = 0.01;
    [SporadicMView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                            animations:^{
                                [ ballRingView moveLabels ];
                            }
                            completion:nil];

#else //  TARGET_IOS
    [ ballRingView moveLabels ];
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
