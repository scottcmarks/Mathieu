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
        alert = 
#if TARGET_OS_IPHONE
                [ [ UIAlertView alloc ] initWithTitle: title 
                                              message: message 
                                             delegate: self
                                    cancelButtonTitle: @"Cancel" 
                                    otherButtonTitles: @"OK", nil ] ;
#elif TARGET_OS_MAC
                [ NSAlert alertWithMessageText: title
                                 defaultButton: @"Cancel"
                               alternateButton: nil
                                   otherButton: @"OK" 
                     informativeTextWithFormat: message ] ;
#else
#error Don't know this platform!
#endif
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
        alert = 
#if TARGET_OS_IPHONE
        [ [ UIAlertView alloc ] initWithTitle: title 
                                      message: message 
                                     delegate: self
                            cancelButtonTitle: @"Cancel" 
                            otherButtonTitles: @"OK", nil ] ;
#elif TARGET_OS_MAC
        [ NSAlert alertWithMessageText: title
                         defaultButton: @"Cancel"
                       alternateButton: @"OK" 
                           otherButton: nil
             informativeTextWithFormat: message ] ;
#else
#error Don't know this platform!
#endif
        if ( ! alert ) return nil;
        target         = targ      ; 
        cancelSelector = cancelSel ;
        OKSelector     = OKSel     ;
        hasParameter   = true      ;
        parameter      = param     ;
    }
    return self;
}

- ( void ) alertView: ( AlertView * ) alertView clickedButtonAtIndex: ( NSInteger ) buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    SEL sel = buttonIndex ==
#if TARGET_OS_IPHONE
                              alertView.cancelButtonIndex 
#elif TARGET_OS_MAC
                              NSAlertDefaultReturn   // This might be the wrong one of the two choices here
#else
    #error Don't know this platform!
#endif
                                                          ? cancelSelector : OKSelector ;
    if ( sel ) 
    {
        if ( hasParameter )
            [ target performSelector: sel withObject: parameter ] ;
        else
            [ target performSelector: sel                       ] ;
    }
}



- ( void ) show 
{ 
#if TARGET_OS_IPHONE
    [ alert show ] ;
#elif TARGET_OS_MAC
    [ self alertView: alert clickedButtonAtIndex: [ alert runModal ] ];
#else
    #error Don't know this platform!
#endif
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
