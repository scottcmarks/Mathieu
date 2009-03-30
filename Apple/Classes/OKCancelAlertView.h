//
//  OKCancelAlertView.h
//  SporadicM12
//
//  Created by Jackie Marks on 1/19/09.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OKCancelAlertView : NSObject
{
    id            target         ;
    SEL           cancelSelector ;
    SEL           OKSelector     ;
    UIAlertView * alert          ; 
    bool          hasParameter   ;
    id            parameter      ;
}

@property ( nonatomic, retain ) id parameter;

+ ( void )OKCancelAlertWithTitle: ( NSString * ) title 
                         message: ( NSString * ) message 
                          target: ( id ) target
                  cancelSelector: ( SEL ) cancelSel
                      OKSelector: ( SEL ) OKSel ;

+ ( void )OKCancelAlertWithTitle: ( NSString * ) title 
                         message: ( NSString * ) message 
                          target: ( id ) target
                  cancelSelector: ( SEL ) cancelSel
                      OKSelector: ( SEL ) OKSel 
                       parameter: ( id ) parameter;

@end
