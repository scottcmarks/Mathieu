# Sporadic M12 — Physical Swap Toy: CLEAN-SHEET Design

A palm-sized, hand-actuated mechanical toy that physically realizes the Sporadic-M12 puzzle:
the **spin** (cyclic shift of the 11 ring balls, apex 0 fixed) and the **fixed swap**
`(0 1)(2 9)(3 4)(5 6)(7 8)(10 11)` (engine swap #22), the swap driven by **flicking the apex
ball 0 down toward 1**.

> Clean-sheet effort. Workspace: `physical/clean/`. Does NOT reuse the `series/` mechanism —
> only its authoritative geometry numbers (Dp = 100 mm, slot coordinates, chord lengths).
> No git commit — left unstaged for human review.

---

## 0. Why a clean sheet — what the prior effort fought

The `series/` line routes *every* moving ball through channels **carved into the plate**, with
balls 1, 2, 9 ducking to deep z-lanes that thread under a central ring gear and past each
other. That created exactly the three pains the brief flags:

1. **Force-path congestion near the rim** — the slider/rack/pinion all crowd one quadrant.
2. **Threading balls** — balls 9 and 1 pass *through* the thickness on rails, so the checker
   must constantly prove "no rail threads a ball," and seats need wells punched through layers.
3. **Grab/release actuation** — cups must capture a ball mid-flight on a deep lane.

The clean-sheet insight is that **all three pains come from trying to keep every ball at one
z-height and route the long (2,9) chord *across* the disc in that plane.** If instead we let
the mechanism use the **third dimension by pair-class** — local pairs swap *in plane* at ball
level, the one long pair swaps on its *own lower deck* — the long chord never has to cross the
ring plane laterally at all, and **no ball ever threads through any part**. Each ball is, at
every instant, either (a) seated, (b) riding the top of a 2-cell rotor that turns under it, or
(c) sitting in a cup on the (2,9) under-deck rotor. A ball is never speared by a rail.

---

## 1. The fixed target permutation

```
Swap = (0 1)(2 9)(3 4)(5 6)(7 8)(10 11)        on POSITION indices
```

| Pair    | Type                     | Mechanism class                  |
|---------|--------------------------|----------------------------------|
| (0 1)   | apex ↔ top-ring          | **apex rotor** at ball level (the trigger) |
| (3 4)   | adjacent ring neighbors  | **rim rotor** at ball level      |
| (5 6)   | adjacent ring neighbors  | **rim rotor** at ball level      |
| (7 8)   | adjacent ring neighbors  | **rim rotor** at ball level      |
| (10 11) | adjacent ring neighbors  | **rim rotor** at ball level      |
| (2 9)   | cross-ring (≈ diametral)  | **under-deck rotor** below ball level (the one excursion off-plane) |

§3 of the original `DESIGN.md` proves the 4 neighbor rotors + apex rotor are **mutually clear**
in plane (every pairwise bounding circle is clear by ≥ +23.6 mm). We adopt that result verbatim
and only have to solve the (2,9) chord — which we solve by dropping it to its own deck.

---

## 2. Authoritative geometry (reused, not re-derived)

Unit circle, +x right, **+y DOWN**. Ring slots `i = 1..11` at `a_i = -90° + (i-1)·(360/11)°`.
Ball diameter **18 mm** (`rb = 9`), pitch-circle radius **R = 50 mm**.

> **CORRECTED apex geometry (vs the series numbers):** the series put slot 0 at radius
> 1.25·R = 62.5 → a 12.50 mm chord. But a 2-cell apex rotor of chord 12.50 mm holds its two
> balls only 12.5 mm apart — **less than a ball diameter (18 mm)** — so the two apex balls
> would physically overlap. The clean-sheet design pushes slot 0 out to radius **R + 24 = 74**
> so the (0,1) chord (= the flick stroke) is **24 mm > 18 mm**, and the two apex balls stay
> 24 mm apart (6 mm clearance) throughout the half-turn. The "0-flick" is therefore a **24 mm
> plunge/arc**, still a clean palm-scale flick. (`check_clean.py` enforces this; with the old
> 12.5 mm the ball-vs-ball check FAILs by 5.5 mm.)

| slot | (x,y) mm        | slot | (x,y) mm        |
|------|-----------------|------|-----------------|
| 0    | (  0.0, −74.0)  | 6    | (+14.1, +48.0)  |
| 1    | (  0.0, −50.0)  | 7    | (−14.1, +48.0)  |
| 2    | (+27.0, −42.1)  | 8    | (−37.8, +32.7)  |
| 3    | (+45.5, −20.8)  | 9    | (−49.5, + 7.1)  |
| 4    | (+49.5, + 7.1)  | 10   | (−45.5, −20.8)  |
| 5    | (+37.8, +32.7)  | 11   | (−27.0, −42.1)  |

| Pair    | chord (mm) | rotor r (mm) | midpoint (mm)   |
|---------|-----------:|-------------:|-----------------|
| (0 1)   | 24.00      | 12.00        | (  0.0, −62.0)  |
| (3 4)   | 28.17      | 14.09        | (+47.5,  −6.8)  |
| (5 6)   | 28.17      | 14.09        | (+25.9, +40.4)  |
| (7 8)   | 28.17      | 14.09        | (−25.9, +40.4)  |
| (10 11) | 28.17      | 14.09        | (−36.3, −31.4)  |
| (2 9)   | 90.96      | 45.48        | (−11.2, −17.5)  |

**Ring spin** indexes by 360/11 = **32.727°**. (Slot-0 at radius 74 is well outside the
R = 50 ring, so the apex token never interferes with the spinning ring.)

---

## 3. Layer stack & z-budget (bottom → top)

All z measured from the ring-plane ball **bottom = 0**, so ball **centre = eq = 9**, ball
**top = 18**. The "world z" used in `check_clean.py` matches this.

```
 z = +21   top window plate top         ─┐
 z = +18   ball top                       │ clear window plate: oval apertures,
 z = +16   window retaining lip (< rb)    │ retaining lips, fingertip access
 z = +9    BALL CENTRE (eq) ──────────────┼─ ring plane: spin carousel holds the 11 balls
 z =  0    ball bottom / carousel floor  ─┘
 z = -2    rim/apex rotor hub top         ─┐ in-plane rotor gear hubs sit BELOW the balls.
 z = -7    DRIVE GEAR DECK + retracted     │ During a SWAP the 5 rotor cups RISE to z=+9 to
            in-plane cups (spin regime)     │ carry balls; during SPIN they RETRACT to z=-7
                                            │ (mode switch) so a spinning ball at z=9 clears.
 z = -11.5 (2,9) bar top                   ─┤ the (2,9) carrier — a 2-cell bar, r = 45.48,
 z = -16   (2,9) rotor cup/bar centre       │  living ENTIRELY below the ring plane. The bar
 z = -24   (2,9) rotor floor / base disc   ─┘  passes ~3 mm under the in-plane hubs; sweeps a
                                               clear sub-plane; touches nothing above.
```

Total stack height ≈ 45 mm (z −24 … +21) — palm-sized at Dp ≈ 100. The (2,9) deck is the only
part below the gear train. Its bar top (−11.5) clears the in-plane rotor-hub bottoms (−8.5) by
3 mm (verified by `check_clean.py` part-vs-part), and its 90.96 mm sweep is otherwise free air.

---

## 4. How SPIN works (near-frictionless, 11 detents)

- The 11 ring balls sit in a **spin carousel** — a thin ring (the "ring plane" floor) with 11
  oval ball pockets at R = 50. The apex ball 0 is **not** on the carousel; it sits in its own
  straight slide from slot 0 to slot 1 (so spin is order-11 on the ring, apex fixed — matching
  the engine).
- The carousel rides on a **central ball bearing** (608ZZ, 8×22×7) on the base boss → low
  friction. A fingertip on any exposed ball spins the whole ring.
- **Detents:** an **11-tooth star profile** on the carousel underside engages a single
  **sprung ball detent** (Ø4 ball + light compression spring) in the base. One clean *click*
  every 32.727°. This is the only sprung detent in the toy; it defines ring registration.
- **Mode interlock (retract-during-spin):** spin is only free when the 5 in-plane rotors are
  **retracted** below the ball plane. A **mode-switch sleeve** (lift/twist) raises the 5 rotor
  cups from the gear deck (z = −7) up to ball level (z = +9) for a swap, and drops them back for
  spin. When retracted, the highest carrying surface is the cup rim at z ≈ −3.8 and the bar at
  z ≈ −3, both ≥ 3 mm below a ball whose bottom is z = 0 → a ring ball spins freely over them
  (verified: the SPIN sweep clears every resting part by ≥ 3 mm). The rotor gear *hubs* stay at
  z = −2…−8.5 always. This time-multiplexing (never swap + spin at once) is what makes the SPIN
  sweep pass the checker.

**Why this beats the series ring-gear:** there is no central ring gear threading the plane;
the only central part is a bearing. Nothing the balls pass over during spin is taller than
z = −2, and balls live at z = 9.

---

## 5. How the 0-FLICK drives all six swaps

The IDEAL input (per brief) is **flicking ball 0 toward 1** — a 24 mm plunge/arc (the apex
chord, §2). We keep that as the primary trigger. The flick is converted to **180° of rotation**
shared by every rotor:

```
 0-flick  (push ball 0 along the apex-rotor arc toward slot 1, ~24 mm)
     │  ball 0 rides the APEX ROTOR (2-cell, r=12, on the sun-pinion shaft)
     ▼
 SUN PINION / APEX CRANK   (turns 180° as ball 0 sweeps 0→1)        at the apex pivot
     │  1:1 idler train (all gears same pitch Ø → every output turns exactly 180°)
     ├──► apex rotor   (0 1)     in-plane, ball level   (= the input crank itself)
     ├──► rim rotor    (3 4)     in-plane, ball level
     ├──► rim rotor    (5 6)     in-plane, ball level
     ├──► rim rotor    (7 8)     in-plane, ball level
     ├──► rim rotor    (10 11)   in-plane, ball level
     └──► (2,9) under-deck rotor          below ball level
```

- **Apex rotor = the input crank.** Ball 0 sits in a cup at one end of the apex 2-cell rotor
  (chord 24 mm, r = 12, pivoting at (0,−62) on the sun-pinion shaft). Flicking ball 0 toward
  slot 1 turns the apex rotor 180°: ball 0 sweeps to slot 1 and ball 1 sweeps to slot 0 on the
  **opposite semicircle** (they stay 24 mm apart — never collide). The apex rotor is **rigid on
  the sun-pinion shaft**, so that same 180° drives the 1:1 idler train and hence all four rim
  rotors and the (2,9) under-deck rotor. **One flick = all six swaps.** No rack needed — the
  apex rotor *is* the crank (a rack+slide is documented in §9 as an optional fallback that gives
  a purely-linear 24 mm plunge instead of a 24 mm arc).
- **1:1 everywhere.** Every rotor must turn exactly 180°, so every gear in the train shares one
  pitch diameter; ratio is 1:1 through idlers. Idler count per branch is chosen so the rotor
  spins the *correct sense* (CW vs CCW doesn't matter for a 180° swap — either way the two cups
  trade places — so idler parity is free; we use the count that places idlers in clear gaps).
- **Reset:** push ball 0 back up (24 mm, reversing the apex arc) → the whole train runs backward
  → all tokens re-park.
  A light **return spring** on the slide biases to the up/locked rest state and removes backlash
  (anti-backlash preload).
- **End detents:** a ramp on the slide drops into a notch at full-up (rest) and full-down
  (swapped), giving tactile end-stops and preventing the toy resting mid-swap (which would leave
  a rotor cup half-across the ring and block spin).

### Why the 0-flick is feasible here (no fallback needed)
The series effort worried the 0-flick couldn't drive a central ring gear without congestion.
The clean-sheet design has **no ring gear at all** — the only central part is a spin bearing —
and the apex rotor *is* the input crank, sitting **outside** the R = 50 ring at radius 74, the
least congested spot on the whole toy. The flick force goes straight into the sun-pinion shaft
with nothing crowding it. So the 0-flick is the sole input. (Fallback in §9 if wanted: a rack
on a linear apex slide for a straight-line plunge, or a thumbwheel — same downstream train.)

---

## 6. How each of the six pairs physically exchanges

### 6a. The four rim rotors (3 4)(5 6)(7 8)(10 11) and the apex (0 1)
Each is a **2-cell rotor**: a rigid bar of length = chord, with an **open-topped cup** (a
C-shaped cradle) at each end, pivoting about the pair midpoint. The cup cradles the ball's lower
hemisphere from below and sides, open at top (window plate retains the ball from above). A 180°
turn carries each ball to the other end → the pair is swapped. Balls are **always diametrically
opposite on the bar (separation = chord)**, so the two members of a pair **never collide** —
provided the chord exceeds a ball diameter. The four rim chords are 28.17 mm ≫ 18 mm; the apex
chord was widened to **24 mm** (> 18) for exactly this reason (§2). So the swap is collision-free
*by construction*, for every pair, at every angle. This is the key simplification: a 2-cell
rotor with chord > ball-Ø cannot self-collide.

**Rest geometry (so SPIN passes):** at rest each rotor parks with its bar along the **ring
tangent** at the pair, both cups coincident with the two carousel pockets, cup gaps facing
outward. The bar's swept disc at rotor radius 14.09 (rim) sits centred on the pair midpoint; §3
proves these five discs are mutually clear and clear of all non-pair parked balls. During a
swap the disc is swept, but only the pair's own two balls ride it; §3's table shows the only
disc that would hit a parked ball is the (2,9) one — which we removed from this plane.

### 6b. The (2,9) pair — the one off-plane excursion
A **single 2-cell under-deck rotor**: a bar of length 90.96 mm, cups at each end, pivoting about
(−11.2, −17.5) at deck z = −16, **entirely below the ring plane**. Sequence in one flick (u = 0→1):

1. **u ∈ [0, 0.12] — drop.** Balls 2 and 9 descend straight down their plate **wells** (vertical
   holes at slots 2 and 9) from z = 9 to z = −16 into the rotor's two cups. Pure axial motion,
   guided by the well walls — *no rail threads the ball*; it falls into a cradle.
2. **u ∈ [0.12, 0.88] — sweep.** The rotor turns 180°. Balls 2 and 9 (diametrically opposite,
   91 mm apart) trade ends in free air at z = −16, a clear 25 mm below the ring plane. The
   sweep disc (r = 45.48) lives in the sub-plane; the only things at that z are the rotor and
   base disc, so nothing is threaded and parked balls 1/10/11 (at z = 9) are far above.
3. **u ∈ [0.88, 1] — rise.** The rotor's cups, now under wells 9 and 2 (swapped), lift balls
   back up to z = 9 into the carousel pockets. Axial again.

Because the two (2,9) balls are always 91 mm apart on the rigid bar, **they never pass through
each other** — the prior over/under two-lane bridge is unnecessary. The drop/rise are short
axial moves inside wells (no threading), and the sweep is in a private sub-plane (no plane
sharing). This is the whole reason the clean-sheet checker passes with large margins.

**Drive of the (2,9) rotor:** the sun-pinion train has one branch that turns a vertical idler
shaft down to the under-deck and spins the (2,9) bar 180°. The drop/rise are produced by a
**barrel cam** on that same shaft: a 23 mm-lift cam profile, lift in [0,0.12], dwell (sweep) in
[0.12,0.88], lower in [0.88,1] — so the same flick that turns the bar also raises/lowers the two
balls in step. (Modeled in the checker as the z(u) schedule of balls 2 and 9 and of the rotor
cups.)

---

## 7. The cover ("hides the magic", retains balls, allows spin + flick)

A **clear window plate** (transparent PETG or clear resin) caps the stack at z = 16…20:

- **12 oval apertures** over the 12 slots; each aperture is **smaller than the ball Ø** at its
  lip (lip ID ≈ 14 mm < 18 mm) so a ball is **retained axially** but its number reads through.
- The apex slot 0 aperture is a **slot** (elongated 12.5 mm along 0→1) so ball 0 can plunge —
  the fingertip flicks ball 0 through this slotted opening.
- The window is **recessed around the ring** so a fingertip can reach the ring balls and spin
  them (the lip retains axially but the ball crown protrudes ~2 mm for grip).
- Below the window, the mechanism (rotors, gear deck, under-deck rotor) is **hidden** by an
  opaque mid-shell skirt at the rim — you see 12 numbers on a clean ring, the magic is concealed.
- The window + base disc form a **two-shell sandwich** (Back-Spin manufacturing borrow): load
  balls, close the two shells, everything is captive.

---

## 8. Key dimensions (Dp = 100)

| Quantity | Value |
|---|---|
| Pitch radius R | 50 mm |
| Ball Ø | 18 mm (rb = 9) |
| Apex stroke / chord (0→1) | 24.0 mm (> ball Ø, see §2) |
| Apex slot radius | 74 mm |
| Apex rotor radius | 12.0 mm |
| Sun pinion / apex crank pitch Ø | ~14 mm (module 1.0, ~14 teeth; see FORCES) |
| Rim rotor radius | 14.09 mm |
| (2,9) rotor radius | 45.48 mm |
| Ball-level z (centre) | +9 mm |
| Gear-deck z (and retracted cups) | −7 mm |
| (2,9) deck z (cup/bar centre) | −16 mm |
| Window lip ID | 14 mm (< 18 retains) |
| Stack height | ≈ 45 mm (−24 … +21) |
| Ring-region outer Ø | ≈ 152 mm (incl. apex token at r=74) |

---

## 9. Decisions & rejected alternatives

- **REJECTED: keep all balls at one z, route (2,9) across the plane** (the series approach).
  Causes rail-threading + deep-lane congestion + over/under two-lane bridge. Replaced by a
  single rigid 2-cell under-deck rotor — simpler and self-non-colliding.
- **REJECTED: over/under two-lane (2,9) bridge** (original Concept C). Unnecessary: a rigid
  2-cell bar keeps the two balls 91 mm apart, so they never need separate lanes to avoid each
  other. One bar, one deck.
- **REJECTED: 6 coplanar rotors in one plane** (Concept A). The (2,9) disc eats slots 1/10/11.
  Solved by moving that one rotor to its own deck (the only off-plane part).
- **REJECTED: thumbwheel / button as primary input.** The 0-flick is feasible here (§5) because
  the apex rotor is the crank and sits outside the ring with nothing crowding it; kept as
  primary. Fallbacks (rack-on-linear-slide for a straight plunge; thumbwheel) drive the *same*
  downstream train and are documented only in case a printed apex crank feels awkward.
- **CORRECTED: apex chord 12.5 → 24 mm.** The series 12.5 mm chord is smaller than a ball, so a
  2-cell apex rotor would jam its two balls. Pushed slot 0 out to r = 74 → 24 mm chord. The
  checker FAILs ball-vs-ball by 5.5 mm at the old value and PASSes at the new one.
- **ADOPTED from Back-Spin:** two-shell sandwich, clear window with retaining lips, race-track
  (oval) ball pockets, seat-as-detent feel. (Cited in the series DESIGN.md §4.5.)
- **CHOSEN material:** **PETG** for structural parts (tougher than PLA, less brittle than most
  resin for snap/print-in-place gears), **clear PETG or clear tough resin** for the window. See
  FORCES.md.

---

## 10. The interference proof (the gate)

`check_clean.py` samples **72 swap frames** (u = 0 … 1) and a **132-step spin sweep**, modeling
balls as spheres and all parts as primitives (cyl / box / ring / **capsule** / **part-vs-part**).
It reports worst-case penetration per clashing pair and the frame. The design is *clear by
construction* because:

- the 5 in-plane rotors are mutually clear (§3) and self-non-colliding (2-cell bars);
- the (2,9) rotor is on its own deck 23 mm below everything else and is self-non-colliding;
- balls drop/rise axially in wells (no rail threads a ball);
- at rest, all rotor hubs sit ≥ 11 mm below the ball equator → the spin sweep is clear.

See `check_clean.py` output (and FORCES.md for the load path).
