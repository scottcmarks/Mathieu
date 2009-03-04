if ( /==============================/ )
{
  @a=split() and $level=$a[1];
}
# print if s/}/} $level/
if ( /{ (.*) }  (.*)/ )
{
  $permarray = $1 ;
  $history = $2 ;
  $history =~ s/^ +//;
  $history =~ s/ +%//;
  $parsed = $history ;
  $parsed =~ s/L/ -/g;
  $parsed =~ s/R/ +/g;
  $parsed =~ s/S/ 0/g;
  $parsed .= " ";
  $parsed =~ s/\+ /\+1 /g;
  $parsed =~ s/\- /\-1 /g;
  $parsed =~ s/^ +//;
  $parsed =~ s/ +$//;
  @parsed = split( / /, $parsed );
  $level = $#parsed+1;
  $i = 0;
  $j = $level-1;
  while ( $i < $j )
    {
      $t = $parsed[ $i ];
      $parsed[ $i ] = $parsed[ $j ];
      $parsed[ $j ] = $t;
      $i++;
      $j--;
    };
  $parsed = join( ", " , @parsed );
  $parsed =~ tr/+-/-+/;
  $permarray =~ s/(.[0-9]) /$1, /g and printf( "{ { %s },  !%3d! //  dd   %2d, { %s } },\n", $permarray, $n++, $level, $parsed );
}


