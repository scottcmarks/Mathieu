//
//  GameModel.m
//  SporadicM24
//
//  Created by Jackie Marks on 10/22/08.
//  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
//

#include <iostream>
#include <sstream>
#include <string>
using namespace std;

#import "view.h"

#import "Constants.h"
#import "GameModel.h"
#import "iPhoneUtilities.h"
@implementation GameModel

-( M24PermutationWithHistory *) serializePermutationFrom: ( istream & ) is
{
    unsigned char flag;
    is.read( ( char * )& flag, sizeof( flag ) );
    if ( 0 == flag )
        return NULL;
    assert ( 1 == flag );
    return new M24PermutationWithHistory( is );
}

-( ostream & ) serializePermutation:( M24PermutationWithHistory *)p to:( ostream & ) os
{
    unsigned char flag = p ? 1 : 0;
    os.write( ( char * )& flag, sizeof( flag ) );
    if ( p )
        p -> serialize( os );
    return os;
}

-(id)init{
	if ( self = [super init] ) {
        currentPermutation = new M24PermutationWithHistory;
        startingPermutation = NULL;
	}
	return self;
}

-(id) initFromData:(NSData *)data
{
    // Allow data to be nil
    if ( ! data )
        return [ self init ];
    
    
    __timestamp__;
    
	if ( self = [super init] ) {
        
        __timestamp__;
        
        stringstream ss;
        const char * bytes = ( const char * ) data.bytes;
        size_t length = data.length;
        ss.write( bytes, length );
        
        __timestamp__;
        
        currentPermutation  = [ self serializePermutationFrom: ss ];
        
        __timestamp__;
        
        startingPermutation = [ self serializePermutationFrom: ss ];
	}
    
    __timestamp__;
    
	return self;
}


+ (id)create {
    return [ [ [ GameModel alloc ] init ] autorelease ];
}

+(id) createFromData:(NSData *)data {
    return [ [ [ GameModel alloc ] initFromData: data ] autorelease ];
}

-(NSData *)asData{
    stringstream ss;
    [ self serializePermutation:currentPermutation  to:ss ];
    [ self serializePermutation:startingPermutation to:ss ];
    string str=ss.str( );
    return [ NSData dataWithBytes: str.c_str( ) length:str.length( ) ];
}

-(int) at: (int)index{
	return (*currentPermutation)[ index ];
}

-(void) copyInto: (PermArray) pa{
    forAllBalls(i) pa[ i ] = ( * currentPermutation )[ i ];
}

-(bool) isIdentity{
    return (*currentPermutation).is_identity();
}

-(NSString *) history{
    const std::wstring history_text = wstr( (*currentPermutation).getHistory() );
    if ( history_text.empty() ) return [ NSString string ];
    size_t history_size = history_text.size( ) ;
    const wchar_t * wchar_history = history_text.c_str( );
    unichar * uni_history = (unichar *)calloc( history_size, sizeof( unichar ) );
    assert( uni_history );
    
    // The following is a reprehensible hack occasioned by
    // the inability of the local wcstombs implementation
    // to handle the superscriptMinusOne characters.
    for( size_t i = 0 ; i < history_size ; i ++ )
    {
        uni_history[ i ] = ( unichar ) wchar_history[ i ] ;
        if (! ( wchar_history[ i ] == ( wchar_t ) uni_history[ i ] ) )
            uni_history[ i ] = '?';
    }

    NSString * result = [ NSString stringWithCharacters:uni_history length:history_size ];
    free( uni_history );
    return result;
}


// Allow permutation operations without history changes
static inline M24Permutation & as( M24PermutationWithHistory & p) { return (* ( M24Permutation * ) & p ) ; }

-(void) revert
{
    M24PermutationWithHistory::History saveHistory = currentPermutation -> getHistory( );
	*currentPermutation = *startingPermutation;  // copy
    for( HistoryElement c = 'A'; c <= lastComboButton ; c++ )
        if ( saveHistory.macro_is_defined( c ) )
        {
            M24PermutationWithHistory comboDef = saveHistory.macro_definition( c );
            currentPermutation -> set_macro( c , comboDef ) ;
        }
}

-(void) setStartingPermutation: ( M24PermutationWithHistory *)p
{
    if ( startingPermutation )
        delete startingPermutation;
    startingPermutation = p;
}

-(void) reset{
	(*currentPermutation).reset( );
    [ self setStartingPermutation: NULL ];
}

-(void) right{
	(*currentPermutation).right( );
}

-(void) left{
	(*currentPermutation).left( );
}

-(void) swap{
	(*currentPermutation).swap( );
}

-(void) random{
	(*currentPermutation).random( );
    [ self setStartingPermutation: new M24PermutationWithHistory( *currentPermutation ) ]; 
}

-(bool) undo: (bool)move move: ( HistoryElement & ) e
{
	return (*currentPermutation).maybe_undo( e, move );
}

-(void) spin: (int)n{
    if ( 0 < n )
        (*currentPermutation).right( +n );
    else
        (*currentPermutation).left ( -n );
}

-(void)dealloc{
    delete currentPermutation;
    [ self setStartingPermutation: NULL ];
    [ super dealloc ];
}

-(void)runCombo:(HistoryElement)c inverted:(bool)inverted {
    (*currentPermutation).run_macro( c, inverted );
}

-(void) setCombo:(HistoryElement)c
{
    M24PermutationWithHistory comboDef( * currentPermutation );
    if ( startingPermutation )
        as( comboDef ) = as( * startingPermutation ).inverse( ) * as( comboDef ); 
    (*currentPermutation).set_macro( c, comboDef );
}

-(void) eraseCombo:(HistoryElement)c
{
    (*currentPermutation).erase_macro( c );
}

-(bool) hasDefinedCombo:(HistoryElement)c
{
    return (*currentPermutation).macro_is_defined(c);
}

-(bool) isSolving
{
    return startingPermutation != NULL;
}

-(bool) historyIsEmpty
{
    return (*currentPermutation).history_is_empty();
}

-(bool) historyIsSingleCombo:(HistoryElement)c
{
    return (*currentPermutation).history_is_single_macro( c );
}

-(int) historyLength
{
    return (*currentPermutation).history_length( );
}

@end
