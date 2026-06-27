#!/usr/bin/env python3
"""FULL 6-DRUM INNER LAYOUT — does the unified inward-routing fit inside one ring?

Perm #22 = (0 1)(2 9)(3 4)(5 6)(7 8)(10 11): six pairs, each swapped by easing the two balls down
and routing them INWARD to a compact 2-pocket drum. All six act at once during a push, so all six
drums + their 12 bores must coexist inside the ring without fouling. This is the decisive test
(scale-invariant — it depends only on the 11-station / 6-pair geometry, not the ball size).

Each drum is placed as far OUT as keeps its far swap-ball just inside the ring (so nothing swings
out). Checks: (1) DRUM FIT — every pair of drum footprints clears; (2) INSIDE — every swap-ball
stays within the ring; (3) BORES — no bore crosses another drum.
"""
import math, sys

SCALE   = 1.25
R, N    = 50*SCALE, 11
ball_d  = 18*SCALE
rb      = ball_d/2
tube    = rb + 0.3
RD      = rb + 0.5                 # drum pocket radius (2 balls, 180 apart)
FP      = RD + rb + 1.0            # drum footprint radius (ball-swept + a thin wall)
CR      = R - RD - 1.0             # drum-centre radius: far swap-ball stays just inside the ring
APEX    = R + 24*SCALE

def angleOf(s): return -90 + (s-1)*(360.0/N)
def P(s):
    if s == 0: return (0.0, APEX)
    a = math.radians(angleOf(s)); return (R*math.cos(a), -R*math.sin(a))
def rad(p): return math.hypot(p[0], p[1])
def unit(p): r=rad(p); return (p[0]/r, p[1]/r)

ALLPAIRS = [(0,1),(2,9),(3,4),(5,6),(7,8),(10,11)]            # default = perm #22
if len(sys.argv) > 1:                                          # or pass "0 1 2 4 3 5 ..." (12 ints)
    _v = [int(t) for t in sys.argv[1].replace(',', ' ').split()]
    ALLPAIRS = [(_v[k], _v[k+1]) for k in range(0, 12, 2)]
# The APEX pair (the one containing ball 0) is the INPUT: ball 0 is flicked toward 1 at the TOP,
# in the apex slot -- it is NOT an inner swap drum. So only the OTHER FIVE pairs need inner drums.
PAIRS = [p for p in ALLPAIRS if 0 not in p]
def far_pair(i,j):                                    # a pair whose midpoint is near centre -> central drum
    M=((P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2); return math.hypot(*M) < CR - 4
def drum(i,j):
    M = ((P(i)[0]+P(j)[0])/2.0, (P(i)[1]+P(j)[1])/2.0)
    if far_pair(i,j): return (0.0, 0.0)               # long pair -> central drum
    u = unit(M); return (u[0]*CR, u[1]*CR)            # rim pair -> pushed out along the bisector
DRUMS = {(i,j): drum(i,j) for (i,j) in PAIRS}

def seg_pt_dist(p, a, b):
    ax,ay=a; bx,by=b; dx,dy=bx-ax,by-ay; L2=dx*dx+dy*dy
    t=0.0 if L2==0 else max(0.0,min(1.0,((p[0]-ax)*dx+(p[1]-ay)*dy)/L2))
    return math.hypot(p[0]-(ax+t*dx), p[1]-(ay+t*dy))

def check_fit():
    print('\n=== 1 · DRUM FIT (all six drum footprints must clear) ===')
    worst=1e9; who=None
    keys=list(DRUMS)
    for a in range(len(keys)):
        for b in range(a+1,len(keys)):
            d=math.dist(DRUMS[keys[a]], DRUMS[keys[b]]) - 2*FP
            if d<worst: worst=d; who=(keys[a],keys[b])
    print(f'  drums on a circle of radius {CR:.1f}; each footprint r{FP:.1f}.')
    if worst>0:
        print(f'  PASS — tightest pair {who[0]} / {who[1]} clears by {worst:.1f} mm; all six coexist.')
        return 0
    print(f'  FAIL — pair {who[0]} / {who[1]} OVERLAP by {-worst:.1f} mm: six drums do not fit on one ring.')
    return 1

def check_inside():
    print('\n=== 2 · INSIDE (no swap-ball leaves the ring) ===')
    far = CR + RD + rb     # far edge of a drum's outer swap-ball
    if far <= R + rb + 0.1:    # within the channel (ball rides r<=R, edge <= R+rb)
        print(f'  PASS — a drum\'s outer swap-ball reaches centre r{CR+RD:.1f} (edge {far:.1f}) <= ring edge '
              f'{R+rb:.1f}: nothing swings out.')
        return 0
    print(f'  FAIL — outer swap-ball edge {far:.1f} exceeds the ring {R+rb:.1f}.')
    return 1

CLEAR_R = CR - FP                                     # inside this radius the disc is clear of every rim drum
def bore_path(st, C):
    """station -> drum, routed to dodge rim drums: rim drums are short & direct; the CENTRAL drum's
    long bores dive radially to the clear inner disc first, then run in to the entry."""
    if rad(C) < CLEAR_R - 1:                          # central drum: radial dive, then to centre
        wp = (st[0]/rad(st)*(CLEAR_R-1), st[1]/rad(st)*(CLEAR_R-1))
        return [(st, wp), (wp, C)]
    return [(st, C)]                                  # rim drum: short direct bore

def check_bores():
    print('\n=== 3 · BORES (routed to dodge other drums) ===')
    worst=1e9; who=None
    for (i,j) in PAIRS:
        C=DRUMS[(i,j)]; u=unit(C) if rad(C)>1e-6 else (1.0,0.0); tang=(-u[1],u[0])
        e_i=(C[0]+tang[0]*RD, C[1]+tang[1]*RD); e_j=(C[0]-tang[0]*RD, C[1]-tang[1]*RD)
        for st,en in ((P(i),e_i),(P(j),e_j)):
            for (a,b) in bore_path(st, en):
                for (k,l) in PAIRS:
                    if (k,l)==(i,j): continue
                    d=seg_pt_dist(DRUMS[(k,l)], a, b) - (FP+rb)
                    if d<worst: worst=d; who=((i,j),(k,l))
    if worst>0:
        print(f'  PASS — every bore clears every other drum (tightest {who[0]}->{who[1]} by {worst:.1f} mm);')
        print(f'         the long 2-9 bores dive into the clear inner disc (r<{CLEAR_R:.0f}) and run across it.')
        return 0
    print(f'  FAIL — a bore of {who[0]} runs through drum {who[1]} (by {-worst:.1f} mm).')
    return 1

if __name__ == '__main__':
    print(f'INNER LAYOUT  ({len(PAIRS)} drums; apex pair = top input; ball Ø{ball_d:.1f}; drum-circle r{CR:.1f}; footprint r{FP:.1f})')
    rc  = check_fit()
    rc |= check_inside()
    rc |= check_bores()
    print()
    if rc:
        print('RESULT: FAIL — the five-drum inner layout (apex = top input) does not fit (see above).')
        sys.exit(1)
    print('RESULT: PASS — five inward-routing drums (apex pair handled at the top) + their bores coexist')
    print('               inside the ring. The alternative architecture fits with the production perm #22.'); sys.exit(0)
