//
//  HelpViewController.h
//  SporadicM12
//
//  Created by Jackie Marks on 01/01/09.
//  Copyright 2009 Magnolia Heights Research and Development.  All rights reserved.
//

#import "Kit.h"

#import "RootViewController.h"
#import "HelpView.h"


@interface HelpViewController : ViewController
#if TARGET_OS_IPHONE
                                                <UIWebViewDelegate>
#endif
{
    RootViewController *rootViewController;
    IBOutlet HelpView* helpView;
}

@property ( nonatomic, assign   ) RootViewController *rootViewController;
@property ( nonatomic, retain   ) HelpView *helpView;

- (IBAction)dismissHelp:(id)sender;

@end
