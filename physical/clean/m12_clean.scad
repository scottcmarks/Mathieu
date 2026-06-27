// =====================================================================
//  Sporadic M12 — CLEAN-SHEET swap toy  (parametric, Dp = 100 mm)
//  Architecture: 5 in-plane 2-cell rotors (apex + 4 rim) at ball level,
//  + 1 (2,9) 2-cell rotor on a private UNDER-DECK below the ring plane.
//  Mirrors the geometry/z-decks proven in check_clean.py.
//
//  Render one part at a time with -D 'PART="..."', e.g.
//    openscad -o base_disc.scad.stl   -D 'PART="base"'     m12_clean.scad
//    openscad -o rim_rotor.stl        -D 'PART="rim"'      m12_clean.scad
//    openscad -o apex_rotor.stl       -D 'PART="apex"'     m12_clean.scad
//    openscad -o cross_rotor.stl      -D 'PART="cross29"'  m12_clean.scad
//    openscad -o window.stl           -D 'PART="window"'   m12_clean.scad
//    openscad -o ball.stl             -D 'PART="ball"'     m12_clean.scad
//    openscad -o assembly_preview.stl -D 'PART="all"'      m12_clean.scad
// =====================================================================

PART = "all";          // base | rim | apex | cross29 | window | ball | carousel | all
$fn  = 96;

// ---- geometry (authoritative, = check_clean.py) ----
// SCALE is a UNIFORM size factor: every linear dimension scales together, so all clearances
// and capture bites scale proportionally (the design stays valid) while the fixed-size
// fingertip meets proportionally larger crowns -> easier spin. 1.0 = the original 18 mm ball.
SCALE    = 1.25;
R        = 50*SCALE;
N        = 11;
ball_d   = 18*SCALE;           // 22.5
rb       = ball_d/2;           // 11.25
eq       = ball_d/2;           // 11.25  ball-centre height (ball bottom = 0)
nbchord  = 2*R*sin(180/N);
APEX_STK = 24*SCALE;           // (0,1) chord/stroke (> ball_d so the two apex balls clear)
apexR    = R + APEX_STK;

// z-decks (world; ball bottom = 0)
Z_GEAR    = -7*SCALE;
Z_HUB     = -2*SCALE;
Z_29      = -22*SCALE;  // ball-2's deep-sweep top clears the apex PIVOT bottom (Z_PLATE); verified in check_clean.py
Z_29FLOOR = -41*SCALE;  // floor follows the deck down (room for the (2,9) bar, which runs under the dipped balls)

clr       = 0.25;               // moving-fit clearance (per side)
cup_r     = rb*0.82;            // cradle radius (cups the lower hemisphere)
well_r    = rb + 1;             // 10  vertical well for balls 2 & 9
lip_id    = 14*SCALE;           // window aperture lip ID (< ball_d, retains)

function angleOf(i) = -90 + (i-1)*(360/N);
function Pp(i) = (i==0) ? [0, apexR] : [R*cos(angleOf(i)), -R*sin(angleOf(i))];
function mid(i,j) = (Pp(i)+Pp(j))/2;

NEIGH = [[3,4],[5,6],[7,8],[10,11]];
INPLANE = concat([[0,1]], NEIGH);

// ---------- self-contained INVOLUTE spur gear (no external library) ----------
// m = module (mm/tooth), z = tooth count, h = face width, pa = pressure angle.
// True involute flanks sampled from root to addendum; radial below the base circle.
PI_ = 3.1415926536;
function inv_deg(a) = tan(a)*180/PI_ - a;          // involute polar angle (deg) at pressure angle a (deg)
module spur_gear(m=1.25, z=14, h=6, bore=3, pa=20, clr=0.25) {
    pr = m*z/2;                                    // pitch radius
    rbc = pr*cos(pa);                              // base radius
    ra = pr + m;                                   // addendum (outer) radius
    rf = max(1, pr - (1.25*m + clr));              // root radius
    half = 90/z;                                   // half tooth angle at pitch circle
    beta = half - inv_deg(pa);                     // rotate flank so the pitch point lands at +half
    r0 = max(rf, rbc);
    steps = 8;
    rpts = [ for (i=[0:steps]) let(r = r0 + (ra-r0)*i/steps,
                                   al = acos(min(1, rbc/r)),
                                   pol = inv_deg(al) + beta)
                 [r*cos(pol), r*sin(pol)] ];
    // close down to the root radius along a radial at the flank base angle
    rightflank = concat([[rf*cos(beta), rf*sin(beta)]], rpts);
    leftflank  = [ for (i=[len(rpts)-1:-1:0]) [rpts[i][0], -rpts[i][1]] ];
    tooth = concat(rightflank, leftflank, [[rf*cos(-beta), rf*sin(-beta)]]);
    difference() {
        union() {
            cylinder(h=h, r=rf+0.01);              // root disc
            for (k=[0:z-1]) rotate([0,0, k*360/z]) linear_extrude(h) polygon(tooth);
        }
        if (bore>0) translate([0,0,-1]) cylinder(h=h+2, r=bore/2);
    }
}

// idler chain: a row of meshing idler gears from `frm` to `to` at deck height z.
// 1:1 train (sun & rotor gears equal), so idlers only transmit — count set by span.
module gear_chain(frm, to, z, gz=14, m=1.25) {
    D = norm(to-frm);
    n = max(1, round(D/(gz*m)));           // mesh gaps (~17.5 mm each for 14T @ m1.25)
    for (i=[1:n-1]) {                        // interior idlers only (endpoints are sun/rotor)
        p = frm + (to-frm)*(i/n);
        translate([p[0],p[1],z]) spur_gear(m=m, z=gz, h=5, bore=3);
    }
}

// ---------- CAM / DRIVE PLATE (hidden swap drive; chosen 2026-06-16) ----------
// One hidden disc below the rotors. The 0-flick turns the APEX rotor 180°; its crank
// pin drives the plate; the plate's cam slots each turn one of the other 5 rotors 180°.
// Each rotor's drive pin rides its PIVOT SHAFT, which stays engaged with the plate even
// when the cup retracts for spin. Detents (DESIGN §5) finalize each rotor at 180°.
Z_PLATE = -12*SCALE;                        // plate deck: below rotor hubs, above the (2,9) deck
PLATE_R = 66*SCALE;                         // reaches past the apex rotor pin
CRANK_E = 7*SCALE;                          // rotor crank-pin offset from its pivot
// COUPLING (parallel-crank) PLATE — the actual plate<->rotor linkage. Every in-plane rotor
// carries a crank post at radius CRANK_E at the SAME world phase (+x). One rigid plate
// journals all five posts. Because >=2 equal, parallel cranks pin a rigid body, the plate
// has a single DOF: it can only TRANSLATE on a circle of radius CRANK_E (never rotate).
// That coupling forces every rotor through the IDENTICAL angle — so one plate orbit swings
// all five 180deg in lockstep. (The (2,9) rotor is driven on the central idler branch.)
module drive_plate() {
    difference() {
        translate([0,0,Z_PLATE]) cylinder(h=4, r=PLATE_R);
        translate([0,0,Z_PLATE-1]) cylinder(h=6, r=13);                 // central shaft clearance (orbit-proof)
        // a close-fit journal for each in-plane crank post, at the COMMON phase (+x)
        for (pr=INPLANE) translate([mid(pr[0],pr[1])[0]+CRANK_E, mid(pr[0],pr[1])[1], Z_PLATE-1])
            cylinder(h=6, r=2.2);
        // DROP WELLS at slots 2 & 9 so those balls pass through the plate to the under-deck
        translate([Pp(2)[0],Pp(2)[1],Z_PLATE-1]) cylinder(h=6, r=well_r);
        translate([Pp(9)[0],Pp(9)[1],Z_PLATE-1]) cylinder(h=6, r=well_r);
    }
}
// drive linkage per rotor (coupling plate). In-plane rotors: a short PIVOT/axis above the
// plate (in the base boss, so it never passes through the orbiting plate) + a COMMON-PHASE
// (+x) crank web & post that the one coupling plate journals. The (2,9) rotor is driven on
// the central idler branch instead, so it gets a central shaft, not a coupling post.
module crank_pins() {
    for (pr=INPLANE) rotor_drive(pr[0],pr[1]);
    rotor_drive(2,9);
}
// (The "push 0" input is a fingertip on ball 0's exposed crown, through the apex slot in the
//  window — no internal pusher part. The earlier schematic flick-rod was removed.)

// ONE rotor's drive linkage, emitted with its rotor as a single rigid STL the viewer
// articulates. In-plane: pivot axis (Z_HUB..eq, above the plate) + crank web + a COMMON-
// PHASE crank post (M+[CRANK_E,0]) crossing the plate — all five posts share phase, so the
// rigid plate translate-couples them (see drive_plate). (2,9): central drive shaft only.
module rotor_drive(i, j) {
    M = mid(i,j);
    if (i==2 && j==9) {
        translate([M[0],M[1],Z_29]) cylinder(h=Z_PLATE-Z_29+2, r=2);                 // central drive shaft to the deck
    } else {
        translate([M[0],M[1],Z_HUB]) cylinder(h=eq-Z_HUB, r=2);                       // pivot/axis (above the plate)
        translate([M[0],M[1],Z_HUB-0.1]) hull() {                                     // crank web: axis -> post
            cylinder(h=2, r=2.2);
            translate([CRANK_E,0,0]) cylinder(h=2, r=2.2);
        }
        translate([M[0]+CRANK_E, M[1], Z_PLATE]) cylinder(h=Z_HUB-Z_PLATE+2, r=1.6);  // crank post: plate -> web (clears the deep 2,9 sweep)
    }
}

// 2-9 LIFT: the cross-rotor is a CARRIAGE that rises to grip balls 2 & 9 at the channel,
// carries them down to the sub-deck and back, then retracts — its forks track the balls the
// whole carry (verified in check_clean.py:check_retention). The viewer slides it on z. The
// actual DRIVE hardware (a positive cam) is unresolved — see the report's "rethink" note, so
// it is intentionally NOT drawn here rather than left as a misleading stub.

// ---------- reusable pieces ----------
module ball_cradle(z) {        // open-topped cup: cradles lower hemisphere, open above
    difference() {
        translate([0,0,z]) cylinder(h=ball_d, r=cup_r+1.6, center=false);
        translate([0,0,z]) sphere(r=rb+clr);                 // the ball pocket
        translate([0,0,z+rb]) cylinder(h=ball_d, r=lip_id/2);// open the top (lip retains)
    }
}

// FORK end-effector (gravity-proof capture): a lower cradle cups the ball below its
// equator AND an upper C-lip slips in just ABOVE the equator (inner radius < rb, so the
// ball's equator can't rise past it). Together they hold the ball in ANY orientation.
// The C's open mouth (~110°, toward +x) is the slip-on side that a GATE covers in transit.
fork_z  = eq + 2.5*SCALE;      // upper grip height — just above the equator
fork_ir = rb - 0.4;            // C-lip inner radius (< rb): catches the rising equator
module ball_fork(z=eq) {
    dz = z - eq;
    // lower cradle: cups the lower hemisphere only (open above the equator for the C)
    translate([0,0,dz]) difference() {
        translate([0,0,eq-rb-0.5]) cylinder(h=rb+0.5, r=rb+1.8);
        translate([0,0,eq]) sphere(r=rb+clr);
        translate([0,0,eq]) cylinder(h=rb+2, r=rb+0.2);      // clear everything above the equator
    }
    // upper C-lip, just above the equator, open ~110° toward +x (the slip-on / gate side)
    translate([0,0,dz]) difference() {
        translate([0,0,fork_z]) difference() {
            cylinder(h=2.6, r=fork_ir+2.4);
            translate([0,0,-0.1]) cylinder(h=2.8, r=fork_ir);
        }
        translate([0,0,fork_z-0.2]) linear_extrude(3) polygon([[0,0],[40,34],[40,-34]]);  // mouth wedge
    }
}

// a 2-cell rotor: rigid bar between the two pair slots, a cradle at each end,
// pivot boss (for a Ø3 dowel or a flanged bearing) at the midpoint.
module two_cell_rotor(i, j, z, bar_w=8, boss_r=5.5, bar_h=6) {
    a = Pp(i); b = Pp(j); m = mid(i,j);
    L = norm(a-b);
    bz = z - rb - bar_h;          // bar TOP sits at z-rb (the ball bottom): the bar runs UNDER the
                                  // balls so it never spears them; it meets the fork cradles there.
    translate(m) {
        // connecting bar (bar_h per FORCES.md: 6 mm rim/apex, 8 mm for the long (2,9) bar) — below the balls
        rotate([0,0, atan2(b[1]-a[1], b[0]-a[0])])
            translate([-L/2, -bar_w/2, bz]) cube([L, bar_w, bar_h]);
        translate([0,0,bz]) cylinder(h=bar_h, r=boss_r);              // hub boss (below the balls)
        translate([0,0,bz]) cylinder(h=(z+5)-bz, r=2.4);             // thin pivot stub up to the bearing (clears balls)
        translate([0,0,bz-2]) cylinder(h=(z+7)-bz, r=1.6);          // Ø3 dowel bore
    }
    // FORKS at the two ends — mouth faces the pivot (the gate side), grips above equator
    translate(a) rotate([0,0, atan2(m[1]-a[1], m[0]-a[0])]) ball_fork(z);
    translate(b) rotate([0,0, atan2(m[1]-b[1], m[0]-b[0])]) ball_fork(z);
}

// ---------- BASE DISC (structural floor + bosses + (2,9) deck floor) ----------
module base_disc() {
    ann_out = apexR + ball_d + 4;          // ~96 outer radius -> Ø ~192? -> trim:
    Ro = R + nbchord/2 + rb + 6;            // ring-region outer ~ 71
    difference() {
        union() {
            // main floor under the ring plane
            translate([0,0,Z_29FLOOR]) cylinder(h = (Z_HUB - Z_29FLOOR), r = Ro);
            // pivot bosses for the 5 in-plane rotors
            for (pr=INPLANE) translate([mid(pr[0],pr[1])[0], mid(pr[0],pr[1])[1], Z_HUB])
                cylinder(h=2, r=6);
            // central bearing boss (608: 8 bore -> seat for spin carousel)
            cylinder(h = eq, r = 12);
        }
        // bores for rotor dowels
        for (pr=INPLANE) translate([mid(pr[0],pr[1])[0], mid(pr[0],pr[1])[1], Z_29FLOOR-1])
            cylinder(h=50, r=1.6);
        // (2,9) rotor pivot bore at its midpoint
        translate([mid(2,9)[0], mid(2,9)[1], Z_29FLOOR-1]) cylinder(h=40, r=1.6);
        // wells for balls 2 & 9 to drop to the under-deck
        translate([Pp(2)[0],Pp(2)[1], Z_29-5]) cylinder(h=eq+10, r=well_r);
        translate([Pp(9)[0],Pp(9)[1], Z_29-5]) cylinder(h=eq+10, r=well_r);
        // central bearing bore (608 OD 22)
        translate([0,0,-1]) cylinder(h=eq+2, r=11.1);
    }
}

// ---------- FIXED SPIN CHANNEL (Goal 1: captive top-slotted ring, fingertip spin) ----------
// A FIXED circular channel (~0.3 mm bigger than the ball) at R=50 that wraps each ball
// PAST its equator — the channel mouth is ~17 mm < the 18 mm ball, so balls are captive
// in ANY orientation (held even shaken/upside-down) — yet ~5.5 mm of crown protrudes
// through the open top for a fingertip to spin them either way. Detent bumps between the
// 11 stations make the balls click and settle. No carousel, no bearing: the finger is
// the only motor for spin (per Goal 1). Balls leave for a swap by dropping through their
// station well to the hidden mechanism below (drop-swap-rise) — see the review note.
tube_sp  = rb + 0.3;                                       // channel ~0.3 mm bigger than the ball
spin_top = eq + sqrt(tube_sp*tube_sp - rb*rb) + 1.5;      // ~12.8: channel mouth height
wall_t   = 1.5;                                            // wall thickness beyond the ball tube (thin -> less bulk around the crown)
chamf    = 1.5;                                            // rim-top chamfer: ramps a fingertip onto the crown (lips kept full height)
// ---- GATES: the channel's INNER wall is segmented at each station. A gate segment
// closed = continuous captive channel (ball held, any orientation, for spin). Open
// (dropped below) = that inner-wall piece is gone, so the fork can carry the ball
// INWARD off the channel onto the swap path. Gates are cam-actuated with the forks,
// and the fork covers the ball's open mouth while the gate is down (always held). ----
GATE_W    = ball_d + 1.5;          // gate width (tangential) — wide enough for the ball to pass inward
GATE_DROP = 16*SCALE;              // how far a gate drops to open (clear below the ball)
function stAng(k) = atan2(Pp(k)[1], Pp(k)[0]);
module _gate_vol(k, grow=0) {      // the inner-wall slab at station k (radial), the gate's volume
    a = stAng(k);
    rotate([0,0,a]) translate([R-tube_sp-wall_t-grow, -(GATE_W+2*grow)/2, eq-tube_sp-1-grow])
        cube([wall_t+2*grow, GATE_W+2*grow, (spin_top-(eq-tube_sp-1))+2*grow]);
}
module spin_channel() {
    difference() {
        // channel body: an annular wall around the ring, from the floor up to spin_top
        difference() {
            cylinder(h=spin_top, r=R+tube_sp+wall_t);
            translate([0,0,-0.1]) cylinder(h=spin_top+0.2, r=R-tube_sp-wall_t);
        }
        // carve the ball channel (circular-section torus at the ball plane)
        translate([0,0,eq]) rotate_extrude($fn=200) translate([R,0]) circle(r=tube_sp,$fn=32);
        // NOTCH the inner wall at each station -> gate openings (the gates fill these)
        for (k=[1:N]) _gate_vol(k, grow=0.4);
        // CHAMFER both rim tops down-and-away from the slot so a fingertip ramps onto the crown.
        // The cut starts at the ball tube (R±tube_sp), OUTSIDE the retaining lip, so the lips
        // (the torus edges) keep their full height -> no loss of capture bite.
        rotate_extrude($fn=160) polygon([[R+tube_sp,spin_top],[R+tube_sp+wall_t+1,spin_top-chamf],
                                         [R+tube_sp+wall_t+1,spin_top+2],[R+tube_sp,spin_top+2]]);
        rotate_extrude($fn=160) polygon([[R-tube_sp,spin_top],[R-tube_sp-wall_t-1,spin_top-chamf],
                                         [R-tube_sp-wall_t-1,spin_top+2],[R-tube_sp,spin_top+2]]);
    }
    // detents: a small bump between each pair of stations -> ball clicks over and settles
    for (k=[1:N]) { a = angleOf(k) + 360/(2*N);
        translate([R*cos(a), -R*sin(a), eq-rb+0.6]) sphere(r=1.3, $fn=16); }
}
// the 11 inner-wall gate segments. open = list of station indices whose gate is dropped.
module gates(open=[]) {
    for (k=[1:N]) translate([0,0, (search(k,open)!=[]) ? -GATE_DROP : 0]) _gate_vol(k);
}

// ---------- (2,9) UNDER-DECK ROTOR ----------
module cross_rotor() {
    // 8 mm-tall bar per FORCES.md §3 (stiffness: end-deflection 0.10 mm)
    two_cell_rotor(2, 9, Z_29, bar_w=9, boss_r=6, bar_h=8);
}

// ---------- CLEAR WINDOW PLATE (cover: retains balls, shows numbers) ----------
module window() {
    Ro = R + nbchord/2 + rb + 6;
    difference() {
        translate([0,0, ball_d+0.5]) cylinder(h=3, r=Ro);
        // 11 ring apertures (lip ID < ball_d so balls are retained but visible)
        for (k=[1:N]) translate([Pp(k)[0],Pp(k)[1], ball_d]) cylinder(h=6, r=lip_id/2);
        // apex aperture: elongated slot along 0->1 so ball 0 can plunge & be flicked
        hull() {
            translate([Pp(0)[0],Pp(0)[1], ball_d]) cylinder(h=6, r=lip_id/2);
            translate([Pp(1)[0],Pp(1)[1], ball_d]) cylinder(h=6, r=lip_id/2);
        }
        // recess the rim so a fingertip can reach the balls to spin them
        difference() {
            translate([0,0, ball_d-1]) cylinder(h=6, r=R+rb+1);
            translate([0,0, ball_d-1]) cylinder(h=6, r=R-rb-1);
        }
    }
}

// ---------- BALL (clear token; digit recessed on each face) ----------
// Ball token (stolen from Track 1's nicer design): a clear/milky sphere with the
// numeral repeated, FLUSH (recessed inward — balls roll, nothing may protrude), on
// all 12 dodecahedron faces so a number always faces the viewer.
// numeral solids on all 12 dodecahedron faces (so a number always faces you).
NUM_T = 0.8;
module _numerals(num, extra=0) {
    phi=(1+sqrt(5))/2; nv=sqrt(1+phi*phi);
    dirs=[[0,1,phi],[0,1,-phi],[0,-1,phi],[0,-1,-phi],
          [1,phi,0],[1,-phi,0],[-1,phi,0],[-1,-phi,0],
          [phi,0,1],[phi,0,-1],[-phi,0,1],[-phi,0,-1]];
    sz=ball_d*0.26;                                        // small enough that 10/11 aren't crowded
    for (i=[0:len(dirs)-1]) { d=dirs[i]/nv;
        rotate([0,0,atan2(d[1],d[0])]) rotate([0,acos(d[2]),0])
            translate([0,0,rb-NUM_T]) rotate([0,0,i*40])
                linear_extrude(NUM_T+extra) text(str(num), size=sz, halign="center", valign="center"); }
}
// ball BODY: a clear sphere with shallow pockets so the black numerals inlay FLUSH.
module ball(num=0)      { difference() { sphere(r=rb); _numerals(num, extra=0.8); } }
// number INLAY: the numerals clipped to the sphere -> flush BLACK digits (separate part/material).
module ball_nums(num=0) { intersection() { sphere(r=rb); _numerals(num, extra=0); } }

// ---------------- dispatch ----------------
if (PART=="fork") { ball_fork(eq); color([0.9,0.6,0.2]) translate([0,0,eq]) sphere(r=rb,$fn=40); } // fork gripping a ball
else if (PART=="gear")     spur_gear(m=1.25, z=14, h=6, bore=3);   // test: one real gear
else if (PART=="base")     base_disc();
else if (PART=="carousel" || PART=="spin") spin_channel();
else if (PART=="rim")  two_cell_rotor(3,4, eq);     // representative rim rotor
else if (PART=="apex") two_cell_rotor(0,1, eq, bar_w=10, boss_r=6);
else if (PART=="cross29") cross_rotor();
else if (PART=="window")  window();
else if (PART=="ball") { color([0.86,0.89,1,0.95]) ball(7); color([0.04,0.04,0.04]) ball_nums(7); }
// --- grouped, fully-placed sets for the interactive viewer ---
else if (PART=="structure") { base_disc(); spin_channel(); gates(); }
else if (PART=="gates")     gates();
else if (PART=="rotors") {
    for (pr=NEIGH) two_cell_rotor(pr[0],pr[1], eq);
    two_cell_rotor(0,1, eq, bar_w=10, boss_r=6);
    cross_rotor();
}
else if (PART=="gears") {        // the hidden CAM DRIVE (plate + crank pins + 2-9 lift)
    drive_plate(); crank_pins();
}
// --- per-body MECHANISM parts for the articulated "push 0" viewer (each is one rigid
//     body the viewer rotates/translates): 6 rotors+linkage, the plate ---
else if (PART=="rotor01")   { two_cell_rotor(0,1, eq, bar_w=10, boss_r=6); rotor_drive(0,1); }
else if (PART=="rotor34")   { two_cell_rotor(3,4, eq);  rotor_drive(3,4); }
else if (PART=="rotor56")   { two_cell_rotor(5,6, eq);  rotor_drive(5,6); }
else if (PART=="rotor78")   { two_cell_rotor(7,8, eq);  rotor_drive(7,8); }
else if (PART=="rotor1011") { two_cell_rotor(10,11, eq); rotor_drive(10,11); }
else if (PART=="rotor29")   cross_rotor();   // the sliding carriage only (shaft/drive is fixed, TBD)
else if (PART=="plate")     drive_plate();
else if (PART=="balls")   { for (k=[0:N]) translate([Pp(k)[0],Pp(k)[1], eq]) ball(k); }       // clear bodies
else if (PART=="numbers") { for (k=[0:N]) translate([Pp(k)[0],Pp(k)[1], eq]) ball_nums(k); }  // flush BLACK inlays
else {  // "all" assembly preview
    color([0.6,0.6,0.65,0.5]) base_disc();
    color([0.7,0.8,1.0,0.4])  spin_channel();
    color([0.95,0.55,0.2])    gates();
    for (pr=NEIGH) color([0.3,0.7,0.4]) two_cell_rotor(pr[0],pr[1], eq);
    color([0.9,0.5,0.3] ) two_cell_rotor(0,1, eq, bar_w=10, boss_r=6);
    color([0.8,0.3,0.3] ) cross_rotor();
    // --- hidden CAM DRIVE: one plate below the rotors; the 0-flick turns the apex
    //     rotor, whose pin drives the plate, whose cam slots turn the other 5 rotors 180°.
    color([0.55,0.55,0.62]) drive_plate();
    color([0.8,0.8,0.85])   crank_pins();
    color([0.6,0.8,1.0,0.25]) window();
    // balls at rest
    for (k=[0:N]) translate([Pp(k)[0],Pp(k)[1], eq]) color([0.8,0.85,1,0.6]) sphere(r=rb);
}
