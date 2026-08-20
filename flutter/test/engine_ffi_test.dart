// The Dart↔C++ contract, exercised against the real engine.
//
// Everything else in test/ checks the Dart port in isolation. This checks that
// the port and the engine agree, through the very bindings the app ships —
// including the three entry points added for the tutorial and the scramble fix
// they depend on.
//
// Skipped unless the engine has been built as a shared library:
//
//   ./tool/build_native_test_lib.sh
//   MATHIEU_ENGINE_LIB="$PWD/build/native-test/libmathieu_engine.dylib" flutter test
//
// (The app targets link the engine into the app binary, so a standalone Dart VM
// has nothing to look in — hence the opt-in.)

@TestOn('vm')
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/m12/analysis.dart';
import 'package:mathieu/m12/perm.dart';
import 'package:mathieu/m12/rank.dart';
import 'package:mathieu/m12/table.dart';
import 'package:mathieu/m12/word.dart';
import 'package:mathieu/mathieu_ffi.dart';

final _libPath = Platform.environment['MATHIEU_ENGINE_LIB'] ?? '';
final _haveEngine = _libPath.isNotEmpty && File(_libPath).existsSync();
final _why = _haveEngine
    ? null
    : 'engine not built — run tool/build_native_test_lib.sh and set '
        'MATHIEU_ENGINE_LIB';

/// A word built the way the app builds them: one primitive move at a time,
/// through the same reduction History::_step performs.
Word randomWord(math.Random rnd, int maxMoves) {
  final w = Word.empty();
  for (var i = 0; i < 1 + rnd.nextInt(maxMoves); i++) {
    if (rnd.nextBool()) {
      w.push(0);
    } else {
      final n = 1 + rnd.nextInt(11);
      final unit = rnd.nextBool() ? 1 : -1;
      for (var k = 0; k < n; k++) {
        w.push(unit);
      }
    }
  }
  return w;
}

/// Replay a word through the engine, one primitive move at a time.
void play(MathieuEngine g, Word w) {
  for (final e in w.primitiveSteps()) {
    if (e == 0) {
      g.swap();
    } else if (e > 0) {
      g.right(e);
    } else {
      g.left(-e);
    }
  }
}

void main() {
  group('engine ↔ Dart', () {
    late List<int> swap;

    setUpAll(() {
      if (!_haveEngine) return;
      MathieuEngine.swapIndex = 1;
      swap = MathieuEngine.swapPermutation(kBalls);
    });

    test('the generators are the ones the Dart layer assumes', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      g.reset();
      g.right();
      expect(g.arrangement(), kRight, reason: 'kRight must be the engine\'s R');
      g.reset();
      g.swap();
      expect(g.arrangement(), swap);
      g.reset();
      g.left();
      expect(g.arrangement(), inversePerm(kRight));
    });

    test('a word evaluated in Dart equals the engine playing it', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      final rnd = math.Random(101);
      for (var i = 0; i < 300; i++) {
        final w = randomWord(rnd, 10);
        g.reset();
        play(g, w);
        expect(g.arrangement(), w.permutation(swap: swap), reason: w.compact);
        expect(Word.parse(g.historyStr()).compact, w.compact,
            reason: 'the engine must reduce the word the same way');
        expect(g.moves, w.moves);
        expect(g.steps, w.steps());
      }
    });

    test('a macro set from home means exactly the word played', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      g.reset();
      play(g, Word.parse('RSRS'));
      g.setMacro(kMacroA);
      expect(g.macroPermutation(kMacroA), Word.parse('RSRS').permutation(swap: swap));
      expect(Word.parse(g.macroWord(kMacroA)).compact, 'RSRS');
    });

    // The regression this release exists for. Before the fix, a macro defined
    // part-way through a scramble stored start·W while its word said only W —
    // so run_macro re-applied the scramble and every analysis was about the
    // wrong element.
    test('a macro set MID-SCRAMBLE still means only the moves you played', () {
      final rnd = math.Random(7);
      for (var trial = 0; trial < 40; trial++) {
        final g = MathieuEngine();
        g.random();
        final start = g.start();
        expect(start, g.arrangement(),
            reason: 'random() leaves the history empty, so start IS the position');

        final w = randomWord(rnd, 8);
        if (w.isEmpty) {
          // An empty history means "erase", not "define" — nothing to check.
          g.dispose();
          continue;
        }
        play(g, w);
        final contaminated = compose(start, w.permutation(swap: swap));
        expect(g.arrangement(), contaminated,
            reason: 'the board really is scramble·word');

        g.setMacro(kMacroB());
        expect(g.macroPermutation(kMacroB()), w.permutation(swap: swap),
            reason: 'the macro must be the word, NOT scramble·word');
        expect(g.macroPermutation(kMacroB()), isNot(contaminated));
        expect(Word.parse(g.macroWord(kMacroB())).compact, w.compact);
        g.dispose();
      }
    });

    test('running a macro applies its permutation, and its inverse undoes it', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      final rnd = math.Random(13);
      for (var i = 0; i < 50; i++) {
        g.reset();
        final w = randomWord(rnd, 6);
        if (w.isEmpty) continue;
        play(g, w);
        g.setMacro(kMacroA);
        g.reset();
        g.runMacro(kMacroA);
        expect(g.arrangement(), w.permutation(swap: swap));
        g.runMacro(kMacroA, inverted: true);
        expect(g.arrangement(), identityPerm());
        expect(g.isSolved, isTrue);
      }
    });

    test('setMacroFrom binds a word without touching the live history', () {
      final g = MathieuEngine();
      final scratch = MathieuEngine();
      addTearDown(g.dispose);
      addTearDown(scratch.dispose);

      g.reset();
      play(g, Word.parse('L3S'));
      final beforeHistory = g.historyStr();
      final beforeArr = g.arrangement();

      final target = Word.parse('RSRS');
      scratch.reset();
      play(scratch, target);
      g.setMacroFrom(kMacroC(), scratch);

      expect(g.historyStr(), beforeHistory, reason: 'binding is not a move');
      expect(g.arrangement(), beforeArr);
      expect(g.macroPermutation(kMacroC()), target.permutation(swap: swap));
      expect(Word.parse(g.macroWord(kMacroC())).compact, 'RSRS');
    });

    test('an undefined macro reads back as null and an empty word', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      g.reset();
      expect(g.macroDefined(kMacroE), isFalse);
      expect(g.macroPermutation(kMacroE), isNull);
      expect(g.macroWord(kMacroE).trim(), isEmpty);
    });

    test('setPosition puts the board exactly where the table says', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      final t = M12Table.buildSync(MathieuEngine.swapIndex, swap);
      final rnd = math.Random(5);
      for (var i = 0; i < 100; i++) {
        final rank = rnd.nextInt(kM12Order);
        final p = t.permAt(rank);
        expect(g.setPosition(p), isTrue);
        expect(g.arrangement(), p);
        expect(g.historyLength, 0, reason: 'a fresh position starts a fresh solve');
        expect(g.start(), p);
        // and the table's own solution really solves it
        play(g, t.solutionFrom(p));
        expect(g.isSolved, isTrue);
        expect(g.moves, t.dist[rank], reason: 'and in the promised number of moves');
      }
    });

    test('setPosition refuses anything that is not a permutation', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      g.reset();
      expect(g.setPosition(List<int>.filled(kBalls, 0)), isFalse);
      expect(g.setPosition([for (var i = 0; i < kBalls; i++) i]..[3] = 99), isFalse);
      expect(g.arrangement(), identityPerm(), reason: 'a refusal changes nothing');
    });

    test('setPosition keeps macro definitions', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      g.reset();
      play(g, Word.parse('RSRS'));
      g.setMacro(kMacroA);
      g.setPosition(Word.parse('L4S').permutation(swap: swap));
      expect(g.macroDefined(kMacroA), isTrue);
      expect(Word.parse(g.macroWord(kMacroA)).compact, 'RSRS');
    });

    test('the history buffer no longer truncates a long session', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      g.reset();
      // 200 alternating moves; the old 256-byte cap cut this off.
      for (var i = 0; i < 100; i++) {
        g.right(1 + (i % 9));
        g.swap();
      }
      final s = g.historyStr();
      expect(s.length, greaterThan(256));
      expect(Word.parse(s).moves, g.moves,
          reason: 'a truncated string would parse to fewer moves');
    });

    test('erase_all_macros with a live reference does not crash steps()', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      g.reset();
      play(g, Word.parse('RS'));
      g.setMacro(kMacroA);
      g.runMacro(kMacroA);
      g.eraseAllMacros();
      expect(() => g.steps, returnsNormally);
    });

    test('the analysis the app shows matches what the engine will do', () {
      final g = MathieuEngine();
      addTearDown(g.dispose);
      final t = M12Table.buildSync(MathieuEngine.swapIndex, swap);
      g.random();
      play(g, Word.parse('RSRS'));
      g.setMacro(kMacroA);

      // What the macro sheet computes: start^-1 * current.
      final shown = compose(inversePerm(g.start()), g.arrangement());
      final fromEngine = g.macroPermutation(kMacroA)!;
      expect(shown, fromEngine);

      final a = MacroAnalysis.of(fromEngine,
          word: Word.parse(g.macroWord(kMacroA)), table: t);
      expect(a.type, [3, 3, 3]);
      expect(a.distance, 4);

      // And running it from home lands on precisely that element.
      g.reset();
      g.runMacro(kMacroA);
      expect(g.arrangement(), fromEngine);
    });
  }, skip: _why);
}

int kMacroB() => kMacroA + 1;
int kMacroC() => kMacroA + 2;
