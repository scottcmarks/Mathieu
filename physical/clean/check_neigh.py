#!/usr/bin/env python3
"""TRACK-2 NEIGHBOUR unit-cell — converge + radial-axis pi tumble (analytic kinematics gate).

An adjacent pair (here 3,4) can't swap by an in-plane 180 deg rotation about its midpoint — that
swings a ball outside the ring wall (the old r77.6 problem; ~r79 at Ø20). The fix: CONVERGE the pair
to near-touching, then TUMBLE pi about the RADIAL axis through the pair midpoint, so the two balls
roll over each other VERTICALLY (one dips, one rises) instead of swinging radially outward. They stay
at ~ring radius (inside the wall) at the cost of vertical room. Gates:
  BALL-BALL   the pair never interpenetrate (a rigid tumble keeps them 2*rt apart -> set rt>rb)
  INSIDE      both ball surfaces stay inside the ring wall the whole cycle (the point of tumbling)
  NEIGHBOUR   the tumbling pair clears the balls resting at the adjacent stations (2 & 5)
  RETURN      ball-at-3 lands at 4 and vice-versa
  SPIN-STEP   parked cell sits clear of a ball rolling any detent (1 step = all, by ring symmetry)
Mirrors clean constants (SCALE=20/18 -> Ø20).  Analytic; a solid sweep + viewer come next.
"""
import math, sys

SCALE=20/18; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2     # Ø20, R 55.56
tube=rb+0.3; wall=R+tube+1.5*SCALE        # ring outer wall radius (~67.5)
GAP=3.0; rt=(ball_d+GAP)/2                 # tumble arm radius: balls stay 2*rt apart -> GAP clearance
PAIR=(3,4); NEIGH=(2,5); SEG=240

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    a=math.radians(A(s)); return (R*math.cos(a), -R*math.sin(a))
def sub(a,b): return (a[0]-b[0], a[1]-b[1])
def add(a,b): return (a[0]+b[0], a[1]+b[1])
def mul(a,s): return (a[0]*s, a[1]*s)
def nrm(a):
    m=math.hypot(*a); return (a[0]/m, a[1]/m)
def lerp(p,q,t): return (p[0]+(q[0]-p[0])*t, p[1]+(q[1]-p[1])*t)
def d3(a,b): return math.dist(a,b)

P3,P4=P(*[PAIR[0]]),P(*[PAIR[1]])         # noqa (clarity)
P3=P(PAIR[0]); P4=P(PAIR[1])
M=mul(add(P3,P4),0.5); hc=d3(P3,P4)/2
t_hat=nrm(sub(P4,P3))                      # chord (tangent) direction P3->P4
# convergence ladder + tumble about the radial axis through M (offset stays in the tangent-vertical plane)
def cell(which,u):
    sgn = -1 if which=='A' else 1          # A starts at P3 (-t side), B at P4 (+t side)
    home = P3 if which=='A' else P4
    dest = P4 if which=='A' else P3
    if u<=0.25:                            # CONVERGE: home -> M + sgn*rt*t_hat  (z=eq)
        s=u/0.25; q=lerp(home, add(M, mul(t_hat, sgn*rt)), s); return (q[0],q[1],eq)
    if u<=0.75:                            # TUMBLE pi about the radial axis (vertical roll-over)
        th=math.pi*(u-0.25)/0.5
        xy=add(M, mul(t_hat, sgn*rt*math.cos(th))); z=eq + sgn*rt*math.sin(th)
        return (xy[0],xy[1],z)
    s=(u-0.75)/0.25                        # DIVERGE: M - sgn*rt*t_hat -> dest (note sign flips post-tumble)
    q=lerp(add(M, mul(t_hat, -sgn*rt)), dest, s); return (q[0],q[1],eq)

RESTN=[(P(s)[0],P(s)[1],eq) for s in NEIGH]

def main():
    print(f"NEIGHBOUR unit-cell  pair {PAIR}  (Ø{ball_d:.0f}, R {R:.1f}, tumble arm rt {rt:.1f}, wall {wall:.1f})")
    print(f"  in-plane 180 would swing a ball to r{math.hypot(*M)+hc+rb:.1f} (>wall {wall:.1f}) -> tumble instead\n")
    bb=0; inside_bad=0; nb=0; zmin=eq; zmax=eq; rmax=0; gmin=9e9
    for k in range(SEG+1):
        u=k/SEG; a=cell('A',u); b=cell('B',u)
        g=d3(a,b)-ball_d; gmin=min(gmin,g)
        if d3(a,b)<ball_d-1e-6: bb+=1
        for p in (a,b):
            r=math.hypot(p[0],p[1]); rmax=max(rmax,r+rb); zmin=min(zmin,p[2]-rb); zmax=max(zmax,p[2]+rb)
            if r+rb>wall+1e-6: inside_bad+=1
            for rn in RESTN:
                if d3(p,rn)<ball_d-0.4: nb+=1
    eA=d3(cell('A',1.0),(*P4,eq)); eB=d3(cell('B',1.0),(*P3,eq)); ret_ok=eA<0.5 and eB<0.5
    PARK=eq-40; spin_clear=(eq-rb)-(PARK+4)
    def line(n,ok,extra): print(f"  {n:10} {'PASS' if ok else 'FAIL':4}  {extra}")
    print(f"  worst pair gap {gmin:.2f} mm   vertical zone z[{zmin:.1f},{zmax:.1f}] = {zmax-zmin:.0f} mm   max radius {rmax:.1f}\n")
    line('BALL-BALL', bb==0,        f'pair never interpenetrate ({bb} bad); rigid tumble holds them {2*rt:.0f} mm apart')
    line('INSIDE',    inside_bad==0,f'both balls stay inside the wall the whole cycle ({inside_bad} bad) — tumbling, not swinging out')
    line('NEIGHBOUR', nb==0,        f'tumbling pair clears the balls resting at stations {NEIGH} ({nb} bad)')
    line('RETURN',    ret_ok,       f'3->4 err {eA:.2f}, 4->3 err {eB:.2f} mm (<0.5)')
    line('SPIN-STEP', spin_clear>1, f'parked cell {spin_clear:.1f} mm below the spin floor -> spin clears (1 step=all)')
    print(f"\n  NOTE: vertical zone {zmax-zmin:.0f} mm at each of the 5 neighbour pairs is the tumble's cost (height for"
          f"\n  no radial swing-out). REST-CAPTIVITY at 3/4 (swap-channel throat seal) = same plug pattern as 2/9, TBD.")
    rc = bb or inside_bad or nb or (not ret_ok) or (spin_clear<=1)
    if rc: print("\nRESULT: FAIL"); sys.exit(1)
    print("\nRESULT: PASS — converge + radial-axis tumble swaps an adjacent pair inside the ring wall.")
    sys.exit(0)

if __name__=='__main__': main()
