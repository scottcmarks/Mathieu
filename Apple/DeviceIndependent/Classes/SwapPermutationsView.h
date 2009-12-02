//
//  SwapPermutations.h
//  Mathieu
//
//  Created by Scott Marks on 3/30/09.
//  Copyright 2009 Magnolia Heights R & D. All rights reserved.
//

#import "Kit.h"

@class BallRingView;
#if TARGET_OS_IPHONE
@interface SwapPermutationsView : UIView   <UIPickerViewDelegate , UIPickerViewDataSource> 
#elif TARGET_OS_MAC
@interface SwapPermutationsView : NSView 
else
#error Don't know this platform!
#endif
{
    UILabel          * currentPermutation        ;
    BallRingView     * currentPermutationPreview ;
    int                pickedSwapIndex           ;
#if TARGET_OS_IPHONE
    UIPickerView     * swapPermutationPicker     ;
	UINavigationItem * navigationBar             ;
#endif
}

@property( nonatomic, readonly )          int               pickedSwapIndex                ;
#if TARGET_OS_IPHONE
@property( nonatomic, assign   ) IBOutlet UILabel         * currentPermutation             ;
@property( nonatomic, assign   ) IBOutlet UIPickerView     * swapPermutationPicker         ;
@property( nonatomic, assign   ) IBOutlet UINavigationItem * navigationBar                 ;
#endif

- ( void ) synchronize;

@end
