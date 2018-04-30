//
//  SwapPermutationsViewController.h
//  SporadicM12
//
//  Created by Scott Marks on 01/01/09.
//  Copyright © 2009, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"

@class PreferencesViewController;
@class SwapPermutationsView;


@interface SwapPermutationsViewController : UIViewController
#if TARGET_IOS
//                                                           <UIWebViewDelegate>
#endif
{
    PreferencesViewController * preferencesViewController ;
    SwapPermutationsView      * swapPermutationsView      ;
}

@property ( nonatomic, assign   )          PreferencesViewController * preferencesViewController ;
@property ( nonatomic, retain   ) IBOutlet SwapPermutationsView      * swapPermutationsView      ;

- ( IBAction ) showHelp ;

@end
