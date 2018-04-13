//
//  SwapPermutationsViewController.h
//  SporadicM12
//
//  Created by Jackie Marks on 01/01/09.
//  Copyright 2009 Magnolia Heights Research and Development.  All rights reserved.
//

#include "Apple Cross-platform.h"

@class RootViewController;
@class PreferencesViewController;
@class SwapPermutationsView;


@interface SwapPermutationsViewController : UIViewController
#if TARGET_IOS
//                                                           <UIWebViewDelegate>
#endif
{
    RootViewController        * rootViewController        ;
    PreferencesViewController * preferencesViewController ;
    SwapPermutationsView      * swapPermutationsView      ;
}

@property ( nonatomic, assign   )          RootViewController        * rootViewController        ;
@property ( nonatomic, assign   )          PreferencesViewController * preferencesViewController ;
@property ( nonatomic, retain   ) IBOutlet SwapPermutationsView      * swapPermutationsView      ;

- ( IBAction ) dismissSwapPermutations ;
- ( IBAction ) showHelp ;

@end
