// VARIANT C4 — SLOTTED ROTATING DISH (z-staged Variant C with seg-clearing slots)
// =============================================================================
// Variant C rises the dish through z=[0, spin_top=13.97] to escape the seg band.
// The naked dish (radius 23.97 at M) collides with the spin-segs during transit.
// C4: cut SEG-SHAPED SLOTS into the dish at the world locations of each interfering
// seg, with a small radial+angular clearance. The dish rotates so that, during
// the critical transit z, its slots align with the segs in world frame.
//
// Implementation: dish slots are SUBTRACTED from a cylinder centered at the
// pair's chord midpoint M. Each slot is a wedge of the spin-band annulus
// covering the seg's world position, expanded by SLOT_CLR.
//
// PARAMETERS:
//   PAIR_I, PAIR_J: which divider pair this dish is for (selects M and seg list).
//                   Apex pair is (0,1); others (3,4)(5,6)(7,8)(10,11).
//   PART: dish | div | seg_inner | seg_outer (which to render)
//
// Geometric notes:
//   - For non-apex pairs, only segs i and j overlap the dish disk. Each at
//     closest approach ~1.5mm to M, i.e. the seg crosses through the dish.
//   - For apex pair (0,1), seg(1) sits dead center under M; seg(2) and seg(11)
//     clip the dish edges. Apex needs 3 slots.
//
// The dish material remaining (between the slots) is positioned in the
// inter-seg gaps of the spin-band, providing pass-through clearance.
use <proto_wall.scad>;

SCALE      = 20/18;
R          = 50*SCALE;        // 55.56
N          = 11;
ball_d     = 18*SCALE;        // 20
rb         = ball_d/2;        // 10
eq         = ball_d/2;        // 10
apexR      = R + 24*SCALE;    // 82.22
tube       = rb + 0.3;        // 10.3
wall_t     = 1.5*SCALE;       // 1.667
div_t      = 3.0;
orbit      = rb + div_t/2 + 0.5;          // 12
dish_outer = orbit + tube + wall_t;       // 23.967
band_inner = R - tube - wall_t;           // 43.589
band_outer = R + tube + wall_t;           // 67.523
spin_top   = eq + sqrt(tube*tube - rb*rb) + 1.5;   // 13.97
floorz     = eq - tube;                            // -0.3
seg_gap    = 1.5;
seg_half   = (360/N)/2 - seg_gap;                  // 14.864 deg
SLOT_CLR_R = 1.5;                                  // radial clearance around seg
SLOT_CLR_A = 1.5;                                  // angular clearance (deg) each side

function angleOf(k) = -90 + (k-1)*(360/N);
function th(k)      = -angleOf(k);
function Pp(k)      = k==0 ? [0, apexR] : [R*cos(angleOf(k)), -R*sin(angleOf(k))];
function pair_M(i,j) = (Pp(i)+Pp(j))/2;

// Seg list per pair — which segs the dish has to slot through.
// Apex (0,1): seg(1) center, plus seg(2) and seg(11) edge clips.
// Non-apex pairs: just segs i and j.
function seg_list(i,j) =
    (i==0 && j==1) ? [1, 2, 11] :
    [i, j];

// One slot: a wedge in the world annulus [band_inner-SLOT_CLR_R, band_outer+SLOT_CLR_R]
// covering azimuth [th(k)-seg_half-SLOT_CLR_A, th(k)+seg_half+SLOT_CLR_A].
// We build it as the difference of two cylinders intersected with a wedge.
module world_slot(k, h=spin_top+2, dz=-1) {
    intersection() {
        // annular shell
        difference() {
            translate([0,0,dz]) cylinder(h=h, r=band_outer+SLOT_CLR_R, $fn=180);
            translate([0,0,dz-1]) cylinder(h=h+2, r=band_inner-SLOT_CLR_R, $fn=180);
        }
        // angular wedge centered at th(k), with clearance margin
        rotate([0,0, th(k)])
            translate([0,0,dz-1]) linear_extrude(h+2)
            polygon(concat([[0,0]],
                [for(a=[-seg_half-SLOT_CLR_A : 2 : seg_half+SLOT_CLR_A])
                    (band_outer+SLOT_CLR_R+5)*[cos(a),sin(a)] ],
                [(band_outer+SLOT_CLR_R+5)*[cos(seg_half+SLOT_CLR_A), sin(seg_half+SLOT_CLR_A)]] ));
    }
}

// Slotted dish for pair (i,j): the regular swap_wall cylinder/groove, with
// world-positioned slots cut out. The dish module is built in WORLD coords
// (placed at M, no further translation needed); but the check script will
// translate by M as for the base swap_wall, so we build the dish CENTERED
// at the ORIGIN and subtract slots translated by -M (i.e. in dish-local).
module C4_dish(i, j) {
    M = pair_M(i, j);
    difference() {
        // base dish: same as swap_wall, centered at origin
        swap_wall();
        // subtract each interfering seg's world footprint, in dish-local coords
        for (k = seg_list(i, j)) {
            translate([-M[0], -M[1], 0])
                world_slot(k);
        }
    }
}

module C4_div(i, j) { divider(); }

// Dispatch — defaults rebuild pair (3,4)
PAIR_I = 3;
PAIR_J = 4;
PART   = "dish";

if      (PART == "dish")       C4_dish(PAIR_I, PAIR_J);
else if (PART == "div")        C4_div(PAIR_I, PAIR_J);
else if (PART == "seg_inner")  spin_seg_inner(1);
else if (PART == "seg_outer")  spin_seg_outer(1);
