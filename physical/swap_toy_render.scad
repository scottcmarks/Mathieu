// swap_toy_render.scad
// Presentation / viewer model of the Sporadic M12 physical swap toy.
// Realizes swap #22 = (0 1)(2 9)(3 4)(5 6)(7 8)(10 11).
//
// Each 2-cycle (i,j) is a CARRIER: a dumbbell with a ball-cup at each end that
// pivots 180 degrees about the pair midpoint to trade the two balls. One input
// (the 0->1 pull) spins all six carriers together. The long (2,9) carrier would
// sweep the centre, so in the real design those two balls transfer through the
// disc thickness (front<->back) instead — the "bridge".
//
// Export modes (STL is colourless; the web viewer recombines + colours parts):
//   MODE="disc"            -> clear glass disc body with oblong wells
//   MODE="ball"  BALL=0..11-> one numbered ball, centred at origin
//   MODE="carrier" PAIR=0..5-> one carrier bar (that pair's length), at origin
//   MODE="all"             -> full assembly, for a static PNG/POV render (default)
//
// Coord convention matches DESIGN.md (+x right, +y DOWN); OpenSCAD Y is up so we
// negate Y on placement (numeric coords stay identical to the doc).

/* ---------------- Export selectors ---------------- */
MODE = "all";
PAIR = 0;
BALL = 0;

/* ---------------- Parameters ---------------- */
N          = 11;
pitch_dia  = 100;
ball_d     = 18;
track_w    = 24;
track_depth= 7;
base_th    = 14;
rim_h      = 4;
margin     = 14;
apex_extra = 0.55;   // was 0.25 (12.5mm) -> 0.55 (27.5mm) so ball 0 clears ball 1
carrier_th = 4;

R   = pitch_dia/2;
$fn = 64;

/* ---------------- Slot positions ---------------- */
function angleOf(i) = -90 + (i - 1) * (360 / N);   // ring slots 1..11 (degrees)
function slot_xy(i) =
    (i == 0) ? [0, -(1 + apex_extra) * R]
             : let(a = angleOf(i)) [R*cos(a), R*sin(a)];
function P(i) = let(p = slot_xy(i)) [p[0], -p[1]];

pairs = [[0,1],[2,9],[3,4],[5,6],[7,8],[10,11]];
function chord_len(idx) = let(pr = pairs[idx]) norm(P(pr[0]) - P(pr[1]));

ball_z    = base_th - track_depth + ball_d/2 - 1;   // seat height of ball centre
carrier_z = base_th - track_depth + 1;              // carrier sits below the balls

/* ---------------- Helpers ---------------- */
module stadium2d(a, b, w) {
    hull() { translate(a) circle(d=w); translate(b) circle(d=w); }
}

// Clear glass disc. The five local pairs get oblong front wells; the (2,9)
// cross pair gets TWO round through-holes instead (its swap routes via the back
// arm, not a front channel) so the geometry tells the truth about the mechanism.
module disc_body() {
    hole_d = ball_d + 3;
    difference() {
        union() {
            cylinder(h = base_th, r = R + margin);
            translate([0,0,base_th])
                difference() {
                    cylinder(h = rim_h, r = R + margin);
                    translate([0,0,-0.1]) cylinder(h = rim_h+0.2, r = R + margin - 4);
                }
        }
        for (idx = [0:len(pairs)-1]) {
            pr = pairs[idx];
            if (idx == 1) {                       // (2,9): through-holes at each end
                for (s = pr) {
                    p = P(s);
                    translate([p[0], p[1], -1]) cylinder(h = base_th + rim_h + 2, d = hole_d);
                }
            } else {                              // local pair: oblong front well
                a = P(pr[0]); b = P(pr[1]);
                translate([0,0,base_th - track_depth])
                    linear_extrude(track_depth + rim_h + 1) stadium2d(a, b, track_w);
            }
        }
    }
}

// Indexing carousel: a circular channel (annulus) with 11 radial dividers, one
// pocket per ring slot 1..11. Spin rotates this one detent (360/11 deg). Base at
// z=0; the viewer drops it so the balls sit in the channel. Apex (0) is NOT on it.
module carousel() {
    ch_w = ball_d + 6; ch_h = ball_d*0.62; wall = 1.6;
    color("#7f8aa0") {
        difference() {
            cylinder(h = ch_h, r = R + ch_w/2);
            translate([0,0,-0.1]) cylinder(h = ch_h+0.2, r = R - ch_w/2);
        }
        for (i = [1:11]) {                        // dividers between pockets
            a = angleOf(i) + (360/N)/2;
            rotate([0,0,a]) translate([R - ch_w/2, -wall/2, 0]) cube([ch_w, wall, ch_h]);
        }
    }
}

// Clear ball, centred at origin. The number is a SEPARATE part (so it can be
// black on a clear ball); the colour lives on the fixed position ring, not here.
module ball_at_origin(n) { sphere(d = ball_d); }

// A numeral solid, centred at origin (viewer places it at the ball's top, black).
module num_at_origin(n) {
    linear_extrude(1.6) text(str(n), size = ball_d*0.52, halign="center", valign="center");
}

// A position ring/collar, centred at origin (viewer places one at every slot and
// colours it by the slot's swap-pair). These stay with the POSITION, not the ball.
module ring_at_origin() {
    inr = ball_d/2 + 1.2; outr = ball_d/2 + 4.2; h = 5.5;
    difference() {
        cylinder(h = h, r = outr);
        translate([0,0,-0.1]) cylinder(h = h+0.2, r = inr);
    }
}

// A carrier bar of length L along +x, centred at the origin: end cups + hub.
module carrier_origin(L) {
    cup = ball_d*0.9;
    linear_extrude(carrier_th)
        hull() { translate([-L/2,0]) circle(d=cup); translate([L/2,0]) circle(d=cup); }
    cylinder(h = carrier_th + 3, d = 6);   // pivot hub
}

/* ---------------- Full static assembly ---------------- */
module assembly() {
    color("#9fb3c8", 0.25) disc_body();                 // glassy tint in preview
    for (idx = [0:len(pairs)-1]) {
        pr = pairs[idx]; a = P(pr[0]); b = P(pr[1]);
        mx = (a[0]+b[0])/2; my = (a[1]+b[1])/2;
        ang = atan2(b[1]-a[1], b[0]-a[0]);
        color("#8893a5")                                 // carrier
            translate([mx, my, carrier_z]) rotate([0,0,ang]) carrier_origin(chord_len(idx));
        for (k = [0,1]) {
            p = P(pr[k]);
            translate([p[0], p[1], ball_z]) ball_at_origin(pr[k]);
        }
    }
}

/* ---------------- Export switch ---------------- */
if      (MODE == "disc")     disc_body();
else if (MODE == "ball")     ball_at_origin(BALL);
else if (MODE == "num")      num_at_origin(BALL);
else if (MODE == "ring")     ring_at_origin();
else if (MODE == "carrier")  carrier_origin(chord_len(PAIR));
else if (MODE == "carousel") carousel();
else                         assembly();
