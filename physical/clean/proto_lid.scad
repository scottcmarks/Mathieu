// TRACK-2 LID — opaque top piece whose UNDERSIDE is channelled to capture the balls past their equators
// =============================================================================
// "Subsequent thought" (Scott): provide the over-equator CAPTURE from above, with channels cut into the
// underside of a new opaque lid that MATCH the channels in the pieces we already have:
//   * SPIN ring  -> an over-equator channel with a FINGER SLOT open to the sky (capture + you can spin).
//   * SWAP paths -> the COMPLETE upper half is capped (swap hidden; could be clear windows) — no slot.
// The lid is fixed; a ball is under SOME lid channel at every spin/swap position, so the lid is the
// continuous TOP of the any-orientation capture (walls give the sides/bottom; deep 2-9 ball is in its lane).
//   openscad -o lid.stl -D 'PART="lid"' proto_lid.scad
SCALE=20/18; R=50*SCALE+2; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2; apexR=R+24*SCALE;   // R +2 → object 4 mm larger (Scott 2026-07-03)
tube=rb+0.3; wall_t=2.0; clr=0.4;                                                              // wall_t 2 mm to match proto_simple.scad
// Match proto_simple.scad exactly so lid seg-slots align with the spin walls (formula, not hardcode).
inner_R_spin = R - rb - clr - wall_t/2;         // was hardcoded 44.66 — now = R − 11.4
outer_R_spin = R + rb + clr + wall_t/2;         // was hardcoded 66.46 — now = R + 11.4
apex_h       = 24*SCALE/2;                       // 13.33 — apex_half_chord
// per-pair orbit radius = half-chord (varies: ring pairs 15.65, apex 13.33)
function pair_orbit_lid(i,j) = norm(P(j)-P(i))/2;
lid_bot=eq+1.5;                     // 11.5  lid underside (just over the equator -> lips retain)
lid_top=eq+rb+4;                    // 24    lid top (above the crown)
finger_w=ball_d-4;                  // 16   finger-slot width (< ball_d=20 -> ball can't lift out)
// slab_r only needs to cover the RING pairs' swap footprints; apex (0,1) is a vertical shaft below
// the plane and doesn't need overhang. Cover R+ring_orbit+rb+margin ≈ 55.56+15.65+10+4 = 85.21.
slab_r = 85.5;                     // was 113.55 (needed for horizontal apex torus, no longer)
function angleOf(k)=-90+(k-1)*(360/N);
function P(k)= k==0?[0,apexR]:[R*cos(angleOf(k)),-R*sin(angleOf(k))];
function mid(i,j)=[(P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2];
// (0,1) intentionally omitted — apex swap is now VERTICAL (proto_simple.scad::swap_ring_apex_vertical),
// so ball 0 lives BELOW the floor and never traces a horizontal torus under the lid. Ball 1 stays at
// its spin-channel station; the existing spin-ring torus already carves its clearance.
DIVPAIRS=[[3,4],[5,6],[7,8],[10,11]];

// a ball-dome clearance: a full ball-sphere; since the lid lives above lid_bot it only carves the DOME
module dome(p){ translate([p[0],p[1],eq]) sphere(r=rb+clr, $fn=32); }
// a swept dome channel between two xy points (capped — for swap paths)
module dome_path(a,b){ hull(){ dome(a); dome(b); } }

module lid(){
  difference(){
    translate([0,0,lid_bot]) cylinder(h=lid_top-lid_bot, r=slab_r, $fn=220);
    // ---- SPIN ring: over-equator dome channel + a through FINGER SLOT (open to the sky) ----
    translate([0,0,eq]) rotate_extrude($fn=200) translate([R,0]) circle(r=rb+clr, $fn=36);   // dome clearance (ring)
    difference() {                                                                            // finger slot through the lid
        translate([0,0,lid_bot-1]) cylinder(h=lid_top-lid_bot+2, r=R+finger_w/2, $fn=200);
        translate([0,0,lid_bot-1]) cylinder(h=lid_top-lid_bot+2, r=R-finger_w/2, $fn=200);
    }
    // ---- SWAP paths: dome channels FULLY capped (no finger slot) -> swap hidden ----
    for(pr=DIVPAIRS){ M=mid(pr[0],pr[1]); orb=pair_orbit_lid(pr[0],pr[1]);                     // per-pair orbit torus in the lid
        translate([M[0],M[1],eq]) rotate_extrude($fn=80) translate([orb,0]) circle(r=rb+clr,$fn=28); }
    // ---- SWAP-RING POCKETS: the full tall swap rings (width 20.8 centered on ball plane →
    //      working top Z=20.4) and tall paddles (top 20.9) reach into the lid slab. Blind
    //      cylindrical pocket per pair: radius = ring outer surface + clr, top at 21.9 (leaves
    //      a 2.1 mm roof — lid stays one piece, swap still hidden from above).
    for(pr=DIVPAIRS){ M=mid(pr[0],pr[1]); orb=pair_orbit_lid(pr[0],pr[1]);
        pocket_r = orb + rb + clr + wall_t/2 + 0.5 + wall_t/2 + clr;   // outer_R + wall_t/2 + clr ≈ 29.51
        translate([M[0],M[1],lid_bot-0.1]) cylinder(h=10.5, r=pocket_r, $fn=90); }
    // Central (2,9) swap-ring pocket — now FULL pair-ring size (centerline 28.11):
    // 28.11 + wall_t/2 + clr ≈ 29.51, same as the pair pockets.
    translate([0,0,lid_bot-0.1]) cylinder(h=10.5, r=29.51, $fn=90);
    // Tunnel stadium pockets: the (2,9) test-tube walls (to Z=20.4) and the transiting balls
    // pass under the lid along the lines origin→P(2) and origin→P(9). Hull of two cylinders
    // (r 12.6 = tube outer 12.1 + clr) from radial 24 (inside the central pocket) out past
    // the tube end cap (R + 12.6 = 70.16 ≥ cap outer 69.66 + clr).
    for (s=[2,9]) {
        hull() {
            translate([P(s)[0]*24/R, P(s)[1]*24/R, lid_bot-0.1]) cylinder(h=10.5, r=12.6, $fn=60);
            translate([P(s)[0],      P(s)[1],      lid_bot-0.1]) cylinder(h=10.5, r=12.6, $fn=60);
        }
    }
    // 2-9 dome_path DROPPED (2026-07-03) — that channel was never committed to and isn't
    // needed by the current architecture.
    // ---- SPIN-SEG LID SLOTS: through-slots for stations 2..N (BOTH inner + outer walls)
    //      so a risen seg can pass through the lid without collision. Station 1 gets NO
    //      spin-wall slot (Scott 2026-07-03) — its inner wall stays put during the (0,1)
    //      swap (ball 1's Y-range never dips below its rest inner surface at 47.56), and
    //      its outer wall is gone entirely (replaced by the apex paddle at rest). Instead
    //      of a spin-wall slot at station 1, the lid gets the APEX PADDLE SLIT below.
    for (k = [2:N]) {
      rotate([0, 0, (-angleOf(k)) - (360/N/2 - 5.0/2)])
        rotate_extrude(angle = 2*(360/N/2 - 5.0/2), $fn=120)
          for (rc = [inner_R_spin, outer_R_spin])
            translate([rc - wall_t/2 - clr, lid_bot]) square([wall_t + 2*clr, lid_top - lid_bot + 0.5]);
    }
    // ---- APEX (0,1) PADDLE SLIT (station 1's swap-wall-divider slot per Scott's spec) ----
    // Through-hole in the lid at the (0,1) ring axis so the paddle can protrude AND rotate
    // through the lid without intersection. Ring axis passes through (0, R+apex_h, eq) with
    // direction world +X. Paddle corner-to-axis distance is
    //   √((apex_div_ext/2)² + (apex_div_thin/2)²) = √(23.13² + 3²) ≈ 23.32 mm
    // (post-shrink paddle: apex_div_ext = 46.26). A cylinder of radius 23.32 + clr = 23.72
    // contains the entire swept envelope. Axial length exceeds the paddle X span (apex_div_h
    // = 22.8) by clr each side.
    // NARROWED (Scott 2026-07-03): the paddles are now div_width = 16 wide, so the slit's
    // axial width drops to 16.8 < ball Ø 20 — balls 0/1 CANNOT fall out through it.
    apex_paddle_corner = sqrt(pow(46.26/2, 2) + pow(6/2, 2));  // ≈ 23.32
    apex_paddle_h_half = 16/2 + clr;                            // 8.4 — paddle width 16 + clr
    apex_paddle_R      = apex_paddle_corner + clr;              // 23.72
    translate([0, R + apex_h, eq])
      rotate([0, 90, 0])
        cylinder(h = 2*apex_paddle_h_half, r = apex_paddle_R, center = true, $fn = 60);
    // BALL TRANSIT TORUS: with the slit too narrow for a ball, the over-the-top (0,1) transit
    // needs its own clearance — a torus (tube r = rb + clr) around the apex orbit circle
    // (radius apex_h = 13.33 about the world-X axis through (0, R+apex_h, eq)). Only its top
    // portion intersects the lid slab. At the two REST stations (orbit points at ±Y,
    // horizontal) the carve tops out at Z = 20.4, leaving a 3.6 mm roof — resting balls
    // stay captured; the open-to-sky stretch exists only mid-transit (swap in progress).
    translate([0, R + apex_h, eq])
      rotate([0, 90, 0])
        rotate_extrude($fn = 100)
          translate([apex_h, 0]) circle(r = rb + clr, $fn = 36);
  }
}

PART="lid";
if(PART=="lid") color([0.62,0.55,0.45]) lid();
else { color([0.62,0.55,0.45,0.5]) lid(); for(k=[1:N]) translate([P(k)[0],P(k)[1],eq]) color([0.9,0.92,1]) sphere(r=rb,$fn=24); }
