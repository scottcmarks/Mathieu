//
//  SwapPermutationsViewController.h
//  SporadicM12
//
//  Created by Jackie Marks on 01/01/09.
//  Copyright 2009 Magnolia Heights Research and Development.  All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
@class PreferencesViewController;
@class SwapPermutationsView;


@interface SwapPermutationsViewController : UIViewController <UIWebViewDelegate>
{
    RootViewController *rootViewController;
    PreferencesViewController *preferencesViewController;
    IBOutlet SwapPermutationsView* swapPermutationsView;
}

@property ( nonatomic, assign   ) RootViewController *rootViewController;
@property ( nonatomic, assign   ) PreferencesViewController *preferencesViewController;
@property ( nonatomic, retain   ) SwapPermutationsView *swapPermutationsView;

- (IBAction)dismissSwapPermutations:(id)sender;
- (IBAction)showHelp:(id)sender;

@end
