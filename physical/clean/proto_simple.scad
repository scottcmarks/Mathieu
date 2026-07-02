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
wall_t = 2.0;              // wall thickness (radial)
wall_h = rb + 0.5;         // wall height (z); slightly above ball center to provide good lateral grip
clr    = 0.4;

inner_R_spin = R - rb - clr - wall_t/2;   // 44.66 — radial centerline of inner spin wall
outer_R_spin = R + rb + clr + wall_t/2;   // 66.46 — radial centerline of outer spin wall

function angleOf(k) = -90 + (k-1)*(360/N);
function th(k) = -angleOf(k);
function P(k) = [R*cos(angleOf(k)), -R*sin(angleOf(k))];
function pair_M(i,j) = (P(i)+P(j))/2;

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

// ---- swap ring (SEGMENTED: 2 arc pieces at perpendicular azimuths, NOT a full annulus) ----
// Continuous 360° outer wall would (a) block ball entry/exit, (b) overlap the spin-seg arcs
// nearby. Place 2 arc pieces at azimuths PERPENDICULAR to the chord direction, so they confine
// the ball outward during the divider sweep but leave the entry/exit azimuths (along the chord)
// open. Each arc is narrow enough to fit OUTSIDE the spin band (the inner arc is INSIDE the
// band's inner wall, the outer arc is OUTSIDE the band's outer wall).
orbit_swap = rb + 1.5;                       // 11.5 — ball orbit radius around M
outer_R_swap = orbit_swap + rb + clr + wall_t/2;   // 22.4 — wall centerline from M
swap_arc_half_deg = 25;                       // each arc spans 50° centered on perpendicular axis
module swap_ring(i, j) {
    M = pair_M(i, j);
    // chord direction T = P(j) - P(i), perpendicular = T rotated 90° in xy. OpenSCAD atan2() RETURNS DEGREES.
    Tv = P(j) - P(i);
    base_perp_deg = atan2(-Tv[0], Tv[1]);
    translate([M[0], M[1], 0])
        for (side = [0, 180]) {                 // two arcs at perpendicular azimuths (180° apart)
            rotate([0, 0, base_perp_deg + side - swap_arc_half_deg])
                rotate_extrude(angle = 2*swap_arc_half_deg, $fn=120)
                    translate([outer_R_swap - wall_t/2, 0])
                        square([wall_t, wall_h]);
        }
}

// ---- divider (the diameter of the swap ring; TRIMMED to fit inside swap-ring inner radius) ----
div_w = 2;                                    // divider thickness — fits in the 5° inter-seg gap at r=43.59
div_l_half = orbit_swap + rb - 0.5;            // 21.0 — just inside swap-ring inner edge (21.4) by 0.4 mm
module divider_simple() {
    translate([-div_w/2, -div_l_half, 0]) cube([div_w, 2*div_l_half, wall_h+2]);
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
else if (PART == "swap_ring") swap_ring(5, 6);
else if (PART == "divider")   divider_simple();
else if (PART == "base_spin") base_spin();
else if (PART == "base_swap") base_swap(5, 6);
else {
    color([0.6, 0.75, 0.9, 0.95]) for (k=[1:N]) spin_segment_real(k);
    color([0.9, 0.55, 0.45, 0.95]) swap_ring(5, 6);
    color([0.85, 0.35, 0.65, 0.95]) translate([pair_M(5,6)[0], pair_M(5,6)[1], 0]) divider_simple();
}
