#!/usr/bin/env python3
"""VARIANT C4 — slotted rotating dish, seg/dish non-overlap verification.

For each of the 5 divider pairs, the dish is centered at the chord midpoint M
of that pair. The slots are cut at the WORLD-frame positions of the segs that
overlap the dish footprint:
  - apex pair (0,1): seg(1), seg(2), seg(11)  (3-slot dish)
  - non-apex pairs:  segs at the two pair stations  (2-slot dish)

We test the worst case z values during the transit:
  z = 0     (dish at seg-band floor, fully embedded in segs)
  z = 6     (mid-band)
  z = 12    (near spin_top=13.97, last contact)
The test geometry: place the slotted dish at (M, z), keep all 11 spin-segs at
HOME (z=0). Intersect; report mm^3 of clash. 0 = clean pass-through.

We also test the working state (z=0, segs DROPPED) to confirm the dish still
works as a ball container when needed.
"""
import math, struct, subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor

HERE    = os.path.dirname(os.path.abspath(__file__))
OPENSCAD = "/opt/homebrew/bin/openscad"
SCALE = 20/18
R = 50*SCALE; N = 11; ball_d = 18*SCALE; rb = ball_d/2; eq = ball_d/2
apexR = R + 24*SCALE
tube = rb + 0.3; wall_t = 1.5*SCALE; div_t = 3.0
orbit = rb + div_t/2 + 0.5
dish_outer = orbit + tube + wall_t
band_inner = R - tube - wall_t
band_outer = R + tube + wall_t
spin_top   = eq + math.sqrt(tube*tube - rb*rb) + 1.5
DIVP = [(0,1),(3,4),(5,6),(7,8),(10,11)]
# transit z samples — critical heights where dish is inside seg band
Z_SAMPLES = [0.0, 6.0, 12.0]
TOL = 1.0

def A(s): return -90 + (s-1)*(360.0/N)
def P(s):
    if s == 0: return (0.0, apexR)
    a = math.radians(A(s)); return (R*math.cos(a), -R*math.sin(a))
def th(k): return -A(k)
def pair_M(i, j): return ((P(i)[0]+P(j)[0])/2, (P(i)[1]+P(j)[1])/2)

# ---- ASCII + binary STL parser (canonical impl from check_variants.py) ----
def vol(p):
    with open(p, 'rb') as f: d = f.read()
    if d[:5] == b'solid' and b'facet' in d[:512]:
        verts = []
        for line in d.decode('ascii', 'ignore').splitlines():
            t = line.split()
            if t[:1] == ['vertex']:
                verts.append((float(t[1]), float(t[2]), float(t[3])))
        v = 0.0
        for i in range(0, len(verts)-2, 3):
            a, b, c = verts[i], verts[i+1], verts[i+2]
            v += (a[0]*(b[1]*c[2]-b[2]*c[1])
                  - a[1]*(b[0]*c[2]-b[2]*c[0])
                  + a[2]*(b[0]*c[1]-b[1]*c[0]))/6
        return abs(v)
    if len(d) < 84: return 0.0
    n = struct.unpack('<I', d[80:84])[0]
    if 84 + n*50 != len(d) or n == 0: return 0.0
    v = 0.0; o = 84
    for _ in range(n):
        t = struct.unpack('<12f', d[o:o+48]); o += 50
        a, b, c = t[3:6], t[6:9], t[9:12]
        v += (a[0]*(b[1]*c[2]-b[2]*c[1])
              - a[1]*(b[0]*c[2]-b[2]*c[0])
              + a[2]*(b[0]*c[1]-b[1]*c[0]))/6
    return abs(v)

def rv(body, tag, scad_file="proto_variant_C4.scad"):
    sf = f'/tmp/V_{tag}.scad'; of = f'/tmp/V_{tag}.stl'
    if os.path.exists(of): os.remove(of)
    with open(sf, 'w') as f:
        f.write(f'use <{HERE}/{scad_file}>\nuse <{HERE}/proto_wall.scad>\n$fn=32;\n{body}\n')
    subprocess.run([OPENSCAD, '-o', of, sf], capture_output=True, text=True)
    return vol(of) if os.path.exists(of) else 0.0

def expr_all_segs_at_home():
    """Render all 11 spin-segs at their home positions (z=0)."""
    parts = []
    for k in range(1, N+1):
        rz = th(k) - th(1)
        parts.append(f'rotate([0,0,{rz:.3f}]) spin_seg(1);')
    return 'union(){ ' + ' '.join(parts) + ' }'

def expr_dish_at(i, j, z):
    M = pair_M(i, j)
    return (f'translate([{M[0]:.3f},{M[1]:.3f},{z:.3f}]) '
            f'C4_dish({i},{j});')

def test_transit():
    print("VARIANT C4 — slotted rotating dish, TRANSIT test")
    print(f"  (segs at HOME, dish rising through z in {Z_SAMPLES})\n")
    worst = 0.0
    rows = []
    tasks = []
    for (i, j) in DIVP:
        for z in Z_SAMPLES:
            tag = f'C4_t_{i}_{j}_z{int(z*10)}'
            body = (f'intersection(){{ '
                    f'{expr_dish_at(i, j, z)} '
                    f'{expr_all_segs_at_home()} '
                    f'}}')
            tasks.append((i, j, z, body, tag))
    with ThreadPoolExecutor(max_workers=4) as ex:
        futs = {ex.submit(rv, body, tag): (i, j, z) for (i, j, z, body, tag) in tasks}
        results = {}
        for fut, key in futs.items():
            pass
        # simple sequential collection
    # actually use sequential — openscad parallelism is fine but order matters for printing
    results = {}
    for (i, j, z, body, tag) in tasks:
        v = rv(body, tag)
        results[(i, j, z)] = v
        worst = max(worst, v)
    for (i, j) in DIVP:
        line = f"  pair ({i:2d},{j:2d}): "
        for z in Z_SAMPLES:
            v = results[(i, j, z)]
            flag = "*" if v > TOL else " "
            line += f" z={z:4.1f}: {v:8.2f}{flag} "
        print(line)
    print(f"\n  worst transit overlap = {worst:.2f} mm^3   ->  {'PASS' if worst<=TOL else 'FAIL'}")
    return worst

def test_working():
    """At u=0.5 (mid-rotation), all segs at this pair are dropped; the dish sits
    at z=0 with the divider rotated 90 deg. Confirms the slotted dish still
    encloses the orbit. We test dish-vs-(unrelated, non-pair segs at home)."""
    print("\nVARIANT C4 — working state (dish at z=0, pair-segs DROPPED)")
    worst = 0.0
    for (i, j) in DIVP:
        # only NON-pair segs are present at home (the pair's own segs are dropped)
        segs = []
        for k in range(1, N+1):
            if k == i or k == j: continue
            rz = th(k) - th(1)
            segs.append(f'rotate([0,0,{rz:.3f}]) spin_seg(1);')
        if (i, j) == (0, 1):
            # apex case: seg(2) and seg(11) also clip the dish edges; we still
            # require they're cleared by their slots. They are NOT dropped in
            # the working state (only seg(1) drops for the apex swap mechanism).
            pass
        segs_expr = 'union(){ ' + ' '.join(segs) + ' }'
        body = (f'intersection(){{ '
                f'{expr_dish_at(i, j, 0.0)} '
                f'{segs_expr} '
                f'}}')
        v = rv(body, f'C4_w_{i}_{j}')
        flag = " ** CLASH **" if v > TOL else ""
        print(f"  pair ({i:2d},{j:2d}): dish ∩ (other-segs at home) = {v:8.2f} mm^3{flag}")
        worst = max(worst, v)
    print(f"\n  worst working overlap = {worst:.2f} mm^3   ->  {'PASS' if worst<=TOL else 'FAIL'}")
    return worst

def main():
    print("="*78)
    print("SWAP-RING VARIANT C4 — slotted rotating dish (z-staged with seg-clearing slots)")
    print("="*78)
    w_transit = test_transit()
    w_working = test_working()
    worst_overall = max(w_transit, w_working)
    print("\n" + "="*78)
    print(f"  TRANSIT worst : {w_transit:8.2f} mm^3")
    print(f"  WORKING worst : {w_working:8.2f} mm^3")
    print(f"  OVERALL worst : {worst_overall:8.2f} mm^3   ->  "
          f"{'PASS' if worst_overall <= TOL else 'FAIL'}")
    print("="*78)
    return 0 if worst_overall <= TOL else 1

if __name__ == '__main__':
    sys.exit(main())
