#!/usr/bin/env python3
"""TRACK-2 FULL CONCURRENT SWEEP — all six pairs swap AT ONCE; the integration test.

Per-pair checks can't see cross-pair interference. This fires the WHOLE perm #22 simultaneously
(5 divider pairs in-plane + 2-9 depth-multiplex) and checks, every frame:
  BALL-BALL   none of the 12 balls collide (all 66 pairs) -- the cross-pair test (analytic, all frames)
  RINGS       the 5 risen swap-rings don't foul each other (static, at full rise)        (solid)
  BALL-WALL   union(12 balls) ∩ union(all walls: segs + swap-rings + dividers + lid) ≈ 0 (solid, coarse)
"""
import math, struct, subprocess, sys, os, itertools
from concurrent.futures import ThreadPoolExecutor

HERE=os.path.dirname(os.path.abspath(__file__)); OPENSCAD="/opt/homebrew/bin/openscad"
SCALE=20/18; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2; apexR=R+24*SCALE
div_t=3.0; orbit=rb+div_t/2+0.5; DROP=27.0; RAMP=0.20; ENG=0.14; REL=0.14
DROP_INNER={2,9}; DROP_OUTER={1,3,4,5,6,7,8,10,11}
DIVP=[(0,1),(3,4),(5,6),(7,8),(10,11)]; TOL=1.0

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    if s==0: return (0.0,apexR)
    a=math.radians(A(s)); return (R*math.cos(a),-R*math.sin(a))
def sub(a,b): return (a[0]-b[0],a[1]-b[1])
def nrm(a):
    m=math.hypot(*a); return (a[0]/m,a[1]/m)
def rotz(p,deg):
    a=math.radians(deg); return (p[0]*math.cos(a)-p[1]*math.sin(a),p[0]*math.sin(a)+p[1]*math.cos(a))
def cl(x): return max(0.0,min(1.0,x))
def lerp(p,q,t): return (p[0]+(q[0]-p[0])*t,p[1]+(q[1]-p[1])*t)
def d3(a,b): return math.dist(a,b)
def ss(x): x=cl(x); return x*x*(3-2*x)
def dfr(u): return ss(u/RAMP) if u<RAMP else (ss((1-u)/RAMP) if u>1-RAMP else 1.0)

def divpair(i,j,which,u):
    M=((P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2); T=nrm(sub(P(j),P(i)))
    sgn=-1 if which==i else 1; home=P(i) if which==i else P(j); dest=P(j) if which==i else P(i)
    off=(sgn*orbit*T[0],sgn*orbit*T[1])
    if u<=0.25: q=lerp(home,(M[0]+off[0],M[1]+off[1]),u/0.25)
    elif u<=0.75: r=rotz(off,180*(u-0.25)/0.5); q=(M[0]+r[0],M[1]+r[1])
    else: q=lerp((M[0]-off[0],M[1]-off[1]),dest,(u-0.75)/0.25)
    return (q[0],q[1],eq)
def far(s,u):
    a=P(2) if s==2 else P(9); b=P(9) if s==2 else P(2)
    # bow toward the dead CENTRE (quadratic bezier, control=origin) so the 2-9 crossing ducks INSIDE
    # the divider inward-swings (r41); 2 & 9 still meet at the centre but pass in Z (depth-multiplex).
    x=(1-u)**2*a[0] + u*u*b[0]; y=(1-u)**2*a[1] + u*u*b[1]      # control at (0,0) -> middle term vanishes
    return (x,y, eq-(DROP*dfr(u) if s==9 else 0.0))
def allballs(u):
    pos={}
    for (i,j) in DIVP: pos[i]=divpair(i,j,i,u); pos[j]=divpair(i,j,j,u)
    pos[2]=far(2,u); pos[9]=far(9,u)
    return pos

# ---- solid helpers ----
def scad(b): return f'use <{HERE}/proto_wall.scad>\nuse <{HERE}/proto_lid.scad>\n$fn=32;\n{b}\n'
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
    sf=f'/tmp/F_{tag}.scad';of=f'/tmp/F_{tag}.stl'
    if os.path.exists(of): os.remove(of)
    open(sf,'w').write(scad(b))
    r=subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    if 'ERROR' in r.stderr: return None
    return vol(of) if os.path.exists(of) else 0.0
def swz(u): return -22 + 22*cl(u/0.20) if u<0.20 else (-22*cl((u-0.80)/0.20) if u>0.80 else 0.0)
def segdz(u): return 20 if 0.18<u<0.82 else (20*cl((u-0.10)/0.08) if u<=0.18 else 20*cl((0.90-u)/0.08))
def divrot(u): return 180*cl((u-0.25)/0.50)
def th(k): return -A(k)

def walls_scad(u):
    dz=segdz(u); parts=[]
    for k in range(1,12):
        rz=th(k)-th(1)
        zi = -dz if k in DROP_INNER else 0; zo = -dz if k in DROP_OUTER else 0
        parts.append(f'rotate([0,0,{rz:.3f}]) translate([0,0,{zi:.3f}]) spin_seg_inner(1);')   # rotate the k=1 seg into place
        parts.append(f'rotate([0,0,{rz:.3f}]) translate([0,0,{zo:.3f}]) spin_seg_outer(1);')
    for (i,j) in DIVP:
        M=((P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2); base=math.degrees(math.atan2(*nrm(sub(P(j),P(i)))[::-1])); sz=swz(u); rot=base+divrot(u)
        parts.append(f'translate([{M[0]:.3f},{M[1]:.3f},{sz:.3f}]) swap_wall();')
        parts.append(f'translate([{M[0]:.3f},{M[1]:.3f},{sz:.3f}]) rotate([0,0,{rot:.3f}]) divider();')
    parts.append('lid();')
    return 'union(){ '+' '.join(parts)+' }'
def balls_scad(u):
    pos=allballs(u)
    return 'union(){ '+' '.join(f'translate([{p[0]:.3f},{p[1]:.3f},{p[2]:.3f}]) sphere(r={rb},$fn=28);' for p in pos.values())+' }'

def main():
    workers=8; SEG_BB=200; SEG_SOLID=16
    print("FULL CONCURRENT SWEEP  (perm #22, all 6 pairs at once)\n")
    # ---- BALL-BALL (analytic, all frames) ----
    bb=0; worst=(0,None)
    for k in range(SEG_BB+1):
        u=k/SEG_BB; pos=allballs(u); ids=list(pos)
        for a,b in itertools.combinations(ids,2):
            pen=ball_d-d3(pos[a],pos[b])
            if pen>0.4:
                bb+=1
                if pen>worst[0]: worst=(pen,(a,b,round(u,2)))
    print(f"  BALL-BALL  {'PASS' if bb==0 else 'FAIL':4}  none of the 12 balls collide ({bb} bad)"
          + (f"; worst {worst}" if worst[1] else ""))
    # ---- RINGS (solid, static, all swap-rings at full rise u=0.5) ----
    ringexpr='; '.join(f'translate([{(P(i)[0]+P(j)[0])/2:.3f},{(P(i)[1]+P(j)[1])/2:.3f},0]) swap_wall();' for (i,j) in DIVP)
    rr=0; bad=[]
    for a,b in itertools.combinations(DIVP,2):
        Ma=((P(a[0])[0]+P(a[1])[0])/2,(P(a[0])[1]+P(a[1])[1])/2); Mb=((P(b[0])[0]+P(b[1])[0])/2,(P(b[0])[1]+P(b[1])[1])/2)
        v=rv(f'intersection(){{ translate([{Ma[0]:.3f},{Ma[1]:.3f},0]) swap_wall(); translate([{Mb[0]:.3f},{Mb[1]:.3f},0]) swap_wall(); }}', f'rr{a}{b}')
        if v and v>TOL: rr+=1; bad.append(f"{a}∩{b}={v:.0f}")
    print(f"  RINGS      {'PASS' if rr==0 else 'FAIL':4}  the 5 risen swap-rings don't foul each other"+(f' ({"; ".join(bad)})' if bad else ''))
    # ---- BALL-WALL (solid, coarse) ----
    def frame(k):
        u=k/SEG_SOLID; return rv(f'intersection(){{ {walls_scad(u)} {balls_scad(u)} }}', f'bw{k}')
    bw=0; errs=0; worstbw=(0,None)
    with ThreadPoolExecutor(max_workers=workers) as ex:
        for k,v in zip(range(SEG_SOLID+1), ex.map(frame, range(SEG_SOLID+1))):
            if v is None: errs+=1; continue
            if v>TOL: bw+=1
            if v>worstbw[0]: worstbw=(v,k)
    print(f"  BALL-WALL  {'PASS' if bw==0 else 'FAIL':4}  no ball penetrates any wall/lid ({bw} bad frames; worst {worstbw[0]:.1f} mm^3 @frame {worstbw[1]})"
          + (f"; render-errs {errs}" if errs else ""))
    ok = bb==0 and rr==0 and bw==0 and errs==0
    print()
    if not ok: print("RESULT: FAIL — concurrent interference (see above)."); sys.exit(1)
    print("RESULT: PASS — all six pairs swap simultaneously with no ball-ball, ring-ring, or ball-wall collision.")
    sys.exit(0)

if __name__=='__main__': main()
