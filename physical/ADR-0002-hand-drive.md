# ADR-0002 — Hand-actuated drive: down-over-back-up handle, divider gear train, magnet 2/9 shuttle

**Status:** Proposed (2026-07-07). Divider gear train modelled + interference-checked
(`clean/proto_geartrain.scad`, `clean/check_geartrain.py`). Handle/rectifier + shuttle are
designed but not yet modelled — gated on a magnet bench test (see `MAGNET-BENCH-TEST.md`).

**Supersedes nothing.** Builds on the "no gears yet" checkpoint (`clean/` @ Mathieu 9aab10d):
the geometry + choreography are frozen and verified (121-frame sweep, 7 gates); this ADR adds
the mechanism that *drives* that choreography from a human hand.

---

## 1. Context

The toy's reconfiguration is a fixed `u ∈ [0,1]` clip, already proven collision-free:

| phase | u | motion |
|---|---|---|
| **down** | 0.00–0.20 | 21 mm elevator lifts both spin rings + all swap rings + apex ring |
| (down tail) | 0.20–0.35 | balls 2 & 9 travel their test-tubes inward to the central ring (r 16.71) |
| **over** | 0.35–0.50 | first half of the divider π |
| **back** | 0.50–0.65 | second half of the divider π (balls now swapped) |
| (up tail) | 0.65–0.80 | balls 2 & 9 travel back out to their swapped stations |
| **up** | 0.80–1.00 | elevator drops; everything returns to rest |

The user's chosen input is an **exterior handle with a down-over-back-up gate**, force applied
on down/over/back, spring-returned on up. The drive must map handle motion → `u(t)` and be:

- **gravity-independent** (works upside down / on edge): no gravity returns for load-bearing
  parts; a handle return spring is fine.
- **FDM-printable** (PETG, 0.4 nozzle, walls ≥ 1.2, no support-heavy geometry), low part count,
  COTS only (steel balls, N42 magnets, music-wire springs, Ø3 pins).
- **state-safe**: no misuse (mid-stroke reversal, early release, force-feeding the wrong order)
  may scramble the puzzle or jam.

This ADR records the design chosen after a 5-design / 3-adversarial-judge exploration
(workflow `wf_a756f0c2`), and what remains gated.

---

## 2. Decision

Three subsystems, decided independently, integrate through one input shaft.

### 2.1 Handle + gate + rectifier — **rotate-then-plunge shaft with a slider-crank rectifier**

One input shaft **S** (Ø12, tangential, at azimuth −90° — a verified feature gap) with exactly
**two DOF**: rotate 60° (**down/up**) then slide 26 mm (**over/back**). Not a gimbal — a shifter,
so all gearing stays meshed.

- **Stroke order is enforced mechanically, not procedurally:** a **bayonet L-groove** cut in S
  rides a fixed Ø3 pin — axial slide is geometrically impossible until S is fully rotated (down
  before over), and S cannot rotate while displaced axially (up is locked out through the whole
  over/back excursion). An exterior L-slot duplicates the gate. Wrong-order input is *impossible*,
  not merely discouraged.
- **DOWN → frame + shuttle:** S-rotation drives a **captive barrel cam** (positive both ways →
  the frame is *pushed* down on UP even inverted). One cam face lifts the frame 21 mm over the
  first 57 % of the throw (u 0→0.20); a second cam face runs the 2/9 shuttles in over the
  remaining throw (u 0.20→0.35). Sequencing is a *geometric property of one printed cam*, not a
  latch.
- **OVER/BACK → continuous π (the elegant part):** S's 26 mm axial slide is the slider of a
  **slider-crank**. The handle's reversal at the gate corner lands *exactly on the crank's dead
  center*, so the divider train continues the same rotational sense with **no ratchet, pawl, or
  clutch**, and — because dead-centers are backlash-immune — the π lands exactly. This is the
  single best idea from the exploration; all three judges singled it out.
- **UP → restoration:** a compression spring (frame + walls ≈ 150–250 g PETG × 21 mm + friction,
  ≈ 5 N) drives the up stroke; the barrel cam's dwell/rise profile forces order (shuttles out,
  then frame down).

*Open sub-items:* the 3:1 crown/face gear the doc used prints poorly (FDM line-contact teeth) and
the flexure pawl / over-center kicker are fatigue-prone — **re-package to shed all three** before
committing (a plain spur reduction + the slider-crank's own dead-center is enough).

### 2.2 Divider gear train — **in-plane sun + 4 idlers + 4 pinions, 1:1, same-sense** *(MODELLED)*

One rotary input at the **sun** (origin) turns all five in-plane blades exactly π, same sense:

```
sun 21T (CW) → idler 25T (CCW) → pinion 21T (CW = sun)     ω_pinion/ω_sun = (21/25)(25/21) = 1
```

- Module 1.2, 20° PA. Sun 21T at origin; four idlers 25T at radius **27.60** on each pair ray
  (azimuths 8.18°, −57.27°, −122.73°, 139.09°); four pinions 21T under the blades at the true pair
  centers (radius 55.224). Center distances 27.60 exact; sun→pinion 55.20 vs 55.224 = **0.024 mm**,
  absorbed by nominal backlash.
- The idler restores the sense (a bare sun would reverse its planets); **equal sun/pinion teeth
  make the ratio exactly 1**, so one input π = π at every blade with no per-branch tuning. The
  idler count (25) is free — it only sets the idler's radius, never the ratio.
- The idlers sit at radius 27.60 ≈ the central-ring wall (28.11), so the ring's under-deck boss
  ring is the natural idler-post mount — one feature serves ring and pivots.
- **Elevation** (blades ride the 21 mm elevator, gears axially fixed): **sliding square shafts** —
  each pinion has a 5 mm square through-bore; each blade carries a square shaft that slides in it,
  torque through the flats, free vertical travel. Chosen over engage-at-altitude (five
  simultaneous lead-ins = jam risk) and whole-layer-on-elevator (double mass).
- **Location:** basement, gear layer Z −33..−27 (below the pan at −24). The pan needs **4 shaft
  bores** at the pair centers.

**Verified** by `check_geartrain.py`: all non-adjacent gear pairs clear (only the 8 intended
meshes touch); the gear layer clears the pan + parked mechanism + balls + lid by Z-separation;
the 4 square shafts thread cleanly between the two spin-ring walls (46.16 / 68.96) at r=55.224.

*Not modelled:* the **apex branch** (the apex blade turns about a horizontal axis and also rides
the elevator — a bevel/crown branch off the sun). The exploration's apex routing was unfinished
and mis-modeled the spare-tire bulge cavity; it needs a from-scratch design and is deferred.

### 2.3 2/9 shuttle — **positive rack radial drive + magnet on the elevator frame + fixed center cage**

A hybrid of the two best shuttle variants:

- **Radial travel by rack-and-pinion** (from rack variant): positive-drive, so it **fails to a
  known state** — a resisted ball is left behind and recovered next cycle, never mis-positioned
  (a belt or bare magnet silently loses position). Travel 40.85 mm (r 57.56 → 16.71).
  *Fix required:* the rack agent's z=20 m1 pinion (pitch r 10.0) placed at tunnel half-width
  y=10.1 fouls the ball corridor 10 mm — offset the pinion outboard by its radius.
- **Grip/release by a magnet on the elevator frame** (from floor-strip variant — the keystone):
  a Ø14×4 N42 disc under each ball. At full-up (0.8 mm standoff) it holds ≈ 8× ball weight; at
  full park (21 mm away) it falls to 0.8 % of ball weight — **below any spin-detent threshold**.
  So the 21 mm park-drop *is* the release and the rise *is* the grip — both engage/release timing
  and the detent-lesson compliance fall out of motion the frame already makes. (These two axial
  numbers reproduce `check_29_mag.py`.)
- **Fixed center cage** (mandatory — closes the one true gravity-dependence all three judges
  found): as the divider shears a ball off magnet A across the ~38 mm center arc to magnet B, a
  fixed captive ceiling/rib over the center floor disc (r ≈ 26.5, on posts threading the 1.42 mm
  slot between blade sweep 25.69 and ring wall 27.11) traps the ball on all sides so it cannot
  slide off the disc in the on-edge orientation.

---

## 3. The gate before commit — a bench measurement

The shuttle's load-bearing number — the **lateral/shear force to drag a ball off the magnet** —
is computed *nowhere* (`check_29_mag.py` models only axial pull). Every shuttle variant quoted a
0.2–0.4× lateral/axial ratio as an *assumption*. Before any shuttle SCAD is committed, this must
be measured on a real Ø14×4 N42. The jig is specified in `MAGNET-BENCH-TEST.md`.

Two secondary gates: (a) offset the rack pinion outboard of the ball corridor; (b) guarantee full
elevator park (positive spring) so an early release never rests the magnet at the ~11 %-weight
half-park detent.

---

## 4. Consequences

- **Body grows a ~22 mm basement** (Z −24 → −46) for the cam pack + gear train. This is the price
  of hand actuation; the mechanism roughly doubles in part count.
- **No exotic parts:** printed gears/cams, N42 discs, music-wire springs, Ø3 pins, steel balls.
- **State integrity** is structural: the bayonet gate makes wrong-order input impossible, the
  slider-crank makes the over→back reversal continue the divider sense, and rack + frame-magnet
  make the shuttle fail-to-known-state. The residual risks are the center-cage (fix specified)
  and the unmeasured lateral magnet force (bench test specified).

## 5. Alternatives rejected

- **Belt/cable shuttle** — capstan slip + no outer end-stop to re-datum a short return = silent
  lost-position. Rejected by all three judges.
- **Ratchet/pawl rectifier** — quantizes the divider to the ratchet pitch (±7.5°); the blades need
  an exact π to re-register with tunnels/stations. Rejected as primary drive.
- **Alternating double-rack rectifier** — every over→back handoff is a tooth-on-tooth crash under
  FDM tolerance. Rejected for the slider-crank.
- **Magnet as the throat seal / detent** — a magnet parked under a resting ball pins the spin.
  The frame-mounted magnet (parked 21 mm away at rest) avoids this entirely.
