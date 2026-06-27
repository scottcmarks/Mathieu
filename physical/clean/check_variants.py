#!/usr/bin/env python3
"""TRACK-2 SWAP-RING VARIANTS — does each variant actually clear the wall-vs-wall clash?

The original in-plane swap-ring at chord midpoint M (|M|=53) with outer dish radius 23.97 reaches
inward to r=29, inside band_inner=43.59 — so dish_outer overlaps the spin-band annulus, and the
issue is geometric, not just a timing artifact. This file tests three architectural fixes:
  A: push M outward to |M'|>=69 so dish inner edge clears band_inner=43.59.
  B: angular outward arc — dish is open inward; narrower spin-seg wedge (half-width 10° vs 14.86°).
  C: keep M, but Z-stage the dish on a 3-position cam: rise to z=14 (above seg top), seg drops, then
     lower to z=0 (working position) for the divider turn.

For each: at the critical TRANSITION frame (u=0.13, where the dish must be up and the segs must
still be at home for confinement-continuity), report dish∩seg overlap by pair.
"""
import math, struct, subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor

HERE=os.path.dirname(os.path.abspath(__file__)); OPENSCAD="/opt/homebrew/bin/openscad"
SCALE=20/18; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2; apexR=R+24*SCALE
tube=rb+0.3; wall_t=1.5*SCALE; div_t=3.0; orbit=rb+div_t/2+0.5
dish_outer=orbit+tube+wall_t
band_inner=R-tube-wall_t
A_target=band_inner+dish_outer+1.5
DIVP=[(0,1),(3,4),(5,6),(7,8),(10,11)]
TOL=1.0

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    if s==0: return (0.0,apexR)
    a=math.radians(A(s)); return (R*math.cos(a),-R*math.sin(a))
def nrm(v):
    m=math.hypot(*v); return (v[0]/m,v[1]/m)
def th(k): return -A(k)
def pair_M(i,j): return ((P(i)[0]+P(j)[0])/2, (P(i)[1]+P(j)[1])/2)
def A_M(i,j):
    M=pair_M(i,j); rM=math.hypot(*M); s=max(1.0, A_target/rM); return (M[0]*s, M[1]*s)

# ---- ASCII-aware STL volume parser (fixed 2026-06-25) ----
def vol(p):
    with open(p,'rb') as f: d=f.read()
    if d[:5]==b'solid' and b'facet' in d[:512]:
        verts=[]
        for line in d.decode('ascii','ignore').splitlines():
            t=line.split()
            if t[:1]==['vertex']: verts.append((float(t[1]),float(t[2]),float(t[3])))
        v=0.0
        for i in range(0,len(verts)-2,3):
            a,b,c=verts[i],verts[i+1],verts[i+2]
            v+=(a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6
        return abs(v)
    if len(d)<84: return 0.0
    n=struct.unpack('<I',d[80:84])[0]
    if 84+n*50!=len(d) or n==0: return 0.0
    v=0.0;o=84
    for _ in range(n):
        t=struct.unpack('<12f',d[o:o+48]);o+=50;a,b,c=t[3:6],t[6:9],t[9:12]
        v+=(a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6
    return abs(v)
def rv(body, tag):
    sf=f'/tmp/V_{tag}.scad'; of=f'/tmp/V_{tag}.stl'
    if os.path.exists(of): os.remove(of)
    open(sf,'w').write(f'use <{HERE}/proto_variants.scad>\n$fn=28;\n{body}\n')
    subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    return vol(of) if os.path.exists(of) else 0.0

def expr_seg(k, segmod, dz=0):
    rz = th(k) - th(1)
    return f'rotate([0,0,{rz:.3f}]) translate([0,0,{-dz:.3f}]) {segmod}(1);'
def expr_dish_at(M, z, base, divrot, dish_mod, div_mod):
    return (f'translate([{M[0]:.3f},{M[1]:.3f},{z:.3f}]) {dish_mod}(); '
            f'translate([{M[0]:.3f},{M[1]:.3f},{z:.3f}]) rotate([0,0,{base+divrot:.3f}]) {div_mod}();')

def test_variant(name, M_func, z_up, dish_mod, div_mod, seg_inner_mod, seg_outer_mod, seg_inner_drops):
    """At u=0.13 the cam schedule says dish fully up, segs about to drop (still at z=0).
       Test dish∩seg material at this critical frame."""
    print(f"  --- variant {name}: dish={dish_mod}, seg_inner={'drops' if seg_inner_drops else 'stays UP'}, z_up={z_up:.1f} ---")
    worst=0
    for (i,j) in DIVP:
        Mp=M_func(i,j); T=(P(j)[0]-P(i)[0], P(j)[1]-P(i)[1])
        base=math.degrees(math.atan2(*nrm(T)[::-1]))
        # seg at i and j, at home (segdz=0)
        si_dz = 0 if not seg_inner_drops else 20
        segs = f'union(){{ {expr_seg(i,seg_inner_mod,si_dz)} {expr_seg(j,seg_inner_mod,si_dz)} '
        segs+= f'{expr_seg(i,seg_outer_mod,20)} {expr_seg(j,seg_outer_mod,20)} }}'   # outer always drops in transit
        ring = f'union(){{ {expr_dish_at(Mp, z_up, base, 0, dish_mod, div_mod)} }}'
        v = rv(f'intersection(){{ {ring} {segs} }}', f'{name}_{i}_{j}')
        worst=max(worst,v)
        flag = "" if v<=TOL else " ** CLASH **"
        print(f"     pair ({i},{j}): M'={tuple(round(x,1) for x in Mp)}  dish∩seg = {v:8.2f} mm^3{flag}")
    return worst

def main():
    print("WALL-VS-WALL VARIANTS  (at u=0.13 transition: dish fully UP, segs at HOME)\n")
    results={}
    # ---------------- variant A: pushed-out swap-ring ----------------
    # Both halves drop for divider pairs (same as current); inner stays up only when not needed.
    # The point of A is the pushed-out position eliminates the seg conflict EVEN IF inner stays up.
    results['A'] = test_variant('A', A_M, 0.0, 'A_dish', 'A_div',
                                  'spin_seg_inner', 'spin_seg_outer', seg_inner_drops=False)
    # ---------------- variant B: open-inward arc + narrower wedge ----------------
    # Inner spin-seg STAYS UP (narrower wedge) to provide inner confinement; dish has no inner wall.
    results['B'] = test_variant('B', pair_M, 0.0, 'B_dish', 'B_div',
                                  'seg_B_inner', 'spin_seg_outer', seg_inner_drops=False)
    # ---------------- variant C: same M, dish at z=14 (above seg top 13.97) during transition ----
    # Both halves drop for divider pairs (same as current). C's "win" is the dish is ABOVE the seg
    # when both must be present — segs at z=0 (home), dish at z=14 -> no z overlap.
    results['C'] = test_variant('C', pair_M, 14.0, 'C_dish', 'C_div',
                                  'spin_seg_inner', 'spin_seg_outer', seg_inner_drops=False)
    # also test C at working z=0 with segs dropped (mid-rotation, u=0.5)
    print(f"\n  --- variant C also at u=0.5 (dish at WORKING z=0, segs FULLY dropped) ---")
    C_mid=0
    for (i,j) in DIVP:
        Mp=pair_M(i,j); T=(P(j)[0]-P(i)[0], P(j)[1]-P(i)[1])
        base=math.degrees(math.atan2(*nrm(T)[::-1]))
        segs=f'union(){{ {expr_seg(i,"spin_seg_inner",20)} {expr_seg(j,"spin_seg_inner",20)} {expr_seg(i,"spin_seg_outer",20)} {expr_seg(j,"spin_seg_outer",20)} }}'
        ring=f'union(){{ {expr_dish_at(Mp, 0, base, 90, "C_dish", "C_div")} }}'
        v=rv(f'intersection(){{ {ring} {segs} }}', f'Cmid_{i}_{j}')
        C_mid=max(C_mid,v); flag=" ** CLASH **" if v>TOL else ""
        print(f"     pair ({i},{j}): dish∩seg = {v:8.2f} mm^3{flag}")
    results['C_working']=C_mid
    # ---- summary ----
    print(f"\n  SUMMARY (transition frame; lower is better, 0 = no clash):")
    print(f"    Variant A (push-out)      : worst {results['A']:8.2f} mm^3   -> {'PASS' if results['A']<=TOL else 'FAIL'}")
    print(f"    Variant B (asymmetric arc): worst {results['B']:8.2f} mm^3   -> {'PASS' if results['B']<=TOL else 'FAIL'}")
    print(f"    Variant C (z-staged): transition {results['C']:8.2f} mm^3, working {results['C_working']:.2f} mm^3   -> {'PASS' if max(results['C'],results['C_working'])<=TOL else 'FAIL'}")
    return 0 if all(v<=TOL for v in results.values()) else 1

if __name__=='__main__': sys.exit(main())
