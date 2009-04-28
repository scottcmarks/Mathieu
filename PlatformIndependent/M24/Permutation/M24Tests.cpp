

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <iostream>
#include <sstream>
#include <cstdlib>
using namespace std;

#include "view.h"

typedef MathieuPermutationWithHistory Perm;
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
  static PermArray swap_perm = {  1,  0, 23,  4,  3, 22, 11,  8,  7, 10,  9,  6, 21, 14, 13, 20, 17, 16, 19, 18, 15, 12,  5,  2 } ;
  static Perm S( swap_perm );
  static PermArray right_perm= {  0, 23,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 };
  static Perm R( right_perm );

  Perm m24, id24;

  assert( id24.is_identity( ) );
  assert_history( m24, L"" );

  m24.swap( );
  assert( m24 == swap_perm );
  assert( !m24.is_identity( ) );
  //  cout << "After swap, m24.getHistory is: " << str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"S" );

  m24.reset( );
  assert( m24.is_identity( ) );
  //  cout << "After reset, m24.getHistory is: " << str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"" );

  m24.right( );
  assert( m24 == right_perm );
  assert( !m24.is_identity( ) );
  //  cout << "After right, m24.getHistory is: " << str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"R" );

  for (int i=2; i<nBalls; i++) m24.right( );
  assert( m24.is_identity( ) );
  //  cout << "After right^" << (nBalls-1) << ", " 
  //       << "m24.getHistory is: " << str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"" );
   
  m24.swap( ).swap( );
  assert( m24.is_identity( ) );
  //  cout << "After swap*swap, m24.getHistory is: "<< str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"" );


  m24.right( ).left( );
  assert( m24.is_identity( ) );
  //  cout << "After right*left, m24.getHistory is: "<< str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"" );

  m24.left( ).right( );
  assert( m24.is_identity( ) );
  //  cout << "After left*right, m24.getHistory is: "<< str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"" );

  m24.right( ).swap( ).right( ).swap( ).right( ).swap( );
  assert( m24.is_identity( ) );
  //  cout << "After right*swap*right*swap*right*swap, " 
  //       << "m24.getHistory is: "<< str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"RSRSRS" );
  assert( m24.moves( ) == 6 );
  assert( m24.steps( ) == 6 );

  m24.reset( );
  m24.right( ).swap( );
  //  cout << "After right*swap, m24.getHistory is: "<< str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"RS" );

  History rs = m24.getHistory( );
  //  cout << "rs is: " << str( rs ) << endl;
  assert( wstr( rs ) == L"RS" );

  m24.run( rs ).run( rs );
  assert( m24.is_identity( ) );
  //  cout << "After run(rs).run(rs), m24.getHistory is: " << str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"RSRSRS" );
  
  m24.undo( ).undo( ).undo( ).undo( ).undo( );
  assert( m24 == right_perm );
  assert( !m24.is_identity( ) );
  //  cout << "After undo^5, m24.getHistory is: " << str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"R" );

  R.reset( ).right( );
  S.reset( ).swap( );
  m24 = R*S*R*S*R*S;
  assert( m24.is_identity( ) );
  //  cout << "m24=R*S*R*S*R*S, m24.getHistory is: " << str( m24.getHistory( ) ) << endl;
  assert_history( m24, L"RSRSRS" );
  
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

  m24.set_macro( 'A', R7SR9SR7 );
  
  m24.reset( );
  
  m24.run_macro( 'A', false );
  
  assert( m24 == R7SR9SR7 );
  
  assert_history( m24, L"A" );
  
  m24.run_macro( 'A', true );
  
  assert( m24.is_identity( ) );
  
  m24.run_macro( 'A', true );
  
  assert( !m24.is_identity( ) );
  
  assert_history( m24, L"A\x207B\x00B9" );
  
  serialization.seekp( 0 );
  
  m24.serialize( serialization );
  
  s = serialization.str( );
  
  serialization.seekg( 0 );
  
  MathieuPermutationWithHistory m24_2( serialization );
  
  assert( m24 == m24_2 );
  
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

  m24.reset( );

  m24.right( ).right( );
  
  m24.set_macro( 'A', m24 );
  
  m24.run_macro( 'A' ).run_macro( 'A' );
  
  assert_history( m24, L"R2AA" );
  
  m24.undo( );
  
  assert_history( m24, L"R2A" );
  
  m24.set_macro( 'A', m24 );
  
  assert_history( m24, L"R4" );
  
  m24.run_macro( 'A' ).run_macro( 'A' );
  
  assert_history( m24, L"R4AA" );
  
  m24.set_macro( 'B', m24 );
  
  m24.run_macro( 'B' ).run_macro( 'B' ).run_macro( 'B' );
  
  assert_history( m24, L"R4AABBB" );
  
  m24.set_macro( 'A', m24 );
  
  assert_history( m24, L"R12BBB" );
  
  m24.reset( ).run_macro( 'A' ).set_macro( 'A', m24 );
  
  assert_history( m24, L"R12BBB" );
  
  m24.reset( ).run_macro( 'B' ).set_macro( 'B', m24 );
  
  assert_history( m24, L"R12" );
  
  m24.reset( ).run_macro( 'A' ).set_macro( 'A', m24 );
  
  assert_history( m24, L"R2" );
  

  return EXIT_SUCCESS;
}
