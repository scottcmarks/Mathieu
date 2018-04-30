//
//  HelpViewController.mm
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "mathieu.h"
#import "HelpViewController.h"
#import "SporadicMAppDelegate.h"

@implementation HelpViewController
@synthesize helpView;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ AppleApplication sharedApplication ] delegate ] ; }


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // this will appear as the title in the navigation bar
        self.title = NSLocalizedString(fullAppName, @"");
    }
    return self;
}

- (IBAction)unwindToSourceViewController:(UIStoryboardSegue*)sender
{
    // UIViewController *sourceViewController = sender.sourceViewController;
    return;
}

#pragma mark AppleWebView delegate methods

- (void)webViewDidStartLoad:(AppleWebView *)webView
{
#if TARGET_IOS
	// starting the load, show the activity indicator in the status bar
	[AppleApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
}

- (void)webViewDidFinishLoad:(AppleWebView *)webView
{
#if TARGET_IOS
	// finished loading, hide the activity indicator in the status bar
	[AppleApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    [ helpView updateBackButton ];
}

- (void)webView:(AppleWebView *)webView didFailLoadWithError:(NSError *)error
{
#if TARGET_IOS
	// load error, hide the activity indicator in the status bar
	[AppleApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    // let the helpView report the error;
    [ helpView reportError: error ];
}


- (void)dealloc {
    self.helpView = nil;
    [super dealloc];
}

@end
