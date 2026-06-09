// Series parts — three stacked pieces (each checkbox-toggleable in the viewer):
//   bottom (clear): z 0..eq           — channels, holds the lower hemisphere
//   mid    (clear): z eq..clear_top   — continues the channels; bottom+mid = a
//                                        60%-of-ball clear structure round the ball
//   cover  (opaque): z clear_top..bd  — the top 40%: the bottom reflected, with
//                                        ONLY the spin channel cut all the way
//                                        through (narrower than a ball -> captures;
//                                        spin ring open above, swaps hidden under).
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
swap_pairs = [[0,1],[3,4],[5,6],[7,8],[10,11]];
MODE = "bottom";

module annulus(h) { difference() { cylinder(h=h, r=ann_out); translate([0,0,-0.1]) cylinder(h=h+0.2, r=ann_in); } }
module spin_torus() { translate([0,0,eq]) rotate_extrude($fn=180) translate([R,0]) circle(r=tube,$fn=30); }
module swap_torus(i,j) { a=Pp(i); b=Pp(j); Rmaj=norm([a[0]-b[0],a[1]-b[1]])/2;
    translate([(a[0]+b[0])/2,(a[1]+b[1])/2,eq]) rotate_extrude($fn=80) translate([Rmaj,0]) circle(r=tube,$fn=30); }
module channels() { spin_torus(); for (pr=swap_pairs) swap_torus(pr[0],pr[1]); }

module plate_bottom() { difference() { annulus(eq); channels(); } }
module plate_mid()    { h=clear_top-eq;    difference() { annulus(h); translate([0,0,-eq])        channels();    } }
// a stubby arc of an OUTER ring at ball 0's radius — a sideways slit just big
// enough to show the one ball (a fragment of a concentric outer channel)
module zero_stub() {
    r0 = R + nbchord; arc = 26;            // degrees — stubby
    translate([0,0,eq]) rotate([0,0, 90 - arc/2])
        rotate_extrude(angle = arc, $fn = 160) translate([r0,0]) circle(r = tube, $fn = 30);
}
// opaque cover: open over the spin ring + a stubby outer-ring slit showing 0
// (the apex swap loop itself stays hidden under the cover)
module plate_cover()  { h=plate_top-clear_top;
    difference() { annulus(h); translate([0,0,-clear_top]) spin_torus();
                               translate([0,0,-clear_top]) zero_stub(); } }

// --- lower gear layer: houses the swap gears for the neighbour-style pairs ---
gear_z = -4; gear_h = 5;                // sits below the channel plate (z 0..)
swap5 = [[0,1],[3,4],[5,6],[7,8],[10,11]];
module gear(r, nteeth) {
    cylinder(h = gear_h, r = r - 1.4);
    for (i = [0:nteeth-1]) rotate([0,0,360/nteeth*i]) translate([r-1.6,-1.0,0]) cube([2.0, 2.0, gear_h]);
    cylinder(h = gear_h + 2, d = 4);    // hub
}
module plate_gears() {
    translate([0,0,gear_z-3]) cylinder(h = 2.5, r = ann_out);          // housing floor
    for (pr = swap5) {                                                 // a swap gear per pair
        a = Pp(pr[0]); b = Pp(pr[1]); Rmaj = norm([a[0]-b[0],a[1]-b[1]])/2;
        translate([(a[0]+b[0])/2,(a[1]+b[1])/2, gear_z]) gear(Rmaj+2, round(Rmaj));
    }
    translate([0,0,gear_z]) gear(28, 30);                              // central sun gear
}

if      (MODE=="bottom") plate_bottom();
else if (MODE=="mid")    plate_mid();
else if (MODE=="cover")  plate_cover();
else if (MODE=="gears")  plate_gears();
else { plate_bottom(); translate([0,0,eq]) plate_mid(); translate([0,0,clear_top]) plate_cover(); }
