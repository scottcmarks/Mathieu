#!/usr/bin/env python3
"""TRACK-2 SIMPLE-WALLS interference checker — per-frame solid boolean sweep.

Scott called out (visually, from viewer_simple.html) three real bugs the viewer didn't catch:
  frame 6:   swap walls intersect spin walls (full 360° swap ring overlaps inner spin-wall arc)
  frame 51:  balls counter-rotate through each other; ball 6 intersects the divider
  frame 112: spin wall ∩ swap wall, swap wall ∩ ball, divider ∩ spin wall (no slots)

This script samples FRAMES across the (5,6) swap clip and at each frame booleans:
  SWAP-vs-SPIN     swap walls (at z = swapWallZ) ∩ spin segs (at z = spinSegZ(k,u))
  DIV-vs-SPIN      divider (at dividerPose) ∩ spin segs at their current z
  BALL-vs-WALL     each ball sphere ∩ union of all walls + divider
  BALL-vs-BALL     all C(12,2) pairs of ball spheres (analytic — fast)
  BALL-vs-DIV      each ball ∩ divider

Mirrors viewer_simple.html kinematics EXACTLY (including the FIXED same-direction orbit).
Uses the ASCII-aware vol() parser from check_29_solid.py.
"""
import math, struct, subprocess, sys, os, itertools, re
from concurrent.futures import ThreadPoolExecutor

HERE   = os.path.dirname(os.path.abspath(__file__))
OPENSCAD = "/opt/homebrew/bin/openscad"
TOL    = 1.0           # mm^3
FRAMES = 24            # sample density for solid checks (every 5 frames of the 120-frame clip)

# ---- mirror proto_simple.scad constants ----
SCALE=20/18; R=50*SCALE+2; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2   # R +2 mm (Scott 2026-07-03)
wall_t=2.0; wall_h=rb+0.5
clr=0.4
inner_R_spin=R-rb-clr-wall_t/2          # 44.66
outer_R_spin=R+rb+clr+wall_t/2          # 66.46
gap_deg=5.0                              # widened so divider fits through inter-seg gap
half_angle=360/N/2 - gap_deg/2
# UPDATED: ball stays at half-chord distance from M throughout the orbit (no radial transit)
orbit_swap = 2*R*math.sin(math.pi/N)/2   # 15.63 — half-chord from M (== station distance)
outer_R_swap = orbit_swap + rb + clr + wall_t/2 + 0.5   # mirror proto_simple.scad pair_outer_R (+0.5 fudge since ring shrink)
# Blade divider (all pairs like the 0-1 paddle): thin 6 along chord, long ≈50.8 perpendicular
div_thin = 3*wall_t                       # 6.0
div_ext  = 2*(outer_R_swap - wall_t) - 1.2  # blade length for pair (5,6)
# COMMON STROKE (Scott 2026-07-03): segs, swap walls, and dividers all travel the same 21 mm
# in the same u-window so they can be rigidly attached to one common movement piece.
COMMON_STROKE = 21
LIFT_SEG_UP = COMMON_STROKE      # segs RISE UP into lid THROUGH-SLOTS; must clear ball top at Z=20
PARK_DEPTH_DIV = COMMON_STROKE   # divider parks 21 below (was 13) — rides the common frame
PARK_DEPTH_SWAP = COMMON_STROKE  # swap walls park 21 below (was 11) — ride the common frame
PARK_DEPTH = LIFT_SEG_UP         # alias for backward-compat (segs)

PAIR_I, PAIR_J = 5, 6

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    a=math.radians(A(s)); return (R*math.cos(a), -R*math.sin(a))
def th(s): return -A(s)
def mid(i,j): return ((P(i)[0]+P(j)[0])/2, (P(i)[1]+P(j)[1])/2)
def nrm(v):
    m=math.hypot(*v); return (v[0]/m, v[1]/m)
Mp = mid(PAIR_I, PAIR_J)
T_chord = nrm((P(PAIR_J)[0]-P(PAIR_I)[0], P(PAIR_J)[1]-P(PAIR_I)[1]))
chord_base_ang = math.atan2(T_chord[1], T_chord[0])

# ---- kinematics (mirror viewer_simple.html) ----
def ss(x): x=max(0.0,min(1.0,x)); return x*x*(3-2*x)
def ramp(u,a,b): return max(0.0,min(1.0,(u-a)/(b-a)))
def srmp(u,a,b): return ss(ramp(u,a,b))
# Phased schedule (UNIFIED — spin segs, swap walls, and divider all rise/drop over the same
# u=[0.00, 0.20] / [0.80, 1.00] windows; divider rotates through u=[0.20, 0.80] (same as balls))
#   [0.00, 0.20] spin segs at 5,6 rise + swap walls + divider rise (all together)
#   [0.20, 0.35] balls transit inward to orbit
#   [0.35, 0.65] divider rotates π (both balls same direction)
#   [0.65, 0.80] balls transit outward to swapped stations
#   [0.80, 1.00] spin segs at 5,6 drop + swap walls + divider drop (all together)
# CONTINUOUS RINGS (2026-07-03): per-station segments replaced by two one-piece rings
# (spin_ring_inner / spin_ring_outer in proto_simple.scad — continuous except the 4 paddle
# slots + station-1 outer wedge gap). Both rings ride the elevator frame: the WHOLE rings
# lift LIFT_SEG_UP together during the swap.
def spinRingZ(u):
    return LIFT_SEG_UP * (srmp(u, 0.00, 0.20) - srmp(u, 0.80, 1.00))
def swapWallZ(u):
    upT = srmp(u, 0.00, 0.20) - srmp(u, 0.80, 1.00)
    return -PARK_DEPTH_SWAP * (1 - upT)
def dividerPose(u):
    upT = srmp(u, 0.00, 0.20) - srmp(u, 0.80, 1.00)
    z = -PARK_DEPTH_DIV * (1 - upT)
    rot = math.pi * srmp(u, 0.35, 0.65)             # dividers turn only while balls 2,9 are INSIDE the central ring
    return Mp[0], Mp[1], z, chord_base_ang + rot

# Central (2,9) constants — mirror viewer_simple.html
AZ2 = math.atan2(P(2)[1], P(2)[0])
AZ9 = math.atan2(P(9)[1], P(9)[0])
D29_2 = ((AZ9 - AZ2) % (2*math.pi) + 2*math.pi) % (2*math.pi)   # +130.91° CCW (ball 2)
D29_9 = 2*math.pi - D29_2                                        # +229.09° CCW (ball 9)
CENTRAL_R = outer_R_swap                                          # 28.11 — full pair-ring size
R_ORB29 = CENTRAL_R - wall_t/2 - rb - clr                         # 16.71 — orbit radius inside central ring
CENTRAL_P_AZ = math.atan2(mid(3,4)[1] + mid(7,8)[1], mid(3,4)[0] + mid(7,8)[0]) + math.pi  # line P azimuth
CENTRAL_DIV_BASE = CENTRAL_P_AZ - math.pi/2

def ballPose(s, u):
    if s in (2, 9):
        # tunnel IN (0.20–0.35) → CCW orbit inside central ring (0.35–0.65) → tunnel OUT (0.65–0.80)
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
    if s not in (PAIR_I, PAIR_J): return (*P(s), eq)
    home_pos = P(s); partner_pos = P(PAIR_J if s==PAIR_I else PAIR_I)
    dir_to_home    = nrm((home_pos[0]-Mp[0],    home_pos[1]-Mp[1]))
    # Balls stay at station distance from M; orbit synchronously with the dividers (u 0.35–0.65).
    if u <= 0.35:      xy = home_pos
    elif u <= 0.65:
        t = srmp(u, 0.35, 0.65)                # same-direction π orbit
        startAng = math.atan2(dir_to_home[1], dir_to_home[0])
        ang = startAng + math.pi * t
        xy = (Mp[0]+orbit_swap*math.cos(ang), Mp[1]+orbit_swap*math.sin(ang))
    else:              xy = partner_pos
    return (xy[0], xy[1], eq)

# ---- ASCII-aware STL parser (the fixed one) ----
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
    r=subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    return vol(of) if os.path.exists(of) else 0.0

# ---- SCAD-string helpers for placed parts at frame u ----
def rings_scad(u):
    z = spinRingZ(u)
    return f'translate([0,0,{z:.3f}]) {{ spin_ring_inner(); spin_ring_outer(); }}'
def swap_scad(u):    return f'translate([0,0,{swapWallZ(u):.3f}]) swap_ring({PAIR_I},{PAIR_J});'
def div_scad(u):
    x,y,z,a = dividerPose(u); ang=math.degrees(a)
    # NB: must pass (i,j) — a bare divider_simple() yields an EMPTY solid (undef params) and
    # silently zeroes every divider gate. Caught 2026-07-03; same silent-zero family as the
    # ASCII-STL and missing-use bugs.
    return f'translate([{x:.3f},{y:.3f},{z:.3f}]) rotate([0,0,{ang:.3f}]) divider_simple({PAIR_I},{PAIR_J});'
def ball_scad(s, u):
    x,y,z = ballPose(s,u); return f'translate([{x:.3f},{y:.3f},{z:.3f}]) sphere(r={rb},$fn=28);'
def central_scad(u):
    return f'translate([0,0,{swapWallZ(u):.3f}]) swap_ring_central();'
def cdiv_scad(u):
    _,_,z,_ = dividerPose(u)
    rot = math.degrees(CENTRAL_DIV_BASE) + 180*srmp(u, 0.35, 0.65)
    return f'translate([0,0,{z:.3f}]) rotate([0,0,{rot:.3f}]) divider_central();'

def frame_check(k):
    u = k/FRAMES
    segs_all = rings_scad(u)
    walls_div = f'{swap_scad(u)} {div_scad(u)} {central_scad(u)} {cdiv_scad(u)}'
    all_walls = f'{segs_all} {walls_div}'
    balls = ' '.join(ball_scad(s,u) for s in range(1,N+1))
    out = {}
    out['swap_vs_spin'] = rv(f'intersection(){{ {swap_scad(u)} union(){{ {segs_all} }} }}', f'ss{k}')
    out['div_vs_spin']  = rv(f'intersection(){{ {div_scad(u)}  union(){{ {segs_all} }} }}', f'ds{k}')
    out['div_vs_swap']  = rv(f'intersection(){{ {div_scad(u)}  {swap_scad(u)} }}',          f'd_sw{k}')
    out['ball_vs_wall'] = rv(f'intersection(){{ union(){{ {balls} }} union(){{ {all_walls} }} }}', f'bw{k}')
    out['ball_vs_div']  = rv(f'intersection(){{ union(){{ {balls} }} {div_scad(u)} }}',     f'bd{k}')
    # ball-ball analytic
    bb = 0; worst_bb=(0,None)
    pos = [ballPose(s,u) for s in range(1,N+1)]
    for a, b in itertools.combinations(range(len(pos)),2):
        pen = ball_d - math.dist(pos[a], pos[b])
        if pen>0.4:
            bb+=1
            if pen>worst_bb[0]: worst_bb=(pen,(a+1,b+1))
    out['ball_vs_ball'] = (bb, worst_bb)
    return k, u, out

def main():
    print(f"SIMPLE-WALLS INTERFERENCE SWEEP  ({FRAMES+1} frames sampled across the (5,6) swap clip)")
    print(f"  (mirror of viewer_simple.html with FIXED same-direction ball orbit)\n")
    hits = {k:0 for k in ['swap_vs_spin','div_vs_spin','div_vs_swap','ball_vs_wall','ball_vs_div','ball_vs_ball']}
    worst = {k:(0,None) for k in hits}
    with ThreadPoolExecutor(max_workers=8) as ex:
        for k, u, out in ex.map(frame_check, range(FRAMES+1)):
            line_bits = []
            for key in ['swap_vs_spin','div_vs_spin','div_vs_swap','ball_vs_wall','ball_vs_div']:
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
            if line_bits: print(f"  frame {k*120//FRAMES:3d} (u={u:.2f}): " + "  ".join(line_bits))
    print()
    print("  SUMMARY (over the {} sampled frames; lower is better):".format(FRAMES+1))
    for key in ['swap_vs_spin','div_vs_spin','div_vs_swap','ball_vs_wall','ball_vs_div']:
        h, w = hits[key], worst[key]
        mark = "PASS" if h==0 else "FAIL"
        print(f"    {key:15} {mark}  {h:3d} bad frames; worst {w[0]:.1f} mm^3 @ frame {w[1]*120//FRAMES if w[1] is not None else '—'}")
    h, w = hits['ball_vs_ball'], worst['ball_vs_ball']
    mark = "PASS" if h==0 else "FAIL"
    print(f"    {'ball_vs_ball':15} {mark}  {h:3d} bad frames; worst pen {w[0]:.2f}mm pair={w[1]}")
    rc = sum(hits.values())
    print()
    if rc==0:
        print("RESULT: PASS — no interference detected (within TOL=1 mm^3, every-{}-frame sampling).".format(120//FRAMES))
        sys.exit(0)
    else:
        print(f"RESULT: FAIL — {rc} category-frames have interference. Geometry needs revision.")
        sys.exit(1)

if __name__=='__main__': main()
