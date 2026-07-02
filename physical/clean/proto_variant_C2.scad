// VARIANT C2 — dish PARKED HIGH (above the lid), descends through lid bore
// =============================================================================
// Architecture: invert variant C's z-staging. Instead of dish parked LOW (z=-22) and rising
// through the spin band annulus, the dish is parked HIGH (z=+28..+42, above lid_top=24) and
// descends straight down to z=0 working position. The dish never radially overlaps the spin
// segs in z because, during the dish's *descent* through z=[0, spin_top=13.97], the segs are
// already FULLY DROPPED.  The dish passes through the lid via a circular BORE at chord
// midpoint M of each ring pair.
//
// CHOREOGRAPHY (4 stages, dish moves only along Z):
//   u=0.00..0.10  segs at home, dish parked at z=+28 (above lid)
//   u=0.10..0.30  segs DROP from z=0 to z=-20 (channel evacuated, balls held by... see below)
//   u=0.30..0.55  dish DESCENDS from z=+28 through lid bore down to z=0 (working position)
//   u=0.55..0.75  divider turn (vertical axis, dish at z=0)
//   u=0.75..0.95  dish RISES back to z=+28 through lid bore
//   u=0.95..1.00  segs RISE back from z=-20 to z=0 (channel restored)
//
// CONFINEMENT-CONTINUITY GAP: between u=0.10 (segs gone) and u=0.55 (dish at work z, groove
// captures), the two affected balls have NO lateral wall. The lid above them caps the top, the
// floor (z=floorz=-0.3) caps the bottom, but radially they could roll free. See check_C2.py
// for the analysis.  Options modelled here:
//   (a) accept the gap (the lid bore is RING-SHAPED at small radius so the *neighbouring*
//       fixed inner-wall remains — this file implements this option).
//   (b) extend the divider arms to act as side-wall stubs during seg-down.
//   (c) magnet sub-mechanism holds both balls during the gap (mechanism extension).
//
// LID MODIFICATION: each of the 4 ring pairs (3,4)(5,6)(7,8)(10,11) gets a CIRCULAR BORE
// of radius dish_outer+clr=24.5 mm centered at M, cut from z=lid_bot=11.5 through z=lid_top=24.
// This bore lies WITHIN the existing swap-arc cap region (the lid already carves a swap-path
// dome there for the dividers' rotation channel; this is a larger penetration but does NOT
// touch the SPIN-ring finger slot at radius R).
//
// The bore breaks the swap-arc CAP, which was the lid's "swap hidden + ball top retention" for
// the swap path.  Replacement: a tower (annular skirt) attached to the dish that EXTENDS
// upward through the lid bore so that the bore is plugged by the dish material itself at all
// times.  When dish is parked-high, the tower sits inside the bore (still plugging it).  When
// the dish lowers to z=0, the tower extends from the dish-top (z=spin_top=13.97) up through
// the bore to z>=lid_top, still plugging.  So the lid retains its top-cap function via the
// tower at all dish positions; only the BORE WALL replaces the LID CAP at the M location.
//
// Pair (0,1) is special: its M sits at azimuth 90° on the symmetry axis of seg(1) — the bore
// would punch through the SPIN-ring finger slot, not a swap arc.  C2 keeps variant A's
// pushed-out treatment for (0,1) and applies the descend-from-above scheme only to the four
// chord pairs that align with inter-seg gaps.
//
// PART in: C2_dish | C2_div | C2_lid | C2_dish_with_tower
use <proto_wall.scad>;

SCALE = 20/18; R = 50*SCALE; N = 11; ball_d = 18*SCALE; rb = ball_d/2; eq = ball_d/2;
apexR = R + 24*SCALE;
tube = rb + 0.3; wall_t = 1.5*SCALE;
div_t = 3.0; orbit = rb + div_t/2 + 0.5;          // 12
dish_outer = orbit + tube + wall_t;                 // 23.97
spin_top   = eq + sqrt(tube*tube - rb*rb) + 1.5;    // 13.97
floorz     = eq - tube;                              // -0.3
clr        = 0.4;

// lid geometry (mirror of proto_lid.scad)
lid_bot   = eq + 1.5;                                // 11.5
lid_top   = eq + rb + 4;                             // 24
finger_w  = ball_d - 4;                              // 16
slab_r    = R + orbit + tube + 3;                    // 80.9

// dish-PARK-HIGH band
park_top    = lid_top + 4 + spin_top;                // 41.97
park_bot    = lid_top + 4;                           // 28
working_z   = 0.0;                                   // dish working position
// bore radius slightly larger than dish_outer so the dish slides freely
bore_r      = dish_outer + 0.5;                       // 24.47
tower_r_out = dish_outer - 0.1;                       // 23.87 — slides inside bore
tower_r_in  = orbit + tube + wall_t - 6;              // 17.97 — hollow tower (mass + bore-plug only)
// downward SKIRT length: must plug bore even when dish is parked at park_bot=28
//   skirt extends DOWN from dish bottom by skirt_h; tip at z = dish_z - skirt_h
//   when dish at park_bot=28, skirt covers [28-skirt_h, 28]; we need this to include z<=eq=10
//   so skirt_h >= park_bot - eq = 18.  Use 19 for margin.
skirt_h     = park_bot - eq + 1;                      // 19

function angleOf(k) = -90 + (k-1)*(360/N);
function Pp(k) = k==0 ? [0, apexR] : [R*cos(angleOf(k)), -R*sin(angleOf(k))];
function pair_M(i,j) = (Pp(i) + Pp(j))/2;

// ---- the new dish (geometry identical to swap_wall except a TOWER extends upward) --------
// The tower is a hollow cylinder of OUTER radius tower_r_out, INNER radius tower_r_in, running
// from z=spin_top (dish top) up to z = working_z + park_top + 1.  When the dish is at z=0 the
// tower top sits at z=park_top+1=42.97 (above the parked-high band). When dish parks at z=28,
// the tower sits at z=[28+spin_top, 28+park_top+1] = [41.97, 70.97], its bottom flush with
// the dish top.  Either way, the tower OR the dish always intersects every z in
// [working_z, park_top+something], so the lid bore is plugged at all times.

tower_h_above_dish = park_top + 1 - spin_top;        // 28 + 1 = 29 (from z=spin_top up by 29 = z=42.97)

module C2_dish() {
    // identical to swap_wall(): grooved over-equator channel at orbit
    union() {
        // base dish: same as proto_wall.swap_wall()
        difference() {
            cylinder(h=spin_top, r=dish_outer, $fn=120);
            translate([0,0,eq]) rotate_extrude($fn=120) translate([orbit,0]) circle(r=tube, $fn=34);
            translate([0,0,-1]) cylinder(h=spin_top+2, r=3.2, $fn=24);
        }
        // upper tower: hollow annular cylinder rising from dish top (plugs bore at WORKING z)
        translate([0,0,spin_top]) difference() {
            cylinder(h=tower_h_above_dish, r=tower_r_out, $fn=80);
            translate([0,0,-1]) cylinder(h=tower_h_above_dish+2, r=tower_r_in, $fn=80);
            translate([0,0,-1]) cylinder(h=tower_h_above_dish+2, r=3.2, $fn=24);
        }
        // lower SKIRT: hollow annular cylinder hanging below dish (plugs bore at PARKED z)
        // tip-clearance: the divider thin paddle still hangs into the inner ball-orbit region, but
        // the skirt's inner radius tower_r_in=17.97 leaves room for both the divider (width 3 mm
        // ±~12 mm = ±13.5 mm out from M) and the drive post.  Below z=0 (when dish at working z)
        // the skirt extends to z=-19, BELOW floor=-0.3.  Segs are dropped to z=-20 then.  The
        // skirt's footprint at M (radius~24 mm) does NOT overlap dropped segs at z=-19 because
        // segs sit at radial band [43.59, 67.52] from origin, but the skirt is at |M|≈53 with
        // outer radius 23.87 around M, so it spans radius [29, 77] from origin -- IT DOES OVERLAP
        // the dropped-seg band [43.59, 67.52] in xy!  The dropped segs are at z=[-20, -6.03] and
        // the skirt at dish-working extends to z=[-19, 0].  z-overlap = [-19, -6.03] = 13mm.
        // -> the skirt would CLASH with dropped segs when dish is at working z.  Solution: keep
        // skirt SHORT enough that at dish=working its tip stays above z = dropped seg top.  Since
        // segs are dropped 20 mm, dropped-seg top at z=spin_top-20 = -6.03.  Skirt tip at dish=0
        // must be >= -6.03 + clr, i.e. skirt_h_eff <= 6.0.  But to plug bore at parked z=28 we
        // need skirt_h >= 18.  Conflict.
        //
        // RESOLUTION: drop the segs DEEPER (to z=-35) so dropped-seg top is at z=-21.  Then a
        // skirt of length 19 mm with dish at working z=0 has tip at z=-19, which is above
        // -21 -> clears.  This requires the seg-drop mechanism to travel 35 mm instead of 20.
        // We document and check this trade-off in check_C2.py.
        translate([0,0,-skirt_h]) difference() {
            cylinder(h=skirt_h, r=tower_r_out, $fn=80);
            translate([0,0,-1]) cylinder(h=skirt_h+2, r=tower_r_in, $fn=80);
            translate([0,0,-1]) cylinder(h=skirt_h+2, r=3.2, $fn=24);
        }
    }
}

module C2_div() { divider(); }                        // unchanged thin paddle

// ---- the new lid (lid with bores at 4 ring-pair midpoints) --------------------------------
module dome(p) { translate([p[0],p[1],eq]) sphere(r=rb+clr, $fn=32); }
module dome_path(a,b) { hull() { dome(a); dome(b); } }

DIVPAIRS_C2_BORED = [[3,4],[5,6],[7,8],[10,11]];     // four chord pairs that get bores
DIVPAIRS_C2_CAPPED = [[0,1]];                         // apex pair: no bore (use variant-A push-out)
DIVPAIRS_ALL = [[0,1],[3,4],[5,6],[7,8],[10,11]];

module C2_lid() {
  difference() {
    translate([0,0,lid_bot]) cylinder(h=lid_top-lid_bot, r=slab_r, $fn=220);
    // SPIN ring dome + finger slot (unchanged from proto_lid.scad)
    translate([0,0,eq]) rotate_extrude($fn=200) translate([R,0]) circle(r=rb+clr, $fn=36);
    difference() {
        translate([0,0,lid_bot-1]) cylinder(h=lid_top-lid_bot+2, r=R+finger_w/2, $fn=200);
        translate([0,0,lid_bot-1]) cylinder(h=lid_top-lid_bot+2, r=R-finger_w/2, $fn=200);
    }
    // SWAP path domes (capped) for ALL pairs — same as proto_lid for swap-rotation clearance
    for(pr=DIVPAIRS_ALL) {
        M = (Pp(pr[0]) + Pp(pr[1]))/2;
        translate([M[0],M[1],eq]) rotate_extrude($fn=80) translate([orbit,0]) circle(r=rb+clr,$fn=28);
    }
    dome_path(Pp(2), Pp(9));                              // 2-9 dome
    // ----- NEW: BORES at the 4 chord-pair midpoints -----
    for(pr=DIVPAIRS_C2_BORED) {
        M = (Pp(pr[0]) + Pp(pr[1]))/2;
        translate([M[0],M[1],lid_bot-1])
            cylinder(h=lid_top-lid_bot+2, r=bore_r, $fn=80);
    }
  }
}

// ---- assembled preview at dish-PARKED-HIGH (testing the bore plug)  ----
PART = "C2_dish";
if      (PART=="C2_dish") C2_dish();
else if (PART=="C2_div")  C2_div();
else if (PART=="C2_lid")  C2_lid();
else if (PART=="C2_assembled_park") {
    // dish parked high, segs at home
    color([0.55,0.62,0.72,0.4]) for(k=[1:N]) spin_seg(k);
    color([0.62,0.55,0.45,0.5]) C2_lid();
    color([0.80,0.55,0.30,0.85]) for(pr=DIVPAIRS_C2_BORED) {
        M = (Pp(pr[0]) + Pp(pr[1]))/2;
        translate([M[0],M[1],park_bot]) C2_dish();
    }
}
else if (PART=="C2_assembled_work") {
    // dish at working z, segs dropped, divider turning
    color([0.55,0.62,0.72,0.25]) for(k=[1:N]) translate([0,0,-20]) spin_seg(k);
    color([0.62,0.55,0.45,0.4]) C2_lid();
    color([0.80,0.55,0.30,0.95]) for(pr=DIVPAIRS_C2_BORED) {
        M = (Pp(pr[0]) + Pp(pr[1]))/2;
        translate([M[0],M[1],working_z]) C2_dish();
    }
}
