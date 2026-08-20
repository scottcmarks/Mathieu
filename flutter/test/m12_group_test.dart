// The correctness net for the group layer.
//
// Three independent anchors, because "the maths looks right" is not a test:
//
//  1. swaps.inc — the swap permutations are read out of the C++ source the
//     engine compiles, not copied into this file.
//  2. engine_fixture.dart — random move sequences replayed through the real
//     mathieu_ffi.cpp, with its own reduced notation and permutation recorded.
//     lib/m12/word.dart is a port of that reduction; this proves it matches.
//  3. perms.lst — the 95,040-row God's-algorithm table generated offline in
//     2009. The runtime BFS must reproduce its move count for every single row.
//
// Anchor 3 is what finally makes Perms.bin.golden (a 4.35 MB git-LFS blob that
// is not even fetched in this tree) non-load-bearing.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/m12/analysis.dart';
import 'package:mathieu/m12/perm.dart';
import 'package:mathieu/m12/rank.dart';
import 'package:mathieu/m12/search.dart';
import 'package:mathieu/m12/table.dart';
import 'package:mathieu/m12/word.dart';

import 'engine_fixture.dart';

// --- reading the engine's own data ------------------------------------------

const _repo = '..';
const _permDir = '$_repo/PlatformIndependent/M12/Permutation';

/// Every swap permutation, parsed straight out of swaps.inc.
List<List<int>> loadSwaps() {
  final src = File('$_permDir/swaps.inc').readAsStringSync();
  final re = RegExp(r'\{\s*(-?\d+),\s*\{([^}]*)\}\s*\}');
  final out = <List<int>>[];
  for (final m in re.allMatches(src)) {
    final p = m
        .group(2)!
        .split(',')
        .map((s) => int.parse(s.trim()))
        .toList();
    if (p.length == kBalls) out.add(p);
  }
  return out;
}

final List<List<int>> swaps = loadSwaps();
List<int> swapAt(int i) => swaps[i];

// The app's default swap, and the one the physical toy uses.
const int kDefaultSwapIndex = 1;
const int kPlanarSwapIndex = 21;

/// The five engine macro codes, spelled out here so the test does not depend
/// on the library layer to know what a macro element looks like.
const List<int> kMacroSlotsForTest = [65, 66, 67, 68, 69];

void main() {
  group('swaps.inc', () {
    test('has 341 entries, all six disjoint 2-cycles', () {
      expect(swaps.length, 341);
      for (final s in swaps) {
        expect(cycleType(s), [2, 2, 2, 2, 2, 2]);
        expect(compose(s, s), identityPerm());
      }
    });

    test('index 21 is the brief\'s internally-planar swap', () {
      expect(swapAt(kPlanarSwapIndex), [1, 0, 9, 4, 3, 6, 5, 8, 7, 2, 11, 10]);
      expect(cyclesString(swapAt(kPlanarSwapIndex)),
          '(0 1)(2 9)(3 4)(5 6)(7 8)(10 11)');
    });
  });

  group('permutation arithmetic', () {
    final rnd = math.Random(7);
    final r = kRight;
    final s = swapAt(kDefaultSwapIndex);

    List<int> sample() => randomWordPerm(rnd, r, s, 1 + rnd.nextInt(20));

    test('compose matches the C++ (a*b)[i] = a[b[i]]', () {
      // right() is p *= R, so one right from home must equal R itself.
      expect(compose(identityPerm(), r), r);
      expect(compose(r, identityPerm()), r);
    });

    test('composition is associative', () {
      for (var i = 0; i < 200; i++) {
        final a = sample(), b = sample(), c = sample();
        expect(compose(compose(a, b), c), compose(a, compose(b, c)));
      }
    });

    test('inverse really inverts, on both sides', () {
      for (var i = 0; i < 200; i++) {
        final a = sample();
        expect(compose(a, inversePerm(a)), identityPerm());
        expect(compose(inversePerm(a), a), identityPerm());
      }
    });

    test('the generators have the orders the group needs', () {
      expect(orderOf(r), 11);
      expect(cycleType(r), [11]);
      expect(r[0], 0, reason: 'the outboard seat never spins');
      expect(orderOf(s), 2);
    });

    test('order is the number of repeats that returns home', () {
      for (var i = 0; i < 100; i++) {
        final a = sample();
        var p = identityPerm();
        for (var k = 0; k < orderOf(a); k++) {
          p = compose(p, a);
        }
        expect(isIdentityPerm(p), isTrue);
        if (orderOf(a) > 1) {
          var q = identityPerm();
          for (var k = 0; k < orderOf(a) - 1; k++) {
            q = compose(q, a);
          }
          expect(isIdentityPerm(q), isFalse, reason: 'order must be minimal');
        }
      }
    });

    test('cycles account for every moved seat exactly once', () {
      for (var i = 0; i < 200; i++) {
        final a = sample();
        final seen = <int>{};
        for (final c in cyclesOf(a)) {
          expect(c.length, greaterThan(1));
          for (final x in c) {
            expect(seen.add(x), isTrue);
          }
        }
        expect(seen.toList()..sort(), supportOf(a));
        expect(supportOf(a).length + fixedOf(a).length, kBalls);
      }
    });
  });

  group('conjugation and commutators', () {
    final rnd = math.Random(11);
    final s = swapAt(kDefaultSwapIndex);
    List<int> sample() => randomWordPerm(rnd, kRight, s, 1 + rnd.nextInt(20));

    test('conjugation maps support exactly where it claims', () {
      for (var i = 0; i < 500; i++) {
        final m = sample(), x = sample();
        final c = conjugate(x, m);
        expect(supportOf(c), imageOfSeats(x, supportOf(m)),
            reason: 'supp(x m x^-1) must be x(supp m)');
        // the moved pieces are the same ones, relabelled by x
        for (final i in supportOf(m)) {
          expect(c[x[i]], x[m[i]]);
        }
      }
    });

    test('conjugation preserves cycle type and order', () {
      for (var i = 0; i < 300; i++) {
        final m = sample(), x = sample();
        final c = conjugate(x, m);
        expect(cycleType(c), cycleType(m));
        expect(orderOf(c), orderOf(m));
      }
    });

    test('x m x^-1 is literally: do x, do m, undo x', () {
      for (var i = 0; i < 300; i++) {
        final m = sample(), x = sample();
        final stepwise = compose(compose(x, m), inversePerm(x));
        expect(conjugate(x, m), stepwise);
      }
    });

    test('[a,b] is trivial exactly when a and b commute', () {
      for (var i = 0; i < 300; i++) {
        final a = sample(), b = sample();
        final k = commutator(a, b);
        expect(isIdentityPerm(k), compose(a, b) == compose(b, a) ||
            permEquals(compose(a, b), compose(b, a)));
        // and it is what its definition says
        expect(k, compose(compose(compose(a, b), inversePerm(a)), inversePerm(b)));
      }
    });
  });

  group('Word — the port of History', () {
    test('reduces and evaluates exactly as the C++ engine does', () {
      for (final fixtures in [
        (engineFixture1, kDefaultSwapIndex),
        (engineFixture21, kPlanarSwapIndex),
      ]) {
        final rows = fixtures.$1;
        final swap = swapAt(fixtures.$2);
        for (final row in rows) {
          final raw = row[0] as String;
          final wantNotation = row[1] as String;
          final wantPerm = (row[2] as List).cast<int>();
          final wantMoves = row[3] as int;
          final wantSteps = row[4] as int;

          final w = Word.parse(raw);
          expect(w.engineNotation, wantNotation, reason: 'notation for "$raw"');
          expect(w.permutation(swap: swap), wantPerm, reason: 'perm for "$raw"');
          expect(w.moves, wantMoves, reason: 'moves for "$raw"');
          expect(w.steps(), wantSteps, reason: 'steps for "$raw"');
        }
      }
    });

    test('a word composes the same as applying its moves one at a time', () {
      final swap = swapAt(kDefaultSwapIndex);
      final rnd = math.Random(3);
      final rightInv = inversePerm(kRight);
      for (var t = 0; t < 300; t++) {
        final w = Word.empty();
        var expected = identityPerm();
        for (var i = 0; i < 1 + rnd.nextInt(12); i++) {
          final k = rnd.nextInt(3);
          if (k == 2) {
            w.push(0);
            expected = compose(expected, swap);
          } else {
            final n = 1 + rnd.nextInt(11);
            final unit = k == 0 ? 1 : -1;
            for (var j = 0; j < n; j++) {
              w.push(unit);
              expected = compose(expected, unit > 0 ? kRight : rightInv);
            }
          }
        }
        expect(w.permutation(swap: swap), expected);
        // and the reduced word's primitive steps replay to the same element
        var byStep = identityPerm();
        for (final e in w.primitiveSteps()) {
          byStep = compose(byStep,
              e == 0 ? swap : (e > 0 ? kRight : rightInv));
        }
        expect(byStep, expected, reason: 'primitiveSteps must be faithful');
      }
    });

    // Regression: primitiveSteps used to fall through to the raw element for a
    // macro letter, so a word containing A handed 65 to the caller, and every
    // caller feeds a positive element to right(), where the engine reduces it
    // modulo the ring — right(65) is R10. A booklet QR of "#word=A" spun the
    // ring ten wedges. The two halves also disagreed: permutation() skipped the
    // letter, so the same word analysed as the identity and played as R10.
    group('macro letters', () {
      final swap = swapAt(kDefaultSwapIndex);
      final macros = {kMacroA: Word.parse('RS'), kMacroA + 1: Word.parse('L2S')};

      test('a letter never leaks out as a rotation', () {
        for (final src in ['A', 'a', 'B', 'RAS', 'A^-1B']) {
          final steps = Word.parse(src).primitiveSteps(macros: macros);
          for (final e in steps) {
            expect(e, inInclusiveRange(-1, 1),
                reason: '"$src" emitted $e — a raw macro code, not a move');
          }
        }
      });

      test('an expanded letter plays the element it analyses as', () {
        for (final src in ['A', 'a', 'B', 'RAS', 'A^-1B', 'ABab']) {
          final w = Word.parse(src);
          var byStep = identityPerm();
          for (final e in w.primitiveSteps(macros: macros)) {
            byStep = compose(byStep, e == 0 ? swap : (e > 0 ? kRight : inversePerm(kRight)));
          }
          expect(byStep, w.permutation(swap: swap, macros: macros),
              reason: 'play and analysis must agree for "$src"');
        }
      });

      test('an unresolved letter is dropped, matching permutation()', () {
        final w = Word.parse('RAS');
        expect(w.primitiveSteps(), [1, 0]);
        expect(w.permutation(swap: swap), Word.parse('RS').permutation(swap: swap));
      });

      test('a cyclic definition terminates instead of hanging', () {
        final cyclic = {kMacroA: Word.parse('RB'), kMacroA + 1: Word.parse('SA')};
        expect(Word.parse('A').primitiveSteps(macros: cyclic).length,
            lessThan(64));
        expect(() => Word.parse('A').expanded(cyclic), returnsNormally);
      });

      test('steps() charges a macro its real cost when the map is given', () {
        final w = Word.of([kMacroA, 1, 0]); // A R S
        expect(w.steps(), 3, reason: 'no map: a letter is charged 1');
        expect(w.steps(macros: macros), 4, reason: 'A is "RS", worth 2');
      });
    });

    test('inverting a word inverts its element', () {
      final swap = swapAt(kDefaultSwapIndex);
      final rnd = math.Random(5);
      for (var t = 0; t < 200; t++) {
        final w = Word.of(List.generate(
            1 + rnd.nextInt(10), (_) => rnd.nextBool() ? 0 : 1 + rnd.nextInt(10)));
        final p = w.permutation(swap: swap);
        expect(w.inverted().permutation(swap: swap), inversePerm(p));
        expect(w.times(w.inverted()).isEmpty, isTrue,
            reason: 'a word times its own inverse must cancel away entirely');
      }
    });

    test('composing words composes their elements', () {
      final swap = swapAt(kDefaultSwapIndex);
      final rnd = math.Random(9);
      for (var t = 0; t < 300; t++) {
        Word gen() => Word.of(
            List.generate(1 + rnd.nextInt(8), (_) => rnd.nextBool() ? 0 : 1 + rnd.nextInt(10)));
        final a = gen(), b = gen();
        expect(a.times(b).permutation(swap: swap),
            compose(a.permutation(swap: swap), b.permutation(swap: swap)));
      }
    });

    test('parses every notation the app can hand it', () {
      expect(Word.parse('R S R S ').compact, 'RSRS');
      expect(Word.parse('RSRS').compact, 'RSRS');
      expect(Word.parse('L2 S R3').compact, 'L2SR3');
      expect(Word.parse('r s r s').compact, 'RSRS');
      expect(Word.parse('SS').isEmpty, isTrue, reason: 'two swaps cancel');
      expect(Word.parse('R11').isEmpty, isTrue, reason: 'a full turn is nothing');
      expect(Word.parse('R6R6').compact, 'R', reason: '12 wedges wraps to one');
      expect(Word.parse('A').elements, [kMacroA]);
      expect(Word.parse('a').elements, [-kMacroA]);
      expect(Word.parse('A^-1').elements, [-kMacroA]);
      expect(Word.parse('A⁻¹').elements, [-kMacroA]);
      expect(Word.parse('Aa').isEmpty, isTrue, reason: 'a macro cancels its inverse');
      expect(Word.parse(null).isEmpty, isTrue);
      // Junk is skipped character by character rather than rejected — but note
      // that a..e and A..E ARE the macro letters, so "nonsense" is not junk: it
      // reads as S e⁻¹ S e⁻¹. Callers that accept free text (the deep link)
      // validate the shape first; see DeepLinkRequest._wordish.
      expect(Word.parse('!!?? ##').isEmpty, isTrue);
      expect(Word.parse('nonsense').compact, 'SeSe');
    });

    test('a full turn pushed as one element is nothing, but a macro is not', () {
      // History::_step cancels the eleventh unit as it lands, so right(11)
      // leaves an empty history; push() has to reach the same answer when the
      // run arrives as a single element. The second half of this guards a bug
      // that reduction caused: 'A' is 65, and 65 mod 11 is 10, so an unguarded
      // reduction quietly turned macro A into a ten-wedge spin.
      expect(Word.of([11]).isEmpty, isTrue);
      expect(Word.of([-11]).isEmpty, isTrue);
      expect(Word.of([13]).compact, 'R2');
      for (final code in kMacroSlotsForTest) {
        expect(Word.of([code]).elements, [code]);
        expect(Word.of([-code]).elements, [-code]);
      }
      expect(Word.of([0]).elements, [0], reason: 'the swap is element 0');
    });

    test('macro letters expand to their bodies', () {
      final swap = swapAt(kDefaultSwapIndex);
      final macros = {kMacroA: Word.parse('RSRS')};
      final w = Word.parse('R2AL');
      expect(w.expanded(macros).compact, 'R2RSRSL'.replaceFirst('R2R', 'R3'));
      expect(w.permutation(swap: swap, macros: macros),
          Word.parse('R3SRSL').permutation(swap: swap));
      // inverse macro expands to the reversed, negated body
      expect(Word.parse('a').expanded(macros).compact,
          Word.parse('RSRS').inverted().compact);
    });
  });

  group('rank', () {
    test('reproduces the rank column of perms.lst for all 95,040 rows', () {
      final f = File('$_permDir/perms.lst');
      expect(f.existsSync(), isTrue, reason: 'the golden table must be present');
      var rows = 0;
      for (final line in f.readAsLinesSync()) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        final want = int.parse(parts[0]);
        final perm = parts.sublist(3, 3 + kBalls).map(int.parse).toList();
        expect(m12Rank(perm), want, reason: 'rank of $perm');
        rows++;
      }
      expect(rows, kM12Order);
    });
  });

  group('the BFS table', () {
    late M12Table t1;

    setUpAll(() {
      t1 = M12Table.buildSync(kDefaultSwapIndex, swapAt(kDefaultSwapIndex));
    });

    test('reaches all 95,040 elements — so the rank hash is injective', () {
      var reached = 0;
      for (var r = 0; r < kM12Order; r++) {
        if (t1.dist[r] != 255) reached++;
      }
      expect(reached, kM12Order);
    });

    test('reproduces the move count of perms.lst for all 95,040 rows', () {
      final f = File('$_permDir/perms.lst');
      var rows = 0;
      for (final line in f.readAsLinesSync()) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        final rank = int.parse(parts[0]);
        final moves = int.parse(parts[1]);
        expect(t1.dist[rank], moves, reason: 'distance at rank $rank');
        rows++;
      }
      expect(rows, kM12Order);
    });

    test('diameter is swap-dependent: 11 under #1, 12 under #21', () {
      expect(t1.diameter, 11);
      final t21 = M12Table.buildSync(kPlanarSwapIndex, swapAt(kPlanarSwapIndex));
      expect(t21.diameter, 12);
    });

    test('every stored word really produces its element, at its distance', () {
      final rnd = math.Random(21);
      for (var i = 0; i < 400; i++) {
        final r = rnd.nextInt(kM12Order);
        final p = t1.permAt(r);
        final w = t1.wordTo(r);
        expect(w.permutation(swap: t1.swap), p, reason: 'word for rank $r');
        expect(w.moves, t1.dist[r], reason: 'word for rank $r must be shortest');
      }
    });

    test('the solver walks any position home in exactly dist moves', () {
      final rnd = math.Random(33);
      for (var i = 0; i < 200; i++) {
        var p = t1.permAt(rnd.nextInt(kM12Order));
        final want = t1.distanceOf(p);
        var taken = 0;
        while (!isIdentityPerm(p)) {
          final mi = t1.nextMoveHome(p);
          expect(mi, isNotNull);
          final g = t1.generators[mi!];
          p = List<int>.generate(kBalls, (i) => p[g[i]]);
          taken++;
          expect(taken, lessThanOrEqualTo(t1.diameter));
        }
        expect(taken, want);
      }
    });

    test('solutionFrom takes the current position home', () {
      final rnd = math.Random(44);
      for (var i = 0; i < 200; i++) {
        final p = t1.permAt(rnd.nextInt(kM12Order));
        final sol = t1.solutionFrom(p);
        expect(compose(p, sol.permutation(swap: t1.swap)), identityPerm());
      }
    });
  });

  group('what the tutorial claims', () {
    late M12Table t1;
    late Discovery d1;

    setUpAll(() {
      t1 = M12Table.buildSync(kDefaultSwapIndex, swapAt(kDefaultSwapIndex));
      d1 = discoverSync(t1);
    });

    test('no element of M12 disturbs fewer than 8 seats — there are no 3-cycles',
        () {
      expect(d1.supportCensus, {
        0: 1,
        8: 3465,
        9: 1760,
        10: 21384,
        11: 33120,
        12: 35310,
      });
      expect(d1.minimumSupport, kMinimumSupport);
      for (final e in d1.entries) {
        expect(e.type.where((l) => l == 3).length == 1 && e.type.length == 1,
            isFalse,
            reason: 'a bare 3-cycle would be an element of support 3');
      }
    });

    test('the cheapest small-support words differ by swap — nothing is constant',
        () {
      DiscoveryEntry pick(Discovery d, List<int> type) =>
          d.entries.firstWhere((e) => e.type.join(',') == type.join(','));

      expect(pick(d1, [3, 3, 3]).moves, 4);
      expect(pick(d1, [3, 3, 3]).word.compact, 'RSRS');
      expect(pick(d1, [4, 4]).moves, 4);
      expect(pick(d1, [2, 2, 2, 2]).moves, 6);

      final d21 = discoverSync(
          M12Table.buildSync(kPlanarSwapIndex, swapAt(kPlanarSwapIndex)));
      expect(pick(d21, [4, 4]).moves, 2, reason: 'under #21 a 4+4 costs two moves');
      expect(pick(d21, [4, 4]).word.compact, 'RS');
      expect(pick(d21, [2, 2, 2, 2]).moves, 4);
      expect(pick(d21, [3, 3, 3]).moves, 4);
      expect(pick(d21, [3, 3, 3]).word.compact, isNot('RSRS'),
          reason: 'RSRS is a 2+2+2+2 under #21, not a 3+3+3');
    });

    test('every discovered representative is what it says it is', () {
      for (final e in d1.entries) {
        expect(e.word.permutation(swap: t1.swap), e.perm);
        expect(e.word.moves, e.moves);
        expect(supportOf(e.perm).length, e.supportSize);
        expect(cycleType(e.perm), e.type);
      }
      expect(d1.entries.fold<int>(0, (a, e) => a + e.population), kM12Order);
    });

    test('the shortlist is the teachable classes, without the identity', () {
      expect(d1.shortlist.map((e) => '${e.supportSize}:${e.typeLabel}').toList(),
          ['8:4+4', '8:2+2+2+2', '9:3+3+3']);
    });

    test('a setup word always exists — for every one of the 220 triples', () {
      final triple = d1.entries.firstWhere((e) => e.type.join() == '333');
      final m = triple.perm;
      var worst = 0;
      var total = 0;
      var n = 0;
      for (var a = 0; a < kBalls; a++) {
        for (var b = a + 1; b < kBalls; b++) {
          for (var c = b + 1; c < kBalls; c++) {
            // aim the macro so that exactly {a,b,c} are left alone
            final target = <int>{
              for (var i = 0; i < kBalls; i++)
                if (i != a && i != b && i != c) i
            };
            final r = findConjugationSync(t1, m, target, macroWord: triple.word);
            expect(r, isNotNull, reason: 'no setup word for fixing $a,$b,$c');
            expect(supportOf(r!.resultPerm).toSet(), target,
                reason: 'the conjugate must move exactly the targeted seats');
            expect(fixedOf(r.resultPerm), [a, b, c]);
            // and the full word really performs it
            expect(r.fullWord.permutation(swap: t1.swap), r.resultPerm);
            expect(cycleType(r.resultPerm), [3, 3, 3]);
            worst = math.max(worst, r.setup.moves);
            total += r.setup.moves;
            n++;
          }
        }
      }
      expect(n, 220);
      expect(worst, lessThanOrEqualTo(6));
      expect(total / n, lessThan(5));
    });
  });

  // The app never calls buildSync: on mobile and desktop it hands the work to
  // an isolate via compute(), which has to serialise a ~1.3 MB table there and
  // back. That the object survives the trip is not obvious, and it is the only
  // path real users take, so check it rather than only the synchronous one.
  group('the off-thread path the app actually uses', () {
    test('a table built through compute() is the same table', () async {
      final want = M12Table.buildSync(kDefaultSwapIndex, swapAt(kDefaultSwapIndex));
      final got = await M12Table.build(kDefaultSwapIndex, swapAt(kDefaultSwapIndex));
      expect(got.swapIndex, want.swapIndex);
      expect(got.swap, want.swap);
      expect(got.diameter, want.diameter);
      expect(got.dist, want.dist);
      expect(got.prevMove, want.prevMove);
      expect(got.perms, want.perms);
      // and it is still usable on this side of the wire
      expect(got.wordTo(12345).permutation(swap: got.swap), got.permAt(12345));
    });

    test('a discovery run through compute() survives the trip', () async {
      final t = M12Table.buildSync(kDefaultSwapIndex, swapAt(kDefaultSwapIndex));
      final got = await discover(t);
      expect(got.supportCensus, discoverSync(t).supportCensus);
      expect(got.shortlist.map((e) => e.word.compact).toList(),
          ['SRSL2', 'L4SL3SL5S', 'RSRS']);
    });
  });

  group('analysis prose', () {
    late M12Table t1;
    setUpAll(() {
      t1 = M12Table.buildSync(kDefaultSwapIndex, swapAt(kDefaultSwapIndex));
    });

    test('describes RSRS correctly and with no invented numbers', () {
      final w = Word.parse('RSRS');
      final p = w.permutation(swap: swapAt(kDefaultSwapIndex));
      final a = MacroAnalysis.of(p, word: w, table: t1);
      expect(a.type, [3, 3, 3]);
      expect(a.isTripleThreeCycle, isTrue);
      expect(a.order, 3);
      expect(a.support.length, 9);
      expect(a.fixed, [2, 5, 9]);
      expect(a.distance, 4);
      expect(a.cycleNotation, '(0 6 3)(1 11 8)(4 10 7)');
      expect(a.plainEnglish, contains('Three 3-cycles'));
      expect(a.plainEnglish, contains('seats 2, 5 and 9'));
      expect(a.plainEnglish, contains('Repeat it 3 times'));
      expect(a.plainEnglish, contains('4 moves'));
    });

    test('the identity is described as doing nothing', () {
      final a = MacroAnalysis.of(identityPerm(), table: t1);
      expect(a.isIdentity, isTrue);
      expect(a.distance, 0);
      expect(a.plainEnglish, contains('nothing at all'));
    });
  });
}
