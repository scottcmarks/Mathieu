# Sporadic M12 — Physical Swap Toy: Design Package

A palm-sized, hand-actuated mechanical toy that physically realizes **one swap move** of the
*Sporadic M12* digital puzzle. A single user action — the **0→1 pull** (sliding the apex token
down toward the top of the ring) — simultaneously exchanges the two tokens in each of six
position-pairs.

> Status: design study + parametric starter geometry. Not yet a finished printable model.
> No git commit — left for human review.

---

## 1. The fixed target permutation

```
Swap = (0 1)(2 9)(3 4)(5 6)(7 8)(10 11)      on POSITION indices
```

(Engine swap-table index 21 / app picker #22 — the unique one of 341 swaps with 5
ring-neighbor swaps + 1 cross-ring chord.)

| Pair    | Type                        | Role |
|---------|-----------------------------|------|
| (0 1)   | APEX ↔ top-ring             | **User trigger** ("0→1 pull") |
| (3 4)   | adjacent ring neighbors     | short rim chord |
| (5 6)   | adjacent ring neighbors     | short rim chord |
| (7 8)   | adjacent ring neighbors     | short rim chord |
| (10 11) | adjacent ring neighbors     | short rim chord |
| (2 9)   | cross-ring (≈ diametral)    | the single long chord |

This particular swap is attractive for a near-planar toy precisely because **5 of the 6 pairs
are local** (apex pull + four rim-hugging neighbor pairs). Only the (2,9) chord crosses the
disc, so only **one** mechanism has to traverse the interior — all the routing-congestion
problems collapse onto that single element.

---

## 2. Exact geometry (computed, not re-derived)

Unit circle, +x right, **+y DOWN** (screen convention). Ring slots `i = 1..11` at
`a_i = -90° + (i-1)·(360/11)°`. Apex slot 0 is placed radially outward above slot 1, at unit
radius **1.25** (a design choice — far enough to give the pull a clean 12.5 mm stroke at
Dp=100; adjust via `apex_extra` in the SCAD).

| slot | unit (x,y)        | slot | unit (x,y)        |
|------|-------------------|------|-------------------|
| 0    | (+0.0000,−1.2500) | 6    | (+0.2817,+0.9595) |
| 1    | (+0.0000,−1.0000) | 7    | (−0.2817,+0.9595) |
| 2    | (+0.5406,−0.8413) | 8    | (−0.7557,+0.6549) |
| 3    | (+0.9096,−0.4154) | 9    | (−0.9898,+0.1423) |
| 4    | (+0.9898,+0.1423) | 10   | (−0.9096,−0.4154) |
| 5    | (+0.7557,+0.6549) | 11   | (−0.5406,−0.8413) |

Adjacent ring chord (unit) = `2·sin(π/11) = 0.56347`. Angular pitch = 360/11 = **32.727°**.

### Derived dimensions at **pitch-circle diameter Dp = 100 mm** (ring radius R = 50 mm)

Chord length = (unit distance)·R. Rotor radius = chord/2. Rotor swept circle diameter = chord.

| Pair    | chord (unit) | **chord (mm)** | **rotor r (mm)** | midpoint (mm)   | swept Ø (mm) |
|---------|-------------:|---------------:|-----------------:|-----------------|-------------:|
| (0 1)   | 0.2500       | **12.50**      | 6.25             | (  0.0, −56.2)  | 12.50        |
| (3 4)   | 0.5635       | **28.17**      | 14.09            | ( 47.5,  −6.8)  | 28.17        |
| (5 6)   | 0.5635       | **28.17**      | 14.09            | ( 25.9, +40.4)  | 28.17        |
| (7 8)   | 0.5635       | **28.17**      | 14.09            | (−25.9, +40.4)  | 28.17        |
| (10 11) | 0.5635       | **28.17**      | 14.09            | (−36.3, −31.4)  | 28.17        |
| (2 9)   | 1.8193       | **90.96**      | **45.48**        | (−11.2, −17.5)  | **90.96**    |

The **0→1 pull stroke** = distance(slot0,slot1) = 0.25·R = **12.50 mm**.

> All numbers scale linearly with Dp. At Dp=120 multiply by 1.2; at Dp=80 by 0.8.

---

## 3. Swept-area conflict analysis (the crux)

If each pair were a **rigid diametral carrier** (Concept A) rotating 180° about its midpoint,
each carrier needs a clear swept *disc* of the diameter above. Pairwise bounding-circle overlaps
at Dp=100:

| pair vs pair        | center dist | r-sum  | result          |
|---------------------|------------:|-------:|-----------------|
| (0,1) vs (2,9)      | 40.37       | 51.73  | **OVERLAP −11.4**|
| (0,1) vs (10,11)    | 43.95       | 20.34  | clear +23.6     |
| (2,9) vs (3,4)      | 59.67       | 59.57  | clear +0.1 (grazing) |
| (2,9) vs (7,8)      | 59.67       | 59.57  | clear +0.1 (grazing) |
| (2,9) vs (5,6)      | 68.75       | 59.57  | clear +9.2      |
| (2,9) vs (10,11)    | 28.65       | 59.57  | **OVERLAP −30.9**|
| all 4 neighbor pairs mutually | ≥51.9 | 28.17 | **clear (≥ +23.7)** |

**The four small neighbor rotors never touch each other or each other's tokens** — they live
happily side-by-side around the rim. The entire conflict is the (2,9) rotor.

Worse than bounding circles: the (2,9) rigid bar's swept *disc* (r=45.48 mm, centered at
(−11.2,−17.5)) physically **passes through slots 1, 10, and 11**:

| slot | dist to (2,9) center | inside 45.48 mm disc? |
|------|---------------------:|-----------------------|
| 1    | 34.41               | **YES**               |
| 10   | 34.41               | **YES**               |
| 11   | 29.23               | **YES**               |

So a single rigid diametral bar for (2,9) would sweep straight through the tokens parked at
slots 1, 10, 11 (and crowd the apex rotor). **This is the decisive constraint.** A naive
"6 coplanar rotors" toy is impossible for *this* permutation because of the one long chord.

---

## 4. Concept comparison

### A) Six coplanar 180° swap rotors, one central drive
Each pair = rigid carrier holding both tokens at its ends; 180° rotation swaps them. Elegant
and exactly realizes a transposition. **Verdict: works beautifully for the 5 local pairs,
fails for (2,9)** because (i) its swept disc eats slots 1/10/11 and (ii) it overlaps the apex
rotor. A single planar layer cannot host the long chord.

### B) Tube + shuttle / gravity-marble
Two tokens cannot pass each other inside one straight tube, so a true *exchange* needs either a
loop (two parallel lanes + a 180° turnaround at each end) or a carrier. A 6-way *simultaneous*
gravity swap in one plane is essentially impossible: gravity has one direction, the six pairs
point six different ways, and tokens would have to cross. **Verdict: rejected** for simultaneous
single-plane operation. (A loop-tube *could* swap one pair, but you'd need 6 independent
lane-pairs nested in the disc — far more congested than rotors.)

### C) Recommended hybrid — **"5 rim rotors + 1 arched over/under bridge"**
Keep Concept A for the 5 local pairs (they're conflict-free). Replace the single problematic
(2,9) rigid bar with a **two-token over/under bridge** that lifts the two tokens out of the
ring plane, carries them across on **two separate stacked lanes** (one going 2→9 on an upper
deck, one going 9→2 on a lower deck) so they never collide, then drops them. The bridge is the
*only* part that leaves the single layer, and it does so by going **up**, not sideways — so it
never sweeps slots 1/10/11. This preserves the "essentially one layer" vision: 11 of 12 token
motions are planar; only the diametral pair takes a small vertical excursion.

### D) Backspin-style two-face sandwich (NEW — from prior art, see §4.5)
A two-shell disc holding tokens in slots on **both faces**, with a single empty cell and a
register-and-push transfer between faces. Native move is "rotate + push into the hole," **not**
a one-pull 6-transposition. Analyzed in detail in §4.5. **Verdict: a faithful Backspin clone
does *not* realize our perm-25 swap in one actuation**, but Backspin contributes decisive
ideas for token retention, the clear-window requirement, detents, and the two-shell mold
breakdown. It also suggests a *narrow* role: the two-ended oblong pocket is a clean way to
host the (2,9) cross-chord without a swept disc.

**Recommendation: Concept C remains the primary**, now hardened with Backspin-derived
retention/manufacturing details (§4.5) and an optional pocket-based variant for the (2,9)
chord. See updated recommendation at the end of §4.5.

---

## 4.5 Related toy (partial analogue, not strict prior art): Back Spin / Loophole

> **Attribution correction (cited).** The puzzle in `backspin_ref.jpg` is **"Back Spin"**
> (also sold as **"Loophole"**), invented by **Ferdinand Lammertink**, **US Patent 5,172,912,
> granted 22 Dec 1992**, originally published by **Binary Arts** (the company that later became
> **ThinkFun**), with later ThinkFun reissues. It is *not* a Hasbro product — the brief
> referred to it as "Hasbro Backspin," but no source supports Hasbro authorship; the maker is
> Binary Arts / ThinkFun. (Hasbro's similarly-named handheld is a different item.) Calling it
> "Backspin" colloquially is fine; the *mechanism* below is what matters.

### 4.5.1 How Back Spin actually works (cited; confidence: HIGH on topology, MEDIUM on the exact transfer-hole geometry)

Back Spin is a **two-faced rotary sliding-block puzzle** — topologically a colour-sorting
"15-puzzle" wrapped onto both faces of a disc, with **one** empty cell as the only free space.

- **Construction.** A circular disc ≈ **6 in (152 mm) diameter × 1.25 in (32 mm) thick** made
  of **two molded shells** whose **two faces rotate relative to each other** about the common
  central axis. You hold one half in each hand and twist.
- **Pocket layout (per face).** **6 pockets per face: 3 radial "spoke" channels** (running
  edge→hub like wheel spokes) **alternating with 3 curved "rim" channels** along the disc edge.
  **6 pockets × 2 faces = 12 pockets total.** Each pocket holds **3 balls in a single-file
  row** (the oblong race-track pockets visible in the photo).
- **Ball count.** Capacity is **6·3 = 18 balls per face = 36 total**, but the puzzle ships with
  **35 balls** (9 colours, mixed multiplicities) — **one ball is omitted**, leaving exactly one
  **empty cell** in a curved rim area. That single hole is the only place anything can move
  *into*, exactly like the blank tile of a 15-puzzle. (One review miscounts colours/sets; the
  authoritative count is Jaap's: 35 balls, 9 colours.)
- **In-face motion (gravity-assisted sliding).** Within a pocket, balls are single-file and
  can only shuffle **toward the empty cell**. The player **rotates/tilts the whole puzzle in
  hand** so gravity rolls a ball into the adjacent empty slot — i.e. gravity moves balls
  *within the plane of a face*, one step at a time.
- **Cross-face transfer (the "loophole").** A ball changes faces by a **register-and-push**:
  when the two halves are twisted so that **the end of a spoke channel on one face lines up
  directly behind the empty cell of a rim channel on the other face**, the ball at that shared
  end can be **pushed through a hole** to the opposite side, where it occupies the (formerly
  empty) cell. Sources agree the transfer is **mechanical alignment + push-through a hole at
  the channel ends**, with gravity used only to coax balls toward the hole. **The puzzle is
  NOT flipped over to dump balls by gravity** — there is no free-fall transfer; the single hole
  + relative rotation is the entire mechanism. (Exact internal geometry of the through-hole and
  how many positions register at once is the part I'm least certain of: Jaap's and the patent
  describe the topology — "curved-area position ↔ outer spoke position on the other face" — but
  consumer reviews don't show the molded detail. Confidence MEDIUM here; HIGH on the topology.)
- **Goal.** Sort all balls so each pocket holds one colour, where the **3 spoke colours on one
  face match the 3 rim colours on the opposite face** — which is what forces using both faces.

**Sources:** Jaap's Puzzle Page (Backspin/Loophole), J. A. Storer "JimPuzzles" Back Spin page,
SAHM Reviews ThinkFun Back Spin review, ThinkFun product page. US Patent 5,172,912 (Lammertink,
1992). Where consumer reviews conflict with Jaap's/patent on counts, I take Jaap's as
authoritative and flag it above.

### 4.5.2 Reconciliation with our toy — the fundamental difference

Back Spin's **native move is "twist + nudge one ball into the single hole" (and occasionally
push one ball through to the other face).** It is an *incremental, one-token-at-a-time*
sliding-block machine driven by **relative rotation + gravity**, with **no gear train and no
simultaneous multi-swap.** Our toy's required move is the **opposite kind of thing**: a
**single actuation that applies a fixed 6-transposition permutation
(0 1)(2 9)(3 4)(5 6)(7 8)(10 11) to all 12 tokens at once.** These are categorically different:

| Aspect | Back Spin | Our M12 swap toy |
|---|---|---|
| Free space | exactly **one** empty cell | **none** — all 12 cells full, must exchange in place |
| Per-action effect | move **1** ball one step (or 1 transfer) | apply **6 transpositions simultaneously** |
| Drive | relative rotation + gravity, no gears | one pull → geared/cammed 180° everywhere |
| State machine | permutation *group of the 35-blank* (reachable configs) | a *single fixed generator* repeated |

So a **faithful Backspin clone cannot perform our move.** A 6-transposition involution with
**no blank cell** is exactly what a sliding-block puzzle *cannot* do — sliding blocks need a
hole, and they move one tile per step. To get an *all-at-once* swap you fundamentally need
carriers/rotors (Concept A/C) or some mechanism that holds both members of a pair and exchanges
them — which is not what Back Spin does.

**Could the oblong two-ended pocket + a half-turn exchange a pair without a gear train?**
Partly, and this is the genuinely useful borrow. A Backspin-style **oblong pocket that holds
exactly two tokens, mounted on a carrier that does a 180° flip/half-turn about the pocket's own
center, swaps that pair with no gear** — but that *is* Concept A's rotor by another name (a
2-cell carrier turned 180°). Backspin's contribution there is the **race-track pocket profile
and end-retention**, not a new kinematic principle. To drive **all six** pockets from one pull
you still need to couple them, i.e. a gear/cam train — Backspin offers nothing that removes
that, because Backspin never moves more than one ball per action.

**Does a flip-based transfer help the (2,9) cross-chord?** Back Spin's *cross-face* transfer is
the one idea that maps onto our hardest problem. Recall §3: a rigid in-plane (2,9) bar sweeps a
**Ø 90.96 mm** disc (r = 45.48 mm at the (−11.2, −17.5) midpoint) that **passes through slots
1, 10, 11**. Back Spin shows a clean way to move a token between two positions **without any
in-plane sweep at all**: put slot 2 over a pocket-end on the **front** face and slot 9 over a
pocket-end on the **back** face, and transfer **through the disc (a short axial push), not
across it.** This is exactly the spirit of Concept C's "go **up**, not sideways" bridge — Back
Spin validates the through-thickness route and supplies a proven retention detail (ball captured
in a molded race-track, pushed end-to-end). **However**, Back Spin transfers **one ball at a
time into a hole**; a true (2,9) *exchange* needs **both** tokens to cross **simultaneously and
past each other**, which Back Spin never does (it always has a blank to step into). So Back Spin
**reduces but does not eliminate** the (2,9) difficulty: it endorses the over/under /
through-thickness approach and the pocket retention, but the two-token *simultaneous* exchange
still requires Concept C's stacked two-lane bridge (upper 2→9, lower 9→2) so they don't collide.
**Net: Backspin helps the (2,9) problem at the level of "route it through the thickness," which
we already chose; it does not give a one-piece blank-cell solution because we have no blank.**

### 4.5.3 What Back Spin teaches us (the borrowable ideas)

1. **Two-shell molding (biggest manufacturability win).** Back Spin is **two molded shells**
   that capture all balls between them and rotate on a common boss. Adopt this for our **base
   disc + top window plate** as the primary split line: tokens are loaded, then the two shells
   close and capture everything. This is cleaner than the 14-part stack in §7 and is exactly an
   FDM-friendly two-print breakdown (print each shell flat, no supports).
2. **Visible-but-captive via a clear window.** Back Spin's coloured rings frame each pocket and
   the balls are always **visible and captive** — you can see state but nothing falls out. Our
   §5.1 clear top window plate is the same idea; Back Spin confirms the **molded retaining lip
   around each pocket mouth** as the retention detail (token visible through an oval aperture,
   lip < token OD so it can't escape axially).
3. **Race-track (oblong) pocket profile for token retention.** The oblong single-file pocket
   with rounded ends positively locates round/disc tokens and gives a tactile "seated" feel at
   each end — adopt for our **rotor end-pockets** and the **(2,9) lane carriages** so a token
   clicks home at hand-off (mitigates the §10.1 registration risk).
4. **Detents come "for free" from the geometry, not a separate star wheel.** Back Spin has no
   sprung detent; the **ball-in-pocket seating** *is* the detent. We can copy this: shape the
   carousel/rotor pockets so the **token itself seats** at each indexed position, reducing
   reliance on the separate 11-tooth star wheel (§5.5) — keep the star wheel as backup.
5. **Through-thickness transfer for the long chord.** As analyzed in §4.5.2, route (2,9)
   **axially through the disc** (front pocket-end ↔ back pocket-end) rather than across it —
   this is independent corroboration of Concept C's lifted bridge and the strongest single
   borrow for our crux problem.

### 4.5.4 Updated recommendation (what changed and why)

**Unchanged primary recommendation: Concept C** (5 rim rotors + over/under bridge, geared from
the 0→1 pull). Back Spin does **not** displace it, because Back Spin's blank-cell,
one-ball-at-a-time, no-gear paradigm fundamentally cannot apply a fixed all-at-once
6-transposition. **What changed:**

- **Manufacturing split adopted from Back Spin:** make the **two-shell sandwich** (base + clear
  window) the primary part division (§4.5.3-1), simplifying the §7 stack.
- **Retention adopted:** **race-track pockets + molded retaining lips** for all token cells and
  rotor/lane ends (§4.5.3-2,3); seat-as-detent to de-risk hand-off (§4.5.3-4).
- **(2,9) route corroborated:** keep the over/under bridge but reframe it as Back Spin's
  **through-thickness transfer** (front face ↔ back face), the borrow with the most leverage on
  the crux (§4.5.3-5).
- **Recorded but not adopted: "Concept D" pure Backspin clone** — rejected for *one-pull
  simultaneous swap* (no blank cell, one ball per move), but kept on the table as a *different
  toy* if the goal ever relaxes from "apply generator 25 in one pull" to "freely sort tokens
  toward a target," in which case a Backspin-style sandwich would be far simpler than the gear
  train. **Left for the human to choose; the prior Concept C recommendation is preserved above,
  not deleted.**

---

## 5. Recommended mechanism in detail

### 5.1 Layer stack (bottom → top)
1. **Base disc** — structural floor, central bearing boss, mounting bosses for the 5 rim
   rotors and the bridge towers, rack channel for the pull slide.
2. **Rotor layer** — the 5 small carriers (4 neighbor + 1 apex) on vertical pins; the central
   sun gear / cam hub; the (2,9) bridge's two lane-carriages.
3. **Token ring (rotation generator)** — an indexing carousel that holds the 12 tokens captive
   between swaps and rotates them by 32.727° detents (see §5.5). In *swap mode* it is clamped;
   in *rotate mode* the rotors are disengaged.
4. **Top window plate** — clear PETG/printed window with 12 oval apertures so numbers read
   through; retains tokens vertically.

### 5.2 The single-actuation drive (0→1 pull → 180° everywhere)
- The apex token sits on a **slide** in a straight channel from slot 0 to slot 1 (12.50 mm
  stroke). Pulling it down is the user trigger.
- The slide carries a **rack** (12.50 mm of travel). It meshes a central **sun pinion**.
  For a half-turn (180°) from 12.50 mm of rack, pinion pitch Ø = `2·stroke/π = 7.96 mm`
  (≈ Ø8 mm pinion). That is the apex rotor's own rotation.
- The sun hub drives the **4 neighbor rotors** through a 1:1 idler/gear train (each must also
  turn exactly 180°). A 1:1 ratio keeps every rotor synchronized to the same half-turn.
- The (2,9) **bridge** is driven by a **cam-and-follower** off the sun hub: the cam profile
  lifts both lane-carriages, translates them across (upper deck 2→9, lower deck 9→2), and
  lowers them, all within the same single pull. A cam (not a gear) is used here because the
  bridge motion is *lift–translate–lower*, not pure rotation.
- **Reset**: push the apex token back up (12.50 mm). Because every element is positively
  geared/cammed to the slide, the reverse stroke runs the swap backward and re-parks all
  tokens. A light **return spring** (see hardware) biases toward the locked/up position so the
  toy rests in a defined state and removes free-play.

### 5.3 Token retention / capture
- Tokens are **captive in the carousel ring**: each token is a printed disc (Ø ≈ 22 mm at
  Dp=100; must clear the 28.17 mm neighbor pitch with walls) riding in a pocket with a
  retaining lip top (window plate) and bottom (rotor-layer floor). It can slide laterally only
  via a rotor end-pocket or carousel pocket, never fall out.
- During a swap, a rotor end-pocket and the carousel pocket **register** (line up) so the token
  transfers from carousel → rotor → carousel-on-the-other-end. Registration tolerance is the
  main risk (see §9).

### 5.4 0→1 pull also re-locks (optional)
A small **detent ramp** on the slide drops into a notch at full-up (locked) and full-down
(swapped) positions, giving tactile end-stops and preventing mid-swap rest. The return spring
holds it in whichever detent it last reached.

### 5.5 Coexistence with the ROTATION generator (separate modes)
- **Mode switch**: a sleeve/ring that, when twisted or pushed, either (a) **engages** the
  rotor pins to the carousel pockets (swap mode) or (b) **retracts** them below the carousel
  floor (rotate mode), freeing the carousel to spin.
- In **rotate mode** the carousel indexes by **32.727°** detents (an 11-tooth star wheel /
  sprung ball detent), advancing tokens around the ring so different tokens occupy the 6 swap
  slots before the next swap. The apex slot (0) is *not* on the ring carousel; it has its own
  fixed slide. (Note: the digital rotation is order-11 on the ring with the apex fixed — the
  carousel must therefore carry only the 11 ring tokens; the apex token stays in its slide.)
- The two mechanisms are **time-multiplexed**, never engaged at once, which sidesteps any need
  for them to share the plane simultaneously.

### 5.6 Backlash
- Use **anti-backlash** by preloading the return spring so gear flanks stay on one side.
- Keep gear modules generous (module ~1.0–1.25) for FDM; expect ~0.15 mm backlash per mesh —
  acceptable because end-of-stroke detents define final position, not the gear train.

### 5.7 Reset / play loop
1. Carousel in rotate mode → index tokens to taste.
2. Switch to swap mode (rotors engage).
3. Pull apex token down (0→1) → all 6 pairs swap.
4. Push apex token up → swap reverses (or leave swapped and re-rotate). Repeat.

---

## 6. Planarity argument

Of the 12 token excursions in one swap, **10 are pure in-plane rotations** about rim/apex axes
(the 5 local rotors), and only **2** (the (2,9) pair) leave the plane — and they leave it
*vertically* via the bridge, never sweeping laterally into other slots. Thus the toy is
"single-layer" in the user-meaningful sense: the visible top window shows a flat ring; only a
small central arch betrays the one cross-disc pair. No two in-plane mechanisms overlap (proven
in §3: the 4 neighbor rotors + apex rotor are mutually clear; the lone interior traverse is
lifted out of plane). This is exactly why the (0 1)(2 9)(3 4)(5 6)(7 8)(10 11) routing was
chosen.

---

## 7. Parts list

### Printed (PLA/PETG, 0.4 mm nozzle)
| Part | Qty | Rough size (Dp=100) | Print notes |
|------|----:|---------------------|-------------|
| Base disc | 1 | Ø ~120 mm × 6 mm | flat on bed, no supports |
| Rotor-layer floor / carousel track | 1 | Ø ~115 mm × 3 mm | flat |
| Neighbor rotor carrier | 4 | 28 mm long × 10 mm | print flat, axis vertical in use |
| Apex rotor carrier | 1 | 12.5 mm | flat |
| Central sun hub + pinion (Ø8) | 1 | Ø ~20 mm | print teeth-up, fine layers |
| Idler gears (1:1 train) | ~5 | Ø ~12–16 mm | teeth-up |
| (2,9) bridge towers | 2 | ~25 mm tall | may need light support |
| (2,9) upper/lower lane carriages | 2 | ~50 mm | flat |
| (2,9) cam | 1 | Ø ~20 mm | flat |
| Apex slide + rack | 1 | 12.5 mm travel | flat |
| Mode-switch sleeve | 1 | Ø ~25 mm | — |
| 11-tooth detent star wheel | 1 | Ø ~30 mm | flat |
| Top window plate | 1 | Ø ~120 mm × 2 mm | clear PETG, flat |
| Tokens 0–11 | 12 | Ø ~22 mm × 5 mm | numbers embossed/inset, flat |

**Token numbering choice: 0–11** (matches engine/position indices in this package; relabel to
1–12 trivially if preferred for lay users).

### Non-printed hardware
| Item | Qty | Use |
|------|----:|-----|
| M3 × 12 cap screws | ~6 | layer stack-up |
| M3 brass heat-set inserts | ~6 | into base bosses |
| Ø3 mm steel dowel pins | ~7 | rotor/idler axes (low-friction) |
| Compression spring (light, ~5–10 N/mm) | 1 | apex-slide return / detent preload |
| Ball-detent springs (or small magnets) | ~2 | carousel 32.727° indexing |
| Optional Ø3 mm ID bushings/bearings | ~7 | smoother rotor spin |

---

## 8. Tolerances & print orientation

- Moving fits: **0.2–0.3 mm** diametral clearance (pins in holes, token in pocket). Start at
  0.25 mm and tune with a fit-test coupon.
- Gear teeth: module 1.0–1.25; pressure angle 20°; expect to sand/iterate the sun pinion.
- Print all flat parts **on the bed** (no supports). Only the bridge towers may need minimal
  support; consider splitting them to print support-free.
- Tokens: emboss numbers ≥1.5 mm tall, 0.6 mm raised, for legibility through the window.
- Keep token OD < neighbor pitch (28.17 mm) minus 2× wall; Ø22 mm leaves ~3 mm walls.

---

## 9. Assembly sequence

1. Heat-set M3 inserts into base bosses.
2. Press Ø3 dowel pins for the 5 rotors + idlers into the base.
3. Drop idler train + sun hub/pinion; verify 1:1 mesh and that all turn 180° together by hand.
4. Mount the 4 neighbor rotors + apex rotor on their pins.
5. Build the (2,9) bridge: towers → lane carriages → cam on sun hub; verify lift-cross-lower.
6. Fit the apex slide + rack; mesh to sun pinion; install return spring; check 12.50 mm stroke
   gives 180°.
7. Install carousel track, star wheel, detent springs; verify 32.727° indexing.
8. Install mode-switch sleeve; verify engage/retract.
9. Load 12 tokens; fit top window plate; screw the stack together.

---

## 10. Open risks & suggested prototype tests

1. **Token transfer registration** (biggest risk): the rotor end-pocket and carousel pocket
   must align within ~0.3 mm at hand-off, or tokens jam. *Test:* print a single neighbor-rotor
   subassembly (base + one Ø3 pin + one rotor + two pockets + two tokens) and exercise the
   hand-off by hand before building the whole train.
2. **(2,9) bridge complexity**: the over/under cam motion is the hardest part. *Test:* prototype
   the bridge in isolation; if it's fragile, fall back to a **manual** long-chord (user lifts
   and swaps slots 2/9 by hand) while the pull does the other 5 — still a valid demo.
3. **Gear-train sync / backlash**: 6+ meshes accumulate error. *Test:* the §10.1 coupon, then a
   5-rotor train mock-up; confirm all reach 180° at full stroke.
4. **Carousel vs rotor mode switch** reliability. *Test:* the sleeve engage/retract alone.
5. **Apex-on-carousel question**: confirm the apex token need not ride the carousel (it
   doesn't, per §5.5) — but verify the (0,1) swap still makes sense after rotation, since after
   a ring rotation a *different* ring token sits at slot 1 to be pulled against the apex.

### Suggested build order for prototypers
single neighbor-rotor coupon → 5-rotor + drive (skip bridge, hand-swap 2/9) → add carousel +
mode switch → finally the (2,9) bridge.

---

## 11. Addendum — interactive viewer & mechanism refinements

Worked out in the live 3D viewer (`viewer/index.html`) and validated with the
interference checker (`check_interference.py`, trimesh + manifold boolean volumes):

- **Bearings:** snap-in flanged **MF105ZZ** (5 mm bore × 10 mm OD × 4 mm) at each
  rotor pivot; central axis a **608ZZ** (8 × 22 × 7). Print the bore at OD+~0.1 mm
  with a ~0.35 mm retaining lip; flanged race seats against a shoulder. (igus
  JFM/JSM clip-in flanged sleeves are the all-plastic alternative.) Scale a size
  down (MF85 / 688) for a ~70 mm toy.
- **Rim gear** is housed in a bay **below** the balls and **only rotates** (never
  translates) — a descending gear would pass through the disc.
- **Neighbour/apex swaps** happen **in-plane** inside round swap pockets (no lift).
- **(2,9) transfer is positively driven both ways** (must work upside-down): a
  face cam on the (2,9) idler drives two **pushrods** that shove balls 2 & 9 down
  through the holes into the back swing-arm's **cups + retaining ruts** (first
  gear-step), the arm rotates 180°, then the arm/cam re-seats them up. Continuous
  rut capture means a ball is never momentarily free.
- **Tokens:** clear milky balls; the digit is repeated on all 12 dodecahedral
  faces, **flush with the surface** (recessed, not embossed) so they roll.
- **Colour = light:** each position emits its swap-pair colour onto whatever ball
  is in it (no physical colour rings to collide with).

### The ball channel — DONE (checker PASSES)
The channel is now **carved into the disc** as one part: a continuous ring groove,
widened into round **swap pockets** at every pair (apex included) except the (2,9)
cross, which has through-holes. All balls ride at **one height** (2 & 9 line up at
rest); the rim gear sits in a **bay below the ball bottoms** and only rotates; the
front rotors **retract during spin** and rise to engage for a swap; the **(2,9)
swing plane is below the rim gear** so the cross balls never clip it. The
interference checker (`check_interference.py`, run as the last step of
`make_parts.sh`) reports **PASS — no parts pass through each other** (only legit
seat-contacts remain).

### Open (next pass)
- The **windowed top shell** (caps poke through; mechanism fully hidden — completes
  the BackSpin enclosure and actually conceals the (2,9) ring).
- Make the **equatorial-ring cam** and its drive arms explicit (and add the ring +
  arms to the interference checker so their motion is gated too).
- Detents / the indexing carrier for the spin.
