//
//  SwapPermutations.h
//  Mathieu
//
//  Created by Scott Marks on 3/30/09.
//  Copyright © 2009, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#include "Apple Cross-platform.h"

@class BallRingView;
#if TARGET_IOS
@interface SwapPermutationsView : UIView   <UIPickerViewDelegate , UIPickerViewDataSource>
#elif TARGET_MACOS
@interface SwapPermutationsView : NSView
else
#error Don't know this platform!
#endif
{
    UILabel          * currentPermutation        ;
    BallRingView     * currentPermutationPreview ;
    int                pickedSwapIndex           ;
#if TARGET_IOS
    UIPickerView     * swapPermutationPicker     ;
	UINavigationItem * navigationBar             ;
#endif
}

@property( nonatomic, readonly )          int               pickedSwapIndex                ;
#if TARGET_IOS
@property( nonatomic, assign   ) IBOutlet UILabel          * currentPermutation            ;
@property( nonatomic, assign   ) IBOutlet BallRingView     * currentPermutationPreview     ;
@property( nonatomic, assign   ) IBOutlet UIPickerView     * swapPermutationPicker         ;
@property( nonatomic, assign   ) IBOutlet UINavigationItem * navigationBar                 ;
#endif

- ( void ) synchronize;

@end
