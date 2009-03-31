//
//  BallView.h
//  SporadicM12
//
//  Created by Jackie Marks on 10/21/08.
//  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "mathieu.h"

@interface BallView : UIView 
{
    int _ballNumber;
}

+ ( void ) setColorsForSwapPermutation: ( const MPermutation & ) swap;

+ ( BallView * ) ballViewWithFrame: ( CGRect ) frame ballNumber:( int ) ballNumber;

- (id)initWithFrame:(CGRect)frame ballNumber: ( int ) ballNumber;


@end
