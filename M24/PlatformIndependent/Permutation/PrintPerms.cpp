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
#include <string>
using namespace std;

#include <getopt.h>


#include "M24PermTable.h"
#include "view.h"


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

int usage( char *argv[], int return_code )
{
  ostream & os = return_code == 0 ? cout : cerr;
  os << "usage: " << argv[ 0 ] << " -h | --help  [permutations file name]" << endl;
  return return_code;
}

int main(int argc, char *argv[])
{
  int c;
  struct option long_options[] =
  {
    {"help",      no_argument,       0, 'h'},
    {0, 0, 0, 0}
  };

  int option_index = 0;
  while (! ( -1 == ( c = getopt_long (argc, argv, "h",
              long_options, &option_index) ) ) )
    switch (c)
    {
      case 'h':
        return usage( argv, 0 );

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
  
  M24PermInfoTable table;
  
  table.map( filename.data( ), map_attach_read_only );
  
  table.print( );

  table.unmap( );

#if defined( WIN32 ) && defined( _DEBUG )
  // make sure the memory debugger finds at least one leak
  // M24Permutation *p = new M24Permutation( );
  _CrtDumpMemoryLeaks();
#endif   /* defined( WIN32 ) && defined( _DEBUG )  */

  return 0;
}
