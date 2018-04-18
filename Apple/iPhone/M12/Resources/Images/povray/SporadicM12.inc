// http://xahlee.org/3d/index.html

// POV-Ray texture study

#include "colors.inc"
#include "glass.inc"
#include "textures.inc"
#include "finish.inc"

global_settings
{
  max_trace_level 10
  ambient_light 3
  assumed_gamma 1.0
}

light_source {
    15*y+10*z
    color White
    parallel point_at 0
  }


camera {
  orthographic
  right x
  up y
  scale 15.5
  look_at 0
  location y
}


#declare NBalls=12;

#declare WHITE              = rgb<  255, 255, 255 > / 255 ;
#declare YELLOW             = rgb<  255, 255,   0 > / 255 ;
#declare LIGHT_HARD_ORANGE  = rgb<  255, 153,  51 > / 255 ;
#declare PALE_DULL_PINK     = rgb<  255, 153, 204 > / 255 ;
#declare RED                = rgb<  255,   0,   0 > / 255 ;
#declare DARK_HARD_RED                = rgb<  204,   0,   0 > / 255 ;
#declare MAGENTA            = rgb<  255,   0, 255 > / 255 ;
#declare DARK_HARD_ORANGE   = rgb<  204, 102,   0 > / 255 ;
#declare LIGHT_HARD_VIOLET  = rgb<  187,  84, 255 > / 255 ;
#declare LIGHT_AZURE_BLUE   = rgb<  119, 170, 255 > / 255 ;
#declare LIGHT_BLUE_AZURE   = rgb<   68, 119, 255 > / 255 ;
#declare DARK_HARD_CYAN     = rgb<    0, 204, 204 > / 255 ;
#declare DARK_HARD_GREEN    = rgb<    0, 204,   0 > / 255 ;

#declare colors = array[NBalls]
{
  WHITE             ,
  WHITE             ,
  LIGHT_BLUE_AZURE  ,
  LIGHT_BLUE_AZURE  ,
  LIGHT_HARD_ORANGE ,
  YELLOW            ,
  DARK_HARD_GREEN   ,
  DARK_HARD_RED               ,
  LIGHT_HARD_ORANGE ,
  DARK_HARD_GREEN   ,
  YELLOW            ,
  DARK_HARD_RED
}
#declare turbulences = array[NBalls]
{
	0.8,
	1.3,
	1.1,
	0.9
	1.4,
	0.75,
	1.2,
	1.05,
	0.9,
	1.3,
	0.7,
	1.0
}

#declare PLAIN=1;
#declare MARB=2;
#declare AG=3;

#macro Pigment(N)
#switch ( PIGMENT_STYLE)
    #case (MARB)
         pigment{ 
         			marble  
                        turbulence turbulences[N] 
         			color_map {
         				[0.0 0.9* colors[N]]
         				[0.8 0.5* colors[N]]
         				[1.0 0.2* colors[N]]
         			}
          }
          #break
          #case (AG)
         pigment{ 
                        agate
                        agate_turb turbulences[N]
         			color_map {
         				[0.0 0.9* colors[N]]
         				[0.8 0.5* colors[N]]
         				[1.0 0.2* colors[N]]
         			}
          }
          #break
#case (PLAIN)
         pigment { 
			color colors[N]
          }
          #break
#end

#end

#macro Ball(N)
sphere { <0,0,0>, 1
         texture{ Polished_Chrome }
         Pigment(N)
         finish{ phong 0.0 brilliance 5}
         rotate 360*clock*z  // for animation
         translate 1*y
       }
#end

#macro RingBall(N)
  object
  {
    #if (N=0)
      object{ Ball(0) translate 8.1*z }
    #else
      object{ Ball(N) translate 5.5*z
	              rotate 360/(NBalls-1)*(N-1)*y
            }
    #end
    translate -1.45*z
  }
#end

#macro BallRing()
#for (N,0,11)
  RingBall(N)
#end
#end


#macro Plane()
plane { y // normal vector
        , 0 // distance from origin
  pigment {
//    checker color White, color Black
//      color rgb<0.05, 0.05, 0.10>
      color Black
  }
}
#end


#macro Free()
	text {
	    ttf "/System/Library/Fonts/MarkerFelt.ttc" "Free" .3 , 0
	    pigment { color Very_Light_Purple }
	    scale 2
	    rotate 75*x
	    translate -1.45*x+3*y-4*z
	}
#end
