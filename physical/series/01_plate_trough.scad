// Series picture 01 — balls 1..11 in a clear plate's trough, with detents.
// A circular trough 60% of the ball diameter deep; a spherical detent at each of
// the 11 spots so the balls happily stay put.
use <../swap_toy_render.scad>      // ball_at_origin(), num_at_origin()

ball_d = 18; R = 50; N = 11; $fn = 80;
function angleOf(i) = -90 + (i-1)*(360/N);
function Pp(i) = [R*cos(angleOf(i)), -R*sin(angleOf(i))];

plate_top    = 12;
trough_depth = ball_d*0.6;              // 60% of the ball diameter
floorz       = plate_top - trough_depth;
ch_w         = ball_d + 2;              // trough width = ball + a little clearance
inr          = R - ch_w/2;
outr         = R + ch_w/2;
det_d        = ball_d*0.5;              // detent dimple diameter
ballc        = floorz + ball_d/2;       // ball centre resting on the floor

// clear plate: a disc with the trough cut in and a detent at each spot
color([0.80, 0.90, 1.0, 0.22]) difference() {
    cylinder(h = plate_top, r = outr + 6);
    translate([0,0,floorz]) difference() {
        cylinder(h = trough_depth + 1, r = outr);
        translate([0,0,-0.1]) cylinder(h = trough_depth + 1.2, r = inr);
    }
    for (i = [1:11]) translate([Pp(i)[0], Pp(i)[1], floorz]) sphere(d = det_d);
}

// balls 1..11, settled into their detents
for (i = [1:11]) translate([Pp(i)[0], Pp(i)[1], ballc - 1.2]) {
    color([0.93, 0.94, 1.0, 0.9]) ball_at_origin(i);
    color("black") num_at_origin(i);
}
