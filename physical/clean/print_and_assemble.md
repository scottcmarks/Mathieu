# Print & Assemble — M12 clean-sheet swap toy

Written for Scott to execute physically. Material/orientation chosen per FORCES.md (PETG).

> **Build philosophy:** prove the risky bits as cheap coupons FIRST (a single rim rotor + its
> hand-off, then the gear-train sync), then the full toy. The interference proof
> (`check_clean.py`) covers geometry; the prototype proves *fit and feel* (registration,
> backlash, detent), which calc cannot.

---

## 0. Before printing — render the STLs

`openscad` is on this machine. From `physical/clean/`:

```
openscad -o base_disc.stl    -D 'PART="base"'     m12_clean.scad
openscad -o carousel.stl     -D 'PART="carousel"' m12_clean.scad
openscad -o rim_rotor.stl    -D 'PART="rim"'      m12_clean.scad   # ×4 (3-4,5-6,7-8,10-11)
openscad -o apex_rotor.stl   -D 'PART="apex"'     m12_clean.scad
openscad -o cross_rotor.stl  -D 'PART="cross29"'  m12_clean.scad
openscad -o window.stl       -D 'PART="window"'   m12_clean.scad
openscad -o ball.stl         -D 'PART="ball"'     m12_clean.scad   # ×12, edit num per ball
openscad -o preview.stl      -D 'PART="all"'      m12_clean.scad   # visual assembly check only
```

> NOTE (pending render): this clean-sheet package was authored in an environment that **blocks
> executing `openscad` and `python`**, so the STLs and the `check_clean.py` run are **pending a
> render on your machine.** The SCAD is parametric and self-consistent with the checker's
> geometry constants; render and eyeball `preview.stl` before committing to prints. The gear
> *teeth* in the SCAD are placeholder bosses — add real teeth with a gear lib (BOSL2
> `spur_gear(mod=1.25, teeth=…, …)`) before final prints; see §6.

---

## 1. What to print (PETG unless noted)

| Part | Qty | Orientation | Notes |
|------|----:|-------------|-------|
| Base disc | 1 | flat, bores up | ≥4 perimeters, 40 % infill; the (2,9) deck floor + wells are in this part |
| Spin carousel | 1 | flat | 11 ball pockets up; underside 11-tooth star; prints support-free |
| Rim rotor (3-4,5-6,7-8,10-11) | 4 | flat, cradles up | cradle is open-topped → no supports |
| Apex rotor (0-1) | 1 | flat | chord 24 mm; on the sun-pinion shaft |
| (2,9) cross rotor | 1 | flat | 91 mm bar, **8 mm tall** (stiffness); cradles up |
| Sun pinion / apex crank gear | 1 | teeth-up, 0.12 mm layers | module 1.25, b = 6 mm, 20° PA |
| Idler gears (1:1 train) | ~5 | teeth-up | same module; count set by routing (see §6) |
| Mode-switch sleeve | 1 | flat | raises/retracts the 5 in-plane rotors |
| Window plate | 1 | flat | **clear PETG**; oval apex slot + 11 round apertures + rim recess |
| Balls / tokens 0–11 | 12 | flat | clear/milky; digit recessed on faces; print hollow (~3 g) |

### Non-printed hardware
| Item | Qty | Use |
|------|----:|-----|
| 608ZZ bearing (8×22×7) | 1 | central spin bearing under the carousel |
| Ø3 mm steel dowel pins | 6 | 5 in-plane rotor pivots + (2,9) pivot |
| M3 × 12 cap screws + heat-set inserts | 6 | window-to-base sandwich |
| Ø4 mm bearing ball + light comp. spring (k≈2.6 N/mm) | 1 | spin detent |
| Light comp. spring | 1 | mode-switch / return bias |

---

## 2. Tolerances
- Moving fits: **0.25 mm** per side (pins in bores, ball in pocket). Print a fit coupon first.
- Ball pocket: sphere radius rb + 0.25; cradle lip ID 14 mm (retains the 18 mm ball).
- Gear backlash: expect ~0.15 mm/mesh; the end-of-stroke detents define final position, not the
  train, so this is acceptable. Preload the return/mode spring to keep gear flanks on one side
  (anti-backlash).

---

## 3. Assembly sequence
1. Heat-set 6× M3 inserts into the base disc rim bosses.
2. Press the 6 Ø3 dowel pins (5 in-plane + (2,9)) into the base.
3. Drop the **(2,9) cross rotor** onto its central pin at the −16 deck; confirm it swings a full
   180° in free air below the gear deck (nothing above it within 3 mm).
4. Seat the **608 bearing** in the central boss; drop the **spin carousel** on it; check it
   spins freely and the 11-tooth detent clicks every 32.7°.
5. Place the **sun pinion/apex crank** on its shaft; build the **idler train**; verify by hand
   that turning the crank 180° turns **all five** in-plane rotor positions + the (2,9) rotor
   **exactly 180°** (mark a tooth and count). Fix idler count/mesh until synced.
6. Mount the **4 rim rotors + apex rotor** on their pins, engaged to the train.
7. Fit the **mode-switch sleeve**; verify it raises the 5 cups to ball level (swap) and drops
   them below (spin), and that spin is free only when dropped.
8. Load the 12 balls (0 in the apex cup; 1–11 in carousel pockets).
9. Screw the **window plate** down; confirm numbers read through, ball 0 can plunge through its
   slot, and ring balls protrude enough at the rim recess to spin by fingertip.

---

## 4. Test plan (prove fit & feel)
**Coupon A — single rim rotor hand-off (highest risk):** print base-segment + one Ø3 pin + one
rim rotor + 2 balls. Exercise the 180° swap by hand; confirm balls transfer between carousel
pocket and rotor cup without jamming at the 0.25 mm clearance. Tune clearance here before
printing the rest.

**Coupon B — gear-train sync:** print sun crank + idlers + two rim rotors; confirm one 180°
crank turn = 180° at both rotors (backlash within one detent). 

**Coupon C — (2,9) deck:** print the (2,9) rotor + base deck + 2 balls + the two wells; confirm
balls drop, the bar sweeps 180° clear of everything, balls rise into the swapped wells. This is
the one off-plane motion — verify it never touches the ring plane.

**Full toy:** spin → index → switch to swap → flick 0 → all six pairs swap → flick back. Repeat.

---

## 5. Known risks to watch (mirror DESIGN.md §10)
1. **Hand-off registration** (0.25–0.3 mm) — Coupon A gates this.
2. **(2,9) bar stiffness** — end-deflection ~0.10 mm at 8 mm tall; if cups miss the wells on
   rise, thicken the bar or add a centre rib.
3. **Gear-train sync / backlash** across 6 meshes — Coupon B; rely on end detents.
4. **Mode-switch reliability** — the swap/spin sleeve must fully retract cups or spin jams.

---

## 6. Gear teeth — finishing the SCAD
The SCAD models gear hubs as plain cylinders (placeholder). For functional prints, replace the
`sun-pinion`/idler/rotor-hub cylinders with real involute gears, **module 1.25, 20° PA, face
6 mm** (FORCES.md §2). Easiest: install BOSL2 and use `spur_gear(mod=1.25, teeth=N, thickness=6)`
with all gears sharing the module so the 1:1 train holds. Tooth counts: pick equal counts on
crank and each rotor hub for true 1:1; idlers any count (they only transfer motion). Verify the
pitch radii still place the meshes where the hubs sit (rotor midpoints) — adjust idler positions
to bridge the gaps. This is the one remaining modeling step before a final print.
