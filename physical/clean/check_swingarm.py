#!/usr/bin/env python3
"""SWING-ARM SWEPT-ARC CHECK — can a single rotary arm FETCH + SWAP a rim pair in one motion?

Idea under test: instead of (route inward through a bore) THEN (rotate a drum), put each ball on
a cradle and let ONE rotation carry it from its station, around, to the partner station — collapsing
fetch+swap+return into a single rotary stroke (no separate bore travel, no radial followers).

This checks pair (3,4) by sweeping the carrier and, at every frame, measuring each swapping ball's
distance from the ring axis (vs the wall) and from its partner and the two RESTING neighbour balls
(stations 2 and 5). Gates on the wall: a ball whose surface passes outside the wall has left the toy.

Three mechanisms are evaluated:
  A) RIGID diametric arm  — two cradles 180 deg apart on a rigid carrier, pivot forced to the chord
     midpoint (the only rigid 2-cradle swap).  Both rotation senses tried.
  B) RIGID arm, inner pivot — pivot pulled toward the ring centre (does it help?).
  C) CAM-SLOTTED arm — cradles ride radial slots; a cam pulls BOTH inward through mid-sweep so
     neither reaches the far radius.  Reports the required pull and the tightest clearances.
"""
import math

SCALE=1.25; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2
tube=rb+0.3; WALL=R+tube                       # 74.05 ring wall (ball surface must stay inside)
EASE=5.6; chz=eq-EASE                           # swapping balls ride at chamber level
CENTER_MAX = WALL - rb                          # 62.8 : max ball-CENTRE radius that keeps surface in
PAIR=(3,4); NEIGH=(2,5)
SEG=180

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    a=math.radians(A(s)); return (R*math.cos(a),-R*math.sin(a))
def rad(p): return math.hypot(p[0],p[1])
def unit(p):
    r=rad(p); return (p[0]/r,p[1]/r)
def rot(p,c,deg):
    a=math.radians(deg); co,si=math.cos(a),math.sin(a); dx,dy=p[0]-c[0],p[1]-c[1]
    return (c[0]+dx*co-dy*si, c[1]+dx*si+dy*co)
def mid(a,b): return ((a[0]+b[0])/2,(a[1]+b[1])/2)

P3,P4=P(PAIR[0]),P(PAIR[1])
NB=[ (P(s),eq) for s in NEIGH ]                 # resting neighbour balls sit on the band at z=eq
chord=math.dist(P3,P4)

def horiz_then_3d(c2a, za, c2b, zb):
    return math.dist((c2a[0],c2a[1],za),(c2b[0],c2b[1],zb))

def sweep(posfn, label):
    """posfn(t in 0..1) -> ((xa,ya),(xb,yb)) centres of the two swapping balls (z=chz)."""
    maxr=0.0; minpair=9e9; minneigh=9e9; wall_breach=0
    for k in range(SEG+1):
        t=k/SEG; a2,b2=posfn(t)
        ra,rb_=rad(a2)+rb, rad(b2)+rb
        maxr=max(maxr,ra,rb_)
        if ra>WALL+1e-6 or rb_>WALL+1e-6: wall_breach+=1
        minpair=min(minpair, horiz_then_3d(a2,chz,b2,chz))
        for (nc,nz) in NB:
            minpair_n=min(horiz_then_3d(a2,chz,nc,nz), horiz_then_3d(b2,chz,nc,nz))
            minneigh=min(minneigh,minpair_n)
    verdict = "PASS" if (wall_breach==0 and minpair>2*rb-0.4 and minneigh>2*rb-0.4) else "FAIL"
    print(f"  [{verdict}] {label}")
    print(f"        max ball-surface radius {maxr:6.2f}  (wall {WALL:.2f};  margin {WALL-maxr:+.2f})"
          + ("   <-- LEAVES THE TOY" if maxr>WALL else ""))
    print(f"        wall-breach frames {wall_breach:3d}/{SEG+1}   min pair-gap {minpair:5.2f}"
          f"   min neighbour-gap {minneigh:5.2f}   (need >{2*rb:.1f})")
    return verdict

print(f"SWING-ARM SWEPT-ARC CHECK   pair {PAIR}   chord {chord:.2f}   ball O{ball_d:.1f}   wall {WALL:.2f}\n")

# --- A) rigid diametric arm, pivot at chord midpoint (the only rigid 2-cradle swap) ---
O=mid(P3,P4)
print(f"A) RIGID diametric arm  pivot=midpoint r{rad(O):.2f}  arm={chord/2:.2f}")
sweep(lambda t:(rot(P3,O, 180*t), rot(P4,O, 180*t)), "rotate CCW (one cradle takes outer semicircle)")
sweep(lambda t:(rot(P3,O,-180*t), rot(P4,O,-180*t)), "rotate CW  (the other cradle takes outer)")

# --- B) rigid arm, pivot pulled inward along the radial bisector (does moving the pivot in help?) ---
print(f"\nB) RIGID arm, inner pivot (still must map P3<->P4, so this is a sanity check)")
for rp in (49.75, 40.0):
    Oi=(unit(mid(P3,P4))[0]*rp, unit(mid(P3,P4))[1]*rp)
    # a rigid rotation about Oi maps P3 -> 2*Oi-P3, which is NOT P4 unless Oi is the midpoint;
    # so a fixed inner pivot cannot perform the swap.  Show where P3 actually lands:
    land=rot(P3,Oi,180); err=math.dist(land,P4)
    print(f"     pivot r{rp:5.2f}: 180 deg about it sends P3 to {tuple(round(v,1) for v in land)} "
          f"-- misses P4 by {err:.1f} mm  => cannot swap with a fixed inner pivot")

# --- C) cam-slotted arm: rigid carrier about inner pivot, cradles ride radial slots pulled inward ---
print(f"\nC) CAM-SLOTTED arm  pivot inside ring; cam pulls both cradles in through mid-sweep")
Oc=(unit(mid(P3,P4))[0]*49.75, unit(mid(P3,P4))[1]*49.75)   # pivot at CR, on the bisector
armEnd=math.dist(Oc,P3)                                       # = dist(Oc,P4) by symmetry
ang3=math.degrees(math.atan2(P3[1]-Oc[1],P3[0]-Oc[0]))
ang4=math.degrees(math.atan2(P4[1]-Oc[1],P4[0]-Oc[0]))
dang=(ang4-ang3)                                              # carrier sweep to take A from P3->P4
# cam radius profile: flat-bottom — held at the ends to reach the stations, pulled in across a wide
# middle plateau (a kidney groove).  Search (armMid, edge) for the profile with the most margin.
def make_cam(armMid, edge):
    def f(t):
        if t<edge:        s=1-(t/edge)               # 1 at station, ramps to 0
        elif t>1-edge:    s=1-((1-t)/edge)
        else:             s=0.0                        # plateau: held fully pulled-in
        r=armMid+(armEnd-armMid)*s
        th=math.radians(ang3+dang*t)
        a=(Oc[0]+r*math.cos(th), Oc[1]+r*math.sin(th))
        b=(2*Oc[0]-a[0], 2*Oc[1]-a[1])
        return a,b
    return f
print(f"     pivot r49.75  arm-end {armEnd:.2f}  carrier sweep {abs(dang):.1f} deg")
best=None
for armMid in [13.0,12.5,12.0,11.6,11.3]:
    for edge in [0.10,0.14,0.18,0.22]:
        f=make_cam(armMid,edge)
        ok=True; mr=0; mp=9e9; mn=9e9
        for k in range(SEG+1):
            t=k/SEG; a2,b2=f(t)
            mr=max(mr,rad(a2)+rb,rad(b2)+rb)
            mp=min(mp,horiz_then_3d(a2,chz,b2,chz))
            for (nc,nz) in NB: mn=min(mn,horiz_then_3d(a2,chz,nc,nz),horiz_then_3d(b2,chz,nc,nz))
        if mr<=WALL and mp>2*rb-0.4 and mn>2*rb-0.4:
            score=min(WALL-mr, mp-2*rb, mn-2*rb)
            if best is None or score>best[0]: best=(score,armMid,edge)
if best:
    _,armMid,edge=best
    print(f"     best feasible cam: arm-mid {armMid:.2f}  (pull {armEnd-armMid:.2f} mm)  end-ramp {edge:.2f}")
    sweep(make_cam(armMid,edge), f"cam-slotted (pull {armEnd-armMid:.1f} mm, plateau)")
else:
    print("     no cam profile in the search keeps both balls inside  => cam-slotted also infeasible here")
    sweep(make_cam(12.0,0.14), "cam-slotted (best-effort, still breaches)")
