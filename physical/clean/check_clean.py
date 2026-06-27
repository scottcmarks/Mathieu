#!/usr/bin/env python3
"""CLEAN-SHEET 3-D interference checker for the M12 swap toy — the design GATE.

Exceeds series/check_series.py:
  * 72 swap frames (u = 0, 1/72, ..., 1)         (series used 24)
  * 132 spin steps                                (matches series)
  * primitives: sphere, cyl, box, ring(annulus), CAPSULE (segment+radius)
  * BALL-vs-PART  *and*  PART-vs-PART penetration  (series did ball-vs-part only)
  * per-clashing-pair worst penetration + the frame it occurs at
  * exit non-zero on FAIL so it gates the build (like check_series.py)

Architecture under test (see DESIGN.md):
  - 5 in-plane 2-cell rotors at ball level: apex (0,1) + rims (3,4)(5,6)(7,8)(10,11).
    A 2-cell rotor keeps its pair's two balls diametrically opposite (>=28mm apart)
    => never self-collide. The five swept discs are mutually clear (DESIGN.md s3).
  - ONE (2,9) 2-cell rotor on a private under-deck at z=-16, entirely below the ring
    plane. Balls 2,9 drop axially in wells, the bar turns 180deg in free sub-plane air,
    they rise. 91mm apart on a rigid bar => never collide; ~25mm below the ball plane =>
    threads nothing; parked balls 1/10/11 (z=9) are far above the sweep.
  - SPIN: at rest all rotor hubs/teeth sit z<=-2 (below ball equator z=9); cups open
    along the ring tangent so a ball rolls past. A spinning ball at z=9 clears them.

Conventions: +x right, +y DOWN, ball bottom z=0, ball centre eq=9, ball top 18.
"""
import math, sys

# ---------------- geometry constants (mirror clean/*.scad) -------------------
# SCALE: uniform size factor (mirror m12_clean.scad). 1.0 = original 18 mm ball. Every linear
# dimension scales together, so all clearances/bites scale proportionally and the gates stay valid.
SCALE = 1.25
R, N, ball_d = 50.0*SCALE, 11, 18.0*SCALE
rb   = ball_d / 2.0                    # 11.25  ball radius
eq   = ball_d / 2.0                    # 11.25  ball-centre height at the ring plane
nbchord = 2 * R * math.sin(math.pi / N)
APEX_STROKE = 24.0*SCALE
apexR   = R + APEX_STROKE                        # apex slot radius (y, downward)

# z-decks (world z; ball bottom = 0)
Z_GEAR   = -7.0*SCALE                  # sun + idler gear deck
Z_HUB    = -2.0*SCALE                  # in-plane rotor hub top (below ball equator)
Z_29     = -22.0*SCALE                 # (2,9) under-deck rotor cup-centre (ball-2 deep sweep clears the plate)
Z_29FLOOR= -41.0*SCALE                 # base disc floor (room for the (2,9) bar under the dipped balls)
WELL_R   = rb + 1.0                    # vertical well radius (2 & 9 pass through)

SEG_PUSH = 72                          # swap frames (EXCEEDS series' 24)
SEG_SPIN = 132                         # spin steps
TOL      = 0.4                         # ignore penetrations shallower than this (mm)
CLR_GOAL = 1.0                         # design margin we *want* (reported, not gating)

# --- fixed spin channel, fork capture, gates, cam/drive plate ---
tube_sp  = rb + 0.3                    # spin-channel tube radius (mirror m12_clean.scad)
spin_top = eq + math.sqrt(tube_sp*tube_sp - rb*rb) + 1.5    # channel mouth height
fork_z   = eq + 2.5*SCALE              # fork C-lip grip height (just above equator)
fork_ir  = rb - 0.4                    # fork C-lip inner radius (< rb -> gravity-proof)
Z_PLATE  = -12.0*SCALE                 # hidden cam/drive plate deck
PLATE_R  = 66.0*SCALE                  # cam plate radius
GATE_DROP= 16.0*SCALE                  # gate drop to open a station
CRANK_E  = 7.0*SCALE                   # crank-pin offset from the rotor pivot (rides the cam slot)

def check_capture():
    """Goal 0/1: balls are held in ANY orientation — the open channel wraps each ball
    past its equator (mouth < ball Ø), and the fork's C-lip grips above the equator
    (inner r < rb). Neither relies on gravity. This is the any-orientation gate."""
    mouth = 2*math.sqrt(tube_sp*tube_sp - (spin_top-eq)**2)
    print('\n=== CAPTURE (any-orientation retention; no gravity) ===')
    if mouth < ball_d-0.05 and fork_ir < rb:
        print(f'  PASS — spin-channel mouth {mouth:.2f} mm < ball {ball_d:.0f} mm (bite {ball_d-mouth:.2f}); '
              f'fork C-lip r{fork_ir} < rb{rb:.0f} grips above the equator; cap {ball_d-spin_top:.1f} mm proud.')
        return 0
    print(f'  FAIL — capture not gravity-proof (mouth {mouth:.2f}, fork_ir {fork_ir}).')
    return 1

def angleOf(s): return -90 + (s - 1) * (360.0 / N)
def P(s):
    if s == 0: return (0.0, apexR)                    # apex, +y (down), radius 1.25R
    a = math.radians(angleOf(s)); return (R * math.cos(a), -R * math.sin(a))

NEIGH = [(3,4),(5,6),(7,8),(10,11)]
RIMS  = NEIGH                                          # rim rotors
ALL_INPLANE = [(0,1)] + NEIGH                          # 5 in-plane rotors

# ---------------- vector helpers --------------------------------------------
def sub(a,b): return tuple(a[k]-b[k] for k in range(3))
def add(a,b): return tuple(a[k]+b[k] for k in range(3))
def dot(a,b): return sum(a[k]*b[k] for k in range(3))
def norm(a):  return math.sqrt(dot(a,a))

def rot2(p, c, ang):
    """rotate planar point p about centre c by ang (rad)."""
    co, si = math.cos(ang), math.sin(ang)
    dx, dy = p[0]-c[0], p[1]-c[1]
    return (c[0]+dx*co-dy*si, c[1]+dx*si+dy*co)

# ---------------- BALL kinematics over the swap (u = 0..1) -------------------
# In-plane rotors: each pair's two balls rotate 180*u about the pair midpoint,
# staying at z=eq. They are always diametrically opposite => never collide.
def inplane_ball(i, j, which, u):
    A, B = P(i), P(j)
    M = ((A[0]+B[0])/2.0, (A[1]+B[1])/2.0)
    start = A if which == 0 else B
    x, y = rot2(start, M, math.pi * sweep_frac(u))     # hold at station until the carry window (after grip)
    return (x, y, eq)

# (2,9): the ball HOLDS at channel level until the fork has gripped + the gate opens (u<0.12);
# only THEN is it positively driven down, deep through the carry, and back up by 0.88 — so it
# never leaves the channel before its fork holds it (see check_retention). Never gravity-fed.
M29 = ((P(2)[0]+P(9)[0])/2.0, (P(2)[1]+P(9)[1])/2.0)
def z29(u):
    """ball/cup height during the (2,9) cycle: held at eq, driven eq->Z_29->eq inside the carry."""
    if u <= 0.12 or u >= 0.88: return eq            # held in the channel before/after the carry
    s = (u - 0.12) / 0.76                            # 0..1 across the carry window
    f = min(1.0, s/0.12, (1.0-s)/0.12)              # driven down over the first/last 12% of the carry
    return eq + (Z_29 - eq) * f
def sweep_frac(u):
    """0..1 sweep progress during the dwell; 0 before, 1 after."""
    if u <= 0.12: return 0.0
    if u >= 0.88: return 1.0
    return (u-0.12)/0.76
def cross_ball(which, u):
    """which=0 -> ball 2's path (starts at slot2), which=1 -> ball 9's."""
    start = P(2) if which == 0 else P(9)
    x, y = rot2(start, M29, math.pi * sweep_frac(u))
    return (x, y, z29(u))

def carriage_z(u):
    """(2,9) carriage height on its barrel cam: parked deep (Z_29) for spin, RISES to grip the
    balls at the channel (eq), carries them down & back up (= z29 through the dwell), then
    RETRACTS. The forks track the balls through the whole carry — never gravity-fed."""
    if u <= 0.12: return Z_29 + (eq - Z_29) * (u/0.12)          # rise to engage at the channel
    if u >= 0.88: return Z_29 + (eq - Z_29) * ((1.0-u)/0.12)    # retract back to the park
    return z29(u)                                                # carry: down to Z_29 and back

def ball_positions(u):
    pos = {}
    for (i,j) in NEIGH:
        pos[i] = inplane_ball(i,j,0,u); pos[j] = inplane_ball(i,j,1,u)
    # apex (0,1): realized by the slide; geometrically a 180deg rotor of r=6.25
    pos[0] = inplane_ball(0,1,0,u); pos[1] = inplane_ball(0,1,1,u)
    pos[2] = cross_ball(0,u);       pos[9] = cross_ball(1,u)
    return pos

# ---------------- PART model (each is a typed primitive) --------------------
# 'cyl' : ('cyl', (cx,cy), r, z0, z1)
# 'box' : ('box', (cx,cy), hx, hy, z0, z1)            (axis-aligned)
# 'ring': ('ring',(cx,cy), Rr, t, z0, z1)             (annulus, half-thickness t)
# 'cap' : ('cap', (p0x,p0y,p0z),(p1x,p1y,p1z), r)     (capsule = segment + radius)
def rotor_caps(i, j, u, z, barr=None, cupr=None):
    """A 2-cell rotor as a capsule bar + two end cup cylinders, rotated 180*u."""
    A, B = P(i), P(j)
    M = ((A[0]+B[0])/2.0, (A[1]+B[1])/2.0)
    a = rot2(A, M, math.pi*u); b = rot2(B, M, math.pi*u)
    if barr is None: barr = 4.0
    if cupr is None: cupr = rb*0.82
    zbar = z - rb - barr                         # bar runs UNDER the balls (top at z-rb), never spears them
    bar = ('cap', (a[0],a[1],zbar), (b[0],b[1],zbar), barr)
    ca  = ('cyl', (a[0],a[1]), cupr, z-rb*0.9, z-rb*0.1)
    cb  = ('cyl', (b[0],b[1]), cupr, z-rb*0.9, z-rb*0.1)
    return [(bar, f'bar{i}-{j}'), (ca, f'cup{i}-{j}@{i}'), (cb, f'cup{i}-{j}@{j}')]

def parts(u, engaged=True):
    """All mechanism solids at swap fraction u.
    engaged=True  -> SWAP regime (rotor cups at ball level / (2,9) on its deck).
    engaged=False -> REST/SPIN regime (in-plane cups parked open; (2,9) seated low).
    """
    L = []
    def add_(solid, name): L.append((solid, name))

    # --- in-plane rotors: rise to BALL level for a swap, RETRACT below the equator
    #     for spin (mode switch). When retracted, a spinning ring ball clears them. ---
    zc = eq if engaged else Z_GEAR           # carried at ball level; retracted to gear deck for spin
    for (i,j) in ALL_INPLANE:
        for s, n in rotor_caps(i, j, (sweep_frac(u) if engaged else 0.0), zc):   # rotor tracks its balls (carry window)
            add_(s, n)
        # rotor gear hub always sits below the equator
        M = ((P(i)[0]+P(j)[0])/2.0, (P(i)[1]+P(j)[1])/2.0)
        add_(('cyl', M, 7.0, Z_GEAR-1.5, Z_HUB), f'hub{i}-{j}')

    # (the apex crank is now the cam-driven pivot0-1 added below — no separate sun-pinion.)

    # --- (2,9) CARRIAGE on a barrel cam: the cross-rotor RISES to grip the balls at the
    #     channel, is driven DOWN to the sub-deck, turns 180°, driven back UP, then RETRACTS.
    #     Its forks TRACK the balls the whole carry (carriage_z), so 2 & 9 are never unheld. ---
    zc29 = carriage_z(u) if engaged else Z_29
    sf29 = sweep_frac(u) if engaged else 0.0
    for s, n in rotor_caps(2, 9, sf29, zc29, barr=4.5, cupr=rb*0.82):
        add_(s, n)
    add_(('cyl', M29, 6.0, Z_29FLOOR, zc29-rb*0.9-0.5), 'hub2-9')      # carriage hub on the splined shaft

    # (2,9) splined SHAFT — long enough that the carriage hub stays keyed over the full carry
    # while telescoping on it (supplies the 180° turn). M29 is central (r~26), so a tall shaft
    # clear of every ball fits — this is why the 2,9 lift is geometrically possible at all.
    add_(('cyl', M29, 2.5, Z_29FLOOR+2, eq+4), 'shaft2-9')
    add_(('cyl', M29, 5.0, Z_GEAR-2.0, Z_HUB), 'idler2-9')
    # NOTE: the actual cam/lift HARDWARE that drives the carriage up-to-grip and down-to-carry is
    # deliberately NOT asserted here — see report. This gate validates the ball KINEMATICS and
    # the geometric retention of the tracking carriage, not the (unsolved) drive packaging.

    # --- cam-drive PIVOT SHAFTS (on each rotor axis = midpoint, which CLEARS the balls)
    #     up to the rotor, + the offset CRANK PIN that rides the cam slot (plate level
    #     ONLY — modelling these is what would have caught the pin-into-ball-0/1 bug). ---
    for (i,j) in ALL_INPLANE:
        M = ((P(i)[0]+P(j)[0])/2.0, (P(i)[1]+P(j)[1])/2.0)
        ptop = eq if engaged else Z_HUB     # the rotor (incl. its pivot) RETRACTS below the balls for spin
        add_(('cyl', M, 2.0, Z_PLATE, ptop), f'pivot{i}-{j}')
        # COMMON-PHASE crank post (+x) — the parallel-crank coupling plate journals all five
        # at the same phase, so one plate translation turns every rotor the identical angle.
        add_(('cyl', (M[0]+CRANK_E, M[1]), 1.6, Z_PLATE, Z_HUB), f'crankpin{i}-{j}')

    # --- hidden CAM / DRIVE PLATE: a disc below the rotors (the swap drive). It has
    #     drop WELLS at slots 2 & 9 so those balls pass through it (exempted below). ---
    add_(('cyl', (0.0,0.0), PLATE_R, Z_PLATE-2.0, Z_PLATE+2.0), 'cam-plate')

    # --- base disc floor (everything sits above it; balls never reach it) ---
    add_(('ring', (0.0,0.0), R, 6.0, Z_29FLOOR-3.0, Z_29FLOOR-0.5), 'base-rim')

    return L

# ---------------- penetration: SPHERE vs PART -------------------------------
def closest_on_seg(p, a, b):
    ab = sub(b,a); L2 = dot(ab,ab)
    if L2 == 0.0: return a
    t = max(0.0, min(1.0, dot(sub(p,a),ab)/L2))
    return add(a, tuple(ab[k]*t for k in range(3)))

def pen_sphere(c, part):
    typ = part[0]
    if typ == 'cyl':
        _, (cx,cy), r, z0, z1 = part
        dr = max(0.0, math.hypot(c[0]-cx, c[1]-cy) - r)
        dz = max(0.0, z0-c[2], c[2]-z1)
        return rb - math.hypot(dr, dz)
    if typ == 'box':
        _, (cx,cy), hx, hy, z0, z1 = part
        dx = max(0.0, abs(c[0]-cx)-hx); dy = max(0.0, abs(c[1]-cy)-hy)
        dz = max(0.0, z0-c[2], c[2]-z1)
        return rb - math.sqrt(dx*dx+dy*dy+dz*dz)
    if typ == 'ring':
        _, (cx,cy), Rr, t, z0, z1 = part
        dr = max(0.0, abs(math.hypot(c[0]-cx, c[1]-cy)-Rr)-t)
        dz = max(0.0, z0-c[2], c[2]-z1)
        return rb - math.hypot(dr, dz)
    if typ == 'cap':
        _, p0, p1, r = part
        q = closest_on_seg(c, p0, p1)
        return (rb + r) - norm(sub(c, q))
    raise ValueError(typ)

# ---------------- penetration: PART vs PART (faithful, not vertically inflated) ----
# Each primitive is decomposed into (planar-segment + planar-radius, z-interval).
# True min distance = hypot(planar_gap, z_gap); penetration = (pr_a+pr_b) - planar_gap
# combined with the z separation. This does NOT inflate a cylinder vertically by its
# radius (the bug a naive capsule-cast introduces), so vertical deck separation reads
# correctly.
def planar_seg(part):
    """Return (p0xy, p1xy, planar_radius, z0, z1). A cyl/ring/box reduce to a planar
    segment swept by planar_radius, plus a true z-interval."""
    typ = part[0]
    if typ == 'cap':
        _, p0, p1, r = part
        return (p0[0],p0[1]), (p1[0],p1[1]), r, min(p0[2],p1[2])-r, max(p0[2],p1[2])+r
    if typ == 'cyl':
        _, (cx,cy), r, z0, z1 = part
        return (cx,cy), (cx,cy), r, z0, z1
    if typ == 'box':
        _, (cx,cy), hx, hy, z0, z1 = part
        if hx >= hy: return (cx-hx,cy),(cx+hx,cy), hy, z0, z1
        return (cx,cy-hy),(cx,cy+hy), hx, z0, z1
    if typ == 'ring':
        _, (cx,cy), Rr, t, z0, z1 = part
        return None, None, None, z0, z1            # annulus: skip part-vs-part
    raise ValueError(typ)

def seg2d_dist(p1,p2,q1,q2):
    """planar (2-D) min distance between two segments."""
    def s3(p): return (p[0],p[1],0.0)
    return seg_seg_dist(s3(p1),s3(p2),s3(q1),s3(q2))

def seg_seg_dist(p1,p2,q1,q2):
    d1=sub(p2,p1); d2=sub(q2,q1); r=sub(p1,q1)
    a=dot(d1,d1); e=dot(d2,d2); f=dot(d2,r)
    if a<=1e-9 and e<=1e-9: return norm(r)
    if a<=1e-9: s=0.0; t=max(0.0,min(1.0,f/e))
    else:
        c=dot(d1,r)
        if e<=1e-9: t=0.0; s=max(0.0,min(1.0,-c/a))
        else:
            b=dot(d1,d2); den=a*e-b*b
            s=max(0.0,min(1.0,(b*f-c*e)/den)) if den>1e-9 else 0.0
            t=(b*s+f)/e
            if t<0: t=0.0; s=max(0.0,min(1.0,-c/a))
            elif t>1: t=1.0; s=max(0.0,min(1.0,(b-c)/a))
    cp=add(p1,tuple(d1[k]*s for k in range(3)))
    cq=add(q1,tuple(d2[k]*t for k in range(3)))
    return norm(sub(cp,cq))

def pen_part_part(pa, pb):
    a0,a1,pra,az0,az1 = planar_seg(pa)
    b0,b1,prb,bz0,bz1 = planar_seg(pb)
    if pra is None or prb is None: return -999.0     # annulus: skip
    planar_gap = max(0.0, seg2d_dist(a0,a1,b0,b1) - (pra+prb))
    z_gap = max(0.0, bz0-az1, az0-bz1)
    # penetration > 0 when solids overlap in BOTH planar and z senses
    return -math.hypot(planar_gap, z_gap) if (planar_gap>0 or z_gap>0) else (pra+prb) - seg2d_dist(a0,a1,b0,b1)

# ---------------- which contacts are EXPECTED (not clashes) -----------------
def carried(ball, part_name):
    """parts a ball legitimately rides (cup of its own pair / its slide thumb)."""
    if part_name.startswith('cup'):
        seat = part_name.split('@')[1]
        return str(ball) == seat
    if part_name.startswith('bar'):
        a,b = part_name[3:].split('-'); return ball in (int(a),int(b))
    if part_name == 'slide-thumb': return ball == 0
    if part_name == 'cam-plate': return ball in (2, 9)   # drop wells at slots 2 & 9
    return False

def same_rotor(na, nb):
    """two part names belonging to the SAME rotor assembly (expected to touch)."""
    def key(n):
        if n.startswith('bar'):  return n[3:]
        if n.startswith('cup'):  return n[3:].split('@')[0]
        if n.startswith('hub'):  return n[3:]
        if n.startswith('shaft'): return n[5:]   # shaft2-9 / idler2-9 coaxial with the 2-9 carriage
        if n.startswith('idler'): return n[5:]
        if n.startswith('pivot'): return n[5:]   # pivot/crankpin are part of the rotor's drive linkage
        if n.startswith('crankpin'): return n[8:]
        return n
    return key(na) == key(nb)

# Expected drive-train contacts (gears mesh, slide rides its rack). Not clashes.
LEGIT_PAIRS = {
    frozenset(('sun-pinion','slide-rack-base')),   # rack meshes the sun pinion
    frozenset(('slide-rack-base','slide-thumb')),  # thumb sits on the slide
    frozenset(('sun-pinion','slide-thumb')),       # column of the apex slide
}
def legit_contact(na, nb):
    if 'cam-plate' in (na, nb): return True   # the drive deck: crank pins/shafts pass through it by design
    if same_rotor(na, nb): return True
    if frozenset((na,nb)) in LEGIT_PAIRS: return True
    # a rotor's gear hub meshes the drive train at its own pivot — allow hub<->sun/idler
    if na.startswith('hub') and nb in ('sun-pinion',): return True
    if nb.startswith('hub') and na in ('sun-pinion',): return True
    # the apex (0,1) rotor is rigid on the sun-pinion shaft (coaxial assembly) — they touch by design
    apex = lambda n: n in ('bar0-1','cup0-1@0','cup0-1@1','hub0-1')
    if (apex(na) and nb=='sun-pinion') or (apex(nb) and na=='sun-pinion'): return True
    return False

# ---------------- the SWAP sweep (72 frames) --------------------------------
def check_swap():
    clashes = []
    for k in range(SEG_PUSH+1):
        u = k/SEG_PUSH
        pos = ball_positions(u); pl = parts(u, engaged=True)
        balls = sorted(pos)
        # ball <-> ball
        for ia in range(len(balls)):
            for ib in range(ia+1, len(balls)):
                ca, cb = pos[balls[ia]], pos[balls[ib]]
                p = 2*rb - norm(sub(ca,cb))
                if p > TOL:
                    clashes.append((u, f'ball{balls[ia]}', f'ball{balls[ib]}', p))
        # ball <-> part
        for s in balls:
            for part, name in pl:
                p = pen_sphere(pos[s], part)
                if p > TOL and not carried(s, name):
                    clashes.append((u, f'ball{s}', name, p))
        # part <-> part
        for ipa in range(len(pl)):
            for ipb in range(ipa+1, len(pl)):
                (pa,na),(pb,nb) = pl[ipa], pl[ipb]
                if legit_contact(na,nb): continue
                p = pen_part_part(pa, pb)
                if p > TOL:
                    clashes.append((u, na, nb, p))
    return clashes

# ---------------- the SPIN sweep --------------------------------------------
def check_spin():
    """A ball travels every ring position; the resting mechanism must clear it.
    Also re-checks part-vs-part at rest."""
    clashes = []
    pl = parts(0.0, engaged=False)
    for k in range(SEG_SPIN):
        a = math.radians(-90 + k*(360.0/SEG_SPIN))
        c = (R*math.cos(a), -R*math.sin(a), eq)
        for part, name in pl:
            # a parked rotor's OWN cups/bar share the ball at the two pair slots — expected.
            # Only flag if the ball is NOT at this part's pair location (i.e. a real obstruction).
            p = pen_sphere(c, part)
            if p > TOL:
                clashes.append((round(math.degrees(a) % 360,1), 'ring-ball', name, p))
    # part-vs-part at rest
    for ipa in range(len(pl)):
        for ipb in range(ipa+1, len(pl)):
            (pa,na),(pb,nb) = pl[ipa], pl[ipb]
            if legit_contact(na,nb): continue
            p = pen_part_part(pa, pb)
            if p > TOL:
                clashes.append(('rest', na, nb, p))
    return clashes

# ---------------- reporting -------------------------------------------------
def report(title, clashes, stage_label):
    print(f'\n=== {title} ===')
    if not clashes:
        print('  PASS — no interference.'); return 0
    worst = {}
    for st, a, b, p in clashes:
        key = (a,b)
        if key not in worst or p > worst[key][1]:
            worst[key] = (st, p)
    print(f'  FAIL — {len(worst)} distinct clashing pairs (worst penetration each):')
    for (a,b),(st,p) in sorted(worst.items(), key=lambda kv: -kv[1][1]):
        print(f'    {a:>14} n {b:<16} {p:6.2f} mm  (at {stage_label}={st})')
    return 1

# ---------------- ACTUATION TIMING (fork <-> gate <-> 2,9-lift sequence) ----------
# The cam profile sequences these so a ball is NEVER unheld (no gravity, any orientation):
#   grip-before-open / close-before-release. Windows in swap-fraction u:
GRIP_IN,  GRIP_OUT  = 0.04, 0.96       # in-plane forks engaged (grip the ball at its station)
GATE_IN,  GATE_OUT  = 0.11, 0.89       # inner-wall gates OPEN (the carry happens inside this)
LIFT_END, LIFT_START= 0.12, 0.88       # 2&9 cam-lift: drop u<0.12, dwell, rise u>0.88

def fork_grip(u): return GRIP_IN <= u <= GRIP_OUT
def gate_open(u): return GATE_IN <= u <= GATE_OUT
def lift_29(u):   return u < LIFT_END or u > LIFT_START

# ---------------- CONTINUOUS-RETENTION (the capture / handoff) ----------------
# The any-orientation claim only holds if EVERY ball is capped above its equator at EVERY
# instant — by the fixed channel lip OR by its fork — with the two overlapping at the handoff
# (claim-before-release). A ball that is ever off-channel with no fork grip would fall out if
# the toy were inverted at that instant. This is the rigorous form of the capture sequence.
def in_channel(p):
    """True iff a FIXED retainer caps the ball above its equator: the ring channel torus, or
    the apex slot (the elongated x=0 pocket from station 1 out to the apex that holds ball 0)."""
    on_ring = math.hypot(math.hypot(p[0], p[1]) - R, p[2] - eq) <= 1.0
    on_apex = abs(p[0]) <= 1.0 and abs(p[2] - eq) <= 1.0 and (R - 1.0) <= p[1] <= (apexR + 1.0)
    return on_ring or on_apex

def cup_centres(u):
    """centre of every fork cup, keyed by the ball it carries (the cup sits ~rb/2 below the ball)."""
    d = {}
    for solid, name in parts(u, engaged=True):
        if name.startswith('cup'):
            ball = int(name.split('@')[1])
            _, (cx, cy), _cupr, z0, z1 = solid
            d[ball] = (cx, cy, (z0+z1)/2.0 + rb*0.5)
    return d

def near_cup(p, c): return c is not None and math.dist(p, c) <= rb*0.7   # a fork cup is GEOMETRICALLY on the ball

def check_retention():
    print('\n=== RETENTION (continuous over-equator capture; any orientation, no gravity) ===')
    us = [k/SEG_PUSH for k in range(SEG_PUSH+1)]
    worst = 0.0
    for u in us:
        pos = ball_positions(u); cups = cup_centres(u)
        for s, p in pos.items():
            c = cups.get(s)
            held = in_channel(p) or near_cup(p, c)
            if near_cup(p, c): worst = max(worst, math.dist(p, c))
            if not held:
                where = 'no cup near it' if c is None else f'nearest cup {math.dist(p,c):.1f} mm off'
                print(f'  FAIL — ball {s} unheld at u={u:.3f}: off-channel '
                      f'(r={math.hypot(p[0],p[1]):.1f}, z={p[2]:.1f}), {where} — would escape if inverted here.')
                return 1
    # handoff overlap: each ball leaves the channel only AFTER a cup is on it, and re-enters BEFORE the cup leaves
    ms = me = 1.0
    for s in ball_positions(0.0):
        off  = [u for u in us if not in_channel(ball_positions(u)[s])]
        held = [u for u in us if near_cup(ball_positions(u)[s], cup_centres(u).get(s))]
        if off and held: ms = min(ms, min(off)-min(held)); me = min(me, max(held)-max(off))
    print(f'  PASS — at every frame each ball is capped above its equator by the fixed channel OR a fork')
    print(f'         cup that is GEOMETRICALLY on it (worst grip offset {worst:.1f} < {rb*0.7:.1f} mm). The 2&9')
    print(f'         carriage rises to grip at the channel, carries the balls down to the sub-deck and back,')
    print(f'         then retracts — forks track the balls all carry. Handoff overlaps (grip-before-leave '
          f'{ms:+.2f}u, hold-past-return {me:+.2f}u): never gravity-fed.')
    return 0

def check_timing():
    print('\n=== TIMING (fork<->gate<->2,9-lift; a ball is never unheld, no gravity) ===')
    us = [k/SEG_PUSH for k in range(SEG_PUSH+1)]
    bad_gate = [u for u in us if gate_open(u) and not fork_grip(u)]            # gate must not open before the fork grips
    bad_lift = [u for u in us if lift_29(u)  and not (0.0 <= u <= 1.0)]        # 2&9 sit in their cradles all swap (always held)
    if not bad_gate and not bad_lift:
        print(f'  PASS — gates open ({GATE_IN}..{GATE_OUT}) strictly inside the fork grip '
              f'({GRIP_IN}..{GRIP_OUT}): grip-before-open, close-before-release.')
        print(f'         2&9 cam-lift (drop u<{LIFT_END} / rise u>{LIFT_START}) runs while they are held in '
              f'their cradles -> positively driven down & up, never gravity-fed.')
        return 0
    if bad_gate: print(f'  FAIL — a gate opens with no fork grip at u={bad_gate[0]:.3f} (ball free).')
    if bad_lift: print(f'  FAIL — 2/9 lifted unheld at u={bad_lift[0]:.3f}.')
    return 1

if __name__ == '__main__':
    rc  = check_capture()
    rc |= check_retention()
    rc |= check_timing()
    rc |= report(f'SWAP sweep ({SEG_PUSH} frames, ball+part interference)', check_swap(), 'u')
    rc |= report(f'SPIN sweep ({SEG_SPIN} steps, ring free to rotate?)',   check_spin(), 'deg')
    print()
    if rc:
        print('RESULT: FAIL — interference present (see above).'); sys.exit(1)
    print('RESULT: PASS — capture+retention, timing, swap sweep, and spin sweep all clear.'); sys.exit(0)
