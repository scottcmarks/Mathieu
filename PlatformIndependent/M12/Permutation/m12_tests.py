from m12 import *
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

M12Permutation.History.__str__ = _str

def test( ):
    swapPermutation  = M12Permutation( M12Permutation.PermArray(  1,  0, 23,  4,  3, 22, 11,  8,  7, 10,  9,  6, 21, 14, 13, 20, 17, 16, 19, 18, 15, 12, 5,  2 ) )
    rightPermutation = M12Permutation( M12Permutation.PermArray(  0, 23,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 ) )

    m12 = M12Permutation( )
    id24 = M12Permutation( )

    assert ( id24.is_identity( ) )
    assert ( str( m12.getHistory( ) ) == "" )
    m12.swap( )
    assert( m12 == swapPermutation )
    assert( not m12.is_identity( ) )

    assert( str( m12.getHistory( ) ) == "S" )

    m12.reset( )
    assert( m12.is_identity( ) )

    assert( str( m12.getHistory( ) ) == "" )

    m12.right( )
    assert( m12 == rightPermutation )
    assert( not m12.is_identity( ) )

    assert( str( m12.getHistory( ) ) == "R" )

    for i in range(2, nBalls):
      m12.right( )
    assert( m12.is_identity( ) )


    assert( str( m12.getHistory( ) ) == "" )

    m12.swap( ).swap( )
    assert( m12.is_identity( ) )

    assert( str( m12.getHistory( ) ) == "" )


    m12.right( ).left( )
    assert( m12.is_identity( ) )

    assert( str( m12.getHistory( ) ) == "" )

    m12.left( ).right( )
    assert( m12.is_identity( ) )

    assert( str( m12.getHistory( ) ) == "" )

    m12.right( ).swap( ).right( ).swap( ).right( ).swap( )
    assert( m12.is_identity( ) )


    assert( str( m12.getHistory( ) ) == "RSRSRS" )

    m12.reset( )
    m12.right( ).swap( )

    assert( str( m12.getHistory( ) ) == "RS" )

    rs = m12.getHistory( )

    assert( str( rs ) == "RS" )

    m12.run( rs ).run( rs )
    assert( m12.is_identity( ) )

    assert ( str( m12.getHistory( ) ) == "RSRSRS" )

    m12.undo( ).undo( ).undo( ).undo( ).undo( )
    assert( m12 == rightPermutation )
    assert( not m12.is_identity( ) )

    assert( str( m12.getHistory( ) ) == "R" )

    return 0

if __name__ == "__main__":
    import sys
    sys.exit( test( ) )


