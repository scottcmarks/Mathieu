// POV-Ray Sporadic M24 Icon scene

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
  scale 23 // 17
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

#declare NBalls=24;


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
WHITE             ,  //  0 - White for 0 and 1
WHITE             ,  //  1 - White for 0 and 1
PALE_DULL_PINK    ,  //  2 - Pink for 2 and 23
LIGHT_HARD_ORANGE ,  //  3 - Orange for 3 and 4
LIGHT_HARD_ORANGE ,  //  4 - Orange for 3 and 4
YELLOW            ,  //  5 - Yellow for 5 and 22
DARK_HARD_GREEN   ,  //  6 - Green for 6 and 11
MAGENTA           ,  //  7 - Magenta for 7 and 8
MAGENTA           ,  //  8 - Magenta for 7 and 8
LIGHT_AZURE_BLUE  ,  //  9 - Light Blue for 9 and 10
LIGHT_AZURE_BLUE  ,  // 10 - Light Blue for 9 and 10
DARK_HARD_GREEN   ,  // 11 - Green for 6 and 11
LIGHT_BLUE_AZURE  ,  // 12 - Blue for 12 and 21
DARK_HARD_ORANGE  ,  // 13 - Dark Orange for 13 and 14
DARK_HARD_ORANGE  ,  // 14 - Dark Orange for 13 and 14
RED               ,  // 15 - Red for 15 and 20
LIGHT_HARD_VIOLET ,  // 16 - Violet for 16 and 17
LIGHT_HARD_VIOLET ,  // 17 - Violet for 16 and 17
DARK_HARD_CYAN    ,  // 18 - Dark Cyan for 18 and 19
DARK_HARD_CYAN    ,  // 19 - Dark Cyan for 18 and 19
RED               ,  // 20 - Red for 15 and 20
LIGHT_BLUE_AZURE  ,  // 21 - Blue for 12 and 21
YELLOW            ,  // 22 - Yellow for 5 and 22
PALE_DULL_PINK       // 23 - Pink for 2 and 23
}

#macro Ball(N)
sphere { <0,1,0>, 1
         texture{ Polished_Chrome }
         pigment{ colors[N] }
         finish{ phong 0.0 brilliance 5 }
       }
#end

#declare ringradius = 8.75; //5.5; 
#declare ringradius0=11.12; //8.0; 

#macro RingBall(N)
  object
  {
    #if (N=0)
      object{ Ball(0) translate <0,0,ringradius0> }
    #else
      object{ Ball(N) translate <0,0,ringradius>
	              rotate <0,360/(NBalls-1)*(N-1),0>
            }
    #end
    translate <0,0,-1.25>
  }
#end

#declare N=0;
#while (N<NBalls)
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
