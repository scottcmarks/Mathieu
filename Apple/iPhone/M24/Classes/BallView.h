//
//  BallView.h
//  SporadicM24
//
//  Created by Jackie Marks on 10/21/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BallView : UIView {
	float R;
	float G;
	float B;
}

@property float R;
@property float G;
@property float B;

- (id)initWithFrame:(CGRect)frame ballNumber: (int)i;


@end
