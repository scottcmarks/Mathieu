//
//  HelpViewController.h
//  SporadicM12
//
//  Created by Scott Marks on 01/01/09.
//  Copyright © 2009, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"

#import "HelpView.h"


#if TARGET_IOS
@interface HelpViewController : UIViewController // <UIWebViewDelegate>
#elif TARGET_MACOS
@interface HelpViewController : NSViewController
#else
#error Don't know this platform!
#endif
{
    HelpView* helpView;
}

@property ( nonatomic, retain   ) IBOutlet HelpView *helpView;

@end
