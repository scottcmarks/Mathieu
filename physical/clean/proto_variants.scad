// TRACK-2 SWAP-RING VARIANTS — three alternative architectures for the wall-vs-wall clash
// =============================================================================
// The original in-plane swap-ring at chord midpoint M overlaps the spin-ring band annulus
// because dish_outer=23.97 reaches from |M|=53 inward to r=29, well inside band_inner=43.59.
// This file implements three architectural fixes, all parameterized by VARIANT:
//   "A"  — push swap-ring OUTWARD along +M direction until its inner edge clears band_inner.
//          Trade-off: body grows to ~Ø234 (apex stays put, ring pairs push out 17mm).
//   "B"  — angularly clip the swap-ring to the OUTWARD half only (no inner wall). The inner
//          spin-seg provides inner confinement. Requires a narrower spin-seg wedge so ball
//          orbit at mid-rotation doesn't crash the inner-wedge corners. Body stays Ø150.
//   "C"  — keep swap-ring centered at M but ride it on a Z-STAGED cam: rise HIGH (above seg
//          top), wait for segs to drop, lower to working z. 3-stage motion instead of 1.
// Mirrors proto_wall.scad constants.
//   PART in: A_dish | A_div | B_dish | B_div | C_dish | C_div | seg_inner | seg_outer | seg_B
// Each variant uses the SAME divider + same spin-seg; the dish geometry/position changes.
use <proto_wall.scad>;

SCALE = 20/18; R = 50*SCALE; N = 11; ball_d = 18*SCALE; rb = ball_d/2; eq = ball_d/2;
apexR = R + 24*SCALE;
tube = rb + 0.3; wall_t = 1.5*SCALE;
div_t = 3.0; orbit = rb + div_t/2 + 0.5;          // 12
dish_outer = orbit + tube + wall_t;                 // 23.97
band_inner = R - tube - wall_t;                     // 43.59
band_outer = R + tube + wall_t;                     // 67.52
spin_top   = eq + sqrt(tube*tube - rb*rb) + 1.5;    // 13.97

function angleOf(k) = -90 + (k-1)*(360/N);
function Pp(k) = k==0 ? [0, apexR] : [R*cos(angleOf(k)), -R*sin(angleOf(k))];
function pair_M(i,j) = (Pp(i) + Pp(j))/2;
function vlen(v) = sqrt(v[0]*v[0] + v[1]*v[1]);

// ============================================================================
//   VARIANT A — push M' along +M direction so dish inner edge clears band_inner
// ============================================================================
A_target = band_inner + dish_outer + 1.5;           // 69.06 — minimum |M'| for clearance
function A_M(i,j) = let(M=pair_M(i,j), r=vlen(M), s=max(1.0, A_target/r))
                    M * s;                                                                                                  // push out to at least A_target
module A_dish() { swap_wall(); }                    // unchanged geometry, just placed at A_M
module A_div()  { divider(); }                      // arm reaches inward to catch the ball at the station (mechanism abstracted)

// ============================================================================
//   VARIANT B — angular outward arc (open on inner side); narrower spin-seg wedge
// ============================================================================
// Clip swap_wall to angular sector facing OUTWARD from origin. In the swap_wall's local frame
// (centered at the pair's M), "outward" is +x after rotating to align +x with M/|M|. We clip to
// x >= -orbit so the outer arc fully encloses the ball orbit but the dish has no INNER wall.
module B_dish() {
    intersection() {
        swap_wall();
        translate([-orbit, -dish_outer-2, -1]) cube([dish_outer*2+orbit, 2*(dish_outer+2), spin_top+2]);
    }
}
module B_div() { divider(); }
// narrower spin-seg wedge so balls visiting the inner-orbit angle don't crash the inner-band corner.
// Original half-width: (360/N)/2 - seg_gap = 14.86. Narrower half-width = 10 leaves a 4.86° gap each side.
module seg_B_inner(k) {
    intersection() {
        spin_seg_inner(k);
        rotate([0,0, -angleOf(k)]) translate([0,0,-1]) linear_extrude(spin_top+2)
            polygon(concat([[0,0]], [for (a=[-10:1:10]) (R+tube+wall_t+3)*[cos(a),sin(a)]]));
    }
}

// ============================================================================
//   VARIANT C — Z-staged dish lift (above seg top, then down to working z)
// ============================================================================
// Geometry unchanged; the schedule (in check_variants.py) places the dish at z=14 (above
// spin_top=13.97) during the engage/release windows, then lowers it to z=0 for the divider turn.
module C_dish() { swap_wall(); }
module C_div()  { divider(); }

// ============================================================================
//   dispatch
// ============================================================================
PART = "A_dish";
if      (PART=="A_dish")    A_dish();
else if (PART=="A_div")     A_div();
else if (PART=="B_dish")    B_dish();
else if (PART=="B_div")     B_div();
else if (PART=="C_dish")    C_dish();
else if (PART=="C_div")     C_div();
else if (PART=="seg_inner") spin_seg_inner(1);
else if (PART=="seg_outer") spin_seg_outer(1);
else if (PART=="seg_B")     seg_B_inner(1);
