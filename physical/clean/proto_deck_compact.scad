// M12 ALTERNATIVE ARCHITECTURE — COMPACT DECK (band-threading variant)
// =============================================================================
// The concept ease_deck in proto_band.scad is a SOLID SLAB (cylinder r=R-2) that
// interpenetrates the fixed band's walls — not printable. This file reshapes the deck
// into a THIN CHANNEL-NETWORK that THREADS the band's OPEN regions instead of a slab,
// keeping the same 5.62 mm ease:
//   * the deck BODY lives in the band's clear INNER DISC (radius < band inner wall);
//   * each BORE is an OVER-EQUATOR CHANNEL (a carved tube ROOFED with a narrow slot so the
//     top mouth < ball_d -> the ball is retained in transit in any orientation);
//   * the bores reach the station wells (at radius R, in the carved ball-torus) by crossing
//     the band's inner wall ONLY through a small NOTCH, kept entirely BELOW the spin equator
//     so the resting-ball spin retention is never breached;
//   * drums sit in cavities in the deck; deck + drums drop together by EASE for the swap.
//
// Mirrors clean/proto_band.scad constants EXACTLY.
//   openscad -o x.stl -D 'PART="deck"'  proto_deck_compact.scad
//   PART in: band | deck | drums | apex | drum0..4 | notches | all
use <proto_band.scad>

// ---- constants (mirror proto_band.scad) ----
SCALE   = 1.25;
R       = 50*SCALE;            // 62.5
N       = 11;
ball_d  = 18*SCALE;            // 22.5
rb      = ball_d/2;            // 11.25
eq      = ball_d/2;            // 11.25
tube    = rb + 0.3;            // 11.55
spin_top= eq + sqrt(tube*tube - rb*rb) + 1.5;     // 15.365
wall_t  = 1.5*SCALE;           // 1.875
chamf   = 1.5*SCALE;
floorz  = eq - tube;           // -0.3
rw      = rb + 1.5;            // 12.75 (station well radius)
dw      = 16*SCALE;
disc_h  = 4.5;
clr     = 0.4;

apexR   = R + 24*SCALE;        // 92.5
RD      = rb + 0.5;            // 11.75
FP      = RD + rb + 1;         // 24
CR      = R - RD - 1;          // 49.75
EASE    = (spin_top - eq) + 1.5;   // 5.615
chz     = eq - EASE;           // 5.635  (ball-centre height during the carry)
INNER   = [[2,9],[3,4],[5,6],[7,8],[10,11]];

// band geometry handles (for threading the OPEN regions)
band_inner = R - tube - wall_t;   // 49.075  inner wall surface (solid band starts here outward)
band_outer = R + tube + wall_t;   // 75.925
clear_disc = band_inner - 0.6;    // 48.475  the deck body must stay inside this (clear of the wall)

function angleOf(i) = -90 + (i-1)*(360/N);
function Pp(i) = [R*cos(angleOf(i)), -R*sin(angleOf(i))];
function dmid(i,j) = (Pp(i)+Pp(j))/2;
function dlen(v)   = sqrt(v[0]*v[0]+v[1]*v[1]);
function dunit(v)  = v/dlen(v);
function isfar(i,j)= dlen(dmid(i,j)) < CR-4;
function drumC(i,j)= isfar(i,j) ? [0,0] : dunit(dmid(i,j))*CR;
function drumAx(i,j)= isfar(i,j) ? atan2(dmid(i,j)[1],dmid(i,j)[0])-90 : atan2(drumC(i,j)[1],drumC(i,j)[0])+90;
function dentries(i,j) = let(C=drumC(i,j), a=drumAx(i,j))
    [ [C[0]+cos(a)*RD, C[1]+sin(a)*RD], [C[0]-cos(a)*RD, C[1]-sin(a)*RD] ];

// ---- over-equator channel geometry ----
// br = the carved tube radius (ball passage). sw = slot half-width at the roof.
// The roof closes the channel above the ball except a slot of width 2*sw, so the top
// mouth (2*sw) < ball_d and the ball is captured past its equator in any orientation.
br      = rb + 0.4;            // 11.65  passage radius (running clearance)
sw      = rb - 0.85;           // 10.40  slot half-width -> mouth 20.8 < 22.5
roof_t  = 1.6;                 // roof thickness over the slot lip
wall_m  = 1.2;                 // minimal wall around the channel tube
// channel top (lip) height: ball-surface height at the slot edge -> over-equator
zlip    = chz + sqrt(rb*rb - sw*sw);   // 9.924  (< eq=11.25, so spin retention intact)
ch_bot  = chz - br - wall_m;           // channel block bottom
ch_top  = chz + br + wall_m;           // raw channel block top (before roofing the slot)

// ============================================================================
//  CHANNEL PRIMITIVES
// ============================================================================
// A SOLID channel block segment between two xy points (the minimal-wall structure that
// HOLDS a bore), at chamber z. We build the network as a union of these, then carve the
// ball passage (over-equator) and roof-slot out of it.
module chan_block(a,b) {
    hull() {
        translate([a[0],a[1],ch_bot]) cylinder(h=ch_top-ch_bot, r=br+wall_m, $fn=28);
        translate([b[0],b[1],ch_bot]) cylinder(h=ch_top-ch_bot, r=br+wall_m, $fn=28);
    }
}
// the carved ball passage (a swept sphere/cylinder tube) between two points
module chan_void(a,b) {
    hull() {
        translate([a[0],a[1],chz]) sphere(r=br, $fn=28);
        translate([b[0],b[1],chz]) sphere(r=br, $fn=28);
    }
}
// the roof slot: the OPEN top of the channel (width 2*sw) so a finger/the ball mouth shows,
// but capped by the lip on both sides. We carve a slot box from chz+ (lip) up through the top.
module chan_slot(a,b) {
    dx=b[0]-a[0]; dy=b[1]-a[1]; L=sqrt(dx*dx+dy*dy); ang=atan2(dy,dx);
    translate([a[0],a[1],0]) rotate([0,0,ang])
        translate([-br-wall_m, -sw, zlip])
            cube([L+2*(br+wall_m), 2*sw, (ch_top+roof_t)-zlip + 1]);
}

// the full set of routed bore segments (mirrors check_assembly.py routing exactly)
function bore_segs(i,j) =
    let(e=dentries(i,j))
    isfar(i,j)
      ? let(wpi = dunit(Pp(i))*(CR-FP-1), wpj = dunit(Pp(j))*(CR-FP-1))
        [ [Pp(i),wpi],[wpi,e[0]], [Pp(j),wpj],[wpj,e[1]] ]
      : [ [Pp(i),e[0]], [Pp(j),e[1]] ];

// flatten all bores' segments
function all_segs() = [ for (p=INNER) for (s=bore_segs(p[0],p[1])) s ];

// ============================================================================
//  THE COMPACT DECK
// ============================================================================
// 1) a THIN inner-disc hub (a ring/plate in the band's clear inner disc) to tie the
//    channel arms together and host the drum cavities + lift stem;
// 2) channel-block ARMS along every routed segment;
// minus 3) the carved over-equator ball passages; 4) the roof slots; 5) the drum cavities;
//          6) central shaft clearance.
hub_r   = clear_disc;          // 48.475  hub outer radius (inside the band inner wall)
hub_bot = chz - br - wall_m;
hub_h   = (chz + br + wall_m) - hub_bot;   // matches channel block height

// the spin floor: ABOVE this z, at radii out under the band's spin channel (r > R-tube), the
// BAND owns the space (precise rolling torus + lip). The deck must NOT add solid there or it
// fouls the spin channel and cannot be notched away (notching there breaches spin). So the deck
// arms are FULL height only inside the band inner wall; out under the spin channel they are
// clipped to z <= floorz (they tuck UNDER the spin floor; the band's well provides the rest).
spin_floor = floorz;            // -0.3
r_spin     = R - tube;          // 50.95  inner edge of the spin torus (deck must clear above floor here)
module deck_solid() {
    intersection() {
        union() {
            // thin hub plate in the clear inner disc
            translate([0,0,hub_bot]) cylinder(h=hub_h, r=hub_r, $fn=180);
            // channel-block arms (reach OUTWARD to the wells, crossing the band wall via notches)
            for (s=all_segs()) chan_block(s[0],s[1]);
        }
        // CLIP: keep everything inside r_spin at full height; outside r_spin keep only z<=spin_floor
        union() {
            cylinder(h=ch_top+roof_t+1, r=r_spin, $fn=180);                  // inner column, full height
            translate([0,0,ch_bot-1]) cylinder(h=(spin_floor)-(ch_bot-1), r=band_outer+2, $fn=180); // sub-floor everywhere
        }
    }
}
module deck_voids() {
    // carve the ball passages
    for (s=all_segs()) chan_void(s[0],s[1]);
    // roof slots (open top, lip retained)
    for (s=all_segs()) chan_slot(s[0],s[1]);
    // drum cavities
    for (p=INNER) { C=drumC(p[0],p[1]);
        translate([C[0],C[1], chz-br-wall_m-1]) cylinder(h=hub_h+3, r=FP-0.2, $fn=56); }
    // central shaft clearance
    translate([0,0,-50]) cylinder(h=100, r=3.5, $fn=24);
}
module deck() {
    union() {
        difference() { deck_solid(); deck_voids(); }
        // DRUM CEILING ROOF — caps the open-topped drum cavities (the dominant gravity gap).
        drum_roofs();
        // CENTRAL-ARM OUTER CAPS — close the central pair's route-in/route-out open-top window.
        central_arm_caps();
        // 11 flush pocket-discs ride the deck (they drop with it)
        for (k=[1:N]) pocket_disc_local(k);
        // lift stem
        translate([0,0, chz-br-wall_m-14]) cylinder(h=14, r=4, $fn=24);
    }
}

// ============================================================================
//  DRUM CEILING ROOF  (the new cap over the 5 open-topped drum cavities)
// ============================================================================
// Each drum's two pockets ORBIT the drum centre at radius RD; the ball-top sweeps a circle of
// radius RD as the drum turns 180 deg. proto_band.scad's drum is a sphere + an OPEN cylinder up
// (no ceiling), so a ball mid-swap (route-in -> drum-turn -> route-out) was uncapped from above.
//
// The roof is a flat plate, part of the EASE-DECK (drops with it), sitting ABOVE the ball-top so
// the drum spins freely UNDER it. Over each drum it is a solid disc of radius FP with an ANNULAR
// SLOT centred on the ball-orbit radius RD: the slot radial width is 2*sw (= the bore mouth,
// 20.80 mm) < ball_d (22.50), so the ball CANNOT pass up through it in any orientation, yet its
// top pokes up into the open slot as it orbits. The slot is open all the way round the 180 deg arc
// so it caps BOTH pocket positions and every angle between (route-in entry -> turn -> route-out
// entry). The disc's outer ring (RD+sw .. FP) BRIDGES to the bore-block roofs that meet the drum
// entries (same xy footprint, overlapping z), so capping is continuous bore-roof -> drum-roof ->
// bore-roof with no hand-off gap.
//
// Heights: the plate underside sits a running clearance ABOVE the ball-top so it never fouls the
// rotating drum/ball; this puts the whole roof ABOVE the band (spin_top=15.37) -> it can NEVER
// touch the band's spin lip nor interpenetrate the (notched) band, so the closed gates stay closed.
ball_top   = chz + rb;                 // 16.885  highest point of a carried (eased) ball
roof_gap   = 0.8;                       // running clearance: roof underside above the ball-top
// MODE-A FIX: the roof is on the EASE-DECK and DROPS by EASE with it. It must therefore be placed
// above the RESTING ball crown (eq+rb); since both roof and ball then drop by the SAME EASE, the
// roof tracks the ball-top at a constant roof_gap through the WHOLE motion -> it caps the eased ball
// during the swap AND clears the full-height resting/spinning ball at rest. (The old chz+rb+gap
// assumed a non-dropping deck, so at rest it sat EASE=5.6 mm too low and fouled the spinning ball.)
droof_bot  = eq + rb + roof_gap;        // 23.30  (clears resting crown 22.5; drops to 17.70 in swap)
droof_top  = droof_bot + roof_t;        // 24.90
post_top   = chz + 6;                   // 11.635  top of the drum pivot post (clears droof_bot)
// The annular slot disconnects the inner lip (the central hub that blocks the ball escaping
// toward the centre) from the outer ring (which bridges to the bores). We tie them with a few
// THIN radial spokes that span the slot at the roof z-level: the ball-top passes a running
// clearance UNDER them (they are above ball_top), and between spokes the opening stays the
// annular slot (radial width 2*sw < ball_d), so retention is unaffected and the part is one
// connected manifold.
n_spoke   = 3;                          // spokes bridging the slot (manifold tie)
spoke_w   = 2.0;                        // spoke half-width (thin, so they barely shadow the slot)
module drum_roofs() {
    for (p=INNER) {
        C = drumC(p[0],p[1]);
        translate([C[0],C[1],0]) union() {
            // outer ring (bridges out to the bores) — solid [RD+sw .. FP]
            translate([0,0,droof_bot]) difference() {
                cylinder(h=roof_t, r=FP,      $fn=72);
                translate([0,0,-1]) cylinder(h=roof_t+2, r=RD+sw, $fn=72);
            }
            // inner lip / hub — solid [0 .. RD-sw] (blocks the ball escaping inward+up; the post
            // top at z=11.635 is far below the roof underside, so no post-clearance hole is needed)
            translate([0,0,droof_bot]) cylinder(h=roof_t, r=RD-sw, $fn=48);
            // spokes spanning the slot, tying hub to ring (thin -> opening stays < ball_d)
            for (a=[0:n_spoke-1]) rotate([0,0,a*360/n_spoke])
                translate([0,-spoke_w,droof_bot]) cube([FP, 2*spoke_w, roof_t]);
        }
    }
}
// ============================================================================
//  CENTRAL-ARM OUTER CAPS  (close the central pair's route-in / route-out gap)
// ============================================================================
// The rim drums' ceiling roofs happen to overhang their rim stations and cap the eased ball
// during route-in/route-out at those stations; the CENTRAL drum sits at the origin so its roof
// (radius FP) does NOT reach the central stations (2,9 at radius R=62.5). The central arms are
// therefore un-roofed where they cross the band's spin annulus (r in [r_spin .. R]), leaving the
// eased central ball open-topped during route-in (r 51..60) and route-out.
//
// We cap those route frames with a thin plate that rides ABOVE the eased ball, following each
// central arm's radial line outward from the inner roofed region (r_spin) to the largest route
// radius (cap_r_out). The eased ball crown is at ball_top=16.885; the plate underside is held a
// running clearance above it AND, where a *resting/spinning* ball at the station would otherwise
// be hit, above that ball's surface too.
//
// The hard limit is the resting ball at the arm's OWN station (centre (R,eq), radius rb): at
// height z it reaches inward to r_ball_in(z)=R-sqrt(rb^2-(z-eq)^2). To clear it, a flat step over
// r in [r_in,r_out] must sit at z >= cap_under(r_in) (r_in is the most restrictive: smaller r ->
// the ball surface is higher). cap_under(r)=max(ball_top+roof_gap, eq+sqrt(rb^2-(R-r-clr)^2)).
// The plate is always above spin_top (the band top), so it never touches the band -> the
// deck∩band and spin-intact gates are untouched. The station-ease frames (ball AT r=R, easing
// vertically) are NOT capped here: a cap above that ball's crown at r=R lies INSIDE the body of a
// resting ball at the same station (r=R +- ~8 mm at z~19), so it is geometrically irreducible.
cap_r_in   = r_spin;                 // 50.95  inner edge: hand off from the existing inner roofing
cap_r_out  = 60.0;                   // outer edge: covers route radii up to ~59.64 (max route r)
cap_step   = 0.5;                    // radial step size of the staircase underside
cap_clr    = 0.4;                    // clearance from the resting ball surface
cap_halfw  = br + wall_m;            // 12.85  half-width of the cap strip across the arm
function r_ball_in(z) = R - sqrt(rb*rb - (z-eq)*(z-eq));     // resting-ball inner surface radius at z
// cap underside at radius r: above the eased crown, and above the resting ball where it reaches r
function cap_under(r) =
    let(inside = (R - (r+cap_clr)))                          // how far the target r is inside R
    max(droof_bot,                                           // never below the eased-crown roof level
        (abs(inside) < rb) ? eq + sqrt(rb*rb - inside*inside) : droof_bot);
module central_arm_caps() {
    for (p=INNER) if (isfar(p[0],p[1])) {
        for (which=[p[0],p[1]]) {
            u = dunit(Pp(which));                            // radial unit vector toward the station
            ang = atan2(u[1],u[0]);
            // staircase of flat step boxes along the arm, each set by its INNER radius
            for (r0=[cap_r_in : cap_step : cap_r_out-cap_step]) {
                zu = cap_under(r0);                          // underside set by inner radius (most restrictive)
                translate([0,0,0]) rotate([0,0,ang])
                    translate([r0, -cap_halfw, zu])
                        cube([cap_step+0.01, 2*cap_halfw, roof_t]);
            }
            // tie the cap down into the deck: a vertical web at the inner edge dropping from the
            // cap underside into the FULL-HEIGHT inner arm (which exists for r<=r_spin up to
            // ch_top+roof_t). The web lives entirely inside r_spin so it cannot foul the spin
            // annulus or the band, and inside r_spin the resting ball never reaches (R-rb=51.25),
            // so it cannot hit a resting ball either.
            rotate([0,0,ang])
                translate([cap_r_in-3, -cap_halfw, ch_top])
                    cube([3.5, 2*cap_halfw, (droof_bot+roof_t)-ch_top]);
        }
    }
}
// local copy of pocket_disc (so we don't depend on proto_band internals when carved)
module pocket_disc_local(k) {
    translate([Pp(k)[0], Pp(k)[1], floorz - disc_h]) difference() {
        cylinder(h=disc_h, r=rw - clr, $fn=64);
        translate([0,0,disc_h]) sphere(r=rb + 0.6, $fn=48);
    }
}

// ============================================================================
//  BAND INNER-WALL NOTCHES (one where each bore crosses the wall, sub-ball level)
// ============================================================================
// A notch = the channel block intersected with a thin annular shell around the band inner
// wall, but kept ENTIRELY BELOW the spin equator. Used both as a preview (PART="notches")
// and (conceptually) as the cut applied to the band. The notch top = zlip (< eq).
// The notch must remove ALL band material the deck arm would occupy WHERE the arm crosses the
// band's inner wall — full arm cross-section, full arm height — but it is radially CLIPPED to
// r < r_spin (=R-tube=50.95): the spin lip/torus lives at r >= r_spin, so a notch bounded inside
// r_spin can NEVER open the spin channel. (The deck itself is clipped to z<=floorz beyond r_spin,
// so beyond the wall there is nothing left to notch above the floor anyway.)
notch_clr = 0.5;               // notch slightly oversize so the arm clears the notched band
module notch_cutters() {
    intersection() {
        // the full arm envelope (every segment), full height + roof
        union() {
            for (s=all_segs())
                hull() {
                    translate([s[0][0],s[0][1],ch_bot-0.5])
                        cylinder(h=(ch_top+roof_t)-(ch_bot-0.5), r=br+wall_m+notch_clr, $fn=28);
                    translate([s[1][0],s[1][1],ch_bot-0.5])
                        cylinder(h=(ch_top+roof_t)-(ch_bot-0.5), r=br+wall_m+notch_clr, $fn=28);
                }
        }
        // CLIP radially to r < r_spin (spin torus is at r>=r_spin) — spin lip untouched
        cylinder(h=spin_top+roof_t+2, r=r_spin, $fn=180);
    }
}
// the fixed band WITH the inner-wall notched (a notched band; the real deliverable band is
// proto_band.scad's fixed_band, which we must NOT modify — this shows the intended cut).
module band_notched() {
    difference() { fixed_band(); notch_cutters(); }
}

// ============================================================================
//  DRUMS / APEX (reuse proto_band modules)
// ============================================================================
// (drum & apex_input come from proto_band.scad via `use`)

// ============================================================================
//  CHECKER HELPERS — solid intersections the gravity/intersection checker measures
//  (additive PARTs; they do not affect the printable parts)
// ============================================================================
// deck vs the NOTCHED band: should be ~0 (the notches make room for the bore crossings)
module xsect_notched()   { intersection() { deck(); band_notched(); } }
// deck vs the UNNOTCHED band: the prior-run baseline overlap (~3544 mm^3) at the crossings
module xsect_unnotched() { intersection() { deck(); fixed_band();   } }
// the equatorial spin-retention shell: a thin slab of the band at z=eq (where a resting ball
// is captured by the lip). If notching the band removes ANY of this, the spin channel is opened.
// the spin-retention region = the band torus/lip at r >= r_spin (the rolling channel + lip that
// caps a resting ball). The inner wall ring (r < r_spin) is NOT what retains the ball, and the
// notches are confined there, so the spin shell must measure only r >= r_spin.
module spin_retain_slab() {
    intersection() {
        translate([0,0,eq-0.5]) cylinder(h=1.0, r=band_outer+2, $fn=180);
        difference() {
            cylinder(h=spin_top+2, r=band_outer+2, $fn=180);
            translate([0,0,-1]) cylinder(h=spin_top+4, r=r_spin, $fn=180);  // remove inner wall ring
        }
    }
}
module spin_shell()         { intersection() { fixed_band();   spin_retain_slab(); } }
module spin_shell_notched() { intersection() { band_notched(); spin_retain_slab(); } }

// ============================================================================
//  SPIN KEEP-OUT  (mode-A fix for the drum cup-body over-reach)
// ============================================================================
// The volume a ball sweeps while resting / rolling in the spin channel is the 11-station torus
// (centre radius R, z=eq, tube rb+clearance).  NOTHING in the swap mechanism may intrude here or it
// fouls the spinning ball.  The rim drums sit so close to their stations that their cup BODIES reach
// out under the resting ball (the ~850 mm^3 in the solid sweep).  We positively guarantee clearance
// by subtracting this torus from the drums (and the deck).  It sits BELOW the raised roof (top 22.9
// < droof_bot 23.3), so it does not touch the roof; the central drum (at the origin) is far from its
// stations, so only the rim cups are trimmed.
spin_clr = 0.4;
module spin_keepout() {
    translate([0,0,eq]) rotate_extrude($fn=200) translate([R,0]) circle(r=rb+spin_clr, $fn=48);
}
module deck_clean()    { difference() { deck();          spin_keepout(); } }
module drum_clean(i,j) { difference() { drum(i,j);       spin_keepout(); } }

// ---------------- dispatch ----------------
PART = "all";
if      (PART=="band")     band_notched();
else if (PART=="deck")     deck_clean();
else if (PART=="drums")    for (p=INNER) drum_clean(p[0],p[1]);
else if (PART=="apex")     apex_input();
else if (PART=="notches")  notch_cutters();
else if (PART=="roof")     drum_roofs();
else if (PART=="caps")     central_arm_caps();
else if (PART=="drum0")    drum_clean(INNER[0][0],INNER[0][1]);
else if (PART=="drum1")    drum_clean(INNER[1][0],INNER[1][1]);
else if (PART=="drum2")    drum_clean(INNER[2][0],INNER[2][1]);
else if (PART=="drum3")    drum_clean(INNER[3][0],INNER[3][1]);
else if (PART=="drum4")    drum_clean(INNER[4][0],INNER[4][1]);
else if (PART=="xsect_notched")     xsect_notched();
else if (PART=="xsect_unnotched")   xsect_unnotched();
else if (PART=="spin_shell")        spin_shell();
else if (PART=="spin_shell_notched")spin_shell_notched();
else {                                       // full assembly preview
    color([0.55,0.60,0.70,0.32]) band_notched();
    color([0.30,0.55,0.85])      deck_clean();
    color([0.80,0.55,0.30])      for (p=INNER) drum_clean(p[0],p[1]);
    color([0.88,0.47,0.25])      apex_input();
}
