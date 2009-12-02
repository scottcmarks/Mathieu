//
//  PreferencesViewController.h
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"

@class RootViewController;
@class PreferencesView;
@class HelpViewController;
@class SwapPermutationsViewController;

@interface PreferencesViewController : UIViewController 
{
    RootViewController * rootViewController ;
    HelpViewController * helpViewController ;
    SwapPermutationsViewController * swapPermutationsViewController ;
    PreferencesView    * preferencesView    ;
}

@property ( nonatomic, assign   ) RootViewController * rootViewController ;
@property ( nonatomic, retain   ) HelpViewController * helpViewController ;
@property ( nonatomic, retain   ) SwapPermutationsViewController * swapPermutationsViewController ;
@property ( nonatomic, retain   ) IBOutlet  PreferencesView    * preferencesView    ;

- (IBAction)toggleView:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)showSwapPermutations:(id)sender;
- (IBAction)animationSpeedChanged:(id)sender;
- (IBAction)soundEffectsSwitchChanged:(id)sender;
- (IBAction)confirmSwitchChanged:(id)sender;

@end
