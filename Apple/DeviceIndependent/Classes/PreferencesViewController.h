//
//  PreferencesViewController.h
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"

@class PreferencesView;
@class HelpViewController;
@class SwapPermutationsViewController;

@interface PreferencesViewController : UIViewController
{
    HelpViewController * helpViewController ;
    SwapPermutationsViewController * swapPermutationsViewController ;
    PreferencesView    * preferencesView    ;
    UILabel            * versionStringLabel ;
}

@property ( nonatomic, retain   ) HelpViewController * helpViewController ;
@property ( nonatomic, retain   ) SwapPermutationsViewController * swapPermutationsViewController ;
@property ( nonatomic, retain   ) IBOutlet  PreferencesView    * preferencesView    ;
@property ( nonatomic, assign   ) IBOutlet  UILabel            * versionStringLabel ;

- ( IBAction ) toggleView                 ;
- ( IBAction ) showHelp                   ;
- ( IBAction ) showSwapPermutations       ;
- ( IBAction ) animationSpeedChanged      ;
- ( IBAction ) soundEffectsSwitchChanged  ;
- ( IBAction ) confirmSwitchChanged       ;

@end
