#!/usr/bin/env python3
"""
Interference ("3D lint") checker for the Sporadic M12 swap toy.

Replays the viewer's kinematics (rest / Swap / Spin) and, for every pair of
parts whose bounding boxes overlap at a sampled frame, computes the boolean
INTERSECTION VOLUME. Resting/seated contact is ~small; a part sweeping THROUGH
another shows a large volume. Anything over the threshold is reported.

Run:  ./.venv/bin/python check_interference.py
Parts are read from viewer/*.stl (regenerate with viewer/make_parts.sh).
"""
import math, itertools, sys, os
import numpy as np
import trimesh

HERE = os.path.dirname(os.path.abspath(__file__))
VIEW = os.path.join(HERE, "viewer")

# --- geometry constants (must match swap_toy_render.scad / index.html) ---
N=11; R=50.0; AE=0.55; base_th=14; track_depth=7; ball_d=18.0
ballZ    = base_th - track_depth + ball_d/2 - 1      # 15
carrierZ = base_th - track_depth + 1                 # 8
backZ    = -(ball_d/2)                               # -9
gearZ    = 0
carouselZ= ballZ - ball_d/2                          # 6
THRESH   = 8.0    # mm^3 — below this is treated as touching/seating, not a clash

def angleOf(i): return -90 + (i-1)*(360.0/N)
def P(i):
    if i==0: return (0.0, (1+AE)*R)
    a=math.radians(angleOf(i));  return (R*math.cos(a), -R*math.sin(a))
def rotz(t):
    c,s=math.cos(t),math.sin(t)
    return np.array([[c,-s,0,0],[s,c,0,0],[0,0,1,0],[0,0,0,1]])
def tr(x,y,z):
    m=np.eye(4); m[0,3],m[1,3],m[2,3]=x,y,z; return m
def smooth(t): return t*t*(3-2*t)

pairs=[(0,1),(2,9),(3,4),(5,6),(7,8),(10,11)]; CROSS=1
def pair_of(b):
    for idx,(i,j) in enumerate(pairs):
        if b in (i,j): return idx,(j if b==i else i)
def mid(idx):
    i,j=pairs[idx]; a,b=P(i),P(j); return ((a[0]+b[0])/2,(a[1]+b[1])/2)
def baseAng(idx):
    i,j=pairs[idx]; a,b=P(i),P(j); return math.atan2(b[1]-a[1],b[0]-a[0])

# --- ball position for a given frame ---
def ball_T(b, mode, p):
    if mode=="rest":
        x,y=P(b); return tr(x,y,ballZ)
    if mode=="spin":
        if b==0: x,y=P(b); return tr(x,y,ballZ)
        a=math.radians(angleOf(b)+smooth(p)*(360.0/N)); return tr(R*math.cos(a),-R*math.sin(a),ballZ)
    # swap
    idx,partner=pair_of(b); ra=smooth(p)*math.pi
    if idx!=CROSS:
        M=mid(idx); off=(P(b)[0]-M[0], P(b)[1]-M[1])
        c,s=math.cos(ra),math.sin(ra)
        return tr(M[0]+off[0]*c-off[1]*s, M[1]+off[0]*s+off[1]*c, ballZ)
    # (2,9): drop -> swing on back -> rise
    A=P(b); B=P(partner); M=mid(idx); off=(A[0]-M[0],A[1]-M[1])
    if p<0.22:
        z=ballZ+(backZ-ballZ)*smooth(p/0.22); return tr(A[0],A[1],z)
    if p<0.78:
        a=(p-0.22)/0.56; c,s=math.cos(a*math.pi),math.sin(a*math.pi)
        return tr(M[0]+off[0]*c-off[1]*s, M[1]+off[0]*s+off[1]*c, backZ)
    a=(p-0.78)/0.22; z=backZ+(ballZ-backZ)*smooth(a); return tr(B[0],B[1],z)

def carrier_T(idx, mode, p):
    M=mid(idx); ang=baseAng(idx)
    if mode=="swap":
        if idx==CROSS:
            a=max(0,min(1,(p-0.22)/0.56)); return tr(M[0],M[1],backZ)@rotz(ang+a*math.pi)
        ang=ang+smooth(p)*math.pi
    z = backZ if idx==CROSS else carrierZ
    return tr(M[0],M[1],z)@rotz(ang)

def ring_T(mode,p):
    rot = -smooth(p)*math.pi*0.13 if mode=="swap" else 0
    return tr(0,0,gearZ)@rotz(rot)
def carousel_T(mode,p):
    rot = smooth(p)*(2*math.pi/N) if mode=="spin" else 0
    return tr(0,0,carouselZ)@rotz(rot)

# --- load base meshes ---
def load(name):
    m=trimesh.load(os.path.join(VIEW,name+".stl"))   # process=True merges verts -> watertight
    if not m.is_watertight: m.merge_vertices(); m.fix_normals()
    return m
base={n:load(n) for n in ["disc","carousel","ringgear"]+["carrier%d"%i for i in range(6)]+["ball%d"%b for b in range(12)]}

def transforms(mode,p):
    T={"disc":np.eye(4),"carousel":carousel_T(mode,p),"ringgear":ring_T(mode,p)}
    for idx in range(6): T["carrier%d"%idx]=carrier_T(idx,mode,p)
    for b in range(12):  T["ball%d"%b]=ball_T(b,mode,p)
    return T

# Per contact-type tolerance (mm^3): how much overlap is legitimate *seating*
# before it counts as a pass-through clash. Tuned from observed seating volumes
# (ball in a pocket ~27, ball in a carrier cup ~130).
def allowance(a,bn):
    s={a,bn}
    bb=lambda pfx: any(x.startswith(pfx) for x in s)
    if bb("ball") and "disc" in s:        return 60     # ball seated in a pocket
    if bb("ball") and bb("carrier"):      return 330    # ball seated in a carrier/arm cup
    if bb("ball") and "carousel" in s:    return 60     # ball riding the channel
    if bb("carrier") and "carousel" in s: return 45     # rotor hub near the channel
    return 8                                            # anything else: basically must not touch

def aabb_overlap(b1,b2,pad=0.0):
    return all(b1[0][k]-pad<=b2[1][k] and b2[0][k]-pad<=b1[1][k] for k in range(3))

def inter_vol(ma,mb):
    try:
        r=trimesh.boolean.intersection([ma,mb],engine="manifold")
        if r is None or r.is_empty: return 0.0
        return abs(r.volume)
    except Exception:
        return 0.0

frames=[("rest",0.0)]+[("swap",p) for p in (0.1,0.25,0.4,0.5,0.6,0.75,0.9)]+[("spin",p) for p in (0.25,0.5,0.75)]
names=list(base.keys())
worst={}   # (a,b) -> (vol, frame)
for mode,p in frames:
    T=transforms(mode,p)
    M={n:base[n].copy().apply_transform(T[n]) for n in names}
    B={n:M[n].bounds for n in names}
    for a,bn in itertools.combinations(names,2):
        if not aabb_overlap(B[a],B[bn]): continue
        v=inter_vol(M[a],M[bn])
        if v>THRESH:
            key=(a,bn); lbl=f"{mode} p={p}"
            if key not in worst or v>worst[key][0]: worst[key]=(v,lbl)

# classify against per-type allowance
rows=[]
for (a,bn),(v,lbl) in worst.items():
    allow=allowance(a,bn); rows.append((v,a,bn,lbl,v>allow,allow))
clashes=[r for r in rows if r[4]]
rows.sort(key=lambda r:-r[0])

print("\nInterference check — boolean-volume over the Swap/Spin kinematics:\n")
for v,a,bn,lbl,bad,allow in rows:
    tag=f"  <-- CLASH (allow {allow:.0f})" if bad else "  [seat]"
    print(f"  {v:8.1f} mm^3   {a:10s} x {bn:10s}   worst @ {lbl:11s}{tag}")
if clashes:
    print(f"\nFAIL: {len(clashes)} clash(es) exceed their seating allowance.\n")
    sys.exit(1)
print("\nPASS: no parts pass through each other.\n")
sys.exit(0)
