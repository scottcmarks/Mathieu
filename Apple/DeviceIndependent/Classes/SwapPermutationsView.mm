//
//  SwapPermutations.m
//  Mathieu
//
//  Created by Scott Marks on 3/30/09.
//  Copyright 2009 Magnolia Heights R & D. All rights reserved.
//

#import "SwapPermutationsView.h"
#import "mathieu.h"
#import "SporadicMAppDelegate.h"
#import "GameModel.h"
#import "BallView.h"
#import "BallRingView.h"

@implementation SwapPermutationsView

@synthesize currentPermutation        ;
@synthesize pickedSwapIndex           ;
#if TARGET_OS_IPHONE
@synthesize navigationBar             ;
@synthesize swapPermutationPicker     ;
#endif
- ( SporadicMAppDelegate * ) appDelegate { return ( SporadicMAppDelegate * )[ [ Application sharedApplication ] delegate ] ; }
- ( GameModel * ) gameModel { return self.appDelegate.gameModel ; }

- (void) awakeFromNib
{
#if TARGET_OS_IPHONE
    navigationBar.title       = fullAppName ;
#endif
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
#if TARGET_OS_IPHONE
    [ swapPermutationPicker selectRow: row inComponent: 0 animated: NO ];
#endif
}    

- ( void ) willMoveToSuperview: ( View * )superView
{
    if ( superView ) [ self synchronize ] ;
}

#if TARGET_OS_IPHONE

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
    currentPermutation.text = [ self.gameModel cyclesForSwap:row ];
    [ BallView setColorsForSwapPermutation: MathieuPermutation( MathieuPermutation::swaps[ row ].swap ) ] ;
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
        return nSwaps;
#endif
    return 0;
}

#endif  /* TARGET_OS_IPHONE */


- (void)dealloc 
{
    swapPermutationPicker = nil;
    [super dealloc];
}


@end
