//
//  HelpViewController.mm
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
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
        self.helpView.helpWebView.UIDelegate = self;
    }
    return self;
}

- (IBAction)unwindToSourceViewController:(UIStoryboardSegue*)sender
{
    // UIViewController *sourceViewController = sender.sourceViewController;
    return;
}

#pragma mark AppleWebViewNavigationDelegate methods
- (void)webView:(AppleWebView *)webView didStartProvisionalNavigation:(AppleWebViewNavigation *)navigation
{
#if TARGET_IOS
	// starting the load, show the activity indicator in the status bar
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	[AppleApplication sharedApplication].networkActivityIndicatorVisible = YES;
#pragma clang diagnostic pop
#endif
}

- (void)webView:(AppleWebView *)webView didFinishNavigation:(AppleWebViewNavigation *)navigation {
#if TARGET_IOS
	// finished loading, hide the activity indicator in the status bar
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	[AppleApplication sharedApplication].networkActivityIndicatorVisible = NO;
#pragma clang diagnostic pop
#endif
    [ helpView updateBackButton ];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(AppleWebViewNavigation *)navigation
      withError:(NSError *)error
{
#if TARGET_IOS
	// load error, hide the activity indicator in the status bar
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	[AppleApplication sharedApplication].networkActivityIndicatorVisible = NO;
#pragma clang diagnostic pop
#endif
    // let the helpView report the error;
    [ helpView reportError: error ];
}



- (void)dealloc {
    self.helpView = nil;
    [super dealloc];
}

@end
