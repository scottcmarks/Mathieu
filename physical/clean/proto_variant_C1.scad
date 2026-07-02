// TRACK-2 SWAP-RING VARIANT C1 — PETALED DISH
// =============================================================================
// Variant C kept the dish ABOVE the seg top during transition (z=14), but during the actual rise
// from parked-LOW (z=-22) up to working (z=0) it must traverse z=[0, 13.97] where the spin segs
// live, and a CIRCULAR dish of outer radius 23.97 at chord midpoint M overlaps the spin-band
// annulus [43.59, 67.52] heavily — even though the divider paddle (thin) slots through the 3°
// inter-seg gap, the round bowl wall does not.
//
// GEOMETRIC INSIGHT (verified in check_C1.py):
//   For ring pairs (3,4)(5,6)(7,8)(10,11), the chord midpoint M sits at the SAME azimuth as
//   the inter-seg gap between the two stations. We exploit this: within the spin-band annulus
//   (origin r in [band_inner, band_outer]), KEEP DISH MATERIAL ONLY in a narrow azimuth wedge
//   centered on M_az (origin-frame), so that material slides through the gap. Outside the
//   annulus the dish is solid as before, so it still confines the balls at z=0.
//
// APEX (0,1) is a SPECIAL CASE: M sits at azimuth 90° which is the CENTER of seg(1) (no gap).
// We push the apex dish outward by 1.5 mm so dish_inner sits at r=46.4 > band_inner=43.59 — a
// pure radial clearance solution for the apex (the apex |M|=68.89 already nearly clears, so a
// tiny push suffices).
//
// This file provides petaled dish geometry parameterised by the M direction so each pair gets
// its own petal-axis. The orientation is supplied externally (the test driver computes it).
//   PART in: C1_dish | C1_div | C1_petal_test
use <proto_wall.scad>;

SCALE = 20/18; R = 50*SCALE; N = 11; ball_d = 18*SCALE; rb = ball_d/2; eq = ball_d/2;
apexR = R + 24*SCALE;
tube = rb + 0.3; wall_t = 1.5*SCALE;
div_t = 3.0; orbit = rb + div_t/2 + 0.5;          // 12
dish_outer = orbit + tube + wall_t;                 // 23.97
band_inner = R - tube - wall_t;                     // 43.59
band_outer = R + tube + wall_t;                     // 67.52
spin_top   = eq + sqrt(tube*tube - rb*rb) + 1.5;    // 13.97
floorz     = eq - tube;                             // -0.3

// Inter-seg gap is 3.0° wide. Use a narrower 2.6° wedge (0.2° clearance per side) for the
// material that pokes into the spin-band annulus.
petal_half = 1.3;                                   // half-angle (deg) of the petal slot

// ---- petaled dish ----------------------------------------------------------------------------
// "psi" is the origin-frame azimuth (deg) along which the petal should point (= M_az for the gap-
// aligned pairs). Builds an oriented-pair-local dish (centered at origin in the dish's own frame).
// The dish is built at M's local coordinates: the caller translates it by M. We accept psi so that
// the petal points at origin-frame azimuth psi which is, in dish-local coords, the direction from
// dish center back toward origin (i.e. the petal points from M toward origin AND extending outward
// from M along the same axis).
// Strategy:
//   solid = swap_wall() ; everywhere except within the BAND ANNULUS in origin frame.
//   In the band annulus, keep only the petal-wedge sector (origin-frame) centered at psi and
//   spanning [psi - petal_half, psi + petal_half], extending radially across the annulus.
// To express "origin-frame band annulus" in the dish-local frame, the caller MUST pass M so we can
// build the cutting solid in dish-local coords. We accept Mx, My for that.

module band_annulus_origin(Mx, My) {
    // an annular ring centered at origin (origin r in [band_inner, band_outer]), tall enough to
    // cut the full dish height with margin, expressed in DISH-LOCAL coords -> translate by -M.
    translate([-Mx, -My, floorz - 1])
        difference() {
            cylinder(h = spin_top - floorz + 2, r = band_outer, $fn = 200);
            translate([0,0,-1]) cylinder(h = spin_top - floorz + 4, r = band_inner, $fn = 200);
        }
}

module petal_wedge_origin(Mx, My, psi) {
    // wedge (pie sector) in ORIGIN frame, centered at psi with half-angle petal_half, extending
    // radially from r=0 out to r > band_outer; tall to span dish height; expressed in dish-local.
    rad_out = band_outer + 6;
    translate([-Mx, -My, floorz - 1])
        rotate([0,0, psi])
        linear_extrude(height = spin_top - floorz + 2)
            polygon(concat([[0,0]],
                           [ for (a = [-petal_half : 0.2 : petal_half]) rad_out * [cos(a), sin(a)] ]));
}

// petaled dish: full swap_wall MINUS (band annulus MINUS petal wedge).
// Equivalently: full swap_wall, then remove the band annulus material EXCEPT where the petal
// wedge covers it.
module C1_dish_petaled(Mx, My, psi) {
    difference() {
        swap_wall();
        difference() {
            band_annulus_origin(Mx, My);
            petal_wedge_origin(Mx, My, psi);
        }
    }
}

// apex dish: push out by 1.5 mm radially along +M (handled in check_C1.py by translating to a
// pushed M); the dish geometry itself is just the full swap_wall.
module C1_dish_apex() { swap_wall(); }

// TWO-PETAL apex dish: M sits at azimuth 90 (= center of seg(1)), so there's no single gap to
// align with. Cut the band-annulus material everywhere EXCEPT at the two gaps flanking seg(1):
// gap_below = [th(2)+half, th(1)-half] -> centered at psi = 74.32 deg in origin frame.
// gap_above = [th(1)+half, th(0_virtual)-half] -> the gap on the other side of seg(1), centered
//   at psi = 105.68 deg.
module C1_dish_apex_petaled(Mx, My, psi1, psi2) {
    difference() {
        swap_wall();
        difference() {
            band_annulus_origin(Mx, My);
            union() {
                petal_wedge_origin(Mx, My, psi1);
                petal_wedge_origin(Mx, My, psi2);
            }
        }
    }
}

module C1_div() { divider(); }

// ---------------- dispatch ----------------
// For viewing one sample: pair (3,4). Mx = 52.45, My = 7.65, psi = M_az = 8.30 deg.
PART = "C1_petal_test";
if      (PART == "C1_petal_test")
    C1_dish_petaled(52.45, 7.65, 8.30);
else if (PART == "C1_dish_apex")
    C1_dish_apex();
else if (PART == "C1_div")
    C1_div();
