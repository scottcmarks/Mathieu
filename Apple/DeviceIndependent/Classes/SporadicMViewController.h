//
//  SporadicMViewController.h
//  SporadicM
//
//  Created by Scott Marks on 10/14/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"
#import "GameModel.h"
#import "SporadicMView.h"
#import "ComboButtonTargetProtocol.h"
#import "BallRingViewDelegate.h"

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
    bool                 haveNotedSuccess   ;
}

// Handlers for events from the SporadicMView
- ( IBAction ) toggleInverted ;
- ( IBAction ) right          ;
- ( IBAction ) left           ;
- ( IBAction ) swap           ;
- ( IBAction ) home           ;
- ( IBAction ) shake          ;
- ( IBAction ) restart        ;
- ( IBAction ) shakeOrRestart ;
- ( IBAction ) undoMove       ;
- ( IBAction ) undoStep       ;
- ( IBAction ) undoStepOrMove ;
- ( void     ) spinInProgress : ( int ) wedges       ;
- ( void     ) spinFinished   : ( int ) wedges       ;
- ( void     ) setSwapIndex   : ( int ) newSwapIndex ;
- ( void     ) initializeView ;
- ( void     ) synchronize;

@end
