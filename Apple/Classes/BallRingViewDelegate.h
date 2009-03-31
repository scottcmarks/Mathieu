//
//  BallRingViewDelegate.h
//  Mathieu
//
//  Created by scott on 3/31/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
@protocol BallRingViewDelegate
-( void ) spinInProgress: ( int ) wedges;
-( void ) spinFinished: ( int ) wedges;
-( void ) swapped;
@end
