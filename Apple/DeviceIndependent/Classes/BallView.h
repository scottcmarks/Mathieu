//
//  BallView.h
//  SporadicM12
//
//  Created by Scott Marks on 10/21/08.
//  Copyright © 2008, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "Kit.h"
#import "mathieu.h"

@interface BallView : View
{
    int _ballNumber;
}

+ ( void ) setColorsForSwapPermutation: ( const MathieuPermutation & ) swap;

+ ( void ) setColorsForCurrentSwapPermutation;

+ ( BallView * ) ballViewWithFrame: ( CGRect ) frame ballNumber:( int ) ballNumber;

- (id)initWithFrame:(CGRect)frame ballNumber: ( int ) ballNumber;


@end
