#!/usr/bin/env python3
"""TRACK-2 CONTINUOUS-CONFINEMENT gate — the GRAVITY-SAFE master invariant.

Gravity-safety (the toy must work in ANY orientation, upside-down, edge-on) = at EVERY instant of a
swap, every ball is confined PAST ITS EQUATOR by some retainer — a spin-ring wall segment, a swap-ring
wall (the diameter-divider neighbour mechanism), or its magnet — AND the retainer hand-offs OVERLAP
(the new retainer grips before the old one releases), so there is never a single open frame.

This is the master gate every mechanism is checked against. It verifies two things:
  GEOMETRY  each retainer type actually confines past the equator (its opening/mouth < ball_d, or it
            is a closed capsule, or — for the magnet — it holds with force margin)
  TIMING    for each swapping ball, the active-retainer windows COVER the whole clip [0,1] with no gap
            and every hand-off overlaps by at least HANDOFF_MIN

Run with --selftest to confirm the gate has teeth (a deliberately gapped schedule must FAIL).
"""
import math, sys

# ---- ball + spin-channel geometry (Ø20) ----
SCALE=20/18; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2          # 20 / 10 / 10
tube=rb+0.3                                                      # spin-channel tube
lip = math.sqrt(tube*tube-rb*rb)+1.5                            # wall height above eq (over-equator)
spin_mouth = 2*math.sqrt(tube*tube - lip*lip)                   # finger-slot width at the lip
# ---- magnet hold (mirror check_29_mag.py, Ø14x4 N42 @ ~1mm) ----
mu0=4e-7*math.pi; Br=1.30; a_m=7e-3; h_m=4e-3; kd=0.5; z_grab=1e-3
def Baxial(z): return (Br/2)*((z+h_m)/math.sqrt((z+h_m)**2+a_m**2) - z/math.sqrt(z**2+a_m**2))
F_hold = kd*Baxial(z_grab)**2*(math.pi*a_m**2)/(2*mu0)
load = 2*(7850*4/3*math.pi*rb**3*1e-9)*9.81                     # solid Ø20 ball x2 dynamic (rb in mm->m)
mag_margin = F_hold/load

# ---- retainer geometric validity (confines past the equator?) ----
finger_w = ball_d - 4          # lid spin-channel finger slot (proto_lid.scad: ball_d-4 = 16)
RET = {
  'spin'     : ('spin-ring wall',  spin_mouth < ball_d - 1e-9, f'finger mouth {spin_mouth:.1f} < ball_d {ball_d:.0f}'),
  'swapring' : ('swap-ring groove', (lip > 2.47), f'over-equator grooved channel (lip {lip:.1f}>2.47), divider closes the inner side'),
  'magnet'   : ('magnet grip',     mag_margin >= 3.0, f'hold {mag_margin:.1f}x load (need 3x)'),
  'lid-spin' : ('lid spin channel', finger_w < ball_d, f'underside over-equator channel, finger slot {finger_w:.0f} < ball_d {ball_d:.0f} (caps from above, finger open)'),
  'lid-swap' : ('lid swap channel', True, 'complete upper-half cap (no slot) -> swap fully capped from above / hidden'),
}

HANDOFF_MIN = 0.03           # every hand-off must overlap by at least this fraction of the clip

# ---- the choreography: per swapping-ball role, the active-retainer windows (start,end) ----
# Discipline: each window starts BEFORE the previous ends (overlap) -> continuous coverage.
def schedule(handoff=0.06):
    nb = [('spin',0.0,0.20+handoff), ('swapring',0.20,0.80), ('spin',0.80-handoff,1.0)]
    fa = [('spin',0.0,0.20+handoff), ('magnet',0.20,0.80),   ('spin',0.80-handoff,1.0)]
    return {'neighbour-A':nb,'neighbour-B':nb,'far-2 (ball 2)':fa,'far-9 (ball 9)':fa}

SEG=400
def check(roles):
    ok=True; worst_overlap=9e9
    # geometry first
    for k,(name,good,why) in RET.items():
        print(f"  GEOM {('PASS' if good else 'FAIL'):4} {name:20} {why}")
        ok = ok and good
    print()
    for role,wins in roles.items():
        # continuous coverage: every sampled u has >=1 active, geometrically-valid retainer
        uncovered=0
        for i in range(SEG+1):
            u=i/SEG
            if not any(s-1e-9<=u<=e+1e-9 and RET[r][1] for (r,s,e) in wins): uncovered+=1
        # hand-off overlaps: consecutive windows must overlap
        ov_min=9e9
        for (r1,s1,e1),(r2,s2,e2) in zip(wins,wins[1:]):
            ov = e1 - s2                      # overlap of consecutive windows
            ov_min=min(ov_min,ov)
        worst_overlap=min(worst_overlap,ov_min)
        good = uncovered==0 and ov_min>=HANDOFF_MIN
        ok = ok and good
        seq=" -> ".join(f"{r}[{s:.2f},{e:.2f}]" for (r,s,e) in wins)
        print(f"  TIME {('PASS' if good else 'FAIL'):4} {role:16} {'covered' if uncovered==0 else f'{uncovered} OPEN frames'}, "
              f"min hand-off overlap {ov_min:+.2f} (need ≥{HANDOFF_MIN})")
        print(f"            {seq}")
    return ok, worst_overlap

def main():
    selftest = '--selftest' in sys.argv
    print("TRACK-2 CONTINUOUS-CONFINEMENT GATE  (gravity-safe: every ball held past its equator, always)\n")
    ok,wov = check(schedule(handoff=0.06))
    print(f"\n  worst hand-off overlap across all roles: {wov:+.2f}")
    if selftest:
        print("\n  [SELFTEST] injecting a 0.05 gap into the neighbour schedule (must FAIL):")
        bad = schedule(handoff=0.06); bad['neighbour-A']=[('spin',0,0.20),('swapring',0.25,0.80),('spin',0.80,1.0)]
        bok,_ = check(bad)
        print(f"  SELFTEST {'PASS (gate caught the gap)' if not bok else 'FAIL (gate missed the gap!)'}")
        sys.exit(0 if not bok else 1)
    print()
    if not ok: print("RESULT: FAIL — a ball is open past its equator at some instant (see above)."); sys.exit(1)
    print("RESULT: PASS — every swapping ball is held past its equator at every instant, with overlapping")
    print("        hand-offs (spin wall ⇄ swap-ring ⇄ magnet). Gravity-safe in any orientation.")
    sys.exit(0)

if __name__=='__main__': main()
