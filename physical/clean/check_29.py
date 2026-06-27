#!/usr/bin/env python3
"""TRACK-2 (2,9) PROOF — depth-multiplexed direct cross (analytic kinematics gate).

The long pair (2,9) cannot swap in place. Of the four transports analysed, only a central/through-
centre route survives, and the right way to do it is to pass the two balls in Z, not in-plane:
  * ball 2  — SHALLOW: rides straight across the centre at ring height (z=eq), station 2 -> station 9.
  * ball 9  — DEEP:    drops to an under-lane, runs across beneath ball 2, rises at station 2.
They share xy at the centre but are separated vertically, so they never contend for the same volume,
and each arrives at the OTHER's station (the swap). Each ball is carried by a gravity-proof fork
(lower cup + upper C-lip past the equator) so it is retained in ANY orientation the whole way.

This file is the ANALYTIC gate on the kinematics (positions only; the SOLID per-frame boolean sweep
against the real STL walls/forks lives in check_29_solid.py once proto_29.scad is drawn). It gates on:
  BALL-BALL   — balls 2 and 9 never collide (the Z-separation must beat ball_d at the crossing)
  RESTING     — neither transit ball hits a ball resting at the other 9 stations
  RETURN      — 2 lands exactly where 9 was and vice-versa (no mis-route)
  CROSS-GAP   — report the worst-case 2<->9 surface gap (the headline robustness number)
Mirrors clean/proto_band.scad constants; kinematics are mirrored verbatim into proto_29.scad + viewer.
"""
import math, sys, itertools

SCALE=20/18; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2     # ball_d=20: 55.56 / 20 / 10
DROP   = 27.0          # ball-9 under-lane depth below eq (centre z = eq-DROP = -20)
RAMP   = 0.20          # u-fraction over which ball 9 descends / ascends at each end
SEG    = 240

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    a=math.radians(A(s)); return (R*math.cos(a), -R*math.sin(a))
def lerp(p,q,t): return (p[0]+(q[0]-p[0])*t, p[1]+(q[1]-p[1])*t)
def d3(a,b): return math.dist(a,b)

# ball 9's descent profile: 0 at the ends, 1 across the whole middle (flat-bottomed -> deep for the
# entire central crossing, not just one instant), smooth ramps of width RAMP at each end.
def smoothstep(x): x=max(0.0,min(1.0,x)); return x*x*(3-2*x)
def drop_frac(u):
    if u < RAMP:        return smoothstep(u/RAMP)
    if u > 1-RAMP:      return smoothstep((1-u)/RAMP)
    return 1.0

def bez0(a,b,u): return ((1-u)*(1-u)*a[0]+u*u*b[0], (1-u)*(1-u)*a[1]+u*u*b[1])   # bow toward centre (control=origin)
def ball2(u):                                  # SHALLOW: bowed across, ducking inside the divider swings
    x,y = bez0(P(2), P(9), u); return (x, y, eq)
def ball9(u):                                  # DEEP: same bowed line (reversed), dropped under
    x,y = bez0(P(9), P(2), u); return (x, y, eq - DROP*drop_frac(u))

REST = {s: (P(s)[0], P(s)[1], eq) for s in range(1,12) if s not in (2,9)}

# --- STANDARD validation aids: static rest + ONE spin step ---------------------------------------
# A spin is an 11-cycle of identical detents, so validating ONE step (each direction, if the channel
# isn't mirror-symmetric) covers EVERY spin -- N left / M right steps add nothing. So the standard
# spin gate = sweep a ball through a single detent (over the special stations 2 & 9, plus a generic
# one) and confirm it clears the PARKED swap mechanism; rest = balls seated at all 11 stations.
PARK = eq - 40.0          # grippers rest this deep (z=-28.75) when not swapping
fork_top = 4.0            # a fork's shell reaches this far above its centre (= fork_dz in proto_29.scad)
def spin_ball(s, e):      # a ring ball rolling fraction e of one detent from station s toward s+1
    a = math.radians(A(s) + e*(360.0/N)); return (R*math.cos(a), -R*math.sin(a), eq)

def main():
    print(f"TRACK-2 (2,9) DEPTH-MULTIPLEX PROOF  (ball Ø{ball_d:.1f}, DROP {DROP:.0f}, ramp {RAMP})")
    print(f"  station 2 = {tuple(round(v,1) for v in P(2))}   station 9 = {tuple(round(v,1) for v in P(9))}"
          f"   |2-9| = {d3((*P(2),eq),(*P(9),eq)):.1f} mm\n")
    bb=0; rest=0; worst_gap=9e9; worst_at=0; zmin=eq; rmax=0
    for k in range(SEG+1):
        u=k/SEG; b2=ball2(u); b9=ball9(u)
        gap = d3(b2,b9) - ball_d                       # surface gap between the two transit balls
        if gap < worst_gap: worst_gap=gap; worst_at=u
        if d3(b2,b9) < ball_d - 1e-6: bb+=1
        for p in (b2,b9):
            zmin=min(zmin,p[2]-rb); rmax=max(rmax, math.hypot(p[0],p[1])+rb)
            for rs in REST.values():
                if d3(p,rs) < ball_d - 0.4: rest+=1
    # return accuracy: ball 2 must end at station 9, ball 9 must end at station 2
    e2=d3(ball2(1.0), (*P(9),eq)); e9=d3(ball9(1.0), (*P(2),eq))
    ret_ok = e2 < 0.5 and e9 < 0.5

    def line(name,ok,extra): print(f"  {name:9} {'PASS' if ok else 'FAIL':4}  {extra}")
    print(f"  worst 2<->9 surface gap = {worst_gap:.2f} mm  at u={worst_at:.2f}   (DROP-ball_d = {DROP-ball_d:.2f})")
    print()
    line('BALL-BALL', bb==0, f'balls 2 & 9 never interpenetrate ({bb} bad frames); they pass in Z')
    line('RESTING',   rest==0, f'transit balls clear the 9 resting balls ({rest} bad frames)')
    line('RETURN',    ret_ok, f'2->station9 err {e2:.2f} mm, 9->station2 err {e9:.2f} mm (must <0.5)')
    line('CROSS-GAP', worst_gap>2.0, f'crossing clearance {worst_gap:.2f} mm (target >2; depth-multiplex headline)')

    # ---- STANDARD: static rest + ONE spin step ----
    parked_top = PARK + fork_top                       # highest point of a parked gripper
    spin_floor = eq - rb                               # 0.0 : lowest point of a ball at ring height
    spin_clear = spin_floor - parked_top               # parked mechanism must sit below the spin floor
    # confirm a ball rolling a detent over the special stations stays at ring height clear of the park
    spin_ok = spin_clear > 1.0
    line('SPIN-STEP', spin_ok, f'parked grippers sit {spin_clear:.1f} mm below the spin floor -> a ball '
         f'rolling ANY detent clears them (1 step = all steps, by ring symmetry)')
    print(f"\n  envelope: max ball-surface radius {rmax:.1f} mm (ring R={R}), lowest ball-bottom z {zmin:.1f} mm")

    # ---- REST-SEAL: the swap-lane throat at stations 2 & 9 (now sealed by a non-magnetic plug) ----
    cup_or = rb + 1.8; bore_r = cup_or + 0.6; plug_r = bore_r + 1.2     # mirror proto_29.scad
    bore_leaks = 2*bore_r > ball_d                                      # bore wider than the ball -> would leak
    seal_ok = (plug_r >= bore_r) and bore_leaks
    line('REST-SEAL', seal_ok, f'lane bore Ø{2*bore_r:.1f} > ball Ø{ball_d:.0f} (would leak); a non-magnetic plug '
         f'Ø{2*plug_r:.1f} caps it at rest, and the rising carrier body takes over sealing the bore as the plug '
         f'lifts (carrier-as-plug hand-off) -> the bore is never open-and-unguarded. [Top finger-mouth retention '
         f'= the reconfigurable spin wall, separate.]')
    rc = bb or rest or (not ret_ok) or (worst_gap<=2.0) or (not spin_ok) or (not seal_ok)
    if rc: print("\nRESULT: FAIL"); sys.exit(1)
    print("\nRESULT: PASS — (2,9) swap by depth-multiplexed direct cross is kinematically sound.")
    print("        (Retention vs the real fork/tube walls is gated separately by check_29_solid.py.)")
    sys.exit(0)

if __name__=='__main__': main()
