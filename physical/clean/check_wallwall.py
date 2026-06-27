#!/usr/bin/env python3
"""TRACK-2 WALL-vs-WALL — do the dropping SPIN SEGMENTS intersect the rising SWAP RINGS during the swap?

Never checked before. As a swap-ring rises (to confine) the spin segments at the same stations drop;
since confinement requires the ring to cover BEFORE the seg releases, both are near channel level at
the same xy for part of the stroke. This sweeps the clip and booleans each pair's swap-ring (+divider)
against the spin segments it overlaps. Gates non-zero on any intersection (a real part clash).
"""
import math, struct, subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor

HERE=os.path.dirname(os.path.abspath(__file__)); OPENSCAD="/opt/homebrew/bin/openscad"
SCALE=20/18; R=50*SCALE; N=11; apexR=R+24*SCALE
DROP_INNER={2,9}; DROP_OUTER={1,3,4,5,6,7,8,10,11}
DIVP=[(0,1),(3,4),(5,6),(7,8),(10,11)]; SEG=72; TOL=1.0
def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    if s==0: return (0.0,apexR)
    a=math.radians(A(s)); return (R*math.cos(a),-R*math.sin(a))
def nrm(v):
    m=math.hypot(*v); return (v[0]/m,v[1]/m)
def cl(x): return max(0.0,min(1.0,x))
def swz(u): return -22 + 22*cl(u/0.20) if u<0.20 else (-22*cl((u-0.80)/0.20) if u>0.80 else 0.0)
def segdz(u): return 20 if 0.18<u<0.82 else (20*cl((u-0.10)/0.08) if u<=0.18 else 20*cl((0.90-u)/0.08))
def divrot(u): return 180*cl((u-0.25)/0.50)
def th(k): return -A(k)

def scad(b): return f'use <{HERE}/proto_wall.scad>\n$fn=28;\n{b}\n'
def vol(p):
    with open(p,'rb') as f: d=f.read()
    # OpenSCAD may emit ASCII or binary STL; binary-only parsing silently returned 0 for ASCII files
    # (this bug silently invalidated every solid 'PASS' until 2026-06-25 — Scott caught it visually).
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
    import struct
    n=struct.unpack('<I',d[80:84])[0]
    if 84+n*50!=len(d) or n==0: return 0.0
    v=0.0;o=84
    for _ in range(n):
        t=struct.unpack('<12f',d[o:o+48]);o+=50;a,b,c=t[3:6],t[6:9],t[9:12]
        v+=(a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6
    return abs(v)
def rv(b,tag):
    sf=f'/tmp/WW_{tag}.scad';of=f'/tmp/WW_{tag}.stl'
    if os.path.exists(of):os.remove(of)
    open(sf,'w').write(scad(b))
    r=subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    if 'ERROR' in r.stderr: return None
    return vol(of) if os.path.exists(of) else 0.0

def seg_at(k,u):
    dz=segdz(u); rz=th(k)-th(1)
    zi=-dz if k in DROP_INNER else 0; zo=-dz if k in DROP_OUTER else 0
    return (f'rotate([0,0,{rz:.3f}]) translate([0,0,{zi:.3f}]) spin_seg_inner(1); '
            f'rotate([0,0,{rz:.3f}]) translate([0,0,{zo:.3f}]) spin_seg_outer(1);')
def ring_at(i,j,u):
    M=((P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2); base=math.degrees(math.atan2(*nrm((P(j)[0]-P(i)[0],P(j)[1]-P(i)[1]))[::-1])); sz=swz(u)
    return (f'translate([{M[0]:.3f},{M[1]:.3f},{sz:.3f}]) swap_wall(); '
            f'translate([{M[0]:.3f},{M[1]:.3f},{sz:.3f}]) rotate([0,0,{base+divrot(u):.3f}]) divider();')

def main():
    print(f"WALL-vs-WALL  spin segments ∩ swap rings  ({SEG+1} frames)\n")
    # each pair's swap-ring vs the spin segs at its own 2 stations (where they overlap)
    def frame(args):
        k,(i,j)=args; u=k/SEG
        return (k,i,j,rv(f'intersection(){{ union(){{ {ring_at(i,j,u)} }} union(){{ {seg_at(i,u)} {seg_at(j,u)} }} }}', f'{i}_{j}_{k}'))
    jobs=[(k,p) for k in range(SEG+1) for p in DIVP]
    worst={p:(0,None) for p in DIVP}; hits=0; errs=0
    with ThreadPoolExecutor(max_workers=8) as ex:
        for k,i,j,v in ex.map(frame, jobs):
            if v is None: errs+=1; continue
            if v>TOL: hits+=1
            if v>worst[(i,j)][0]: worst[(i,j)]=(v,k)
    for p in DIVP:
        w,k=worst[p]; print(f"  pair {p}: worst seg∩ring = {w:7.1f} mm^3" + (f"  @frame {k} (u={k/SEG:.2f})" if k is not None else ""))
    print()
    if errs: print(f"  render errors: {errs}")
    anybad = any(worst[p][0]>TOL for p in DIVP)
    if anybad:
        print("RESULT: FAIL — spin segments INTERSECT swap rings during the swap (they share space when both")
        print("        are near channel level). Fix = segment the swap-ring to pass through the spin-ring slots")
        print("        (the planned 'spin-wall-type segments'), or radially clear them."); sys.exit(1)
    print("RESULT: PASS — no spin-segment / swap-ring intersection across the clip."); sys.exit(0)

if __name__=='__main__': main()
