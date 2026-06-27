#!/usr/bin/env python3
"""COMBINED INTERFERENCE SWEEP — the whole alternative assembly, perm #22, all 12 balls at once.

The per-piece proofs (check_band/pocket/swap1/layout) each checked one concern. This is the
integration test: every one of the 12 balls runs its full swap path SIMULTANEOUSLY (apex 0,1 at
the top; 2,9 to the central drum; the four rim pairs to their rim drums), and we check, at every
frame:
  BALL-BALL    no two of the 12 balls collide (the cross-pair test the per-pair checks couldn't do)
  BALL-DRUM    no ball penetrates a drum it doesn't belong to
  DRUM-DRUM    the 5 drum footprints stay clear (static)
  INSIDE       every ball stays inside the ring
  RETENTION    every ball is capped above its equator (band lip up / ceiling lip down)
Exit non-zero on any clash so it gates.  Mirrors clean/proto_band.scad geometry.
"""
import math, sys, itertools

SCALE=1.25; R=50*SCALE; N=11; ball_d=18*SCALE; rb=ball_d/2; eq=ball_d/2
tube=rb+0.3; RD=rb+0.5; FP=RD+rb+1.0; CR=R-RD-1.0; CLEAR=CR-FP; apexR=R+24*SCALE
WALL=R+tube
spin_top=eq+math.sqrt(tube*tube-rb*rb)+1.5; DF=spin_top-eq; EASE=DF+1.5; DC=EASE-DF+2.0
SEG=120; TOL=0.4

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

def pairof(s):
    for (i,j) in ALLP:
        if s in (i,j): return (i,j), (0 if s==i else 1)
def routed(i,j,which,u):
    home=P(i) if which==0 else P(j); away=P(j) if which==0 else P(i)
    e=ENT[(i,j)]; ehome=e[0] if which==0 else e[1]; eaway=e[1] if which==0 else e[0]; C=DRUM[(i,j)]
    isf=far(i,j); z=eq-EASE
    if u<=0.10: return (*home, eq-EASE*(u/0.10))
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
    return (*away, eq-EASE*((1.0-u)/0.10))
def apex_ball(which,u):                     # 0,1 swap by a small 180 rotor at the TOP (outside the ring)
    M=mid(0,1); s=P(0) if which==0 else P(1); return (*rot2(s,M,math.pi*u), eq)
def ballpos(s,u):
    (i,j),w=pairof(s)
    return apex_ball(w,u) if (i,j)==(0,1) else routed(i,j,w,u)

def capped(z): return (eq-DF-0.1)<=z<=eq+0.1 or (eq-EASE-0.1)<=z<=(eq-EASE+DC)
def drum_pen(p, C):                          # ball vs a drum footprint cylinder (chamber level)
    dr=max(0.0, math.hypot(p[0]-C[0],p[1]-C[1])-FP); dz=max(0.0,(eq-EASE-rb)-p[2], p[2]-(eq-EASE+1))
    return rb-math.hypot(dr,dz)

def main():
    print(f'COMBINED SWEEP  (perm #22; 12 balls; {len(INNER)} drums; ball Ø{ball_d:.1f})')
    bb=db=ins=ret=0; worst_bb=(0,None)
    for k in range(SEG+1):
        u=k/SEG; pos={s:ballpos(s,u) for s in range(12)}
        # ball-ball (all 66 pairs)
        for a,b in itertools.combinations(range(12),2):
            pen=2*rb-d3(pos[a],pos[b])
            if pen>TOL:
                bb+=1
                if pen>worst_bb[0]: worst_bb=(pen,(a,b,round(u,3)))
        # ball vs foreign drum
        for s in range(12):
            (i,j),_=pairof(s)
            for pr in INNER:
                if pr==(i,j): continue
                if drum_pen(pos[s],DRUM[pr])>TOL: db+=1
        # inside (apex pair 0,1 is the protruding TOP input zone, legitimately outside the ring) + retention
        for s in range(12):
            if s not in (0,1) and rad(pos[s])+rb>WALL+0.1: ins+=1
            if not capped(pos[s][2]): ret+=1
    # drum-drum (static)
    dd=0
    for a,b in itertools.combinations(INNER,2):
        if d3(DRUM[a],DRUM[b])-2*FP<0: dd+=1

    def line(name,n,extra=''):
        print(f'  {name:10} {"PASS" if n==0 else "FAIL":4}  {extra if n==0 else f"{n} clashing frame-instances"}')
    print()
    line('BALL-BALL', bb, 'no two of the 12 balls ever collide'+(f' (worst {worst_bb}) ' if worst_bb[1] else ''))
    line('BALL-DRUM', db, 'no ball enters a foreign drum')
    line('DRUM-DRUM', dd, 'all 5 drum footprints clear')
    line('INSIDE',    ins,'every ball stays inside the ring')
    line('RETENTION', ret,'every ball capped above its equator at every frame')
    rc = bb or db or dd or ins or ret
    print()
    if rc: print('RESULT: FAIL — the assembled swap has interference (see above).'); sys.exit(1)
    print('RESULT: PASS — all 12 balls swap simultaneously with no collision, nothing enters a foreign');
    print('               drum, all drums clear, nothing leaves the ring, every ball stays captured.'); sys.exit(0)

if __name__=='__main__': main()
