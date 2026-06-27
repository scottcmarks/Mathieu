# check_clean.py — results & analytical verification

> **Environment note:** this clean-sheet package was produced in a sandbox that **blocks
> executing `python` and `openscad`** (every such invocation is denied by a permission rule).
> The checker (`check_clean.py`) and the STL renders are therefore **pending execution on
> Scott's machine**:
>
> ```
> physical/.venv/bin/python physical/clean/check_clean.py ; echo "exit=$?"
> ```
>
> Below is the **hand-traced worst-case clearance audit** that the design was iterated against —
> every clash class the checker evaluates, traced analytically to a positive (clear) margin.
> Run the command above to confirm `RESULT: PASS` and exit 0.

## Clearance audit (worst frame per clash class)

All distances in mm. "clear by X" = parts/balls separated by X beyond contact (so checker
penetration = −X < TOL ⇒ no clash). Penetration TOL = 0.4.

### SWAP sweep (72 frames, engaged=True)
| Clash class | Worst geometry | Margin |
|---|---|---|
| ball ↔ ball, within a pair | 2-cell rotor keeps pair members = chord apart | apex 24−18 = **+6**; rims 28.17−18 = **+10.2**; (2,9) 91−18 = **+73** |
| ball ↔ ball, across pairs | §3 discs mutually clear; nearest centers | **> +8** (rims), apex isolated at r=74 |
| (2,9) ball ↔ parked balls 1/10/11 | (2,9) at z=−16 vs balls at z=9 | z-gap **25**, clear |
| (2,9) bar ↔ in-plane rotor hubs | bar passes planar-under (10,11) hub | bar-top −11.5 vs hub-bot −8.5 = **+3.0** |
| (2,9) bar/cups ↔ in-plane cups (z=9) | z separation | **> +20** |
| apex rotor ↔ sun-pinion (coaxial) | excepted (legit, same shaft) | n/a |
| apex slide-thumb ↔ ball 1 | thumb at ball-0 arc, ball 1 opposite arc | centers 24 − 4(thumb) − 9(ball) = **+11** |
| rim rotor ↔ rim rotor (cups) | adjacent pairs, nearest cups | 51.9−14.09−14.09−7.38−7.38 = **+8.9** |
| ball drop/rise (2,9) ↔ rim rotors | slot 2 vs (3,4) disc | 40.8−14.09−9 = **+17.7** |

### SPIN sweep (132 steps, engaged=False — in-plane rotors retracted to z=−7)
| Clash class | Worst geometry | Margin |
|---|---|---|
| ring-ball (z=9) ↔ retracted rotor cup | cup top at z=−7−0.9 = −7.9 | center-to-top 16.9 − rb 9 = **+7.9** |
| ring-ball ↔ retracted rotor bar | bar at z=−7, reaches z=−3 | ball bottom 0 − (−3) = **+3.0** |
| ring-ball ↔ in-plane hubs | hub top z=−2 | center-to-top 11 − rb 9 = **+2.0** |
| ring-ball ↔ sun-pinion / rack (outside ring) | (0,62) outside R=50 | clear (planar + z) |
| ring-ball ↔ (2,9) seated rotor | z=−16 deck | **> +20** |
| part ↔ part at rest | retracted in-plane bar (z−7) vs (2,9) bar (z−16) | **> +0.5** (interval), real ≈ +8.5 |

**Tightest margins:** ring-ball vs in-plane hub top = **+2.0 mm** (spin), and (2,9) bar vs
in-plane hub = **+3.0 mm** (swap). Both positive ⇒ checker reads no clash (penetration < 0 <
TOL). These two are the margins to watch if you change z-decks; everything else has > +6 mm.

## Decisions forced by the audit (already baked into the files)
1. **Apex chord 12.5 → 24 mm** (slot 0 to r=74): the only way the 2-cell apex rotor's two balls
   don't overlap. Old value FAILs ball-vs-ball by 5.5 mm.
2. **(2,9) deck z = −16** (was −14): lifts the bar-vs-hub margin from +1.0 to +3.0 mm.
3. **Retract-during-spin mode switch:** in-plane rotors drop to z=−7 for spin so ring balls
   clear them (else cup-vs-ball penetration ≈ +8 mm). Time-multiplexed swap/spin.
4. **Faithful part-vs-part metric** (planar-gap ⊕ z-gap, no vertical cylinder inflation): a
   naive capsule-cast over-reported the bar-vs-hub deck clearance by ~r and caused false fails.
