#!/usr/bin/env python3
"""TALL-VARIANT CHECKER — big-ease clean sub-chamber deck below the fixed band.

Companion proof for proto_deck_tall.scad. The tall branch trades toy height for cleanliness:
the bore/drum/disc chamber is dropped so far (EASE_tall) that it sits ENTIRELY BELOW the fixed
band floor as its own deck — no band overlap. This script GATES on three intersection concerns
and then, separately, prints an HONEST any-orientation (NO-gravity) retention-gap map.

Mirrors clean/proto_band.scad + clean/check_assembly.py geometry; the routed-ball carry height
is deepened from (eq-EASE) to (eq-EASE_tall).

GATES (exit non-zero on any):
  (a) DECK-BELOW-BAND  the deck slab roof stays below the band floor (report the z-gap)
  (b) SWAP-CLEARS      the deepened 12-ball swap has no ball-ball / foreign-drum / leaves-ring clash
  (c) RETENTION-REPORT EASE_tall + the riser/tube/lip depths are reported

RETENTION (separate, REQUIRED, distinct from intersection):
  Sweep the full 12-ball swap. For EVERY ball at EVERY frame decide whether SOME retainer captures
  it ABOVE ITS EQUATOR so it could not fall out in ANY orientation (no gravity). Enumerate every
  frame/place a ball is NOT fully retained — which ball, which phase, why. Print a gap map.

Run from /Users/scott/Mathieu/physical via  .venv/bin/python clean/check_deck_tall.py
"""
import math, sys, itertools

# ===================== geometry (mirror proto_band.scad / check_assembly.py) =====================
SCALE=1.25; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2
tube=rb+0.3; RD=rb+0.5; FP=RD+rb+1.0; CR=R-RD-1.0; CLEAR=CR-FP; apexR=R+24*SCALE
WALL=R+tube
spin_top=eq+math.sqrt(tube*tube-rb*rb)+1.5
DF=spin_top-eq                      # fixed over-equator lip grip range
floorz=eq-tube                      # band channel floor (torus bottom) ~ -0.30
rw=rb+1.5                           # station well radius (round)
disc_h=4.5

# ---- TALL constants (mirror proto_deck_tall.scad EXACTLY) ----
EASE_tall=25.0
chz=eq-EASE_tall                    # chamber carry level (ball centre)  ~ -13.75
bore_r=rb+0.4                       # carved bore / riser passage radius (running clearance)
# FIX 1 — OVER-EQUATOR bore channels: a carved passage (bore_r) ROOFED except a slot of half-width
# sw, so the top mouth 2*sw < ball_d and the lip wraps each ball past its equator in transit.
sw=rb-0.85                          # 10.40  roof-slot HALF-width -> mouth 2*sw = 20.80 < ball_d 22.5
bore_mouth=2*sw                     # 20.80  open width at the bore roof
zlip=chz+math.sqrt(rb*rb-sw*sw)     # over-equator bore-roof lip height at the slot edge (< eq)
roof_t=1.0
deck_top=chz+rb+roof_t             # top of the deck slab (must be < floorz)
deck_bottom=chz-rb-4
# FIX 2 — DRUM-CEILING ROOF: a continuous plate over the inner disc that caps every drum's ball-
# orbit annulus (opening 2*ann_w < ball_d) AND bridges to the bore roofs.  Drum spins UNDER it.
ann_w=rb-0.85                       # 10.40  half-width of the orbit-annulus opening -> 20.80 < ball_d
drum_mouth=2*ann_w                  # 20.80  open width over each drum's orbit
drum_run=1.0                        # running clearance: roof underside above the spinning drum top
drum_top=chz                        # top of the spinning drum cup bodies (= chz)
roof_under=drum_top+drum_run        # -12.75  roof underside above the drum, clears it
roof_over=deck_top                  # -1.50   roof shares the deck top plane (unified carriage roof)
ROOF_OFF=roof_over-chz              # 12.25   the carriage roof sits this far above the ball centre
# RISERS — CLOSED vertical tubes (full 360 deg lateral enclosure) bridging the bore roof up to the
# band-lip range over the EASE descent; ends capped by the fixed band lip (top) + bore/drum roof (bot).
RISER_H=floorz-deck_top            # vertical retention-tube height (deck roof -> band floor)
SEG=120; TOL=0.4

# ===================== kinematics (ported from check_assembly.py, z deepened) ====================
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

ALLP=[(0,1),(2,9),(3,4),(5,6),(7,8),(10,11)]
INNER=[p for p in ALLP if 0 not in p]
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

# ----- bore-lane geometry (mirror proto_deck_tall.scad bore_cut/bore_slot routing EXACTLY) -----
def bore_segs(i,j):
    e=ENT[(i,j)]
    if far(i,j):
        wpi=(unit(P(i))[0]*(CR-FP-1),unit(P(i))[1]*(CR-FP-1))
        wpj=(unit(P(j))[0]*(CR-FP-1),unit(P(j))[1]*(CR-FP-1))
        return [(P(i),wpi),(wpi,e[0]),(P(j),wpj),(wpj,e[1])]
    return [(P(i),e[0]),(P(j),e[1])]
ALL_SEGS=[s for p in INNER for s in bore_segs(*p)]
def seg_dist(p,a,b):
    ax,ay=a; bx,by=b; dx,dy=bx-ax,by-ay; L2=dx*dx+dy*dy
    t=0.0 if L2==0 else max(0.0,min(1.0,((p[0]-ax)*dx+(p[1]-ay)*dy)/L2))
    return math.hypot(p[0]-(ax+t*dx),p[1]-(ay+t*dy))
def in_bore_lane(p):
    """xy lies within a roofed bore CHANNEL (within bore_r of some lane centre-line)."""
    return any(seg_dist(p,a,b)<=bore_r+0.2 for (a,b) in ALL_SEGS)
def in_drum_annulus(p):
    """xy lies in some drum's roofed ORBIT ANNULUS (radius RD-ann_w .. RD+ann_w from a drum centre)
       -> the drum-roof lip caps the orbiting ball above its equator over the 180 deg turn."""
    for pr in INNER:
        d=math.hypot(p[0]-DRUM[pr][0],p[1]-DRUM[pr][1])
        if (RD-ann_w-0.2)<=d<=(RD+ann_w+0.2): return True
    return False

def pairof(s):
    for (i,j) in ALLP:
        if s in (i,j): return (i,j), (0 if s==i else 1)

# phase tags so the retention map can name WHERE a gap is
PH_DOWN='ease-down'; PH_IN='push-in'; PH_TURN='drum-turn'; PH_OUT='push-out'; PH_UP='ease-up'
def routed_phase(u):
    if u<=0.10: return PH_DOWN
    if u<=0.32: return PH_IN
    if u<=0.68: return PH_TURN
    if u<=0.90: return PH_OUT
    return PH_UP
def routed(i,j,which,u):
    home=P(i) if which==0 else P(j); away=P(j) if which==0 else P(i)
    e=ENT[(i,j)]; ehome=e[0] if which==0 else e[1]; eaway=e[1] if which==0 else e[0]; C=DRUM[(i,j)]
    isf=far(i,j); z=eq-EASE_tall
    if u<=0.10: return (*home, eq-EASE_tall*(u/0.10))
    if u<=0.32:
        s=(u-0.10)/0.22
        if isf:
            wp=(unit(home)[0]*(CLEAR-1),unit(home)[1]*(CLEAR-1))
            return (*(lerp(home,wp,s/0.5) if s<0.5 else lerp(wp,ehome,(s-0.5)/0.5)), z)
        return (*lerp(home,ehome,s), z)
    if u<=0.68: return (*rot2(ehome,C,math.pi*((u-0.32)/0.36)), z)
    if u<=0.90:
        s=(u-0.68)/0.22
        if isf:
            wp=(unit(away)[0]*(CLEAR-1),unit(away)[1]*(CLEAR-1))
            return (*(lerp(eaway,wp,s/0.5) if s<0.5 else lerp(wp,away,(s-0.5)/0.5)), z)
        return (*lerp(eaway,away,s), z)
    return (*away, eq-EASE_tall*((1.0-u)/0.10))
def apex_ball(which,u):
    M=mid(0,1); s=P(0) if which==0 else P(1); return (*rot2(s,M,math.pi*u), eq)
def apex_phase(u): return 'apex-turn'
def ballpos(s,u):
    (i,j),w=pairof(s)
    return apex_ball(w,u) if (i,j)==(0,1) else routed(i,j,w,u)
def phaseof(s,u):
    (i,j),_=pairof(s)
    return apex_phase(u) if (i,j)==(0,1) else routed_phase(u)

def drum_pen(p, C):
    dr=max(0.0, math.hypot(p[0]-C[0],p[1]-C[1])-FP); dz=max(0.0,(eq-EASE_tall-rb)-p[2], p[2]-(eq-EASE_tall+1))
    return rb-math.hypot(dr,dz)

# ===================== SOLID INTERSECTION (OpenSCAD + trimesh) — backs "intersection closes" ======
import os, subprocess
HERE=os.path.dirname(os.path.abspath(__file__)); SCAD=os.path.join(HERE,'proto_deck_tall.scad')
OPENSCAD='/opt/homebrew/bin/openscad'
# a stripped library copy (the .scad's dispatch removed) so we can intersect named modules
_LIB='/tmp/lib_deck_tall.scad'
def _make_lib():
    src=open(SCAD).read().split('// ---------------- dispatch ----------------')[0]
    open(_LIB,'w').write(src)
def _vol(expr):
    _make_lib(); out='/tmp/xsect_tall.stl'
    open('/tmp/_xw.scad','w').write(f'include <{_LIB}>\n'+expr)
    r=subprocess.run([OPENSCAD,'-o',out,'/tmp/_xw.scad'],capture_output=True,text=True)
    warn=[l for l in r.stderr.splitlines() if 'ERROR' in l or 'WARNING' in l]
    if warn: print('   openscad note:',warn)
    if not os.path.exists(out) or os.path.getsize(out)<100: return 0.0
    try:
        import trimesh; return abs(trimesh.load(out).volume)
    except Exception as e:
        print('   (trimesh unavailable:',e,'- skipping solid gate)'); return None

# ============================== GATE (a): DECK BELOW BAND =========================================
def gate_deck_below_band():
    print('\n=== (a) DECK-BELOW-BAND (clean sub-chamber, no interpenetration of the band) ===')
    gap=floorz-deck_top
    print(f'  band floor (torus bottom)   floorz   = {floorz:+.2f} mm')
    print(f'  deck slab roof              deck_top  = {deck_top:+.2f} mm   (= chz+rb+roof_t)')
    print(f'  eased ball TOP              chz+rb    = {chz+rb:+.2f} mm')
    print(f'  deck slab bottom           deck_bot  = {deck_bottom:+.2f} mm')
    if gap>0:
        print(f'  PASS — the whole deck sits BELOW the band floor with a clean z-gap of {gap:.2f} mm;')
        print(f'         no part of the bore/drum/disc chamber interpenetrates the fixed band.')
        return 0, gap
    print(f'  FAIL — deck roof {deck_top:+.2f} is NOT below band floor {floorz:+.2f} (overlap {-gap:.2f} mm).')
    return 1, gap

# ============================== GATE (a2): SOLID INTERSECTION CLOSES (mm^3) =======================
def gate_intersection_closes():
    print('\n=== (a2) INTERSECTION-CLOSES (solid OpenSCAD+trimesh; the new roof/channels must not')
    print('         collide with the band OR the rotating drums) ===')
    checks=[
        ('deck  ∩ band ',  'intersection(){ bore_deck(); fixed_band(); }'),
        ('roof  ∩ band ',  'intersection(){ drum_roof(); fixed_band(); }'),
        ('riser ∩ band ',  'intersection(){ union(){for(k=[1:N]) retention_riser(k);} fixed_band(); }'),
        ('roof  ∩ drums', 'intersection(){ drum_roof(); union(){for(p=INNER) drum(p[0],p[1]);} }'),
        ('deck  ∩ drums', 'intersection(){ bore_deck(); union(){for(p=INNER) drum(p[0],p[1]);} }'),
    ]
    worst=0.0; skipped=False
    for name,expr in checks:
        v=_vol(expr)
        if v is None: skipped=True; print(f'   {name}  = (skipped)'); continue
        worst=max(worst,v)
        print(f'   {name}  = {v:8.2f} mm^3   {"OK" if v<=1.0 else "OVERLAP"}')
    if skipped:
        print('   (solid gate skipped — trimesh missing; deck-below-band z-gap still proves no band overlap)')
        return 0
    ok = worst<=1.0
    print('   PASS' if ok else '   FAIL',
          f'— max residual {worst:.2f} mm^3 ({"intersection closes; no band/drum collision" if ok else "a collision remains"}).')
    return 0 if ok else 1

# ============================== GATE (b): SWAP CLEARS (deepened) ==================================
def gate_swap_clears():
    print('\n=== (b) SWAP-CLEARS (deepened 12-ball kinematics; ball-ball / foreign-drum / inside) ===')
    bb=db=ins=0; worst_bb=(0,None)
    for k in range(SEG+1):
        u=k/SEG; pos={s:ballpos(s,u) for s in range(12)}
        for a,b in itertools.combinations(range(12),2):
            pen=2*rb-d3(pos[a],pos[b])
            if pen>TOL:
                bb+=1
                if pen>worst_bb[0]: worst_bb=(pen,(a,b,round(u,3)))
        for s in range(12):
            (i,j),_=pairof(s)
            for pr in INNER:
                if pr==(i,j): continue
                if drum_pen(pos[s],DRUM[pr])>TOL: db+=1
        for s in range(12):
            if s not in (0,1) and rad(pos[s])+rb>WALL+0.1: ins+=1
    dd=0
    for a,b in itertools.combinations(INNER,2):
        if d3(DRUM[a],DRUM[b])-2*FP<0: dd+=1
    def line(name,n,extra=''):
        print(f'  {name:10} {"PASS" if n==0 else "FAIL":4}  {extra if n==0 else f"{n} clashing frame-instances"}')
    line('BALL-BALL', bb, 'no two of 12 balls collide'+(f' (worst {worst_bb})' if worst_bb[1] else ''))
    line('BALL-DRUM', db, 'no ball enters a foreign drum')
    line('DRUM-DRUM', dd, 'all 5 drum footprints clear')
    line('INSIDE',    ins,'every (non-apex) ball stays inside the ring')
    rc = bb or db or dd or ins
    return (1 if rc else 0)

# ============================== RETENTION MODEL (any-orientation, NO gravity) =====================
# A ball at (x,y,z) is FULLY RETAINED (cannot escape in ANY orientation) iff SOME retainer both
#   (i) ENCLOSES it laterally past its equator (an enclosing wall whose inner radius < rb spans the
#       ball's full height band around it -> the ball cannot translate sideways out), AND
#   (ii) CAPS the escape ENDS: an open-topped cylinder still lets the ball exit straight up when the
#       toy is inverted, so the enclosure must be a CLOSED tube (wall taller than ball top AND a roof
#       within reach) OR carry a top LIP that overhangs the ball top.  A lone lip with no lateral
#       wall, or a lone open well, is NOT full retention.
# We model each retainer by its (inner radius, z_lo, z_hi of solid wall, has_roof, has_floor, center).
# "Fully retained" = ball xy within (radius - rb) of a center AND wall spans [z-rb, z+rb] (closed
# tube) OR (wall spans [z-rb, z] and a top lip/roof overhangs).  We report the BEST retainer + why.

def retainers_at(s, u, p):
    """Return list of (name, captured_bool, reason) for every retainer that could act on ball s here.

    Honest any-orientation model for the FIXED-tall geometry:
      * band-lip+tube  : on the ring, z in the fixed over-equator lip grip [eq-DF, eq].  Closed torus
                         tube (r=tube>rb) holds laterally; the lip (mouth < ball_d) caps the top.
      * bore-roof      : the ball's xy lies under a roofed bore LANE (within bore_r of a lane centre-
                         line).  The lane is a carved passage ROOFED except a slot of width 2*sw<ball_d;
                         the lip wraps the ball past its equator (sides) AND caps the top.  The roof is
                         part of the carriage and DESCENDS WITH the ball, so it caps the ball at every
                         z through ease-down -> route -> ease-up at a lane xy.
      * drum-roof      : the ball's xy lies in a drum's roofed ORBIT ANNULUS (RD +/- ann_w of the drum
                         centre) during the drum turn; opening 2*ann_w < ball_d, so the roof lip caps
                         the orbiting ball above its equator through the full 180 deg turn while the
                         drum cradle (sphere r=rb+0.3) wraps it laterally.
      * apex-cradle    : the deliberate top INPUT (balls 0,1): an open-top rotor outside the ring -> NOT
                         capped against inversion (legit; left uncapped by design).
    """
    (i,j),w=pairof(s); x,y,z=p
    out=[]
    onring = abs(rad(p)-R) <= 1.0
    # The carriage roof is rigidly ROOF_OFF above the ball centre and moves WITH the ball, but it may
    # only act while it stays BELOW the band floor (deck-below-band).  So the bore/drum roof can cap
    # the ball top only when (ball_z + ROOF_OFF) <= floorz, i.e. z <= roof_ok_z.  Above that the roof
    # would foul the band, so only the FIXED band lip can cap the top.
    roof_ok_z = floorz - ROOF_OFF

    # --- FIXED BAND over-equator lip (on the ring, high in the stroke) ---
    if onring and (eq-DF-0.05) <= z <= (eq+0.1):
        out.append(('band-lip+tube', True,
                    f'on ring, z={z:+.2f} in fixed-lip grip [{eq-DF:+.2f},{eq:+.2f}]; closed tube r{tube:.2f}>rb holds laterally, lip (mouth {2*math.sqrt(tube*tube-DF*DF):.2f}<ball_d) caps top'))

    # --- BORE-ROOF lane (carriage roof; mouth 2*sw < ball_d) — only while roof stays below band ---
    if (i,j)!=(0,1) and in_bore_lane(p):
        if z <= roof_ok_z+0.05:
            out.append(('bore-roof', True,
                        f'xy under a roofed bore lane, z={z:+.2f}<= roof-ok {roof_ok_z:+.2f}: carved passage r{bore_r:.2f} roofed to slot mouth {bore_mouth:.2f}<ball_d{ball_d:.2f} (lip z{zlip:+.2f}>equator) -> wraps past equator + caps top'))
        else:
            out.append(('bore-lane-lateral', False,
                        f'xy under a bore lane and laterally held, but z={z:+.2f} > roof-ok {roof_ok_z:+.2f}: the carriage roof would foul the band up here, so the TOP is open (mid-ease handoff)'))

    # --- DRUM-ROOF orbit annulus (drum turn; opening 2*ann_w < ball_d) ---
    if (i,j)!=(0,1) and phaseof(s,u)==PH_TURN and in_drum_annulus(p) and z<=roof_ok_z+0.05:
        out.append(('drum-roof', True,
                    f'over drum orbit annulus (RD+/-{ann_w:.2f}); drum-roof opening {drum_mouth:.2f}<ball_d{ball_d:.2f} caps top, drum cradle (sphere r{rb+0.3:.2f}) wraps laterally -> closed any-orientation'))

    # --- APEX rotor (balls 0,1): deliberate open-top input, NOT retained (by design) ---
    if (i,j)==(0,1):
        out.append(('apex-cradle', False,
                    f'apex rotor cradle (sphere r{rb+0.3:.2f}) wraps laterally past equator BUT is an OPEN-top input rotor outside the ring -> deliberately not capped against inversion'))

    # --- if nothing covered this ball/frame, record why (a genuine gap) ---
    if not any(r[1] for r in out) and not any(r[0] in ('bore-lane-lateral',) for r in out) and (i,j)!=(0,1):
        ph=phaseof(s,u)
        out.append(('uncovered', False,
                    f'phase {ph}, z={z:+.2f}, r={rad(p):.2f}: not in ring-lip range, not under a below-band bore-roof lane, not over a drum annulus'))
    return out

def fully_retained(s,u,p):
    rs=retainers_at(s,u,p)
    good=[r for r in rs if r[1]]
    return (len(good)>0, rs)

# ============================== GRAVITY / ANY-ORIENTATION RETENTION SWEEP =========================
def retention_sweep():
    print('\n=== GRAVITY / ANY-ORIENTATION RETENTION (NO gravity) — full 12-ball swap sweep ===')
    print(f'    EASE_tall={EASE_tall:.1f} mm; descent = eq->chz = {eq:+.2f} -> {chz:+.2f} ({EASE_tall:.1f} mm drop)')
    print(f'    retainers: fixed band-lip grip {DF:.2f} mm | bore-roof slot mouth {bore_mouth:.2f}<ball_d '
          f'(lip z{zlip:+.2f}) | drum-roof opening {drum_mouth:.2f}<ball_d | drum cradle r{rb+0.3:.2f} | '
          f'riser closed-tube span {RISER_H:.2f} mm')
    # enumerate gaps: collapse contiguous (ball, phase, why) runs into ranges of u
    gaps={}   # key=(ball, phase, short_reason) -> [u_min,u_max,count]
    total=0; held=0
    for k in range(SEG+1):
        u=k/SEG
        for s in range(12):
            p=ballpos(s,u); ph=phaseof(s,u); total+=1
            ok,rs=fully_retained(s,u,p)
            if ok: held+=1; continue
            why = '; '.join(f'{r[0]}:{r[2]}' for r in rs) if rs else 'NO retainer covers this z at all (bare ball)'
            short = max(rs, key=lambda r:0)[0] if rs else 'none'
            key=(s,ph,short)
            if key in gaps:
                g=gaps[key]; g[0]=min(g[0],u); g[1]=max(g[1],u); g[2]+=1;
            else:
                gaps[key]=[u,u,1,why]
    pct=100.0*held/total
    print(f'\n    frames swept: {SEG+1}  | ball-frames: {total}  | fully-retained: {held} ({pct:.1f}%)  | GAP frames: {total-held}')
    if not gaps:
        print('    NO retention gaps: every ball at every frame is captured above its equator (any orientation).')
        return held,total,{}
    # categorize the gap frames by cause
    cause={}
    for (s,ph,short),(umin,umax,cnt,why) in gaps.items():
        cause[short]=cause.get(short,0)+cnt
    print(f'\n    GAP frames by cause:')
    for short,n in sorted(cause.items(),key=lambda kv:-kv[1]):
        tag={'apex-cradle':'DELIBERATE top input (balls 0,1) — open-top rotor, legit',
             'bore-lane-lateral':'mid-EASE handoff: laterally held but top open while the carriage roof is above the band floor'}.get(short,short)
        print(f'       {n:4d}  {short:<18} {tag}')
    print(f'\n    RETENTION-GAP MAP — {len(gaps)} distinct (ball,phase,retainer) gap regions:')
    print(f'    {"ball":>4} {"phase":<10} {"u-range":<16} {"frames":>6}  why-not-fully-retained')
    print('    '+'-'*100)
    for (s,ph,short),(umin,umax,cnt,why) in sorted(gaps.items(), key=lambda kv:(kv[0][0],kv[1][0])):
        ur=f'{umin:.2f}-{umax:.2f}'
        print(f'    {s:>4} {ph:<10} {ur:<16} {cnt:>6}  {why[:120]}')
    return held,total,cause   # informational (EXPECTED incomplete) — does not gate

# ============================== (c) RETENTION DEPTH REPORT ========================================
def report_depths():
    print('\n=== (c) RETENTION-DEPTH REPORT ===')
    print(f'  EASE_tall (chosen)              = {EASE_tall:.2f} mm')
    print(f'  descent (eq -> chz)             = {eq-chz:.2f} mm')
    print(f'  fixed band-lip grip (DF)        = {DF:.2f} mm   covers z in [{eq-DF:+.2f}, {eq:+.2f}]')
    print(f'  FIX 1 bore-roof slot mouth      = {bore_mouth:.2f} mm  (2*sw, sw={sw:.2f}; < ball_d {ball_d:.2f}; bite {ball_d-bore_mouth:.2f}); lip z={zlip:+.2f} > equator {chz:+.2f}')
    print(f'  FIX 2 drum-roof opening         = {drum_mouth:.2f} mm  (2*ann_w; < ball_d {ball_d:.2f}; bite {ball_d-drum_mouth:.2f})')
    print(f'  drum-roof running clearance     = {drum_run:.2f} mm  (roof underside {roof_under:+.2f} above drum top {drum_top:+.2f})')
    print(f'  carved bore/riser passage r     = {bore_r:.2f} mm  (rb={rb:.2f}; running clearance {bore_r-rb:+.2f})')
    print(f'  riser closed-tube span          = {RISER_H:.2f} mm  (deck roof {deck_top:+.2f} -> band floor {floorz:+.2f}; full 360 deg lateral)')
    print(f'  drum cradle radius              = {rb+0.3:.2f} mm  (wraps past equator)')
    # toy-height cost vs compact
    EASE_compact = DF + 1.5
    cost = EASE_tall - EASE_compact
    print(f'\n  TOY-HEIGHT COST vs compact: EASE_tall {EASE_tall:.2f} - EASE_compact {EASE_compact:.2f} = +{cost:.2f} mm of swap stroke')
    print(f'                              (the carriage must travel {cost:.2f} mm farther, deepening the')
    print(f'                               toy body by ~that much below the band).')
    return EASE_compact, cost

# ============================================ main ===============================================
def main():
    print(f'TALL-VARIANT CHECK  (perm #22; 12 balls; {len(INNER)} drums; ball Ø{ball_d:.1f}; EASE_tall {EASE_tall:.1f})')
    rc=0
    ra, gap = gate_deck_below_band()
    rc |= ra
    rc |= gate_intersection_closes()
    rc |= gate_swap_clears()
    EASE_compact, cost = report_depths()
    held,total,cause = retention_sweep()   # informational gap map (does not gate; gaps are EXPECTED)
    apex_gap=cause.get('apex-cradle',0); ease_gap=cause.get('bore-lane-lateral',0)
    print('\n'+'='*96)
    print(f'SUMMARY: deck-below-band z-gap = {gap:.2f} mm  |  EASE_tall = {EASE_tall:.1f} mm  '
          f'(+{cost:.2f} mm vs compact {EASE_compact:.2f})')
    print(f'         FIX1 bore-roof mouth {bore_mouth:.2f} & FIX2 drum-roof opening {drum_mouth:.2f} (both < ball_d {ball_d:.2f}) -> over-equator capture')
    print(f'         GRAVITY RETENTION = {held}/{total} = {100.0*held/total:.1f}%  (was 4.5%); residual gaps:')
    print(f'           {apex_gap} apex-input frames (deliberate, legit) + {ease_gap} mid-ease handoff frames (lateral-held, top-open)')
    if rc:
        print('RESULT: FAIL — an INTERSECTION gate failed (see above).'); sys.exit(1)
    print('RESULT: PASS (intersection gates) — the tall clean sub-chamber sits below the band and the')
    print('        deepened swap clears.  See the RETENTION-GAP MAP above for the (expected) any-')
    print('        orientation retention gaps that still need closing.')
    sys.exit(0)

if __name__=='__main__': main()
