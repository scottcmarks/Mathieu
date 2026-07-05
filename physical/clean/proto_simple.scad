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
R     = 50*SCALE + 2;      // 57.56 — spin-ring radius (2 mm larger per side; Scott 2026-07-03: +4 mm on Ø)
N     = 11;
ball_d= 18*SCALE;          // 20 (ball is stock hardware — must NOT scale with R)
rb    = ball_d/2;          // 10
eq    = ball_d/2;          // 10
apexR = R + 24*SCALE;      // 84.22 — apex ball 0 sits here (outside the ring)
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
function pair_outer_R(i,j) = pair_orbit(i,j) + rb + clr + wall_t/2 + 0.5;   // was +1 fudge — Scott 2026-07-03: shrink all rings 1 mm on Ø
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

// ---- CONTINUOUS SPIN RINGS (Scott 2026-07-03) ----
// The 11 per-station segments are replaced by TWO one-piece rings (inner + outer), continuous
// EXCEPT:
//   * a PADDLE SLOT through both rings at each in-plane pair's midpoint azimuth — the blade at
//     rest is radial (the chord's perpendicular bisector passes through the origin) and spans
//     origin-radii ~29.7..80.7, crossing both rings; slot = blade thin (6) + clr each side = 6.8
//     so the paddle could slide straight up through the resting rings (future actuation);
//   * the BIG GAP in the OUTER ring at station 1 (the deleted outer segment's full wedge) —
//     the apex (0,1) blade rises there. The apex blade never reaches the inner ring (its
//     footprint stays at origin-radius >= 65.9), so the inner ring has NO gap at station 1.
IN_PLANE_PAIRS_SCAD = [[3,4], [5,6], [7,8], [10,11]];
paddle_slot_w = 3*wall_t + 2*clr;                  // 6.8 = div_thin + 2·clr (spelled out: div_thin is defined further down and OpenSCAD does NOT forward-reference — an undef here silently skipped the slot cuts)
module paddle_slots(rc) {
    for (pr = IN_PLANE_PAIRS_SCAD) {
        M = pair_M(pr[0], pr[1]);
        az = atan2(M[1], M[0]);                    // degrees (OpenSCAD trig)
        rotate([0, 0, az])
            translate([rc - wall_t/2 - 1, -paddle_slot_w/2, -0.1])
                cube([wall_t + 2, paddle_slot_w, wall_h + 0.2]);
    }
}
module spin_ring_inner() {
    difference() {
        rotate_extrude($fn=240) translate([inner_R_spin - wall_t/2, 0]) square([wall_t, wall_h]);
        paddle_slots(inner_R_spin);
    }
}
module spin_ring_outer() {
    difference() {
        rotate_extrude($fn=240) translate([outer_R_spin - wall_t/2, 0]) square([wall_t, wall_h]);
        paddle_slots(outer_R_spin);
        // station-1 wedge gap (retained from the deleted outer segment)
        rotate([0, 0, th(1) - half_angle])
            rotate_extrude(angle = 2*half_angle, $fn=120)
                translate([outer_R_spin - wall_t/2 - 1, -0.1]) square([wall_t + 2, wall_h + 0.2]);
    }
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
module swap_ring_local_h(i, j, wh, centered, chord_sides = [0, 180]) {
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
    for (side = chord_sides) {
        rotate([0, 0, chord_deg + side - chord_arc_half_deg])
            rotate_extrude(angle = 2*chord_arc_half_deg, $fn=120)
                translate([outer_R - wall_t/2, z_off]) square([wall_t, wh]);
    }
}
module swap_ring_local(i, j) { swap_ring_local_h(i, j, wall_h, false); }

// IN-PLANE SWAP RINGS — FULL RINGS (Scott 2026-07-03): complete annulus, no arc breaks,
// same wall width as the apex (0,1) ring (apex_wall_h = ball_d + 2·clr = 20.8), centered on
// the ball plane: working Z = [eq−10.4, eq+10.4] = [−0.4, 20.4]. Parked (−21 on the elevator
// frame) the top sits at −0.6, just under the floor. NOTE: at working height these walls
// reach into the lid slab — proto_lid.scad carves a blind annular pocket per pair.
// MERGE RULE (Scott 2026-07-03): the full-size CENTRAL ring's wall bites ~1 mm into each pair
// ring's interior and vice versa; every ring subtracts the others' circular interiors so all
// interiors stay clear (walls blend like soap bubbles where they meet).
module swap_ring(i, j) {
    M = pair_M(i, j);
    difference() {
        translate([M[0], M[1], eq - apex_wall_h/2])
            rotate_extrude($fn=180)
                translate([pair_outer_R(i, j) - wall_t/2, 0]) square([wall_t, apex_wall_h]);
        // keep the central ring's interior clear
        translate([0, 0, eq - apex_wall_h/2 - 0.2])
            cylinder(h = apex_wall_h + 0.4, r = central_R - wall_t/2, $fn=180);
    }
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
    // CLOSED AT THE BOTTOM (Scott 2026-07-03): one continuous 240° arc — from 30° above
    // horizontal on the ball-0 side, around the bottom, to 30° above horizontal on the
    // ball-1 side — replacing the old 3-arc set (2 perp + 1 small bottom chord). The 120°
    // OPENING is centered straight UP, where the ring depends on the LID for ball capture.
    // Local angle map: chord0 direction (local −Y) → world DOWN after the two rotations,
    // so the arc is centered at local −90° with ±120° span.
    translate([0, R, eq])
        rotate([90, 0, 0])
            translate([0, -R, -eq])
                translate([0, R, apex_Z_c()])
                    rotate([0, 90, 0])
                        rotate([0, 0, -90 - 120])
                            rotate_extrude(angle = 240, $fn=180)
                                translate([pair_outer_R(0, 1) - wall_t/2, -apex_wall_h/2])
                                    square([wall_t, apex_wall_h]);
}

// legacy constants — used by other files that import from here
orbit_swap = pair_orbit(5, 6);
outer_R_swap = pair_outer_R(5, 6);

// ---- dividers — ALL are THIN BLADES like the (0,1) paddle (Scott 2026-07-03) ----
// Common blade recipe, per pair (i,j):
//   - THIN along the chord (ball-to-ball line):      div_thin = 3·wall_t = 6
//   - LONG perpendicular to the chord, symmetric
//     about the rotation axis, spanning most of
//     the swap ring's inner diameter:                div_ext(i,j) = 2·(pair_outer_R − wall_t) − 1.2
//   - sized along the rotation axis to the pair's wall height.
// In-plane pairs rotate about the VERTICAL (Z) axis at M; the apex pair rotates about the
// ring axis (world X). Same blade, different axis orientation.
div_thin = 3*wall_t;                               // 6.0 — chord thickness (all pairs)
function pair_div_ext(i,j) = 2*(pair_outer_R(i,j) - wall_t) - 1.2;   // blade length (ring pairs ≈50.8; apex ≈45.3)
// In-plane blade: local X = chord (thin), local Y = perpendicular (long), local Z = vertical.
// Viewer/dispatch translate to M and rotate about Z by chord angle + swap rotation.
module divider_simple_h(i, j, dh, centered) {
    ext = pair_div_ext(i, j);
    z_off = centered ? -dh/2 : 0;
    translate([-div_thin/2, -ext/2, z_off]) cube([div_thin, ext, dh]);
}
// PADDLE WIDTH (Scott 2026-07-03): all paddles are as wide (along their rotation axis) as the
// lid's open finger slot over the spin ring — div_width = ball_d − 4 = 16 < ball Ø. This lets
// the lid's apex paddle slit narrow to 16.8 so balls 0/1 cannot fall out through it.
div_width = ball_d - 4;                            // 16 — matches lid finger_w
// In-plane dividers — width 16 along Z, centered on the ball plane (working Z = [2, 18]).
// Parked top = 18 − 21 = −3, safely under the floor.
module divider_simple(i, j) {
    translate([0, 0, eq - div_width/2]) divider_simple_h(i, j, div_width, false);
}
// Apex blade: local X = ring-axial (tall face spans ball flanks), local Y = chord (thin),
// local Z = perpendicular (long). Rendered in ROOT-LOCAL orientation (viewer just translates).
apex_div_h    = ball_d - 4;                        // 16 = div_width — paddle width matches the lid finger slot (Scott 2026-07-03)
apex_div_thin = div_thin;                          // 6.0 — chord thickness (same recipe as all pairs)
apex_div_ext  = pair_div_ext(0, 1);                // ≈45.3 — same formula as all pairs (follows ring size)
module divider_apex() {
    translate([-apex_div_h/2, -apex_div_thin/2, -apex_div_ext/2])
        cube([apex_div_h, apex_div_thin, apex_div_ext]);
}
// legacy alias — the previously constant div_w for check_simple.py compatibility
div_w = pair_div_w(5, 6);

// ---- CENTRAL (2,9) SWAP RING (Scott 2026-07-03, v2: FULL SIZE + MERGED + TEST TUBES) ----
// Center at the ORIGIN (on the perpendicular bisector P of M(3,4)–M(7,8), which passes
// through the origin since both midpoints sit at radius R·cos(180/N)). SAME SIZE as the
// pair rings — its wall MERGES with all four pair rings (mutual ~1 mm bites); every solid
// subtracts the others' circular interiors so all interiors stay clear.
// TEST TUBES: the two ball corridors extend as tube walls from the ring out to the 2-ball
// and 9-ball stations, ending in a semicircular shell that encloses the resting ball with
// 0.1 mm spacing. All walls are the standard 20.8 band (vertical extrusions — they rise and
// fall past the resting balls safely because their footprint clears the ball by 0.1).
central_R       = pair_outer_R(3, 4);              // 28.11 — FULL pair-ring size
central_div_ext = pair_div_ext(3, 4);              // 51.02 — same blade as the pairs
tube_ir  = rb + 0.1;                               // 10.1 — tube interior half-width (0.1 spacing)
tube_or  = tube_ir + wall_t;                       // 12.1
module central_tube(s) {
    az = atan2(P(s)[1], P(s)[0]);
    rotate([0, 0, az]) translate([0, 0, eq - apex_wall_h/2]) {
        // two parallel corridor walls from inside the ring band out to the ball center
        for (sy = [-1, 1])
            translate([central_R - wall_t, sy == 1 ? tube_ir : -tube_or, 0])
                cube([R - central_R + wall_t, wall_t, apex_wall_h]);
        // test-tube end: semicircular shell around the ball, closed side outward
        translate([R, 0, 0]) difference() {
            cylinder(h = apex_wall_h, r = tube_or, $fn=90);
            translate([0, 0, -0.1]) cylinder(h = apex_wall_h + 0.2, r = tube_ir, $fn=90);
            translate([-tube_or - 1, -tube_or - 1, -0.1])
                cube([tube_or + 1, 2*tube_or + 2, apex_wall_h + 0.2]);   // keep outward half only
        }
    }
}
module swap_ring_central() {
    difference() {
        union() {
            translate([0, 0, eq - apex_wall_h/2])
                rotate_extrude($fn=180)
                    translate([central_R - wall_t/2, 0]) square([wall_t, apex_wall_h]);
            central_tube(2);
            central_tube(9);
        }
        // ball corridors through the ring wall (width matches the tube interior, 20.2).
        // The cut starts 4 inside the wall band: the annulus CURVES inward at the corridor's
        // angular edges (inner surface at x≈25.2 when |y|=10.1), and a box starting at the
        // nominal inner surface left a thin curved wedge that clipped the transiting ball.
        for (s = [2, 9]) {
            az = atan2(P(s)[1], P(s)[0]);
            rotate([0, 0, az])
                translate([central_R - wall_t/2 - 4, -tube_ir, eq - apex_wall_h/2 - 0.1])
                    cube([wall_t + 8, 2*tube_ir, apex_wall_h + 0.2]);
        }
        // merge rule: keep the four pair rings' circular interiors clear
        for (pr = IN_PLANE_PAIRS_SCAD) {
            Mpr = pair_M(pr[0], pr[1]);
            translate([Mpr[0], Mpr[1], eq - apex_wall_h/2 - 0.2])
                cylinder(h = apex_wall_h + 0.4, r = pair_outer_R(pr[0], pr[1]) - wall_t/2, $fn=120);
        }
        // keep own interior clear (trims the tube-wall stubs inside the ring)
        translate([0, 0, eq - apex_wall_h/2 - 0.2])
            cylinder(h = apex_wall_h + 0.4, r = central_R - wall_t/2, $fn=180);
    }
}
// Central divider — same thin blade as the pairs; at REST its long axis lies ALONG line P
// (the viewer applies base rotation azimuth(P) − 90°).
module divider_central() {
    translate([0, 0, eq - apex_div_h/2 - 0.5])
        translate([-div_thin/2, -central_div_ext/2, 0])
            cube([div_thin, central_div_ext, apex_div_h]);
}

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
else if (PART == "spin_ring_inner") spin_ring_inner();
else if (PART == "spin_ring_outer") spin_ring_outer();
else if (PART == "central_ring") swap_ring_central();
else if (PART == "central_divider") divider_central();
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
