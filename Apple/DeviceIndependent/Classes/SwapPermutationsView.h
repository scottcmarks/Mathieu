//
//  SwapPermutations.h
//  Mathieu
//
//  Created by Scott Marks on 3/30/09.
//  Copyright 2009 Magnolia Heights R & D. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BallRingView;

@interface SwapPermutationsView : UIView <UIPickerViewDelegate , UIPickerViewDataSource>
{
    UIPickerView * swapPermutationPicker;
	UINavigationItem * navigationBar;
    UILabel * currentPermutation;
    BallRingView * currentPermutationPreview;
    int pickedSwapIndex;
}

@property( nonatomic, retain ) IBOutlet UIPickerView * swapPermutationPicker;
@property( nonatomic, retain ) IBOutlet UINavigationItem * navigationBar;
@property( nonatomic, retain ) IBOutlet UILabel * currentPermutation;
@property( nonatomic, retain ) IBOutlet UIView * currentPermutationPreview;
@property( nonatomic, readonly ) int pickedSwapIndex;

- ( void ) synchronize;

@end
