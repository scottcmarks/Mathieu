//
//  BallRingViewDelegate.h
//  Mathieu
//
//  Created by Scott Marks on 3/31/09.
//  Copyright © 2009, 2018 Magnolia Heights Research and Development. All rights reserved.
//
@protocol BallRingViewDelegate
-( void ) spinInProgress: ( int ) wedges;
-( void ) spinFinished: ( int ) wedges;
-( void ) swapped;
@end
