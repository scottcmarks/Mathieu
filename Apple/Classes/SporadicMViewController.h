//
//  SporadicMViewController.h
//  SporadicM
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameModel.h"
#import "SporadicMView.h"
#import "ComboButtonTargetProtocol.h"
#import "BallRingViewDelegate.h"

@class RootViewController;

@interface SporadicMViewController : UIViewController < UITextFieldDelegate, 
                                                        UIAlertViewDelegate,
                                                        ComboButtonTarget,
                                                        BallRingViewDelegate > 
{
    RootViewController * rootViewController ;
    bool                 haveNotedSuccess   ;
    int                  _newSwapIndex      ;
}

@property ( nonatomic, assign   ) RootViewController * rootViewController;

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
