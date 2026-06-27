#!/usr/bin/env python3
"""TRACK-2 WALL solid sweep — per-frame collision of the reconfiguring walls vs the balls.

check_confine.py gates the TIMING invariant; this is its SOLID counterpart: it places the real wall
solids (proto_wall.scad) per frame of a DIVIDER swap and booleans them against the balls, catching a
moving wall STRIKING a ball as it drops / rises / rotates. Runs for a RING pair (3,4, tangential
converge) and the APEX pair (0,1, radial converge). Per pair:
  RING-BALL   rising swap-ring + turning divider never hit the pair's balls (they ride inside the dish)
  SEG-BALL    the dropping spin segment(s) never hit their ball(s)
  SWING-SEG   the out-swinging balls clear the still-up adjacent segments
The divider is base-oriented to each pair's converge axis (atan2 of the chord) THEN rotated divRot(u).
"""
import math, struct, subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor

HERE=os.path.dirname(os.path.abspath(__file__)); OPENSCAD="/opt/homebrew/bin/openscad"
SCALE=20/18; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2; apexR=R+24*SCALE
div_t=3.0; orbit=rb+div_t/2+0.5
SEG=40; TOL=1.0; PARK=-22; DZDROP=20

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    if s==0: return (0.0, apexR)
    a=math.radians(A(s)); return (R*math.cos(a), -R*math.sin(a))
def sub(a,b): return (a[0]-b[0],a[1]-b[1])
def nrm(a):
    m=math.hypot(*a); return (a[0]/m,a[1]/m)
def rotz(p,deg):
    a=math.radians(deg); return (p[0]*math.cos(a)-p[1]*math.sin(a), p[0]*math.sin(a)+p[1]*math.cos(a))
def cl(x): return max(0.0,min(1.0,x))
def lerp(p,q,t): return (p[0]+(q[0]-p[0])*t,p[1]+(q[1]-p[1])*t)

def nb(i,j,which,u):                       # in-plane divider kinematics for pair (i,j)
    M=((P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2); T=nrm(sub(P(j),P(i)))
    sgn=-1 if which==i else 1; home=P(i) if which==i else P(j); dest=P(j) if which==i else P(i)
    off=(sgn*orbit*T[0],sgn*orbit*T[1])
    if u<=0.25: q=lerp(home,(M[0]+off[0],M[1]+off[1]),u/0.25)
    elif u<=0.75: r=rotz(off,180*(u-0.25)/0.5); q=(M[0]+r[0],M[1]+r[1])
    else: q=lerp((M[0]-off[0],M[1]-off[1]),dest,(u-0.75)/0.25)
    return (q[0],q[1],eq)
def swz(u):    return PARK + (-PARK)*cl(u/0.20) if u<0.20 else (PARK*cl((u-0.80)/0.20) if u>0.80 else 0.0)
def divrot(u): return 180*cl((u-0.25)/0.50)
def segdz(u):  return DZDROP if 0.18<u<0.82 else (DZDROP*cl((u-0.10)/0.08) if u<=0.18 else DZDROP*cl((0.90-u)/0.08))

def scad(body): return f'use <{HERE}/proto_wall.scad>\n$fn=40;\n{body}\n'
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
def rv(body,tag):
    sf=f'/tmp/w_{tag}.scad'; of=f'/tmp/w_{tag}.stl'
    if os.path.exists(of): os.remove(of)
    open(sf,'w').write(scad(body))
    r=subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    if 'ERROR' in r.stderr: return None
    return vol(of) if os.path.exists(of) else 0.0
def bs(which,i,j,u): p=nb(i,j,which,u); return f'translate([{p[0]:.3f},{p[1]:.3f},{p[2]:.3f}]) ball();'

def sweep(i,j,dropsegs,upsegs,segmod,label):
    M=((P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2); T=nrm(sub(P(j),P(i))); base=math.degrees(math.atan2(T[1],T[0]))
    def frame(k):
        u=k/SEG; sz=swz(u); rot=base+divrot(u); dz=segdz(u)
        balls=f'union(){{ {bs(i,i,j,u)} {bs(j,i,j,u)} }}'
        ring=(f'union(){{ translate([{M[0]:.3f},{M[1]:.3f},{sz:.3f}]) swap_wall(); '
              f'translate([{M[0]:.3f},{M[1]:.3f},{sz:.3f}]) rotate([0,0,{rot:.3f}]) divider(); }}')
        segs='union(){ '+' '.join(f'translate([0,0,{-dz:.3f}]) {segmod}({s});' for s in dropsegs)+' }'
        up  ='union(){ '+' '.join(f'spin_seg({s});' for s in upsegs)+' }'
        return (rv(f'intersection(){{ {ring} {balls} }}',f'rb{i}{k}'),
                rv(f'intersection(){{ {segs} {balls} }}',f'sb{i}{k}'),
                rv(f'intersection(){{ {up} {balls} }}',  f'ss{i}{k}'))
    br=bsg=bw=errs=0
    with ThreadPoolExecutor(max_workers=8) as ex:
        for rbv,sbv,ssv in ex.map(frame,range(SEG+1)):
            if None in (rbv,sbv,ssv): errs+=1; continue
            if rbv>TOL: br+=1
            if sbv>TOL: bsg+=1
            if ssv>TOL: bw+=1
    ok = (br==0 and bsg==0 and bw==0 and errs==0)
    print(f"  [{label}] (pair {i},{j})  RING-BALL {'PASS' if br==0 else f'FAIL({br})'} | "
          f"SEG-BALL {'PASS' if bsg==0 else f'FAIL({bsg})'} | SWING-SEG {'PASS' if bw==0 else f'FAIL({bw})'}"
          + (f" | render-errs {errs}" if errs else ""))
    return ok

# ---- 2-9 depth-multiplex: INTERIOR segment drops, ball pops in to the magnet; OUTER stays ----
DROP29=27.0; RAMP=0.20
def dfr(u):
    s=lambda x:(lambda t:t*t*(3-2*t))(max(0,min(1,x)))
    return s(u/RAMP) if u<RAMP else (s((1-u)/RAMP) if u>1-RAMP else 1.0)
def far(s,u):
    a=P(2) if s==2 else P(9); b=P(9) if s==2 else P(2)
    x=(1-u)*(1-u)*a[0]+u*u*b[0]; y=(1-u)*(1-u)*a[1]+u*u*b[1]    # bow toward centre (control=origin)
    return (x,y, eq - (DROP29*dfr(u) if s==9 else 0.0))
def far29():
    br=bo=errs=0
    def frame(k):
        u=k/SEG; dz=segdz(u)
        out=0; ins=0
        for s in (2,9):
            p=far(s,u); bb=f'translate([{p[0]:.3f},{p[1]:.3f},{p[2]:.3f}]) ball();'
            vi=rv(f'intersection(){{ translate([0,0,{-dz:.3f}]) spin_seg_inner({s}); {bb} }}', f'fi{s}{k}')  # inner drops
            vo=rv(f'intersection(){{ spin_seg_outer({s}); {bb} }}', f'fo{s}{k}')                              # outer stays
            if vi is None or vo is None: return None
            ins=max(ins,vi); out=max(out,vo)
        return ins,out
    with ThreadPoolExecutor(max_workers=8) as ex:
        for r in ex.map(frame,range(SEG+1)):
            if r is None: errs+=1; continue
            if r[0]>TOL: br+=1
            if r[1]>TOL: bo+=1
    ok=(br==0 and bo==0 and errs==0)
    print(f"  [far   2-9 (interior drop)] INNER-DROP {'PASS' if br==0 else f'FAIL({br})'} (dropping interior seg clears the ball) | "
          f"OUTER-STAY {'PASS' if bo==0 else f'FAIL({bo})'} (ball pops inward clear of the staying exterior seg)"+(f' | errs {errs}' if errs else ''))
    return ok

def main():
    print(f"WALL SOLID SWEEP  ({SEG+1} frames/pair, TOL {TOL} mm^3, divider base-oriented to each pair's axis)\n")
    ok =  sweep(3,4,[3,4],[2,5],'spin_seg_outer',"ring  3-4 (tangential, exterior drops)")
    ok &= sweep(0,1,[1],[2,11],'spin_seg_outer',"apex  0-1 (radial, exterior drops)")     # ball 0 = apex (no seg); seg 1 exterior drops
    ok &= far29()
    print()
    if not ok: print("RESULT: FAIL — a reconfiguring wall strikes a ball (see above)."); sys.exit(1)
    print("RESULT: PASS — reconfiguring walls never strike a ball, ring pair and apex pair alike.")
    sys.exit(0)

if __name__=='__main__': main()
