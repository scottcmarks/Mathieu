//
//  SporadicMAppDelegate.h
//  Mathieu
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright Magnolia Heights Research and Development. 2008. All rights reserved.
//

#import "Kit.h"

@class RootViewController;
@class GameModel;

@interface SporadicMAppDelegate : NSObject 
#if TARGET_OS_IPHONE
                                           <UIApplicationDelegate>
#endif /* TARGET_OS_IPHONE */
{
    UIWindow *window;
	RootViewController *rootViewController;
    CGFloat animationSpeed;
    bool soundEffects;
    bool confirm;
    bool invert;
    GameModel * gameModel;
    
}

// You'd think that the Interface builder would expand preprocessor constants, but apparently not
#if TARGET_OS_IPHONE
@property (nonatomic, retain ) IBOutlet UIWindow *window;
#elif TARGET_OS_MAC
@property (nonatomic, retain )          NSWindow *window;
#else
#error Don't know this platform!
#endif
@property (nonatomic, retain ) RootViewController *rootViewController;
@property (nonatomic         ) CGFloat animationSpeed;
@property (nonatomic         ) bool soundEffects;
@property (nonatomic         ) bool confirm;
@property (nonatomic         ) bool invert;
@property (nonatomic, retain ) GameModel * gameModel;

@end

