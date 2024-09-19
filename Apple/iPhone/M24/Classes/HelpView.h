//
//  HelpView.h
//  SporadicM24
//
//  Created by Jackie Marks on 01/01/08.
//  Copyright 2009 Magnolia Heights Research and Development.  All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HelpView : UIView {
    IBOutlet WKWebView* helpWebView;
    IBOutlet UIBarButtonItem* backButton;
    NSURL * baseURL;
}

//@property ( nonatomic, retain   ) WKWebView *helpWebView;
@property ( nonatomic, assign   ) UIBarButtonItem *backButton;

-(void) reportError: (NSError *)error;
-(void) updateBackButton;

@end
