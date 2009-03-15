//
//  GameModel.h
//  SporadicM
//
//  Created by Jackie Marks on 10/22/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "mathieu.h"

typedef MPermutationWithHistory::PermArray PermArray;
typedef MPermutationWithHistory::HistoryElement HistoryElement;
@interface GameModel : NSObject {
@private
    MPermutationWithHistory *currentPermutation;
    MPermutationWithHistory *startingPermutation;
}

-(id) init;
-(id) initFromData: ( NSData * ) data;
+(id) create;
+(id) createFromData: ( NSData * ) data;
-(NSData *) asData;
-(int) at: ( int ) index;
-(void) copyInto:( PermArray ) pa;
-(bool) isIdentity;
-(void) reset;
-(void) right;
-(void) left;
-(void) swap;
-(void) random;
-(void) revert;
-(bool) undo: ( bool ) move  move: ( HistoryElement & ) e;
-(void) spin: ( int ) n;
-(void) runCombo: ( HistoryElement ) c inverted: ( bool ) inverted;
-(void) setCombo: ( HistoryElement ) c;
-(void) eraseCombo: ( HistoryElement ) c;
-(bool) hasDefinedCombo: ( HistoryElement) c;
-(bool) isSolving;
-(bool) historyIsEmpty;
-(bool) historyIsSingleCombo: ( HistoryElement ) c;
-(int) historyLength;

@property (nonatomic, readonly) NSString * history;

@end
