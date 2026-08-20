// The library's own contract: it must round-trip, it must never let a corrupt
// store keep the app from starting, and it must keep a macro attached to the
// swap it was written under.

import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/m12/library.dart';
import 'package:mathieu/m12/perm.dart';
import 'package:mathieu/m12/table.dart';
import 'package:mathieu/m12/word.dart';

import 'm12_group_test.dart' show loadSwaps, kDefaultSwapIndex, kPlanarSwapIndex;

void main() {
  final swaps = loadSwaps();

  test('entries and bindings survive a round trip', () {
    final lib = MacroLibrary();
    final a = lib.add(name: 'Triple', word: Word.parse('RSRS'), swapIndex: 1);
    final b = lib.add(
        name: 'Pair', word: Word.parse('L2SR3'), swapIndex: 21, origin: 'by hand');
    lib.bind(kMacroA, a.id);
    lib.bind(kMacroE, b.id);

    final out = MacroLibrary()..decode(lib.encode());
    expect(out.entries.length, 2);
    expect(out.byId(a.id)!.name, 'Triple');
    expect(out.byId(a.id)!.word.compact, 'RSRS');
    expect(out.byId(a.id)!.swapIndex, 1);
    expect(out.byId(b.id)!.origin, 'by hand');
    expect(out.boundTo(kMacroA)!.id, a.id);
    expect(out.boundTo(kMacroE)!.id, b.id);
  });

  test('a corrupt or absent store yields an empty library, never a throw', () {
    for (final junk in [
      null,
      '',
      'not json',
      '[]',
      '{"entries": "nope"}',
      '{"entries": [{"id": 3}], "bindings": {"x": 1}}',
      '{"bindings": {"65": "no-such-entry"}}',
    ]) {
      final lib = MacroLibrary();
      expect(() => lib.decode(junk), returnsNormally, reason: 'input: $junk');
      expect(lib.entries, isEmpty);
      expect(lib.bindings, isEmpty);
    }
  });

  test('a binding pointing at a deleted entry is dropped, not resurrected', () {
    final lib = MacroLibrary();
    final e = lib.add(name: 'X', word: Word.parse('RS'), swapIndex: 1);
    lib.bind(kMacroA, e.id);
    lib.remove(e.id);
    expect(lib.bindings, isEmpty);
    expect(lib.boundTo(kMacroA), isNull);
  });

  test('an entry occupies at most one register', () {
    final lib = MacroLibrary();
    final e = lib.add(name: 'X', word: Word.parse('RS'), swapIndex: 1);
    lib.bind(kMacroA, e.id);
    lib.bind(kMacroA + 1, e.id);
    expect(lib.bindings.length, 1);
    expect(lib.slotOf(e.id), kMacroA + 1);
  });

  test('names are made unique so two macros never share one', () {
    final lib = MacroLibrary();
    lib.add(name: 'Triple', word: Word.parse('RS'), swapIndex: 1);
    lib.add(name: 'Triple', word: Word.parse('SR'), swapIndex: 1);
    lib.add(name: 'Triple', word: Word.parse('SS R'), swapIndex: 1);
    expect(lib.entries.map((e) => e.name).toSet().length, 3);
  });

  test('entries for the swap in force sort ahead of the rest', () {
    final lib = MacroLibrary();
    lib.add(name: 'other', word: Word.parse('RS'), swapIndex: 21);
    lib.add(name: 'mine', word: Word.parse('SR'), swapIndex: 1);
    expect(lib.sortedFor(1).first.name, 'mine');
    expect(lib.sortedFor(21).first.name, 'other');
  });

  test('re-deriving finds the cheapest same-shape move on the same seats', () {
    // A 3+3+3 written under swap #1, re-derived under swap #21.
    final lib = MacroLibrary();
    final old = lib.add(
        name: 'Triple', word: Word.parse('RSRS'), swapIndex: kDefaultSwapIndex);
    final oldSwap = swaps[kDefaultSwapIndex];
    final oldPerm = old.word.permutation(swap: oldSwap);
    expect(cycleType(oldPerm), [3, 3, 3]);

    final t21 = M12Table.buildSync(kPlanarSwapIndex, swaps[kPlanarSwapIndex]);
    final made = lib.rederive(old, t21, oldSwap);
    expect(made, isNotNull);

    final newPerm = made!.word.permutation(swap: swaps[kPlanarSwapIndex]);
    expect(cycleType(newPerm), cycleType(oldPerm),
        reason: 'same shape');
    expect(supportOf(newPerm), supportOf(oldPerm),
        reason: 'acting on the same seats');
    expect(made.swapIndex, kPlanarSwapIndex);

    // and it really is the cheapest such element under the new swap
    for (var r = 0; r < t21.dist.length; r++) {
      if (t21.dist[r] >= made.word.moves) continue;
      final p = t21.permAt(r);
      if (supportOf(p).join() == supportOf(oldPerm).join() &&
          cycleType(p).join() == cycleType(oldPerm).join()) {
        fail('rank $r is a cheaper re-derivation at ${t21.dist[r]} moves');
      }
    }
  });

  test('the same word is a different element under a different swap', () {
    final w = Word.parse('RSRS');
    final p1 = w.permutation(swap: swaps[kDefaultSwapIndex]);
    final p21 = w.permutation(swap: swaps[kPlanarSwapIndex]);
    expect(cycleType(p1), [3, 3, 3]);
    expect(cycleType(p21), [2, 2, 2, 2],
        reason: 'this is exactly why every entry records its swap');
  });
}
