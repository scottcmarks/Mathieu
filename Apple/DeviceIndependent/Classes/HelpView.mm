//
//  HelpView.mm
//  SporadicM12
//
//  Created by Scott Marks on 12/15/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#import "HelpView.h"
#import "SporadicMAppDelegate.h"
#import "Constants.h"

@implementation HelpView


@synthesize helpWebView;
@synthesize backButton;

//- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ AppleApplication sharedApplication ] delegate ] ; }

- ( void ) showScreen: (NSString *)resource
{
    NSBundle * m = [NSBundle mainBundle] ;
    NSString *bundlePath = [m bundlePath];
    NSString *resourcePath = [NSBundle pathForResource:resource ofType:@"html" inDirectory:bundlePath];
    NSURL *resourceURL = [NSURL fileURLWithPath:resourcePath];
    NSURLRequest *resourceRequest = [NSURLRequest requestWithURL:resourceURL];
    [self.helpWebView loadRequest:resourceRequest];
}

- ( void ) showInitialHelpScreen
{
    [self showScreen:@"index"];
}

- ( void ) showErrorScreen: (NSError *)error
{
    [self showScreen:@"error"];
}

- (void) awakeFromNib {
    [super awakeFromNib];
    [ self showInitialHelpScreen ] ;
}

- (void) loadView {
    [super awakeFromNib];
    [ self showInitialHelpScreen ] ;
}


-(void) reportError: (NSError *)error
{
	// report the error
    [ self showErrorScreen: error ];
}

-(void) updateBackButton
{
    backButton.enabled = self.helpWebView.canGoBack;
    if (@available(iOS 16.0, *)) {
        backButton.hidden = !self.helpWebView.canGoBack;
    }
}

-(IBAction) goBack:(id)sender
{
    [self.helpWebView goBack];
}

- (void) dealloc
{
    self.backButton = nil ;
    self.helpWebView = nil ;
    [super dealloc];
}
@end
