// TRACK-2 VARIANT C3 — CARRIER-DIVIDER (no dish)
// =============================================================================
// Architectural insight: variant C (z-staged dish) cannot work because the dish (an O.D.=47.94
// cylinder centered at chord midpoint M) cannot slot through the 3.01-deg inter-seg gaps. Only
// a THIN object (tangential thickness <~ 2 mm at the inner band radius 43.59) can pass.
//
// C3 ELIMINATES the dish entirely. The divider becomes a CARRIER: a thin radial bar with two
// CRADLES at the ends, each cradle holding ONE ball over its equator (gravity-proof fork, same
// vocabulary as the (2,9) fork carrier in proto_29.scad). Mechanism:
//   1. carrier descends from above (parked HIGH inside the lid) into the inter-seg gap aligned
//      with M (azimuth halfway between the two stations).
//   2. at floor level, the two cradles close around the two balls (the spin-seg outer halves
//      have dropped to clear the orbit; inner halves can stay up).
//   3. carrier rises slightly (lifts both balls together over the seg-top), rotates pi about the
//      vertical post at M, descends, releases.
//   4. ascends through gap, returns to parked-HIGH.
//
// Because the bar is THIN (div_t = 2.0 mm) and aligned with the inter-seg gap azimuth, it never
// intersects spin-seg material at any z during the up/down transit.
//
// Cradle = fork shell (sphere shell, C-lip at z=+fork_dz past equator, slip-mouth toward path).
// At the apex pair (0,1) the midpoint M sits at azimuth 90 deg which is INSIDE seg(1), not at a
// gap. So C3 needs a DIFFERENT mechanism for the apex pair — handled by Track-1's apex
// solution (the apex ball is the "12th" managed by the apex-and-2-9 mechanism). C3 covers the
// four ring pairs (3,4)(5,6)(7,8)(10,11) only; the apex pair already had its own treatment.
//
// PART in: C3_carrier | C3_carrier_only | C3_cradle | seg_inner | seg_outer
use <proto_wall.scad>;
use <proto_29.scad>;

SCALE = 20/18; R = 50*SCALE; N = 11; ball_d = 18*SCALE; rb = ball_d/2; eq = ball_d/2;
tube = rb + 0.3; wall_t = 1.5*SCALE;
spin_top = eq + sqrt(tube*tube - rb*rb) + 1.5;       // 13.97
floorz   = eq - tube;                                 // -0.3

// --- C3 carrier-divider geometry ---------------------------------------------------------------
C3_bar_t   = 2.0;          // tangential thickness of the bar (< 2.55 deg at outer band r=67.52)
C3_bar_h   = spin_top - floorz + 0.5;   // bar height covers the spin-band channel
C3_post_r  = 2.5;          // central vertical drive post (same as original divider)
C3_post_h  = spin_top + 12; // post reaches up into the lid for the drive mechanism

// Cradle = fork shell from proto_29 (rb+wall sphere, sliced to floor + C-lip at +fork_dz)
// The C-lip past the equator (fork_dz=4) holds the ball gravity-proof.
// Cradle center sits at distance L = chord/2 = 15.65 mm from carrier center along bar axis.
C3_L = 15.65;             // half-chord for ring pairs (all four pairs have same chord 31.30)

// One cradle, centered at local origin, slip-mouth opening toward +x (which we align outward
// toward the station). heading = heading of slip-mouth direction (degrees).
module C3_cradle(heading=0) {
    rotate([0,0,heading]) difference() {
        intersection() {
            difference() { sphere(r=rb+1.6, $fn=56); sphere(r=rb+0.4, $fn=56); }
            translate([0,0,-(rb+1.6)-1]) cylinder(h=(rb+1.6)+4.0+1, r=rb+1.6+1, $fn=56);
        }
        // slip-mouth: 110-deg wedge on the +x side so the ball can slip in laterally
        linear_extrude(height=3*ball_d, center=true)
            polygon(concat([[0,0]], [ for(a=[-55:5:55]) (rb+1.6+2)*[cos(a),sin(a)] ]));
    }
}

// The full carrier: thin bar across diameter + two cradles at ends + central drive post.
// Bar axis is local +x/-x. Cradles point outward (+x at +L, -x at -L).
// Cradle ball-center sits at z = eq (so it can grab balls at their resting height).
// Bar fills floorz..spin_top+ small overshoot, oriented as a thin slab (Y is tangential = bar_t).
module C3_carrier() {
    // bar
    translate([-(C3_L+rb), -C3_bar_t/2, floorz])
        cube([2*(C3_L+rb), C3_bar_t, C3_bar_h]);
    // central drive post (vertical axis at M; the gear-train planet rides this)
    cylinder(h=C3_post_h, r=C3_post_r, $fn=24);
    // two cradles at the ends, each centered at +/- L with ball-center at z = eq
    translate([ C3_L, 0, eq]) C3_cradle(0);     // slip-mouth opens outward toward +x (station j)
    translate([-C3_L, 0, eq]) C3_cradle(180);   // slip-mouth opens outward toward -x (station i)
}

// just the bar (no cradles) — useful to test thinness clearance through gaps
module C3_carrier_bar() {
    translate([-(C3_L+rb), -C3_bar_t/2, floorz])
        cube([2*(C3_L+rb), C3_bar_t, C3_bar_h]);
    cylinder(h=C3_post_h, r=C3_post_r, $fn=24);
}

// ---------------- dispatch ----------------
PART = "C3_carrier";
if      (PART=="C3_carrier")      C3_carrier();
else if (PART=="C3_carrier_bar")  C3_carrier_bar();
else if (PART=="C3_cradle")       C3_cradle();
else if (PART=="seg_inner")       spin_seg_inner(1);
else if (PART=="seg_outer")       spin_seg_outer(1);
