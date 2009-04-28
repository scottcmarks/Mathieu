while ( <> )
  {
    $si=sprintf("%2d",$i++); 
    s/!...! //; 
    s/dd/$si\n                       /; 
    s/^/                        /;
    print;
  }
