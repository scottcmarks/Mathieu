//
//  BallRingView.h
//  Mathieu
//
//  Created by Scott Marks on 3/31/09.
//  Copyright © 2009, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"

#import "GameModel.h"
#import "BallRingViewDelegate.h"

@class SoundEffect;
@class BallView;

@interface BallRingView : AppleView

+ ( __nonnull instancetype ) ballRingViewWithFrame: ( CGRect ) frame ;
- ( void ) setDelegate: ( id < BallRingViewDelegate > __nonnull ) delegate ;
- ( void ) createSubviews;
- ( void ) moveLabels;
- ( void ) redraw;
#if TARGET_IOS
- ( void ) playRightSound       ;
- ( void ) playLeftSound        ;
- ( void ) playSwapSound        ;
- ( void ) playHomeSound        ;
- ( void ) playShakeSound       ;
- ( void ) playRestartSound     ;
- ( void ) playComboSound       ;
- ( void ) playComboSetSound    ;
- ( void ) playComboNotSetSound ;
- ( void ) playSuccessSound     ;
#elif TARGET_MACOS
#else
#error Don't know this platform!
#endif

@end
