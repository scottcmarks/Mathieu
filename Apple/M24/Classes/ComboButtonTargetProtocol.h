//
//  ComboButtonTargetProtocol.h
//  SporadicM24
//
//  Created by Jackie Marks on 1/14/09.
//  Copyright 2009 Magnolia Heights Research and Development.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "view.h"

@protocol ComboButtonTarget
- ( IBAction ) comboInvoked:        ( HistoryElement ) comboName ;
- ( IBAction ) comboInverseInvoked: ( HistoryElement ) comboName ;
- ( IBAction ) comboSet:            ( HistoryElement ) comboName ;
@end
