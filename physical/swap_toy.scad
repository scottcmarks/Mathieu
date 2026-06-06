// swap_toy.scad
// Parametric layout starter for the Sporadic M12 physical swap toy.
// Realizes the swap (0 1)(2 9)(3 4)(5 6)(7 8)(10 11).
//
// This is a LAYOUT / extension scaffold, not a finished printable model:
// it places the 12 slot positions, draws the base disc, the 6 connecting
// carriers/chords (color-coded), and the swept circles of the diametral
// rotors so conflicts are visible. Extend with real rotor/gear/bridge bodies.
//
// Coordinate convention matches the engine/design doc: +x right, +y DOWN
// (screen). OpenSCAD's Y is up, so we negate Y when placing, keeping the
// numeric coords identical to DESIGN.md.

/* ---------------- Parameters ---------------- */
N            = 11;     // ring slots (1..11); apex is slot 0
pitch_dia    = 100;    // pitch-circle diameter Dp (mm)  -> R = 50
token_dia    = 22;     // printed token disc OD (mm); must be < neighbor pitch (28.17)
clearance    = 0.25;   // moving-fit clearance (mm), 0.2-0.3 typical for FDM
apex_extra   = 0.25;   // apex radial offset past rim, in units of R (0.25 -> 12.5mm stroke)
base_th      = 6;      // base disc thickness (mm)
base_margin  = 12;     // extra radius of base beyond rim (mm)
slot_mark_d  = 8;      // diameter of slot marker peg (mm)
show_swept   = true;   // draw rotor swept circles (conflict visualization)
show_labels  = true;   // 3D number labels

R   = pitch_dia/2;
$fn = 64;

/* ---------------- Slot positions ---------------- */
// Returns [x,y] in DESIGN.md convention (y DOWN). i in 0..11.
function slot_xy(i) =
    (i == 0)
        ? [0, -(1 + apex_extra) * R]                       // apex above slot 1
        : let(a = -90 + (i - 1) * (360 / N))               // ring slot
          [R * cos(a), R * sin(a)];                         // OpenSCAD cos/sin are degrees

// Place a child at slot i (negate Y to convert screen-down -> OpenSCAD-up).
module at_slot(i) {
    p = slot_xy(i);
    translate([p[0], -p[1], 0]) children();
}

// 2D-style line (thin extruded box) between two slots, at height z.
module chord(i, j, w = 4, z = 1, col = "gray") {
    a = slot_xy(i); b = slot_xy(j);
    ax = a[0]; ay = -a[1]; bx = b[0]; by = -b[1];
    len = norm([bx - ax, by - ay]);
    ang = atan2(by - ay, bx - ax);
    color(col)
        translate([ax, ay, z])
        rotate([0, 0, ang])
        translate([0, -w/2, 0])
        cube([len, w, 1.2]);
}

// Swept circle of the rigid diametral rotor for pair (i,j): centered on the
// midpoint, radius = chord/2. Drawn as a thin ring for conflict visualization.
module swept(i, j, col = "red") {
    a = slot_xy(i); b = slot_xy(j);
    mx = (a[0] + b[0]) / 2; my = -((a[1] + b[1]) / 2);
    r  = norm([a[0] - b[0], a[1] - b[1]]) / 2;
    color(col, 0.25)
        translate([mx, my, 0.3])
        linear_extrude(0.4)
        difference() { circle(r); circle(r - 1); }
}

/* ---------------- Pairs ---------------- */
neighbor_pairs = [[3,4],[5,6],[7,8],[10,11]];  // green
cross_pair     = [2,9];                         // red
apex_pair      = [0,1];                         // blue

/* ---------------- Assembly ---------------- */
module base_disc() {
    color("gainsboro")
        cylinder(h = base_th, r = R + base_margin);
}

module slot_markers() {
    for (i = [0:11])
        at_slot(i) color(i==0||i==1 ? "steelblue" : "dimgray")
            cylinder(h = base_th + 2, d = slot_mark_d);
}

module token_pockets() {
    // visualize the captive token footprint at each slot
    for (i = [0:11])
        at_slot(i) color("white", 0.5)
            translate([0,0,base_th])
            cylinder(h = 5, d = token_dia + 2*clearance);
}

module labels() {
    if (show_labels)
        for (i = [0:11])
            at_slot(i)
                translate([0,0,base_th + 5.2])
                linear_extrude(1)
                text(str(i), size = 6, halign="center", valign="center");
}

module chords() {
    for (p = neighbor_pairs) chord(p[0], p[1], 4, base_th+0.5, "green");
    chord(cross_pair[0], cross_pair[1], 4, base_th+0.5, "red");
    chord(apex_pair[0],  apex_pair[1],  6, base_th+0.5, "steelblue");
}

module swepts() {
    if (show_swept) {
        for (p = neighbor_pairs) swept(p[0], p[1], "green");
        swept(cross_pair[0], cross_pair[1], "red");   // the big conflicting one
        swept(apex_pair[0],  apex_pair[1],  "steelblue");
    }
}

base_disc();
slot_markers();
token_pockets();
chords();
swepts();
labels();

// --- Extension hooks (TODO for a printable model) ---
// module neighbor_rotor() { ... }   // dumbbell carrier, 2 token end-pockets, central Ø3 pin bore
// module sun_pinion()     { ... }   // Ø8 pitch, drives 1:1 train
// module bridge_2_9()     { ... }   // over/under cam-lifted carriages for the long chord
// module carousel()       { ... }   // 11-pocket indexing ring, 32.727deg detents
// module top_window()     { ... }   // clear plate with 12 oval apertures
