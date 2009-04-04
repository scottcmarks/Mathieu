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
#import "BallView.h"
#import "BallRingView.h"

@implementation SwapPermutationsView

@synthesize navigationBar;
@synthesize swapPermutationPicker;
@synthesize currentPermutation;
@synthesize currentPermutationPreview;
@synthesize pickedSwapIndex;

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }

- (void) awakeFromNib
{
	navigationBar.title       = fullAppName ;
    currentPermutationPreview = [ BallRingView ballRingViewWithFrame: CGRectMake( 101, 44, 118, 118 )
                                                                tags: NO
                                                            delegate: nil ] ;
    [ self addSubview:currentPermutationPreview ];
}

- ( void ) synchronize
{
    currentPermutation.text    = self.gameModel.cycles;
    pickedSwapIndex = self.gameModel.swapIndex;
#if FREE
    int row = pickedSwapIndex == 1 ? 0 : 1;
#else
    int row = pickedSwapIndex ;
#endif
    [ swapPermutationPicker selectRow: row inComponent: 0 animated: NO ];
}

- ( void ) willMoveToSuperview: ( UIView * )superView
{
    if ( superView ) [ self synchronize ] ;
}

// UIPickerViewDelegate methods
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    assert (component == 0);
#if FREE
    row = ( row == 0 ? 1 : 24 );
#endif
    return [ NSString stringWithFormat: @"#%d  ----  difficulty %d ", row+1, [ self.gameModel difficultyOfSwap:row ] ];
}

-(void) pickerView: (UIPickerView *)pickerView 
      didSelectRow: (NSInteger) row 
       inComponent: (NSInteger) component
{
    assert (component == 0);
#if FREE
    row = ( row == 0 ? 1 : 24 );
#endif
    self.currentPermutation.text = [ self.gameModel cyclesForSwap:row ];
    [ BallView setColorsForSwapPermutation: MPermutation( MPermutation::swaps[ row ].swap ) ] ;
    [ currentPermutationPreview redraw ]; 
    pickedSwapIndex =  row;
}


// UIPickerViewDataSource methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ( component == 0 )
#if FREE
        return 2;
#else
        return self.gameModel.nSwaps;
#endif
    return 0;
}


- (void)dealloc 
{
    swapPermutationPicker = nil;
    [super dealloc];
}


@end
