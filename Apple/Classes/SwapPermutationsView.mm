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

- ( SporadicMAppDelegate * ) appDelegate{ return ( SporadicMAppDelegate * )[ [ UIApplication sharedApplication ] delegate ] ; }


- (void) awakeFromNib
{
	navigationBar.title        = appName                          ;
}

// UIPickerViewDelegate methods
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    assert (component == 0);
    return [ self.appDelegate.gameModel cyclesForSwap:row ];
}

-(void) pickerView: (UIPickerView *)pickerView 
      didSelectRow: (NSInteger) row 
       inComponent: (NSInteger) component {
    assert (component == 0);
    return NSLog(@"Row %d picked", row );
}


// UIPickerViewDataSource methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if ( component == 0 )
        return 3;
    return 0;
}


- (void)dealloc 
{
    swapPermutationPicker = nil;
    [super dealloc];
}


@end
