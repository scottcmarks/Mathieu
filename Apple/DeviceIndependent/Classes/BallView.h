//
//  BallView.h
//  SporadicM12
//
//  Created by Scott Marks on 10/21/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#import "Apple Cross-platform.h"
#import "mathieu.h"

@interface BallView : AppleView
{
    int _ballNumber;
}

+ ( void ) setColorsForSwapPermutation: ( const MathieuPermutation & ) swap;

+ ( void ) setColorsForCurrentSwapPermutation;

+ ( BallView * ) ballViewWithFrame: ( CGRect ) frame ballNumber:( int ) ballNumber;

- (id)initWithFrame:(CGRect)frame ballNumber: ( int ) ballNumber;


@end
