 #include "colors.inc"
  camera {
    location 1*y-10*z
    look_at 0
    angle 35
  }
  light_source { <500,500,-1000> White }
  plane {
    y,0
    pigment { checker Green White }
  }
    text {
    ttf "Vera.ttf" "POV-RAY 3.0" 1, 0
    pigment { Red }
    translate -3*x
  }