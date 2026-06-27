#!/usr/bin/env python3
"""TRACK-2 (2,9) MAGNET-MODE gate — validates the magnet-grip carrier (steel balls + captive magnets).

The fork retains GEOMETRICALLY (C-lip past the equator, gated by check_29_solid.py). The magnet grip
retains by FORCE, so its gate is different:
  MAGNETICS (a defensible disc-magnet field model; conservative Maxwell-stress scaling):
    HOLD-FORCE   the magnet holds a steel ball against worst-case load (any orientation + dynamic)
    SPIN-DETENT  a PARKED magnet's residual pull on a ball at the ring is below perceptibility
    NEIGH-GRAB   a RAISED (grabbing) magnet doesn't drag the adjacent resting balls
  SOLIDS (per-frame boolean sweep of the real magnet-carrier geometry from proto_29.scad):
    CARRIER-X    carrier(2) ∩ carrier(9) = 0   (depth-multiplex keeps them apart)
    REST-2/9     each carrier ∩ the 9 resting balls = 0
Gates non-zero on any failure. Force model assumptions are printed so they can be challenged.
"""
import math, struct, subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor

HERE=os.path.dirname(os.path.abspath(__file__)); OPENSCAD="/opt/homebrew/bin/openscad"
mu0=4e-7*math.pi
# ---- ball + magnet parameters ----
rb=10.0e-3; rho=7850; g=9.81   # Ø20 steel ball
m_solid=rho*4/3*math.pi*rb**3; m_hollow=rho*4*math.pi*rb**2*1.0e-3
Br=1.30                 # N42 NdFeB residual flux density (T)
a_m=7.0e-3; h_m=4.0e-3  # magnet disc Ø14x4 (matches proto_29.scad)
A_m=math.pi*a_m**2
kd=0.5                  # sphere-vs-plate derate on the Maxwell hold (conservative)
z_grab=1.0e-3           # magnet face -> ball surface at grab (thin cup floor ~0.8mm + clearance)
z_park=32.0e-3          # magnet face -> ball surface when parked deep (carrier recessed ~40mm)
z_neigh=26.0e-3         # raised magnet -> a NEIGHBOUR ball's surface (~1 station away)
DYN=2.0                 # dynamic factor (jostle/shake) on the load
MARGIN=3.0              # required hold / load

def Baxial(z):          # on-axis field of an axially-magnetised disc magnet, distance z from its face
    return (Br/2)*((z+h_m)/math.sqrt((z+h_m)**2+a_m**2) - z/math.sqrt(z**2+a_m**2))
def Fmag(z):            # Maxwell-stress pull (conservative: treats the ball as a flat pole of area A_m)
    return kd*Baxial(z)**2*A_m/(2*mu0)

# ---- SOLIDS sweep helpers (mirror check_29_solid.py) ----
SEG=120; TOL=1.0
def scad(expr): return f'use <{HERE}/proto_29.scad>\n$fn=48;\n{expr}\n'
def vol(path):
    d=open(path,'rb').read()
    # OpenSCAD may emit ASCII or binary STL; binary-only parsing silently returned 0 for ASCII files
    # (this bug silently invalidated every solid 'PASS' until 2026-06-25 — Scott caught it visually).
    if d[:5]==b'solid' and b'facet' in d[:512]:
        verts=[]
        for line in d.decode('ascii','ignore').splitlines():
            t=line.split()
            if t[:1]==['vertex']: verts.append((float(t[1]),float(t[2]),float(t[3])))
        v=0.0
        for i in range(0,len(verts)-2,3):
            A,B,C=verts[i],verts[i+1],verts[i+2]
            v+=(A[0]*(B[1]*C[2]-B[2]*C[1])-A[1]*(B[0]*C[2]-B[2]*C[0])+A[2]*(B[0]*C[1]-B[1]*C[0]))/6
        return abs(v)
    if len(d)<84: return 0.0
    n=struct.unpack('<I',d[80:84])[0]
    if 84+n*50!=len(d) or n==0: return 0.0
    v=0.0;o=84
    for _ in range(n):
        t=struct.unpack('<12f',d[o:o+48]);o+=50;A,B,C=t[3:6],t[6:9],t[9:12]
        v+=(A[0]*(B[1]*C[2]-B[2]*C[1])-A[1]*(B[0]*C[2]-B[2]*C[0])+A[2]*(B[0]*C[1]-B[1]*C[0]))/6
    return abs(v)
def render_vol(expr,tag):
    sf=f'/tmp/m29_{tag}.scad';of=f'/tmp/m29_{tag}.stl'
    if os.path.exists(of):os.remove(of)
    open(sf,'w').write(scad(expr))
    r=subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    if 'ERROR' in r.stderr: return None
    return vol(of) if os.path.exists(of) else 0.0
MC=lambda w,u: f'union(){{magbody_only({w},{u});magdisc_only({w},{u});ball_only({w},{u});}}'
def frame(k):
    u=k/SEG
    xx=render_vol(f'intersection(){{ {MC(2,u)} {MC(9,u)} }}', f'xx{k}')
    r2=render_vol(f'intersection(){{ {MC(2,u)} resting_balls(); }}', f'r2{k}')
    r9=render_vol(f'intersection(){{ {MC(9,u)} resting_balls(); }}', f'r9{k}')
    return k,xx,r2,r9

def main():
    print("TRACK-2 (2,9) MAGNET-MODE GATE\n")
    print(f"  [model] N42 disc Ø{a_m*2e3:.0f}x{h_m*1e3:.0f}, Br={Br:.2f}T; on-axis disc field; Maxwell-stress hold, sphere derate {kd};")
    print(f"          standoffs: grab {z_grab*1e3:.1f}mm, parked {z_park*1e3:.0f}mm, neighbour {z_neigh*1e3:.0f}mm\n")
    Fh=Fmag(z_grab); Fp=Fmag(z_park); Fn=Fmag(z_neigh)
    w_solid=m_solid*g; w_hollow=m_hollow*g
    load=DYN*w_solid                     # worst case: solid ball, hanging, with dynamic factor
    hold_ok = Fh >= MARGIN*load
    # spin detent: parked residual must be a small fraction of ball weight AND small absolute
    det_ok = Fp < 0.10*w_solid and Fp < 0.05
    # neighbour: raised magnet's pull on a neighbour ball must not unseat it (< its weight, well under a detent)
    neigh_ok = Fn < 0.5*w_solid

    def line(n,ok,extra): print(f"  {n:11} {'PASS' if ok else 'FAIL':4}  {extra}")
    print(f"  ball weight: solid {w_solid*1e3:.0f} mN  hollow {w_hollow*1e3:.0f} mN   (x12 = {m_solid*12*1e3:.0f} / {m_hollow*12*1e3:.0f} g)")
    line('HOLD-FORCE', hold_ok, f'hold {Fh:.1f} N vs worst load {load:.2f} N (solid x{DYN:.0f} dyn) = {Fh/load:.0f}x  (need {MARGIN:.0f}x; hollow {Fh/(DYN*w_hollow):.0f}x)')
    line('SPIN-DETENT', det_ok, f'parked residual {Fp*1e3:.2f} mN = {100*Fp/w_solid:.2f}% of ball weight (need <10% & <50mN) -> spin unaffected')
    line('NEIGH-GRAB', neigh_ok, f'raised-magnet pull on a neighbour {Fn*1e3:.1f} mN = {100*Fn/w_solid:.0f}% of ball weight (need <50%) -> neighbour stays seated')

    print("\n  SOLIDS (per-frame magnet-carrier collision sweep)...")
    bx=b2=b9=0; errs=0
    with ThreadPoolExecutor(max_workers=8) as ex:
        for k,xx,r2,r9 in ex.map(frame, range(SEG+1)):
            if None in (xx,r2,r9): errs+=1; continue
            if xx>TOL: bx+=1
            if r2>TOL: b2+=1
            if r9>TOL: b9+=1
    line('CARRIER-X', bx==0, 'magnet carriers 2 & 9 never collide (pass in Z)')
    line('REST-2',    b2==0, "carrier-2 clears all 9 resting balls")
    line('REST-9',    b9==0, "carrier-9 clears all 9 resting balls")

    ok = hold_ok and det_ok and neigh_ok and bx==0 and b2==0 and b9==0 and errs==0
    if errs: print(f"\n  render errors: {errs}")
    print()
    if not ok: print("RESULT: FAIL"); sys.exit(1)
    print("RESULT: PASS — magnet grip holds the steel ball in any orientation with margin, the parked")
    print("        magnet doesn't disturb spin or neighbours, and the carriers never collide.")
    if Fp >= 0.02: print("        (note: if the parked residual ever feels detent-y in print, add a steel keeper behind the magnet.)")
    sys.exit(0)

if __name__=='__main__': main()
