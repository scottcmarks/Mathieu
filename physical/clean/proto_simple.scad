// SIMPLE WALL CONCEPT — Scott's idea: walls are just rectangular vertical pieces.
// =============================================================================
// Each "wall" is a plain rectangular bar — width ~ball_d, height ~rb (lower hemisphere of ball),
// thickness wall_t. The walls ONLY provide LATERAL (in-plane) confinement; the over-equator
// retention is provided by the LID above, which has spin-channel and swap-channel torus carves
// in its underside. So the walls don't need over-equator grooves — they just need to be in the
// right places.
//
// Two sets of walls share the architecture:
//   SPIN-RING walls: form the inner and outer banks of the spin channel (full ring, ~11 segments).
//   SWAP-RING walls: form the OUTER bank of each pair's swap channel around M. The divider
//                    provides the diameter (inner confinement).
// Each set sits on its own base. Spin-base is UP at rest; swap-base lifts during a swap and the
// spin walls at the affected stations drop to open the path between channel and orbit.
//   PART in: spin_seg | swap_ring | divider | base_spin | base_swap | all

SCALE = 20/18;
R     = 50*SCALE;          // 55.56
N     = 11;
ball_d= 18*SCALE;          // 20
rb    = ball_d/2;          // 10
eq    = ball_d/2;          // 10
apexR = R + 24*SCALE;      // 82.22 — apex ball 0 sits here (outside the ring)
wall_t = 2.0;              // wall thickness (radial)
wall_h = rb + 0.5;         // wall height (z); slightly above ball center to provide good lateral grip
clr    = 0.4;
// all 5 neighbour swap pairs (5 divider mechanisms)
DIVPAIRS = [[0,1], [3,4], [5,6], [7,8], [10,11]];

inner_R_spin = R - rb - clr - wall_t/2;   // 44.66 — radial centerline of inner spin wall
outer_R_spin = R + rb + clr + wall_t/2;   // 66.46 — radial centerline of outer spin wall

function angleOf(k) = -90 + (k-1)*(360/N);
function th(k) = -angleOf(k);
function P(k) = k==0 ? [0, apexR] : [R*cos(angleOf(k)), -R*sin(angleOf(k))];   // ball 0 lives OUTSIDE the ring at the apex
function pair_M(i,j) = (P(i)+P(j))/2;
function pair_orbit(i,j) = norm(P(j)-P(i))/2;   // half-chord = orbit radius from M (ring pairs 15.65; apex 13.33)
function pair_outer_R(i,j) = pair_orbit(i,j) + rb + clr + wall_t/2 + 1;
function pair_div_w(i,j) = 2*(pair_orbit(i,j) - rb - clr);   // paddle width — face touches ball inner surface with clr clearance

// ---- spin ring segment (one of 11): inner+outer arc walls between two adjacent stations ----
// Each segment spans one detent (1/11 of the ring) centered at station k.
gap_deg = 5.0;                            // angular gap between adjacent segments (wider, to let divider through)
half_angle = 360/N/2 - gap_deg/2;

module spin_segment(k) {
    rotate([0,0, th(k)])
    rotate_extrude(angle=2*half_angle, $fn=120)
        for (rc = [inner_R_spin, outer_R_spin])
            translate([rc - wall_t/2, 0]) square([wall_t, wall_h]);
}
// (rotate_extrude wraps starting at +x; rotate first puts +x at station k azimuth then we extrude
//  from -half_angle to +half_angle... actually rotate_extrude only extrudes CCW from 0°. So:)
module spin_segment_real(k) {
    rotate([0,0, th(k) - half_angle]) rotate_extrude(angle=2*half_angle, $fn=120)
        for (rc = [inner_R_spin, outer_R_spin])
            translate([rc - wall_t/2, 0]) square([wall_t, wall_h]);
}
module spin_segment_inner(k) {
    rotate([0, 0, th(k) - half_angle]) rotate_extrude(angle = 2*half_angle, $fn=120)
        translate([inner_R_spin - wall_t/2, 0]) square([wall_t, wall_h]);
}
module spin_segment_outer(k) {
    rotate([0, 0, th(k) - half_angle]) rotate_extrude(angle = 2*half_angle, $fn=120)
        translate([outer_R_spin - wall_t/2, 0]) square([wall_t, wall_h]);
}

// ---- swap ring (SEGMENTED: 4 arc pieces — 2 perpendicular + 2 along chord) ----
// Balls stay at half-chord distance from M throughout the orbit (no radial transit); divider paddle
// alone drives the swap. Four arcs per pair: 2 PERPENDICULAR to chord + 2 along CHORD direction.
// Pair-parameterized so ring pairs (half-chord 15.65) and apex (0,1) (half-chord 13.33) both work.
perp_arc_half_deg = 30;                            // perpendicular arcs span 60°
chord_arc_half_deg = 12;                           // chord arcs span 24°
// swap_ring_local_h(i,j, wh, centered): 4-arc geometry AT LOCAL ORIGIN, parameterized by wall
// axial height `wh` and whether it's centered on local Z=0 (centered=true) or bottom-anchored
// (centered=false). swap_ring_local is a thin wrapper preserving legacy behavior.
module swap_ring_local_h(i, j, wh, centered) {
    outer_R = pair_outer_R(i, j);
    Tv      = P(j) - P(i);
    perp_deg  = atan2(-Tv[0], Tv[1]);
    chord_deg = atan2(Tv[1], Tv[0]);
    z_off = centered ? -wh/2 : 0;
    for (side = [0, 180]) {
        rotate([0, 0, perp_deg + side - perp_arc_half_deg])
            rotate_extrude(angle = 2*perp_arc_half_deg, $fn=120)
                translate([outer_R - wall_t/2, z_off]) square([wall_t, wh]);
    }
    for (side = [0, 180]) {
        rotate([0, 0, chord_deg + side - chord_arc_half_deg])
            rotate_extrude(angle = 2*chord_arc_half_deg, $fn=120)
                translate([outer_R - wall_t/2, z_off]) square([wall_t, wh]);
    }
}
module swap_ring_local(i, j) { swap_ring_local_h(i, j, wall_h, false); }

module swap_ring(i, j) {
    M = pair_M(i, j);
    translate([M[0], M[1], 0]) swap_ring_local(i, j);
}

// APEX (0,1) SWAP RING — vertical ring, rotated + Z-parked (Scott's 2026-07-02 iteration).
// Starting from the vertical ring in the YZ plane centered at (0, R, eq−half_chord), rotate
// the WHOLE group by +π/2 about ball 1's world-+X tangent axis. That sends:
//   ball 0: (0, R, eq−2·half_chord) → (0, R+2·half_chord, eq) = (0, apexR, eq)  ← horizontal apex
//   ball 1: (0, R, eq)              stays put (on the rotation axis)
//   ring center: (0, R, eq−half_chord) → (0, R+half_chord, eq) = (0, R+13.33, eq)
// Ball 0 is now IN THE HORIZONTAL PLANE with all the other balls (Scott's design goal). Ring plane
// stays YZ (X=0), ring axis stays world +X. Balls sit at the ±Y ends of the ring's orbit diameter.
//   - Ball 1 at ring angular 180° (world −Y from center)
//   - Ball 0 at ring angular   0° (world +Y from center)
// The ring geometry rendered by this module is at the SWAP-UP Z position (ring center Z = eq); at
// REST the viewer parks it Z=−ball_d (drops it ball-diameter below the horizontal plane) so its
// segments don't obstruct spin. During a swap it rises back up.
function apex_half_chord() = norm(P(0)-P(1))/2;
function apex_Z_c() = eq - apex_half_chord();     // = -3.33 — the ORIGINAL vertical-ring center Z
function apex_ring_center_Y() = R + apex_half_chord();  // = 68.89 — after Scott's rotation
apex_wall_h = ball_d + 2*clr;                     // 20.8 — tall enough to capture ball X-extent past its center
module swap_ring_apex_vertical() {
    // Apex (0,1) ring — rotated by +π/2 about ball 1's world-+X tangent axis; walls are TALL
    // (apex_wall_h = ball_d + 2·clr = 20.8) and CENTERED on ball X-center (world X=0) so they
    // reach past both flanks of the ball. Rendered here at the SWAP-UP Z (ring center Z = eq); the
    // viewer parks it Z − ball_d at rest and animates the rise during swap.
    // Result during swap: ring center at (0, R+apex_half_chord, eq) = (0, 68.89, 10). Balls stay
    // at Z=eq throughout; during the π orbit around world +X, one ball dips to Z=eq−apex_half_chord
    // = −3.33 and the other rises to Z=eq+apex_half_chord = +23.33.
    translate([0, R, eq])
        rotate([90, 0, 0])
            translate([0, -R, -eq])
                translate([0, R, apex_Z_c()])
                    rotate([0, 90, 0])
                        swap_ring_local_h(0, 1, apex_wall_h, true);
}

// legacy constants — used by other files that import from here
orbit_swap = pair_orbit(5, 6);
outer_R_swap = pair_outer_R(5, 6);

// ---- divider (WIDE PADDLE — pair-parameterized) ----
// Chord width brings side faces just outside balls' M-facing surfaces (clearance clr=0.4 mm).
// Perpendicular half-length 5 mm — corners stay strictly inside the band's empty channel space.
div_l_half = 5;
module divider_simple_h(i, j, dh, centered) {
    dw = pair_div_w(i, j);
    z_off = centered ? -dh/2 : 0;
    translate([-dw/2, -div_l_half, z_off]) cube([dw, 2*div_l_half, dh]);
}
module divider_simple(i, j) { divider_simple_h(i, j, wall_h + 2, false); }
// Apex divider: taller (past ball equator on BOTH sides) and X-centered — the paddle actually
// reaches past the ball's flanks so its side faces snuggle the balls it's paddling.
apex_div_h = apex_wall_h + 2;                     // 22.8 — matches apex ring height + small margin
module divider_apex() {
    // Same local-origin geometry as divider_simple(0,1) but taller + centered so, once translated
    // to the apex ring center and rotated about world +X, the paddle's tall face fully overlaps
    // the ball's axial extent.
    divider_simple_h(0, 1, apex_div_h, true);
}
// legacy alias — the previously constant div_w for check_simple.py compatibility
div_w = pair_div_w(5, 6);

// ---- bases (just visualization — flat plates under the walls) ----
base_t = 1.5;
module base_spin() {
    // an annular floor that the spin walls sit on
    difference() {
        cylinder(h=base_t, r=outer_R_spin+wall_t+3, $fn=180);
        translate([0,0,-0.1]) cylinder(h=base_t+0.2, r=inner_R_spin-wall_t-3, $fn=180);
    }
}
module base_swap(i, j) {
    // a small disk under the swap ring (one per pair)
    M = pair_M(i, j);
    translate([M[0], M[1], 0])
        cylinder(h=base_t, r=outer_R_swap+wall_t+3, $fn=120);
}

PART = "all";
if      (PART == "spin_seg")  spin_segment_real(1);
else if (PART == "spin_seg_1_inner") spin_segment_inner(1);
else if (PART == "spin_seg_1_outer") spin_segment_outer(1);
else if (PART == "swap_ring") swap_ring(5, 6);
else if (PART == "divider")   divider_simple(5, 6);
else if (PART == "base_spin") base_spin();
else if (PART == "base_swap") base_swap(5, 6);
// STATIC snapshot of the OTHER RING pairs' swap rings + dividers at up-position. Excludes (5,6)
// (which animates) and (0,1) (which is rendered separately as the VERTICAL apex ring).
else if (PART == "other_pairs") {
    for (pr = [[3,4], [7,8], [10,11]]) {
        swap_ring(pr[0], pr[1]);
        Tv = P(pr[1]) - P(pr[0]);
        baseAng = atan2(Tv[1], Tv[0]);
        translate([pair_M(pr[0], pr[1])[0], pair_M(pr[0], pr[1])[1], 0])
            rotate([0, 0, baseAng]) divider_simple(pr[0], pr[1]);
    }
}
// VERTICAL APEX (0,1) swap ring — Scott's design
else if (PART == "apex_vertical") swap_ring_apex_vertical();
// per-pair renders (unused for now but kept for future animation extension)
else if (PART == "swap_ring_01") swap_ring(0, 1);
else if (PART == "swap_ring_34") swap_ring(3, 4);
else if (PART == "swap_ring_56") swap_ring(5, 6);
else if (PART == "swap_ring_78") swap_ring(7, 8);
else if (PART == "swap_ring_1011") swap_ring(10, 11);
else if (PART == "divider_01") divider_apex();
else if (PART == "divider_34") divider_simple(3, 4);
else if (PART == "divider_56") divider_simple(5, 6);
else if (PART == "divider_78") divider_simple(7, 8);
else if (PART == "divider_1011") divider_simple(10, 11);
else {
    // full preview: all 5 swap rings + dividers around the spin ring
    color([0.6, 0.75, 0.9, 0.95]) for (k=[1:N]) spin_segment_real(k);
    for (pr = DIVPAIRS) {
        color([0.9, 0.55, 0.45, 0.95]) swap_ring(pr[0], pr[1]);
        color([0.85, 0.35, 0.65, 0.95]) {
            Tv = P(pr[1]) - P(pr[0]);
            baseAng = atan2(Tv[1], Tv[0]);
            translate([pair_M(pr[0], pr[1])[0], pair_M(pr[0], pr[1])[1], 0])
                rotate([0, 0, baseAng]) divider_simple(pr[0], pr[1]);
        }
    }
}
