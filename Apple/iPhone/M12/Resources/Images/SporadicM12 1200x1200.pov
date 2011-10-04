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
}

light_source {
    <0,15,10>
    color White
    parallel point_at 0
  }


camera {
  orthographic
  right x
  up y
  scale 17
  look_at 0
  location y

//	translate -.8
//   angle 45
}

//ior 1.0
//caustics 0.0
//dispersion 1.0
//dispersion_samples 7
//fade_distance 0.0
//fade_power 0.0
//fade_color <0,0,0>

#declare NBalls=12;


#declare WHITE              = rgb<  255, 255, 255 > / 255 ;
#declare YELLOW             = rgb<  255, 255,   0 > / 255 ;
#declare LIGHT_HARD_ORANGE  = rgb<  255, 153,  51 > / 255 ;
#declare PALE_DULL_PINK     = rgb<  255, 153, 204 > / 255 ;
#declare RED                = rgb<  255,   0,   0 > / 255 ;
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
  LIGHT_HARD_ORANGE ,
  LIGHT_HARD_ORANGE ,
  LIGHT_BLUE_AZURE  ,
  YELLOW            ,
  DARK_HARD_GREEN   ,
  RED               ,
  YELLOW            ,
  DARK_HARD_GREEN   ,
  RED
}

#macro Ball(N)
sphere { <0,1,0>, 1
         texture{ Polished_Chrome }
         pigment{ colors[N] }
         finish{ phong 0.0 brilliance 5 }
       }
#end

#macro RingBall(N)
  object
  {
    #if (N=0)
      object{ Ball(0) translate <0,0,8.0> }
    #else
      object{ Ball(N) translate <0,0,5.5>
	              rotate <0,360/(NBalls-1)*(N-1),0>
            }
    #end
    translate <0,0,-1.25>
  }
#end

#declare N=0;
#while (N<12)
  RingBall(N)
  #declare N=N+1;
#end


plane { <0,1,0> // normal vector
        , 0 // distance from origin
  pigment {
//    checker color White, color Black
      color rgb<0.05, 0.05, 0.10>
  }
}
