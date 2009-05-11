//
//  OKCancelAlertView.h
//  SporadicM12
//
//  Created by Jackie Marks on 1/19/09.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"


@interface OKCancelAlertView : NSObject
{
    id          target         ;
    SEL         cancelSelector ;
    SEL         OKSelector     ;
    AlertView * alert          ; 
    bool        hasParameter   ;
    id          parameter      ;
}

+ ( id ) alertWithTitle: ( NSString * ) title 
                message: ( NSString * ) message 
                 target: ( id ) target
         cancelSelector: ( SEL ) cancelSel
             OKSelector: ( SEL ) OKSel ;

+ ( id ) alertWithTitle: ( NSString * ) title 
                message: ( NSString * ) message 
                 target: ( id ) target
         cancelSelector: ( SEL ) cancelSel
             OKSelector: ( SEL ) OKSel 
              parameter: ( id ) parameter;

- ( void ) show ;
@end
