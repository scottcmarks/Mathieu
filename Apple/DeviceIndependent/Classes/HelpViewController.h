//
//  HelpViewController.h
//  SporadicM12
//
//  Created by Jackie Marks on 01/01/09.
//  Copyright 2009 Magnolia Heights Research and Development.  All rights reserved.
//

#include "Apple Cross-platform.h"

#import "RootViewController.h"
#import "HelpView.h"


#if TARGET_IOS
@interface HelpViewController : UIViewController <UIWebViewDelegate>
#elif TARGET_MACOS
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

- ( IBAction ) dismissHelp ;

@end
