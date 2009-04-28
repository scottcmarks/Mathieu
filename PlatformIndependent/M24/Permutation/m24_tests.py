from m24 import *
from StringIO import StringIO

left_tag  = 'L'
swap_tag  = 'S'
right_tag = 'R'

def _insert_count( f, tag,  count ):
    f.write( str( tag ) )
    if ( 1 < count ):
        f.write( str( count ) )
    return f


def _insert_left( f, count ):
    return insert_count( f, left_tag, count )

def _insert_swap( f ):
    f.write( str( swap_tag ) )
    return f

def _insert_right( f, count ):
    return _insert_count( f, right_tag, count )

def _str( h ):
    f = StringIO( )
    h.insert( f, _insert_left, _insert_swap, _insert_right )
    result = f.getvalue( )
    f.close( )
    return result

M24Permutation.History.__str__ = _str

def test( ):
    swapPermutation  = M24Permutation( M24Permutation.PermArray(  1,  0, 23,  4,  3, 22, 11,  8,  7, 10,  9,  6, 21, 14, 13, 20, 17, 16, 19, 18, 15, 12, 5,  2 ) )
    rightPermutation = M24Permutation( M24Permutation.PermArray(  0, 23,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 ) )

    m24 = M24Permutation( )
    id24 = M24Permutation( )

    assert ( id24.is_identity( ) )
    assert ( str( m24.getHistory( ) ) == "" )
    m24.swap( )
    assert( m24 == swapPermutation )
    assert( not m24.is_identity( ) )

    assert( str( m24.getHistory( ) ) == "S" )

    m24.reset( )
    assert( m24.is_identity( ) )

    assert( str( m24.getHistory( ) ) == "" )

    m24.right( )
    assert( m24 == rightPermutation )
    assert( not m24.is_identity( ) )

    assert( str( m24.getHistory( ) ) == "R" )

    for i in range(2, nBalls):
      m24.right( )
    assert( m24.is_identity( ) )


    assert( str( m24.getHistory( ) ) == "" )

    m24.swap( ).swap( )
    assert( m24.is_identity( ) )

    assert( str( m24.getHistory( ) ) == "" )


    m24.right( ).left( )
    assert( m24.is_identity( ) )

    assert( str( m24.getHistory( ) ) == "" )

    m24.left( ).right( )
    assert( m24.is_identity( ) )

    assert( str( m24.getHistory( ) ) == "" )

    m24.right( ).swap( ).right( ).swap( ).right( ).swap( )
    assert( m24.is_identity( ) )


    assert( str( m24.getHistory( ) ) == "RSRSRS" )

    m24.reset( )
    m24.right( ).swap( )

    assert( str( m24.getHistory( ) ) == "RS" )

    rs = m24.getHistory( )

    assert( str( rs ) == "RS" )

    m24.run( rs ).run( rs )
    assert( m24.is_identity( ) )

    assert ( str( m24.getHistory( ) ) == "RSRSRS" )

    m24.undo( ).undo( ).undo( ).undo( ).undo( )
    assert( m24 == rightPermutation )
    assert( not m24.is_identity( ) )

    assert( str( m24.getHistory( ) ) == "R" )

    return 0

if __name__ == "__main__":
    import sys
    sys.exit( test( ) )


