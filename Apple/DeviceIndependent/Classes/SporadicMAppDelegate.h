//
//  SporadicMAppDelegate.h
//  Mathieu
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright Magnolia Heights Research and Development. 2008. All rights reserved.
//

#include "Apple Cross-platform.h"

@class GameModel;

@interface SporadicMAppDelegate : NSObject
#if TARGET_IOS
                                           <UIApplicationDelegate>
#endif /* TARGET_IOS */
{
    UIWindow *window;
    CGFloat animationSpeed;
    bool soundEffects;
    bool confirm;
    bool invert;
    GameModel * gameModel;

}

// You'd think that the Interface builder would expand preprocessor constants, but apparently not
#if TARGET_IOS
@property (nonatomic, retain ) IBOutlet UIWindow *window;
#elif TARGET_MACOS
@property (nonatomic, retain )          NSWindow *window;
#else
#error Don't know this platform!
#endif
@property (nonatomic         ) CGFloat animationSpeed;
@property (nonatomic         ) bool soundEffects;
@property (nonatomic         ) bool confirm;
@property (nonatomic         ) bool invert;
@property (nonatomic, retain ) GameModel * gameModel;

@end

