//
//  HelpView.h
//  SporadicM12
//
//  Created by Scott Marks on 01/01/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#import "Apple Cross-platform.h"

@interface HelpView : UIView
@property ( nonatomic, retain   ) IBOutlet AppleWebView* helpWebView;
@property ( nonatomic, retain   ) IBOutlet UIBarButtonItem* backButton;

-(void) reportError: (NSError *)error;
-(void) updateBackButton;
-(IBAction) goBack:(id)sender;

@end
