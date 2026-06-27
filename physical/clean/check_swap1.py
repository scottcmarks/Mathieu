#!/usr/bin/env python3
"""ROTARY POCKET — one rim pair, checked against the REAL band (incl. the outer wall).

This is where building it for real earns its keep. The obvious rim-pair swap is a 2-cell pocket
rotor turning 180 about the pair midpoint M. But M sits at radius ~R, and a rigid 180 turn sends
ONE of the two pockets bulging OUTWARD by the half-chord — straight through the outer wall, out
of the toy. (Either turn direction; one ball always goes out.) So:

  A · NAIVE 180 about M        -> measured here, REJECTED (a ball leaves the ring).
  B · INWARD ROUTING to a drum -> the same fix the long 2-9 pair already uses: ease down, route
       the two balls INWARD to a small 2-pocket drum just inside the pair, swap, route back.
       Nothing ever goes outward; everything stays inside the ring, capped, no gravity.
Exit non-zero only if the ADOPTED scheme (B) fails.
"""
import math, sys

SCALE   = 1.25
R, N    = 50*SCALE, 11
ball_d  = 18*SCALE
rb      = ball_d/2
eq      = ball_d/2
tube    = rb + 0.3
wall_t  = 1.5*SCALE
WALL_IN = R + tube                 # inner face of the outer band wall (the ball must stay inside this)
spin_top= eq + math.sqrt(tube*tube - rb*rb) + 1.5
DELTA_F = spin_top - eq
EASE    = DELTA_F + 1.5
DELTA_C = EASE - DELTA_F + 2.0
SEG     = 120

def angleOf(s): return -90 + (s-1)*(360.0/N)
def P(s):
    a = math.radians(angleOf(s)); return (R*math.cos(a), -R*math.sin(a))
def rot2(p, c, ang):
    co, si = math.cos(ang), math.sin(ang); dx, dy = p[0]-c[0], p[1]-c[1]
    return (c[0]+dx*co-dy*si, c[1]+dx*si+dy*co)
def rad(p): return math.hypot(p[0], p[1])

I, J = 3, 4
A, B = P(I), P(J)
M    = ((A[0]+B[0])/2.0, (A[1]+B[1])/2.0)

def check_naive():
    print('\n=== A · NAIVE 180 about M (rejected) ===')
    mr = 0.0
    for k in range(SEG+1):
        u = k/SEG
        for s in (A, B):
            p = rot2(s, M, math.pi*u); mr = max(mr, rad(p))
    out = mr + rb
    print(f'  rim pair {I}-{J}: midpoint M at radius {rad(M):.1f}; a 180 turn pushes a ball centre out to')
    print(f'  radius {mr:.1f} mm (edge {out:.1f}) — the outer wall is at {WALL_IN:.1f} mm. The ball misses the')
    print(f'  toy by {out-WALL_IN:.1f} mm.  >>> REJECTED: a rigid in-plane rotor can\'t swap an adjacent pair.')
    return 0   # informational; the design uses B

# --- B: inward routing to a compact drum just inside the pair (same idea as 2-9) ---
RD   = rb + 1.0                                          # drum pocket radius
Cm   = rad(M)
C    = (M[0]*(Cm-(rb+4))/Cm, M[1]*(Cm-(rb+4))/Cm)        # drum centre, pulled inward off M
mh   = math.atan2(M[1], M[0])                            # M's azimuth
that = (-math.sin(mh), math.cos(mh))                     # tangential unit (entries sit across the drum)
ENTRYI = (C[0]+that[0]*RD, C[1]+that[1]*RD)
ENTRYJ = (C[0]-that[0]*RD, C[1]-that[1]*RD)              # 180 from ENTRYI, so one drum turn swaps
def lerp(p,q,t): return (p[0]+(q[0]-p[0])*t, p[1]+(q[1]-p[1])*t)
def routed(which, u):
    home, hen = (A, ENTRYI) if which==0 else (B, ENTRYJ)
    away, aen = (B, ENTRYJ) if which==0 else (A, ENTRYI)
    if u <= 0.08: return (*home, eq - EASE*(u/0.08))                          # ease down
    if u <= 0.32: t=(u-0.08)/0.24; return (*lerp(home,hen,t), eq-EASE)        # route inward
    if u <= 0.68: t=(u-0.32)/0.36; x,y=rot2(hen,C,math.pi*t); return (x,y,eq-EASE)   # drum 180
    if u <= 0.92: t=(u-0.68)/0.24; return (*lerp(aen,away,t), eq-EASE)        # route outward
    return (*away, eq - EASE*((1.0-u)/0.08))                                  # ease up
def fixed_caps(z):   return (eq-DELTA_F) <= z <= eq+0.1
def ceiling_caps(z): return (eq-EASE-0.1) <= z <= (eq-EASE+DELTA_C)

def check_inward():
    print('\n=== B · INWARD ROUTING to a drum (adopted) ===')
    others=[P(k) for k in range(1,N+1) if k not in (I,J)]
    maxr=0.0; bad=0; near_other=1e9
    for k in range(SEG+1):
        u=k/SEG; b0=routed(0,u); b1=routed(1,u)
        maxr=max(maxr, rad(b0), rad(b1))
        if math.dist(b0,b1) < 2*rb-0.4: bad+=1                       # the two never collide
        for b in (b0,b1):
            if not (fixed_caps(b[2]) or ceiling_caps(b[2])): bad+=1  # always capped
            for q in others: near_other=min(near_other, math.dist((b[0],b[1]),q))
    inside = maxr + rb
    ok = bad==0 and inside <= WALL_IN + 0.1 and near_other > rb+0.5
    if ok:
        print(f'  ease down, route the two balls inward to a drum at radius {rad(C):.1f}, turn 180, route back.')
        print(f'  PASS — ball centres stay within radius {maxr:.1f} (edge {inside:.1f} <= wall {WALL_IN:.1f}): nothing')
        print(f'         leaves the ring. Balls never collide, stay capped throughout, and clear every other')
        print(f'         station by {near_other:.1f} mm. Same shallow {EASE:.1f} mm ease as the band proof.')
        return 0
    print(f'  FAIL — bad={bad}, edge={inside:.1f} vs wall {WALL_IN:.1f}, nearest-other={near_other:.1f}.')
    return 1

if __name__ == '__main__':
    print(f'RIM-PAIR ROTARY POCKET  (pair {I}-{J}; ball Ø{ball_d:.1f}; outer wall r{WALL_IN:.1f})')
    check_naive()
    rc = check_inward()
    print()
    if rc: print('RESULT: FAIL — the inward-routed rim swap does not close.'); sys.exit(1)
    print('RESULT: PASS — the naive in-plane rotor is rejected (ball exits the ring); the rim pair swaps by')
    print('               the SAME inward-routing-to-a-drum the 2-9 pair uses. The architecture unifies:')
    print('               EVERY pair eases down and routes inward — none ever swings a ball outward.'); sys.exit(0)
