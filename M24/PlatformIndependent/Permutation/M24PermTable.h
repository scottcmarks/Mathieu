#if !defined(__M24PERMTABLE_H_INCLUDED__)
#define __M24PERMTABLE_H_INCLUDED__

#include "m24.h"

#if defined(USE_M24PERMUTATION_WITH_HISTORY)
typedef MathieuPermutationWithHistory Perm;
#else
typedef MathieuPermutationWithHistory::super Perm;
#endif

typedef Perm::PermArray PermArray;

const Rank nPerms_0_to_4 = (nBalls) * (nBalls-1) * (nBalls-2) * (nBalls-3) * (nBalls-4);
const Index nPerms_5_to_6 = 48;

const Rank nPermutations = nPerms_0_to_4 * nPerms_5_to_6;

struct perm_info { 
  perm_info(){};
  perm_info( Index m, Index s )
  : moves(m), steps_plus_one(s)
  {};
  bool operator <( const perm_info & other ) const
  {
    return moves < other.moves || moves == other.moves && steps_plus_one < other.steps_plus_one;
  };
  Index moves; 
  Index steps_plus_one;
};
typedef struct { Index pinv5; Index pinv6; perm_info perms[ nPerms_5_to_6 ]; } table_group;
//typedef table_group perm_table[ nPerms_0_to_4 ];

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


class M24PermInfoTable 
{
public:
  M24PermInfoTable( ) 
  : table( NULL ),
    table_attachment_type( map_attach_not_mapped )
  { };
  load_result load( const char * filename );
  dump_result dump( const char * filename );
  map_result map( const char * filename, map_attachment_type attachment_type );
  sync_result sync( );
  void unmap( );
  void print( );
  void clear( ) { memset( table, 0, perm_table_size ); };
  bool p5_and_p6_valid( const Index p5, const Index p6 )
  {
    return (     5 == p5
             ||  6 < p5 && p5 < 15
             || 15 < p5 && p5 < 18 
             || 18 < p5 )
        && (     6 == p6
             || 15 == p6
             || 18 == p6 ) ;
  };
  bool valid( const Perm & p );
  table_group & lookup_group( const Perm & p );
  perm_info & lookup_in_group( const Perm & p, table_group & group );
  perm_info & lookup( const Perm& p ) { return lookup_in_group( p, lookup_group( p ) ); };
  perm_info & lookup( const Rank r ) { return table[ r / 48 ].perms[ r % 48 ]; };
  MathieuPermutationWithHistory lookup_shortest_inverse( const Perm & p );
  MathieuPermutationWithHistory lookup_shortest_inverse( const Rank r );
  MathieuPermutationWithHistory lookup_next_move( const Perm & p );
  MathieuPermutationWithHistory lookup_next_move( const Rank r );
  ~M24PermInfoTable( ) { deallocate( ) ; } ;
  M24PermInfoTable & allocate( ) { table = static_cast< table_group *>( malloc( perm_table_size ) ) ; return *this ;} ;
  M24PermInfoTable & deallocate( ) { if ( table ) free( table ) ; table = NULL ; return *this ; } ;
  static const int perm_table_size = nPerms_0_to_4 * sizeof( table_group ) ;
protected:
  void _try_move( const MathieuPermutation & p, const MathieuPermutationWithHistory & this_move, 
                  perm_info & best_perm_info, MathieuPermutationWithHistory & best_move );
  map_attachment_type table_attachment_type;
  table_group * table;
};
#endif /* !defined(__M24PERMTABLE_H_INCLUDED__) */
