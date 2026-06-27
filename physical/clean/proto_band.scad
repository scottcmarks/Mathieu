// M12 ALTERNATIVE ARCHITECTURE — the pocket-tiling spin band (concept geometry)
// =============================================================================
// The spin feel rests on this: a FIXED precise circular channel (over-equator lip + finger
// chamfer) whose floor has a ROUND well at each of the 11 stations. A ROUND pocket-disc fills
// each well FLUSH at rest, so the rolling surface is continuous and a finger spins the ring
// with zero slop. Round = rotation-invariant: after a swap the rotor may settle at any angle,
// yet its disc still fills the well flush (no funnel, no bump). The disc carries a shallow
// ball-seat (the detent); during a swap the disc + ball EASE down into the well and the rotary
// pocket below carries the ball — that mechanism is the next piece; this file is the band.
//   openscad -o proto_band.stl  -D 'PART="band"'   proto_band.scad
//   openscad -o proto_discs.stl -D 'PART="discs"'  proto_band.scad
SCALE   = 1.25;
R       = 50*SCALE;            // ring radius (62.5)
N       = 11;
ball_d  = 18*SCALE;            // 22.5
rb      = ball_d/2;            // 11.25
eq      = ball_d/2;            // ball-centre height (bottom = 0)
tube    = rb + 0.3;            // channel tube radius
spin_top= eq + sqrt(tube*tube - rb*rb) + 1.5;     // channel mouth (over-equator lip) height
wall_t  = 1.5*SCALE;           // wall beyond the tube
chamf   = 1.5*SCALE;           // finger chamfer on the rim lips
floorz  = eq - tube;           // channel floor level (torus bottom), ~ -0.3
rw      = rb + 1.5;            // station well / pocket radius (round)
dw      = 16*SCALE;            // well depth (room for the ~6 mm ease + the pocket grip below)
disc_h  = 4.5;                 // pocket-disc thickness
clr     = 0.4;                 // disc-to-well running clearance

function angleOf(i) = -90 + (i-1)*(360/N);
function Pp(i) = [R*cos(angleOf(i)), -R*sin(angleOf(i))];

// the continuous precise channel: annular wall, carved ball-torus, chamfered finger lips
module band_walls() {
    difference() {
        difference() {
            cylinder(h=spin_top, r=R+tube+wall_t, $fn=240);
            translate([0,0,-0.1]) cylinder(h=spin_top+0.2, r=R-tube-wall_t, $fn=240);
        }
        translate([0,0,eq]) rotate_extrude($fn=240) translate([R,0]) circle(r=tube, $fn=40);
        rotate_extrude($fn=200) polygon([[R+tube,spin_top],[R+tube+wall_t+1,spin_top-chamf],
                                         [R+tube+wall_t+1,spin_top+2],[R+tube,spin_top+2]]);
        rotate_extrude($fn=200) polygon([[R-tube,spin_top],[R-tube-wall_t-1,spin_top-chamf],
                                         [R-tube-wall_t-1,spin_top+2],[R-tube,spin_top+2]]);
    }
}
// fixed band = walls with a round well sunk at each station (the pocket drops through here)
module fixed_band() {
    difference() {
        band_walls();
        for (k=[1:N]) translate([Pp(k)[0], Pp(k)[1], -dw])
            cylinder(h = floorz + dw, r=rw, $fn=64);    // well from z=-dw up to the channel floor
    }
}
// round flush pocket-disc: top flush with the channel floor, a shallow spherical seat (detent)
module pocket_disc(k) {
    translate([Pp(k)[0], Pp(k)[1], floorz - disc_h]) difference() {
        cylinder(h=disc_h, r=rw - clr, $fn=64);
        translate([0,0,disc_h]) sphere(r=rb + 0.6, $fn=48);   // ball seat scooped into the top
    }
}
module ball() { sphere(r=rb, $fn=48); }

// ---- inner swap drums (5; the apex pair (0,1) is the top input, not a drum) ----
apexR  = R + 24*SCALE;        // apex (ball 0) radius — outside the ring (the protruding input)
RD     = rb + 0.5;             // drum pocket radius
FP     = RD + rb + 1;          // drum footprint radius
CR     = R - RD - 1;           // rim-drum centre radius (far swap-ball stays inside the ring)
EASE   = (spin_top - eq) + 1.5;
chz    = eq - EASE;            // chamber level: ball centre during the carry
INNER  = [[2,9],[3,4],[5,6],[7,8],[10,11]];
function dmid(i,j) = (Pp(i)+Pp(j))/2;
function dlen(v)   = sqrt(v[0]*v[0]+v[1]*v[1]);
function dunit(v)  = v/dlen(v);
function isfar(i,j)= dlen(dmid(i,j)) < CR-4;            // long pair -> central drum
function drumC(i,j)= isfar(i,j) ? [0,0] : dunit(dmid(i,j))*CR;
function drumAx(i,j)= isfar(i,j) ? atan2(dmid(i,j)[1],dmid(i,j)[0])-90 : atan2(drumC(i,j)[1],drumC(i,j)[0])+90;
// a 2-pocket rotary carrier: a bar BELOW the balls + two open cradles + a pivot post
module drum(i,j) {
    C=drumC(i,j); ax=drumAx(i,j);
    translate([C[0],C[1],0]) rotate([0,0,ax]) {
        difference() {
            union() {
                translate([0,0,chz-rb-3]) hull() {            // connecting bar, under the balls
                    translate([ RD,0,0]) cylinder(h=4, r=rb*0.7, $fn=32);
                    translate([-RD,0,0]) cylinder(h=4, r=rb*0.7, $fn=32);
                }
                for (s=[1,-1]) translate([s*RD,0,chz-rb-3]) cylinder(h=rb+3, r=rb+1.3, $fn=40);  // cup bodies
                translate([0,0,chz-rb-3]) cylinder(h=rb+9, r=2.5, $fn=24);                       // pivot post
            }
            for (s=[1,-1]) translate([s*RD,0,chz]) {                                            // carve open cradles
                sphere(r=rb+0.3, $fn=40);
                translate([0,0,rb*0.45]) cylinder(h=rb+2, r=rb-0.4, $fn=40);
            }
        }
    }
}

// ---------------- dispatch ----------------
// ---- bores: the inward routing tunnels, CARVED as channels in a chamber deck ----
// Each ball is PUSHED from its station well to its drum entry through an enclosed tube (radius
// bore_r, so it wraps the ball past its equator -> retained in any orientation in transit).
// Rim pairs: a straight tube station->entry. The central 2-9 pair: dive radially into the clear
// inner disc, then run across to the entry (so the long bores dodge the rim drums).
bore_r = rb + 0.4;
function drumAx(i,j) = isfar(i,j) ? atan2(dmid(i,j)[1],dmid(i,j)[0])-90 : atan2(drumC(i,j)[1],drumC(i,j)[0])+90;
function dentries(i,j) = let(C=drumC(i,j), a=drumAx(i,j))
    [ [C[0]+cos(a)*RD, C[1]+sin(a)*RD], [C[0]-cos(a)*RD, C[1]-sin(a)*RD] ];
module btube(a,b) { hull() {                          // a carved tube segment between two xy points at chamber z
    translate([a[0],a[1],chz]) sphere(r=bore_r, $fn=28);
    translate([b[0],b[1],chz]) sphere(r=bore_r, $fn=28); } }
module bore_cut(i,j) {
    e = dentries(i,j);
    if (isfar(i,j)) for (s=[0,1]) {                   // central: station -> radial waypoint -> entry
        st = (s==0)?Pp(i):Pp(j); wp = dunit(st)*(CR-FP-1);
        btube(st, wp); btube(wp, e[s]);
    } else { btube(Pp(i), e[0]); btube(Pp(j), e[1]); } // rim: straight
}
module bore_deck() {
    difference() {
        translate([0,0,chz-bore_r-2]) cylinder(h=2*bore_r+4, r=R-2, $fn=180);   // the chamber slab (inner disc)
        for (p=INNER) bore_cut(p[0],p[1]);                                       // carve the bore channels
        for (p=INNER) { C=drumC(p[0],p[1]);                                      // carve the drum cavities
            translate([C[0],C[1],chz-bore_r-3]) cylinder(h=2*bore_r+6, r=RD+rb+1.2, $fn=56); }
        translate([0,0,-50]) cylinder(h=100, r=3.5, $fn=24);                     // central shaft clearance
    }
}

// ---- EASE-DECK: the moving carriage (bore deck + the 11 discs + a central lift stem). The whole
//      swap mechanism drops ~EASE so the balls leave the fixed band lip into the pockets, then
//      rises to re-seat them. (Concept solid: overlaps the band's lower region — production must
//      notch the band inner wall at the 5 drum azimuths + shape the deck to the band's openings.)
module ease_deck() {
    union() {
        bore_deck();
        for (k=[1:N]) pocket_disc(k);
        translate([0,0, chz-bore_r-14]) cylinder(h=14, r=4, $fn=24);   // lift stem (the ease cam pushes here)
    }
}
// ---- APEX INPUT: a 2-pocket rotor at the TOP that swaps 0<->1 (the push-0 crank, outside the ring)
module apex_input() {
    M=[0,(apexR+R)/2]; halfc=(apexR-R)/2;          // pockets land on the apex (0) and station 1
    translate([M[0],M[1],0]) difference() {
        union() {
            translate([0,0,eq-rb-3]) hull() {
                translate([0, halfc,0]) cylinder(h=4, r=rb*0.7, $fn=32);
                translate([0,-halfc,0]) cylinder(h=4, r=rb*0.7, $fn=32);
            }
            for (s=[1,-1]) translate([0,s*halfc,eq-rb-3]) cylinder(h=rb+3, r=rb+1.3, $fn=40);
            translate([0,0,eq-rb-3]) cylinder(h=rb+9, r=2.5, $fn=24);
        }
        for (s=[1,-1]) translate([0,s*halfc,eq]) { sphere(r=rb+0.3, $fn=40); translate([0,0,rb*0.45]) cylinder(h=rb+2, r=rb-0.4, $fn=40); }
    }
}

// ---------------- dispatch ----------------
PART = "all";
if      (PART=="band")  fixed_band();
else if (PART=="discs") for (k=[1:N]) pocket_disc(k);
else if (PART=="drums") for (p=INNER) drum(p[0],p[1]);
else if (PART=="bores") bore_deck();
else if (PART=="ease")  ease_deck();
else if (PART=="apex")  apex_input();
else if (PART=="drum0") drum(INNER[0][0],INNER[0][1]);
else if (PART=="drum1") drum(INNER[1][0],INNER[1][1]);
else if (PART=="drum2") drum(INNER[2][0],INNER[2][1]);
else if (PART=="drum3") drum(INNER[3][0],INNER[3][1]);
else if (PART=="drum4") drum(INNER[4][0],INNER[4][1]);
else if (PART=="ball")  ball();
else {                                      // full assembly preview
    color([0.55,0.60,0.70,0.32]) fixed_band();
    color([0.25,0.70,0.45])      for (k=[1:N]) pocket_disc(k);
    color([0.80,0.55,0.30])      for (p=INNER) drum(p[0],p[1]);
    color([0.88,0.47,0.25])      apex_input();
    for (k=[1:N]) translate([Pp(k)[0],Pp(k)[1],eq]) color([0.9,0.92,1,0.9]) ball();
    translate([0,apexR,eq]) color([1,0.54,0.24,0.95]) ball();      // apex ball 0
}
