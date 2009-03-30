 /*
 *  m12.cc
 *  SporadicM12
 *
 *  Created by Jackie Marks on 10/15/08.
 *  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
 *
 */


#include "m12.h"
#include "rand_utils.h"

using namespace std;

M12Permutation::M12Permutation( )
  : super( )
  { };

M12Permutation::M12Permutation( const M12Permutation & other )
  : super( other )
  { };

M12Permutation::M12Permutation( const super & other )
  : super( other )
  { };

M12Permutation::M12Permutation( const M12Permutation::PermArray & p )
  : super( p )
  { };


//  Below are the original SciAm M12 generators.
//  swap was called "Inverse", and right was called "Merge"
//  M12Permutation::PermArray swap_perm = { 11, 10,  9,  8,  7,  6,  5,  4,  3,  2,  1,  0 } ;
//  M12Permutation::PermArray right_perm= {  0, 11,  1, 10,  2,  9,  3,  8,  4,  7,  5,  6 };

// Below are the generators of M12, "swap" and "right"
// swap is a permutation composed of (nBalls/2) 2-cycles
// right is a permutation composed of (0) with a (nBalls-1)-cycle.
//

// Include all 341 permutations that are six 2-cycles and still generate the whole group
#include "swaps.inc"

// Use the second one as it makes a simple 4-preserving move
#define INITIAL_SWAP_PERMUTATION_INDEX 1

M12Permutation::PermArray const & swap_perm = M12Permutation::swaps[ INITIAL_SWAP_PERMUTATION_INDEX ].swap; 
M12Permutation M12Permutation::swapPermutation( swap_perm );

M12Permutation::PermArray right_perm= {  0, 11,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10 };
M12Permutation M12Permutation::rightPermutation( right_perm );

M12Permutation & M12Permutation::left( Index count ) {
  for ( Index i = 0 ; i < count ; i ++ ) *this /= rightPermutation ;
  return *this;
}

M12Permutation & M12Permutation::right( Index count ) {
  for ( Index i = 0 ; i < count ; i ++ ) *this *= rightPermutation;
  return *this;
}

M12Permutation & M12Permutation::swap( ) {
    *this *= swapPermutation ;
    return *this;
}

M12Permutation & M12Permutation::reset( ) {
    super::reset( );
    return *this;
}


M12Permutation& M12Permutation::invert( )
{
  super::invert( );
  return *this;
}

M12Permutation M12Permutation::inverse( ) const
{
  M12Permutation result( *this );
  result.invert( );
  return result;
}

M12Permutation M12Permutation::operator *( const M12Permutation other) const
{
    M12Permutation result( *this );
    result *= other;
    return result;
}


M12Permutation M12Permutation::operator /( const M12Permutation other) const
{
    M12Permutation result( *this );
    result /= other;
    return result;
}

M12PermutationWithHistory::M12PermutationWithHistory( )
  : super( )
  { };

M12PermutationWithHistory::M12PermutationWithHistory( const M12PermutationWithHistory & other )
  : super( other ),
    history( other.history )
  { };

M12PermutationWithHistory::M12PermutationWithHistory( const super & other )
  : super( other )
  { };

M12PermutationWithHistory::M12PermutationWithHistory( const M12PermutationWithHistory::PermArray &p )
: super( p )
{ };

M12PermutationWithHistory::M12PermutationWithHistory( istream & serialization )
: super( serialization ),
  history( serialization )
{ };

ostream & M12PermutationWithHistory::serialize( ostream & serialization )
{
  super::serialize( serialization );
  history.serialize( serialization );
  return serialization;
}

M12PermutationWithHistory & M12PermutationWithHistory::left( Index count ) {
    super::left( count );
    history.left( count );
    return *this;
}

M12PermutationWithHistory & M12PermutationWithHistory::right( Index count ) {
    super::right( count );
    history.right( count );
    return *this;
}

M12PermutationWithHistory & M12PermutationWithHistory::swap( ) {
    super::swap( );
    history.swap( );
    return *this;
}

M12PermutationWithHistory & M12PermutationWithHistory::reset( ) {
    super::reset( );
    history.reset( );
    return *this;
}

M12PermutationWithHistory & M12PermutationWithHistory::random( bool amnesia ) {
    super::reset( );
    // Start out with a swap?
    if ( rand() & 1 )
        swap( );
    // Make some random moves
    for (int i=1; i<=nRandomMoves; i++) {
        const int nMoves = rand_int_from_1_to(nBalls-1);
        if ( rand( ) & 1 )
            for ( int i=0; i<nMoves; i++) left( );
        else
            for ( int i=0; i<nMoves; i++) right( );
        swap( );
    }
    // Erase that last swap?
    if ( rand() & 1 )
        swap( );
    // Amnesia
    if ( amnesia ) history.reset( );
    return *this;
}

// The representation of history is as a vector<signed char>, where
// for each signed char
//   -(nBalls-1)..-1  represents left moves
//   0 represents a swap
//   +1..+(nBalls-1)  represents right moves
//
// The history implements the group generators
// left^11==right^11==swap^2==left*right=right*left=identity
//
// Macro moves are represented as 'A'...
// and their inverses as -'A', ...

typedef M12PermutationWithHistory::History History;
typedef M12PermutationWithHistory::HistoryElement HistoryElement;


History::History( istream & serialization )
{
  size_t length;

  // Serialize in the history elements
  serialization.read( ( char * )&length, sizeof( length ) );
  resize( length );
  serialization.read( ( char * )&( * this )[ 0 ], ( streamsize )( length*sizeof( HistoryElement ) ) );

  // Serialize in the macros
  serialization.read( ( char * )&length, sizeof( length ) );
  macros.clear( );
  for ( size_t i = 0; i < length ; i ++ )
  {
    macro_map::value_type x;
    serialization.read( ( char * )&x.first, sizeof( x.first ) );
    x.second = M12PermutationWithHistory( serialization );
    macros.insert( x );
  }
}

ostream & History::serialize( ostream & serialization )
{
  size_t length;

  // Serialize out the history elements
  length = size( );
  serialization.write( ( char * )&length, sizeof( length ) );
  serialization.write( ( char * )&( * this )[ 0 ], ( streamsize )( length*sizeof( HistoryElement ) ) );

  //Serialze out the macros
  length = macros.size( );
  serialization.write( ( char * )&length, sizeof( length ) );
  for ( macro_map::iterator p = macros.begin( ) ; p != macros.end( ) ; p ++ )
  {
    macro_map::value_type & x = *p;
    serialization.write( ( char * )&x.first, sizeof( x.first ) );
    x.second.serialize( serialization );
  }

  return serialization;
}

History& History::reset( )
{
  resize( 0 );
  return *this;
}


History& History::_step( Index direction, Index count ){
  for ( Index i = 0 ; i < count ; i ++ )
    if ( empty( ) )
      push_back( direction );
    else
    {
      HistoryElement& last = back( );
      if ( ! is_left_or_right( last ) )
        push_back( direction );
      else
      {
        last += direction;
        // Hit an identity?
        if ( last == -(nBalls-1) || last == 0 || last == +(nBalls-1) )
          pop_back( );
      }
    }
  return *this;
}

History& History::left ( Index count ){ return _step( -1, count ); }

History& History::right( Index count ){ return _step( +1, count ); }

History&  History::swap( ){
  if ( empty( ) )
    push_back( 0 );
  else {
    HistoryElement& last = back( );
    if ( 0 == last )
      pop_back( ); // two swaps cancel each other
    else
      push_back( 0 );
  }
  return *this;
}

History& History::invert( ){
  if ( ! empty( ) ) {
    History::iterator p=begin( );
    History::iterator q=end( )-1;
    while ( p < q ) {
      HistoryElement temp=*p;
      *p++ = -*q;
      *q-- = -temp;
    }
    if ( p == q )
      *p = - *p;
  }
  return *this;
}


M12PermutationWithHistory & M12PermutationWithHistory::run( const History& additional_history ) {
  for ( History::const_iterator p=additional_history.begin( ); p != additional_history.end( ); p++ )
    if ( History::is_left( *p ) )
      for ( int i=0; i<-*p; i++) left( );
    else if ( History::is_right( *p ) )
      for ( int i=0; i<+*p; i++) right( );
    else if ( History::History::is_swap( *p ) )
      swap( );
    else if ( *p < 0 )
      run_macro( -*p, true );
    else
      run_macro( +*p, false );
  return *this;
}

M12PermutationWithHistory & M12PermutationWithHistory::undo( bool move)
{
  HistoryElement e;
  maybe_undo( e, move );
  return *this;
}

bool M12PermutationWithHistory::maybe_undo( HistoryElement & e, bool move)
{
  if ( history.empty( ) ) return false;

  e = history.back( );
  if ( History::is_left( e ) )
  {
    if (! move ) e = -1;
    right( -e );
  }
  else if ( History::is_right( e ) )
  {
    if (! move ) e = +1;
    left ( +e );
  }
  else if ( History::is_swap( e ) )
    swap( );
  else if ( e < 0 )
    run_macro( -e, false );
  else
    run_macro( +e, true );
  return true;
}

M12PermutationWithHistory& M12PermutationWithHistory::invert( )
{
  super::invert( );
  history.invert( );
  return *this;
}

M12PermutationWithHistory M12PermutationWithHistory::inverse( ) const
{
  M12PermutationWithHistory result( *this );
  result.invert( );
  return result;
}

History & History::operator *=( const HistoryElement e )
{
  if ( empty( ) )
  {
    push_back( +e );
  }
  else
  {
    HistoryElement & this_back = back( );
    if ( History::is_left_or_right( this_back ) )
    {
      if ( History::is_left_or_right( e ) )
      { // Cancel various Ls and Rs and round trips
        this_back += e;
        if (  this_back == - ( nBalls - 1 )
              || this_back == 0
              || this_back == + ( nBalls - 1 ) )
          pop_back( );
        else if ( this_back < - ( nBalls - 1 ) )
          this_back += ( nBalls - 1 );
        else if ( + ( nBalls - 1 ) < this_back )
          this_back -= ( nBalls - 1 );
      }
      else
        push_back( +e );
    }
    else // ! History::is_left_or_right( this_back )
    {
      if ( History::is_left_or_right( e ) )
        push_back( +e );
      else
      {
        if ( -e == this_back )
          pop_back( );
        else
          push_back( +e );
      }
    }
  }

  return *this;
}

History & History::operator /=( const HistoryElement e )
{
  return *this *= -e;
}


History & History::operator *=( const History & other_history )
{
  for ( const_iterator p = other_history.begin( ); p != other_history.end( ); p++ )
    *this *= *p;
  return *this;
}

History & History::operator /=( const History & other_history )
{
  for ( const_iterator p = other_history.begin( ); p != other_history.end( ); p++ )
    *this /= *p;
  return *this;
}

M12PermutationWithHistory M12PermutationWithHistory::operator *( const M12PermutationWithHistory & other) const
{
    M12PermutationWithHistory result( *this );
    result *= other;
    return result;
}

M12PermutationWithHistory & M12PermutationWithHistory::operator *=( const M12PermutationWithHistory & other)
{
    super::operator *=( other );
    history *= other.history;
    return *this;
}

M12PermutationWithHistory M12PermutationWithHistory::operator /( const M12PermutationWithHistory & other) const
{
    M12PermutationWithHistory result( *this );
    result /= other;
    return result;
}

M12PermutationWithHistory & M12PermutationWithHistory::operator /=( const M12PermutationWithHistory & other)
{
    super::operator /=( other );
    history /= other.history;
    return *this;
}

int History::cmp( History other_history )
{
  const int this_steps = steps( );
  const int other_steps = other_history.steps( );
  if ( this_steps < other_steps )
    return -1;
  else if ( other_steps < this_steps )
    return +1;
  else
    return 0;
}

int History::steps( )
{
  int result = 0;
  for ( const_iterator p = begin( ) ; p != end( ) ; p++ )
    if ( History::is_left_or_right( *p ) )
      if ( *p < -( nBalls - 2 ) / 2 )       // Wrap extreme L moves to smaller R moves
       result += *p + ( nBalls -1 ) ;
      else if ( +( nBalls - 2 ) / 2 < *p )  // Wrap extreme R moves to smaller L moves
        result += ( nBalls -1 ) - *p ;
      else if ( *p < 0 )                    // Small L moves
        result -= *p ;
      else                                  // Small R moves
        result += *p ;
    else if ( History::is_swap( *p ) )               // Swap
      result++ ;
    else                                    // Macro moves
      result += macros[ abs(*p) ].history.steps( );
  return result;
}

int History::moves( ) const
{
  return (int)size( );
}


bool History::macro_is_defined( const HistoryElement c ) const
{
  return ( macros.find( c ) != macros.end( ) );
}

M12PermutationWithHistory History::macro_definition( const HistoryElement c )
{
    return macro_is_defined( c ) ? macros[ c ] : M12PermutationWithHistory( );
}

History& History::expand_macro( const HistoryElement c )
{
  // Recursively expand all macro definitions first
  for ( macro_map::iterator mp = macros.begin( ) ; mp != macros.end( ) ; mp++ )
    mp->second.history.expand_macro( c );
  History pre_expansion_history( *this );
  reset( );
  for ( const_iterator hp = pre_expansion_history.begin( ); hp != pre_expansion_history.end( ); hp++ )
    if ( *hp == c )
      *this *= macros[ c ].history;
    else if ( *hp == -c )
      *this /= macros[ c ].history;
    else
      *this *= *hp;
  return *this;
}


History& History::set_macro( const HistoryElement c, M12PermutationWithHistory & m )
{
  expand_macro( c );
  macros[ c ] = m;
  return *this;
}


History& History::erase_macro( const HistoryElement c )
{
  expand_macro( c );
  macros.erase( c );
  return *this;
}


M12PermutationWithHistory & History::run_macro ( M12PermutationWithHistory & m, const HistoryElement c , bool inverted )
{
  M12Permutation & p=m;  // so that we hack the perm and its history separately
  History & h=m.history;
  if ( h.macro_is_defined( c ) )
    if ( inverted )
    {
      p /= h.macros[ c ];
      h /= c;
    }
  else
    {
      p *= h.macros[ c ];
      h *= c;
    }
  return m;
}


bool M12PermutationWithHistory::macro_is_defined( const HistoryElement c ) const
{
  return history.macro_is_defined( c );
}

M12PermutationWithHistory& M12PermutationWithHistory::expand_macro( const HistoryElement c )
{
  history.expand_macro( c );
  return *this;
}


M12PermutationWithHistory& M12PermutationWithHistory::set_macro( const HistoryElement c,       M12PermutationWithHistory & m )
{
  history.set_macro( c, m );
  return *this;
}


M12PermutationWithHistory& M12PermutationWithHistory::erase_macro( const HistoryElement c )
{
  history.erase_macro( c );
  return *this;
}


M12PermutationWithHistory& M12PermutationWithHistory::run_macro( const HistoryElement c, bool inverted )
{
  return History::run_macro( *this, c, inverted );
}
