 #if !defined(__M12PERMTABLE_H_INCLUDED__)
#define __M12PERMTABLE_H_INCLUDED__

#include "m12.h"

typedef M12PermutationWithHistory Perm;

typedef Perm::PermArray PermArray;

typedef M12PermutationWithHistory::HistoryElement HistoryElement;
typedef M12PermutationWithHistory::History History;

const Rank nPermutations = (nBalls) * (nBalls-1) * (nBalls-2) * (nBalls-3) * (nBalls-4);
const int max_history_length = 32;
struct perm_info {
  perm_info(){};
  perm_info( Perm p )
  {
    *this = p;
  };
  bool operator <( const perm_info & other ) const
  {
    return moves < other.moves || moves == other.moves && steps_plus_one < other.steps_plus_one;
  };
  perm_info & operator=(Perm p)
  {
    moves = p.moves( );
    steps_plus_one = p.steps( ) + 1;
    forAllBalls( i ) perm[ i ] = p[ i ];
    const History p_history=p.getHistory( );
    history_length = p.history_length( );
    assert( history_length <= max_history_length );
    for( int i=0; i < history_length; i++ )
      history[ i ] = p_history[ i ];
  };
  bool is_all_2_cycles( )
  {
    forAllBalls( i )
      if ( ! ( perm[ perm[ i ] ] == i && perm[ i ] != i ) )
        return false;
    return true;
  }
  Index moves;
  Index steps_plus_one;
  PermArray perm;
  short history_length;
  HistoryElement history[ max_history_length ];
};

typedef enum load_result
{
  load_no_data         = -3 ,
  load_wrong_size_file = -2 ,
  load_no_file         = -1 ,
  load_success         =  0 ,
};

typedef enum dump_result
{
  dump_no_data         = -3 ,
  dump_write_failed    = -2 ,
  dump_no_file         = -1 ,
  dump_success         =  0 ,
};

typedef enum map_attachment_type
{
  map_attach_not_mapped ,
  map_attach_read_only  ,
  map_attach_new        ,
  map_attach_write      ,
  map_attach_update     ,
  map_attach_copy       ,
};


typedef enum map_result
{
  map_result_wrong_size_file = -3,
  map_result_no_file         = -2,
  map_result_mapping_failed  = -1,
  map_result_success         =  0,
};

typedef enum sync_result
{
  sync_result_success =  0,
  sync_result_failed  = -1,
};


class M12PermInfoTable
{
public:
  M12PermInfoTable( )
  : table( NULL ),
    table_attachment_type( map_attach_not_mapped )
  { };
  load_result load( const char * filename );
  dump_result dump( const char * filename );
  map_result map( const char * filename, map_attachment_type attachment_type );
  sync_result sync( );
  void unmap( );
  void print_entry( Rank r );
  void print( );
  void clear( ) { memset( table, 0, perm_table_size ); };
  bool valid( const Perm & p );
  perm_info & lookup( const Perm & p );
  perm_info & lookup( const Rank r ) { return table[ r ]; };
  M12PermutationWithHistory lookup_shortest_inverse( const Perm & p );
  M12PermutationWithHistory lookup_shortest_inverse( const Rank r );
  M12PermutationWithHistory lookup_next_move( const Perm & p );
  M12PermutationWithHistory lookup_next_move( const Rank r );
  ~M12PermInfoTable( ) { deallocate( ) ; } ;
  M12PermInfoTable & allocate( ) { table = static_cast< perm_info *>( malloc( perm_table_size ) ) ; return *this ;} ;
  M12PermInfoTable & deallocate( ) { if ( table ) free( table ) ; table = NULL ; return *this ; } ;
  static const int perm_table_size = nPermutations * sizeof( perm_info ) ;
protected:
  void _try_move( const Perm & p, const M12PermutationWithHistory & this_move,
                  perm_info & best_perm_info, M12PermutationWithHistory & best_move );
  map_attachment_type table_attachment_type;
  perm_info * table;
};
#endif /* !defined(__M12PERMTABLE_H_INCLUDED__) */
