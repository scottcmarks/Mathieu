// TRACK-2 LID — opaque top piece whose UNDERSIDE is channelled to capture the balls past their equators
// =============================================================================
// "Subsequent thought" (Scott): provide the over-equator CAPTURE from above, with channels cut into the
// underside of a new opaque lid that MATCH the channels in the pieces we already have:
//   * SPIN ring  -> an over-equator channel with a FINGER SLOT open to the sky (capture + you can spin).
//   * SWAP paths -> the COMPLETE upper half is capped (swap hidden; could be clear windows) — no slot.
// The lid is fixed; a ball is under SOME lid channel at every spin/swap position, so the lid is the
// continuous TOP of the any-orientation capture (walls give the sides/bottom; deep 2-9 ball is in its lane).
//   openscad -o lid.stl -D 'PART="lid"' proto_lid.scad
SCALE=20/18; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2; apexR=R+24*SCALE;
tube=rb+0.3; wall_t=1.5*SCALE; clr=0.4;
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
    dome_path(P(2),P(9));                                                                     // 2-9 shallow cross dome
    // ---- SPIN-SEG LID SLOTS: through-holes matching spin_segment_real(k) so a risen seg
    //      passes cleanly through the lid. Segs lift by 21 mm (ball_d + clr) so their bottoms
    //      clear the ball top at Z=20; wall top at Z=31.5 protrudes 7.5 mm above lid_top=24.
    //      Slot Z=[11.5, 24.5] cuts the entire lid thickness plus 0.5 mm; radial clearance
    //      0.4 mm each side removes only the outer 0.4 mm of the over-equator lips
    //      (lips r=[45.16, 47.56] and r=[63.56, 65.96]) — 2.0 mm of lip remains, still
    //      captures the ball whose dome inner surface at Z=15 is at r=46.90.
    for (k = [1:N]) {
      // Station 1 no longer has an OUTER spin-seg wall (deleted 2026-07-03 — the enlarged
      // apex divider paddle covers that region), so it only needs the INNER slot. Every other
      // station keeps both.
      rcs = (k == 1) ? [44.66] : [44.66, 66.46];
      rotate([0, 0, (-angleOf(k)) - (360/N/2 - 5.0/2)])
        rotate_extrude(angle = 2*(360/N/2 - 5.0/2), $fn=120)
          for (rc = rcs)
            translate([rc - 2.0/2 - 0.4, 11.5]) square([2.0 + 0.8, 13.0]);
    }
    // ---- APEX (0,1) PADDLE SLIT — through-hole in the lid at the (0,1) ring axis so the
    //      thin blade can protrude AND rotate through the lid without intersection.
    //      Ring axis (during swap-up) passes through (0, R+apex_h, eq) = (0, 68.89, 10) with
    //      direction world +X. The paddle's corner-to-axis distance is
    //        sqrt((apex_div_ext/2)^2 + (apex_div_thin/2)^2) ≈ sqrt(23.73^2 + 3^2) ≈ 23.92 mm
    //      so a cylinder of radius 23.92 + clr = 24.32 around the ring axis contains the
    //      entire swept envelope. Extend the axial (X) length past the paddle's own X span
    //      (apex_div_h = 22.8) by clr on each side.
    apex_h             = 24*SCALE/2;     // 13.33 — apex_half_chord (Y offset from spin ring to ring axis)
    apex_paddle_h_half = 22.8/2 + 0.4;   // 11.8 — half the paddle X + clr
    apex_paddle_R      = 23.92 + 0.4;    // 24.32 — half the paddle sweep radius + clr
    translate([0, R + apex_h, eq])       // world (0, 68.89, 10) — ring axis at swap-up Z
      rotate([0, 90, 0])                 // cylinder default is +Z; rotate so it lies along +X
        cylinder(h = 2*apex_paddle_h_half, r = apex_paddle_R, center = true, $fn = 60);
  }
}

PART="lid";
if(PART=="lid") color([0.62,0.55,0.45]) lid();
else { color([0.62,0.55,0.45,0.5]) lid(); for(k=[1:N]) translate([P(k)[0],P(k)[1],eq]) color([0.9,0.92,1]) sphere(r=rb,$fn=24); }
