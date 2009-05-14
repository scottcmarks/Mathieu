//
//  SwapPermutations.h
//  Mathieu
//
//  Created by Scott Marks on 3/30/09.
//  Copyright 2009 Magnolia Heights R & D. All rights reserved.
//

#import "Kit.h"

@class BallRingView;

@interface SwapPermutationsView : View 
#if TARGET_OS_IPHONE
                                       <UIPickerViewDelegate , UIPickerViewDataSource>
#endif
{
    Label * currentPermutation;
    BallRingView * currentPermutationPreview;
    int pickedSwapIndex;
#if TARGET_OS_IPHONE
    UIPickerView * swapPermutationPicker;
	UINavigationItem * navigationBar;
#endif
}

@property( nonatomic, retain ) IBOutlet Label * currentPermutation;
@property( nonatomic, retain ) IBOutlet View * currentPermutationPreview;
@property( nonatomic, readonly ) int pickedSwapIndex;
#if TARGET_OS_IPHONE
@property( nonatomic, retain ) IBOutlet UIPickerView * swapPermutationPicker;
@property( nonatomic, retain ) IBOutlet UINavigationItem * navigationBar;
#endif

- ( void ) synchronize;

@end
