// M12 ALTERNATIVE ARCHITECTURE — TALL VARIANT: big-ease clean sub-chamber deck
// =============================================================================
// This is the "tall" branch of the alternative architecture. It keeps the FIXED precise spin
// band exactly as proto_band.scad defines it (over-equator lip + finger chamfer + 11 round
// wells with flush pocket-discs), but instead of the compact 5.62 mm ease — whose bore/drum
// chamber interpenetrates the band's lower wall — it uses a BIG ease so the whole bore/drum/
// disc chamber sits CLEANLY BELOW the band floor as its own separate deck. No band overlap.
//
// Sizing the ease: at rest the ball centre is at z=eq; its TOP is at eq+rb. The band floor
// (torus bottom) is floorz = eq - tube ~ -0.3. For the eased ball to land FULLY below the band
// floor (ball top < floorz) we need EASE_tall > (eq+rb) - floorz = ball_d + tube - rb + ...
//   = 22.5 - (-0.30) = 22.80 mm.  We pick EASE_tall = 25.0 — and additionally require the deck
//   ROOF above the eased ball to clear the floor: deck_top = chz+rb+roof_t < floorz, i.e.
//   EASE_tall > eq+rb+roof_t-floorz = 11.25+11.25+1.0+0.3 = 23.8 mm.  25.0 leaves a clean ~1.2 mm
//   gap between the deck roof and the band floor.
//
// Retention through the deeper descent (gravity-independent, any orientation):
//   z in [eq-DF, eq]      -> capped by the FIXED band over-equator lip (DF = spin_top-eq).
//   z in [floorz, eq-DF]  -> surrounded laterally by the band WELL wall (radius rw > rb); the
//                            well roof overlaps the fixed lip, so the top is never bare.
//   z in [chz, floorz]    -> surrounded laterally by the deck BORE-TUBE (radius bore_r > rb so
//                            it wraps the ball past its equator) which runs the whole descent.
//   ceiling cap           -> a moving CEILING-LIP plate rides above the deck and caps the ball
//                            from the top end of the bore-tube down to the chamber, so an
//                            inverted toy still cannot drop a ball out the bottom of its tube.
//
//   openscad -o x.stl -D 'PART="band"'  proto_deck_tall.scad
//   openscad -o x.stl -D 'PART="deck"'  proto_deck_tall.scad   (the clean sub-chamber deck)
//   openscad -o x.stl -D 'PART="all"'   proto_deck_tall.scad
// =============================================================================

SCALE   = 1.25;
R       = 50*SCALE;            // ring radius (62.5)
N       = 11;
ball_d  = 18*SCALE;            // 22.5
rb      = ball_d/2;            // 11.25
eq      = ball_d/2;            // ball-centre height (bottom = 0)
tube    = rb + 0.3;            // channel tube radius (11.55)
spin_top= eq + sqrt(tube*tube - rb*rb) + 1.5;     // channel mouth (over-equator lip) height
wall_t  = 1.5*SCALE;           // wall beyond the tube
chamf   = 1.5*SCALE;           // finger chamfer on the rim lips
floorz  = eq - tube;           // channel floor level (torus bottom), ~ -0.3
rw      = rb + 1.5;            // station well / pocket radius (round)
disc_h  = 4.5;                 // pocket-disc thickness
clr     = 0.4;                 // disc-to-well running clearance

// ---- TALL ease ----
DF        = spin_top - eq;                 // fixed-lip grip range (~4.12)
EASE_tall = 25.0;                          // big ease: eased ball top + deck roof < floorz (clean deck below band)
chz       = eq - EASE_tall;                // chamber level: ball centre during the carry (~ -12.75)
// well must run from the band floor down far enough to pass the disc through during the big ease.
// disc top rides with the ball; at full ease the disc top is at chz-? ; carve the well deep enough.
dw      = EASE_tall + disc_h + 4;          // well depth below floorz (room for the deep ease + disc)

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
// fixed band = walls with a round well sunk at each station (the disc + ball drop through here)
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

// ---- bores: OVER-EQUATOR routing channels carved in the clean sub-chamber deck ----
// FIX 1 (mirrors the compact branch): each bore is a carved tube of radius bore_r (running
// clearance) that is ROOFED except for a narrow top SLOT of width 2*sw.  Because the mouth
// 2*sw < ball_d the wall wraps the ball PAST ITS EQUATOR on both sides of the lane, so the ball
// is laterally captured AND cannot lift out the top in any orientation while in transit.
bore_r = rb + 0.4;            // 11.65  carved passage radius (running clearance, > rb)
sw     = rb - 0.85;           // 10.40  roof-slot HALF-width  -> mouth 2*sw = 20.80 < ball_d 22.5
roof_slot_t = 1.6;            // roof lip thickness over the slot edge
chan_wall  = 1.2;             // minimal wall around a channel tube
zlip   = chz + sqrt(rb*rb - sw*sw);   // over-equator roof-lip height at the slot edge (< eq)
function dentries(i,j) = let(C=drumC(i,j), a=drumAx(i,j))
    [ [C[0]+cos(a)*RD, C[1]+sin(a)*RD], [C[0]-cos(a)*RD, C[1]-sin(a)*RD] ];
// carved ball passage (the void) — a swept tube at chamber z
module btube(a,b) { hull() {
    translate([a[0],a[1],chz]) sphere(r=bore_r, $fn=28);
    translate([b[0],b[1],chz]) sphere(r=bore_r, $fn=28); } }
// the roof SLOT over a lane: an open trough of width 2*sw above the lip, so the top mouth < ball_d
module bslot(a,b) {
    dx=b[0]-a[0]; dy=b[1]-a[1]; L=sqrt(dx*dx+dy*dy); ang=atan2(dy,dx);
    translate([a[0],a[1],0]) rotate([0,0,ang])
        translate([-bore_r-chan_wall, -sw, zlip])
            cube([L+2*(bore_r+chan_wall), 2*sw, (deck_top+roof_slot_t)-zlip + 1]);
}
module bore_cut(i,j) {        // the carved passage (void) for one pair's two lanes
    e = dentries(i,j);
    if (isfar(i,j)) for (s=[0,1]) {                   // central: station -> radial waypoint -> entry
        st = (s==0)?Pp(i):Pp(j); wp = dunit(st)*(CR-FP-1);
        btube(st, wp); btube(wp, e[s]);
    } else { btube(Pp(i), e[0]); btube(Pp(j), e[1]); } // rim: straight
}
module bore_slot(i,j) {       // the roof slot (open mouth) for one pair's two lanes
    e = dentries(i,j);
    if (isfar(i,j)) for (s=[0,1]) {
        st = (s==0)?Pp(i):Pp(j); wp = dunit(st)*(CR-FP-1);
        bslot(st, wp); bslot(wp, e[s]);
    } else { bslot(Pp(i), e[0]); bslot(Pp(j), e[1]); }
}
// the clean sub-chamber slab — a deck centred at chz, entirely BELOW the band floor.
// The slab top must clear the band floor (deck_top < floorz). The slab only has to ENCLOSE the
// eased ball (centre chz, top chz+rb), so its half-height is rb+roof, NOT bore_r. With
// EASE_tall=25 the eased ball top is at chz+rb=-2.5 and deck_top=-1.5 < floorz=-0.3, clean z-gap.
// FIX 2 — DRUM-CEILING ROOF parameters.  Over each drum the ball orbits a circle of radius RD as
// the drum makes its 180 deg turn; both pockets stay under the roof through the whole turn.  We cap
// the entire ball-orbit ANNULUS (inner edge RD-rb+drum_mouth, outer edge RD+rb) with a roof, leaving
// a central pivot clearance and a mouth opening < ball_d.  The drum spins UNDER the roof with
// running clearance drum_run.  The roof underside sits at z = chz + sqrt(rb^2 - ann_w^2) i.e. it
// grips each ball ABOVE its equator (ann_w is the radial half-gap of the annulus opening from the
// orbit circle; opening 2*ann_w < ball_d).
ann_w     = rb - 0.85;        // 10.40  half-width of the annulus radial opening -> opening 20.80 < ball_d
drum_run  = 1.0;              // running clearance between the spinning drum top and the roof underside
roof_t    = 1.0;              // thin roof above the eased ball top (kept for deck_top)
deck_top  = chz + rb + roof_t;    // top of the deck slab (must be < floorz)
deck_bottom = chz - rb - 4;       // bottom of the deck slab (room for the drum cup bodies)

// the bore deck: chamber slab, with the bore PASSAGES carved AND the roof SLOTS carved (mouth
// 2*sw < ball_d) so the bore lips remain to wrap each ball past its equator in transit.
module bore_deck() {
    difference() {
        translate([0,0,deck_bottom]) cylinder(h=deck_top-deck_bottom, r=R-2, $fn=180);  // chamber slab (inner disc)
        for (p=INNER) bore_cut(p[0],p[1]);                                       // carve the bore passages
        for (p=INNER) bore_slot(p[0],p[1]);                                      // carve the roof SLOTS (open mouth)
        for (p=INNER) { C=drumC(p[0],p[1]);                                      // carve the drum cavities (full bore)
            translate([C[0],C[1],deck_bottom-1]) cylinder(h=deck_top-deck_bottom+2, r=RD+rb+1.6, $fn=56); }
        translate([0,0,-100]) cylinder(h=200, r=3.5, $fn=24);                    // central shaft clearance
    }
}

// ---- DRUM-CEILING ROOF: a continuous plate over the whole inner disc that ROOFS every drum
// cavity (capping the ball-orbit annulus over the 180 deg turn) AND bridges to the bore roofs, so a
// ball stays capped route-in -> drum-turn -> route-out.  Over each drum it leaves: a central pivot
// clearance (radius pivot_clr) and an annular OPENING of radial width 2*ann_w centred on the orbit
// circle (opening < ball_d).  The roof underside is set so the drum spins beneath it with drum_run.
pivot_clr = 4.0;                          // central clearance for the pivot post (post r=2.5)
drum_top  = chz - rb - 3 + (rb + 3);      // top of the spinning drum cup bodies = chz  (cup h to chz)
roof_under = drum_top + drum_run;         // roof underside above the spinning drum top, with clearance
roof_over  = deck_top;                    // roof shares the deck top plane (a unified carriage roof)
module drum_roof() {
    difference() {
        translate([0,0,roof_under]) cylinder(h=roof_over-roof_under, r=R-2, $fn=180);  // the roof plate
        // open the bore lanes through the roof (full passage so balls travel under the roof)
        for (p=INNER) bore_cut(p[0],p[1]);
        for (p=INNER) bore_slot(p[0],p[1]);
        // over each drum: carve the orbit-annulus opening (mouth 2*ann_w) + the central pivot clearance
        for (p=INNER) { C=drumC(p[0],p[1]);
            translate([C[0],C[1],roof_under-1]) difference() {
                cylinder(h=roof_over-roof_under+2, r=RD+ann_w, $fn=64);     // outer edge of the opening
                cylinder(h=roof_over-roof_under+2, r=RD-ann_w, $fn=64);     // inner edge -> leaves the orbit roof lip
            }
            translate([C[0],C[1],roof_under-1]) cylinder(h=roof_over-roof_under+2, r=pivot_clr, $fn=32); // pivot clearance
        }
        translate([0,0,-100]) cylinder(h=200, r=3.5, $fn=24);              // central shaft clearance
    }
}

// ---- VERTICAL RETENTION RISERS: closed-tube lateral capture bridging the bore roof up to the
// band-lip range over the EASE descent.  Each riser is a CLOSED tube (radius bore_r) carved into a
// solid riser ring rising from the deck roof (deck_top) up to the band floor (floorz).  A closed
// 360 deg tube fully encloses the ball LATERALLY (it can only move along the tube axis); the ENDS
// are capped by the FIXED band lip (top, while z is in lip range) and by the bore/drum roof (bottom).
// The risers are part of the carriage and descend with it, so the closed tube surrounds the ball
// throughout the descent and the lip/roof ranges OVERLAP -> continuous any-orientation capture.
// NOTE: no narrow top lip ring here -- the ball rides in the pocket-disc and must pass freely; the
// top cap during the descent is the fixed band lip (handoff), not a riser constriction.
module retention_riser(k) {
    translate([Pp(k)[0], Pp(k)[1], 0])
    difference() {
        translate([0,0,deck_top]) cylinder(h=floorz-deck_top, r=bore_r+wall_t, $fn=48);  // solid riser, deck->floor
        translate([0,0,deck_top-0.1]) cylinder(h=floorz-deck_top+0.2, r=bore_r, $fn=48); // carve the closed tube bore
    }
}

// ---- the moving carriage: the clean sub-chamber deck (bore deck + drum roof + 11 discs + risers +
//      a central lift stem). The whole carriage drops EASE_tall for the swap, then rises to re-seat.
module deck_assembly() {
    union() {
        bore_deck();
        drum_roof();
        for (k=[1:N]) pocket_disc(k);
        for (k=[1:N]) retention_riser(k);
        translate([0,0, deck_bottom-12]) cylinder(h=12, r=4, $fn=24);   // lift stem (the ease cam pushes here)
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
if      (PART=="band")    fixed_band();
else if (PART=="discs")   for (k=[1:N]) pocket_disc(k);
else if (PART=="drums")   for (p=INNER) drum(p[0],p[1]);
else if (PART=="bores")   bore_deck();
else if (PART=="risers")  for (k=[1:N]) retention_riser(k);
else if (PART=="roof")    drum_roof();
else if (PART=="deck")    deck_assembly();
else if (PART=="apex")    apex_input();
else if (PART=="drum0")   drum(INNER[0][0],INNER[0][1]);
else if (PART=="drum1")   drum(INNER[1][0],INNER[1][1]);
else if (PART=="drum2")   drum(INNER[2][0],INNER[2][1]);
else if (PART=="drum3")   drum(INNER[3][0],INNER[3][1]);
else if (PART=="drum4")   drum(INNER[4][0],INNER[4][1]);
else if (PART=="ball")    ball();
else {                                      // full assembly preview
    color([0.55,0.60,0.70,0.32]) fixed_band();
    color([0.30,0.55,0.75,0.45]) bore_deck();
    color([0.25,0.70,0.45])      for (k=[1:N]) pocket_disc(k);
    color([0.70,0.75,0.85,0.5])  for (k=[1:N]) retention_riser(k);
    color([0.85,0.85,0.92,0.35]) drum_roof();
    color([0.80,0.55,0.30])      for (p=INNER) drum(p[0],p[1]);
    color([0.88,0.47,0.25])      apex_input();
    // balls shown EASED DOWN in the chamber (the swap state), apex ball at the top:
    for (k=[1:N]) translate([Pp(k)[0],Pp(k)[1],chz]) color([0.9,0.92,1,0.9]) ball();
    translate([0,apexR,eq]) color([1,0.54,0.24,0.95]) ball();      // apex ball 0
}
