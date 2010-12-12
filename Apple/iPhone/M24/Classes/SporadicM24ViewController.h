//
//  SporadicM24ViewController.h
//  SporadicM24
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameModel.h"
#import "SporadicM24View.h"
#import "ComboButtonTargetProtocol.h"

@class RootViewController;

@interface SporadicM24ViewController : UIViewController < UITextFieldDelegate,
                                                          UIAlertViewDelegate,
                                                          ComboButtonTarget >
{
    RootViewController * rootViewController ;
    bool                 haveNotedSuccess   ;
}

@property ( nonatomic, assign   ) RootViewController * rootViewController;

// Handlers for events from the SporadicM24View
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


@end
