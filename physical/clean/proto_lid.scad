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
orbit=rb+3.0/2+0.5;                 // 12  ball orbit in a divider swap-ring (matches proto_wall)
lid_bot=eq+1.5;                     // 11.5  lid underside (just over the equator -> lips retain)
lid_top=eq+rb+4;                    // 24    lid top (above the crown)
finger_w=ball_d-4;                  // 16   finger-slot width (< ball_d=20 -> ball can't lift out)
slab_r=R+orbit+tube+3;              // 80.9  covers the ring + divider swing-out + 2-9
function angleOf(k)=-90+(k-1)*(360/N);
function P(k)= k==0?[0,apexR]:[R*cos(angleOf(k)),-R*sin(angleOf(k))];
function mid(i,j)=[(P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2];
DIVPAIRS=[[0,1],[3,4],[5,6],[7,8],[10,11]];

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
    for(pr=DIVPAIRS){ M=mid(pr[0],pr[1]);                                                     // divider swing-circle (orbit) dome
        translate([M[0],M[1],eq]) rotate_extrude($fn=80) translate([orbit,0]) circle(r=rb+clr,$fn=28); }
    dome_path(P(2),P(9));                                                                     // 2-9 shallow cross dome
  }
}

PART="lid";
if(PART=="lid") color([0.62,0.55,0.45]) lid();
else { color([0.62,0.55,0.45,0.5]) lid(); for(k=[1:N]) translate([P(k)[0],P(k)[1],eq]) color([0.9,0.92,1]) sphere(r=rb,$fn=24); }
