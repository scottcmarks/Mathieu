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


#if TARGET_OS_IPHONE
@interface HelpViewController : UIViewController <UIWebViewDelegate>
#elif TARGET_OS_MAC
@interface HelpViewController : NSViewController
#else
#error Don't know this platform!
#endif
{
    RootViewController *rootViewController;
    HelpView* helpView;
}

@property ( nonatomic, assign   ) RootViewController *rootViewController;
@property ( nonatomic, retain   ) IBOutlet HelpView *helpView;

- (IBAction)dismissHelp:(id)sender;

@end
