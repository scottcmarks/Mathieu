//
//  HelpView.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "HelpView.h"
#import "SporadicMAppDelegate.h"
#import "Constants.h"

@implementation HelpView

@synthesize backButton;

//- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }

- ( void ) showInitialHelpScreen
{
    NSURL * indexURL = [NSURL URLWithString: @"index.html" relativeToURL: baseURL];
    [ helpWebView loadRequest:[ NSURLRequest requestWithURL:indexURL ] ];
}

- ( void ) showErrorScreen: ( NSError *)error
{
    NSURL * errorURL = [NSURL URLWithString: @"error.html" relativeToURL: baseURL];
    [ helpWebView loadRequest:[ NSURLRequest requestWithURL:errorURL ] ];
}

- (void) awakeFromNib{
    NSBundle *main = [NSBundle mainBundle];
    NSString *path = [ main bundlePath];
    baseURL = [ [ NSURL fileURLWithPath: path isDirectory:YES ] retain ];
    [ self showInitialHelpScreen ] ;
}

-(void) reportError: (NSError *)error
{
	// report the error
    [ self showErrorScreen: error ];
}

-(void) updateBackButton
{
    backButton.enabled = helpWebView.canGoBack;
}

- (void)dealloc {
    [ baseURL release ];
    [super dealloc];
}


@end

