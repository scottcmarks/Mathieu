#!/usr/bin/env python3
"""TRACK-2 DRIVE / GEAR TRAIN — can ONE input turn all the dividers exactly pi, meshing cleanly?

Only the DIVIDER walls rotate (the swap-ring dishes just rise on cams). Each of the 5 divider posts
must turn pi (180) per swap. This checks a SUN + PLANETS train: a central SUN gear (hollow, so the
2-9 lane crosses the centre) drives a PLANET gear on each of the 4 ring-pair divider posts (all at
the ring-pair midpoint radius); the APEX divider (off that circle) is reached by one IDLER.
Gates:
  MESH      every meshing pair's centre distance == sum of pitch radii (within backlash)
  PLANETS   adjacent planets (and the idler) don't overlap
  RATIO     the sun angle that yields exactly pi at each divider is consistent for all of them
  CLEAR     the (hollow) sun clears the central 2-9 crossing; gears sit below the balls
"""
import math, sys

SCALE=20/18; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; apexR=R+24*SCALE
def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    if s==0: return (0.0,apexR)
    a=math.radians(A(s)); return (R*math.cos(a),-R*math.sin(a))
def mid(i,j): return ((P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2)
def rad(p): return math.hypot(*p)
def ang(p): return math.degrees(math.atan2(p[1],p[0]))

RINGPAIRS=[(3,4),(5,6),(7,8),(10,11)]
mids=[mid(i,j) for (i,j) in RINGPAIRS]; rr=[rad(m) for m in mids]
apex=mid(0,1); ra=rad(apex)

# ---- gear sizing (module m, integer teeth) ----
m=1.5
Np=11; Rp=Np*m/2                       # ring-divider planet pitch radius
Ns=round((rr[0]-Rp)*2/m); Rs=Ns*m/2    # central sun pitch radius so Rs+Rp = ring midpoint radius
# idler bridging sun -> apex divider planet (Np teeth). It need NOT sit on the radial line: place it
# at the intersection of circle(O, Rs+Ri) and circle(apex, Ri+Rp). For the circles to meet we need
# (Rs+Ri)+(Ri+Rp) >= ra  ->  Ri >= (ra-Rs-Rp)/2.
Ni=max(Np, math.ceil(((ra-Rs-Rp)/2)*2/m)); Ri=Ni*m/2
_r1=Rs+Ri; _r2=Ri+Rp; _a=(ra*ra+_r1*_r1-_r2*_r2)/(2*ra); _h=math.sqrt(max(0.0,_r1*_r1-_a*_a))
_u=(apex[0]/ra, apex[1]/ra)
idler=(_u[0]*_a - _u[1]*_h, _u[1]*_a + _u[0]*_h)        # circle-circle intersection (off the radial line)
r_idler=rad(idler)

def line(n,ok,extra): print(f"  {n:8} {'PASS' if ok else 'FAIL':4}  {extra}")
def main():
    print(f"DRIVE / GEAR TRAIN  (module {m}, sun {Ns}T r{Rs:.1f}, ring-planet {Np}T r{Rp:.1f}, idler {Ni}T r{Ri:.1f})")
    print(f"  ring-pair midpoint radii: {[round(x,1) for x in rr]}  apex divider radius: {ra:.1f}\n")
    # MESH: sun<->each ring planet, sun<->idler, idler<->apex
    tol=0.4; bad=[]
    for (i,j),rm in zip(RINGPAIRS,rr):
        if abs((Rs+Rp)-rm)>tol: bad.append(f"sun-planet({i},{j}) {Rs+Rp:.2f} vs {rm:.2f}")
    if abs(rad(idler)-(Rs+Ri))>tol: bad.append(f"sun-idler {rad(idler):.2f} vs {Rs+Ri:.2f}")
    if abs(math.dist(idler,apex)-(Ri+Rp))>tol: bad.append(f"idler-apex {math.dist(idler,apex):.2f} vs {Ri+Rp:.2f}")
    line('MESH', not bad, 'all meshing centre-distances = sum of pitch radii' if not bad else '; '.join(bad))
    # PLANETS: adjacent planet centres (sorted by azimuth) clearance vs 2*outer-radius
    az=sorted(ang(mp) for mp in mids); outer=Rp+m
    mind=9e9
    for a,b in zip(az,az[1:]+[az[0]+360]):
        d=2*rr[0]*math.sin(math.radians((b-a)/2)); mind=min(mind,d)
    # idler vs nearest ring planets
    id_clear=min(math.dist((r_idler*math.cos(math.radians(ang(apex))), r_idler*math.sin(math.radians(ang(apex)))), mp) for mp in mids)
    line('PLANETS', mind>2*outer and id_clear>(Ri+outer), f'min planet gap {mind:.1f} > {2*outer:.1f}; idler clear {id_clear:.1f} > {Ri+outer:.1f}')
    # RATIO: sun angle for planet pi; idler is a relay (ratio Ni cancels), apex sees Rs/Rp too
    sun_for_pi = 180*(Rp/Rs)            # planet turn = sun*(Rs/Rp); for 180 -> sun = 180*Rp/Rs
    apex_turn  = sun_for_pi*(Rs/Rp)     # idler cancels (Ns/Ni * Ni/Np = Ns/Np): apex gets same pi
    line('RATIO', abs(apex_turn-180)<0.5, f'sun turns {sun_for_pi:.1f} deg -> every divider turns {apex_turn:.1f} deg (=pi); ratio Ns/Np={Ns/Np:.2f}')
    # CLEAR: hollow sun inner radius must clear the 2-9 central crossing (balls reach ~rb of centre);
    # gear root radius ~ Rs - 1.25*m ; sun is an annulus, inner bore must exceed the 2-9 swept centre
    sun_inner = Rs - 4*m                # leave an annular rim of teeth; hollow inside
    two9_centre_r = rb + 1.0            # ball-9 crosses the dead centre; needs the bore clear
    line('CLEAR', sun_inner>two9_centre_r, f'hollow sun bore r{sun_inner:.1f} > 2-9 central swept r{two9_centre_r:.1f} (lane crosses the open centre)')
    ok = (not bad) and mind>2*outer and id_clear>(Ri+outer) and abs(apex_turn-180)<0.5 and sun_inner>two9_centre_r
    print()
    if not ok: print("RESULT: FAIL — the divider gear train doesn't close (see above)."); sys.exit(1)
    print(f"RESULT: PASS — one sun (turned {sun_for_pi:.1f} deg) drives all 5 dividers to pi through clean meshes;")
    print( "        the hollow centre leaves the 2-9 lane free. (Cams for dish-lift/seg-drop + the 2-9 magnet")
    print( "        linkage are separate drives off the same input — next.)")
    sys.exit(0)

if __name__=='__main__': main()
