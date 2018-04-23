//
//  ComboBarButtonItem.m
//  Mathieu
//
//  Created by Scott Marks on 04/20/2018.
//

#import "ComboBarButtonItem.h"

@implementation ComboBarButtonItem
- ( void ) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ComboBarButtonItem: touchesBegan: touches=%@ event=%@", touches, event) ;
}

- ( void ) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ComboBarButtonItem: touchesEnded: touches=%@ event=%@", touches, event) ;
}

@end
