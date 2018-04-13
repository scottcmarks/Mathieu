//
//  SporadicMViewController.h
//  SporadicM
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"
#import "GameModel.h"
#import "SporadicMView.h"
#import "ComboButtonTargetProtocol.h"
#import "BallRingViewDelegate.h"

@class RootViewController ;

#if TARGET_IOS
@interface SporadicMViewController : UIViewController
                                                    < UITextFieldDelegate,
                                                      UIAlertViewDelegate,
                                                      ComboButtonTarget,
                                                      BallRingViewDelegate >
#elif TARGET_MACOS
@interface SporadicMViewController : NSViewController
                                                    < ComboButtonTarget,
                                                      BallRingViewDelegate >
#else
#error Don't know this platform!
#endif

{
    RootViewController * rootViewController ;
    bool                 haveNotedSuccess   ;
}

@property ( nonatomic, assign   ) RootViewController * rootViewController ;

// Handlers for events from the SporadicMView
- ( IBAction ) toggleView     ;
- ( IBAction ) toggleInverted ;
- ( IBAction ) right          ;
- ( IBAction ) left           ;
- ( IBAction ) swap           ;
- ( IBAction ) home           ;
- ( IBAction ) shake          ;
- ( IBAction ) restart        ;
- ( IBAction ) undoMove       ;
- ( IBAction ) undoStep       ;
- ( void     ) spinInProgress : ( int ) wedges       ;
- ( void     ) spinFinished   : ( int ) wedges       ;
- ( void     ) setSwapIndex   : ( int ) newSwapIndex ;
- ( void     ) synchronizeView ;

@end
