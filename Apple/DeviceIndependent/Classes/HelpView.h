//
//  HelpView.h
//  SporadicM12
//
//  Created by Jackie Marks on 01/01/08.
//  Copyright 2009 Magnolia Heights Research and Development.  All rights reserved.
//

#import "Kit.h"


@interface HelpView : View 
{
    IBOutlet WebView* helpWebView;
    IBOutlet ToolbarButtonItem* backButton;
    NSURL * baseURL;
}

@property ( nonatomic, assign   ) ToolbarButtonItem *backButton;

-(void) reportError: (NSError *)error;
-(void) updateBackButton;

@end
