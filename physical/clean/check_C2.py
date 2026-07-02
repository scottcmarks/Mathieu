#!/usr/bin/env python3
"""VARIANT C2 — dish parked HIGH, descends through lid bores.

Tests:
  1. DESCENT-PATH CLEARANCE: at sampled z in [working_z=0, park_bot=28], verify the dish (and
     its tower) does NOT intersect any SEG material (segs are dropped during the descent
     window).  At u where the dish is in transit, segs sit at z=-20 (fully dropped).  We
     sample the dish at z in {0, 4, 8, 12, 14, 18, 22, 28} and intersect against the dropped
     segs.  Expected: 0 mm^3 at all sampled z (segs are well below).
  2. LID-BORE PLUG: at z-stages {park, descent-mid z=14, working z=0}, verify the dish's
     tower-or-body always occupies the bore (i.e. some dish material is present at every z in
     [eq=10, lid_top=24]).  This is a 1-D z-coverage check, not a volume intersection — we
     compute the union of [dish_zlow, dish_zhi] for the dish at the given z-position and
     confirm it covers [eq, lid_top].
  3. CONFINEMENT-CONTINUITY GAP: between u=0.10 (segs gone) and u=0.55 (dish reaches z=0), the
     two affected balls (at stations i,j) are radially unbounded by either seg or dish.  We
     report (a) duration of the gap in u-space, (b) physical time estimate at human input
     speed (full cycle ~0.6 s), (c) horizontal distance a ball could roll before its captor
     arrives, and (d) verdict.

Also documents the lid-modification trade-off: bore breaks the lid's swap-arc CAP (top-side
ball retention).  Replacement is the dish's TOWER, which plugs the bore at all times.  We
verify tower-plug as part of test 2.
"""
import math, struct, subprocess, sys, os

HERE=os.path.dirname(os.path.abspath(__file__)); OPENSCAD="/opt/homebrew/bin/openscad"
SCALE=20/18; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2; apexR=R+24*SCALE
tube=rb+0.3; wall_t=1.5*SCALE; div_t=3.0; orbit=rb+div_t/2+0.5
dish_outer=orbit+tube+wall_t                # 23.97
spin_top=eq+math.sqrt(tube*tube-rb*rb)+1.5  # 13.97
floorz=eq-tube                              # -0.3
lid_bot=eq+1.5                              # 11.5
lid_top=eq+rb+4                             # 24
park_top=lid_top+4+spin_top                 # 41.97
park_bot=lid_top+4                          # 28
bore_r=dish_outer+0.5                       # 24.47
tower_r_out=dish_outer-0.1                  # 23.87
tower_r_in=orbit+tube+wall_t-6              # 17.97
tower_h=park_top+1-spin_top                 # 29
skirt_h=park_bot-eq+1                       # 19
SEG_DROP=35                                 # increased from 20 to clear the skirt at dish=working
DIVP=[(3,4),(5,6),(7,8),(10,11)]            # the 4 bored pairs
TOL=1.0

def A(s): return -90+(s-1)*(360.0/N)
def th(k): return -A(k)
def P(s):
    if s==0: return (0.0,apexR)
    a=math.radians(A(s)); return (R*math.cos(a),-R*math.sin(a))
def pair_M(i,j): return ((P(i)[0]+P(j)[0])/2, (P(i)[1]+P(j)[1])/2)
def nrm(v):
    m=math.hypot(*v); return (v[0]/m,v[1]/m)

# ---- ASCII-aware STL volume parser (canonical from check_variants.py) ----
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
    sf=f'/tmp/C2_{tag}.scad'; of=f'/tmp/C2_{tag}.stl'
    if os.path.exists(of): os.remove(of)
    open(sf,'w').write(f'use <{HERE}/proto_variant_C2.scad>\nuse <{HERE}/proto_wall.scad>\n$fn=28;\n{body}\n')
    subprocess.run([OPENSCAD,'-o',of,sf],capture_output=True,text=True)
    return vol(of) if os.path.exists(of) else 0.0

def expr_seg(k, segmod, dz=0):
    rz = th(k) - th(1)
    return f'rotate([0,0,{rz:.3f}]) translate([0,0,{-dz:.3f}]) {segmod}(1);'

def test_descent_clearance():
    """At the descent window, segs are dropped to z=-SEG_DROP=-35.  Verify dish (with
       upper tower AND lower skirt) at z in {0, 4, 8, 12, 14, 18, 22, 28} doesn't touch
       any (dropped) seg material.  The lower skirt extends to z=dish_z-19, so at dish=0
       the skirt tip is at z=-19, which must clear the dropped-seg top at z=spin_top-SEG_DROP
       = 13.97 - 35 = -21.03."""
    print("\n  --- TEST 1: dish (with skirt) descent clearance vs dropped segs (drop {} mm) ---".format(SEG_DROP))
    print(f"     (segs at z=-{SEG_DROP}, dropped-seg top at z={spin_top-SEG_DROP:.2f}; skirt tip at dish=0 is z={-skirt_h})")
    worst=0
    Z_SAMPLES=[0, 4, 8, 12, 14, 18, 22, 28]
    for (i,j) in DIVP:
        Mp=pair_M(i,j)
        worst_pair=0
        for z in Z_SAMPLES:
            segs = 'union(){'+' '.join(expr_seg(k,'spin_seg_inner',SEG_DROP)+' '+expr_seg(k,'spin_seg_outer',SEG_DROP) for k in range(1,N+1))+'}'
            dish = f'translate([{Mp[0]:.3f},{Mp[1]:.3f},{z:.3f}]) C2_dish();'
            v = rv(f'intersection(){{ {dish} {segs} }}', f't1_{i}_{j}_z{z}')
            worst_pair=max(worst_pair, v)
            worst=max(worst, v)
        flag = "" if worst_pair<=TOL else " ** CLASH **"
        print(f"     pair ({i},{j}): M={tuple(round(x,1) for x in Mp)}  worst clash over z={Z_SAMPLES} = {worst_pair:8.3f} mm^3{flag}")
    return worst

def test_lid_bore_plug():
    """At z-stages park / descent-mid / working, verify the dish+tower z-extent COVERS
       [eq=10, lid_top=24] (the lid bore range).  Dish body covers [dish_z, dish_z+spin_top].
       Tower covers [dish_z+spin_top, dish_z+park_top+1].  Total: [dish_z, dish_z+park_top+1]."""
    print("\n  --- TEST 2: lid-bore z-coverage (dish+tower must occupy [eq,lid_top] at every dish z) ---")
    STAGES = [('parked-high', park_bot), ('descent-mid', 14.0), ('working', 0.0)]
    bore_lo, bore_hi = eq, lid_top
    worst_gap = 0.0
    for name, dz in STAGES:
        skirt_lo, skirt_hi = dz-skirt_h, dz
        body_lo, body_hi = dz, dz+spin_top
        tower_lo, tower_hi = dz+spin_top, dz+spin_top+tower_h
        # union of three contiguous z-ranges = [skirt_lo, tower_hi]
        plug_lo, plug_hi = skirt_lo, tower_hi
        cov_lo = max(plug_lo, bore_lo); cov_hi = min(plug_hi, bore_hi)
        covered = max(0.0, cov_hi - cov_lo)
        needed = bore_hi - bore_lo
        gap = needed - covered
        worst_gap = max(worst_gap, gap)
        verdict = "PLUG OK" if gap<=0.01 else f"GAP {gap:.2f}mm"
        print(f"     {name:14s} dish z={dz:6.2f}:  skirt=[{skirt_lo:.2f},{skirt_hi:.2f}]  body=[{body_lo:.2f},{body_hi:.2f}]  tower=[{tower_lo:.2f},{tower_hi:.2f}]  -> covers [{cov_lo:.2f},{cov_hi:.2f}] of bore [{bore_lo:.2f},{bore_hi:.2f}]  {verdict}")
    return worst_gap

def test_confinement_gap():
    """During u=[0.10, 0.55] the 2 affected balls have NO lateral wall.  Estimate the gap
       duration and the physical risk.

       Assumptions:
         - Full cycle (one neighbour swap, start->end) ~ 0.6 s at brisk human input.
         - Gap span: u=[0.10, 0.55] = 0.45 of cycle = 0.27 s.
         - Ball can be displaced by gravity tilt + finger nudge.  With the box held
           reasonably level, lateral acceleration ~ 0.2 g = 2 m/s^2.  In 0.27 s
           displacement = 0.5 * 2 * 0.27^2 = 0.073 m = 73 mm.  That's WAY too far —
           the ball would leave its station.
         - With the box held FLAT (lateral accel ~ 0.05 g): 18 mm displacement.  Still too far
           (station-to-station spacing is ~31 mm chord between adjacent ring positions).
       Conclusion: the bare gap is UNSAFE.  Need a fix.

       Recommended fixes:
         (i)  divider arm extension: thicken the divider (still able to enter inter-seg gap
              edge-on) and add side-tabs that during seg-drop pop up to act as cylindrical wall
              stubs at radius R-some_offset (mechanism-level addition, not modelled here).
         (ii) lift dish FIRST then drop segs:  dish lowers to z=eq (above seg top) plugging
              the bore but NOT yet at z=0, then segs drop, then dish completes its descent
              to z=0.  This needs the dish to slide RADIALLY-FREE past the seg tops — but the
              dish is centered on the inter-seg gap azimuth and the segs are only 14.86° wide
              with 3.01° gaps. The dish footprint (radius 23.97 mm at M=53 from origin)
              ALREADY sweeps across 2 segments (the ones at stations i and j of the pair) —
              so this option fails the same way variant C-original fails.  Reject.
         (iii) magnet sub-mechanism takes over for the 2 affected balls during the gap:
              add a second magnet head to each ring pair that swings under the ball at
              u=0.10 and releases at u=0.55.  Heavy mechanism addition.

       VERDICT in this report: gap is REAL and physically unsafe — C2 requires fix (i)."""
    print("\n  --- TEST 3: confinement-continuity gap analysis ---")
    u_gap_start, u_gap_end = 0.10, 0.55
    u_gap = u_gap_end - u_gap_start
    cycle_s = 0.6
    gap_s = u_gap * cycle_s
    # lateral displacement under 0.05 g over gap_s
    a_flat = 0.05 * 9.81
    d_flat = 0.5 * a_flat * gap_s**2 * 1000.0   # mm
    a_tilt = 0.2 * 9.81
    d_tilt = 0.5 * a_tilt * gap_s**2 * 1000.0
    station_spacing_mm = 2 * R * math.sin(math.pi/N)   # ~31.4
    print(f"     gap span (u-space): [{u_gap_start}, {u_gap_end}] = {u_gap:.2f} of cycle")
    print(f"     est. physical time: cycle ~0.6 s -> gap ~{gap_s*1000:.0f} ms")
    print(f"     ball displacement if box flat (0.05g): {d_flat:6.2f} mm")
    print(f"     ball displacement if box tilted (0.2g): {d_tilt:6.2f} mm")
    print(f"     adjacent-station chord spacing: {station_spacing_mm:.2f} mm")
    safe_threshold_mm = 2.0       # ball within 2 mm of station is recoverable
    verdict = "SAFE" if d_flat < safe_threshold_mm else "UNSAFE — needs fix (divider arm extension recommended)"
    print(f"     verdict: {verdict}")
    return d_flat, d_tilt, verdict

def main():
    print("VARIANT C2  (dish parked HIGH, descends through lid bores)")
    print(f"  geometry: park_bot={park_bot}, park_top={park_top:.2f}, bore_r={bore_r:.2f}, tower_r=[{tower_r_in:.2f},{tower_r_out:.2f}]")
    w1 = test_descent_clearance()
    w2 = test_lid_bore_plug()
    d_flat, d_tilt, verdict = test_confinement_gap()

    print("\n  SUMMARY:")
    pass1 = w1<=TOL
    pass2 = w2<=0.01
    pass3 = (d_flat<=2.0)
    print(f"    Test 1 descent clearance:  worst {w1:8.3f} mm^3   -> {'PASS' if pass1 else 'FAIL'}")
    print(f"    Test 2 lid-bore z-plug:    worst gap {w2:.2f} mm  -> {'PASS' if pass2 else 'FAIL'}")
    print(f"    Test 3 confinement gap:    {d_flat:.2f} mm @0.05g  -> {'PASS' if pass3 else 'FAIL (mechanism fix required)'}")
    return 0 if (pass1 and pass2 and pass3) else 1

if __name__=='__main__': sys.exit(main())
