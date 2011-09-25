//
//  SporadicMViewController.h
//  SporadicM
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"
#import "GameModel.h"
#import "SporadicMView.h"
#import "ComboButtonTargetProtocol.h"
#import "BallRingViewDelegate.h"

@class RootViewController ;

#if TARGET_OS_IPHONE
@interface SporadicMViewController : UIViewController
                                                    < UITextFieldDelegate,
                                                      UIAlertViewDelegate,
                                                      ComboButtonTarget,
                                                      BallRingViewDelegate >
#elif TARGET_OS_MAC
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
- (IBAction) toggleView     : (id)sender;
- (IBAction) toggleInverted : (id)sender;
- (IBAction) right          : (id)sender;
- (IBAction) left           : (id)sender;
- (IBAction) swap           : (id)sender;
- (IBAction) home           : (id)sender;
- (IBAction) shake          : (id)sender;
- (IBAction) undoMove       : (id)sender;
- (IBAction) undoStep       : (id)sender;
- (void    ) spinInProgress : (int)wedges;
- (void    ) spinFinished   : (int)wedges;

- ( void ) setSwapIndex: ( int ) newSwapIndex;


@end
