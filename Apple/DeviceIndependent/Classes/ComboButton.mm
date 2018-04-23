//
//  ComboButton.m
//  SporadicM12
//
//  Created by Scott Marks on 1/7/09.
//  Copyright © 2009, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "Constants.h"
#import "Utilities.h"
#import "view.h"
#import "ComboButton.h"

// Class variables
@interface ComboButton( PrivateLocking )
- ( bool ) isTimerRunning;
@end

@implementation ComboButton

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
        [ self setBackgroundImage: normalImage  forState: UIControlStateNormal ] ;
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

- (void) awakeFromNib {
    [super awakeFromNib];
    timerLock = [ NSLock new];
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
    [ timerLock release ] ;
    timerLock = nil ;
    [super dealloc];
}


@end
