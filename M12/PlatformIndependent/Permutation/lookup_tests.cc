#include <iostream>
using namespace std;

#include <getopt.h>

#include "M12PermTable.h"
#include "view.h"
#include "rand_utils.h"

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

const int default_n_random_tests = 1000;
int n_random_tests = default_n_random_tests;

bool test( const Perm & p, M12PermInfoTable & table  )
{
  M12PermutationWithHistory pinv = table.lookup_shortest_inverse( p );
  bool result = ( p * pinv ).is_identity( );
  if ( ! result )
    cout << p << " = p  pinv = " << pinv << " " << str( pinv.getHistory( ) )
         << " *** failed!"
         << endl << flush;
  else if ( discreet <= verbosity )
    cout << p << " = p  pinv = " << pinv << " " << str( pinv.getHistory( ) )
         << endl;
  return result;
}


typedef bool testfn( M12PermInfoTable & table );

bool test_RSRS( M12PermInfoTable & table )
{
  return test( Perm( ).right( ).swap( ).right( ).swap( ),
               table );
}

bool test_bug1( M12PermInfoTable & table )
{
  Perm::PermArray p={  1,  0, 11,  6,  5,  4,  3, 10,  9,  8,  7,  2 };
  return test( Perm( p ), table );
}



bool test_R7SR9SR7( M12PermInfoTable & table )
{
  return test( Perm( ).right( 7 ).swap( ).right( 9 ).swap( ).right( 7 ),
               table );
}

bool test_one_random( bool amnesia, M12PermInfoTable & table  )
{
  M12PermutationWithHistory p;
  p.random( amnesia );
  if ( ! amnesia ) cout << str( p.getHistory( ) ) << " ";
  return test( p, table );
}


bool test_random( M12PermInfoTable & table )
{
  bool result = true;
  bool amnesia = true;
  for ( int i=0; i < n_random_tests ; i++ )
    result &= test_one_random( amnesia, table );
  return result;
}


int run_tests( M12PermInfoTable & table )
{
  int result = 0;

  testfn * tests[ ] = {
    test_RSRS,
    test_R7SR9SR7,
    test_bug1,
    test_random,
  };

  for ( int i = 0 ; i < sizeof( tests )/sizeof( tests[ 0 ] ); i++ )
    if (! (*tests[ i ])( table ) )
      result |= ( 1 << i ) ;

  return result;
}



int usage( char *argv[], int return_code )
{
  ostream & os = return_code == 0 ? cout : cerr;
  os << "usage: " << argv[ 0 ] << " [OPTION]... [FILE]" << endl
     << "Test M12Permutation lookup" << endl
     << "Example: " << argv[ 0 ] << " -r Perms.bin" << endl
     << endl
     << "Options:" << endl
     << "  -r, --random       initialize random number generator (otherwise srand(0))" << endl
     << "  -n, --nrandom=NUM  run NUL random tests (defaults to 1000)" << endl
     << "  -v, --verbose      more output (normally quiet);  repeat for increased chattiness" << endl
     << "  -h, --help         print this message and quit" << endl
     << endl
     << "[FILE] defaults to Perms.bin" << endl;
  return return_code;
}

int main(int argc, char *argv[])
{
  int c;
  struct option long_options[] =
  {
    {"verbose",   no_argument,       0, 'v'},
    {"help",      no_argument,       0, 'h'},
    {"nrandom",   required_argument, 0, 'n'},
    {"random",    no_argument,       0, 'r'},
    {0, 0, 0, 0}
  };

  srand( 0 ) ;

  int option_index = 0;
  while (! ( -1 == ( c = getopt_long (argc, argv, "vhn:r",
              long_options, &option_index) ) ) )
    switch (c)
    {

      case 'v':
        increase_verbosity( );
        break;

      case 'h':
        return usage( argv, 0 );

      case 'n':
        n_random_tests = atoi(optarg) ;
        if ( ! ( 0 < n_random_tests ) )
        {
          cerr << "nrandom must be between positive, but was given as " << n_random_tests << endl;
          return usage( argv, 2 );
        }
        break;

      case 'r':
        initialize_rand( );
        break;

      case '?':
      default:
        return usage( argv, 1 );
    }


  string filename;
  if ( optind < argc )   // there are command line arguments left
  {
    if ( !( optind == argc - 1 ) )
      return usage( argv, 2 );
    filename = argv[ optind ];
  }
  else
    filename = "Perms.bin";

  M12PermInfoTable table;

  table.map( filename.data( ), map_attach_read_only );

  int result = run_tests( table ) << 4;

  table.unmap( );

  return result;
}
