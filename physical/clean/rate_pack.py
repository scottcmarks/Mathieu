#!/usr/bin/env python3
"""For the LISTED swaps: which ratings go with which distance-profiles (is any 'nice' profile a
rating-4?), and how does the (2,2,2,2,3) swap pack as a 5-drum (apex-excluded) layout?
Rating and profile are both reflection-invariant, so scanning the 341 listed swaps covers all."""
import re, math
INC='/Users/scott/Mathieu/PlatformIndependent/M12/Permutation/swaps.inc'
N=12; SCALE=1.25; R=50*SCALE; rb=9*SCALE; tube=rb+0.3; RD=rb+0.5; FP=RD+rb+1; CR=R-RD-1; apexR=R+24*SCALE
def A(s): return -90+(s-1)*(360.0/11)
def P(s):
    if s==0: return (0.0,apexR)
    a=math.radians(A(s)); return (R*math.cos(a),-R*math.sin(a))
def cycles(p): return [(a,p[a]) for a in range(N) if a<p[a] and p[p[a]]==a]
def stdist(a,b):
    if 0 in (a,b): return None
    d=abs(a-b); return min(d,11-d)
def profile(p):
    cyc=cycles(p); ds=sorted(d for d in (stdist(a,b) for a,b in cyc) if d is not None)
    apexpart=[b if a==0 else a for a,b in cyc if 0 in (a,b)][0]
    return tuple(ds), apexpart
def unit(v): r=math.hypot(*v); return (v[0]/r, v[1]/r) if r>1e-9 else (1.0,0.0)
def pack(p):
    inner=[(a,b) for a,b in cycles(p) if 0 not in (a,b)]            # apex pair excluded (it's the top input)
    C=[]
    for a,b in inner:
        M=((P(a)[0]+P(b)[0])/2,(P(a)[1]+P(b)[1])/2); mr=math.hypot(*M); u=unit(M)
        t=min(mr,CR); C.append((u[0]*t,u[1]*t))
    tight=min((math.dist(C[i],C[j])-2*FP) for i in range(len(C)) for j in range(i+1,len(C)))
    far=max(math.hypot(*c)+RD+rb-(R+rb) for c in C)                 # ball past ring edge?
    return tight, far

listed={}
for line in open(INC):
    m=re.search(r'\{\s*(\d+),\s*\{([^}]*)\}\s*\}',line)
    if m:
        r=int(m.group(1)); v=tuple(int(x) for x in m.group(2).split(','))
        if len(v)==12: listed[v]=r

# --- task 1: rating-4 profiles ---
from collections import defaultdict
byrate=defaultdict(list)
for p,r in listed.items():
    prof,ap=profile(p); tight,far=pack(p); byrate[r].append((prof,ap,tight,far,p))
print('ratings present:', sorted(byrate))
print(f'\n#22 = (0 1)(2 9)(3 4)(5 6)(7 8)(10 11): profile (1,1,1,1,4) apex->1, rating {listed.get((1,0,9,4,3,6,5,8,7,2,11,10))}\n')
print('RATING-4 swaps, by distance-profile (apex->partner), best drum-clearance per profile:')
prof4=defaultdict(lambda:(-1e9,None))
for prof,ap,tight,far,p in byrate.get(4,[]):
    key=(prof,ap)
    if tight>prof4[key][0]: prof4[key]=(tight,p)
for (prof,ap),(tight,p) in sorted(prof4.items(), key=lambda kv:-kv[1][0]):
    cyc=' '.join(f'({a} {b})' for a,b in sorted(cycles(p),key=lambda e:(0 not in e,e)))
    fit='FITS' if tight>0 else '    '
    print(f'  profile {str(prof):16} apex->{ap:<2} drum-clr {tight:+6.1f} {fit}   {cyc}')

# --- task 2: the (2,2,2,2,3) swap ---
def perm_of(pairs):
    p=list(range(12))
    for a,b in pairs: p[a]=b; p[b]=a
    return tuple(p)
T=perm_of([(0,1),(2,4),(3,5),(6,8),(7,10),(9,11)])
# reflection through the apex axis: 0->0,1->1,2<->11,3<->10,4<->9,5<->8,6<->7
refl=[0,1,11,10,9,8,7,6,5,4,3,2]
Tm=tuple(refl[T[refl[i]]] for i in range(12))
rt = listed.get(T) or listed.get(Tm)
tight,far=pack(T)
print(f'\n(2,2,2,2,3) swap (0 1)(2 4)(3 5)(6 8)(7 10)(9 11): rating {rt}, drum-clr {tight:+.1f}, ball-past-wall {far:+.1f}')
print(f'  vs #22: drum-clr {pack((1,0,9,4,3,6,5,8,7,2,11,10))[0]:+.1f}')
