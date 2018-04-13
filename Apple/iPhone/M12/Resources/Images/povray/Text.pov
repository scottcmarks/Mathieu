 #include "colors.inc"
  camera {
    location <0, 1, -10>
    look_at 0
    angle 35
  }
  light_source { <500,500,-1000> White }
  plane {
    y,0
    pigment { checker Green White }
  }