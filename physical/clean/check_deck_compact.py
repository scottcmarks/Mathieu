#!/usr/bin/env python3
"""COMPACT BAND-THREADING DECK — gate + gravity-retention map (proto_deck_compact.scad).

This is the integration proof for the COMPACT variant: instead of the concept SOLID SLAB ease
deck (which interpenetrates the fixed band), proto_deck_compact.scad reshapes the ease/bore deck
into a THIN CHANNEL-NETWORK that THREADS the band's open regions, keeping the same ~5.62 mm ease.
The band's inner wall is NOTCHED only where each bore crosses it, kept clear of the spin lip.

Run from /Users/scott/Mathieu/physical :
    .venv/bin/python clean/check_deck_compact.py

GATES (exit non-zero on failure):
  (a) DECK-vs-BAND   the shaped deck does NOT interpenetrate the NOTCHED band (solid intersection
                     volume via OpenSCAD+trimesh -> mm^3 residual; also reports vs the UNNOTCHED
                     band so the notch's effect is explicit).
  (b) BORE-RETENTION each bore mouth (roof slot) < ball_d, so the ball is captured past its
                     equator in transit in ANY orientation (intersection-of-mouth: the open width
                     measured as the slot the ball would have to pass through).
  (c) SPIN-INTACT    the notches remove ZERO material from the band's spin-retention torus/lip
                     (solid: spin-shell volume notched == unnotched), so a ball resting at z=eq
                     stays captured by the band lip.

GRAVITY / ANY-ORIENTATION RETENTION (distinct from intersection — does NOT gate by itself; it
ENUMERATES every frame/place where a ball is currently NOT fully retained and so would fall out
in some orientation with no gravity assist). The swap kinematics for all 12 balls are ported from
check_assembly.py.  A ball is "fully retained" at a frame iff SOME retainer caps it above its
equator with an opening < ball_d on every side it could escape through.
"""
import math, sys, os, subprocess, itertools

HERE   = os.path.dirname(os.path.abspath(__file__))
SCAD   = os.path.join(HERE, 'proto_deck_compact.scad')
OPENSCAD = '/opt/homebrew/bin/openscad'

# ------------------------------------------------------------------ geometry (mirror the .scad)
SCALE=1.25; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=rb
tube=rb+0.3
spin_top=eq+math.sqrt(tube*tube-rb*rb)+1.5
wall_t=1.5*SCALE; floorz=eq-tube
RD=rb+0.5; FP=RD+rb+1.0; CR=R-RD-1.0; CLEAR=CR-FP; apexR=R+24*SCALE
WALL=R+tube
EASE=(spin_top-eq)+1.5; chz=eq-EASE
DF=spin_top-eq                       # how far a ball may drop and still be under the FIXED band lip
DC=EASE-DF+2.0                       # ceiling-lip grip range (overlaps the fixed lip)
# channel (bore) retention geometry — mirror the .scad
br=rb+0.4; sw=rb-0.85; wall_m=1.2; roof_t=1.6
zlip=chz+math.sqrt(rb*rb-sw*sw)      # bore-roof lip height (the slot edge), < eq
mouth=2*sw                           # the open slot width at the bore roof
r_spin=R-tube                        # inner edge of the spin torus/lip
# DRUM CEILING ROOF — mirror the .scad. A flat plate above ball_top with an ANNULAR slot centred
# on the ball-orbit radius RD; slot radial width 2*sw (<ball_d) so the ball cannot pass up through
# it.  droof_slot_lo/hi bracket the orbit; the inner lip (hub) and outer ring cap either side.
ball_top   = chz+rb                   # 16.885
roof_gap   = 0.8
droof_bot  = ball_top+roof_gap        # 17.685  roof underside (> spin_top -> above the band)
droof_slot_lo = RD-sw                 # inner slot edge (inner lip is solid below this)
droof_slot_hi = RD+sw                 # outer slot edge (outer ring is solid above this)
droof_mouth   = 2*sw                  # radial slot width = bore mouth = 20.80 < ball_d
SEG=120; TOL=0.4

INNER=[(2,9),(3,4),(5,6),(7,8),(10,11)]
ALLP=[(0,1)]+INNER

def A(s): return -90+(s-1)*(360.0/N)
def P(s):
    if s==0: return (0.0,apexR)
    a=math.radians(A(s)); return (R*math.cos(a),-R*math.sin(a))
def rad(p): return math.hypot(p[0],p[1])
def unit(p):
    r=rad(p); return (p[0]/r,p[1]/r) if r>1e-9 else (1.0,0.0)
def rot2(p,c,a):
    co,si=math.cos(a),math.sin(a); dx,dy=p[0]-c[0],p[1]-c[1]
    return (c[0]+dx*co-dy*si, c[1]+dx*si+dy*co)
def lerp(p,q,t): return (p[0]+(q[0]-p[0])*t, p[1]+(q[1]-p[1])*t)
def d3(a,b): return math.dist(a,b)
def mid(i,j): return ((P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2)
def far(i,j): return rad(mid(i,j))<CR-4
def drumC(i,j):
    if far(i,j): return (0.0,0.0)
    u=unit(mid(i,j)); return (u[0]*CR,u[1]*CR)
def entries(i,j):
    C=drumC(i,j)
    if far(i,j): ax=math.atan2(mid(i,j)[1],mid(i,j)[0])-math.pi/2
    else:        ax=math.atan2(C[1],C[0])+math.pi/2
    t=(math.cos(ax),math.sin(ax))
    return ((C[0]+t[0]*RD,C[1]+t[1]*RD),(C[0]-t[0]*RD,C[1]-t[1]*RD))
DRUM={p:drumC(*p) for p in INNER}; ENT={p:entries(*p) for p in INNER}

def pairof(s):
    for (i,j) in ALLP:
        if s in (i,j): return (i,j),(0 if s==i else 1)

# -------- ported kinematics (identical to check_assembly.py) + per-frame PHASE label -----------
def routed(i,j,which,u):
    home=P(i) if which==0 else P(j); away=P(j) if which==0 else P(i)
    e=ENT[(i,j)]; ehome=e[0] if which==0 else e[1]; eaway=e[1] if which==0 else e[0]; C=DRUM[(i,j)]
    isf=far(i,j); z=eq-EASE
    if u<=0.10: return (*home, eq-EASE*(u/0.10)), 'ease-down'
    if u<=0.32:
        s=(u-0.10)/0.22
        if isf:
            wp=(unit(home)[0]*(CLEAR-1),unit(home)[1]*(CLEAR-1))
            return (*(lerp(home,wp,s/0.5) if s<0.5 else lerp(wp,ehome,(s-0.5)/0.5)), z), 'route-in'
        return (*lerp(home,ehome,s), z), 'route-in'
    if u<=0.68: return (*rot2(ehome,C,math.pi*((u-0.32)/0.36)), z), 'drum-turn'
    if u<=0.90:
        s=(u-0.68)/0.22
        if isf:
            wp=(unit(away)[0]*(CLEAR-1),unit(away)[1]*(CLEAR-1))
            return (*(lerp(eaway,wp,s/0.5) if s<0.5 else lerp(wp,away,(s-0.5)/0.5)), z), 'route-out'
        return (*lerp(eaway,away,s), z), 'route-out'
    return (*away, eq-EASE*((1.0-u)/0.10)), 'ease-up'
def apex_ball(which,u):
    M=mid(0,1); s=P(0) if which==0 else P(1); return (*rot2(s,M,math.pi*u), eq), 'apex-top'
def ballpos(s,u):
    (i,j),w=pairof(s)
    return apex_ball(w,u) if (i,j)==(0,1) else routed(i,j,w,u)

# ============================================================================================
#  SOLID-INTERSECTION GATES (OpenSCAD + trimesh)
# ============================================================================================
def render(part, out):
    r=subprocess.run([OPENSCAD,'-o',out,'-D',f'PART="{part}"',SCAD],
                     capture_output=True,text=True)
    err='\n'.join(l for l in (r.stdout+r.stderr).splitlines()
                  if 'ERROR' in l or 'WARNING' in l)
    if err: print('   openscad note:',err)
    return out

def vol(part):
    import trimesh
    out=f'/tmp/chk_{part}.stl'; render(part,out)
    if not os.path.exists(out) or os.path.getsize(out)<100: return 0.0
    m=trimesh.load(out); return abs(m.volume)

def gate_intersection():
    print('\n=== (a) DECK-vs-BAND  (shaped deck must not interpenetrate the NOTCHED band) ===')
    v_un = vol('xsect_unnotched')
    v_no = vol('xsect_notched')
    print(f'   deck ∩ UNNOTCHED band = {v_un:8.2f} mm^3   (the raw overlap, before notching)')
    print(f'   deck ∩ NOTCHED   band = {v_no:8.2f} mm^3   (the residual after the wall notches)')
    ok = v_no <= 1.0     # ~0 (CGAL mesh noise floor)
    print('   PASS' if ok else '   FAIL', f'— residual overlap {v_no:.2f} mm^3 '
          f'({"closed" if ok else "deck still interpenetrates the band"}).')
    return 0 if ok else 1

def gate_spin():
    print('\n=== (c) SPIN-INTACT  (notches remove no spin-retention material at z=eq) ===')
    v_full = vol('spin_shell')
    v_notch= vol('spin_shell_notched')
    removed=v_full-v_notch
    print(f'   spin-retention torus/lip slab  unnotched = {v_full:8.2f} mm^3')
    print(f'                                  notched   = {v_notch:8.2f} mm^3')
    print(f'   material removed from the spin lip by the notches = {removed:.2f} mm^3')
    ok = removed <= 1.0
    print('   PASS' if ok else '   FAIL', f'— {"spin channel intact at z=eq" if ok else "NOTCHES BREACH THE SPIN LIP"}.')
    return 0 if ok else 1

def gate_mouth():
    print('\n=== (b) BORE-RETENTION  (over-equator channel: mouth < ball_d in transit) ===')
    print(f'   bore roof-slot mouth (open width) = {mouth:.2f} mm ;  ball Ø = {ball_d:.2f} mm')
    print(f'   roof lip sits at z={zlip:.2f} (< eq={eq:.2f}); the ball centre rides at chz={chz:.2f},')
    print(f'   so the lip caps it {zlip-chz:.2f} mm above centre — i.e. past its equator.')
    bite=ball_d-mouth
    ok = mouth < ball_d-0.05 and zlip>chz
    print('   PASS' if ok else '   FAIL',
          f'— mouth {mouth:.2f} < ball {ball_d:.2f} (bite {bite:.2f}); ball retained any-orientation in the bore.'
          if ok else f'— mouth {mouth:.2f} does not capture the ball.')
    return 0 if ok else 1

# ============================================================================================
#  GRAVITY / ANY-ORIENTATION RETENTION  (enumerate gaps — does NOT gate)
# ============================================================================================
# A retainer holds a ball "in any orientation" only if it wraps the ball PAST its equator with an
# opening < ball_d on every side the ball could escape. We model each retainer as the region in
# which it is active and the cap it provides, and ask: at this (x,y,z), is the ball capped?
#
#   BAND LIP   : active when the ball is on the spin circle (rad≈R) and high (z within DF of eq).
#                The fixed torus lip caps it (mouth = 2*sqrt(tube^2-(spin_top-eq)^2) < ball_d).
#   BORE WALL  : active when the ball is inside a built bore CHANNEL (its xy lies within br of some
#                bore centre-line segment AND z≈chz). The roofed slot (mouth<ball_d) caps it.
#                NB only the inner-disc portion of each arm is FULL height; out under the spin
#                channel (rad>r_spin) the arm is clipped to z<=floorz (band's well takes over), so
#                the *bore roof* is only present where the arm is full height.
#   WELL WALL  : at a station, while the ball eases between eq and chz it is inside the band's
#                through-well (radius rw). The well is just a vertical hole (NO roof) — it does
#                NOT cap the top. Capping during the ease must come from the band lip (top of the
#                stroke) or the bore roof / ceiling (bottom). The OVERLAP of those ranges is the
#                ease-handoff; a gap here = the ball is briefly open-topped mid-ease.
#   DRUM POCKET: the rotary cradle. In proto_band.scad the cradle is carved as a sphere + an
#                OPEN cylindrical bore (radius rb-0.4) straight UP — i.e. its TOP IS OPEN. So the
#                drum pocket alone does NOT cap the ball; capping in the drum must come from a
#                CEILING above it. The compact deck does not (yet) build that ceiling.
#   CEILING    : a lip ABOVE the eased ball (z≈chz) covering it through route/drum. The compact
#                deck builds bore ROOFS along the arms, but NOT over the open drum cavities.
rw=rb+1.5
def seg_dist(p,a,b):
    ax,ay=a; bx,by=b; dx,dy=bx-ax,by-ay; L2=dx*dx+dy*dy
    t=0.0 if L2==0 else max(0.0,min(1.0,((p[0]-ax)*dx+(p[1]-ay)*dy)/L2))
    return math.hypot(p[0]-(ax+t*dx),p[1]-(ay+t*dy))

def bore_segs(i,j):
    e=ENT[(i,j)]
    if far(i,j):
        wpi=(unit(P(i))[0]*(CLEAR-1),unit(P(i))[1]*(CLEAR-1))
        wpj=(unit(P(j))[0]*(CLEAR-1),unit(P(j))[1]*(CLEAR-1))
        return [(P(i),wpi),(wpi,e[0]),(P(j),wpj),(wpj,e[1])]
    return [(P(i),e[0]),(P(j),e[1])]
ALL_SEGS=[s for p in INNER for s in bore_segs(*p)]

def in_bore_roofed(p):
    """Is xy within a bore channel AND in its FULL-HEIGHT (roofed) region (rad<=r_spin)?"""
    if rad(p)>r_spin+0.01: return False          # out here the arm is clipped sub-floor: NO roof
    for (a,b) in ALL_SEGS:
        if seg_dist(p,a,b)<=br+0.2: return True
    return False

def in_drum_cavity(p):
    for pr in INNER:
        if math.hypot(p[0]-DRUM[pr][0],p[1]-DRUM[pr][1])<=FP-0.2: return True
    return False

def under_drum_roof(p):
    """Is the ball capped by the drum ceiling roof?  True iff its centre lies in a drum cavity
    with its orbit radius bracketed by the annular slot lips (slot radial width 2*sw < ball_d, so
    the ball cannot pass up through it in any orientation; the inner hub-lip and outer ring cap the
    two radial sides, and the slot is open all round the 180 deg arc so every turn angle is held)."""
    for pr in INNER:
        rr=math.hypot(p[0]-DRUM[pr][0],p[1]-DRUM[pr][1])
        if rr<=FP-0.2:
            # capped while the ball centre is within the slot annulus (+ the lips' half-grip).
            # the lips sit at RD±sw; a ball centred anywhere the slot covers it (|rr-RD|<=sw) is
            # bracketed by both lips -> can't escape up (mouth 2*sw < ball_d).
            if abs(rr-RD)<=sw+0.3: return True
    return False

def band_lip_caps(p):
    # on the spin circle, ball high enough that the fixed lip still covers it
    return abs(rad(p)-R)<=tube+0.5 and (eq-DF-0.05)<=p[2]<=eq+0.1

# --- CENTRAL-ARM OUTER CAP (mirror the .scad central_arm_caps) -------------------------------
# A thin plate riding above the eased ball over each central arm's radial line, from r_spin out
# to cap_r_out, closing the central pair's route-in/route-out open-top window. The plate underside
# follows the resting-ball clearance envelope (set by the inner radius of each 0.5 mm step), so it
# clears a ball resting/spinning at the station; it sits above spin_top, so it never touches the
# band. A frame is held by the cap iff its xy lies over a central arm strip within [r_spin,cap_r_out]
# and the eased ball there is below the cap underside (it always is: the cap is ABOVE ball_top by
# construction). Station-ease frames (r ~ R, ball easing vertically) are NOT covered: a cap above
# that ball's crown at r=R lies inside a resting ball at the same station -> irreducible.
cap_r_in  = r_spin                    # 50.95
cap_r_out = 60.0
cap_step  = 0.5
cap_clr   = 0.4
cap_halfw = br + wall_m               # 12.85  (matches the .scad)
def cap_under(r):
    inside = R - (r + cap_clr)
    base = droof_bot
    return max(base, eq + math.sqrt(rb*rb - inside*inside)) if abs(inside) < rb else base
# the central arms' radial unit directions (toward each central station)
CENTRAL_DIRS=[unit(P(s)) for pr in INNER if far(*pr) for s in pr]
def under_central_cap(p):
    """Is the eased ball capped by a central-arm outer cap?  True iff xy is over a central arm
    strip (within cap_halfw of its radial line, between r_spin and cap_r_out) AND the cap underside
    there is above the ball crown (always true by construction).  Mirrors central_arm_caps()."""
    r=rad(p)
    if not (cap_r_in-0.01 <= r <= cap_r_out): return False
    for d in CENTRAL_DIRS:
        # signed distance across the arm (perp to the radial direction) and along it
        along = p[0]*d[0] + p[1]*d[1]
        perp  = abs(-p[0]*d[1] + p[1]*d[0])
        if along <= 0: continue
        if perp <= cap_halfw and cap_r_in-0.01 <= along <= cap_r_out:
            # the step underside set by the inner radius of the 0.5 mm step covering r=along
            r0 = cap_r_in + math.floor((along-cap_r_in)/cap_step)*cap_step
            if cap_under(r0) >= ball_top:    # cap is above the eased crown -> retains
                return True
    return False

def retention(s,u):
    """Return (held:bool, retainer:str, why:str) for ball s at frame u."""
    p,phase=ballpos(s,u); z=p[2]; r=rad(p)
    # 1. band lip (top of ease / at-rest / apex)
    if band_lip_caps(p):
        return True,'band-lip',phase
    # 2. bore roof (eased, inside a roofed channel segment)
    if abs(z-chz)<=DC+0.1 and in_bore_roofed(p):
        return True,'bore-roof',phase
    # 3. drum ceiling roof (eased, in a drum cavity, orbit radius bracketed by the slot lips)
    if abs(z-chz)<=DC+0.1 and under_drum_roof(p):
        return True,'drum-roof', phase
    # 3a. central-arm outer cap (eased, over a central arm strip out under the spin annulus)
    if abs(z-chz)<=DC+0.1 and under_central_cap(p):
        return True,'central-cap', phase
    # 3b. drum cavity but NOT under the roof slot (e.g. ball pulled off the orbit) — open-topped
    if in_drum_cavity(p) and abs(z-chz)<=rb+1:
        return False,'drum-open-top', phase   # pocket sides hold xy, but nothing caps the top
    # 4. eased & inside a well but past the band-lip range and not under a bore roof
    if z<eq-DF-0.05:
        # is there ANY roof? only if in a roofed bore. otherwise open-topped.
        return False,'open-top-eased', phase
    # 5. high but off the band circle (shouldn't happen in this kinematics) -> open
    return False,'uncapped', phase

PHASES=['ease-down','route-in','drum-turn','route-out','ease-up','apex-top']
def retention_map():
    print('\n=== GRAVITY / ANY-ORIENTATION RETENTION MAP  (no gravity assist; all 12 balls) ===')
    print('   For every ball at every frame: is it capped above its equator by SOME retainer with')
    print('   an opening < ball_d (so it could NOT fall out in ANY orientation)?  Gaps enumerated:')
    # aggregate: for each (ball, phase, reason) record the u-range where the ball is unheld
    gaps={}   # (ball,phase,reason) -> [u_lo,u_hi,count]
    held_count=0; total=0
    for k in range(SEG+1):
        u=k/SEG
        for s in range(12):
            total+=1
            held,ret,phase=retention(s,u)
            if held: held_count+=1; continue
            key=(s,phase,ret)
            g=gaps.get(key)
            if g is None: gaps[key]=[u,u,1]
            else: g[1]=u; g[2]+=1
    print(f'\n   frames swept: {SEG+1}; ball-frames: {total}; fully retained: {held_count} '
          f'({100*held_count/total:.1f}%); UNRETAINED: {total-held_count} ({100*(total-held_count)/total:.1f}%)')
    if not gaps:
        print('\n   NO GAPS — every ball is fully retained at every frame (any orientation).')
        return 0
    # group by phase for a readable map
    why_text={
        'drum-open-top':'drum cradle top is OPEN (carved open cylinder up) — no ceiling built over the drum',
        'open-top-eased':'ball eased below the band lip but NOT under a bore roof here — open-topped',
        'uncapped':'ball off the band circle and high — no retainer in range',
    }
    print('\n   RETENTION-GAP MAP (ball · phase · reason · u-window · #frames):')
    by_phase={}
    for (s,phase,ret),(lo,hi,n) in gaps.items():
        by_phase.setdefault(phase,[]).append((s,ret,lo,hi,n))
    for phase in PHASES:
        rows=by_phase.get(phase)
        if not rows: continue
        print(f'\n   [{phase}]')
        for s,ret,lo,hi,n in sorted(rows):
            (i,j),_=pairof(s)
            kind='apex(0,1)' if (i,j)==(0,1) else ('central 2-9' if far(i,j) else f'rim {i},{j}')
            print(f'     ball {s:2d} ({kind:11s})  u∈[{lo:.2f},{hi:.2f}]  {n:3d} frames  — {why_text.get(ret,ret)}')
    # summary by reason
    print('\n   GAP SUMMARY by cause:')
    cause={}
    for (s,phase,ret),(lo,hi,n) in gaps.items():
        cause[ret]=cause.get(ret,0)+n
    for ret,n in sorted(cause.items(),key=lambda x:-x[1]):
        print(f'     {n:4d} ball-frames — {why_text.get(ret,ret)}')
    return 0   # the map is informational; it does not gate

# ============================================================================================
def main():
    print(f'COMPACT DECK CHECK  (perm #22; 12 balls; {len(INNER)} drums; ball Ø{ball_d:.1f}; ease {EASE:.2f} mm)')
    print(f'  bore mouth {mouth:.2f} < ball {ball_d:.2f}; roof lip z={zlip:.2f} < eq={eq:.2f}; r_spin={r_spin:.2f}')
    rc  = gate_mouth()
    rc |= gate_intersection()
    rc |= gate_spin()
    retention_map()   # informational, prints the gap map; does not affect rc
    print()
    if rc:
        print('RESULT: FAIL — the compact band-threading deck does not close on the gated checks above.')
        sys.exit(1)
    print('RESULT: PASS (gates) — the compact deck threads the band without interpenetration, the bore')
    print('        mouth retains the ball in transit, and the wall notches leave the spin lip intact.')
    print('        (See the RETENTION MAP above for where ball capture is still incomplete.)')
    sys.exit(0)

if __name__=='__main__': main()
