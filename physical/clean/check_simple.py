#!/usr/bin/env python3
"""TRACK-2 SIMPLE-WALLS interference checker — per-frame solid boolean sweep.

UPGRADED 2026-07-06 (Scott: "upgrade"):
  * EVERY frame checked (FRAMES=120 — the full clip, no sub-sampling).
  * ALL FOUR pair mechanisms in the unions (was only (5,6)); all pair balls animate.
  * The APEX (0,1) mechanism swept: vertical ring (rises 21), blade (π about world X),
    balls 0 & 1 on their vertical orbit — vs everything else.
  * BALL 0 included in ball-vs-ball and ball-vs-wall.
  * NEW gate WALLS-vs-LID: every mover vs the lid solid (imported from the rendered
    proto_lid.stl so the heavy lid CSG isn't re-evaluated per frame). Verifies the
    ring slits/bridges, pockets, apex slit + transit torus.
  * POSITIVE CONTROLS at startup — aborts loudly if any key solid renders empty
    (the silent-zero family: ASCII STL, missing use<>, undef params, bad cwd).

Gates per frame:
  swap_vs_spin   all swap walls (4 pairs + central + apex ring) ∩ spin rings
  div_vs_spin    all dividers (4 pairs + central + apex blade) ∩ spin rings
  div_vs_swap    all dividers ∩ all swap walls
  ball_vs_wall   balls 0..11 ∩ (rings + swap walls + dividers)
  ball_vs_div    balls 0..11 ∩ dividers
  walls_vs_lid   (rings + swap walls + dividers) ∩ lid
  ball_vs_ball   all C(12,2) pairs (analytic)

Mirrors viewer_simple.html kinematics EXACTLY.
"""
import math, struct, subprocess, sys, os, itertools
from concurrent.futures import ThreadPoolExecutor

HERE   = os.path.dirname(os.path.abspath(__file__))
OPENSCAD = "/opt/homebrew/bin/openscad"
LID_STL  = os.path.join(HERE, 'proto_lid.stl')
TOL    = 1.0           # mm^3
FRAMES = 120           # EVERY frame of the 120-frame clip

# ---- mirror proto_simple.scad constants ----
SCALE=20/18; R=50*SCALE+2; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2
wall_t=2.0; wall_h=rb+0.5
clr=0.4
inner_R_spin=R-rb-clr-wall_t/2          # 46.16
outer_R_spin=R+rb+clr+wall_t/2          # 68.96
orbit_swap = R*math.sin(math.pi/N)      # 16.21 — pair half-chord
outer_R_swap = orbit_swap + rb + clr + wall_t/2 + 0.5   # 28.11 — pair/central ring centerline
div_thin = 3*wall_t                     # 6.0
COMMON_STROKE = 21
LIFT_SEG_UP = COMMON_STROKE
PARK_DEPTH_DIV = COMMON_STROKE
PARK_DEPTH_SWAP = COMMON_STROKE

PAIRS = [(3,4), (5,6), (7,8), (10,11)]
PAIR_OF = {}
for (i,j) in PAIRS:
    PAIR_OF[i] = (i,j); PAIR_OF[j] = (i,j)

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    a=math.radians(A(s)); return (R*math.cos(a), -R*math.sin(a))
def mid(i,j): return ((P(i)[0]+P(j)[0])/2, (P(i)[1]+P(j)[1])/2)
def nrm(v):
    m=math.hypot(*v); return (v[0]/m, v[1]/m)
def chord_ang(i,j):
    T = nrm((P(j)[0]-P(i)[0], P(j)[1]-P(i)[1]))
    return math.atan2(T[1], T[0])

# ---- kinematics (mirror viewer_simple.html) ----
def ss(x): x=max(0.0,min(1.0,x)); return x*x*(3-2*x)
def ramp(u,a,b): return max(0.0,min(1.0,(u-a)/(b-a)))
def srmp(u,a,b): return ss(ramp(u,a,b))
def spinRingZ(u):
    return LIFT_SEG_UP * (srmp(u, 0.00, 0.20) - srmp(u, 0.80, 1.00))
def swapWallZ(u):
    upT = srmp(u, 0.00, 0.20) - srmp(u, 0.80, 1.00)
    return -PARK_DEPTH_SWAP * (1 - upT)
def divRotAccum(u):
    # 2026-07-07: initial/final π/2 turns removed — dividers rest in their WORKING
    # orientation and do only the π swap turn.
    return math.pi * srmp(u, 0.35, 0.65)
def dividerZ(u):
    # Back on the rigid elevator frame (a ⊥-chord blade rises cleanly between resting balls).
    upT = srmp(u, 0.00, 0.20) - srmp(u, 0.80, 1.00)
    return -PARK_DEPTH_DIV * (1 - upT)

# Central (2,9)
AZ2 = math.atan2(P(2)[1], P(2)[0])
AZ9 = math.atan2(P(9)[1], P(9)[0])
D29_2 = ((AZ9 - AZ2) % (2*math.pi) + 2*math.pi) % (2*math.pi)
D29_9 = 2*math.pi - D29_2
CENTRAL_R = outer_R_swap
R_ORB29 = CENTRAL_R - wall_t/2 - rb - clr
CENTRAL_P_AZ = math.atan2(mid(3,4)[1] + mid(7,8)[1], mid(3,4)[0] + mid(7,8)[0]) + math.pi
CENTRAL_DIV_BASE = CENTRAL_P_AZ - math.pi/2   # working start (long axis on P)

# Apex (0,1)
APEX_H  = 12*SCALE                 # 13.33 — half-chord
APEX_CY = R + APEX_H               # 70.89 — ring center Y
APEX_PARK = 21
def apexRingZ(u):
    upT = srmp(u, 0.00, 0.20) - srmp(u, 0.80, 1.00)
    return -APEX_PARK * (1 - upT)
def apexRot(u):
    return math.pi * srmp(u, 0.35, 0.65)

def ballPose(s, u):
    if s in (0, 1):
        home    = (0, R + 2*APEX_H, eq) if s == 0 else (0, R, eq)
        partner = (0, R, eq)            if s == 0 else (0, R + 2*APEX_H, eq)
        if u <= 0.35: return home
        if u >= 0.65: return partner
        a0 = math.pi if s == 1 else 0.0
        a = a0 + math.pi * srmp(u, 0.35, 0.65)
        return (0, APEX_CY + APEX_H*math.cos(a), eq + APEX_H*math.sin(a))
    if s in (2, 9):
        azIn  = AZ2 if s == 2 else AZ9
        azOut = AZ9 if s == 2 else AZ2
        dAng  = D29_2 if s == 2 else D29_9
        if u <= 0.20: return (R*math.cos(azIn), R*math.sin(azIn), eq)
        if u < 0.35:
            t = srmp(u, 0.20, 0.35); r = R + (R_ORB29 - R)*t
            return (r*math.cos(azIn), r*math.sin(azIn), eq)
        if u < 0.65:
            t = srmp(u, 0.35, 0.65); a = azIn + dAng*t
            return (R_ORB29*math.cos(a), R_ORB29*math.sin(a), eq)
        if u < 0.80:
            t = srmp(u, 0.65, 0.80); r = R_ORB29 + (R - R_ORB29)*t
            return (r*math.cos(azOut), r*math.sin(azOut), eq)
        return (R*math.cos(azOut), R*math.sin(azOut), eq)
    # in-plane pair ball (all four pairs animate)
    i, j = PAIR_OF[s]
    M = mid(i, j)
    home_pos = P(s); partner_pos = P(j if s == i else i)
    if u <= 0.35: return (*home_pos, eq)
    if u >= 0.65: return (*partner_pos, eq)
    d = nrm((home_pos[0]-M[0], home_pos[1]-M[1]))
    a = math.atan2(d[1], d[0]) + math.pi * srmp(u, 0.35, 0.65)
    return (M[0]+orbit_swap*math.cos(a), M[1]+orbit_swap*math.sin(a), eq)

# ---- ASCII-aware STL parser ----
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
    sf=f'/tmp/SI_{tag}.scad'; of=f'/tmp/SI_{tag}.stl'
    if os.path.exists(of): os.remove(of)
    open(sf,'w').write(f'use <{HERE}/proto_simple.scad>\n$fn=28;\n{body}\n')
    subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    return vol(of) if os.path.exists(of) else 0.0

# ---- SCAD-string helpers for placed parts at frame u ----
def rings_scad(u):
    return f'translate([0,0,{spinRingZ(u):.3f}]) {{ spin_ring_inner(); spin_ring_outer(); }}'
def pair_swap_scad(i, j, u):
    return f'translate([0,0,{swapWallZ(u):.3f}]) swap_ring({i},{j});'
def pair_div_scad(i, j, u):
    M = mid(i, j)
    rot = math.degrees(chord_ang(i, j) + divRotAccum(u))   # rest = working: blade ⊥ chord
    return f'translate([{M[0]:.3f},{M[1]:.3f},{dividerZ(u):.3f}]) rotate([0,0,{rot:.3f}]) divider_simple({i},{j});'
def central_scad(u):
    return f'translate([0,0,{swapWallZ(u):.3f}]) swap_ring_central();'
def cdiv_scad(u):
    rot = math.degrees(CENTRAL_DIV_BASE + divRotAccum(u))   # rest = working: long axis on line P
    return f'translate([0,0,{dividerZ(u):.3f}]) rotate([0,0,{rot:.3f}]) divider_central();'
def apex_ring_scad(u):
    return f'translate([0,0,{apexRingZ(u):.3f}]) swap_ring_apex_vertical();'
def apex_div_scad(u):
    cz = eq + apexRingZ(u)
    return f'translate([0,{APEX_CY:.3f},{cz:.3f}]) rotate([{math.degrees(apexRot(u)):.3f},0,0]) divider_apex();'
def lid_scad():
    return f'import("{LID_STL}");'
def ball_scad(s, u):
    x,y,z = ballPose(s,u); return f'translate([{x:.3f},{y:.3f},{z:.3f}]) sphere(r={rb},$fn=28);'

def all_swaps_scad(u):
    return ' '.join(pair_swap_scad(i,j,u) for (i,j) in PAIRS) + f' {central_scad(u)} {apex_ring_scad(u)}'
def all_divs_scad(u):
    return ' '.join(pair_div_scad(i,j,u) for (i,j) in PAIRS) + f' {cdiv_scad(u)} {apex_div_scad(u)}'

GATES = ['swap_vs_spin','div_vs_spin','div_vs_swap','ball_vs_wall','ball_vs_div','walls_vs_lid']

def frame_check(k):
    u = k/FRAMES
    rings = rings_scad(u)
    swaps = all_swaps_scad(u)
    divs  = all_divs_scad(u)
    balls = ' '.join(ball_scad(s,u) for s in range(0, N+1))
    out = {}
    out['swap_vs_spin'] = rv(f'intersection(){{ union(){{ {swaps} }} union(){{ {rings} }} }}', f'ss{k}')
    out['div_vs_spin']  = rv(f'intersection(){{ union(){{ {divs} }} union(){{ {rings} }} }}',  f'ds{k}')
    out['div_vs_swap']  = rv(f'intersection(){{ union(){{ {divs} }} union(){{ {swaps} }} }}',  f'd_sw{k}')
    out['ball_vs_wall'] = rv(f'intersection(){{ union(){{ {balls} }} union(){{ {rings} {swaps} {divs} }} }}', f'bw{k}')
    out['ball_vs_div']  = rv(f'intersection(){{ union(){{ {balls} }} union(){{ {divs} }} }}',  f'bd{k}')
    out['walls_vs_lid'] = rv(f'intersection(){{ union(){{ {rings} {swaps} {divs} }} {lid_scad()} }}', f'wl{k}')
    bb = 0; worst_bb=(0,None)
    pos = [ballPose(s,u) for s in range(0, N+1)]
    for a, b in itertools.combinations(range(len(pos)),2):
        pen = ball_d - math.dist(pos[a], pos[b])
        if pen>0.4:
            bb+=1
            if pen>worst_bb[0]: worst_bb=(pen,(a,b))
    out['ball_vs_ball'] = (bb, worst_bb)
    return k, u, out

def positive_controls():
    """Abort loudly if any key solid renders empty — the silent-zero family."""
    checks = [
        ('lid (imported STL)',   lid_scad(),               10000),
        ('spin rings',           rings_scad(0.0),           5000),
        ('pair swap ring (5,6)', pair_swap_scad(5,6,0.0),   3000),
        ('pair divider (5,6)',   pair_div_scad(5,6,0.0),    1000),
        ('central ring+tubes',   central_scad(0.0),         3000),
        ('apex ring',            apex_ring_scad(0.0),       1000),
        ('apex blade',           apex_div_scad(0.0),         500),
    ]
    ok = True
    for name, scad, floor_ in checks:
        v = rv(scad, 'ctl_' + name.split()[0].strip('(),'))
        status = 'ok' if v > floor_ else 'EMPTY/TOO-SMALL'
        if v <= floor_: ok = False
        print(f"  control {name:24} {v:10.1f} mm^3  {status}")
    # detection control: two deliberately-overlapping cubes must intersect
    v = rv('intersection(){ cube(10); translate([5,5,5]) cube(10); }', 'ctl_overlap')
    print(f"  control {'overlap detection':24} {v:10.1f} mm^3  {'ok' if abs(v-125)<5 else 'BROKEN'}")
    if abs(v-125) >= 5: ok = False
    if not ok:
        print("\nABORT: a positive control failed — the boolean pipeline cannot be trusted.")
        sys.exit(2)

def main():
    print(f"SIMPLE-WALLS INTERFERENCE SWEEP — {FRAMES+1} frames (EVERY frame), all 6 mechanisms + lid\n")
    print("  positive controls:")
    positive_controls()
    print()
    hits = {k:0 for k in GATES + ['ball_vs_ball']}
    worst = {k:(0,None) for k in hits}
    with ThreadPoolExecutor(max_workers=8) as ex:
        for k, u, out in ex.map(frame_check, range(FRAMES+1)):
            line_bits = []
            for key in GATES:
                v = out[key]
                if v>TOL:
                    hits[key]+=1
                    if v>worst[key][0]: worst[key]=(v,k)
                    line_bits.append(f"{key}={v:.1f}")
            bb, wbb = out['ball_vs_ball']
            if bb>0:
                hits['ball_vs_ball']+=1
                if wbb[0]>worst['ball_vs_ball'][0]: worst['ball_vs_ball']=wbb
                line_bits.append(f"ball-ball pen={wbb[0]:.2f}mm pair={wbb[1]}")
            if line_bits: print(f"  frame {k:3d} (u={u:.3f}): " + "  ".join(line_bits))
    print()
    print(f"  SUMMARY (over {FRAMES+1} frames — every frame of the clip):")
    for key in GATES:
        h, w = hits[key], worst[key]
        mark = "PASS" if h==0 else "FAIL"
        print(f"    {key:15} {mark}  {h:3d} bad frames; worst {w[0]:.1f} mm^3 @ frame {w[1] if w[1] is not None else '—'}")
    h, w = hits['ball_vs_ball'], worst['ball_vs_ball']
    mark = "PASS" if h==0 else "FAIL"
    print(f"    {'ball_vs_ball':15} {mark}  {h:3d} bad frames; worst pen {w[0]:.2f}mm pair={w[1]}")
    rc = sum(hits.values())
    print()
    if rc==0:
        print(f"RESULT: PASS — no interference detected (TOL={TOL} mm^3, every frame).")
        sys.exit(0)
    else:
        print(f"RESULT: FAIL — {rc} category-frames have interference. Geometry needs revision.")
        sys.exit(1)

if __name__=='__main__': main()
