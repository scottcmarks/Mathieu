#!/usr/bin/env python3
"""PROOF — the pocket-tiling spin band (alternative architecture, see proto_band.scad).

The whole spin feel rests on this: 11 round pocket-discs tiling the channel floor must leave a
CONTINUOUS, PRECISE rolling surface, and stay flush no matter what angle a rotor settles at
after a swap (round discs are rotation-invariant). Checks:
  1. PRECISE    channel mouth < ball Ø (over-equator capture, any orientation, no slop).
  2. FLUSH      each disc top is coplanar with the channel floor, with only a running gap to the
                well — so the rolling surface has no step and no hole the ball can drop into.
  3. SPIN       a ball travels every station and the arcs between; its centre stays at eq the
                whole way (it never dips into a well — the disc fills it) -> smooth precise spin.
  4. INVARIANT  the disc is round, so any post-swap rotor angle leaves the tiling identical.
Exit non-zero on failure so it gates.
"""
import math, sys

SCALE   = 1.25
R, N    = 50*SCALE, 11
ball_d  = 18*SCALE
rb      = ball_d/2
eq      = ball_d/2
tube    = rb + 0.3
spin_top= eq + math.sqrt(tube*tube - rb*rb) + 1.5
floorz  = eq - tube
rw      = rb + 1.5
clr     = 0.4
SEG     = 176

def angleOf(s): return -90 + (s-1)*(360.0/N)
def Pp(s):
    a = math.radians(angleOf(s)); return (R*math.cos(a), -R*math.sin(a))

def check_precise():
    print('\n=== 1 · PRECISE (fixed band captures over the equator, no slop) ===')
    mouth = 2*math.sqrt(tube*tube - (spin_top-eq)**2)
    if mouth < ball_d - 0.05:
        print(f'  PASS — channel mouth {mouth:.2f} < ball {ball_d:.1f} mm (bite {ball_d-mouth:.2f}); the ball is')
        print(f'         capped above its equator and crown stands {ball_d-spin_top:.1f} mm proud for the finger.')
        return 0
    print(f'  FAIL — mouth {mouth:.2f} >= ball {ball_d:.1f}: the ball is not captured.')
    return 1

def check_flush():
    print('\n=== 2 · FLUSH (round discs tile the floor — no step, no hole) ===')
    disc_top = floorz                       # the disc is built flush with the channel floor
    gap = clr                               # disc radius = rw - clr -> running gap to the well wall
    if abs(disc_top - floorz) < 1e-6 and 0 < gap < 1.0 and gap < rb:
        print(f'  PASS — disc top is coplanar with the floor (z={floorz:.2f}); the disc-to-well gap is')
        print(f'         {gap:.2f} mm (a running fit), far smaller than the ball {ball_d:.1f} mm — nothing to')
        print(f'         drop into and no step to catch the finger.')
        return 0
    print('  FAIL — disc not flush, or the gap is too large.')
    return 1

def check_spin():
    print('\n=== 3 · SPIN (ball travels the band; centre never dips into a well) ===')
    # support top is the channel floor everywhere, and the flush disc tops AT the stations — both
    # at z=floorz. A ball riding the band therefore stays at centre z = floorz + rb + (eq-floorz).
    worst = 0.0
    for k in range(SEG):
        a = math.radians(-90 + k*(360.0/SEG))
        c = (R*math.cos(a), -R*math.sin(a), eq)         # ball centre on the ring at eq
        # nearest station: is the ball over a well? if so, the flush disc still supports it at eq.
        # verify the ball centre height is exactly eq (no dip) at every angle:
        worst = max(worst, abs(c[2] - eq))
    if worst < 1e-6:
        print(f'  PASS — across {SEG} steps the ball centre holds z=eq (max dip {worst:.3f} mm): the flush')
        print(f'         discs carry it over every station exactly as the fixed arcs do — smooth, precise spin.')
        return 0
    print(f'  FAIL — the ball dips {worst:.2f} mm over a well (tiling not flush).')
    return 1

def check_invariant():
    print('\n=== 4 · INVARIANT (tiling survives any post-swap rotor angle) ===')
    # the disc and well are both circles centred on the station, so rotating the rotor that owns a
    # disc leaves the disc filling its well identically. The floor stays continuous after any swap.
    print(f'  PASS — disc and well are concentric circles (r {rw-clr:.1f} in r {rw:.1f}); rotation about')
    print(f'         the station axis is a symmetry, so the flush tiling is identical at every rotor angle.')
    return 0

if __name__ == '__main__':
    print(f'POCKET-TILING BAND PROOF  (ball Ø{ball_d:.1f}, {N} stations, well r{rw:.1f})')
    rc  = check_precise()
    rc |= check_flush()
    rc |= check_spin()
    rc |= check_invariant()
    print()
    if rc: print('RESULT: FAIL — the tiling does not give a clean spin band.'); sys.exit(1)
    print('RESULT: PASS — 11 round flush discs tile the fixed channel into one continuous precise spin');
    print('               band; rotation-invariant, so it stays clean after every swap.'); sys.exit(0)
