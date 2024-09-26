//
//  ComboButtonTargetProtocol.h
//  SporadicM12
//
//  Created by Scott Marks on 1/14/09.
//  Copyright © 2009, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#import "Apple Cross-platform.h"
#import "view.h"

@protocol ComboButtonTarget
- ( IBAction ) comboInvoked:        ( HistoryElement ) comboName ;
- ( IBAction ) comboInverseInvoked: ( HistoryElement ) comboName ;
- ( IBAction ) comboSet:            ( HistoryElement ) comboName ;
@end
