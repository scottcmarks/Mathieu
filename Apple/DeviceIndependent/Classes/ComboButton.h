//
//  ComboButton.h
//  SporadicM12
//
//  Created by Scott Marks on 1/7/09.
//  Copyright © 2009, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"
#import "DualActionButton.h"
#import "CanDisableButtonProtocol.h"
#import "ComboButtonTargetProtocol.h"

@interface ComboButton : DualActionButton < DualActionButtonProtocol, CanDisableButtonProtocol >
{
@protected
    // Instance variables for the CanDisableButtonProtocol addition
    HistoryElement comboName             ;
    id< ComboButtonTarget >  comboTarget ;
    BOOL           disabled              ;
    bool           timerRunning          ;
    NSLock *       timerLock             ;
}

// Convenience method -- return button has been autoreleased
+ ( id ) comboButtonWithFrame: ( CGRect                  ) frame
                       target: ( id< ComboButtonTarget > ) target
                    comboName: ( HistoryElement          ) comboName ;

// Initializer used by above convenience method
- (id) initWithFrame: ( CGRect                  ) frame
              target: ( id< ComboButtonTarget > ) target
           comboName: ( HistoryElement          ) comboName ;

@property ( readonly ) HistoryElement comboName;

@end
