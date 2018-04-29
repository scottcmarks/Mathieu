//
//  HelpView.h
//  SporadicM12
//
//  Created by Scott Marks on 01/01/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "Apple Cross-platform.h"


@interface HelpView : UIView
{
    IBOutlet UIWebView* helpWebView;
    IBOutlet UIBarButtonItem* backButton;
    NSURL * baseURL;
}

@property ( nonatomic, assign   ) UIBarButtonItem *backButton;

-(void) reportError: (NSError *)error;
-(void) updateBackButton;

@end
