

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <iostream>
#include <sstream>
#include <cstdlib>
using namespace std;

#include "view.h"

typedef M12PermutationWithHistory Perm;
typedef Perm::PermArray PermArray;
typedef Perm::History History;

void assert_history( const Perm & p, const wchar_t * s )
{
  wstring history = wstr( p.getHistory( ) );
  if ( history != s )
      assert( history == s );
}

int main(int argc, char *argv[])
{
  static PermArray swap_perm = {  1,  0,  5,  8, 11,  2, 10,  9,  3,  7,  6,  4 } ;
  static Perm S( swap_perm );
  static PermArray right_perm= {  0, 11,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10 };
  static Perm R( right_perm );

  Perm m12, id12;

  assert( id12.is_identity( ) );
  assert_history( m12, L"" );

  m12.swap( );
  assert( m12 == swap_perm );
  assert( !m12.is_identity( ) );
  //  cout << "After swap, m12.getHistory is: " << str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"S" );

  m12.reset( );
  assert( m12.is_identity( ) );
  //  cout << "After reset, m12.getHistory is: " << str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"" );

  m12.right( );
  assert( m12 == right_perm );
  assert( !m12.is_identity( ) );
  //  cout << "After right, m12.getHistory is: " << str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"R" );

  for (int i=2; i<nBalls; i++) m12.right( );
  assert( m12.is_identity( ) );
  //  cout << "After right^" << (nBalls-1) << ", "
  //       << "m12.getHistory is: " << str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"" );

  m12.swap( ).swap( );
  assert( m12.is_identity( ) );
  //  cout << "After swap*swap, m12.getHistory is: "<< str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"" );


  m12.right( ).left( );
  assert( m12.is_identity( ) );
  //  cout << "After right*left, m12.getHistory is: "<< str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"" );

  m12.left( ).right( );
  assert( m12.is_identity( ) );
  //  cout << "After left*right, m12.getHistory is: "<< str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"" );

  /**tests below are commented out

  m12.right( ).swap( ).right( ).swap( ).right( ).swap( );
  assert( m12.is_identity( ) );
  //  cout << "After right*swap*right*swap*right*swap, "
  //       << "m12.getHistory is: "<< str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"RSRSRS" );
  assert( m12.moves( ) == 6 );
  assert( m12.steps( ) == 6 );

  m12.reset( );
  m12.right( ).swap( );
  //  cout << "After right*swap, m12.getHistory is: "<< str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"RS" );

  History rs = m12.getHistory( );
  //  cout << "rs is: " << str( rs ) << endl;
  assert( wstr( rs ) == L"RS" );

  m12.run( rs ).run( rs );
  assert( m12.is_identity( ) );
  //  cout << "After run(rs).run(rs), m12.getHistory is: " << str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"RSRSRS" );

  m12.undo( ).undo( ).undo( ).undo( ).undo( );
  assert( m12 == right_perm );
  assert( !m12.is_identity( ) );
  //  cout << "After undo^5, m12.getHistory is: " << str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"R" );

  R.reset( ).right( );
  S.reset( ).swap( );
  m12 = R*S*R*S*R*S;
  assert( m12.is_identity( ) );
  //  cout << "m12=R*S*R*S*R*S, m12.getHistory is: " << str( m12.getHistory( ) ) << endl;
  assert_history( m12, L"RSRSRS" );

  Perm R7SR9SR7 = R*R*R*R*R*R*R * S * R*R*R*R*R*R*R*R*R * S * R*R*R*R*R*R*R ;
  //  cout << "R7SR9SR7=R*R*R*R*R*R*R * S * R*R*R*R*R*R*R*R*R * S * R*R*R*R*R*R*R, R7SR9SR7.getHistory is: " << str( R7SR9SR7.getHistory( ) ) << endl;
  assert_history( R7SR9SR7, L"R7SR9SR7" );
  assert( R7SR9SR7.moves( ) == 5 );
  assert( R7SR9SR7.steps( ) == 25 );

  stringstream serialization( stringstream::in | stringstream::out | ios::binary );

  R7SR9SR7.serialize( serialization );

  Perm R7SR9SR7_2( serialization );

  assert ( R7SR9SR7 == R7SR9SR7_2 );

  string s = serialization.str( );

  assert ( s.length( ) == 38
      && s[  0 ] == 24    // nBalls == 24
      && s[  1 ] == 13    // permutation[  0 ]
      && s[  2 ] ==  1    // permutation[  1 ]
      && s[  3 ] ==  2    // permutation[  2 ]
      && s[  4 ] ==  3    // permutation[  3 ]
      && s[  5 ] ==  4    // permutation[  4 ]
      && s[  6 ] == 20    // permutation[  5 ]
      && s[  7 ] == 11    // permutation[  6 ]
      && s[  8 ] == 10    // permutation[  7 ]
      && s[  9 ] == 17    // permutation[  8 ]
      && s[ 10 ] ==  6    // permutation[  9 ]
      && s[ 11 ] == 12    // permutation[ 10 ]
      && s[ 12 ] ==  9    // permutation[ 11 ]
      && s[ 13 ] ==  7    // permutation[ 12 ]
      && s[ 14 ] == 16    // permutation[ 13 ]
      && s[ 15 ] == 21    // permutation[ 14 ]
      && s[ 16 ] ==  5    // permutation[ 15 ]
      && s[ 17 ] ==  0    // permutation[ 16 ]
      && s[ 18 ] == 18    // permutation[ 17 ]
      && s[ 19 ] ==  8    // permutation[ 18 ]
      && s[ 20 ] == 14    // permutation[ 19 ]
      && s[ 21 ] == 15    // permutation[ 20 ]
      && s[ 22 ] == 19    // permutation[ 21 ]
      && s[ 23 ] == 22    // permutation[ 22 ]
      && s[ 24 ] == 23    // permutation[ 23 ]
      && s[ 25 ] ==  5    // history.size( ) == 5
      && s[ 26 ] ==  0    //    .
      && s[ 27 ] ==  0    //    .
      && s[ 28 ] ==  0    //    .
      && s[ 29 ] ==  7    // R7
      && s[ 30 ] ==  0    // S
      && s[ 31 ] ==  9    // R9
      && s[ 32 ] ==  0    // S
      && s[ 33 ] ==  7    // R7
      && s[ 34 ] ==  0    // history.macros.size( ) == 0
      && s[ 35 ] ==  0    //    .
      && s[ 36 ] ==  0    //    .
      && s[ 37 ] ==  0    //    .
         );

  m12.set_macro( 'A', R7SR9SR7 );

  m12.reset( );

  m12.run_macro( 'A', false );

  assert( m12 == R7SR9SR7 );

  assert_history( m12, L"A" );

  m12.run_macro( 'A', true );

  assert( m12.is_identity( ) );

  m12.run_macro( 'A', true );

  assert( !m12.is_identity( ) );

  assert_history( m12, L"A\x207B\x00B9" );

  serialization.seekp( 0 );

  m12.serialize( serialization );

  s = serialization.str( );

  serialization.seekg( 0 );

  M12PermutationWithHistory m12_2( serialization );

  assert( m12 == m12_2 );

  assert( s.length( ) == 73
      && s[  0 ] ==  24    // nBalls == 24
      && s[  1 ] ==  16    // permutation[  0 ]
      && s[  2 ] ==   1    // permutation[  1 ]
      && s[  3 ] ==   2    // permutation[  2 ]
      && s[  4 ] ==   3    // permutation[  3 ]
      && s[  5 ] ==   4    // permutation[  4 ]
      && s[  6 ] ==  15    // permutation[  5 ]
      && s[  7 ] ==   9    // permutation[  6 ]
      && s[  8 ] ==  12    // permutation[  7 ]
      && s[  9 ] ==  18    // permutation[  8 ]
      && s[ 10 ] ==  11    // permutation[  9 ]
      && s[ 11 ] ==   7    // permutation[ 10 ]
      && s[ 12 ] ==   6    // permutation[ 11 ]
      && s[ 13 ] ==  10    // permutation[ 12 ]
      && s[ 14 ] ==   0    // permutation[ 13 ]
      && s[ 15 ] ==  19    // permutation[ 14 ]
      && s[ 16 ] ==  20    // permutation[ 15 ]
      && s[ 17 ] ==  13    // permutation[ 16 ]
      && s[ 18 ] ==   8    // permutation[ 17 ]
      && s[ 19 ] ==  17    // permutation[ 18 ]
      && s[ 20 ] ==  21    // permutation[ 19 ]
      && s[ 21 ] ==   5    // permutation[ 20 ]
      && s[ 22 ] ==  14    // permutation[ 21 ]
      && s[ 23 ] ==  22    // permutation[ 22 ]
      && s[ 24 ] ==  23    // permutation[ 23 ]
      && s[ 25 ] ==   1    // history.size( ) == 1
      && s[ 26 ] ==   0    //    .
      && s[ 27 ] ==   0    //    .
      && s[ 28 ] ==   0    //    .
      && s[ 29 ] == -65    // A-1
      && s[ 30 ] ==   1    // history.macros.size( ) == 1
      && s[ 31 ] ==   0    //    .
      && s[ 32 ] ==   0    //    .
      && s[ 33 ] ==   0    //    .
      && s[ 34 ] ==  65    // 'A'
      && s[ 35 ] ==  24    // nBalls == 24
      && s[ 36 ] ==  13    // permutation[  0 ]
      && s[ 37 ] ==   1    // permutation[  1 ]
      && s[ 38 ] ==   2    // permutation[  2 ]
      && s[ 39 ] ==   3    // permutation[  3 ]
      && s[ 40 ] ==   4    // permutation[  4 ]
      && s[ 41 ] ==  20    // permutation[  5 ]
      && s[ 42 ] ==  11    // permutation[  6 ]
      && s[ 43 ] ==  10    // permutation[  7 ]
      && s[ 44 ] ==  17    // permutation[  8 ]
      && s[ 45 ] ==   6    // permutation[  9 ]
      && s[ 46 ] ==  12    // permutation[ 10 ]
      && s[ 47 ] ==   9    // permutation[ 11 ]
      && s[ 48 ] ==   7    // permutation[ 12 ]
      && s[ 49 ] ==  16    // permutation[ 13 ]
      && s[ 50 ] ==  21    // permutation[ 14 ]
      && s[ 51 ] ==   5    // permutation[ 15 ]
      && s[ 52 ] ==   0    // permutation[ 16 ]
      && s[ 53 ] ==  18    // permutation[ 17 ]
      && s[ 54 ] ==   8    // permutation[ 18 ]
      && s[ 55 ] ==  14    // permutation[ 19 ]
      && s[ 56 ] ==  15    // permutation[ 20 ]
      && s[ 57 ] ==  19    // permutation[ 21 ]
      && s[ 58 ] ==  22    // permutation[ 22 ]
      && s[ 59 ] ==  23    // permutation[ 23 ]
      && s[ 60 ] ==   5    // history.size( ) == 5
      && s[ 61 ] ==   0    //    .
      && s[ 62 ] ==   0    //    .
      && s[ 63 ] ==   0    //    .
      && s[ 64 ] ==   7    // R7
      && s[ 65 ] ==   0    // S
      && s[ 66 ] ==   9    // R9
      && s[ 67 ] ==   0    // S
      && s[ 68 ] ==   7    // R7
      && s[ 69 ] ==   0    // history.macros.size( ) == 0
      && s[ 70 ] ==   0    //    .
      && s[ 71 ] ==   0    //    .
      && s[ 72 ] ==   0    //    .
        );

  m12.reset( );

  m12.right( ).right( );

  m12.set_macro( 'A', m12 );

  m12.run_macro( 'A' ).run_macro( 'A' );

  assert_history( m12, L"R2AA" );

  m12.undo( );

  assert_history( m12, L"R2A" );

  m12.set_macro( 'A', m12 );

  assert_history( m12, L"R4" );

  m12.run_macro( 'A' ).run_macro( 'A' );

  assert_history( m12, L"R4AA" );

  m12.set_macro( 'B', m12 );

  m12.run_macro( 'B' ).run_macro( 'B' ).run_macro( 'B' );

  assert_history( m12, L"R4AABBB" );

  m12.set_macro( 'A', m12 );

  assert_history( m12, L"R12BBB" );

  m12.reset( ).run_macro( 'A' ).set_macro( 'A', m12 );

  assert_history( m12, L"R12BBB" );

  m12.reset( ).run_macro( 'B' ).set_macro( 'B', m12 );

  assert_history( m12, L"R12" );

  m12.reset( ).run_macro( 'A' ).set_macro( 'A', m12 );

  assert_history( m12, L"R2" );


  **/ // end of commented-out tests

  return EXIT_SUCCESS;
}
