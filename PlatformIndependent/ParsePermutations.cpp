#include <sstream>
#include <iostream>

using namespace std;

#include "ParsePermutations.h"

typedef Permutation::PermArray PermArray;

bool parse_permutation_number( string s, Rank & n_permutation, const Rank nPermutations )
{
  stringstream ss ( s );
  ss >> n_permutation;
  if ( ss.fail( ) )
  {
    cerr << "Error convertion permutation number: " << s << endl;
    cout << "??" << endl;
    return false;
  }
  if ( ! ( 0 <= n_permutation && n_permutation < nPermutations ) )
  {
    cerr << "Permutation number is " << s << " but should be non-negative and less than " << nPermutations << endl;
    cout << "??" << endl;
    return false;
  }
  return true;
}

bool parse_permutation_items( const vector< string > & items, PermArray & permutation )
{
  forAllBalls( i )
  {
    stringstream si( items[ i ] );
    int pi;
    si >> pi;
    if ( si.fail( ) )
    {
      cerr << "Error convertion permutation index: " << items[ i ] << endl;
      cout << "??" << endl;
      return false;
    }
    if ( ! ( 0 <= pi && pi < nBalls ) )
    {
      cerr << "Permutation index is " << items[ i ] << " but should be non-negative and less than " << nBalls << endl;
      cout << "??" << endl;
      return false;
    }
    permutation[ i ] = pi;
  }
  return true;
}
