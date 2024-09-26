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
    [self.helpWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:resourcePath]]];
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
    self.backButton.enabled = self.helpWebView.canGoBack;
}

- (IBAction) receiveBackButton
{
    [ self.helpWebView goBack];
}

- (void) dealloc
{
    self.backButton = nil ;
    self.helpWebView = nil ;
    [super dealloc];
}
@end

