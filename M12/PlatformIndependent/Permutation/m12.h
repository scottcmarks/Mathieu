#if !defined( __M12_H_INCLUDED__ )
#define  __M12_H_INCLUDED__
/*
 *  m12.h
 *  SporadicM12
 *
 *  Created by Jackie Marks on 10/15/08.
 *  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
 *
 */

#include "permutation"
#include <vector>
#include <map>
#include <ostream>
#include "Utilities.h"

// The next defines are used as template parameters and are
// also necessary to make the macro forAllBalls work correctly.
typedef signed char tiny_int;
typedef long int big_int;

#define nBalls 12

// #define Index tiny_int
#define Index tiny_int
#define Rank big_int
#define nRandomMoves 100

class M12Permutation: public Permutation< nBalls, Index, Rank > {
public:
  typedef Permutation< nBalls, Index, Rank > super;
  static const int nSwaps=341;
  typedef struct{ Index best; const PermArray swap; } swap_table_entry;
  static swap_table_entry swaps[ nSwaps ];
  M12Permutation( );
  M12Permutation( const M12Permutation& other );
  M12Permutation( const super& other );
  M12Permutation( const PermArray & p );
  M12Permutation & reset( );
  M12Permutation & left ( Index count = 1 );
  M12Permutation & right( Index count = 1 );
  M12Permutation & swap( );
  M12Permutation & random( );
  M12Permutation & undo( );
  M12Permutation & invert( );
  M12Permutation inverse( ) const;
  M12Permutation operator *( const M12Permutation other) const;
  M12Permutation operator /( const M12Permutation other) const;
  void compute_indices( PermArray & f, Rank & r ) const
  {
  // Compute the inverse into f, by hand for speed
    Index i;
    for( i = 0 ; i < nBalls ; i++ ) f[ permutation[ i ] ] = i;

  //  cout << "lookup_group: pinv=" << f << endl;


  // Do a factoradic, truncated to the first 5 elements
  // In particular, leave f[5] and f[6] untouched
    Index fi;

    Index j;
    r = fi = f[ i = 0 ];
    goto after_the_multiply;

    while ( ++i < 5 )
    {
      fi = f[ i ];
      r = r * ( nBalls - i ) + fi;
after_the_multiply:
    for ( j = i + 1 ; j < 5 ; j++ )
    if ( fi < f[ j ] )
    --f[ j ];
    }
  };
  static M12Permutation swapPermutation;
  static int swapPermutationIndex;
  static int set_swapPermutationIndex( int i )
  {
    int old_index = swapPermutationIndex;
    if ( 0 <= i && i <= n_array_elements( swaps ) )
    {
        swapPermutation = M12Permutation( swaps[ i ].swap );
        swapPermutationIndex = i;
    }
    return old_index;
  };
  static M12Permutation rightPermutation;
  bool preserves_4( )
  {
    for ( Index i=0; i < nBalls-1; i++ )
    {
      for ( Index j=0; j < 4; j++ )
      {
        Index k=( i + j ) % ( nBalls - 1 ) + 1;
        if ( ! ( permutation[ k ] == k ) ) goto not_this_k; 
      }
      return true;
not_this_k: 
      ;
    }
    return false;
  }
};

class M12PermutationWithHistory: public M12Permutation {
public:
  typedef M12Permutation super;
  typedef signed char HistoryElement;

  M12PermutationWithHistory( );
  M12PermutationWithHistory( const M12PermutationWithHistory& other );
  M12PermutationWithHistory( const super& other );
  M12PermutationWithHistory( const PermArray & p );
  M12PermutationWithHistory( std::istream & serialization );
  std::ostream & serialize( std::ostream & serialization );
  M12PermutationWithHistory & reset( );
  M12PermutationWithHistory & left ( Index count = 1 );
  M12PermutationWithHistory & right( Index count = 1 );
  M12PermutationWithHistory & swap( );
  M12PermutationWithHistory & random( bool amnesia=true );
  M12PermutationWithHistory & undo( bool move=true );
  bool maybe_undo( HistoryElement & e, bool move=true );
  M12PermutationWithHistory & invert( );
  class History: public std::vector<HistoryElement> {
  public:
    static inline bool is_left( HistoryElement e )
      { return -( nBalls - 1 ) <= e && e <= -1 ; };
    static inline bool is_right( HistoryElement e )
      { return +1 <= e && e <= +( nBalls - 1 ) ; };
    static inline bool is_left_or_right( HistoryElement e )
      { return is_left( e ) || is_right( e ) ; };
    static inline bool is_swap( HistoryElement e )
      { return 0 == e ; };
    template < typename ostream_type >
    ostream_type& insert( ostream_type& os,
                          ostream_type& insert_left ( ostream_type& os, int Count ),
                          ostream_type& insert_swap ( ostream_type& os            ),
                          ostream_type& insert_right( ostream_type& os, int Count ),
                          ostream_type& insert_macro( ostream_type& os, HistoryElement m ),
                          ostream_type& insert_macro_inverted( ostream_type& os, HistoryElement m )) const
    {
      for ( History::const_iterator p = begin( ); p != end( ); p++ )
        if ( is_left( *p ) )
          insert_left ( os, -*p );
        else if ( is_right( *p ) )
          insert_right( os, +*p );
        else if ( is_swap( *p ) )
          insert_swap ( os      );
        else if ( *p < 0 )
          insert_macro_inverted( os, -*p );
        else
          insert_macro( os, +*p );
        return os;
    };
    History( ){ };
    History( std::istream & serialization );
    std::ostream & serialize( std::ostream & serialization );
    bool macro_is_defined ( const HistoryElement c ) const;
    M12PermutationWithHistory macro_definition( const HistoryElement c ) ;
    History& expand_macro ( const HistoryElement c );
    History& set_macro    ( const HistoryElement c , M12PermutationWithHistory & m );
    History& erase_macro  ( const HistoryElement c );
    History& erase_all_macros( );
    static M12PermutationWithHistory & run_macro ( M12PermutationWithHistory & m, const HistoryElement c , bool inverted=false );
  protected:
    friend class M12PermutationWithHistory;
    History& reset( );
    History& left ( Index count = 1 );
    History& right( Index count = 1 );
    History& swap( );
    History& invert( );
    History& operator *=( const HistoryElement c );
    History& operator /=( const HistoryElement c );
    History& operator *=( const History & other_history );
    History& operator /=( const History & other_history );
    int cmp( History other_history )       ;
    bool operator <( const History & other_history )       { return cmp( other_history ) < 0 ; };
    int moves( ) const ;
    int steps( )       ;
    typedef std::map < HistoryElement,  M12PermutationWithHistory > macro_map;
    macro_map macros;
  private:
    History& _step( Index direction, Index count );
  };
  History getHistory( ) const { return history ; } ;
  bool history_is_empty( ) const { return history.empty( ) ; } ;
  bool history_is_single_macro( HistoryElement e ) { return history.size( ) == 1 && history[ 0 ] == e ; } ;
  int history_length( ) { return history.size( ) ; } ;
  M12PermutationWithHistory & run( const History& additional_history );
  M12PermutationWithHistory   inverse( ) const;
  M12PermutationWithHistory   operator * ( const M12PermutationWithHistory & other ) const;
  M12PermutationWithHistory & operator *=( const M12PermutationWithHistory & other );
  M12PermutationWithHistory   operator / ( const M12PermutationWithHistory & other ) const;
  M12PermutationWithHistory & operator /=( const M12PermutationWithHistory & other );
  int moves( ) const { return history.moves( ) ; } ;
  int steps( )       { return history.steps( ) ; } ;
  bool macro_is_defined( const HistoryElement c ) const;
  M12PermutationWithHistory& expand_macro ( const HistoryElement c );
  M12PermutationWithHistory& set_macro    ( const HistoryElement c ,       M12PermutationWithHistory & m );
  M12PermutationWithHistory& erase_macro  ( const HistoryElement c );
  M12PermutationWithHistory& erase_all_macros( ) ;
  M12PermutationWithHistory& run_macro    ( const HistoryElement c , bool inverted=false );
protected:
  friend class History;
  History history;
};
#endif /* !defined( __M12_H_INCLUDED__ ) */
