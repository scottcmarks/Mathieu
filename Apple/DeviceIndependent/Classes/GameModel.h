//
//  GameModel.h
//  SporadicM
//
//  Created by Scott Marks on 10/22/08.
//  Copyright © 2008, 2023 Magnolia Heights Research and Development. All rights reserved.
//

#import "Apple Cross-platform.h"
#import "mathieu.h"

typedef MathieuPermutationWithHistory::PermArray PermArray;
typedef MathieuPermutationWithHistory::HistoryElement HistoryElement;
@interface GameModel : NSObject

-(id) init;
-(id) initFromData: ( NSData * ) data;
+(id) gameFromData;
+(id) gameFromData: ( NSData * ) data;
-(NSData *) data;
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
-(void) eraseAllCombos;
-(bool) hasDefinedCombo: ( HistoryElement) c;
-(bool) hasAnyDefinedCombo;
-(bool) isSolving;
-(bool) historyIsEmpty;
-(bool) historyIsSingleCombo: ( HistoryElement ) c;
-(int) historyLength;
-( int ) moves;
-( int ) steps;

@property (nonatomic, readonly) NSString * history;
@property (nonatomic, readonly) NSString * cycles;

@property (nonatomic          ) int swapIndex;
- ( NSString *) cyclesForSwap: (int)nSwap;
- ( int ) difficultyOfSwap: ( int )nSwap;
@end
