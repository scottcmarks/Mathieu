// TRACK-2 (2,9) PROOF SOLIDS — depth-multiplexed direct cross
// =============================================================================
// The long pair swaps by passing in Z: ball 2 rides SHALLOW across the centre at ring height,
// ball 9 rides DEEP in an under-lane beneath it; each lands at the other's station. Every transit
// ball is held by a GRAVITY-PROOF FORK (cup below the equator + a C-lip over the shoulder + a
// ~110 deg slip-mouth toward the path) so it can't escape in any orientation. Kinematics mirror
// clean/check_29.py EXACTLY (so reported frame numbers match the checker + viewer).
//   render one frame:  openscad -o f.stl -D 'PART="frame"' -D U=0.5 proto_29.scad
//   carriers for the solid sweep: PART="carrier2" / "carrier9" (with -D U=..)
//   sweep visualisation:          PART="sweep"
SCALE = 20/18;             // ball_d = 20 mm (stock bearing size)
R     = 50*SCALE;          // 55.56
N     = 11;
ball_d= 18*SCALE;          // 20
rb    = ball_d/2;          // 10
eq    = ball_d/2;          // 10
DROP  = 27;                // ball-9 under-lane depth below eq (crossing gap = DROP-ball_d = 7; boss floor ~ 2*ball_d)
RAMP  = 0.20;              // descent/ascent u-fraction at each end

// fork (gravity-proof carrier)
clr   = 0.4;               // ball running clearance inside the cup
wall  = 1.6;               // fork wall thickness
fork_dz = 4.0;             // C-lip reaches this far ABOVE the ball centre (past the equator)
mouth_half = 55;           // half-angle of the slip-mouth (110 deg total -> chord 18.4 < ball_d)
stem_w = 5;                // carrier stem (down to a notional rail)

U = 0.0;                   // frame fraction (set with -D U=..)

function A(s)   = -90 + (s-1)*(360/N);
function Pf(s)  = [R*cos(A(s)), -R*sin(A(s))];
function lerp2(p,q,t) = [p[0]+(q[0]-p[0])*t, p[1]+(q[1]-p[1])*t];
function ss(x)  = let(t = max(0,min(1,x))) t*t*(3-2*t);
function dfrac(u) = u<RAMP ? ss(u/RAMP) : (u>1-RAMP ? ss((1-u)/RAMP) : 1);
// 2-9 paths BOW toward the dead centre (quadratic bezier, control = origin) so the crossing ducks
// INSIDE the divider inward-swings (avoids the concurrent ball-2 vs ball-10 graze the full sweep found);
// 2 & 9 still meet at the centre but pass in Z.
function bez0(a,b,u) = [(1-u)*(1-u)*a[0]+u*u*b[0], (1-u)*(1-u)*a[1]+u*u*b[1]];
function b2(u)  = let(p=bez0(Pf(2),Pf(9),u)) [p[0],p[1],eq];
function b9(u)  = let(p=bez0(Pf(9),Pf(2),u)) [p[0],p[1],eq - DROP*dfrac(u)];
function head2()= atan2(Pf(9)[1]-Pf(2)[1], Pf(9)[0]-Pf(2)[0]);
function head9()= atan2(Pf(2)[1]-Pf(9)[1], Pf(2)[0]-Pf(9)[0]);

module ball() sphere(r=rb, $fn=48);

// the fork, ball centre at local origin, slip-mouth opening toward +x then rotated to `heading`
module fork(heading) {
    rotate([0,0,heading]) difference() {
        // spherical shell, closed cup below, capped at z = fork_dz (so the rim is a C-lip past eq)
        intersection() {
            difference() { sphere(r=rb+wall, $fn=56); sphere(r=rb+clr, $fn=56); }
            translate([0,0,-(rb+wall)-1]) cylinder(h=(rb+wall)+fork_dz+1, r=rb+wall+1, $fn=56);
        }
        // slip-mouth: a 110 deg pie wedge removed on the +x side, full height
        linear_extrude(height=3*ball_d, center=true)
            polygon(concat([[0,0]],
                [ for (a=[-mouth_half:5:mouth_half]) (rb+wall+2)*[cos(a),sin(a)] ]));
    }
    // stem down to a notional rail (carrier drive; not load-checked here)
    translate([0,0,-(rb+wall)]) cylinder(h=3, r=stem_w/2, $fn=20);
}

// ---- MAGNET-GRIP carrier (alternative to the fork) ------------------------------------------
// A plain STEEL ball sits in a shallow SADDLE (cup below the equator only — no C-lip); an embedded
// MAGNET disc just under the cup holds it down, so retention is magnetic, not geometric, and the
// ball is a standard bearing. The magnet sits low on the carrier and the carrier parks deep, so at
// rest the magnet is far from a ball at the ring (no spin grab). magbody = cup+stem, magdisc = magnet.
magnet_r = 7; magnet_h = 4; cup_wall = 1.8; cup_or = rb + cup_wall;   // Ø14x4 N42 -> ~4x hold on a Ø20 solid bearing, hangs less (lets DROP shrink)
module mag_cradle() {
    intersection() {
        difference() { sphere(r=cup_or,$fn=56); sphere(r=rb+0.5,$fn=56); }     // spherical shell
        translate([0,0,-cup_or-1]) cylinder(h=cup_or-1.5, r=cup_or+1, $fn=56);  // keep only z <= -1.5 (a saddle below the equator)
    }
}
module mag_disc()  { translate([0,0,-rb-0.8-magnet_h/2]) cylinder(h=magnet_h, r=magnet_r, center=true, $fn=36); }
module mag_body()  { mag_cradle(); translate([0,0,-cup_or+0.5]) cylinder(h=3, r=3.2, $fn=24); }   // cup + short stem
module mag_carrier(heading) { rotate([0,0,heading]) { color([0.7,0.74,0.8]) mag_body(); color([0.85,0.30,0.30]) mag_disc(); } }
module magbody_only(which,u){ translate(which==2?b2(u):b9(u)) rotate([0,0,which==2?head2():head9()]) mag_body(); }
module magdisc_only(which,u){ translate(which==2?b2(u):b9(u)) rotate([0,0,which==2?head2():head9()]) mag_disc(); }

// ---- THROAT PLUG (rest-state seal of the swap-lane bore at stations 2,9) -----------------------
// The carrier rises through a bore of radius cup_or+clr (> rb), so WITHOUT a seal a resting ball
// would drop into it when inverted. A NON-magnetic plug disc caps the bore at rest (the ball rests
// on it); it drops to clear the lane during transit, then returns. Discipline: the plug opens only
// while the carrier already holds the ball (plug-open ⊂ carrier-engaged) -> retention never breaks.
bore_r = cup_or + 0.6;          // 12.4  lane bore the carrier passes through
plug_t = 3; plug_r = bore_r + 1.2;
module plug_disc() { cylinder(h=plug_t, r=plug_r, $fn=56); }
module plug_at(which, ztop) { c = which==2?Pf(2):Pf(9); translate([c[0],c[1], ztop-plug_t]) plug_disc(); }

module carrier(which, u) {
    c = which==2 ? b2(u) : b9(u);
    h = which==2 ? head2() : head9();
    translate(c) { color([0.9,0.92,1]) ball(); color([0.8,0.55,0.3]) fork(h); }
}
module ball_only(which, u) { translate(which==2 ? b2(u) : b9(u)) ball(); }
module fork_only(which, u) { translate(which==2 ? b2(u) : b9(u)) fork(which==2?head2():head9()); }

module resting_balls() {
    for (s=[1:N]) if (s!=2 && s!=9) translate([Pf(s)[0],Pf(s)[1],eq]) color([0.7,0.74,0.82]) ball();
}
module ring_ref() {           // a thin reference ring at the spin radius (context only)
    color([0.4,0.45,0.55,0.25]) rotate_extrude($fn=160) translate([R,0]) circle(r=0.8,$fn=12);
}

// ---------------- dispatch ----------------
PART = "frame";
if      (PART=="carrier2") fork_only(2,U);            // fork+bore for the solid sweep (ball checked separately)
else if (PART=="carrier9") fork_only(9,U);
else if (PART=="ball2")    ball_only(2,U);
else if (PART=="ball9")    ball_only(9,U);
else if (PART=="resting")  resting_balls();
else if (PART=="fork")     fork(0);
else if (PART=="plug")     plug_disc();
else if (PART=="magbody")  mag_body();
else if (PART=="magdisc")  mag_disc();
else if (PART=="magcarrier") mag_carrier(0);
else if (PART=="sweep") {                             // the two carved channels (union over u)
    color([0.30,0.65,0.95,0.5]) for (k=[0:40]) fork_only(2,k/40);
    color([0.95,0.55,0.30,0.5]) for (k=[0:40]) fork_only(9,k/40);
}
else {                                                // PART=="frame": one inspectable frame at U
    ring_ref(); resting_balls();
    carrier(2,U); carrier(9,U);
}
