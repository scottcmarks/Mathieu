// AnalyzeM12.cpp : Defines the entry point for the console application.
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
#include <vector>
using namespace std;

#include <getopt.h>


#include "M12PermTable.h"
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

inline perm_info possibly_record( M12PermInfoTable & table, const Perm & p, const perm_info & new_p_info )
{
//    table_group & group = *table.lookup_group( p );
  perm_info & p_info = table.lookup( p );
  const bool unseen = ( 0 == p_info.steps_plus_one );
  const bool replace = unseen || new_p_info < p_info;
  if ( replace )
  {
    if ( unseen ) 
      --n_permutations_remaining;
    else if ( ! ( Perm( p_info.perm ) == p ) )
      cout << "Error: strict 5-transitivity violated." << endl
           << p_info.perm << " == p_info.perm != new_p_info.perm == " << new_p_info.perm << endl;
    p_info = p;
    if ( ! ( p_info.moves == new_p_info.moves && p_info.steps_plus_one == new_p_info.steps_plus_one ) )
    {
      cerr << "Still don't have move and step counting right" << endl
          << "  p_info.moves == " << (int)p_info.moves << " new_p_info.moves == " << (int)new_p_info.moves
          << "  p_info.steps_plus_one == " << (int)p_info.steps_plus_one << " new_p_info.steps_plus_one == " << (int)new_p_info.steps_plus_one
          << endl;
      assert( p_info.moves == new_p_info.moves && p_info.steps_plus_one == new_p_info.steps_plus_one );
    }
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
#if defined(USE_M12PERMUTATION_WITH_HISTORY)
        << setiosflags( ios::left ) << setw(20) << str( p.getHistory( ) ) << resetiosflags( ios::left )
#endif
        << ( unseen ? " add" : "dup" ) << endl;
  }
  return p_info;
}

// Iterate action in positions to the right and left of this one
// If empty_spin, action on this one first, before iterating
#define iterate( empty_spin, action )            \
do                                               \
{                                                \
  if ( empty_spin ) action;                      \
  p_info.moves++;                                \
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
  p_info.moves--;                                \
} while( 0 )
// Action to possibly record this position in the table
#define record   possibly_record( table, p, p_info )
// Action to recur
#define branch generate_branches( table, p, p_info, n_swaps, max_swaps )

void generate_leaves( M12PermInfoTable & table, Perm & p, perm_info & p_info )
{
  iterate( true, record );
}

void generate_branches( M12PermInfoTable & table, Perm & p, perm_info & p_info, Index n_swaps, const Index max_swaps )
{
  p.swap( );
  n_swaps++;
  p_info.moves++;
  p_info.steps_plus_one++;
  if ( n_swaps < max_swaps )
    iterate( false, branch );
  else
    generate_leaves( table, p, p_info );
  p_info.steps_plus_one--;
  p_info.moves--;
  n_swaps--;
  p.swap( );
}

void generate_root( M12PermInfoTable & table, Perm & p, perm_info & p_info, const Index max_swaps )
{
  Index n_swaps = 0;
  iterate( true, branch );
}



int max_depth = nBalls ;

void find_all_permutations( M12PermInfoTable & table )
{
  Perm p;
  perm_info p_info( p );
  table.clear( );
  generate_leaves( table, p, p_info );
  for ( Index max_swaps = 1; max_swaps <= max_depth ; max_swaps++ )
  {
    if ( 0 == n_permutations_remaining ) return;
    generate_root( table, p, p_info, max_swaps );
  }
}

int usage( char *argv[], int return_code )
{
  ostream & os = return_code == 0 ? cout : cerr;
  os << "usage: " << argv[ 0 ] << " -h | --help | -v | --verbosity |  -s | --simple | ( -d | --max-depth ) D | ( -n | --nperms ) N" << endl
      << "  -v or --verbosity may be repeated for increased chattness." << endl
      << "  -s or --simple         searches using all the swap bases for simple 4-transitive moves" << endl
      << "  -d or --max-depth  D   limits searching the tree to depth D" << endl
      << "  -n or --nperms     N   limits the number of permutations found to N" << endl;
  return return_code;
}

int main(int argc, char *argv[])
{
  bool simple=false;
  int c;
  struct option long_options[] =
  {
    {"verbose",   no_argument,       0, 'v'},
    {"help",      no_argument,       0, 'h'},
    {"simple",    no_argument,       0, 's'},
    {"nperms",    required_argument, 0, 'n'},
    {"max-depth", required_argument, 0, 'd'},
    {0, 0, 0, 0}
  };

  int option_index = 0;
    while (! ( -1 == ( c = getopt_long (argc, argv, "vhsn:d:",
              long_options, &option_index) ) ) )
    switch (c)
    {
      case 'v':
        increase_verbosity( );
        break;

      case 'h':
        return usage( argv, 0 );

      case 's':
        simple=true;
        break;

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
        if ( ! ( 0 <= max_depth && max_depth <= nBalls ) )
        {
          cerr << "max depth must be between 0 and " << nBalls << " but was given as " << max_depth << endl;
          return usage( argv, 2 );
        }
        break;

      case '?':
      default:
        return usage( argv, 1 );
    }


  cout << "One Perm is " << sizeof( Perm ) << " bytes." << endl ;
  cout << "One perm_info is " << sizeof( perm_info ) << " bytes." << endl ;
  cout << "Permutation table is " << M12PermInfoTable::perm_table_size << " bytes." << endl ;
  cout << "Finding " << n_permutations_remaining << " permutations" ;
  if ( discreet <= verbosity )
    cout << "." << endl;
  else
    cout << " ... ";
  cout << flush ;
  
  M12PermInfoTable table;

  table.allocate( );
  
  find_all_permutations( table );

  cout << "done." << endl;
  if ( 0 < n_permutations_remaining )
    cout << "Quit early, with " << n_permutations_remaining << " remaining to be found." << endl;
  
  table.dump( "Perms.bin" );
  
  if ( simple )
  {
    // Find all permutations that are all 2-cycles ("swaps")
    typedef vector< MathieuPermutation > perm_vector;
    perm_vector swaps;
    swaps.reserve( 396 );
    for ( Rank r = 0; r < nPermutations; r++ )
    {
      perm_info & pi = table.lookup( r );
      if ( pi.is_all_2_cycles( ) )
        swaps.push_back( MathieuPermutation( pi.perm ) );
    }
    
    // Using each of those as a basis together with "right"
    //   Generate permutations up to depth 2
    //   Print any permutations that leave 4 or more cyclically contiguous balls fixed
    max_depth = 7; // 2;
    for ( perm_vector::const_iterator p = swaps.begin( ); p < swaps.end( ); p ++ )
    {
      MathieuPermutation::swapPermutation = *p;
      bool printed = false;
      find_all_permutations( table );
      for ( Rank r=0; r<nPermutations; r++ )
      {
        perm_info & pi = table.lookup( r );
        if ( 1 < pi.steps_plus_one )
        {
          Perm p( pi.perm );
          if ( p.preserves_4( ) )
          {
            if ( ! printed )
            {
              cout << MathieuPermutation::swapPermutation << endl;
              printed = true;
            }

            table.print_entry( r );
          }
        }
      }
    }
    
  }
  
  
  table.deallocate( );

#if defined( WIN32 ) && defined( _DEBUG )
  // make sure the memory debugger finds at least one leak
  // Perm *p = new Perm( );
  _CrtDumpMemoryLeaks();
#endif   /* defined( WIN32 ) && defined( _DEBUG )  */

  return 0;
}
