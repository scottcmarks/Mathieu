#if !defined( __M_H_INCLUDED__ )
#define  __M_H_INCLUDED__
/*
 *  m.h
 *  SporadicM
 *
 *  Created by Scott Marks on 4/4/09.
 *  Copyright 2009 Magnolia Heights Research and Development. All rights reserved.
 *
 */

#include <vector>
#include <map>
#include <ostream>
#include "Utilities.h"
#include "rand_utils.h"


// The next defines are used as template parameters and are
// also necessary to make the macro forAllBalls work correctly.
typedef signed char tiny_int;
typedef long int big_int;


// #define Index tiny_int
#define Index tiny_int
#define Rank big_int
#define nRandomMoves 100

class MathieuPermutation: public Permutation< nBalls, Index, Rank >
{
public:
    typedef Permutation< nBalls, Index, Rank > super;
    typedef struct{ Index best; const PermArray swap; } swap_table_entry;
    static swap_table_entry swaps[ nSwaps ];

    MathieuPermutation( )
    : super( )
    { };

    MathieuPermutation( const MathieuPermutation& other )
    : super( other )
    { };

    MathieuPermutation( const super& other )
    : super( other )
    { };

    MathieuPermutation( const PermArray & p )
    : super( p )
    { }

    MathieuPermutation( std::istream & serialization )
    : super( serialization )
    {
        serialization >> swapPermutationIndex;
        set_swapPermutationIndex( swapPermutationIndex );
    }

    std::ostream & serialize( std::ostream & serialization )
    {
        super::serialize( serialization );
        serialization << ( int ) swapPermutationIndex;
        return serialization;
    };

    MathieuPermutation & reset( )
    {
        super::reset( );
        return *this;
    };

    MathieuPermutation & left ( Index count = 1 )
    {
        for ( Index i = 0 ; i < count ; i ++ ) *this /= rightPermutation ;
        return *this;
    };

    MathieuPermutation & right( Index count = 1 )
    {
        for ( Index i = 0 ; i < count ; i ++ ) *this *= rightPermutation;
        return *this;
    };

    MathieuPermutation & swap( )
    {
        *this *= swapPermutation ;
        return *this;
    };

    MathieuPermutation & random( );
    MathieuPermutation & undo( );

    MathieuPermutation & invert( )
    {
        super::invert( );
        return *this;
    };

    MathieuPermutation inverse( ) const
    {
        MathieuPermutation result( *this );
        result.invert( );
        return result;
    };

    MathieuPermutation operator *( const MathieuPermutation other) const
    {
        MathieuPermutation result( *this );
        result *= other;
        return result;
    };

    MathieuPermutation operator /( const MathieuPermutation other) const
    {
        MathieuPermutation result( *this );
        result /= other;
        return result;
    };

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
    static MathieuPermutation swapPermutation;
    static int swapPermutationIndex;
    static int set_swapPermutationIndex( int i )
    {
        int old_index = swapPermutationIndex;
        if ( 0 <= i && i <= n_array_elements( swaps ) )
        {
            swapPermutation = MathieuPermutation( swaps[ i ].swap );
            swapPermutationIndex = i;
        }
        return old_index;
    };
    static MathieuPermutation rightPermutation;
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

class MathieuPermutationWithHistory: public MathieuPermutation
{
public:
    typedef MathieuPermutation super;
    typedef signed char HistoryElement;


    class History: public std::vector<HistoryElement>
    {

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

        History( std::istream & serialization )
        {
            size_t length;

            // Serialize in the history elements
            serialization.read( ( char * )&length, sizeof( length ) );
            resize( length );
            serialization.read( ( char * )&( * this )[ 0 ], ( std::streamsize )( length*sizeof( HistoryElement ) ) );

            // Serialize in the macros
            serialization.read( ( char * )&length, sizeof( length ) );
            macros.clear( );
            for ( size_t i = 0; i < length ; i ++ )
            {
                macro_map::value_type x;
                serialization.read( ( char * )&x.first, sizeof( x.first ) );
                x.second = MathieuPermutationWithHistory( serialization );
                macros.insert( x );
            }
        };

        std::ostream & serialize( std::ostream & serialization )
        {
            size_t length;

            // Serialize out the history elements
            length = size( );
            serialization.write( ( char * )&length, sizeof( length ) );
            serialization.write( ( char * )&( * this )[ 0 ], ( std::streamsize )( length*sizeof( HistoryElement ) ) );

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
        };

        bool macro_is_defined ( const HistoryElement c ) const
        {
            return ( macros.find( c ) != macros.end( ) );
        };

        bool any_macro_is_defined ( ) const
        {
            return ( 0 != macros.size( ) );
        };

        MathieuPermutationWithHistory macro_definition( const HistoryElement c )
        {
            return macro_is_defined( c ) ? macros[ c ] : MathieuPermutationWithHistory( );
        };

        History& expand_macro ( const HistoryElement c )
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
        };

        History& set_macro    ( const HistoryElement c , MathieuPermutationWithHistory & m )
        {
            expand_macro( c );
            macros[ c ] = m;
            return *this;
        };

        History& erase_macro  ( const HistoryElement c )
        {
            expand_macro( c );
            macros.erase( c );
            return *this;
        };

        History& erase_all_macros( )

        {
            macros.clear( );
            return *this;
        };

        static MathieuPermutationWithHistory & run_macro ( MathieuPermutationWithHistory & m, const HistoryElement c , bool inverted=false )
        {
            MathieuPermutation & p=m;  // so that we hack the perm and its history separately
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
        };
    protected:
        friend class MathieuPermutationWithHistory;

        History& reset( ) { resize( 0 ); return *this; };

        History& left ( Index count = 1 ) { return _step( -1, count ); };

        History& right( Index count = 1 ) { return _step( +1, count ); };

        History& swap( )
        {
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
        };

        History& invert( )
        {
            if ( ! empty( ) )
            {
                History::iterator p=begin( );
                History::iterator q=end( )-1;
                while ( p < q )
                {
                    HistoryElement temp=*p;
                    *p++ = -*q;
                    *q-- = -temp;
                }
                if ( p == q )
                    *p = - *p;
            }
            return *this;
        };

        History& operator *=( const HistoryElement e )
        {
            if ( empty( ) )
                push_back( +e );
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
        };

        History& operator /=( const HistoryElement e )
        {
            return *this *= -e;
        };

        History& operator *=( const History & other_history )
        {
            for ( const_iterator p = other_history.begin( ); p != other_history.end( ); p++ )
                *this *= *p;
            return *this;
        };

        History& operator /=( const History & other_history )
        {
            for ( const_iterator p = other_history.begin( ); p != other_history.end( ); p++ )
                *this /= *p;
            return *this;
        };

        int cmp( History other_history ) const
        {
            const int this_steps = steps( );
            const int other_steps = other_history.steps( );
            if ( this_steps < other_steps )
                return -1;
            else if ( other_steps < this_steps )
                return +1;
            else
                return 0;
        };

        bool operator <( const History & other_history ) const { return cmp( other_history ) < 0 ; };

        int moves( ) const { return (int)size( ); } ;

        int steps( ) const
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
                    else if ( History::is_swap( *p ) )    // Swap
                        result++ ;
                    else                                  // Macro moves
                        // Can't use map::operator[ ] in a const method
                        // because it will insert the element pair if not found
                        result += macros.find( abs( *p ) )->second.history.steps( );
            return result;
        };

        typedef std::map < HistoryElement,  MathieuPermutationWithHistory > macro_map;
        macro_map macros;

    private:

        History& _step( Index direction, Index count )
        {
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
        };
    };

    MathieuPermutationWithHistory( )
    : super( )
    { };

    MathieuPermutationWithHistory( const MathieuPermutationWithHistory& other )
    : super( other ),
    history( other.history )
    { };

    MathieuPermutationWithHistory( const super& other )
    : super( other )
    { };

    MathieuPermutationWithHistory( const PermArray & p )
    : super( p )
    { };

    MathieuPermutationWithHistory( std::istream & serialization )
    : super( serialization ),
    history( serialization )
    { };

    std::ostream & serialize( std::ostream & serialization )
    {
        super::serialize( serialization );
        history.serialize( serialization );
        return serialization;
    };

    MathieuPermutationWithHistory & reset( )
    {
        super::reset( );
        history.reset( );
        return *this;
    };

    MathieuPermutationWithHistory & left ( Index count = 1 )
    {
        super::left( count );
        history.left( count );
        return *this;
    };

    MathieuPermutationWithHistory & right( Index count = 1 )
    {
        super::right( count );
        history.right( count );
        return *this;
    };

    MathieuPermutationWithHistory & swap( )
    {
        super::swap( );
        history.swap( );
        return *this;
    };

    MathieuPermutationWithHistory & random( bool amnesia=true )
    {
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
    };

    MathieuPermutationWithHistory & undo( bool move=true )
    {
        HistoryElement e;
        maybe_undo( e, move );
        return *this;
    };

    bool maybe_undo( HistoryElement & e, bool move=true )
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
    };

    History getHistory( ) const { return history ; } ;
    bool history_is_empty( ) const { return history.empty( ) ; } ;
    bool history_is_single_macro( HistoryElement e ) { return history.size( ) == 1 && history[ 0 ] == e ; } ;
    int history_length( ) { return history.size( ) ; } ;

    MathieuPermutationWithHistory & run( const History& additional_history )
    {
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
    };


    MathieuPermutationWithHistory & invert( )
    {
        super::invert( );
        history.invert( );
        return *this;
    };

    MathieuPermutationWithHistory   inverse( ) const
    {
        MathieuPermutationWithHistory result( *this );
        result.invert( );
        return result;
    };

    MathieuPermutationWithHistory   operator * ( const MathieuPermutationWithHistory & other ) const
    {
        MathieuPermutationWithHistory result( *this );
        result *= other;
        return result;
    };

    MathieuPermutationWithHistory & operator *=( const MathieuPermutationWithHistory & other )
    {
        super::operator *=( other );
        history *= other.history;
        return *this;
    };

    MathieuPermutationWithHistory   operator / ( const MathieuPermutationWithHistory & other ) const
    {
        MathieuPermutationWithHistory result( *this );
        result /= other;
        return result;
    };

    MathieuPermutationWithHistory & operator /=( const MathieuPermutationWithHistory & other )
    {
        super::operator /=( other );
        history /= other.history;
        return *this;
    };

    int moves( ) const { return history.moves( ) ; } ;

    int steps( ) const { return history.steps( ) ; } ;

    bool macro_is_defined( const HistoryElement c ) const
    {
        return history.macro_is_defined( c );
    };

    bool any_macro_is_defined( ) const
    {
        return history.any_macro_is_defined( );
    };

    MathieuPermutationWithHistory& expand_macro ( const HistoryElement c )
    {
        history.expand_macro( c );
        return *this;
    };

    MathieuPermutationWithHistory& set_macro    ( const HistoryElement c ,       MathieuPermutationWithHistory & m )
    {
        history.set_macro( c, m );
        return *this;
    };

    MathieuPermutationWithHistory& erase_macro  ( const HistoryElement c )
    {
        history.erase_macro( c );
        return *this;
    };

    MathieuPermutationWithHistory& erase_all_macros( )
    {
        history.erase_all_macros( );
        return *this;
    };

    MathieuPermutationWithHistory& run_macro    ( const HistoryElement c , bool inverted=false )
    {
        return History::run_macro( *this, c, inverted );
    };

protected:
    friend class History;
    History history;
};

#endif  /* defined( __M_H_INCLUDED__ ) */
