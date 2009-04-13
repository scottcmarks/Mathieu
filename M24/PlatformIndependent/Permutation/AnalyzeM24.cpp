// AnalyzeM24.cpp : Defines the entry point for the console application.
//
#if defined( WIN32 ) && defined( _DEBUG )
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif   /* defined( WIN32 ) && defined( _DEBUG )  */

#include <iostream>
#include <fstream>

#if defined( WIN32 ) && defined( _DEBUG )
#define DEBUG_CLIENTBLOCK   new( _CLIENT_BLOCK, __FILE__, __LINE__)
#define new DEBUG_CLIENTBLOCK
#endif  /* defined( WIN32 ) && defined( _DEBUG )  */


#include <sstream>
#include <cstdlib>
using namespace std;

#include <getopt.h>


#include "M24PermTable.h"
#include "view.h"


std::ostream & operator<<(std::ostream& out, const PermArray & p )
{
  out << "{";
  forAllBalls(i) out << " " << setw(2) << (int)p[ i ];
  out << " }";
  return out;
}

int n_permutations_remaining = nPermutations;

typedef enum { silent=0, discreet=1, chatty=2, babbling=3, MAX_VERBOSITY=babbling} verbosity_level;

verbosity_level verbosity = silent;

static void increase_verbosity( )
{
  if ( verbosity < MAX_VERBOSITY )
    switch ( verbosity )
    {
      case silent:
        verbosity = discreet;
        break ;
      case discreet:
        verbosity = chatty;
        break;
      case chatty:
        verbosity = babbling;
        break;
      case babbling:
        verbosity = MAX_VERBOSITY;
        break;
      default:
        ;
    }
}

inline perm_info possibly_record( M24PermInfoTable & table, const Perm & p, const perm_info & new_p_info )
{
//    table_group & group = *table.lookup_group( p );
  perm_info & p_info = table.lookup( p );
  const bool unseen = ( 0 == p_info.steps_plus_one ) ;
  const bool replace = unseen || new_p_info < p_info;
  if ( replace )
  {
    p_info = new_p_info;
    if ( unseen ) --n_permutations_remaining;
  }
  
  if ( babbling <= verbosity )
  {
    cout << "possibly_record( " << p << " )" 
         << "  " 
         << "n_permutations_remaining=" << setw(9) << n_permutations_remaining 
         << endl;
  }
  else if ( discreet <= verbosity )
  {
    cout
//          << setw(2)   << (int)group.pinv5  << " "
//          << setw(2)   << (int)group.pinv6  << ": "
#if defined(USE_M24PERMUTATION_WITH_HISTORY)
        << setiosflags( ios::left ) << setw(20) << str( p.getHistory( ) ) << resetiosflags( ios::left )
#endif
        << ( unseen ? " add" : "dup" ) << endl;
  }
  return p_info;
}

void generate_permutations_recursively( M24PermInfoTable & table, Perm & p, perm_info p_info, const Index max_moves )
{

  if ( 0 == n_permutations_remaining ) return;

  // Iterate action in positions to the right and left of this one
  // If condition, action on this one first, before iterating
  #define iterate( condition, action )               \
    do                                               \
    {                                                \
      if ( condition ) action;                       \
      for ( int i = 1; i <= ( nBalls - 1 )/2 ; i++ ) \
      {                                              \
        p_info.steps_plus_one += i;                  \
        p.right( i );                                \
        action;                                      \
        p.left( 2 * i );                             \
        action;                                      \
        p.right( i );                                \
        p_info.steps_plus_one -= i;                  \
      }                                              \
    } while( 0 )
  // Action to possibly record this position in the table
  #define record   possibly_record( table, p, p_info )
  // Action to recursively invoke this function
  #define generate generate_permutations_recursively( table, p, p_info, max_moves )
  
  if ( 1 == p_info.moves )
  {
    if ( p_info.moves == max_moves )
      iterate( true, record );
    else  // 1 == moves < max_moves
    {
      p_info.moves++;
      iterate( true, generate );
      p_info.moves--;
    }
  }
  else
  {
    p.swap( );
    p_info.steps_plus_one++;
    if ( p_info.moves == max_moves )
      iterate( true, record );
    else  // 1 < moves < max_moves
    {
      p_info.moves++;
      iterate( false, generate );
      p_info.moves--;
    }
    p_info.steps_plus_one--;
    p.swap( );
  }

}

int max_depth = nBalls ;

void find_all_permutations( M24PermInfoTable & table )
{
  Perm p;
  perm_info p_info( 1, 1 );
  for ( Index max_moves = 1; max_moves <= max_depth ; max_moves++ )
  {
    if ( (nPermutations - n_permutations_remaining) == nPermutations ) break;
    generate_permutations_recursively( table, p, p_info, max_moves );
  }
}

int usage( char *argv[], int return_code )
{
  ostream & os = return_code == 0 ? cout : cerr;
  os << "usage: " << argv[ 0 ] << " -h | --help | -v | --verbosity | ( -d | --max-depth ) d | ( -n | --nperms ) n" << endl
      << "  -v or --verbosity may be repeated for increased chattness." << endl
      << "  -d or --max-depth  d   limits searching the tree to depth d" << endl
      << "  -n or --nperms     n   limits the number of permutations found to n" << endl;
  return return_code;
}

int main(int argc, char *argv[])
{
  int c;
  struct option long_options[] =
  {
    {"verbose",   no_argument,       0, 'v'},
    {"help",      no_argument,       0, 'h'},
    {"nperms",    required_argument, 0, 'n'},
    {"max-depth", required_argument, 0, 'd'},
    {0, 0, 0, 0}
  };

  int option_index = 0;
    while (! ( -1 == ( c = getopt_long (argc, argv, "vhn:d:",
              long_options, &option_index) ) ) )
    switch (c)
    {
      case 'v':
        increase_verbosity( );
        break;

      case 'h':
        return usage( argv, 0 );

      case 'n':
        n_permutations_remaining = atol(optarg) ;
        if ( ! ( 0 < n_permutations_remaining && n_permutations_remaining <= nPermutations ) )
        {
          cerr << "nperms must be between 1 and " << nPermutations << " but was given as " << n_permutations_remaining << endl;
          return usage( argv, 2 );
        }
        break;

      case 'd':
        max_depth = atoi(optarg) ;
        if ( ! ( 0 < max_depth && max_depth <= nBalls ) )
        {
          cerr << "max depth must be between 1 and " << nBalls << " but was given as " << max_depth << endl;
          return usage( argv, 2 );
        }
        break;

      case '?':
      default:
        return usage( argv, 1 );
    }


  cout << "One Perm is " << sizeof( Perm ) << " bytes." << endl ;
  cout << "One table_group is " << sizeof( table_group ) << " bytes." << endl ;
  cout << "Permutation table is " << M24PermInfoTable::perm_table_size << " bytes." << endl ;
  cout << "Finding " << n_permutations_remaining << " permutations" ;
  if ( discreet <= verbosity )
    cout << "." << endl;
  else
    cout << " ... ";
  cout << flush ;
  
  M24PermInfoTable table;

  table.allocate( );
  
  find_all_permutations( table );

  cout << "done." << endl;
  if ( 0 < n_permutations_remaining )
    cout << "Quit early, with " << n_permutations_remaining << " remaining to be found." << endl;
  
  table.dump( "Perms.bin" );
  
  table.deallocate( );

#if defined( WIN32 ) && defined( _DEBUG )
  // make sure the memory debugger finds at least one leak
  // Perm *p = new Perm( );
  _CrtDumpMemoryLeaks();
#endif   /* defined( WIN32 ) && defined( _DEBUG )  */

  return 0;
}









/***

The purpose of this program is to create a table that can be use to solve M24.

The M24 solver needs to do the following:

The incremental algorithm:

From the general position, move the 0 ball home.
    Look up in a table of all 24 positions
    The answer is simple -- if the 0 ball is home, we're done.
    Otherwise, if it is in position i, use L(i-1) or R(24-i) to bring it to position 1
    Then use swap to bring it home

With the 0 ball home, move the 1 ball home
    Look up in a table of all 23 positions
    The answer is simple -- if the 1 ball is home, we're done.
    Otherwise, if it is in position i, use L(i-1) or R(24-i) to bring it home

With the 0 and 1 balls home, move the 2 ball home
    Look up in a table of all 22 positions

With the 0, 1 and 2 balls home, move the 3 ball home
    Look up in a table of all 21 positions

With the 0, 1, 2 and 3 balls home, move the 4 ball home
    Look up in a table of all 20 positions

with the 0, 1, 2, 3 and 4 balls home, look at the 5 and 6 positions:
    The 5 position will be any ball except 6, 15 or 18 -- 16 possibilities
    The 6 position will be 6, 15, or 18 -- 3 possibilities
    Look up in a table of 48 solutions for the final answer that brings all balls home.


The fast algorithm:
Use a table of 5100480 entries indexed to find a subtable containing:
    a single permutation that puts 0_4 in place
    and a vector of 48 complete histories or history lengths (see below)
    (This is a total of 244823040 histories, or at about 20 bytes each,
     4896460800 bytes = 4.56GiB).
Compute the split rank of the position, where
    the 0_4 part of the split rank is computed by
        taking the inverse of the position
            (which gives the positions of all balls)
        computing the factoradic 'f' of that inverse
        then computing ( ( ( f[0] * 23 + f[1] ) * 22 + f[2] ) * 21 + f[3]) * 20 + f[4]
            which tells in which of the 5,100,480 positions are balls 0-4
    the 5_6 part of the split rank
        Use the single permutation to compute a new position with 0_4 in place
        Use the 5 and 6 positions of that position to compute which of the
            16*3 complete histories to use

The not-quite-as-fast algorithm:
In the place of the complete histories, we could just record the length of those histories
(in complete steps, i.e. R7 is 7), and then use the M12 trick of looking up the history length
of the positions moved to from the current position after a single L, R or S -- (at least) one
of those should have a history one step shorter, so choose it.
    (This is a total of 244823040 history lengths, or at 1 byte each,
     244823040 bytes = 233MiB.  Assuming 255 steps is enough, that is.).

This leaves out the 5100480 permutations required to move the position to 0_4_are_home.
Permutations can be stored as tightly as nybbles, but bytes are easier.
5100480 * 24 bytes is 122411520 bytes = 116MiB.


To fill out either plan requires knowing everything -- the histories (preferably shortest)
of all 244823040 positions.  SO the plan is to generate all histories of length 0, 1 ...
until 244823040 positions have been found.

As soon as the first history of the 48 in any group of the 5100480 groups has been found,
it can be used (OK, its inverse can be used) to convert all of those 48 to an 0_4_are_home position
whereupon the 5 and 6 positions can be used to select the 0..47 index in which to record any
new positions of that group encountered while enumerating all positions.  That first position
will convert itself to id, so it will neatly go into subtable position zero.

For any position, to determine to which of the of the 5100480 groups it belongs, take the
inverse permutation, compute its split rank part as above.


Analysis implementation optimization ideas:
   Only save pinv5 and pinv6 instead of all of pinv in the table
   Don't compute steps by calling steps.  Instead, compute it by induction in the recursion.
     Then build the table using Permutation<nBalls, Index, Rank> instead of MathieuPermutation,
     and avoid the history baggage.
     [It actually turned out necessary to split MathieuPermutation into a class that knows right,
      etc. (MathieuPermutation) and a subclass that knows about history (MathieuPermutationWithHistory)].
   Don't bother to invert the permutation.  Just think of the recursion as generating all
      the inverse permutations -- it's the same set.
      Then lookup should be fast enough to use it for search pruning.
   possibly_record should replace an existing steps count with a lower one if it happens to
      find one.  But it still must return some indication that there nothing new was recorded.
   Don't be so fancy generating R, then L, then R2, then L2, ...
      or if doing so, cache the 23 "next" permutations first, so as to avoid the 23*22/2 algorithm.
      
      
mmap-related use cases
   Create new table (what AnalyzeM24.cpp is doing now)
      open file in overwrite/create mode
      write last byte
      truncate file
      use mmap to set table pointer
      sync, set table pointer to NULL in destructor
   Use table for lookup
      open file in read-only mode
      stat should show file size==perm_table size
      use mmap to set table pointer
      set table pointer to NULL (don't sync) in destructor
   Update table with macro-moves
      open file in ? mode
      stat should show file size==perm_table size
      use mmap in copy-on-write mode to set table pointer
      table.dump( ) should write to different file (must be different)
          then use mmap to reset table point to newly-written file?
      sync, set table pointer to NULL in destructor
      
      
      
											
***/
