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

// The disc IS the capture channel: a continuous ring groove (all balls ride in
// it at one height, so 2 & 9 line up with the rest), widened into round pockets
// at the neighbour swap pairs, with full through-holes at 2 & 9 (the idler arm
// supports them at rest and carries them down/around during a swap).
ch_in    = R - (ball_d/2 + 2);   // 39  channel inner radius
ch_out   = R + (ball_d/2 + 2);   // 61  channel outer radius
ch_floor = 2;                    // channel floor height
module disc_body() {
    top = base_th + rim_h;
    difference() {
        union() {
            cylinder(h = base_th, r = R + margin);
            translate([0,0,base_th])
                difference() {
                    cylinder(h = rim_h, r = R + margin);
                    translate([0,0,-0.1]) cylinder(h = rim_h+0.2, r = R + margin - 4);
                }
        }
        // continuous channel groove carved into the disc
        translate([0,0,ch_floor]) difference() {
            cylinder(h = top - ch_floor + 1, r = ch_out);
            translate([0,0,-0.1]) cylinder(h = top - ch_floor + 1.2, r = ch_in);
        }
        // swap pockets: round widenings at every pair EXCEPT the (2,9) cross
        // (apex idx 0 included so the apex swap has a carved region too)
        for (idx = [0:len(pairs)-1]) if (idx != 1) {
            a = P(pairs[idx][0]); b = P(pairs[idx][1]);
            rsw = chord_len(idx)/2 + ball_d/2 + 1.5;
            translate([(a[0]+b[0])/2,(a[1]+b[1])/2, ch_floor])
                cylinder(h = top - ch_floor + 1, r = rsw);
        }
        // (2,9): full through-holes (ball drops to the idler arm below)
        for (s = pairs[1]) { p = P(s); translate([p[0],p[1],-1]) cylinder(h = top+2, d = ball_d+3); }
        // apex pair (idx 0): no well — ball 0 sits outboard, off the disc
    }
}

// The CAPTURE CHANNEL: a real trough (inner + outer walls) the balls ride in,
// NOT a solid ring. Radial gaps at each swap pair let a ball bulge out into its
// swap pocket instead of plowing through a wall.
module carousel() {
    inr = R - (ball_d/2 + 2); outr = R + (ball_d/2 + 2); wt = 2; h = ball_d*0.8;
    difference() {
        union() {
            difference() { cylinder(h=h, r=inr+wt); translate([0,0,-0.1]) cylinder(h=h+0.2, r=inr); }   // inner wall
            difference() { cylinder(h=h, r=outr);   translate([0,0,-0.1]) cylinder(h=h+0.2, r=outr-wt); } // outer wall
        }
        for (idx = [1:len(pairs)-1]) {            // gaps at swap-pair midpoints
            a = P(pairs[idx][0]); b = P(pairs[idx][1]);
            ma = atan2((a[1]+b[1])/2, (a[0]+b[0])/2);
            rotate([0,0,ma]) translate([0,-(ball_d+4)/2,-1]) cube([outr+5, ball_d+4, h+2]);
        }
    }
}

// Clear ball, centred at origin. The number is a SEPARATE part (so it can be
// black on a clear ball); the colour lives on the fixed position ring, not here.
module ball_at_origin(n) { sphere(d = ball_d); }

// The number repeated on all 12 dodecahedron faces of the ball, barely proud of
// the surface (the balls roll, so it can't stick up) — a number always faces you.
// Centred at origin to match the ball; viewer renders these black.
module num_at_origin(n) {
    phi = (1 + sqrt(5)) / 2;
    nv  = sqrt(1 + phi*phi);
    dirs = [ [0,1,phi],[0,1,-phi],[0,-1,phi],[0,-1,-phi],
             [1,phi,0],[1,-phi,0],[-1,phi,0],[-1,-phi,0],
             [phi,0,1],[phi,0,-1],[-phi,0,1],[-phi,0,-1] ];   // dodeca face centres
    r  = ball_d/2;                // OUTER face flush with the surface (recessed inward)
    t  = 0.6;                     // numeral goes inward; nothing protrudes (balls roll)
    sz = ball_d*0.26;             // smaller still, so 10/11 aren't crowded
    for (i = [0:len(dirs)-1]) {
        d = dirs[i] / nv;
        rotate([0,0, atan2(d[1], d[0])]) rotate([0, acos(d[2]), 0])
            translate([0,0,r - t]) rotate([0,0, i*40])   // various angles
            linear_extrude(t) text(str(n), size = sz, halign="center", valign="center");
    }
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

// A carrier/swing-arm of length L along +x, centred at origin. Each end has a
// seat cup with a partial retaining rut so a ball can't fall off mid-swing (the
// (2,9) arm especially must hold when the toy is vertical/upside-down).
module carrier_origin(L) {
    cup = ball_d*0.92; wall = ball_d*0.34;
    difference() {
        union() {
            linear_extrude(carrier_th)
                hull() { translate([-L/2,0]) circle(d=cup); translate([L/2,0]) circle(d=cup); }
            for (s = [-1,1]) translate([s*L/2, 0, carrier_th-0.01])   // retaining rut walls
                difference() {
                    cylinder(h = wall, d = cup);
                    translate([0,0,-0.1]) cylinder(h = wall+0.2, d = cup-2.6);
                }
        }
        for (s = [-1,1]) translate([s*L/2, 0, carrier_th + wall*0.55])  // concave seat cups
            sphere(d = ball_d*0.98);
    }
    cylinder(h = carrier_th + 3, d = 6);   // pivot hub
}

// --- drive train (schematic gears so the motion has a visible cause) ---
gear_h = 5;
// rotor pinion: small external gear, centred at origin
module pinion() {
    pr = 7; n = 10; tw = 2.4; tl = 2.6;
    cylinder(h = gear_h, r = pr - 1);
    for (i = [0:n-1]) rotate([0,0,360/n*i]) translate([pr-tl, -tw/2, 0]) cube([tl+0.6, tw, gear_h]);
    cylinder(h = gear_h + 3, d = 4);                 // hub / shaft
}
// the rim ring gear: an annulus with INWARD teeth that the rotor pinions mesh
module ring_gear() {
    rin = 55; band = 6; n = 40; tw = 2.4; tl = 2.6;
    difference() {
        union() {
            difference() {
                cylinder(h = gear_h, r = rin + band);
                translate([0,0,-0.1]) cylinder(h = gear_h + 0.2, r = rin);
            }
            for (i = [0:n-1]) rotate([0,0,360/n*i]) translate([rin - tl, -tw/2, 0]) cube([tl, tw, gear_h]);
        }
        // (2,9) drop gaps: a wide ARC at each (the gear rotates, so the gap must
        // stay under the ball through the whole swing) — clear of the pinion angles
        for (s = [2,9]) for (da = [-26,-13,0,13,26]) {
            a = angleOf(s) + da;
            translate([R*cos(a), -R*sin(a), -1]) cylinder(h = gear_h+2, d = ball_d+8);
        }
    }
}
// a snap-in bearing/bushing for the load-bearing pivots: outer body + snap
// flange + a snap groove, with a shaft bore through the middle.
module bearing() {
    od = 10; bore = 4.2; h = 5; fl = 1.3;
    difference() {
        union() {
            cylinder(h = h, d = od);
            translate([0,0,h-1]) cylinder(h = 1, d = od + 2*fl);   // top snap flange
            translate([0,0,1.2]) cylinder(h = 1.0, d = od + 1.4);  // snap detent ring
        }
        translate([0,0,-0.1]) cylinder(h = h + 1.2, d = bore);     // shaft bore
    }
}

// Case bottom shell (BackSpin-style enclosure): a dish everything mounts to,
// with snap-on axle POSTS (rods) at each rotor pivot + the centre. Bearings
// (MF105) snap onto the posts; the rotors, idler arm, and carousel spin on them.
// The mating top shell (with ball windows) is the other half.
module case_bottom() {
    floor_th = 3; wallh = base_th + 2;
    difference() {
        cylinder(h = wallh, r = R + margin + 1);
        translate([0,0,floor_th]) cylinder(h = wallh, r = R + margin - 2);   // hollow interior
    }
    for (idx = [0:len(pairs)-1]) {                       // axle posts at the rotor pivots
        a = P(pairs[idx][0]); b = P(pairs[idx][1]);
        translate([(a[0]+b[0])/2,(a[1]+b[1])/2,floor_th]) cylinder(h = carrier_z, d = 4.8);
    }
    translate([0,0,floor_th]) cylinder(h = carrier_z, d = 7.8);              // central post (608 bore)
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
else if (MODE == "bearing")  bearing();
else if (MODE == "pinion")   pinion();
else if (MODE == "ringgear") ring_gear();
else if (MODE == "casebottom") case_bottom();
else                         assembly();
