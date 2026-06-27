#!/usr/bin/env python3
"""Cross-check the M12-generating swaps against the app's list (swaps.inc).

swaps.inc = MathieuPermutation::swaps[] = { {rating, {12 ints}}, ... } -- the swaps the app offers
as choices (entry #22 1-based = perm #22). Question (Scott's): are there M12 swaps NOT in that list?
"""
import re, math
from find_swap import (SPIN, compose, perm_of, matchings, gens_order_capped,
                       pack_score, dist_profile, canon)

INC = '/Users/scott/Mathieu/PlatformIndependent/M12/Permutation/swaps.inc'
listed = {}
for line in open(INC):
    m = re.search(r'\{\s*(\d+),\s*\{([^}]*)\}\s*\}', line)
    if m:
        rating = int(m.group(1))
        ints = tuple(int(x) for x in m.group(2).split(','))
        if len(ints) == 12: listed[ints] = rating
print(f'parsed swaps.inc: {len(listed)} listed swaps; ratings {min(listed.values())}..{max(listed.values())}')

# every listed swap should generate M12 with the spin
notm12 = [p for p in listed if gens_order_capped([SPIN, p], check_orders=True) != 95040]
print(f'listed swaps that do NOT generate M12: {len(notm12)}')

# enumerate ALL M12-generating fpf involutions (unreduced)
allm12 = set()
for mt in matchings(list(range(12))):
    p = perm_of(mt)
    if gens_order_capped([SPIN, p], check_orders=True) == 95040:
        allm12.add(p)
print(f'total M12-generating swaps (unreduced): {len(allm12)}')

inlist  = allm12 & set(listed)
newones = allm12 - set(listed)
print(f'  in the app list : {len(inlist)}')
print(f'  NOT in the list : {len(newones)}')

def perm_to_cycles(p):
    seen=set(); cyc=[]
    for a,b in [(i,p[i]) for i in range(12)]:
        if a<b and p[b]==a: cyc.append((a,b))
    return cyc
def score(p):
    return pack_score([(a,b) for a,b in perm_to_cycles(p)])

# group the NEW swaps by spin-conjugacy class, report best-packing reps
seen=set(); reps=[]
for p in newones:
    cyc=perm_to_cycles(p); c=canon(cyc)
    if c not in seen: seen.add(c); reps.append(p)
reps.sort(key=lambda p: -score(p)[0])
print(f'\nNEW M12 swaps not in the list: {len(newones)} swaps in {len(reps)} spin-classes.')
print('Best-packing NEW classes (tightest drum clearance; all still <0 = none truly pack):')
print(f'  {"clr":>6} {"gaps":>14}   transpositions')
for p in reps[:10]:
    cyc=sorted(perm_to_cycles(p), key=lambda e:(0 not in e, e))
    ts,_=dist_profile(cyc); tight,_=score(p)
    print(f'  {tight:+6.1f} {str(ts):>14}   ' + ' '.join(f'({a} {b})' for a,b in cyc))

# is perm #22 in the list, and what's the evenest LISTED swap?
P22=(1,0,9,4,3,6,5,8,7,2,11,10)
print(f'\nperm #22 in list: {P22 in listed} (rating {listed.get(P22)})')
best_listed=max(listed, key=lambda p: score(p)[0])
ts,_=dist_profile(perm_to_cycles(best_listed)); print(f'evenest-packing LISTED swap: clr {score(best_listed)[0]:+.1f}, gaps {ts}, rating {listed[best_listed]}')
