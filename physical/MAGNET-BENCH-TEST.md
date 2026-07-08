# Magnet bench test — the one measurement that gates the 2/9 shuttle

## Why this exists

The whole magnet-shuttle path rests on one number that is **computed nowhere** in the codebase:
the **lateral (shear) force needed to drag a steel ball sideways off the face of the magnet**,
through a thin plastic wall, at the working standoff.

`check_29_mag.py` models only the **axial** pull (straight off the pole face). But in the toy the
divider blade sweeps the ball **sideways** across the magnet, and the tunnel/cart geometry relies
on:

1. the magnet holding the ball **hard enough** that the cart carries it in and out without the
   ball slipping off (grip ≳ a few × ball weight, laterally), **and**
2. the blade being able to **shear the ball off** the magnet at the center with a hand-scale force
   (so the swap doesn't need gorilla effort or rip the magnet out of its pocket).

Those two pull in opposite directions, and the window between them is the whole ballgame. The
axial number (8× ball weight at 0.8 mm) does **not** tell us the lateral number — for a sphere on
a disc magnet the lateral break-away is typically 20–40 % of the axial, but that ratio is an
**assumption**, and it swings the design. Ten minutes on a kitchen scale replaces the guess with a
curve.

## What you're measuring (three curves)

For the candidate magnet (**Ø14 × 4 mm N42 disc**, axis = the 4 mm thickness) against a
**Ø20 chrome-steel ball** (52100 or 440C — whatever the toy will use), through a **printed PETG
wall**, measure:

- **A — axial pull-off vs. wall thickness.** Straight-away force to detach the ball, at wall
  thicknesses **0.8 / 1.2 / 1.6 / 2.0 mm**. (This validates `check_29_mag.py` against reality and
  anchors the other two.)
- **B — lateral shear vs. wall thickness.** Sideways force to slide the ball off the pole edge, at
  the same four thicknesses. **This is the gating number.**
- **C — "does it hold through a carry" sanity.** With the ball on the 0.8 mm wall, how many g can
  you swing/jerk the assembly before the ball flies off (a proxy for the cart accelerating the
  ball along the tunnel). Qualitative is fine; A and B are the real data.

You need each curve because the design has two free choices — **wall thickness** (grip vs.
printability: 0.8 mm is two 0.4 perimeters, the practical floor) and **whether one magnet can do
both jobs** — and the A/B ratio decides them.

## Shopping list (all cheap, all COTS)

| item | spec | notes |
|---|---|---|
| Magnet | Ø14 × 4 mm N42 disc, axially magnetized | buy 3–4; they chip. K&J part `DC2` or any N42 Ø14×4. |
| Steel ball | Ø20 chrome steel (G100 or better) | the toy's actual ball; buy 2. |
| Kitchen/pocket scale | 0–5 kg, 1 g resolution, **tare button** | the whole instrument. A luggage/fish hanging scale (0–5 kg, hook) is even better for the pull tests — you pull *up* against gravity and read directly. |
| Fine cord / braided fishing line | ~20 lb, non-stretch | ties the ball to the scale. |
| Printed jig | the fixture below (PETG) | prints in ~1 h, ≈ 15 g. |
| Feeler-gauge shims or calipers | to confirm wall thickness | optional; the jig sets thickness by design. |
| Small G-clamp or bench vise | to anchor the jig | so you pull the ball, not the jig. |

**Safety:** N42 discs snap together hard enough to blood-blister a finger and shatter (they're
brittle, plated). Keep them apart, away from cards/drives/phones, and wear eye protection when two
can slam together.

---

## The printed jig (I'll generate the STL — this section is what it *is* and how to use it)

The jig's whole job is to (1) hold the magnet at a **known, repeatable wall thickness** under the
ball, (2) constrain the ball so it can only move in the **one direction you're measuring**, and
(3) give the scale a clean line of pull. One printed part per test mode, or one part with
swappable inserts.

### Part 1 — the magnet well block (shared by all tests)

A rectangular PETG block, **40 × 40 × 12 mm**, with:

- A **blind cylindrical pocket** on top, Ø14.3 (0.15/side slip fit) × 4.2 deep, to drop the magnet
  in flush.
- The **floor of that pocket is the "wall"** between magnet and ball. To test multiple
  thicknesses without reprinting the whole block, the floor is a **removable shim disc**: the
  pocket is actually cut *through* (Ø14.3 all the way), and a **stack of Ø18 shim discs**
  (0.8 / 1.2 / 1.6 / 2.0 mm, printed flat = best top-surface finish) drops onto a Ø18 ledge above
  the magnet. Magnet sits under the shim; ball sits on the shim. Swap the shim, keep everything
  else identical.
  - *Print the shims solid, 100 % infill, flat on the bed*, so the wall is a true solid slab (a
    sparse-infill wall would give a garbage, non-repeatable air-gap). Label each shim's thickness
    with an embossed digit.
- Four **M3 clearance holes** (or two slots) so you can **clamp/bolt the block to the bench** — you
  must anchor the block and pull the ball, never the reverse.
- A shallow **spherical dimple** (radius 10.2) centered over the magnet on the shim's *top* — no,
  **do not dimple the shim**: the ball must sit on a flat so the magnet's grip, not a geometric
  pocket, is what holds it. The lateral rig (below) provides the sideways constraint instead.

### Part 2a — axial pull-off cap (Test A)

A tiny **ball yoke**: a 3-fingered printed cap that cups the top hemisphere of the Ø20 ball
loosely (inner radius 10.3, three 120°-spaced fingers reaching to the equator) with a **cord loop
eyelet** at the top pole. You seat the ball on the shim (magnet grabs it), drop the yoke over it,
thread the cord up to the hanging scale, and **pull straight up, slowly**, watching the peak
reading. The number at the instant the ball breaks free = axial pull-off for that shim. Repeat 3×
per shim, average.

- *Alignment matters:* pull must be **perpendicular to the shim**. Print a **tall guide collar**
  (Ø22 bore, 25 mm tall) standing off the block around the ball so the yoke/cord can only travel
  vertically. Without it you'll accidentally add a lateral component and read low.

### Part 2b — lateral shear sled (Test B — the important one)

The ball must move **only horizontally, tangent to the shim surface, at constant height**, while
you pull it sideways off the pole. Geometry:

- A **captive channel** on the block: two parallel walls 20.4 mm apart (0.2/side) and 12 mm tall,
  running across the top of the block through the magnet center, so the ball is boxed left/right
  and can only roll/slide **along** the channel (the pull axis). The channel floor over the magnet
  is the shim; on either side of the magnet the floor rises to meet the ball's equator height so
  the ball transitions onto a plain PETG runway when it leaves the pole (mimicking the ball
  sliding off the magnet onto the tunnel floor).
- The ball starts centered over the magnet. Tie the cord around the ball (a light dab of
  cyanoacrylate to a tiny printed **belt clip** that snaps on the ball's "equator" keeps the cord
  from slipping — or use a second small yoke with a **horizontal** eyelet). Pull **horizontally**,
  in line with the channel, through the scale.
- **Read the peak** as the ball breaks over the pole edge and accelerates down the runway. That
  peak = lateral shear force for that shim.
- The scale should be pulled **through a low-friction guide** (a printed post with a rounded
  Ø6 top the cord rides over, turning your vertical hand-pull into horizontal cord tension) *or*
  just lay the whole rig flat and pull the scale horizontally across the bench. Keep the cord
  parallel to the channel to ±5°.

### Part 2c — jerk test (Test C — qualitative)

Seat the ball on the 0.8 mm shim (magnet gripping). Hold the block and **accelerate it along the
channel direction** by hand, increasing snap until the ball flies off. You're feeling for "does a
brisk carry keep the ball, or does a normal wrist-flick shed it." If it holds a hard flick, the
carry is fine. (If you have the hanging scale + a known swing, you can estimate g, but eyeballing
pass/fail is enough at this stage.)

---

## Procedure (the actual ten minutes)

1. Clamp the well block to the bench. Drop the Ø14×4 magnet into the pocket.
2. **Test A:** insert the 0.8 shim, seat the ball (feel it grab), fit the axial yoke + guide
   collar, hang/pull straight up through the scale, tare-then-pull slowly, record the **peak g at
   release**. Do 3 pulls; average. Repeat for 1.2, 1.6, 2.0 shims.
3. **Test B:** swap to the lateral sled top (or the lateral insert), 0.8 shim, ball centered,
   horizontal pull through the guide, record **peak g at break-over**. 3× each shim.
4. **Test C:** 0.8 shim, flick-test, note pass/fail and rough effort.
5. Write the numbers into the table below and hand them back to me.

## Data to send back

| shim (mm) | A: axial pull-off (g) | B: lateral shear (g) | B/A ratio |
|---|---|---|---|
| 0.8 |  |  |  |
| 1.2 |  |  |  |
| 1.6 |  |  |  |
| 2.0 |  |  |  |

Plus: **Test C** at 0.8 mm — held a hard flick? (y/n) and rough feel.

Convert g → newtons if you like (×0.00981), or just send grams; a solid Ø20 chrome ball weighs
**≈ 32.7 g** (0.32 N), so I can read everything as multiples of ball weight directly.

## What each outcome means (so you know what you're proving)

- **Grip (B at 0.8 mm) ≥ ~5× ball weight (~165 g):** the cart will carry the ball reliably; the
  frame-mounted-magnet shuttle is a go.
- **Shear (B at 0.8 mm) ≤ what a finger can overcome through the blade at r≈16–25 (~a few N,
  i.e. a few hundred g):** the divider sweeps the ball off without heroic force or unseating the
  magnet — the center handoff works.
- **B/A ratio:** anchors the model so I can size the magnet, the wall, and the blade sweep force
  in the SCAD without guessing. If B/A is high (~0.4) I have lots of margin; if low (~0.2) I may
  need to go to a **Ø15 or a countersunk pole** or thin the wall to 0.8, and the curve tells me
  exactly which.
- **If grip is too weak even at 0.8 mm:** step up to Ø15×5 N42 or a Ø14×4 N52, re-run A/B for that
  magnet only — the jig is unchanged.
- **If shear is too high (ball won't come off without bending the blade):** either the wall goes
  thicker (weaker grip, easier shear) or the handoff geometry gets a lead-out ramp; again the
  curve says which.

Once I have the table, the shuttle SCAD stops being gated and I model it for real.
