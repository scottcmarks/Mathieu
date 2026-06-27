#!/usr/bin/env python3
"""TRACK-2 (2,9) PROOF — per-frame SOLID boolean sweep against the real fork/ball geometry.

check_29.py proved the kinematics; this proves the SOLIDS. At each frame it builds the two real
carriers (gravity-proof fork + ball, from proto_29.scad) at their computed poses and boolean-tests:
  RETENTION  (once)  — the fork encloses the ball past its equator: top-hole radius < rb AND
                       slip-mouth chord < ball_d, and the ball actually FITS the cup (ball∩fork≈0).
  CARRIER-X  (sweep) — carrier(2) ∩ carrier(9) = 0  (the depth-multiplex must keep them apart)
  REST-2 / REST-9    — each carrier ∩ the 9 resting balls = 0
Gates non-zero on any overlap. Empty intersection => OpenSCAD exits 1 with no file => vol 0 (clean).
"""
import math, struct, subprocess, sys, os, argparse
from concurrent.futures import ThreadPoolExecutor

HERE=os.path.dirname(os.path.abspath(__file__)); OPENSCAD="/opt/homebrew/bin/openscad"
TOL=1.0; SEG=120
SCALE=20/18; R=50*SCALE; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2     # ball_d=20
clr=0.4; fork_dz=4.0; mouth_half=55

def scad(expr): return f'use <{HERE}/proto_29.scad>\n$fn=48;\n{expr}\n'
def vol(path):
    with open(path,'rb') as f: d=f.read()
    # OpenSCAD may output ASCII or binary STL; binary-only parsing silently returns 0 for ASCII (this bug
    # invalidated every solid 'PASS' until 2026-06-25 — Scott caught it visually). Handle BOTH formats.
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
    v=0.0; o=84
    for _ in range(n):
        t=struct.unpack('<12f',d[o:o+48]); o+=50; a,b,c=t[3:6],t[6:9],t[9:12]
        v+=(a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6
    return abs(v)
def render_vol(expr, tag):
    sf=f'/tmp/c29_{tag}.scad'; of=f'/tmp/c29_{tag}.stl'
    if os.path.exists(of): os.remove(of)
    open(sf,'w').write(scad(expr))
    r=subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    if 'ERROR' in r.stderr: return None
    return vol(of) if os.path.exists(of) else 0.0

C2=lambda u: f'union(){{fork_only(2,{u});ball_only(2,{u});}}'
C9=lambda u: f'union(){{fork_only(9,{u});ball_only(9,{u});}}'

def frame(k):
    u=k/SEG
    xx  = render_vol(f'intersection(){{ {C2(u)} {C9(u)} }}',           f'xx{k}')   # carrier2 ∩ carrier9
    r2  = render_vol(f'intersection(){{ {C2(u)} resting_balls(); }}',  f'r2{k}')   # carrier2 ∩ resting
    r9  = render_vol(f'intersection(){{ {C9(u)} resting_balls(); }}',  f'r9{k}')   # carrier9 ∩ resting
    return k,u,xx,r2,r9

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--workers',type=int,default=6); a=ap.parse_args()
    print(f"TRACK-2 (2,9) SOLID SWEEP  ({SEG+1} frames, TOL {TOL} mm^3, ball Ø{ball_d})\n")
    # --- RETENTION (geometric + ball-fits) ---
    top_hole = math.sqrt((rb+clr)**2 - fork_dz**2)          # radius of the opening above the C-lip
    mouth_chord = 2*rb*math.sin(math.radians(mouth_half))    # widest gap of the slip-mouth
    fit = render_vol('intersection(){ fork(0); ball(); }', 'fit')   # ball penetrating the cup wall
    ret_ok = top_hole < rb and mouth_chord < ball_d and (fit or 0) < TOL
    print(f"  RETENTION {'PASS' if ret_ok else 'FAIL'}  top-hole r={top_hole:.2f} < rb {rb} ; "
          f"mouth chord={mouth_chord:.2f} < ball_d {ball_d} ; ball-fits overlap={fit:.2f} mm^3")
    # --- per-frame collision sweep ---
    bad_xx=bad_r2=bad_r9=0; worst_xx=(9e9,None); errs=0
    with ThreadPoolExecutor(max_workers=a.workers) as ex:
        for k,u,xx,r2,r9 in ex.map(frame, range(SEG+1)):
            if xx is None or r2 is None or r9 is None: errs+=1; continue
            # track the *closest approach* of the two carriers (min overlap is 0; we want the
            # frame nearest to touching — reported via the analytic gap, here just flag >TOL)
            if xx>TOL: bad_xx+=1
            if r2>TOL: bad_r2+=1
            if r9>TOL: bad_r9+=1
            if (xx>TOL or r2>TOL or r9>TOL):
                print(f"  frame {k:3d} u={u:4.2f}  C2∩C9={xx:7.2f}  C2∩rest={r2:7.2f}  C9∩rest={r9:7.2f}  **HIT**")
    print()
    def line(n,bad,extra): print(f"  {n:10} {'PASS' if bad==0 else 'FAIL':4}  {extra if bad==0 else f'{bad} frames overlap'}")
    line('CARRIER-X', bad_xx, 'fork+ball of 2 and 9 never collide (they pass in Z)')
    line('REST-2',    bad_r2, "ball-2's carrier clears all 9 resting balls")
    line('REST-9',    bad_r9, "ball-9's carrier clears all 9 resting balls")
    rc = (not ret_ok) or bad_xx or bad_r2 or bad_r9 or errs
    if errs: print(f"\n  render errors: {errs}")
    if rc: print("\nRESULT: FAIL"); sys.exit(1)
    print("\nRESULT: PASS — both balls stay captive in their forks and the carriers never collide")
    print("        nor strike a resting ball, across the whole (2,9) depth-multiplexed swap.")
    sys.exit(0)

if __name__=='__main__': main()
