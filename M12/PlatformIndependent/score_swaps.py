import re

def print_swap( swap, best ):
    print "  { %2d, %s }," % ( best, re.sub( ' (.[0-9])', lambda m:m.group(1)+", ", swap.strip( ) ).replace(",  }", " }") )

f = open( 'swaps.full' )
swap = None
print """struct { Index best; PermArray swap; } swaps[ ]=
{"""
for l in f:
    if l.startswith( "{" ):
        if swap: print_swap( swap, best )
        swap = l
        best = 99
    else:
        m = re.match( ' *[0-9]+ ([ 0-9][0-9]) ..:', l )
        if m:
            n = int( m.group( 1 ) )
            if n < best: best = n
f.close( )
if swap: print_swap( swap, best )
print "};"

