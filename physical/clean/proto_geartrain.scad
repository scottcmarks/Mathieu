// M12 HAND-DRIVE — DIVIDER GEAR TRAIN (in-plane sun + 4 idlers + 4 pinions)
// =============================================================================
// Realizes "gears on the bottom of the divider paddles" (ADR-0002). ONE rotary input at the
// SUN (origin) turns all FIVE in-plane divider blades exactly π, the SAME sense, 1:1:
//   sun 21T (CW) → idler 25T (CCW) → pinion 21T (CW = sun).  ω_pinion/ω_sun = (21/25)(25/21)=1.
// The idler restores the sense (a bare sun would reverse its planets); equal sun/pinion teeth
// make the ratio exactly 1 so one input π = π at every blade, no per-branch tuning.
// The APEX blade (horizontal axis) is a SEPARATE open problem — NOT modelled here.
//
// ELEVATION: the blades ride the 21 mm elevator; the gears are axially FIXED in a basement
// (Z −33..−27, below the pan at −24). Each pinion has a SQUARE through-bore; each blade carries
// a square shaft that slides in that bore — torque through the flats, free vertical travel.
//
//   PART in: sun | idler | pinion | shafts | geartrain | all
// =============================================================================

SCALE = 20/18; R = 50*SCALE + 2; N = 11;               // 57.556 — mirror proto_simple.scad
function angleOf(k) = -90 + (k-1)*(360/N);
function Pp(k)      = [R*cos(angleOf(k)), -R*sin(angleOf(k))];
function midp(i,j)  = [(Pp(i)[0]+Pp(j)[0])/2, (Pp(i)[1]+Pp(j)[1])/2];
PAIRS = [[3,4],[5,6],[7,8],[10,11]];

// ---- gear params ----
mG   = 1.2;                          // module (robust for a 0.4 nozzle: tip r ≥ 13, teeth thick)
// Tooth counts: sun = pinion = 25 (so ω_pinion/ω_sun = 1 exactly, one input π = π at every blade),
// idler = 21 = the SMALL gear. This is the FIX for the adjacent-idler collision the checker caught:
// idlers are forced to radius 27.6 (half of sun→pinion 55.224), and on the two 65.45° station gaps
// adjacent idler CENTERS are only 29.84 apart. A 25T idler (tip r16.2) clashes there (needs 32.4);
// a 21T idler (tip r13.8, needs 27.6) clears by 2.24 mm. Bigger sun/pinion, smaller idler.
Zsun = 25; Zidl = 21; Zpin = 25;
PA   = 20;                           // pressure angle
GCLR = 0.25;                         // root clearance / backlash
Ridl = 27.60;                        // idler center radius on each pair ray (= sun+idler CD)
GZ   = -30; gh = 6;                  // gear layer center Z + face thickness → Z −33..−27
sqf  = 5.0;                          // square shaft across flats
bwh  = 20.8;                         // divider blade height (mirror divider_simple)

// ---- geometry helpers ----
function azray(i,j)   = atan2(midp(i,j)[1], midp(i,j)[0]);       // origin→pair-center ray azimuth
function idlerpos(ij) = [Ridl*cos(azray(ij[0],ij[1])), Ridl*sin(azray(ij[0],ij[1]))];
function pinpos(ij)   = midp(ij[0], ij[1]);                      // pinion sits UNDER the blade
function fmod(x,m)    = x - floor(x/m)*m;
// conjugate mesh clocking: given driver phase phi_i (deg), tooth counts, and the line-of-centers
// azimuth a_ij (deg), return the driven gear's phase so a tooth of i lands in a space of j.
function meshphase(phi_i, zi, zj, a_ij) =
    let(pi_ = 360/zi, pj = 360/zj, aji = a_ij + 180,
        fi  = fmod((a_ij - phi_i)/pi_, 1))
    fmod(aji - (fi + 0.5)*pj, pj);
// sun→idler and idler→pinion are BOTH along the ray (collinear), so both use azray.
function phi_idler(ij)  = meshphase(0, Zsun, Zidl, azray(ij[0],ij[1]));
function phi_pinion(ij) = meshphase(phi_idler(ij), Zidl, Zpin, azray(ij[0],ij[1]));

// ---- involute spur gear (self-contained; from m12_clean.scad's spur_gear) ----
function inv_deg(a) = tan(a)*180/PI - a;
module sgear(z, h=gh, bore=0, sqbore=0) {
    pr = mG*z/2; rbc = pr*cos(PA); ra = pr + mG; rf = max(1, pr - (1.25*mG + GCLR));
    half = 90/z; beta = half - inv_deg(PA); r0 = max(rf, rbc); steps = 8;
    rpts = [ for (i=[0:steps]) let(r = r0 + (ra-r0)*i/steps, al = acos(min(1, rbc/r)),
                                   pol = inv_deg(al) + beta) [r*cos(pol), r*sin(pol)] ];
    rightflank = concat([[rf*cos(beta), rf*sin(beta)]], rpts);
    leftflank  = [ for (i=[len(rpts)-1:-1:0]) [rpts[i][0], -rpts[i][1]] ];
    tooth = concat(rightflank, leftflank, [[rf*cos(-beta), rf*sin(-beta)]]);
    difference() {
        union() {
            cylinder(h=h, r=rf+0.01, $fn=64);
            for (k=[0:z-1]) rotate([0,0,k*360/z]) linear_extrude(h) polygon(tooth);
        }
        if (bore>0)   translate([0,0,-1]) cylinder(h=h+2, r=bore/2, $fn=32);
        if (sqbore>0) translate([0,0,-1]) linear_extrude(h+2)
                          square([sqbore+0.3, sqbore+0.3], center=true);  // 0.15 slip fit/side
    }
}

// ---- placed parts (rendered at rest phase; the viewer applies the swap spin) ----
module sun_gear()    { translate([0,0,GZ]) sgear(Zsun, gh, bore=6); }        // hollow-ish sun (input)
module idler_gear(ij){ p=idlerpos(ij); translate([p[0],p[1],GZ]) rotate([0,0,phi_idler(ij)])  sgear(Zidl, gh, bore=3); }
module pinion_gear(ij){p=pinpos(ij);   translate([p[0],p[1],GZ]) rotate([0,0,phi_pinion(ij)]) sgear(Zpin, gh, sqbore=sqf); }

// square shaft: from the pinion top (GZ+gh) up to the blade bottom at WORKING height (−0.4).
// (At rest/park the blade is 21 lower; the shaft simply slides deeper into the bore.)
module sq_shaft(ij) {
    p = pinpos(ij); z0 = GZ + gh; z1 = eq_working_bottom();
    translate([p[0], p[1], z0]) linear_extrude(z1 - z0) square([sqf, sqf], center=true);
}
function eq_working_bottom() = 10 - bwh/2;   // −0.4 (ball plane 10, blade 20.8 centered)

module shafts() { for (ij = PAIRS) sq_shaft(ij); }
module geartrain() {
    sun_gear();
    for (ij = PAIRS) { idler_gear(ij); pinion_gear(ij); }
    shafts();
}

// bare gears at the ORIGIN, spanning Z 0..gh (the viewer instances them at (px,py,GZ) with phase+spin)
module sun_bare()    { sgear(Zsun, gh, bore=6); }
module idler_bare()  { sgear(Zidl, gh, bore=3); }
module pinion_bare() { sgear(Zpin, gh, sqbore=sqf); }

PART = "all";
if      (PART == "sun")       sun_bare();
else if (PART == "idler")     idler_bare();
else if (PART == "pinion")    pinion_bare();
else if (PART == "shafts")    shafts();
else if (PART == "geartrain") geartrain();
else {
    color([0.85,0.7,0.35]) sun_gear();
    for (ij = PAIRS) { color([0.55,0.7,0.9]) idler_gear(ij); color([0.9,0.55,0.45]) pinion_gear(ij); }
    color([0.6,0.6,0.65]) shafts();
}
