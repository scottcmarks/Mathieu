//
//  AltButton.m
//  Mathieu
//
//  Created by Scott Marks on 04/20/2018.
//

#import "AltButton.h"

@implementation AltButton
-( void ) setAlternate: ( BOOL ) alt {
    [super setAlternate:alt];
    self.highlighted = alt;
}
@end
