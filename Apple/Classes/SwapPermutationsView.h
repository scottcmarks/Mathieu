//
//  SwapPermutations.h
//  Mathieu
//
//  Created by scott on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SwapPermutationsView : UIView <UIPickerViewDelegate , UIPickerViewDataSource>
{
    UIPickerView * swapPermutationPicker;
	UINavigationItem * navigationBar;
    UILabel * currentPermutation;
    UIView * currentPermutationPreview;
}

@property( nonatomic, retain ) IBOutlet UIPickerView * swapPermutationPicker;
@property( nonatomic, retain ) IBOutlet UINavigationItem * navigationBar;
@property( nonatomic, retain ) IBOutlet UILabel * currentPermutation;
@property( nonatomic, retain ) IBOutlet UIView * currentPermutationPreview;

- ( void ) synchronize;

@end
