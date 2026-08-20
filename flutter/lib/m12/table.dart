// The whole group, breadth-first.
//
// M12 has 95,040 elements and eleven natural neighbours per element (R1..R5,
// L1..L5, S — the move set M12PermTable.cpp:72-80 uses). That is small enough
// to enumerate at runtime, which is the whole reason this is Dart rather than a
// shipped asset:
//
//   * PlatformIndependent/M12/Permutation/Perms.bin.golden is a 4.35 MB git-LFS
//     blob that is not even fetched in this tree, is byte-nondeterministic on
//     regeneration (REGENERATION.md:39-45), and is valid for exactly ONE of the
//     341 swap permutations the app lets you choose.
//   * A runtime BFS is correct for all 341, costs ~1.3 MB of memory and well
//     under a second, and needs no asset-loading path on web.
//
// Everything the tutorial claims about distance, diameter, cheapest words and
// small-support elements is read out of this table for the swap in force. No
// lesson may hard-code any of it: under swap #1 the diameter is 11 and the
// cheapest 3+3+3 is RSRS, under swap #21 the diameter is 12 and RSRS is a
// 2+2+2+2 instead.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;

import 'perm.dart';
import 'rank.dart';
import 'word.dart';

/// Index of each neighbour move, in the order the table stores them.
const int kMoveCount = 11;

/// Human notation for move index [mi] (0..4 = R1..R5, 5..9 = L1..L5, 10 = S).
String moveLabel(int mi) {
  if (mi == 10) return 'S';
  final n = mi < 5 ? mi + 1 : mi - 4;
  return '${mi < 5 ? 'R' : 'L'}${n > 1 ? '$n' : ''}';
}

/// The history element for move index [mi].
int moveElement(int mi) => mi == 10 ? 0 : (mi < 5 ? mi + 1 : -(mi - 4));

/// The move index that undoes [mi].
int inverseMove(int mi) => mi == 10 ? 10 : (mi < 5 ? mi + 5 : mi - 5);

/// The eleven neighbour permutations, for a given swap.
List<Uint8List> neighbourGenerators(List<int> swap, {List<int> right = kRight}) {
  final rightInv = inversePerm(right);
  final gens = <Uint8List>[];
  for (final base in [right, rightInv]) {
    var acc = identityPerm(kBalls);
    for (var k = 0; k < 5; k++) {
      acc = compose(acc, base);
      gens.add(Uint8List.fromList(acc));
    }
  }
  // gens is R1..R5 then L1..L5; append the swap.
  gens.add(Uint8List.fromList(swap));
  return gens;
}

/// A breadth-first map of the whole group, for one swap permutation.
class M12Table {
  /// The swap this table describes. A table is meaningless under any other.
  final int swapIndex;
  final List<int> swap;

  /// dist[rank] = shortest number of moves from home. Never 255 — every rank is
  /// reachable, which is itself checked when the table is built.
  final Uint8List dist;

  /// The move that produced this rank on a shortest path; -1 at home.
  final Int8List prevMove;

  /// perms[rank*12 + i] = the permutation with that rank.
  final Uint8List perms;

  /// The largest distance from home — God's number for this swap.
  final int diameter;

  /// How long the BFS took, so the app can report an honest number.
  final Duration buildTime;

  const M12Table._({
    required this.swapIndex,
    required this.swap,
    required this.dist,
    required this.prevMove,
    required this.perms,
    required this.diameter,
    required this.buildTime,
  });

  /// The permutation stored at [rank].
  List<int> permAt(int rank) {
    final base = rank * kBalls;
    return List<int>.generate(kBalls, (i) => perms[base + i]);
  }

  /// Distance from home to [p], in moves. Exact, not an estimate.
  int distanceOf(List<int> p) => dist[m12Rank(p)];

  /// The eleven neighbour generators, rebuilt on demand (cheap).
  List<Uint8List> get generators => neighbourGenerators(swap);

  /// A shortest word taking home to the element at [rank].
  Word wordTo(int rank) {
    final gens = generators;
    final moves = <int>[];
    var r = rank;
    var p = permAt(r);
    while (dist[r] != 0) {
      final mi = prevMove[r];
      moves.add(mi);
      // Step back along the edge we came in on.
      final g = gens[inverseMove(mi)];
      p = List<int>.generate(kBalls, (i) => p[g[i]]);
      r = m12Rank(p);
    }
    final w = Word.empty();
    for (final mi in moves.reversed) {
      w.push(moveElement(mi));
    }
    return w;
  }

  /// A shortest word for the element [p] itself.
  Word wordFor(List<int> p) => wordTo(m12Rank(p));

  /// A shortest word taking the *current position* [p] home, i.e. for p⁻¹.
  Word solutionFrom(List<int> p) => wordFor(inversePerm(p));

  /// The next move on some shortest path home from [p], or null if already home.
  int? nextMoveHome(List<int> p) {
    final d = distanceOf(p);
    if (d == 0) return null;
    final gens = generators;
    for (var mi = 0; mi < kMoveCount; mi++) {
      final g = gens[mi];
      final q = List<int>.generate(kBalls, (i) => p[g[i]]);
      if (dist[m12Rank(q)] < d) return mi;
    }
    return null; // unreachable: dist is a true metric on the Cayley graph
  }

  /// How many elements sit at each distance. Index = distance.
  List<int> get distanceHistogram {
    final h = List<int>.filled(diameter + 1, 0);
    for (var r = 0; r < kM12Order; r++) {
      h[dist[r]]++;
    }
    return h;
  }

  // --- construction ---------------------------------------------------------

  /// Build the table for [swap] off the UI thread where the platform has
  /// threads. On web `compute` runs inline (dart2js has no isolates), which is
  /// why callers show a "working" state around this rather than assuming it is
  /// free.
  static Future<M12Table> build(int swapIndex, List<int> swap) =>
      compute(_buildEntry, _BuildRequest(swapIndex, swap));

  /// Synchronous build — used by tests and by the isolate entry point.
  static M12Table buildSync(int swapIndex, List<int> swap) {
    final sw = Stopwatch()..start();
    final gens = neighbourGenerators(swap);

    final dist = Uint8List(kM12Order)..fillRange(0, kM12Order, 255);
    final prev = Int8List(kM12Order)..fillRange(0, kM12Order, -1);
    final perms = Uint8List(kM12Order * kBalls);

    // A plain ring buffer beats a growable queue here: we know the exact
    // number of states, so it never resizes.
    final queue = Int32List(kM12Order);
    var head = 0, tail = 0;

    final ident = identityPerm(kBalls);
    final r0 = m12Rank(ident);
    dist[r0] = 0;
    for (var i = 0; i < kBalls; i++) {
      perms[r0 * kBalls + i] = i;
    }
    queue[tail++] = r0;

    final cur = Uint8List(kBalls);
    final nxt = Uint8List(kBalls);
    final inv = Uint8List(kBalls);
    var seen = 1;
    var diameter = 0;

    while (head < tail) {
      final r = queue[head++];
      final d = dist[r];
      if (d > diameter) diameter = d;
      final base = r * kBalls;
      for (var i = 0; i < kBalls; i++) {
        cur[i] = perms[base + i];
      }
      for (var mi = 0; mi < kMoveCount; mi++) {
        final g = gens[mi];
        for (var i = 0; i < kBalls; i++) {
          nxt[i] = cur[g[i]];
        }
        final nr = _rankOf(nxt, inv);
        if (dist[nr] != 255) continue;
        dist[nr] = d + 1;
        prev[nr] = mi;
        final nb = nr * kBalls;
        for (var i = 0; i < kBalls; i++) {
          perms[nb + i] = nxt[i];
        }
        queue[tail++] = nr;
        seen++;
      }
    }

    // Reaching every rank is the proof that m12Rank is injective on the group:
    // |M12| == 95040 == the number of distinct ranks, so no two elements can
    // have collided without leaving a rank unvisited.
    assert(seen == kM12Order,
        'BFS reached $seen of $kM12Order ranks — the swap does not generate M12, '
        'or the rank hash collided.');

    sw.stop();
    return M12Table._(
      swapIndex: swapIndex,
      swap: List<int>.unmodifiable(swap),
      dist: dist,
      prevMove: prev,
      perms: perms,
      diameter: diameter,
      buildTime: sw.elapsed,
    );
  }

  /// m12Rank over a Uint8List, reusing [inv] so the hot loop allocates nothing.
  static int _rankOf(Uint8List p, Uint8List inv) {
    for (var i = 0; i < kBalls; i++) {
      inv[p[i]] = i;
    }
    var i = 0;
    var fi = inv[0];
    var r = fi;
    while (true) {
      for (var j = i + 1; j < 5; j++) {
        if (fi < inv[j]) inv[j]--;
      }
      i++;
      if (i >= 5) break;
      fi = inv[i];
      r = r * (kBalls - i) + fi;
    }
    return r;
  }
}

class _BuildRequest {
  final int swapIndex;
  final List<int> swap;
  const _BuildRequest(this.swapIndex, this.swap);
}

M12Table _buildEntry(_BuildRequest req) => M12Table.buildSync(req.swapIndex, req.swap);
