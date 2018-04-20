//
//  SwapPermutations.m
//  Mathieu
//
//  Created by Scott Marks on 3/30/09.
//  Copyright © 2009, 2018 Magnolia Heights Research and Development. All rights reserved.
//

#import "SwapPermutationsView.h"
#import "mathieu.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"
#import "BallView.h"
#import "BallRingView.h"

@implementation SwapPermutationsView

@synthesize currentPermutation        ;
@synthesize currentPermutationPreview ;
@synthesize pickedSwapIndex           ;
#if TARGET_IOS
@synthesize navigationBar             ;
@synthesize swapPermutationPicker     ;
#endif
- ( SporadicMAppDelegate * ) appDelegate { return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }

- (void) awakeFromNib
{
    [super awakeFromNib];
#if TARGET_IOS
    navigationBar.title       = fullAppName ;
#endif
    [currentPermutationPreview createSubviews];
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
#if TARGET_IOS
    [ swapPermutationPicker selectRow: row inComponent: 0 animated: NO ];
#endif
}

- ( void ) willMoveToSuperview: ( View * )superView
{
    if ( superView ) [ self synchronize ] ;
}

#if TARGET_IOS

// UIPickerViewDelegate methods
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    assert (component == 0);
#if FREE
    row = ( row == 0 ? 1 : 24 );
#endif
    return [ NSString stringWithFormat: @"#%ld  ----  difficulty %d ", (long)(row+1),
            [ self.gameModel difficultyOfSwap:(int)row ] ];
}

-(void) pickerView: (UIPickerView *)pickerView
      didSelectRow: (NSInteger) row
       inComponent: (NSInteger) component
{
    assert (component == 0);
#if FREE
    row = ( row == 0 ? 1 : 24 );
#endif
    currentPermutation.text = [ self.gameModel cyclesForSwap:(int)row ];
    [ BallView setColorsForSwapPermutation: MathieuPermutation( MathieuPermutation::swaps[ row ].swap ) ] ;
    [ currentPermutationPreview redraw ];
    pickedSwapIndex = (int)row;
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
        return nSwaps;
#endif
    return 0;
}

#endif  /* TARGET_IOS */


- (void)dealloc
{
    swapPermutationPicker = nil;
    [super dealloc];
}


@end
