//
//  ComboButton.m
//  SporadicM12
//
//  Created by Jackie Marks on 1/7/09.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Constants.h"
#import "Utilities.h"
#import "view.h"
#import "ComboButton.h"

// Class variables
static Image * comboButtonDisabledImage    ;

@interface ComboButton( PrivateLocking )
- ( bool ) isTimerRunning;
@end

@implementation ComboButton

+ ( void ) initialize
{
    comboButtonDisabledImage = [ [ [ Image imageNamed: @"ComboButtonDisabled.png" ]
                                        stretchableImageWithLeftCapWidth: 12.0
                                                            topCapHeight: 0.0 ]
                                      retain ] ;
}

+ ( id ) comboButtonWithFrame: ( CGRect                  ) frame
                       target: ( id< ComboButtonTarget > ) target
                    comboName: ( HistoryElement          ) comboName
{
    return [ [ [ ComboButton alloc ] initWithFrame: ( CGRect         ) frame
                                            target: ( id             ) target
                                         comboName: ( HistoryElement ) comboName ] autorelease ] ;
}


// Instance variables


@dynamic alternate;
-( BOOL ) alternate { return alternate ; }
-( void ) setAlternate: ( BOOL ) alt
{
    if ( alt == alternate ) return ;
    if ( !disabled )
        [ super setAlternate: alt ] ;
    else
        alternate = alt;
}


@dynamic disabled;
-( BOOL ) disabled { return disabled ; }
-( void ) setDisabled: ( BOOL ) dis
{
    if ( dis == disabled ) return ;
    if ( dis )
    {
        if ( alternate )
            [ self setTitle:           normalTitle               forState: UIControlStateNormal ];
        [ self setBackgroundImage: comboButtonDisabledImage  forState: UIControlStateNormal ] ;
    }
    else if ( alternate )
    {
        [ self setTitle:           alternateTitle            forState: UIControlStateNormal ];
        [ self setBackgroundImage: alternateImage            forState: UIControlStateNormal ] ;
    }
    else
    {
        [ self setBackgroundImage: normalImage    forState: UIControlStateNormal ] ;
    }
    disabled = dis;
}


@synthesize comboName;


- (id) initWithFrame: ( CGRect                  ) frame
              target: ( id< ComboButtonTarget > ) targ
           comboName: ( HistoryElement          ) m
{
    if ( self = [ super initWithFrame: frame
                               target: self
                       normalSelector: @selector( touchUpInside: )
                          normalTitle: [ NSString stringWithFormat: @"%c", m ]
                    alternateSelector: @selector( touchUpInside: )
                       alternateTitle: [ NSString stringWithFormat: @"%c%C%C", m, superscriptMinus, superscriptOne ] ] )
    {
        [ self addTarget: self action: @selector( touchDown: )
                     forControlEvents: UIControlEventTouchDown ];
        comboTarget    = targ ;
        comboName      = m ;
        disabled       = false ;
        timerLock      = [ [ NSLock alloc ] init ] ;
        timerRunning   = false;
    }
    return self;
}


- (id) initWithFrame: ( CGRect     ) frame
              target: ( id         ) targ
      normalSelector: ( SEL        ) normalSel
         normalTitle: ( NSString * ) normalTit
   alternateSelector: ( SEL        ) alternateSel
      alternateTitle: ( NSString * ) alternateTit
{
    return nil ;
}


- ( bool ) wasTimerRunning
{
    [ timerLock lock ] ;
    bool result = timerRunning ;
    timerRunning = false ;
    [ timerLock unlock ] ;
    return result ;
}


- ( void ) touchUpInside: ( id ) sender
{
    if ( ! [ self wasTimerRunning ] ) return ;

    [ NSObject cancelPreviousPerformRequestsWithTarget:self
                                              selector: @selector( timerExpired: )
                                                object: nil ] ;
    if ( alternate )
        [ comboTarget comboInverseInvoked: comboName ];
    else
        [ comboTarget comboInvoked: comboName ];
}

- ( void ) timerExpired: ( id ) sender
{
    if ( ! [ self wasTimerRunning ] ) return ;
    [ comboTarget comboSet: comboName ]  ;
}

- ( void ) touchDown:( id ) sender
{
    [ timerLock lock ];
    timerRunning = true;
    [self performSelector: @selector( timerExpired: )
               withObject: nil
               afterDelay: MACROPRESSTIME ];
    [ timerLock unlock ] ;
}

- (void)dealloc {
    [super dealloc];
    [ timerLock release ] ;
}


@end
