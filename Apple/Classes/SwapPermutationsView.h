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
}

@property( nonatomic, retain )  UIPickerView * swapPermutationPicker;
@property( nonatomic, retain ) IBOutlet UINavigationItem * navigationBar;

@end
