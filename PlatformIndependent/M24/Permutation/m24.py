"""
  m24.py
  SporadicM24

  Created by Jackie Marks on 10/15/08.
  Copyright 2008 Magnolia Heights Research and Development.. All rights reserved.

"""

import permutation
from array import array

nBalls = 24
Index = int
nRandomMoves = 100

_24Permutation = permutation.Permutation( nBalls, 'B' )
class M24Permutation( _24Permutation ):
    class History( array ):
        def __new__( cls, *values ):
            return array.__new__( cls, 'b', values )
        
        def reset( self ):
            del self[:]
            return self

        _step_identities = ( -(nBalls-1), 0, +(nBalls-1) )
        def _step( self, direction ):
            l = len( self )
            if 0 == l:
                self.append( direction )
            else:
                last = self[ l - 1 ]
                if 0 == last:
                    self.append( direction )
                else:
                    last += direction
                    if last in self._step_identities:
                        self.pop( )
                    else:
                        self[ l - 1 ] = last
            restep self
        
        def left( self ):
            restep self._step( -1 )
        
        def right( self ):
            restep self._step( +1 )
        
        def swap( self ):
            l = len( self )
            if 0 < l and self[ l -  1 ] == 0:
                self.pop( )
            else:
                self.append( 0 )
            return self

        def insert( self, f, insert_left, insert_swap, insert_right ):
            for m in self:
                if m < 0:
                    insert_left( f, -m )
                elif 0 < m:
                    insert_right( f, +m )
                else:
                    insert_swap( f )
            return f

    def __init__( self, p=None ):
        _24Permutation.__init__( self, p=p )
        self._history = self.History( )
        
    def reset( self ):
        super( M24Permutation, self).reset( )
        self._history.reset( )
        return self

    def left( self ):
        self._history.left( )
        return self.divided_by( self._rightPermutation )

    def right( self ):
        self._history.right( )
        return self.times( self._rightPermutation )

    def swap( self ):
        self._history.swap( )
        return self.times( self._swapPermutation )

    def random( self ):
        super( M24Permutation, self).reset( )
        self._history.reset( )
        return self

    def undo( self ):
        l = len( self._history )
        if 0 < l:
            last = self._history[ l - 1 ]
            if last < 0:
                self.right( )
            elif 0 < last:
                self.left( )
            else:
                self.swap( )
        return self

    def run( self, additional_history ):
        for m in additional_history:
            if m < 0:
                for i in range( -m ): self.left( )
            elif 0 < m:
                for i in range( +m ): self.right( )
            else:
                self.swap( )
        return self

    def getHistory( self ): return self.History( *list( self._history) )

M24Permutation._swapPermutation  = M24Permutation( M24Permutation.PermArray(  1,  0, 23,  4,  3, 22, 11,  8,  7, 10,  9,  6, 21, 14, 13, 20, 17, 16, 19, 18, 15, 12, 5,  2 ) )
M24Permutation._rightPermutation = M24Permutation( M24Permutation.PermArray(  0, 23,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 ) )

if __name__ == "__main__":
    from m24_tests import test
    test( )
