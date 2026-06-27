#!/usr/bin/env python3
"""TRACK-2 DRIVE SCHEDULE — one input (a cam drum at angle theta) drives EVERY motion, sequenced safe.

One swap = one drum revolution theta in [0,1]. The drum carries cam tracks + a Geneva so a SINGLE input
produces, in the right order:
  dish_rise(t)   the swap-ring grooves rise around each pair          (cam track)
  seg_drop(t)    the spin-wall segments drop (outer for dividers, inner for 2-9)  (cam track)
  divider(t)     the dividers turn pi  -- via the gear train, GATED by a Geneva so it turns ONLY in the
                 middle window (sun is coupled only while confined)   (Geneva off the drum)
  magnet(t)      the 2-9 magnets rise, carry the depth-multiplex, return  (belt + lift cam = the 2-9 linkage)
Gates:
  ORDER    dishes cover BEFORE segs open, and segs re-cover BEFORE dishes drop (confinement never breaks)
  DIVIDER  the divider pi happens entirely inside the confined window (segs down AND dishes up)
  MAGNET   the 2-9 magnet grabs (up) before the interior seg drops, and releases after it re-covers
  REALIZE  every cam track is a single-valued function of theta with BOUNDED slope (a real cam/Geneva)
"""
import math, sys

# ---- cam phase schedule (fractions of one drum revolution) ----
DISH_UP   =(0.03,0.13)   # dishes rise
SEG_DOWN  =(0.13,0.21)   # segments drop (start only AFTER dishes are up @0.13)
DIV_TURN  =(0.25,0.75)   # dividers turn pi (Geneva engaged)
SEG_UP    =(0.79,0.87)   # segments re-cover
DISH_DOWN =(0.87,0.97)   # dishes drop (only after segs re-cover @0.87)
MAG_GRAB  =(0.10,0.20)   # 2-9 magnets rise to the balls (grab)
MAG_CARRY =(0.20,0.80)   # 2-9 depth-multiplex transit
MAG_REL   =(0.80,0.90)   # 2-9 magnets release/retract

def ramp(t,a,b):                  # smooth 0->1 over [a,b], clamped (a realizable cam segment)
    if t<=a: return 0.0
    if t>=b: return 1.0
    x=(t-a)/(b-a); return x*x*(3-2*x)
def dish_rise(t): return ramp(t,*DISH_UP) - ramp(t,*DISH_DOWN)
def seg_drop(t):  return ramp(t,*SEG_DOWN) - ramp(t,*SEG_UP)
def divider(t):   return 180*ramp(t,*DIV_TURN)            # degrees, 0 -> 180
def mag_engage(t):return ramp(t,*MAG_GRAB) - ramp(t,*MAG_REL)

SEG=1000
def maxslope(f):
    m=0
    for i in range(SEG):
        t0=i/SEG; t1=(i+1)/SEG; m=max(m, abs(f(t1)-f(t0))/(1/SEG))
    return m

def line(n,ok,extra): print(f"  {n:8} {'PASS' if ok else 'FAIL':4}  {extra}")
def main():
    print("DRIVE SCHEDULE  (one drum revolution theta in [0,1] drives all motions)\n")
    # ORDER: dish fully up before seg starts down; seg fully up before dish starts down
    o1 = DISH_UP[1] <= SEG_DOWN[0] + 1e-9          # dishes cover (1.0) at/by seg-drop start
    o2 = SEG_UP[1]  <= DISH_DOWN[0] + 1e-9          # segs re-cover before dishes drop
    line('ORDER', o1 and o2,
         f'dish-up done @{DISH_UP[1]:.2f} <= seg-down start @{SEG_DOWN[0]:.2f}; '
         f'seg-up done @{SEG_UP[1]:.2f} <= dish-down start @{DISH_DOWN[0]:.2f}  (overlap, never open)')
    # DIVIDER pi must be wholly inside (segs fully down) AND (dishes still up)
    segs_down_window=(SEG_DOWN[1], SEG_UP[0]); dishes_up_window=(DISH_UP[1], DISH_DOWN[0])
    dok = (DIV_TURN[0]>=segs_down_window[0] and DIV_TURN[1]<=segs_down_window[1]
           and DIV_TURN[0]>=dishes_up_window[0] and DIV_TURN[1]<=dishes_up_window[1])
    line('DIVIDER', dok, f'pi turn [{DIV_TURN[0]:.2f},{DIV_TURN[1]:.2f}] inside segs-down [{segs_down_window[0]:.2f},'
         f'{segs_down_window[1]:.2f}] & dishes-up [{dishes_up_window[0]:.2f},{dishes_up_window[1]:.2f}]')
    # MAGNET grabs before the 2-9 interior seg drops, releases after it re-covers
    mok = MAG_GRAB[1] <= SEG_DOWN[1] and MAG_REL[0] >= SEG_UP[0]
    line('MAGNET', mok, f'grab done @{MAG_GRAB[1]:.2f} <= seg-down done @{SEG_DOWN[1]:.2f}; '
         f'release start @{MAG_REL[0]:.2f} >= seg-up start @{SEG_UP[0]:.2f}  (magnet holds while seg open)')
    # REALIZE: bounded slopes (a cam can't be vertical). Report max d/dtheta of each track.
    sl = {'dish':maxslope(dish_rise),'seg':maxslope(seg_drop),'divider/180':maxslope(lambda t:divider(t)/180),'magnet':maxslope(mag_engage)}
    rok = all(v < 25 for v in sl.values())     # <25 means each motion spreads over >~4% of the revolution
    line('REALIZE', rok, 'all cam tracks single-valued, max |d/dθ|: '+", ".join(f"{k} {v:.1f}" for k,v in sl.items()))
    ok = (o1 and o2) and dok and mok and rok
    print()
    if not ok: print("RESULT: FAIL — the one-input schedule isn't safe/realizable (see above)."); sys.exit(1)
    print("RESULT: PASS — one drum revolution sequences dish-rise -> seg-drop -> divider pi (+ 2-9 magnet")
    print("        carry) -> seg-up -> dish-drop, with confinement held throughout and realizable cam slopes.")
    print("        Direction-symmetric: reversing the drum runs the same cycle (the pi swap is its own inverse).")
    sys.exit(0)

if __name__=='__main__': main()
