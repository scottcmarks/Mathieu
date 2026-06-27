#!/usr/bin/env python3
"""SEARCH for a friendlier M12 swap-involution than perm #22.

The toy = <spin, swap>.  spin = the 11-cycle on the ring (apex 0 fixed).  swap = a fixed-point-
free involution (6 transpositions).  For the toy to be M12 the pair must generate M12 (order
95040).  Perm #22's six transpositions pack badly (two drums forced 49 apart -> overlap).  This
enumerates EVERY fpf involution, keeps the ones that still generate M12 with the spin, and ranks
them by how evenly their swap-drums pack inside the ring.  (Note: a perfectly even swap is a rigid
180 rotation, which commutes with spin and gives only C11/dihedral -- NOT M12.  So we want the
best achievable evenness, not perfection.)
"""
import math, itertools

n = 12
def compose(p, q): return tuple(p[q[x]] for x in range(n))     # apply q then p
SPIN = tuple([0] + [(i % 11) + 1 for i in range(1, 12)])       # 0 fixed; 1->2,...,10->11,11->1
def spin_pow(k):
    p = tuple(range(n))
    for _ in range(k): p = compose(SPIN, p)
    return p
SPK = [spin_pow(k) for k in range(11)]

LIMIT = 95040
M12_ORDERS = {1,2,3,4,5,6,8,10,11}            # the only element orders in M12
def perm_order(p):
    seenx = [False]*n; o = 1
    for i in range(n):
        if not seenx[i]:
            L = 0; j = i
            while not seenx[j]: seenx[j] = True; j = p[j]; L += 1
            o = o*L // math.gcd(o, L)
    return o
def gens_order_capped(gens, check_orders=False):
    idp = tuple(range(n)); seen = {idp}; frontier = [idp]
    while frontier:
        nf = []
        for p in frontier:
            for g in gens:
                q = compose(g, p)
                if q not in seen:
                    if check_orders and perm_order(q) not in M12_ORDERS:
                        return -1                 # contains an order 7/9/12 element -> NOT M12
                    seen.add(q)
                    if len(seen) > LIMIT: return len(seen)
                    nf.append(q)
        frontier = nf
    return len(seen)

def matchings(pts):
    if not pts: yield []; return
    a = pts[0]
    for i in range(1, len(pts)):
        b = pts[i]
        for m in matchings(pts[1:i] + pts[i+1:]): yield [(a, b)] + m

def perm_of(match):
    p = list(range(n))
    for a, b in match: p[a] = b; p[b] = a
    return tuple(p)

def canon(match):                                              # canonical rep under spin-conjugacy
    best = None
    for k in range(11):
        s = SPK[k]
        m = frozenset(frozenset((s[a], s[b])) for a, b in match)
        key = tuple(sorted(tuple(sorted(e)) for e in m))
        if best is None or key < best: best = key
    return best

# ---- geometry / packing score (mirrors check_layout.py) ----
SCALE = 1.25; R = 50*SCALE; rb = 9*SCALE; tube = rb + 0.3
RD = rb + 0.5; FP = RD + rb + 1.0; CR = R - RD - 1.0; APEX = R + 24*SCALE; WALL = R + tube
def angleOf(s): return -90 + (s-1)*(360.0/11)
def Pst(s):
    if s == 0: return (0.0, APEX)
    a = math.radians(angleOf(s)); return (R*math.cos(a), -R*math.sin(a))
def drum_center(a, b):
    Pa, Pb = Pst(a), Pst(b); M = ((Pa[0]+Pb[0])/2, (Pa[1]+Pb[1])/2); mr = math.hypot(*M)
    if mr < 1e-6: return (0.0, 0.0)
    t = min(mr, CR); return (M[0]/mr*t, M[1]/mr*t)
def pack_score(match):
    C = [drum_center(a, b) for a, b in match]
    tight = 1e9
    for i in range(len(C)):
        for j in range(i+1, len(C)):
            tight = min(tight, math.dist(C[i], C[j]) - 2*FP)
    far_out = max((math.hypot(*drum_center(a,b)) + RD + rb) - WALL for a, b in match)  # ball past wall?
    return tight, far_out
def dist_profile(match):                                       # station-gap multiset (apex=0 special)
    prof = []
    for a, b in match:
        if 0 in (a, b): prof.append('apex'); continue
        d = abs(a-b); d = min(d, 11-d); prof.append(d)
    return tuple(sorted(x for x in prof if x != 'apex')), ('apex' in [ 'apex' for a,b in match if 0 in (a,b)])

PERM22 = [(0,1),(2,9),(3,4),(5,6),(7,8),(10,11)]

if __name__ == '__main__':
    # validate the group test on known cases
    print('validate: <spin> =', gens_order_capped([SPIN]), '(expect 11)')
    print('validate: <spin, #22> =', gens_order_capped([SPIN, perm_of(PERM22)]), '(expect 95040 = M12)')

    seen_canon = set(); reps = []
    for m in matchings(list(range(n))):
        c = canon(m)
        if c not in seen_canon: seen_canon.add(c); reps.append(m)
    print(f'\nfpf involutions: 10395 total -> {len(reps)} classes under spin-conjugacy')

    m12 = []
    for m in reps:
        if gens_order_capped([SPIN, perm_of(m)], check_orders=True) == 95040:
            ts, _ = dist_profile(m); tight, far = pack_score(m)
            m12.append((tight, far, m, ts))
    print(f'of those, {len(m12)} generate M12 with the spin\n')

    m12.sort(key=lambda r: -r[0])    # most positive tightest-clearance first
    t22, f22 = pack_score(PERM22)
    print(f'perm #22 baseline: tightest drum clearance {t22:+.1f} mm, ball-past-wall {f22:+.1f} mm  (FAILS)\n')
    print('TOP packing-friendly M12 swaps (tightest drum clearance, +mm = fits):')
    print(f'  {"clr":>6} {"out":>6}  gaps(non-apex)         transpositions')
    for tight, far, m, ts in m12[:12]:
        tag = 'FITS ' if (tight > 0 and far <= 0.1) else '     '
        ms = ' '.join(f'({a},{b})' for a,b in sorted(m, key=lambda e: (0 not in e, e)))
        print(f'  {tight:+6.1f} {far:+6.1f} {tag} {str(ts):20} {ms}')
    fits = [r for r in m12 if r[0] > 0 and r[1] <= 0.1]
    print(f'\n{len(fits)} of {len(m12)} M12 swaps PACK (all six drums fit + nothing exits the ring).')
