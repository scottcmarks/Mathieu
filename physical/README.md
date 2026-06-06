# physical/ — Sporadic M12 hand-held swap toy

A mechanical-design package for a palm-sized toy that physically performs **one swap move** of
the *Sporadic M12* puzzle (the digital app lives in the parent repo). A single user action — the
**0→1 pull** — simultaneously exchanges the two tokens in each of six position-pairs.

## Target permutation (the whole package designs around exactly this)

```
(0 1)(2 9)(3 4)(5 6)(7 8)(10 11)
```
- `(0 1)`  apex ↔ top-ring — the **trigger** (pull the apex token down toward slot 1)
- `(3 4)(5 6)(7 8)(10 11)`  four adjacent ring-neighbor swaps (short rim chords)
- `(2 9)`  the single long cross-ring chord

## Files
| File | What |
|------|------|
| `DESIGN.md` | Full design: concept comparison + recommendation, geometry tables, swept-circle conflict analysis, drive kinematics, parts list, tolerances, assembly, risks/tests. |
| `ring_layout.svg` | Top-view schematic: 11 ring slots + apex, all 6 swaps color-coded. |
| `swap_toy.scad` | Parametric OpenSCAD layout starter (slots, base disc, 6 carriers, swept circles), structured for extension. |
| `README.md` | This file. |

## How to view / render
- **SVG**: open `ring_layout.svg` in any browser, or `qlmanage -p ring_layout.svg` (macOS Quick
  Look). It is plain, valid SVG.
- **SCAD**: install OpenSCAD (`brew install --cask openscad`), then `Open` the file or
  `openscad swap_toy.scad`. Adjust parameters at the top (`pitch_dia`, `token_dia`, `clearance`,
  `apex_extra`, `show_swept`). The big red swept circle is the (2,9) rotor — note how it overlaps
  neighbors; that conflict is the core design problem (see DESIGN.md §3).

## Recommended mechanism (one line)
**5 coplanar 180° swap rotors** (4 rim-neighbor + 1 apex), all driven 1:1 from the apex pull via
a central pinion/gear train, **plus a single over/under "bridge"** that lifts the (2,9) pair out
of plane and carries the two tokens across on stacked lanes so they never collide. The ROTATION
generator is a separate **mode**: a 32.727°-indexing carousel that spins the 11 ring tokens
between swaps while the rotors are disengaged.

## Key numbers (at pitch-circle Ø = 100 mm)
- 0→1 pull stroke: **12.50 mm** → 180° on every rotor (sun pinion pitch Ø ≈ 8 mm).
- Neighbor rotor radius **14.09 mm** (chord 28.17 mm); apex rotor radius 6.25 mm.
- (2,9) rotor radius **45.48 mm** (chord 90.96 mm) — its swept disc passes through slots 1/10/11,
  which is exactly why the long chord uses the lifted bridge instead of a rigid bar.

## Related toy (partial analogue): Back Spin / Loophole
DESIGN.md §4.5 analyzes the **Back Spin** puzzle (a.k.a. *Loophole*; Ferdinand Lammertink, US
Pat. 5,172,912, 1992; Binary Arts → ThinkFun — **not Hasbro**), shown in `backspin_ref.jpg`. It
is a **two-faced rotary sliding-block puzzle**: two molded shells rotate against each other, 6
oblong pockets per face (3 radial spokes + 3 curved rim areas) holding 3 balls each (36 cells,
35 balls → **one empty cell**), with balls slid toward the hole by gravity and transferred
front↔back by **pushing through a registered hole** — no flip, no gears, **one ball per move**.
Because its native move is incremental and needs a blank cell, **it cannot apply our fixed
all-at-once 6-transposition**, so it does **not** replace Concept C. What we adopt from it:
two-shell molding, clear-window captive retention, race-track pockets with seat-as-detent, and
routing the (2,9) chord **through the disc thickness** rather than across it (corroborating the
over/under bridge). A pure "Concept D" Backspin clone is recorded but rejected for this toy.

## Status / next steps
Design study + valid layout geometry, **not yet a printable model**. No git commit (left for
review). Prior-art analysis incorporated (Back Spin, §4.5). **Recommended primary remains
Concept C**, now with a Backspin-derived **two-shell sandwich** part split and race-track
retention. Suggested prototype order: single neighbor-rotor hand-off coupon (race-track pocket)
→ 5-rotor train + drive (hand-swap 2/9) → carousel + mode switch → finally the (2,9)
through-thickness bridge. See DESIGN.md §10 and §4.5.
