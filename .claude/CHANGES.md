# Mathieu — Change Log

## 2026-06-04 — The big rebuild: M12 revived across platforms

Goal: get **M12** building in multiple variants, linked from a landing page
analogous to sudokux4.com. Approach chosen: a **Flutter port reusing the C++
`PlatformIndependent` engine over FFI** (the SudokuX4 model), since the old
native cross-platform code was Apple-only and bit-rotted. Native iOS kept as a
fallback; macOS-native AppKit port deliberately not pursued.

### Engine / FFI
- New C ABI shim `flutter/native/mathieu_ffi.{cpp,h}` over
  `MathieuPermutationWithHistory` (new/free/reset/left/right/swap/random/undo/
  revert, arrangement, swap-index + swap-permutation, macros A..E, history,
  moves/steps, is_solved). Include via `m12.h` (nBalls=12, nSwaps=341).
- FFI entry points marked `__attribute__((used))` to survive dead-strip and
  resolve via `DynamicLibrary.process()` on Apple. (Tried
  `-exported_symbols_list` — broke dyld; reverted.)
- Compiles `mathieu_ffi.cpp` + `m12.cc` + `~/Toolbox/.../rand_utils.c`.

### Flutter app (`flutter/`)
- Full port on **iOS, macOS, web, Android** (Windows/Linux wired for CI).
- `lib/main.dart`: black bg; **fixed coloured spheres** (colour = position's swap
  pairing) with **moving number labels**; rotations spin labels along the arc,
  swaps exchange in straight lines; continuous finger-drag with **flick/momentum**
  + speed slider; marble gradient from `BallView.mm`; flat Shake/Home controls;
  A/A⁻¹/Alt macros; status line + counters; Settings flip page with
  swap-permutation **preview + picker**; applause only on first solve of a
  scramble; portrait-locked.
- Per-platform native build: `native/CMakeLists.txt` (libmathieu_engine),
  android gradle `externalNativeBuild` (minSdk 28), linux/windows
  `add_subdirectory(../native)`; web via `native/build_wasm.sh` (emcc) +
  `web/mathieu_glue.js` + js_interop, conditional-import barrel
  `lib/mathieu_ffi.dart`; `emscripten_compat.c`/`win32_compat.c` for arc4random.
- Runner pbxproj wired programmatically with the ruby `xcodeproj` gem (mod-pbxproj
  choked on Flutter 3.44 SPM build files).
- **Display name M₁₂**, bundle id `com.magnoliaheights.SporadicM12` (replaces the
  original native app), swap-ring icon.
- Audio: one **WAV** master set in `assets/sounds/` (left/right/swap/combo/
  combo_set/success/applause/shake/home/restart).

### Native iOS
- Revived the original `Apple/iPhone/Mathieu.xcodeproj` under Xcode 26
  (`neg<T>()`, `#else` typo, `CISwipeTransition`, IB SystemTarget); fixed the
  **permutation-selector modal** UI bug. Kept as a fallback.

### Apple Watch (`watch/`)
- New standalone SwiftUI watchOS app reusing the same engine (xcodegen from
  `project.yml`). Crown rotates the ring; A / A⁻¹ peer buttons; Double-Tap → A.
- Installed + launched on a real Apple Watch (team 23JBC9D428). Simulator install
  is buggy on this Mac (CoreSimulator IXUserPresentableError) — device only.
  Sidecar for now; TestFlight/landing tile later.

### Engine bug fix
- `PlatformIndependent/M12/Permutation/M12PermTable.h`: added missing
  `return *this;` to `perm_info & operator=(Perm p)` — falling off the end was UB
  that modern clang -O2 turned into a **segfault** in `find_all_permutations`.
  Documented the generator build in `REGENERATION.md`.

### Hosting (live)
- **Web is live:** https://magnolia-heights.com/sporadicgames/m12/
- `web/index.html` landing page + `web/deploy.sh` (build web with base-href
  `/sporadicgames/m12/app/`, **additive** rsync over SSH to magnol9@…:2222).
- Backed up the server's existing `sporadicgames/` tree before deploy; old SVN
  landing pages left in place but **unlinked** (to be rewritten later).

### Goldens / Git LFS
- Migrated the large permutation tables (`Perms.bin.golden`, M24 ~477 MB) into
  **Git LFS** (history rewrite) to unblock push. Static blob → uploaded once.
- Regeneration: segfault root-caused/fixed; M12 regenerates to correct size but
  ~132/4.56M bytes off golden (padding/order); M24 not fully generated. **Goldens
  remain the source of truth** until bit-exact.

### CI
- `.github/workflows/desktop.yml` — Linux + Windows builds, **`workflow_dispatch`
  only** (never on push/PR, per requirement). Needs repo secret `TOOLBOX_PAT`.

### Repo
- Active branch **`develop`** on `git@github.com:scottcmarks/Mathieu.git`, pushed
  over SSH (gh auth dead on this machine).
- Deferred (manual, Scott): set default branch to `develop`; add `TOOLBOX_PAT`;
  un-pause Actions; bump home-repo submodule pointer via wapex recipe.

## 2026-06-23 / 24 / 25 — Track 2 reconfigurable-wall: built, then a parser bug revealed real interference

This was a multi-day stretch designing, modelling, and (we thought) verifying
Track 2 of the physical M12 toy (`physical/clean/`) — the reconfigurable-wall
architecture replacing the static-channel design that hit irreducible spin-vs-swap
collisions in earlier rounds. Final session ended with the discovery that the
solid-overlap verifier had been silently broken; the architecture stands, but the
detail geometry needs a real revision pass.

### Architecture decisions locked
- **Gravity-safe master invariant** (Scott): at every instant, every ball is held
  PAST ITS EQUATOR by some retainer (spin wall / swap-ring / magnet) with
  overlapping hand-offs. Encoded in `check_confine.py` with a `--selftest`.
- **Two ball-grip vocabulary:** spin-ring + grooved-channel swap-ring + magnet —
  all over-equator (mouth < ball Ø).
- **Neighbour mechanism = in-plane DIAMETER DIVIDER** rotating π about a vertical
  axis (Scott chose, vs radial-axis tumble — picked for robustness: vertical-axis
  gears cleanly off the main drivetrain; no per-pair grippers).
- **(2,9) = depth-multiplex direct cross** with a magnet grip (steel ball
  bearings + captive magnets, Scott's reframe; safer + simpler than magnetic
  balls; force model closes 4–17×).
- **0–1 = 5th divider pair at the apex** (radial converge).
- **Bow the 2-9 path through the dead centre** so it ducks INSIDE the divider
  inward-swings (cross-pair fix found by analytic sweep).
- **Lid** (Scott): opaque top piece whose underside is channelled to match —
  finger-slot over the spin ring, full cap over the swaps.
- **Drivetrain** (one input): hollow sun (60T, bore for 2-9 lane) + 4 ring-divider
  planets + 1 idler at the circle-circle intersection (NOT on the radial line —
  the fix after a 10T idler couldn't bridge) + apex planet. Sun turns 33° → every
  divider turns π. Geneva couples sun only during the confined middle. Cam drum
  on the same shaft drives dish-rise + seg-drop + 2-9 magnet-lift.
- **Stations 2 & 9 throat seal** = a non-magnetic plug + carrier-as-plug hand-off
  (the magnet stays parked DEEP and only rises through the opened plug).
- **Ball Ø20 stock chrome-steel** (52100, magnetic — NOT austenitic stainless),
  via `SCALE = 20/18`. Boss height 47 mm; footprint Ø ~150 (the swing-out cost
  of the in-plane divider).

### Files built (`physical/clean/`)
- `proto_29.scad`, `proto_wall.scad` (spin_seg + grooved swap_wall + divider),
  `proto_lid.scad`, `proto_drive.scad` (sun/planet/idler/drum/geneva)
- Checkers: `check_29.py`, `check_29_solid.py`, `check_29_mag.py`, `check_wall.py`,
  `check_wallwall.py`, `check_full.py`, `check_confine.py`, `check_drive.py`,
  `check_cam.py`
- Viewers: `viewer_29.html` (depth-multiplex + spin + grippers that rise from
  the depths), `viewer_wall.html` (full reconfiguration with `drivetrain`+`lid`
  toggles)

### The parser bug Scott caught visually (2026-06-25)
Looking at viewer frame 112 Scott said "looks like the spin wall is intersecting
the 9-ball." Three of my "all PASS" boolean checks denied it. Investigation found:
my `vol()` STL parser opened files in BINARY mode and read facet count from
offset 80 — but **OpenSCAD emits ASCII STL by default** (`solid …` header).
For ASCII files, the consistency check failed and `vol()` silently returned 0.
So every solid sweep that reported 0 mm³ overlap was a lie.

Direct boolean on Scott's flagged case: ball-9 vs `spin_seg(2)` at frame 112
= **692.57 mm³** real overlap (was reported as 0).

Fix landed in all 5 affected checkers: sniff `d[:5]==b'solid'`, parse ASCII
vertex lines first, then fall back to binary.

### Honest re-verification after the fix
- **Still PASS (analytic, never affected by the bug):** `check_29`, `check_confine`,
  `check_drive`, `check_cam`, `check_29_mag`. The analytic BALL-BALL portion of
  `check_full` also still passes (the 2↔10 graze fix via the centre-bow stands).
- **Now failing (the real interference the bug was hiding):**
  - `check_29_solid` RETENTION — fork ball-fits overlap 23.76 mm³.
  - `check_wall` RING-BALL (31 + 27 frames), SEG-BALL (6), SWING-SEG (3),
    INNER-DROP (8).
  - `check_wallwall` spin segs ∩ swap rings during the swap.
  - `check_full` BALL-WALL 15 of 17 sampled frames; worst 3279 mm³ @ frame 6.

### What this means
The Track-2 *architecture* is sound; the detail geometry needs a real revision —
fork cup sizing, seg/ring radial clearance during the up-down overlap, kinematics
tuning so no moving wall crosses a ball, and 2-9 INNER-DROP timing. Memory note
records the parser-bug lesson for all future checkers: always sniff STL format.

## 2026-07-02 — Track-2: swap-ring variants exhausted, simple-walls concept adopted

### The path (multi-session narrative)
Started with the divider swap-ring vs spin-band radial-overlap architectural
pickle. Explored via `viewer_variants.html`: (A) push M outward → PASS but body
grows to Ø234, (B) asymmetric arc → FAIL, (C) z-staged → PASS but had a
pass-through hole Scott caught visually. Ran a workflow with 4 sub-variants of C
(petaled dish / parked-high / no-dish-cradle / rotating-slotted); adversarial
review killed 3 outright — including one via a silent-zero bug (`check_C3.py`
had no `use <proto_wall.scad>`, so unknown modules yielded empty intersection →
0 mm³ false PASS). C1 (petaled) only worked for 4 of 5 pairs; apex arithmetic
was unrecoverable.

### The reframe (Scott's simplification)
Drop the elaborate seg geometry entirely. **Walls are plain rectangular
vertical pieces** (~ball-Ø × half-ball tall × 2 mm thick) that only confine
LATERALLY. The over-equator capture moves into the **lid** whose underside
carries the spin-channel and swap-channel torus carves.

### Files created (`physical/clean/`)
- `proto_simple.scad` — spin_segment_real (11 arc walls), swap_ring (segmented),
  divider_simple, bases
- `proto_simple_{spin_seg,swap_ring,divider}.stl` — rendered parts
- `viewer_simple.html` — animated viewer for the (5,6) swap
- `check_simple.py` — per-frame solid interference checker (SWAP-vs-SPIN,
  DIV-vs-SPIN, DIV-vs-SWAP, BALL-vs-WALL, BALL-vs-DIV, BALL-vs-BALL)

### The iteration (all caught by the new checker)
Initial viewer had 39 bad category-frames. Scott flagged three visual bugs:
frames 6, 51, 112 — swap wall ∩ spin wall, balls counter-rotating and passing
through each other, divider not fitting through the spin wall. Fixes:
1. **Same-direction orbit** — both balls now go CCW paddled by the divider,
   180° apart (was counter-rotating, passing through).
2. **Segmented swap ring** — 2 short arcs at perpendicular-to-chord azimuths
   (which happens to align with the origin-radial through M → inter-seg gap),
   NOT a full 360° annulus.
3. **Phased schedule** — segs 5,6 drop FIRST (u=0.00–0.10), THEN divider +
   swap walls rise (0.10–0.20). Balls transit (0.20–0.35), divider π
   (0.35–0.65), balls exit (0.65–0.80), reverse.
4. **Inter-seg gap widened** 2° → 5° + divider thinned 3→2 mm — so divider
   fits through gap at band radii.
5. **Divider half-length trimmed** 21.9 → 21.0 — clears swap-ring inner edge.

**Result: 6/6 gates PASS** for pair (5,6). 39 bad frames → 0.

### New parser bug caught
OpenSCAD's `atan2()` returns **degrees** (not radians like every other language).
Multiplying by 180/PI placed the swap-ring arcs at random angles. Standing note
added to memory: OpenSCAD trig is ALWAYS degrees; never `* 180/PI` a trig
result.

### Open items carried forward
- Lid channels need re-designed to be a torus at r=12 from M (not old dome_path).
- Each other divider pair (3,4)(7,8)(10,11)(0,1) needs its own perpendicular-
  arc placement + re-check.
- Ball-push mechanism (what physically drives the ball from station to
  orbit_start) not yet modelled — balls follow scripted positions today.

### Extending to 5 pairs + wide-paddle + apex-vertical pivot

Same day, extended the (5,6) proof to all five neighbour swap pairs.

**Wide-paddle divider.** The divider was thin, so it wasn't touching the ball
surfaces. Widened it to a paddle whose chord width `dw = 2*(orbit − rb − clr)`,
so its side face contacts each ball with a 0.4 mm running clearance. Div half-
length dropped to 5 (corners now stay strictly inside empty channel space).
Parked deeper too — `PARK_DEPTH_DIV = 40` vs `PARK_DEPTH_SEG = 20`, so the
paddle parks below the dropped segs and doesn't share z with them.

**Chord-axis arcs added.** The swap ring grew from 2 perp arcs to **4 arcs** —
2 perpendicular (30° half-span) + 2 along the chord (12° half-span, narrower
because the chord-side wall reaches close to the outer spin-band). Full
"stretched-circle" containment for the two orbiting balls.

**Ring extended to 5 pairs.** `swap_ring(i,j)` and `divider_simple(i,j)` are
now pair-parameterized (any (i,j) with `pair_M`, `pair_orbit`, `pair_outer_R`,
`pair_div_w`). All 4 other ring pairs (3,4)/(7,8)/(10,11) rendered as a static
`other_pairs` STL for the viewer.

**Lid slab expanded** for the wider footprint: `slab_r = 113.55` and per-pair
torus carves cut via `pair_orbit_lid(i,j)` (ring pairs use half-chord 15.65,
apex uses 13.33).

### The apex (0,1) horizontal swap didn't fit

Pushing (0,1) through the same in-plane machinery revealed an inherent conflict:
the perp-arc endpoints reach world r ≈ 66.80–68.15, which sits inside spin-
seg 2's outer wall band (65.96–67.96), so the (0,1) swap ring pokes through
spin material at multiple frames. Ball 0 also sits at r ≈ 82 (outside the ring)
so lid overhang has to reach that far to bridge it — awkward.

### Apex → **VERTICAL** ring (Scott's pivot)

Instead of solving the in-plane conflict, rotate the whole (0,1) mechanism
**out of the horizontal plane**:

- Ring now lives in the **YZ plane** (x=0), centered at `(0, R, eq − half_chord) = (0, 55.56, −3.33)`, radius `half_chord = 13.33`.
- **Ball 1** sits at the TOP of the ring — its normal station-1 position `(0, 55.56, 10)`.
- **Ball 0** sits at the BOTTOM of the ring — `(0, 55.56, −16.66)`, **hidden below the floor** at rest.
- The (0,1) swap is a π rotation of the divider paddle about the **X axis**: balls exchange top↔bottom, so what pops up at station 1 was ball 0.

Implementation:

- `proto_simple.scad`: refactored `swap_ring(i,j)` into `swap_ring_local(i,j)`
  (geometry at LOCAL origin, no M translation) so it can be composed with
  arbitrary transforms. Added `swap_ring_apex_vertical()` =
  `translate([0, R, apex_Z_c()]) rotate([0, 90, 0]) swap_ring_local(0,1)`.
  New PART: `apex_vertical`.
- `other_pairs` PART now excludes (0,1) — only 3 rings (3-4, 7-8, 10-11) plus
  (5,6) which animates separately.
- `proto_lid.scad`: dropped (0,1) from DIVPAIRS (ball 0 no longer traces a
  horizontal torus under the lid — it's below the floor) and shrunk slab_r
  113.55 → 85.5 (only ring pairs need lid overhang now; the apex is a vertical
  shaft below the plane).
- `viewer_simple.html`: 6th STL loader for `proto_simple_apex_vertical.stl`,
  purple `apexVertMesh` added to the root, ball loop extended to include
  ball 0 rendered at `(0, R, eq − 2·half_chord) = (0, 55.56, −16.66)` in both
  idle and swap render paths.

## 2026-07-03..07 — Track-2: full 6-swap concept complete ("no gears yet")

Rapid-iteration run that took the simple-walls concept from one working
pair to the complete 6-swap machine, checked every frame. Highlights:

### Geometry (physical/clean/proto_simple.scad, proto_lid.scad)
- R +2 → 57.56; toy Ø200: pan + lid r=100, enclosing side cylinder
  r98–100, pan at −24..−22 with a "half spare tire" bulge housing the
  parked apex ring.
- Spin walls → two CONTINUOUS rings (4 paddle slots + station-1 outer
  wedge gap) riding a common 21 mm elevator frame through matching lid
  slits (bridges at the ring gaps keep the lid one piece).
- Swap rings → full tall annuli (20.8, ball-plane centered), all five
  the same size; CENTRAL (2,9) ring at the origin MERGED with the four
  pair rings (mutual interior-clearing); test-tube channels out to
  stations 2 and 9 (0.1 ball spacing).
- Apex (0,1) ring → 180° bottom arc, both-edge lips; in-plane rings +
  tubes → 1.0 × 2.0 bottom lips (2/9 tunnels become ball-captive).
- Paddles → thin blades (6 × ~51 × 20.8); apex blade 16 wide to fit the
  ball-proof 16.8 lid slit; π/2 bookend turns added (floor-paddle
  scheme) then removed — plain π turn, dividers on the rigid frame.
- Lid → vertex-colour zones, pockets for the tall rings/paddles,
  tunnel stadium pockets, apex slit + ball-transit torus.

### Choreography
rise [0,.20] → 2/9 tunnel in [.20,.35] → all dividers π + all orbits
[.35,.65] (2/9 CCW +130.9°/+229.1° at r16.71) → 2/9 out [.65,.80] →
drop [.80,1]. Full M12 swap perm applied to viewer state.

### Verification (check_simple.py)
Upgraded to EVERY frame (121), EVERY mechanism + the lid, 7 gates,
startup positive controls (abort on any empty solid). First full sweep
immediately caught two real apex-arc bugs (tips hitting resting balls
during the rise; tips inside the lid at swap-up) → fixed by the 180°
arc. Final state: ALL 7 GATES PASS every frame; separate housing sweep
(balls/mechanism vs lid/pan/side wall) CLEAN. Silent-zero bug family
grew by four members (no-arg module call, top-level forward reference,
wrong-cwd render, rv()-on-failure) — all now guarded.

### Viewer (viewer_simple.html)
All-six-swap sync animation, spin ◀/▶ with permutation state,
pair-colour station spotlights (+ toggle), diffuse + lid-opacity
sliders, pan/side/isolate-1/info toggles (info hidden by default for
phones), STL cache-buster, and a LIVE orange intersection highlighter
(three-mesh-bvh/three-bvh-csg: AABB → BVH → CSG, designed contacts
excluded, throttled during play after a stall made play skip frames).

### Not done (the tag says it)
No gears/drivetrain, no elevator-frame solid, no ball-push input, apex
kinematics still scripted, ball-0 rest outward confinement open.

### Open items carried forward (v2)
- Extra constraining wall panels for the vertical ring's mid-section (below
  the lid, above the drivetrain deck) — the lid covers only the top segment
  where ball 1 pokes out; the shaft body needs enclosing walls.
- Kinematics for the apex swap (rotation about X axis, phased schedule) not
  yet wired into `viewer_simple.html` — the vertical ring is currently static.
- `check_simple.py` doesn't yet sweep the apex vertical swap.
- Same open items as (v1): lid channels tightening, ball-push mechanism.

### Stow architecture + lift-into-lid-slots (v3)

Scott's simplification of the stow motion. Rules:
- **Swap-ring panels stow just panel-height below the spin ring** (not 40 mm).
  `PARK_DEPTH_SWAP: 40 → 11`, `PARK_DEPTH_DIV: 40 → 13`.
- **Spin-ring segments that clear a swap RISE UP into the lid** (not down).

#### First attempt — LIFT_SEG_UP=11 (panel-height) FAILED

Made the changes in parallel via workflow: `proto_lid.scad` grew blind pockets
at each of the 11 stations (inner + outer walls, Z=[11.5, 22.0], 0.4mm radial
clearance each side), `check_simple.py` and `viewer_simple.html` got the new
constants and sign-flipped seg motion.

Checker exposed the bug: `ball_vs_wall` FAILED, 13 bad frames, worst 508 mm³
at frame 45. Root cause: **ball body extends Z=[0, 20]**, so seg lifted to
Z=[11, 21.5] still overlaps ball Z by 9mm. During the (5,6) swap, ball 5's
center sweeps radially from station r=55.56 through r=44.66 (the seg's inner
wall radial position) to orbit-inward min r=37.68, and during that traversal
the ball's inner-radial flank is inside the wall's Z range → 3D collision.
Panel-height clearance was sufficient for swap-ring vs spin-ring, but not for
seg-vs-ball because balls are 20mm tall not 10.

#### Second attempt — LIFT_SEG_UP=21 with through-slots PASS

Chosen after weighing three variants: lift by ball-diameter + clearance so
seg bottom (Z=21) clears ball top (Z=20) with 1mm margin. Two ways to fit:
extend the lid taller (24 → 32) so seg stays inside, or cut through-slots
and let segs protrude 7.5mm above lid_top during the swap only. Scott picked
**slots + protrusion** for best ball exposure (lid stays 24mm tall, finger
depth to ball top stays at ~5mm).

Slot geometry: r=[42.76, 45.56] (inner) and r=[65.56, 68.36] (outer), each
2.8mm wide = wall_t 2.0 + 0.4mm clearance each side. Z=[11.5, 24.5] cuts
straight through the lid.

Capture preservation check: the over-equator "lips" at r=[45.16, 47.56]
(inner, 2.4mm wide) and r=[63.56, 65.96] (outer, 2.4mm wide) each lose only
their outermost 0.4mm sliver to the slots. Remaining 2.0mm lips still capture
the ball whose dome inner surface at Z=15 is at r=46.90 — well inside.

Lid rendered NoError, **Genus 22** (11 stations × 2 walls, confirming all 22
slots are through-cuts).

Positive control confirmed: same `check_simple.py` reported 508 mm³ at
LIFT=11 minutes before the fix and 0 mm³ at LIFT=21 — genuine detection, not
a silent-zero.

Files: `physical/clean/{proto_lid.scad,check_simple.py,viewer_simple.html}`.
All 6 gates PASS (swap_vs_spin/div_vs_spin/div_vs_swap/ball_vs_wall/ball_vs_div/ball_vs_ball).
