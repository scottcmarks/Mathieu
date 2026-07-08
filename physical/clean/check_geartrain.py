#!/usr/bin/env python3
"""DIVIDER GEAR TRAIN interference checker (ADR-0002, proto_geartrain.scad).

Verifies the NOVEL risks of adding the basement gear train:
  MESH        non-adjacent gear pairs must NOT touch (the 8 intended meshes — sun↔each idler,
              each idler↔its pinion — are exempt: correct involute mesh IS a small overlap).
  BASEMENT    the whole gear disk layer must clear the pan + the parked mechanism + resting
              balls + lid (it lives at Z −33..−27, below the pan at −24; pure Z-separation).
  SHAFTS      the 4 square shafts rise at the pair centers (r=55.224) from the pinions to the
              blades; they must thread BETWEEN the two spin-ring walls (46.16 / 68.96) and clear
              the balls/lid. Their own divider blade and the pan (which needs 4 bores) are exempt.
Positive controls abort (exit 2) if any solid renders empty.
"""
import math, os, sys, itertools
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_simple as cs      # reuse rv(), vol(), and the verified rest-state geometry

HERE = os.path.dirname(os.path.abspath(__file__))
GT   = os.path.join(HERE, 'proto_geartrain.scad')
TOL  = 1.0

# mirror proto_geartrain.scad
mG=1.2; Zsun=25; Zidl=21; Zpin=25; Ridl=27.60; GZ=-30; gh=6
def angleOf(k): return -90+(k-1)*(360/cs.N)
def Pp(k):
    a=math.radians(angleOf(k)); return (cs.R*math.cos(a), -cs.R*math.sin(a))
def midp(i,j): return ((Pp(i)[0]+Pp(j)[0])/2,(Pp(i)[1]+Pp(j)[1])/2)
PAIRS=[(3,4),(5,6),(7,8),(10,11)]

def rv_gt(body, tag):
    """render a scad that uses BOTH proto_simple (for mechanism) and proto_geartrain (for gears)."""
    sf=f'/tmp/GT_{tag}.scad'; of=f'/tmp/GT_{tag}.stl'
    if os.path.exists(of): os.remove(of)
    open(sf,'w').write(f'use <{cs.HERE}/proto_simple.scad>\nuse <{GT}>\n$fn=28;\n{body}\n')
    import subprocess
    subprocess.run([cs.OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    return cs.vol(of) if os.path.exists(of) else 0.0

# ---- placed gear scad strings ----
def azray(i,j): return math.degrees(math.atan2(midp(i,j)[1], midp(i,j)[0]))
def fmod(x,m): return x - math.floor(x/m)*m
def meshphase(phi_i, zi, zj, a):
    pi_=360/zi; pj=360/zj; aji=a+180; fi=fmod((a-phi_i)/pi_,1)
    return fmod(aji-(fi+0.5)*pj, pj)
def phi_idler(i,j):  return meshphase(0, Zsun, Zidl, azray(i,j))
def phi_pinion(i,j): return meshphase(phi_idler(i,j), Zidl, Zpin, azray(i,j))

def sun_s():  return f'translate([0,0,{GZ}]) sgear({Zsun},{gh},6);'
def idler_s(i,j):
    p=midp(i,j); a=azray(i,j); ip=(Ridl*math.cos(math.radians(a)), Ridl*math.sin(math.radians(a)))
    return f'translate([{ip[0]:.4f},{ip[1]:.4f},{GZ}]) rotate([0,0,{phi_idler(i,j):.4f}]) sgear({Zidl},{gh},3);'
def pinion_s(i,j):
    p=midp(i,j)
    return f'translate([{p[0]:.4f},{p[1]:.4f},{GZ}]) rotate([0,0,{phi_pinion(i,j):.4f}]) sgear({Zpin},{gh},0,{5.0});'
def shaft_s(i,j):
    p=midp(i,j); z0=GZ+gh; z1=10-20.8/2
    return f'translate([{p[0]:.4f},{p[1]:.4f},{z0}]) linear_extrude({z1-z0:.3f}) square([5,5],center=true);'

# named gear solids
GEARS = {'sun': sun_s()}
for (i,j) in PAIRS:
    GEARS[f'idl{i}{j}'] = idler_s(i,j)
    GEARS[f'pin{i}{j}'] = pinion_s(i,j)
# intended meshes (exempt): sun↔each idler, each idler↔its own pinion
MESH = set()
for (i,j) in PAIRS:
    MESH.add(frozenset(['sun', f'idl{i}{j}']))
    MESH.add(frozenset([f'idl{i}{j}', f'pin{i}{j}']))

# rest-state mechanism (u=0: frame parked). Pull from check_simple's verified kinematics.
def rest_mech():
    u=0.0
    rings = cs.rings_scad(u)
    swaps = cs.all_swaps_scad(u)          # parked swap rings incl central + apex
    balls = ' '.join(cs.ball_scad(s,u) for s in range(0, cs.N+1))
    lid   = cs.lid_scad()
    pan   = 'bottom_pan();'
    return rings, swaps, balls, lid, pan

def positive_controls():
    checks = [('sun', sun_s(), 500), ('idler', idler_s(3,4), 700), ('pinion', pinion_s(3,4), 500),
              ('shaft', shaft_s(3,4), 400)]
    ok=True
    for name, s, floor_ in checks:
        v=rv_gt(s, 'ctl_'+name)
        print(f"  control {name:10} {v:9.1f} mm^3  {'ok' if v>floor_ else 'EMPTY'}")
        if v<=floor_: ok=False
    v=rv_gt('intersection(){ cube(10); translate([5,5,5]) cube(10); }','ctl_ov')
    print(f"  control {'overlap':10} {v:9.1f} mm^3  {'ok' if abs(v-125)<5 else 'BROKEN'}")
    if abs(v-125)>=5: ok=False
    if not ok:
        print("ABORT: positive control failed."); sys.exit(2)

def main():
    print("DIVIDER GEAR TRAIN INTERFERENCE CHECK (ADR-0002)\n")
    print("  positive controls:")
    positive_controls()
    print()
    bad = 0

    # 1) MESH: every non-adjacent gear pair must be clear
    print("  MESH (non-adjacent gear pairs must be 0; 8 intended meshes exempt):")
    names = list(GEARS)
    for a, b in itertools.combinations(names, 2):
        if frozenset([a,b]) in MESH: continue
        v = rv_gt(f'intersection(){{ {GEARS[a]} {GEARS[b]} }}', f'm_{a}_{b}')
        if v > TOL:
            print(f"    FAIL {a} ∩ {b} = {v:.1f} mm^3"); bad += 1
    if bad == 0: print("    all clear")

    # 2) BASEMENT: gear disks vs pan + parked mechanism + balls + lid
    print("  BASEMENT (gear layer vs pan/rings/balls/lid — Z separation):")
    rings, swaps, balls, lid, pan = rest_mech()
    gears_union = ' '.join(GEARS.values())
    v = rv_gt(f'intersection(){{ union(){{ {gears_union} }} union(){{ {pan} {rings} {swaps} {balls} {lid} }} }}', 'basement')
    mark = 'clear' if v <= TOL else f'FAIL {v:.1f} mm^3'; print(f"    gears ∩ (pan+mech+balls+lid): {mark}")
    if v > TOL: bad += 1

    # 3) SHAFTS: square shafts vs spin rings + balls + lid (own divider + pan exempt)
    print("  SHAFTS (4 square shafts thread between spin walls; vs rings+balls+lid):")
    shafts = ' '.join(shaft_s(i,j) for (i,j) in PAIRS)
    v = rv_gt(f'intersection(){{ union(){{ {shafts} }} union(){{ {rings} {balls} {lid} }} }}', 'shafts')
    mark = 'clear' if v <= TOL else f'FAIL {v:.1f} mm^3'; print(f"    shafts ∩ (spin rings+balls+lid): {mark}")
    if v > TOL: bad += 1
    # informational: shaft vs pan (EXPECTED — the pan needs 4 shaft bores)
    vpan = rv_gt(f'intersection(){{ union(){{ {shafts} }} bottom_pan(); }}', 'shaftpan')
    print(f"    [info] shafts ∩ pan = {vpan:.1f} mm^3 (EXPECTED — pan needs 4 shaft bores at the pair centers)")

    print()
    if bad == 0:
        print("RESULT: PASS — gear train meshes cleanly and clears the mechanism (pan needs 4 shaft bores).")
        sys.exit(0)
    print(f"RESULT: FAIL — {bad} interference(s)."); sys.exit(1)

if __name__ == '__main__': main()
