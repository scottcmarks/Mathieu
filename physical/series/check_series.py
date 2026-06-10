#!/usr/bin/env python3
"""3-D interference checker for the series toy — the design gate.

Two regimes, because the mechanism has to do contradictory things:
  PUSH  — parts rise to BALL level to carry the balls through perm #22.
  SPIN  — parts must CLEAR the balls so the ring is free to rotate (a ball can't
          spin if it's pinned). So at rest every part must sit below the balls.

We model balls as spheres (r=rb) and mechanism parts as primitive solids
(cylinders for gears, boxes for racks/shuttles), with transforms = f(u) that
mirror series/viewer.html. At each sampled stage we report:
  * ball <-> ball penetration   (does the over/under z-separation actually work?)
  * ball <-> part penetration   (push: through-collisions; spin: pinning)

Exit non-zero on FAIL so it can gate the build.
"""
import math, sys

# ---- geometry constants (mirror plate.scad / viewer.html) ----
R, N, ball_d = 50.0, 11, 18.0
rb   = ball_d/2                       # 9 — ball radius
eq   = ball_d/2                       # 9 — ball-centre height on the ring
tube = ball_d/2 + 0.5
nbchord = 2*R*math.sin(math.pi/N)     # ~28.17
underZ  = -11.0
GZ      = -9.0                        # gear-layer origin z (world = GZ + local)
RET_SAG = 12.0                        # ball-1 return bows this far in +x (< chord/2=14, clears the plunger column)
Sx      = nbchord
SEG_PUSH = 24                         # push samples (u = 0..1)
SEG_SPIN = 132                        # spin samples around the ring (~ every 2.7°)
TOL      = 0.4                        # ignore penetrations shallower than this (mm)

def angleOf(s): return -90 + (s-1)*(360.0/N)
def P(s):
    if s == 0: return (0.0, R+nbchord)
    a = math.radians(angleOf(s));  return (R*math.cos(a), -R*math.sin(a))

# ---- ball kinematics ----------------------------------------------------------
NEIGH = [(3,4),(5,6),(7,8),(10,11)]
PAIRS = [(0,1),(2,9)] + NEIGH

def arcpt(a, b, sag, e):
    c = math.hypot(b[0]-a[0], b[1]-a[1]); arcR = (c*c/4+sag*sag)/(2*sag)
    ux,uy = (b[0]-a[0])/c,(b[1]-a[1])/c; nx,ny = -uy,ux
    mx,my = (a[0]+b[0])/2,(a[1]+b[1])/2
    cx,cy = mx-(arcR-sag)*nx, my-(arcR-sag)*ny
    a0 = math.atan2(a[1]-cy, a[0]-cx); daw = math.atan2(b[1]-cy, b[0]-cx)-a0
    daw -= 2*math.pi*round(daw/(2*math.pi)); an = a0+daw*e
    return (cx+arcR*math.cos(an), cy+arcR*math.sin(an))

def dip(u):                                          # eq -> underZ -> eq (smooth, immediate)
    return eq - (eq-underZ)*math.sin(math.pi*u)
def lin(p, q): return lambda e: (p[0]+(q[0]-p[0])*e, p[1]+(q[1]-p[1])*e)

# ball-1 return: a +x-bowed arc P1->P0 so it leaves the central plunger column at once
def ret1(e):  return arcpt(P(0), P(1), RET_SAG, 1-e)
# ball-2 over / ball-9 under share the 2-9 arc footprint
def arc29(e): return arcpt(P(2), P(9), 14, e)

def ball_positions_push(u):
    """world (x,y,z) for every ball 0..11 at push fraction u."""
    pos = {}
    for (i,j) in NEIGH:
        A,B = P(i),P(j); M = ((A[0]+B[0])/2,(A[1]+B[1])/2)
        def orb(o):
            t = -u*math.pi; c,s = math.cos(t),math.sin(t)
            return (M[0]+o[0]*c-o[1]*s, M[1]+o[0]*s+o[1]*c, eq)
        pos[i] = orb((A[0]-M[0],A[1]-M[1])); pos[j] = orb((B[0]-M[0],B[1]-M[1]))
    pos[0] = (*lin(P(0),P(1))(u), eq)                # 0 slides in on top
    pos[1] = (*ret1(u), dip(u))                       # 1 ducks under (bowed +x), resurfaces at P0
    pos[2] = (*arc29(u), eq)                           # 2 over-arc, on top
    pos[9] = (*arc29(1-u), dip(u))                    # 9 under-arc, ducks
    return pos

# ---- mechanism part transforms (mirror viewer build()) ------------------------
# Each part: ('cyl', center_xy(u), r, z0_world, z1_world) or
#            ('box', center_xy(u), hx, hy, z0_world, z1_world)
m29 = ((P(2)[0]+P(9)[0])/2, (P(2)[1]+P(9)[1])/2)

def parts(u, engaged=True):
    """Mechanism solids at push fraction u.

    engaged=True  -> PUSH regime: carrying shuttles ride at ball level.
    engaged=False -> SPIN/REST regime: every carrying part retracts to gear-layer
                     depth so the ring is free to rotate.
    """
    sh_over  = eq      if engaged else GZ      # over-shuttle height (carries ball 2)
    sh_under = underZ  if engaged else GZ-3    # under-shuttle height (carries 1 & 9)
    L = []
    for (i,j) in NEIGH:
        A,B = P(i),P(j)
        L.append(('cyl', ((A[0]+B[0])/2,(A[1]+B[1])/2), 10.0, GZ-2.5, GZ+2.5))  # carrier gear (hub low)
    # input pinion OFF the +y axis (-x side), so ball 1's column is clear
    L.append(('cyl', (-13,46),                9.0, GZ-3.0, GZ+3.0))
    # 0-plunger rack: rides ABOVE the balls (pushes ball 0 via a down-prong), so it
    # never shares ball 1's duck column; trails behind ball 0
    L.append(('box', (0, (R+nbchord)+6-Sx*u), 3.0,7.0, eq+11, eq+15))
    # carrying shuttles (ride at ball level when engaged; carried contact is expected)
    L.append(('box', ret1(u),  4.0,4.0, sh_under-2.5, sh_under+2.5))   # shuttle 1 (under, +x bow)
    L.append(('box', arc29(u), 4.0,4.0, sh_over-2.5,  sh_over+2.5))    # shuttle 2 (over)
    L.append(('box', arc29(1-u),4.0,4.0, sh_under-2.5, sh_under+2.5))  # shuttle 9 (under)
    # 2-9 drivetrain — RIM-ROUTED (radius ~40) at gear-layer depth, off the central arc:
    #   compound at the south rim -> east/west idlers -> seat-end pinions at P2 / P9
    L.append(('cyl', (0,-40),                13.0, GZ-2.0, GZ+2.0))    # compound (south rim)
    L.append(('cyl', (32,-34),                9.0, GZ-2.5, GZ+2.5))    # east idler
    L.append(('cyl', (-32,-34),               9.0, GZ-2.5, GZ+2.5))    # west idler
    L.append(('cyl', P(2),                    7.0, GZ-3.0, GZ+3.0))    # seat pinion @2
    L.append(('cyl', P(9),                    7.0, GZ-3.0, GZ+3.0))    # seat pinion @9
    return L

PART_NAMES = ['carrier34','carrier56','carrier78','carrier10-11',
              'input-pinion','top-rack','shuttle1','shuttle2','shuttle9',
              'compound','idlerE','idlerW','seat-pinion2','seat-pinion9']

# ---- primitive intersection: penetration depth (>0 means overlap) -------------
def pen_sphere_cyl(c, part):
    _, (cx,cy), r, z0, z1 = part
    dr = max(0.0, math.hypot(c[0]-cx, c[1]-cy) - r)
    dz = max(0.0, z0 - c[2], c[2] - z1)
    return rb - math.hypot(dr, dz)

def pen_sphere_box(c, part):
    _, (cx,cy), hx, hy, z0, z1 = part
    dx = max(0.0, abs(c[0]-cx) - hx)
    dy = max(0.0, abs(c[1]-cy) - hy)
    dz = max(0.0, z0 - c[2], c[2] - z1)
    return rb - math.sqrt(dx*dx + dy*dy + dz*dz)

def pen(c, part):
    return pen_sphere_cyl(c, part) if part[0]=='cyl' else pen_sphere_box(c, part)

# ---- the two regime checks ----------------------------------------------------
def carried_part(ball, part_name):
    """parts a ball is *supposed* to ride on (contact expected, not a clash)."""
    return ((ball==0 and part_name=='top-rack') or
            (ball==1 and part_name=='shuttle1') or
            (ball==2 and part_name=='shuttle2') or
            (ball==9 and part_name=='shuttle9'))

def check_push():
    clashes = []
    for k in range(SEG_PUSH+1):
        u = k/SEG_PUSH
        pos = ball_positions_push(u); pl = parts(u, engaged=True)
        balls = sorted(pos)
        # ball <-> ball
        for a in range(len(balls)):
            for b in range(a+1, len(balls)):
                ca, cb = pos[balls[a]], pos[balls[b]]
                d = math.dist(ca, cb); p = 2*rb - d
                if p > TOL:
                    clashes.append((u, f'ball{balls[a]}', f'ball{balls[b]}', p))
        # ball <-> part
        for s in balls:
            for idx, part in enumerate(pl):
                nm = PART_NAMES[idx]
                p = pen(pos[s], part)
                if p > TOL and not carried_part(s, nm):
                    clashes.append((u, f'ball{s}', nm, p))
    return clashes

def check_spin():
    """Sweep a ball through every ring position; the rest mechanism must clear it."""
    clashes = []
    pl = parts(0.0, engaged=False)
    for k in range(SEG_SPIN):
        a = math.radians(-90 + k*(360.0/SEG_SPIN))
        c = (R*math.cos(a), -R*math.sin(a), eq)
        for idx, part in enumerate(pl):
            nm = PART_NAMES[idx]
            p = pen(c, part)
            if p > TOL:
                clashes.append((math.degrees(a) % 360, 'ring-ball', nm, p))
    return clashes

def report(title, clashes, stage_label):
    print(f'\n=== {title} ===')
    if not clashes:
        print('  PASS — no interference.'); return 0
    worst = {}
    for st, a, b, p in clashes:
        key = (a, b)
        if key not in worst or p > worst[key][1]:
            worst[key] = (st, p)
    print(f'  FAIL — {len(worst)} distinct clashing pairs (worst penetration each):')
    for (a, b), (st, p) in sorted(worst.items(), key=lambda kv: -kv[1][1]):
        print(f'    {a:>10} ∩ {b:<14} {p:5.1f} mm  (at {stage_label}={st:.2f})')
    return 1

if __name__ == '__main__':
    rc  = report('PUSH (0-ball push, all stages)', check_push(), 'u')
    rc |= report('SPIN (ring free to rotate?)',    check_spin(), 'deg')
    print()
    if rc: print('RESULT: FAIL — interference present (see above).'); sys.exit(1)
    print('RESULT: PASS'); sys.exit(0)
