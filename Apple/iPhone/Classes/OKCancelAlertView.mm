//
//  OKCancelAlertView.mm
//  SporadicM12
//
//  Created by Jackie Marks on 1/19/09.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "OKCancelAlertView.h"



@implementation OKCancelAlertView


- (id)initWithFrame:(CGRect)frame 
{
    return nil;
}


- ( id ) initWithTitle: ( NSString * ) title 
               message: ( NSString * ) message 
                target: ( id  ) targ
        cancelSelector: ( SEL ) cancelSel
            OKSelector: ( SEL ) OKSel 
{
    if ( self = [ super init ] )
    {
        alert = [ [ UIAlertView alloc ] initWithTitle: title 
                                              message: message 
                                             delegate: self
                                    cancelButtonTitle: @"Cancel" 
                                    otherButtonTitles: @"OK", nil ] ;
        if ( ! alert ) return nil;
        target         = targ      ; 
        cancelSelector = cancelSel ;
        OKSelector     = OKSel     ;
        hasParameter   = false     ;
        parameter      = nil       ;
    }
    return self;
}


- ( id ) initWithTitle: ( NSString * ) title 
               message: ( NSString * ) message 
                target: ( id  ) targ
        cancelSelector: ( SEL ) cancelSel
            OKSelector: ( SEL ) OKSel 
             parameter: ( id ) param
{
    if ( self = [ super init ] )
    {
        alert = [ [ UIAlertView alloc ] initWithTitle: title 
                                              message: message 
                                             delegate: self
                                    cancelButtonTitle: @"Cancel" 
                                    otherButtonTitles: @"OK", nil ] ;
        if ( ! alert ) return nil;
        target         = targ      ; 
        cancelSelector = cancelSel ;
        OKSelector     = OKSel     ;
        hasParameter   = true      ;
        parameter      = param     ;
    }
    return self;
}

- ( void ) show { [ alert show ] ; }

- ( void ) alertView: ( UIAlertView * ) alertView clickedButtonAtIndex: ( NSInteger ) buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    SEL sel =  buttonIndex == alertView.cancelButtonIndex ? cancelSelector : OKSelector ;
    if ( sel ) 
    {
        if ( hasParameter )
            [ target performSelector: sel withObject: parameter ] ;
        else
            [ target performSelector: sel                       ] ;
    }
}


+ ( id ) alertWithTitle: ( NSString * ) title 
                message: ( NSString * ) message 
                 target: ( id ) target
         cancelSelector: ( SEL ) cancelSel
             OKSelector: ( SEL ) OKSel 
{
    return [ [ OKCancelAlertView alloc ]
                initWithTitle: title 
                      message: message 
                       target: target
               cancelSelector: cancelSel
                   OKSelector: OKSel ] ;
}


+ ( id ) alertWithTitle: ( NSString * ) title 
                message: ( NSString * ) message 
                 target: ( id ) target
         cancelSelector: ( SEL ) cancelSel
             OKSelector: ( SEL ) OKSel 
              parameter: ( id ) parameter
{
   return [ [ OKCancelAlertView alloc ]
               initWithTitle: title 
                     message: message 
                      target: target
              cancelSelector: cancelSel
                  OKSelector: OKSel 
                   parameter: parameter ];
}


- (void)dealloc
{
    [ alert release ] ;
    [super dealloc];
}


@end
