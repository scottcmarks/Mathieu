#include <iostream>
#include <fstream>
using namespace std;

#include "M12PermTable.h"
#include "view.h"
#include <sys/mman.h>
#include <fcntl.h>

perm_info & M12PermInfoTable::lookup( const Perm & p )
{
  PermArray f;
  Rank r;
  p.compute_indices( f, r );
  return table[ r ];
}

bool M12PermInfoTable::valid( const Perm & p )
{
  perm_info & perm = lookup( p ) ;
  return Perm( perm.perm ) == p;
}


load_result M12PermInfoTable::load( const char * filename )
{
  if ( table == NULL ) return load_no_data;
  ifstream file (filename, ios::in|ios::binary|ios::ate);
  if ( ! ( file.is_open( ) ) ) return load_no_file;
  streamoff size = file.tellg();
  if ( ! ( perm_table_size == size ) )
  {
    file.close();
    return load_wrong_size_file;
  }
  file.seekg (0, ios::beg);
  file.read (reinterpret_cast<char *>(table), size);
  file.close();
  return load_success;
}

dump_result M12PermInfoTable::dump( const char * filename )
{
  if ( table == NULL ) return dump_no_data;
  ofstream file (filename, ios::out|ios::binary|ios::trunc);
  if ( ! ( file.is_open( ) ) ) return dump_no_file;
  file.write (reinterpret_cast<char *>(table), perm_table_size );
  bool bad = file.bad( );
  file.close();
  return bad ? dump_write_failed : dump_success;
}


void M12PermInfoTable::_try_move( const Perm & p, const MathieuPermutationWithHistory & this_move,
                                  perm_info & best_perm_info, MathieuPermutationWithHistory & best_move )
{
  const perm_info & this_perm_info = lookup( p * this_move );
  if ( this_perm_info < best_perm_info )
  {
    best_perm_info = this_perm_info;
    best_move = this_move;
  }
}


MathieuPermutationWithHistory M12PermInfoTable::lookup_next_move( const Perm & p )
{
  perm_info best_perm_info = lookup( p );
  MathieuPermutationWithHistory best_move;

  // See if any right moves improve things
  for ( int i = 1 ; i < nBalls / 2; i++ )
    _try_move( p, MathieuPermutationWithHistory( ).right( i ), best_perm_info, best_move );

  // See if any left moves improve things
  for ( int i = 1 ; i < nBalls / 2; i++ )
    _try_move( p, MathieuPermutationWithHistory( ).left( i ), best_perm_info, best_move );

  // See if a swap move improve things
  _try_move( p, MathieuPermutationWithHistory( ).swap( ), best_perm_info, best_move );

  return best_move;
}


MathieuPermutationWithHistory M12PermInfoTable::lookup_shortest_inverse( const Perm & p )
{
  MathieuPermutation p_reduced( p ); // no history, for speed
  MathieuPermutationWithHistory p_inverse;
  // Invariant: p_reduced == p * p_inverse
  while ( ! p_reduced.is_identity( ) )
  {
    const MathieuPermutationWithHistory & next_move = lookup_next_move( p_reduced );
    if ( next_move.is_identity( ) )
    {
      cout << endl
          << "Stuck!" << endl
          << p << " = p  p_inverse = " << p_inverse << " " << str( p_inverse.getHistory( ) ) << endl
          << "p_reduced = " << p_reduced << endl;
      assert( ! ( next_move.is_identity( ) ) );
    }
    p_reduced *= next_move;
    p_inverse *= next_move;
  }
  return p_inverse;
}


MathieuPermutationWithHistory M12PermInfoTable::lookup_next_move( const Rank r )
{
  perm_info best_perm_info = lookup( r );
  MathieuPermutationWithHistory best_move;
  Perm p;

  cout << "lookup_next_move( const Rank ) not yet implemented." << endl;
  assert( false );

  // See if any right moves improve things
  for ( int i = 1 ; i < nBalls / 2; i++ )
    _try_move( p, MathieuPermutationWithHistory( ).right( i ), best_perm_info, best_move );

  // See if any left moves improve things
  for ( int i = 1 ; i < nBalls / 2; i++ )
    _try_move( p, MathieuPermutationWithHistory( ).left( i ), best_perm_info, best_move );

  // See if a swap move improve things
  _try_move( p, MathieuPermutationWithHistory( ).swap( ), best_perm_info, best_move );

  return best_move;
}


MathieuPermutationWithHistory M12PermInfoTable::lookup_shortest_inverse( Rank r )
{
  Perm p;

  cout << "lookup_shortest_inverse( const Rank ) not yet implemented." << endl;
  assert( false );

  MathieuPermutation p_reduced( p ); // no history, for speed
  MathieuPermutationWithHistory p_inverse;
  // Invariant: p_reduced == p * p_inverse
  while ( ! p_reduced.is_identity( ) )
  {
    const MathieuPermutationWithHistory & next_move = lookup_next_move( p_reduced );
    if ( next_move.is_identity( ) )
    {
      cout << endl
          << "Stuck!" << endl
          << p << " = p  p_inverse = " << p_inverse << " " << str( p_inverse.getHistory( ) ) << endl
          << "p_reduced = " << p_reduced << endl;
      assert( ! ( next_move.is_identity( ) ) );
    }
    p_reduced *= next_move;
    p_inverse *= next_move;
  }
  return p_inverse;
}

void M12PermInfoTable::print_entry( Rank r )
{
  perm_info & perm = table[ r ];
  short steps = perm.steps_plus_one - 1;
  short moves = perm.moves;
  cout << setw( 5 ) << r << " " << setw( 2 ) << moves << setw( 3 ) << steps << ": " ;
  forAllBalls( i ) cout << setw( 3 ) << (int)perm.perm[ i ];
  History h;
  for( int i=0; i < perm.history_length; i++ )
    h.push_back( perm.history[ i ] );
  cout << " " << str( h ) << endl ;
}


void M12PermInfoTable::print( )
{
  for ( Rank r = 0; r < nPermutations ; r++ )
  {
    if ( 0 == table[ r ].steps_plus_one )
      cout << setw( 5 ) << r << "     .  " << endl;
    else
      print_entry( r );
  }
}

map_result M12PermInfoTable::map( const char * filename, map_attachment_type attachment_type )
{
  int oflag;
  int prot;
  int flags;

  switch ( attachment_type )
  {
    case map_attach_read_only:
      oflag = O_RDONLY;
      prot = PROT_READ;
      flags = MAP_PRIVATE;
      break;

    case map_attach_new:
      oflag = O_RDWR | O_CREAT | O_EXCL;
      prot = PROT_READ | PROT_WRITE;
      flags = MAP_SHARED;
      break;


    case map_attach_write:
      oflag = O_RDWR | O_CREAT | O_TRUNC;
      prot = PROT_READ | PROT_WRITE;
      flags = MAP_SHARED;
      break;


    case map_attach_update:
      oflag = O_RDWR;
      prot = PROT_READ | PROT_WRITE;
      flags = MAP_SHARED;
      break;

    case map_attach_copy:
      oflag = O_RDONLY;
      prot = PROT_READ | PROT_WRITE;
      flags = MAP_PRIVATE;
      break;
  }


  switch ( attachment_type )
  {
    case map_attach_read_only:
    case map_attach_update:
    case map_attach_copy:
    {
      // Check file length
      struct stat statbuf;
      if ( ! ( 0 == stat( filename, &statbuf ) ) )
        return map_result_no_file;

      if ( ! ( statbuf.st_size == perm_table_size ) )
        return map_result_wrong_size_file;
    }
    break;
  }

  int fd = open( filename, oflag );
  if ( ! ( fd != -1 ) )
    return map_result_no_file;

  switch ( attachment_type )
  {
    case map_attach_new:
    case map_attach_write:
    {
      // Set file length
      char nul[ 1 ] = { 0 };
      lseek( fd, perm_table_size - 1, SEEK_SET );
      write( fd, nul, 1 );
      lseek( fd,                   0, SEEK_SET );
    }
    break;
  }

  table = static_cast < perm_info *> ( mmap( NULL, perm_table_size, prot, flags, fd, 0 ) );
  if ( ! ( table != NULL ) )
  {
    close( fd );
    return map_result_mapping_failed;
  }

  table_attachment_type = attachment_type;
  return map_result_success;

}

/***

  case map_attach_not_mapped:
  case map_attach_read_only:
  case map_attach_update:
  case map_attach_copy:
  case map_attach_new:
  case map_attach_write:

***/
void M12PermInfoTable::unmap( )
{
  switch( table_attachment_type )
  {
    case map_attach_not_mapped:
      return;

    case map_attach_read_only:
    case map_attach_update:
    case map_attach_copy:
    case map_attach_new:
    case map_attach_write:
      munmap( table, perm_table_size );
      table = NULL ;
      return;
  }
}

sync_result M12PermInfoTable::sync( )
{
  switch ( table_attachment_type )
  {
    case map_attach_not_mapped:
      return sync_result_failed;

    case map_attach_read_only:
    case map_attach_copy:
      table = NULL ;
      return sync_result_success;

    case map_attach_update:
    case map_attach_new:
    case map_attach_write:
    {
      sync_result result =
          msync( table, perm_table_size, MS_SYNC ) == 0
            ? sync_result_success
            : sync_result_failed;
      table = NULL ;
      return result;
    }
  }
}
