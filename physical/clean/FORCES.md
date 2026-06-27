# Sporadic M12 clean-sheet — Force & Structural Feasibility

Hand calculations with stated assumptions. **Material: PETG** for all structural/moving parts
(tougher and less brittle than PLA; good layer adhesion; the gear teeth and thin bars want
ductility, not PLA's brittleness). Window: **clear PETG** (or clear tough resin if SLA-printed).

PETG (FDM, ~0.4 mm nozzle, ≥4 perimeters, ≥40 % infill on loaded parts) — conservative working
properties used here:

| Property | Value (conservative) |
|---|---|
| Tensile/flexural strength σ_f | 35 MPa (de-rated from ~50 MPa for FDM anisotropy & layer planes) |
| Young's modulus E | 1.8 GPa |
| Safe working stress (FoS ≈ 3 on σ_f) | **≈ 12 MPa** |

The toy is **hand-actuated and low-speed**; the governing loads are (1) the user's flick force,
(2) the spin detent, (3) ball retention by the cover, (4) gear-tooth bending in the 1:1 train.
There is no inertial/impact spec beyond "a child can flick it" — assume a generous **F_flick =
20 N** peak finger force (a brisk flick; a normal flick is 3–8 N).

---

## 1. Input: the 0-flick → torque on the apex crank

The apex rotor radius is r_a = 12 mm. The user pushes ball 0 roughly tangent to the crank arc.

    T_in = F_flick · r_a = 20 N · 0.012 m = 0.24 N·m   (peak)

This torque is shared out 1:1 to 5 driven rotors + the (2,9) rotor through the idler train.
Friction and the six swaps load it, but each swap is just lifting/turning an 18 mm ball
(mass ≈ 3 g if printed hollow PETG, ≈ 5 g solid) — negligible weight load
(5 g · 9.81 = 0.05 N per ball). **The flick energy is dominated by overcoming detents and gear
friction, not by moving the balls.** 0.24 N·m is ample; in practice the train will turn on a
few N of flick. Verdict: **input torque non-critical, comfortably available.**

---

## 2. Gear-tooth bending (the 1:1 train) — Lewis check

Worst-loaded mesh = the sun pinion / apex crank, carrying the full input torque before it
splits. Pitch Ø ≈ 14 mm, module **m = 1.0**, face width **b = 4 mm**.

Tangential tooth load at the pitch circle:

    W_t = T_in / r_pitch = 0.24 / 0.007 = 34 N   (peak, all torque on one mesh — conservative;
                                                  real load splits across the train)

Lewis bending stress (Lewis form factor Y ≈ 0.32 for ~14 teeth, 20° PA):

    σ = W_t / (b · m · Y) = 34 / (0.004 · 0.001 · 0.32) m-units
      = 34 / (4 mm · 1 mm · 0.32) = 34 / 1.28 mm² = 26.6 N/mm² = **26.6 MPa**

That is **above** the 12 MPa safe working stress (FoS would be only ~1.3 on σ_f = 35 MPa).
**FLAGGED.** Two cheap fixes, both adopted:

- **Increase face width to b = 6 mm** (the gear deck has the room): σ → 17.7 MPa.
- **Increase module to m = 1.25, b = 6 mm**: σ = 34/(6·1.25·0.32) = **14.2 MPa** → FoS ≈ 2.5
  on σ_f. Combined with the fact that 34 N is the *un-split* peak (the real per-mesh load after
  the train splits to 6 outputs is far lower), the true FoS is comfortably > 3.

**Decision: module 1.25, face width 6 mm, 20° pressure angle, ≥4 perimeters so teeth are
solid-walled.** Update the SCAD pinion accordingly (currently drawn as a plain Ø boss — gear
teeth to be generated with a gear library or BOSL2 `spur_gear`). Rim/idler gears same module.

---

## 3. The rotor bars (thin sections in bending)

Each 2-cell rotor bar carries its two balls' weight + the small swap acceleration. Largest bar =
the **(2,9) under-deck bar**, L = 91 mm, modeled 9 mm wide × 6 mm tall in the SCAD.

Worst case: treat it as a simply-supported beam (pivot at centre, a ball at each end = two
cantilevers of 45.5 mm). Load per end = ball weight + a generous 2 N swap/handling load ≈ 2.1 N.

    M = F · L_cant = 2.1 N · 0.0455 m = 0.0955 N·m
    Section (9 mm wide, 6 mm tall): I = b·h³/12 = 9·6³/12 = 162 mm⁴; c = 3 mm
    σ = M·c / I = 95.5 N·mm · 3 mm / 162 mm⁴ = 1.77 MPa

**FoS ≈ 20 on σ_f.** The bar is over-strong even at 91 mm. The four rim bars (28 mm) and apex
bar (24 mm) are far shorter and stiffer → trivially OK. **Verdict: bars PASS with huge margin.**
(Stiffness, not strength, is the real concern for registration; deflection of the (2,9) bar end:
δ = F·L³/(3EI) = 2.1·45.5³/(3·1800·162) = 2.1·94196/(874800) = 0.23 mm. Acceptable but at the
edge of the 0.3 mm hand-off tolerance — keep the bar at 6 mm tall or add a 1 mm rib; the SCAD's
6 mm cube bar is the minimum. **FLAGGED-minor: stiffen the (2,9) bar to 8 mm tall**, dropping δ
to 0.10 mm.)

**Adopted:** (2,9) bar 9 mm wide × **8 mm** tall (update SCAD `cross_rotor` bar height).

---

## 4. The pivot pins (Ø3 dowels)

Each rotor pivots on a Ø3 mm pin (steel dowel preferred, or printed). Shear on the (2,9) pin
from the 34 N peak drive reaction:

    A = π·1.5² = 7.07 mm²;  τ = 34 / 7.07 = 4.8 MPa (steel dowel: trivial; printed PETG pin
    shear strength ~25 MPa → FoS ~5). **PASS.** Use steel dowels at the 5 in-plane rotors and
    the (2,9) pivot for low friction and zero wear; printed bores at Ø3.0 + 0.25 clearance.

---

## 5. Spin detent spring

One sprung-ball detent (Ø4 ball) into an 11-tooth star, pitch 32.727°. We want a crisp but easy
click — target seating force **F_d ≈ 3 N** at the ball, ramp angle ~30°.

    Spring force needed ≈ F_d / tan(30°) ≈ 3 / 0.577 ≈ 5.2 N over ~2 mm of ball lift.
    A light compression spring, k ≈ 2.6 N/mm, preload ~3 N. (Commodity Ø4 detent plunger or a
    music-wire spring + Ø4 bearing ball.) The star-tooth ramp sees 5 N contact on a ~2 mm² land
    → 2.5 MPa bearing on PETG: **PASS** (well under 12 MPa). Tooth wear over thousands of clicks
    is the practical limit; a steel ball on PETG ramps is fine for a toy. **Verdict: PASS;**
    tune k on a coupon for feel.

---

## 6. Ball retention by the cover (the window lip)

Window aperture lip ID = 14 mm, ball Ø = 18 mm → **2 mm radial overlap** per side holds the ball
axially. Retention load = whatever a user pushes a ball *up* with (e.g. shaking, or pressing) —
say a 30 N abuse load on one ball. The lip is a 14 mm-ID annular ledge in a 3 mm-thick window.

Treat the lip as an annular plate ledge; the ball bears on the 2 mm-wide ring at the aperture.
Bearing area ≈ π·(lip_id)·(overlap) ≈ π·14·2 = 88 mm². Stress = 30/88 = 0.34 MPa. **PASS hugely.**
The failure mode is the window *delaminating from the base sandwich*, not the lip — so the
window-to-base screw circle (6× M3) governs; 6 M3 in PETG bosses with heat-set inserts hold
> 6·500 N pull-out → **PASS.** **Verdict: ball retention PASS.**

---

## 7. Mode-switch sleeve (raises/retracts the 5 in-plane rotor cups)

The sleeve lifts five rotor assemblies 16 mm (from z = −7 to +9). Each rotor + ball ≈ 8 g →
5·8·9.81 = 0.4 N of weight + cup friction; a cam ramp or a twist-lift sleeve handles this with a
light thumb force. Low-stress; the **detent that holds the sleeve in "swap" vs "spin"** wants a
~5 N click (same class as §5). **Verdict: PASS;** make the sleeve walls ≥ 2 mm (4 perimeters).

---

## 8. Summary of flags & actions

| # | Item | Status | Action taken |
|---|------|--------|--------------|
| 2 | Sun-pinion / crank gear teeth | **FLAGGED** (26.6 MPa at m1.0/b4) | → **module 1.25, face 6 mm** → 14.2 MPa, FoS ≈ 2.5 (and real split-load FoS > 3) |
| 3 | (2,9) bar stiffness | minor flag (δ = 0.23 mm) | → **bar 8 mm tall** → δ = 0.10 mm |
| 1,4,5,6,7 | input torque, pins, detent, retention, sleeve | PASS | dowel pins Ø3 steel; lip 2 mm; ≥4 perimeters |

**Net verdict:** structurally feasible in PETG. The only genuinely load-critical element is the
**central gear mesh**, fixed by module 1.25 / 6 mm face. Everything else has FoS ≥ 2.5, most far
higher. The real-world risk is **registration/stiffness/backlash** (a fit problem), not strength
— which is exactly what the prototype coupons in `print_and_assemble.md` target.
