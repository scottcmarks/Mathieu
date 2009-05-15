//
//  HelpViewController.mm
//  SporadicM12
//
//  Created by Jackie Marks on 12/15/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "mathieu.h"
#import "HelpViewController.h"
#import "SporadicMAppDelegate.h"

@implementation HelpViewController
@synthesize rootViewController;
@synthesize helpView;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // this will appear as the title in the navigation bar
        self.title = NSLocalizedString(fullAppName, @"");
    }
    return self;
}


#if TARGET_OS_IPHONE

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

//  - (void)didReceiveMemoryWarning {
//      [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
//      // Release anything that's not essential, such as cached data shadow?
//  }

#endif


- (void)dealloc {
    self.rootViewController = nil;
    self.helpView = nil;
    [super dealloc];
}

- (IBAction)dismissHelp:(id)sender 
{
    [ self.rootViewController toggleView ];
}

#pragma mark WebView delegate methods

- (void)webViewDidStartLoad:(WebView *)webView
{
#if TARGET_OS_IPHONE
	// starting the load, show the activity indicator in the status bar
	[Application sharedApplication].isNetworkActivityIndicatorVisible = YES;
#endif
}

- (void)webViewDidFinishLoad:(WebView *)webView
{
#if TARGET_OS_IPHONE
	// finished loading, hide the activity indicator in the status bar
	[Application sharedApplication].isNetworkActivityIndicatorVisible = NO;
#endif
    [ helpView updateBackButton ];
}

- (void)webView:(WebView *)webView didFailLoadWithError:(NSError *)error
{
#if TARGET_OS_IPHONE
	// load error, hide the activity indicator in the status bar
	[Application sharedApplication].isNetworkActivityIndicatorVisible = NO;
#endif
    // let the helpView report the error;
    [ helpView reportError: error ];
}

@end
