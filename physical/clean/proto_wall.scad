// TRACK-2 RECONFIGURABLE WALL — solids for the gravity-safe spin/swap wall
// =============================================================================
// SPIN/REST: 11 over-equator wall segments line the ring (a channel whose top mouth < ball_d, so a
// ball is captive in any orientation yet finger-spinnable). For a NEIGHBOUR swap, the relevant
// segments DROP while a SWAP-RING (circumference wall + diameter DIVIDER) rises around the pair and
// the divider turns pi (vertical axis). For 2&9 the INTERIOR segment drops and a magnet lifts in.
// Kinematics/states are driven by the viewer + check_wall.py; this file is the parts + a preview.
//   openscad -o seg.stl -D 'PART="seg"' proto_wall.scad        (one spin segment; viewer instances 11x)
//   PART in: seg | swapwall | divider | mag | ball | all
SCALE = 20/18;             // Ø20
R     = 50*SCALE;          // 55.56 ring radius
N     = 11;
ball_d= 18*SCALE;          // 20
rb    = ball_d/2;          // 10
eq    = ball_d/2;          // 10
tube  = rb + 0.3;          // 10.3
wall_t= 1.5*SCALE;         // 1.667
clr   = 0.4;
spin_top = eq + sqrt(tube*tube-rb*rb) + 1.5;   // 13.97  channel top (mouth here < ball_d)
floorz   = eq - tube;                           // -0.3
mouth_r  = sqrt(tube*tube-(spin_top-eq)*(spin_top-eq));  // 9.5  half the top mouth (mouth 19 < 20)
seg_gap  = 1.5;            // angular gap (deg) between adjacent segments

function angleOf(k)=-90+(k-1)*(360/N);
function th(k)= -angleOf(k);                    // standard-angle of station k (Pp uses -sin)
function Pp(k)=[R*cos(angleOf(k)), -R*sin(angleOf(k))];

// over-equator channel VOID: a cylinder up to eq, then a cone narrowing to the mouth at spin_top
module channel_void() {
    translate([0,0,eq]) rotate_extrude($fn=160) translate([R,0]) circle(r=tube, $fn=36);  // groove (wraps past eq)
}
module band_block() {
    difference() {
        cylinder(h=spin_top, r=R+tube+wall_t, $fn=180);
        translate([0,0,-1]) cylinder(h=spin_top+2, r=R-tube-wall_t, $fn=180);
    }
}
module wedge(half) {                            // pie sector around +x, half-angle `half`
    pts = concat([[0,0]], [ for(a=[-half:3:half]) (R+tube+wall_t+3)*[cos(a),sin(a)] ]);
    translate([0,0,floorz-1]) linear_extrude(height=spin_top-floorz+2) polygon(pts);
}
// one spin-ring segment at station k (a grooved-band arc); built in place
module spin_seg(k) {
    intersection() {
        difference() { band_block(); channel_void(); }
        rotate([0,0, th(k)]) wedge(360/N/2 - seg_gap);
    }
}
// split at radius R: the INTERIOR half drops for the 2-9 magnet pop-in; the EXTERIOR half drops for
// the divider pairs (balls swing out). Each is independently liftable in the choreography.
module spin_seg_inner(k) { intersection() { spin_seg(k); translate([0,0,floorz-1]) cylinder(h=spin_top-floorz+2, r=R, $fn=180); } }
module spin_seg_outer(k) { difference()   { spin_seg(k); translate([0,0,floorz-1]) cylinder(h=spin_top-floorz+2, r=R, $fn=180); } }

// ---- neighbour swap-ring (circumference wall + diameter divider), built at ORIGIN ----
div_t   = 3.0;                      // divider wall thickness
orbit   = rb + div_t/2 + 0.5;       // 12.0  ball orbit radius (ball clears the divider face)
dish_r  = orbit + rb + 0.6;         // 22.6  dish inner radius (holds a ball at orbit + rb)
// SPIN-WALL-TYPE swap ring: an over-equator GROOVED channel at the ball-ORBIT radius (same cross-
// section as the spin ring), so it captures each ball past its equator in any orientation (top mouth
// < ball_d, groove floor + outer lip; the divider closes the inner side). Being the same segment
// vocabulary as the spin ring, these can ultimately reposition through the spin-ring inter-segment
// slots, and adjacent swap rings (e.g. 0-1 and 10-11) can be expanded to SHARE a wall.
module swap_wall() {
    difference() {
        cylinder(h=spin_top, r=orbit+tube+wall_t, $fn=100);                                          // block
        translate([0,0,eq]) rotate_extrude($fn=120) translate([orbit,0]) circle(r=tube, $fn=34);     // groove (captures)
        translate([0,0,-1]) cylinder(h=spin_top+2, r=3.2, $fn=24);                                    // centre clearance for the divider post
    }
}
module divider() {                  // THIN diameter wall across the groove + a drive post (vertical axis)
    translate([-div_t/2, -(orbit+rb-1), floorz]) cube([div_t, 2*(orbit+rb-1), spin_top-floorz]);
    cylinder(h=spin_top+6, r=2.5, $fn=24);                              // vertical drive post (the gear-train planet rides this)
}

// ---- 2-9 magnet carrier (reuse the proto_29 magnet grip) ----
use <proto_29.scad>;
module mag() { mag_carrier(0); }    // magnet grip head (from proto_29.scad)

module ball() sphere(r=rb, $fn=40);

// ---------------- dispatch ----------------
PART="all";
if      (PART=="seg")      spin_seg(1);
else if (PART=="seg_in")   spin_seg_inner(1);
else if (PART=="seg_out")  spin_seg_outer(1);
else if (PART=="swapwall") swap_wall();
else if (PART=="divider")  divider();
else if (PART=="mag")      mag();
else if (PART=="ball")     ball();
else {                                                   // assembled preview (rest state)
    color([0.55,0.62,0.72,0.5]) for(k=[1:N]) spin_seg(k);
    color([0.9,0.92,1,0.95])    for(k=[1:N]) translate([Pp(k)[0],Pp(k)[1],eq]) ball();
    // a swap-ring shown parked-low under the 3-4 midpoint, divider too (demo)
    M=(Pp(3)+Pp(4))/2;
    color([0.80,0.55,0.30,0.6]) translate([M[0],M[1],-22]) swap_wall();
    color([0.85,0.30,0.30,0.8]) translate([M[0],M[1],-22]) divider();
}
