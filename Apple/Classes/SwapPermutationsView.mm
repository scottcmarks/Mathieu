//
//  SwapPermutations.m
//  Mathieu
//
//  Created by scott on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SwapPermutationsView.h"
#import "mathieu.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"

@implementation SwapPermutationsView

@synthesize navigationBar;
@synthesize swapPermutationPicker;
@synthesize currentPermutation;
@synthesize currentPermutationImage;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }

- (void) awakeFromNib
{
	navigationBar.title        = appName                          ;
}

- ( void ) synchronize
{
    currentPermutation.text    = self.gameModel.cycles;
    [ swapPermutationPicker selectRow:1 inComponent:0 animated:NO ];
}

- ( void ) willMoveToSuperview: ( UIView * )superView
{
    if ( superView ) [ self synchronize ] ;
}

// UIPickerViewDelegate methods
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    assert (component == 0);
    return [ NSString stringWithFormat: @"#%d -- difficulty %d ", row, [ self.gameModel difficultyOfSwap:row ] ];
}

-(void) pickerView: (UIPickerView *)pickerView 
      didSelectRow: (NSInteger) row 
       inComponent: (NSInteger) component
{
    assert (component == 0);
    self.currentPermutation.text = [ self.gameModel cyclesForSwap:row ];
    NSLog(@"Row %d picked -- %@", row, self.currentPermutation.text );
}


// UIPickerViewDataSource methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ( component == 0 )
        return self.gameModel.nSwaps;
    return 0;
}


- (void)dealloc 
{
    swapPermutationPicker = nil;
    [super dealloc];
}


@end
