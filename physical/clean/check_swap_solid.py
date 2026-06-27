#!/usr/bin/env python3
"""PER-FRAME SOLID SWEEP — the rigorous boolean check the analytic sweep can't give.

check_assembly.py samples the swap at 121 frames but models balls/drums as PRIMITIVES
(spheres vs cylinders, penetration depth + tolerance).  This script instead, at each of the
SAME 121 frames (u = k/120, k = 0..120 -- identical numbering to the viewer's transport), places
the REAL ball solids at their computed positions and BOOLEAN-INTERSECTS them against the ACTUAL
printed part STLs in their actual pose:

    structure(u) = notched band (static)
                 + deck            translated z by -EASE*engageFrac(u)
                 + 5 drums         each rotated 180*drumFrac(u) about its centre, dropped with deck
                 + apex rotor      rotated 180*epte(u) about mid(0,1)
    balls(u)     = 12 spheres (r = rb) at ballpos(s,u)

    interference(u) = volume( structure(u)  ∩  balls(u) )      # must be ~0 every frame

A correctly-channelled ball sits in CARVED VOID, so the intersection is empty; any nonzero volume
means a ball is poking through a real wall / roof / cradle at that frame.  Gates non-zero if any
frame exceeds TOL_VOL.  Kinematics mirror assembly_compact.html EXACTLY so reported frame numbers
match what you see (and can pause on) in the viewer.

  usage:  .venv/bin/python clean/check_swap_solid.py [--frames 0,60,120] [--workers 4]
"""
import math, struct, subprocess, sys, os, tempfile, argparse
from concurrent.futures import ThreadPoolExecutor

HERE   = os.path.dirname(os.path.abspath(__file__))
OPENSCAD = "/opt/homebrew/bin/openscad"
TOL_VOL  = 1.0          # mm^3 ; below this is facet noise (channels have 0.4 mm running clearance)

# ---- constants (mirror assembly_compact.html / proto_band.scad) ----
N=11; SCALE=1.25; R=50*SCALE; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2; apexR=R+24*SCALE
tube=rb+0.3; RD=rb+0.5; FP=RD+rb+1; CR=R-RD-1; CLEAR=CR-FP
spin_top=eq+math.sqrt(tube*tube-rb*rb)+1.5; EASE=(spin_top-eq)+1.5
FRAMES=120

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    if s==0: return [0.0,apexR]
    a=math.radians(A(s)); return [R*math.cos(a),-R*math.sin(a)]
def mid(i,j): return [(P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2]
def radf(p): return math.hypot(p[0],p[1])
def uni(p):
    r=radf(p); return [p[0]/r,p[1]/r]
def rot2(p,c,a):
    co,si=math.cos(a),math.sin(a); dx,dy=p[0]-c[0],p[1]-c[1]
    return [c[0]+dx*co-dy*si, c[1]+dx*si+dy*co]
def lerp(p,q,t): return [p[0]+(q[0]-p[0])*t, p[1]+(q[1]-p[1])*t]
ALLP=[[0,1],[2,9],[3,4],[5,6],[7,8],[10,11]]
INNER=[p for p in ALLP if 0 not in p]
def far(i,j): return radf(mid(i,j))<CR-4
def drumC(i,j):
    if far(i,j): return [0.0,0.0]
    u=uni(mid(i,j)); return [u[0]*CR,u[1]*CR]
def drumAxd(i,j):
    if far(i,j): return math.atan2(mid(i,j)[1],mid(i,j)[0])-math.pi/2
    C=drumC(i,j); return math.atan2(C[1],C[0])+math.pi/2
def entries(i,j):
    C=drumC(i,j); a=drumAxd(i,j); t=[math.cos(a),math.sin(a)]
    return [[C[0]+t[0]*RD,C[1]+t[1]*RD],[C[0]-t[0]*RD,C[1]-t[1]*RD]]
def pairof(s):
    for p in ALLP:
        if s in p: return p,(0 if p[0]==s else 1)

def routed(i,j,which,u):
    home=P(i) if which==0 else P(j); away=P(j) if which==0 else P(i); e=entries(i,j)
    eh=e[0] if which==0 else e[1]; ea=e[1] if which==0 else e[0]; C=drumC(i,j); isf=far(i,j); z=eq-EASE
    if u<=0.10: return [home[0],home[1], eq-EASE*(u/0.10)]
    if u<=0.32:
        s=(u-0.10)/0.22
        if isf:
            w=[uni(home)[0]*(CLEAR-1),uni(home)[1]*(CLEAR-1)]
            q=lerp(home,w,s/0.5) if s<0.5 else lerp(w,eh,(s-0.5)/0.5); return [q[0],q[1],z]
        q=lerp(home,eh,s); return [q[0],q[1],z]
    if u<=0.68:
        q=rot2(eh,C,math.pi*((u-0.32)/0.36)); return [q[0],q[1],z]
    if u<=0.90:
        s=(u-0.68)/0.22
        if isf:
            w=[uni(away)[0]*(CLEAR-1),uni(away)[1]*(CLEAR-1)]
            q=lerp(ea,w,s/0.5) if s<0.5 else lerp(w,away,(s-0.5)/0.5); return [q[0],q[1],z]
        q=lerp(ea,away,s); return [q[0],q[1],z]
    return [away[0],away[1], eq-EASE*((1.0-u)/0.10)]
def epte(t): return 2*t*t if t<0.5 else 1-((-2*t+2)**2)/2
def apexBall(which,u):
    q=rot2(P(0) if which==0 else P(1), mid(0,1), math.pi*epte(u)); return [q[0],q[1],eq]
def ballpos(s,u):
    p,w=pairof(s); return apexBall(w,u) if p==[0,1] else routed(p[0],p[1],w,u)
def engageFrac(u): return u/0.10 if u<0.10 else (1-u)/0.10 if u>0.90 else 1.0
def drumFrac(u):   return 0.0 if u<0.32 else 1.0 if u>0.68 else (u-0.32)/0.36

# ---- per-frame SCAD ----
def imp(name): return f'import("{HERE}/{name}");'
def frame_scad(u):
    dz   = -EASE*engageFrac(u)
    dang = 180*drumFrac(u)
    aang = 180*epte(u)
    M    = mid(0,1)
    parts=[ imp("proto_band_compact.stl"),
            f'translate([0,0,{dz:.5f}]) {imp("proto_deck_compact.stl")}' ]
    for k,pr in enumerate(INNER):
        C=drumC(pr[0],pr[1])
        parts.append(f'translate([0,0,{dz:.5f}]) translate([{C[0]:.5f},{C[1]:.5f},0]) '
                     f'rotate([0,0,{dang:.5f}]) translate([{-C[0]:.5f},{-C[1]:.5f},0]) '
                     f'{imp(f"proto_drum{k}_compact.stl")}')
    parts.append(f'translate([{M[0]:.5f},{M[1]:.5f},0]) rotate([0,0,{aang:.5f}]) '
                 f'translate([{-M[0]:.5f},{-M[1]:.5f},0]) {imp("proto_apex_compact.stl")}')
    balls=[]
    for s in range(12):
        x,y,z=ballpos(s,u)
        balls.append(f'translate([{x:.5f},{y:.5f},{z:.5f}]) sphere(r={rb},$fn=48);')
    return ("$fn=48;\nintersection(){\n union(){\n  " + "\n  ".join(parts)
            + "\n }\n union(){\n  " + "\n  ".join(balls) + "\n }\n}\n")

def stl_volume(path):
    with open(path,'rb') as f: data=f.read()
    if len(data)<84: return 0.0
    n=struct.unpack('<I',data[80:84])[0]
    if 84+n*50==len(data):                          # binary STL
        if n==0: return 0.0
        vol=0.0; off=84
        for _ in range(n):
            v=struct.unpack('<12f', data[off:off+48]); off+=50
            a,b,c=v[3:6],v[6:9],v[9:12]
            vol+=(a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6.0
        return abs(vol)
    # ASCII STL fallback
    nums=[];
    for line in data.decode('ascii','ignore').splitlines():
        t=line.split()
        if t[:1]==['vertex']: nums.append((float(t[1]),float(t[2]),float(t[3])))
    vol=0.0
    for i in range(0,len(nums)-2,3):
        a,b,c=nums[i],nums[i+1],nums[i+2]
        vol+=(a[0]*(b[1]*c[2]-b[2]*c[1])-a[1]*(b[0]*c[2]-b[2]*c[0])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6.0
    return abs(vol)

def run_frame(k, outdir):
    u=k/FRAMES
    scad=os.path.join(outdir,f'f{k:03d}.scad'); stl=os.path.join(outdir,f'f{k:03d}.stl')
    with open(scad,'w') as f: f.write(frame_scad(u))
    r=subprocess.run([OPENSCAD,"-o",stl,scad],capture_output=True,text=True)
    # NOTE: an EMPTY intersection (the desired no-overlap result) makes OpenSCAD exit 1 with
    # "Current top level object is empty" and write NO file -> that is vol 0, NOT an error.
    real_err = "ERROR" in r.stderr
    if os.path.exists(stl):
        vol=stl_volume(stl); err=real_err
    else:
        vol=0.0; err=real_err                       # no file + no ERROR => empty intersection => clean
    return k,u,vol,err,(r.stderr.strip().splitlines()[-1] if err and r.stderr.strip() else "")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--frames",default=None,help="comma list, else all 0..120")
    ap.add_argument("--workers",type=int,default=4)
    ap.add_argument("--keep",action="store_true",help="keep per-frame STL/SCAD")
    a=ap.parse_args()
    ks = [int(x) for x in a.frames.split(",")] if a.frames else list(range(FRAMES+1))
    outdir = os.path.join(HERE,"_swap_solid"); os.makedirs(outdir,exist_ok=True)
    print(f"PER-FRAME SOLID SWEEP  ({len(ks)} frames, ball O{ball_d:.1f}, TOL {TOL_VOL} mm^3, {a.workers} workers)")
    print(f"  structure = notched band + deck + 5 drums + apex, each in its frame-u pose\n")
    results={}
    with ThreadPoolExecutor(max_workers=a.workers) as ex:
        for k,u,vol,err,msg in ex.map(lambda k:run_frame(k,outdir), ks):
            results[k]=(u,vol,err,msg)
            flag = "RENDER-ERR" if err else ("**HIT**" if vol>TOL_VOL else "ok")
            if err or vol>TOL_VOL:
                print(f"  frame {k:3d}  u={u:4.2f}  vol={vol:8.2f} mm^3  {flag}  {msg}")
    hits=[k for k in ks if results[k][1]>TOL_VOL and not results[k][2]]
    errs=[k for k in ks if results[k][2]]
    worst=max(ks,key=lambda k:results[k][1])
    print(f"\n  worst frame: {worst} (vol {results[worst][1]:.2f} mm^3)")
    print(f"  render errors: {len(errs)} {errs if errs else ''}")
    if not a.keep:
        import shutil; shutil.rmtree(outdir,ignore_errors=True)
    if errs:
        print("\nRESULT: INCONCLUSIVE — some frames failed to render (see above)."); sys.exit(2)
    if hits:
        print(f"\nRESULT: FAIL — {len(hits)} frame(s) have a ball penetrating a solid: {hits}"); sys.exit(1)
    print(f"\nRESULT: PASS — every frame's ball solids stay within the carved voids "
          f"(max overlap {results[worst][1]:.2f} < {TOL_VOL} mm^3).")
    sys.exit(0)

if __name__=="__main__": main()
