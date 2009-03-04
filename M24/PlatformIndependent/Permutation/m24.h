#if !defined( __M24_H_INCLUDED__ )
#define  __M24_H_INCLUDED__
/*
 *  m24.h
 *  SporadicM24
 *
 *  Created by Jackie Marks on 10/15/08.
 *  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.
 *
 */

#include "permutation"
#include <vector>
#include <map>
#include <ostream>

// The next defines are used as template porameters and are
// also necessary to make the macro forAllBalls work correctly.
typedef signed char tiny_int;
typedef long long int big_int;

#define nBalls 24
// #define Index tiny_int
#define Index tiny_int
#define Rank big_int
#define nRandomMoves 100

class M24Permutation: public Permutation< nBalls, Index, Rank > {
public:
  typedef Permutation< nBalls, Index, Rank > super;
  M24Permutation( );
  M24Permutation( const M24Permutation& other );
  M24Permutation( const super& other );
  M24Permutation( const PermArray p );
  M24Permutation & reset( );
  M24Permutation & left ( Index count = 1 );
  M24Permutation & right( Index count = 1 );
  M24Permutation & swap( );
  M24Permutation & random( );
  M24Permutation & undo( );
  M24Permutation & invert( );
  M24Permutation inverse( ) const;
  M24Permutation operator *( const M24Permutation other) const;
  M24Permutation operator /( const M24Permutation other) const;
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
};

class M24PermutationWithHistory: public M24Permutation {
public:
  typedef M24Permutation super;
  typedef signed char HistoryElement;
  
  M24PermutationWithHistory( );
  M24PermutationWithHistory( const M24PermutationWithHistory& other );
  M24PermutationWithHistory( const super& other );
  M24PermutationWithHistory( const PermArray p );
  M24PermutationWithHistory( std::istream & serialization );
  std::ostream & serialize( std::ostream & serialization );
  M24PermutationWithHistory & reset( );
  M24PermutationWithHistory & left ( Index count = 1 );
  M24PermutationWithHistory & right( Index count = 1 );
  M24PermutationWithHistory & swap( );
  M24PermutationWithHistory & random( bool amnesia=true );
  M24PermutationWithHistory & undo( bool move=true );
  bool maybe_undo( HistoryElement & e, bool move=true );
  M24PermutationWithHistory & invert( );
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
    M24PermutationWithHistory macro_definition( const HistoryElement c ) ;
    History& expand_macro ( const HistoryElement c );
    History& set_macro    ( const HistoryElement c , M24PermutationWithHistory & m );
    History& erase_macro  ( const HistoryElement c );
    static M24PermutationWithHistory & run_macro ( M24PermutationWithHistory & m, const HistoryElement c , bool inverted=false );
  protected:
    friend class M24PermutationWithHistory;
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
    typedef std::map < HistoryElement,  M24PermutationWithHistory > macro_map;
    macro_map macros;
  private:
    History& _step( Index direction, Index count );
  };
  History getHistory( ) const { return history ; } ;
  bool history_is_empty( ) const { return history.empty( ) ; } ;
  bool history_is_single_macro( HistoryElement e ) { return history.size( ) == 1 && history[ 0 ] == e ; } ;
  int history_length( ) { return history.size( ) ; } ;
  M24PermutationWithHistory & run( const History& additional_history );
  M24PermutationWithHistory   inverse( ) const;
  M24PermutationWithHistory   operator * ( const M24PermutationWithHistory & other ) const;
  M24PermutationWithHistory & operator *=( const M24PermutationWithHistory & other );
  M24PermutationWithHistory   operator / ( const M24PermutationWithHistory & other ) const;
  M24PermutationWithHistory & operator /=( const M24PermutationWithHistory & other );
  int moves( ) const { return history.moves( ) ; } ;
  int steps( )       { return history.steps( ) ; } ;
  bool macro_is_defined( const HistoryElement c ) const;
  M24PermutationWithHistory& expand_macro ( const HistoryElement c );
  M24PermutationWithHistory& set_macro    ( const HistoryElement c ,       M24PermutationWithHistory & m );
  M24PermutationWithHistory& erase_macro  ( const HistoryElement c );
  M24PermutationWithHistory& run_macro    ( const HistoryElement c , bool inverted=false );
protected:
  friend class History;
  History history;
};
#endif /* !defined( __M24_H_INCLUDED__ ) */
