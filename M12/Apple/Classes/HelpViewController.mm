//
//  HelpViewController.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import "HelpViewController.h"
#import "SporadicM12AppDelegate.h"

@implementation HelpViewController
@synthesize rootViewController;
@synthesize helpView;

- ( SporadicM12AppDelegate * ) appDelegate{ return ( SporadicM12AppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // this will appear as the title in the navigation bar
        self.title = NSLocalizedString(@"SporadicM12", @"");
    }
    return self;
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

//  - (void)didReceiveMemoryWarning {
//      [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
//      // Release anything that's not essential, such as cached data shadow?
//  }


- (void)dealloc {
    self.rootViewController = nil;
    self.helpView = nil;
    [super dealloc];
}

- (IBAction)dismissHelp:(id)sender {
    [ self.rootViewController toggleView:sender];
}

#pragma mark UIWebView delegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[UIApplication sharedApplication].isNetworkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].isNetworkActivityIndicatorVisible = NO;
    [ helpView updateBackButton ];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// load error, hide the activity indicator in the status bar
	[UIApplication sharedApplication].isNetworkActivityIndicatorVisible = NO;
    // let the helpView report the error;
    [ helpView reportError: error ];
}

@end
