//
//  SporadicM24AppDelegate.h
//  SporadicM24
//
//  Created by Jackie Marks on 10/14/08.
//  Copyright Magnolia Heights Research and Development. 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
@class GameModel;

@interface SporadicM24AppDelegate : NSObject <UIApplicationDelegate> {
    IBOutlet UIWindow *window;
	RootViewController *rootViewController;
    CGFloat animationSpeed;
    bool soundEffects;
    bool confirm;
    bool invert;
    bool useSpinMessages;
    GameModel * gameModel;

}

@property (nonatomic, retain ) IBOutlet UIWindow *window;
@property (nonatomic, retain ) RootViewController *rootViewController;
@property (nonatomic         ) CGFloat animationSpeed;
@property (nonatomic         ) bool soundEffects;
@property (nonatomic         ) bool confirm;
@property (nonatomic         ) bool invert;
@property (nonatomic         ) bool useSpinMessages;
@property (nonatomic, retain ) GameModel * gameModel;

@end

