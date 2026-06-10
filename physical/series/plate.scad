// Series parts — two stacked clear pieces (each checkbox-toggleable in the viewer):
//   bottom (clear): z 0..eq           — channels, holds the lower hemisphere
//   mid    (clear): z eq..clear_top   — continues the channels; bottom+mid = a
//                                        60%-of-ball clear structure that retains the
//                                        balls (even inverted). No opaque cover.
// Channels: the spin ring + four neighbour swap loops ([3,4][5,6][7,8][10,11]).
// Ball 0 sits at the outboard end of a straight chute to ball 1 (zero_chute); the
// gear layer is gone and the 0-1 swap loop is replaced by that chute.
use <../swap_toy_render.scad>          // ball_at_origin(), num_at_origin()

ball_d = 18; R = 50; N = 11; $fn = 96;
nbchord = 2*R*sin(180/N);              // neighbour chord (≈28.17)
function angleOf(i) = -90 + (i-1)*(360/N);
// ball 0 (apex) sits radially OUTSIDE slot 1, a neighbour-chord away
function Pp(i) = (i==0) ? [0, R + nbchord] : [R*cos(angleOf(i)), -R*sin(angleOf(i))];

tube      = ball_d/2 + 0.5;            // snug round channel
rb        = ball_d/2;                  // ball radius
eq        = ball_d/2;                  // 9  — ball centre (ball bottom at 0)
// split the clear/opaque at the height where the round channel narrows BELOW the
// ball radius (sqrt(tube^2 - rb^2)) plus a retaining bite — so bottom+mid alone
// hold the balls (1,2,9 included) even inverted with the cover off.
clear_top = eq + sqrt(tube*tube - rb*rb) + 1.5;   // ~13.5
plate_top = ball_d;                    // 18 — top of the opaque cover (ball top flush)
ann_in  = 0;                           // no central hole — full disc now
// grow the outer edge so the apex (0,1) ring keeps the same margin as the others:
margin  = (R + 2*ball_d) - (R*cos(180/N) + nbchord/2 + (ball_d/2+0.5));   // current swap-ring margin
ann_out = (R + nbchord/2) + nbchord/2 + (ball_d/2+0.5) + margin;          // apex-ring outer + margin
swap_pairs = [[3,4],[5,6],[7,8],[10,11]];   // the four neighbour-pair swap channels (0-1 is the straight chute)
// the four transfer seats where a ball ducks under / pops up (1,9 down; 0,2 up):
xfer_pts  = [Pp(0), Pp(1), Pp(2), Pp(9)];
under_z   = -11;                       // ball-1 return lane (apex, clears the centre)
under_z9  = -21;                       // ball-9 cross lane — BELOW the ring gear region
under_bot = under_z9 - rb - 1;         // floor of the lower channel layer (~-31)
MODE = "bottom";

module annulus(h) { difference() { cylinder(h=h, r=ann_out); translate([0,0,-0.1]) cylinder(h=h+0.2, r=ann_in); } }
module spin_torus() { translate([0,0,eq]) rotate_extrude($fn=180) translate([R,0]) circle(r=tube,$fn=30); }
module swap_torus(i,j) { a=Pp(i); b=Pp(j); Rmaj=norm([a[0]-b[0],a[1]-b[1]])/2;
    translate([(a[0]+b[0])/2,(a[1]+b[1])/2,eq]) rotate_extrude($fn=80) translate([Rmaj,0]) circle(r=tube,$fn=30); }
// constant-radius circular-arc channel (a single clean arc, tube cross-section) from
// a to b, bowing by sagitta `sag` toward the +normal of a->b. Built as a smooth
// chain of capsules at ball-centre height.
module arc_chute(a, b, sag, z=eq, segs=56) {
    c    = norm([b[0]-a[0], b[1]-a[1]]);
    arcR = (c*c/4 + sag*sag) / (2*sag);                 // radius giving that sagitta
    ux=(b[0]-a[0])/c; uy=(b[1]-a[1])/c;  nx=-uy; ny=ux; // +normal = bulge direction
    mx=(a[0]+b[0])/2; my=(a[1]+b[1])/2;
    cx=mx-(arcR-sag)*nx; cy=my-(arcR-sag)*ny;           // arc centre (opposite the bulge)
    a0=atan2(a[1]-cy, a[0]-cx); a1=atan2(b[1]-cy, b[0]-cx);
    daw=(a1-a0) - 360*round((a1-a0)/360);               // signed minor-arc sweep
    for (i=[0:segs-1]) hull()
        for (k=[i,i+1]) let(an=a0+daw*k/segs)
            translate([cx+arcR*cos(an), cy+arcR*sin(an), z]) sphere(r=tube, $fn=20);
}
// straight tube channel between two planar points at height z
module straight_chute(a, b, z=eq) {
    hull() { translate([a[0],a[1],z]) sphere(r=tube,$fn=30);
             translate([b[0],b[1],z]) sphere(r=tube,$fn=30); }
}
// vertical / ramp drop at a planar point, from z0 to z1
module vchute(p, z0, z1) {
    hull() { translate([p[0],p[1],z0]) sphere(r=tube,$fn=24);
             translate([p[0],p[1],z1]) sphere(r=tube,$fn=24); }
}
module zero_chute() { straight_chute(Pp(1), Pp(0)); }     // 0-1 surface chute (ball 0 nests outboard)
// the (2 9) cross-ring swap — a gentle constant-radius arc bowing toward centre
module cross_chute() { arc_chute(Pp(2), Pp(9), 14); }
// surface channels + the vertical wells where 0,1,2,9 pass between levels
module channels() {
    spin_torus(); for (pr=swap_pairs) swap_torus(pr[0],pr[1]); cross_chute(); zero_chute();
    for (p=xfer_pts) vchute(p, -1, clear_top+1);          // wells through the main plate
}

module plate_bottom() { difference() { annulus(eq); channels(); } }
module plate_mid()    { h=clear_top-eq;    difference() { annulus(h); translate([0,0,-eq])        channels();    } }

// ---- lower layer: the under-lane that lets ball 9 pass beneath 2 and ball 1
//      travel from its seat back out to the 0-seat, each with ramps to the surface.
module under_channels() {
    arc_chute(Pp(2), Pp(9), 14, under_z9);                // 9's cross lane — deep, below the ring gear
    arc_chute(Pp(0), Pp(1), 12, under_z);                 // 1's return — bows +x, clearing the plunger column
    vchute(Pp(0), under_z,  1);  vchute(Pp(1), under_z,  1);   // 0/1 wells to the -11 lane
    vchute(Pp(2), under_z9, 1);  vchute(Pp(9), under_z9, 1);   // 2/9 wells down to the deep lane
}
module plate_under() {
    difference() {
        translate([0,0,under_bot]) cylinder(h = -under_bot, r = ann_out);   // clear slab below the plate
        under_channels();
    }
}

if      (MODE=="bottom") plate_bottom();
else if (MODE=="mid")    plate_mid();
else if (MODE=="under")  plate_under();
else { plate_under(); plate_bottom(); translate([0,0,eq]) plate_mid(); }
