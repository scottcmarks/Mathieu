#include <iostream>
#include <list>
#include <vector>
#include <split>
using namespace std;

#include <getopt.h>

#include "M12PermTable.h"
#include "view.h"
#include "rand_utils.h"
#include "ParsePermutations.h"

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


bool html_output = false;

struct request
{
  bool is_permutation;
  union{ PermArray p; Rank n; } req;
};

typedef bool request_generator( request & r );

typedef list< request > saved_requests_list;

saved_requests_list saved_requests;

void fill_out_permutation_number_request( request & r, const Rank n_permutation )
{
  r.is_permutation = false;
  r.req.n = n_permutation ;
}

void save_permutation_number_request( const Rank n_permutation )
{
  request r;
  fill_out_permutation_number_request( r, n_permutation );
  saved_requests.push_back( r ) ;
}




string permutation_index_delimiters = " \t+,";

bool parse_permutation( string s, PermArray & permutation )
{
  vector< string > items = split( s, permutation_index_delimiters );
  if ( ! ( items.size( ) == nBalls ) )
    return false;
  return parse_permutation_items( items, permutation );
}

void fill_out_permutation_request( request & r, PermArray & permutation )
{
  r.is_permutation = true;
  forAllBalls(i)
    r.req.p[ i ] = permutation[ i ];
}

void save_permutation_request( PermArray & permutation )
{
  request r;
  fill_out_permutation_request( r, permutation );
  saved_requests.push_back( r );
}

bool parse_requests_from_stdin( request & r )
{

  string s;
  if ( !getline( cin, s ) )
    return false;

  vector< string >items = split(s, permutation_index_delimiters );
  if ( 1 == items.size( ) )
  {
    Rank n_permutation;
    if ( parse_permutation_number( s, n_permutation, nPermutations ) )
      fill_out_permutation_number_request( r, n_permutation );
  }
  else if ( nBalls == items.size( ) )
  {
    PermArray permutation;
    if ( parse_permutation( s, permutation ) )
      fill_out_permutation_request( r, permutation );
  }
  else
  {
    cerr << "Input neither a permutation number nor a permutation: " << s << endl;
    cout << "??" << endl;
    return false;
  }
  return true;
}

bool use_saved_requests( request & r )
{
  if ( saved_requests.empty( ) )
    return false;
  r = saved_requests.front( );
  saved_requests.pop_front( );
  return true;
}

int process_permutation_request( const PermArray & a, M12PermInfoTable & table )
{
  int result = 0 ;

  if ( html_output )
    cout << "<html>" << endl << "<body>" << endl;

  Perm pa( a );
  if ( table.valid( pa ) )
  {
    M12PermutationWithHistory pinv = table.lookup_shortest_inverse( pa );
    M12PermutationWithHistory p = pinv.inverse( );
    if ( discreet <= verbosity )
      cout << str( pinv.getHistory( ) ) << " " << pinv << " = pinv  p = " << p << " " << str( p.getHistory( ) )
          << endl;
    else
      cout << str( pinv.getHistory( ) ) << endl;
  }
  else
  {
    cerr << "Permutation " << pa << " is not an M12 permutation." << endl;
    cout << "??" << endl;
    result = 1;
  }

  if ( html_output )
    cout << "</body>" << endl << "</html>" << endl;

  return result;
}

int process_permutation_number_request( Rank n_permutation, M12PermInfoTable & table )
{
  M12PermutationWithHistory pinv = table.lookup_shortest_inverse( n_permutation );
  M12PermutationWithHistory p = pinv.inverse( );
  if ( discreet <= verbosity )
    cout << str( pinv.getHistory( ) ) << " " << pinv << " = pinv  p = " << p << " " << str( p.getHistory( ) )
        << endl;
  else
    cout << str( pinv.getHistory( ) ) << endl;
  return 0;
}


int process_request( const request & r, M12PermInfoTable & table )
{
  if ( r.is_permutation )
    return process_permutation_request( r.req.p, table );
  else
    return process_permutation_number_request( r.req.n, table );
}


int process_requests( M12PermInfoTable & table )
{
  int result = 0;

  request_generator * g = saved_requests.empty( ) ? parse_requests_from_stdin : use_saved_requests;

  for( request r ; (*g)( r ) ; )
    result |= process_request( r, table );

  return result;
}



int usage( char *argv[], int return_code )
{
  ostream & os = return_code == 0 ? cout : cerr;
  os << "usage: " << argv[ 0 ] << " [OPTION]... [FILE]" << endl
      << "M12Permutation lookup" << endl
      << "Example: " << argv[ 0 ] << " -p 1,23,4,3,22,11,8,7,10,9,6,21,14,13,20,17,16,19,18,15,12,5,2,0" << endl
      << "Example: " << argv[ 0 ] << " -n 10663728" << endl
      << "Example: " << argv[ 0 ] << endl
      << endl
      << "Options:" << endl
      << "  -p, --permutation=P0,...,P23   look up the permutation {P0 ... P23}" << endl
      << "  -n, --number=NUM               look up permutation NUM" << endl
      << "  -v, --verbose                  more output (normally quiet);  repeat for increased chattiness" << endl
      << "  -w, --web                      surround output in <html><body> ... </body></html> brackets for CGI" <<endl
      << "  -h, --help                     print this message and quit" << endl
      << endl
      << "[FILE] defaults to Perms.bin" << endl
      << "-p and -n can be repeated" << endl
      << "if neither -p nor -n, read standard input" << endl
      << "    wherein each line should be a permutation" << endl
      << "        or a single permutation number" << endl
      << endl
      << "Normal (quiet) output for a permutation is a history for that permutation" << endl
      << "                  and for a permutation is the permutation." << endl
      << "Verbose output for either is the permuation, its inverse and a history of that inverse." << endl
      << endl
      << "Return code is nonzero if a specified permutation is not an M12 permutation" << endl
      << "or if the specified number is not between 0 and the max M12 permutation number (" << ( nPermutations - 1 )  << ")" << endl;
      return return_code;
}

int main(int argc, char *argv[])
{

  int c;
  struct option long_options[] =
  {
    {"verbose",       no_argument,       0, 'v'},
    {"help",          no_argument,       0, 'h'},
    {"web",           no_argument,       0, 'w'},
    {"permutation",   required_argument, 0, 'p'},
    {"number",        required_argument, 0, 'n'},
    {0, 0, 0, 0}
  };

  srand( 0 ) ;

  int option_index = 0;
  while (! ( -1 == ( c = getopt_long (argc, argv, "vhwn:p:",
     long_options, &option_index) ) ) )
    switch (c)
  {

    case 'v':
      increase_verbosity( );
      break;

    case 'h':
      return usage( argv, 0 );

    case 'w':
      html_output = true;
      break;

    case 'n':
      Rank n_permutation ;

      if ( ! ( parse_permutation_number( optarg, n_permutation, nPermutations ) ) )
        return usage( argv, 2 );
      save_permutation_number_request( n_permutation );
      break;

    case 'p':
      PermArray permutation;

      if ( !( parse_permutation( optarg, permutation ) ) )
        return usage( argv, 2 );
      save_permutation_request( permutation );
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

  switch ( table.map( filename.data( ), map_attach_read_only ) )
  {
    case map_result_no_file:
      cerr << "Can't find permutation info table file " << filename << endl;
      return usage( argv, 1 );

    case map_result_wrong_size_file:
      cerr << "File " << filename << " is the wrong size for a permutation info table file" << endl;
      return usage( argv, 1 );

    case map_result_mapping_failed:
      cerr << "Can't map file " << filename << " into memory as permutation info table pointer" << endl;
      return usage( argv, 1 );

    case map_result_success:
      break;
  }

  int result = process_requests( table ) << 4;

  table.unmap( );

  return result;
}
