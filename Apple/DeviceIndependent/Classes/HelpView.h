//
//  HelpView.h
//  SporadicM12
//
//  Created by Scott Marks on 01/01/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#import "Apple Cross-platform.h"


@interface HelpView : UIView
{
    IBOutlet UIBarButtonItem* backButton;
    NSURL * baseURL;
}

@property ( nonatomic, assign ) UIBarButtonItem *backButton;
@property ( nonatomic, strong ) IBOutlet AppleWebView* helpWebView;

-(void) reportError: (NSError *)error;
-(void) updateBackButton;
-(IBAction) goBack:(id)sender;
@end
