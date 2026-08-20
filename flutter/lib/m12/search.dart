// Searches over the whole group. All of them are single linear passes over the
// 95,040-entry table, which is fast enough to be exhaustive — so the answers
// are guaranteed cheapest, not merely good.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;

import 'perm.dart';
import 'rank.dart';
import 'table.dart';
import 'word.dart';

/// The cheapest element of one (support size, cycle type) class.
class DiscoveryEntry {
  final int supportSize;
  final List<int> type;
  final int moves;
  final int rank;
  final List<int> perm;
  final Word word;

  /// How many elements of the group share this class.
  final int population;

  const DiscoveryEntry({
    required this.supportSize,
    required this.type,
    required this.moves,
    required this.rank,
    required this.perm,
    required this.word,
    required this.population,
  });

  String get typeLabel => type.isEmpty ? 'identity' : type.join('+');
}

/// The result of scanning the group by how much each element disturbs.
class Discovery {
  /// How many elements move exactly n seats, keyed by n.
  final Map<int, int> supportCensus;

  /// Cheapest representative of each class, least-disturbing first.
  final List<DiscoveryEntry> entries;

  final Duration searchTime;

  const Discovery({
    required this.supportCensus,
    required this.entries,
    required this.searchTime,
  });

  /// The floor: the smallest support any non-identity element achieves.
  int get minimumSupport =>
      supportCensus.keys.where((k) => k > 0).fold(kBalls, (a, b) => a < b ? a : b);

  /// Entries at the floor, plus the class just above it — the shortlist the
  /// tutorial actually works with. The identity is excluded: it is technically
  /// the least disturbing element of all, and saying so is not a lesson.
  List<DiscoveryEntry> get shortlist => entries
      .where((e) => e.supportSize > 0 && e.supportSize <= minimumSupport + 1)
      .toList();
}

/// Scan every element, keeping the cheapest word per (support, cycle type).
///
/// Must be recomputed per swap: under swap #1 the cheapest 3+3+3 is RSRS at 4
/// moves and the cheapest 4+4 is SRSL2 at 4, while under swap #21 the cheapest
/// 4+4 is RS at *two*. Hard-coding any of it would be wrong.
Discovery discoverSync(M12Table t) {
  final sw = Stopwatch()..start();
  final census = <int, int>{};
  final best = <String, DiscoveryEntry>{};
  final population = <String, int>{};

  final p = Uint8List(kBalls);
  for (var r = 0; r < kM12Order; r++) {
    final base = r * kBalls;
    var supp = 0;
    for (var i = 0; i < kBalls; i++) {
      final v = t.perms[base + i];
      p[i] = v;
      if (v != i) supp++;
    }
    census[supp] = (census[supp] ?? 0) + 1;
    // Cycle type, without allocating: walk each unvisited orbit.
    final type = _cycleType(p);
    final key = '$supp:${type.join(",")}';
    population[key] = (population[key] ?? 0) + 1;
    final d = t.dist[r];
    final cur = best[key];
    if (cur == null || d < cur.moves) {
      best[key] = DiscoveryEntry(
        supportSize: supp,
        type: type,
        moves: d,
        rank: r,
        perm: List<int>.of(p),
        word: Word.empty(), // filled in below, once, for the winners only
        population: 0,
      );
    }
  }

  // Reconstructing a word walks the prevMove chain, so do it only for the
  // handful of class winners rather than for all 95,040.
  final entries = best.entries.map((e) {
    final v = e.value;
    return DiscoveryEntry(
      supportSize: v.supportSize,
      type: v.type,
      moves: v.moves,
      rank: v.rank,
      perm: v.perm,
      word: t.wordTo(v.rank),
      population: population[e.key] ?? 0,
    );
  }).toList()
    ..sort((a, b) {
      final s = a.supportSize.compareTo(b.supportSize);
      if (s != 0) return s;
      final m = a.moves.compareTo(b.moves);
      if (m != 0) return m;
      return b.type.length.compareTo(a.type.length);
    });

  sw.stop();
  return Discovery(
    supportCensus: Map<int, int>.fromEntries(
        census.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
    entries: entries,
    searchTime: sw.elapsed,
  );
}

List<int> _cycleType(Uint8List p) {
  final seen = List<bool>.filled(kBalls, false);
  final t = <int>[];
  for (var i = 0; i < kBalls; i++) {
    if (seen[i]) continue;
    var len = 0;
    var j = i;
    while (!seen[j]) {
      seen[j] = true;
      len++;
      j = p[j];
    }
    if (len > 1) t.add(len);
  }
  t.sort((a, b) => b - a);
  return t;
}

/// A setup word that aims a macro at chosen seats.
class Conjugation {
  /// The setup, X.
  final Word setup;
  final List<int> setupPerm;

  /// The macro being aimed, M, and the result X·M·X⁻¹.
  final List<int> macroPerm;
  final List<int> resultPerm;

  /// The full word: setup, macro, setup undone.
  final Word fullWord;

  /// Setup + macro + undo counted as three separate pieces.
  final int totalMoves;

  /// What it costs once written as one word: the seam between the setup and
  /// the macro usually cancels, so this is normally smaller than [totalMoves].
  int get joinedMoves => fullWord.moves;

  /// How many moves the joins saved.
  int get movesSavedByJoining => totalMoves - joinedMoves;

  const Conjugation({
    required this.setup,
    required this.setupPerm,
    required this.macroPerm,
    required this.resultPerm,
    required this.fullWord,
    required this.totalMoves,
  });

  List<int> get resultSupport => supportOf(resultPerm);
}

/// Find the cheapest X with X(support of [macroPerm]) == [targetSeats], then
/// return the conjugate X·M·X⁻¹ and its word.
///
/// **There is no failure case.** M12 is sharply 5-transitive, hence transitive
/// on k-subsets for every k, so a setup word always exists for any target of
/// the right size. Measured over all 220 triples: under swap #1 the setup costs
/// at most 5 moves (mean 3.74), under swap #21 at most 6 (mean 4.15). The only
/// way this returns null is a target of the wrong size or an identity macro.
Conjugation? findConjugationSync(
  M12Table t,
  List<int> macroPerm,
  Set<int> targetSeats, {
  Word? macroWord,
}) {
  final supp = supportOf(macroPerm);
  if (supp.isEmpty) return null;
  if (targetSeats.length != supp.length) return null;

  // Membership as a bitmask so the inner test is one integer compare.
  var targetMask = 0;
  for (final s in targetSeats) {
    if (s < 0 || s >= kBalls) return null;
    targetMask |= 1 << s;
  }

  var bestRank = -1;
  var bestDist = 1 << 30;
  for (var r = 0; r < kM12Order; r++) {
    final d = t.dist[r];
    if (d >= bestDist) continue;
    final base = r * kBalls;
    var mask = 0;
    for (final i in supp) {
      mask |= 1 << t.perms[base + i];
    }
    if (mask != targetMask) continue;
    bestDist = d;
    bestRank = r;
  }
  if (bestRank < 0) return null; // 5-transitivity says we never get here

  final x = t.permAt(bestRank);
  final setup = t.wordTo(bestRank);
  final result = conjugate(x, macroPerm);
  final mw = macroWord ?? t.wordFor(macroPerm);
  final full = setup.times(mw).times(setup.inverted());

  return Conjugation(
    setup: setup,
    setupPerm: x,
    macroPerm: macroPerm,
    resultPerm: result,
    fullWord: full,
    totalMoves: setup.moves * 2 + mw.moves,
  );
}

// --- off-thread wrappers ----------------------------------------------------
//
// A table is ~1.3 MB, so shipping it into an isolate and the result back costs
// more than the scan itself on native, and on web `compute` runs inline anyway.
// These exist so the UI can await them uniformly; the discovery scan is the one
// that genuinely benefits.

Future<Discovery> discover(M12Table t) => compute(discoverSync, t);

Future<Conjugation?> findConjugation(
  M12Table t,
  List<int> macroPerm,
  Set<int> targetSeats, {
  Word? macroWord,
}) async =>
    findConjugationSync(t, macroPerm, targetSeats, macroWord: macroWord);
