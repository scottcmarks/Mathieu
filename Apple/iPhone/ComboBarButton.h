//
//  ComboBarButton.h
//  Mathieu
//
//  Created by Scott Marks on 04/20/2018.
//

#import <Foundation/Foundation.h>
#import "ComboButtonTargetProtocol.h"
#import "UIDualButton.h"


IB_DESIGNABLE
@interface ComboBarButton: UIDualButton
@property (nonatomic, weak) IBOutlet id<ComboButtonTarget> target;
@property (nonatomic, readonly) HistoryElement comboName;
@end
