// Words in the generators, modelled exactly on the engine's History.
//
// An element of a word is a signed int, using the engine's encoding (m.h:191):
//     -11 .. -1   a left run of that many wedges
//       0         the swap
//      +1 .. +11  a right run
//      65 .. 69   macro A..E          (negative: its inverse)
//
// Word arithmetic reproduces History::operator*= (m.h:395-433) and _step
// (m.h:497-516) — adjacent runs merge, a full turn vanishes, two swaps cancel,
// and a macro next to its own inverse cancels. Getting this identical matters:
// the app shows the cancellation happening as a teaching moment, so it had
// better be the same cancellation the engine performs.

import 'perm.dart';

/// The right generator: an 11-cycle fixing seat 0 (m12.cc:34).
const List<int> kRight = [0, 11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

const int kSwapElement = 0;
const int kMacroA = 65; // 'A'
const int kMacroE = 69; // 'E'

bool isLeftElement(int e) => e >= -(kBalls - 1) && e <= -1;
bool isRightElement(int e) => e >= 1 && e <= kBalls - 1;
bool isRunElement(int e) => isLeftElement(e) || isRightElement(e);
bool isSwapElement(int e) => e == 0;
bool isMacroElement(int e) => e.abs() >= kMacroA && e.abs() <= kMacroE;

/// How deep macro-in-macro expansion may go before we call it a cycle. There
/// are only five slots, so five is the deepest honest chain (A→B→C→D→E); the
/// headroom is there so the guard never fires on a legitimate word.
const int _maxMacroDepth = 8;

/// A word: a sequence of history elements, kept in the engine's reduced form.
class Word {
  final List<int> elements;

  const Word(this.elements);

  Word.empty() : elements = <int>[];

  factory Word.of(Iterable<int> es) {
    final w = Word.empty();
    for (final e in es) {
      w.push(e);
    }
    return w;
  }

  bool get isEmpty => elements.isEmpty;
  bool get isNotEmpty => elements.isNotEmpty;

  /// One history entry per element, like the engine's moves().
  int get moves => elements.length;

  /// Primitive quarter-turns and swaps, like the engine's steps() — a run
  /// longer than half the ring is charged the short way round.
  int steps({Map<int, Word>? macros}) {
    var total = 0;
    for (final e in elements) {
      if (isRunElement(e)) {
        const half = (kBalls - 2) ~/ 2; // 5
        if (e < -half) {
          total += e + (kBalls - 1);
        } else if (e > half) {
          total += (kBalls - 1) - e;
        } else {
          total += e.abs();
        }
      } else if (isSwapElement(e)) {
        total += 1;
      } else {
        final m = macros?[e.abs()];
        total += m == null ? 1 : m.steps(macros: macros);
      }
    }
    return total;
  }

  /// Append one element with the engine's merge/cancel rules.
  void push(int rawElement) {
    var e = rawElement;
    // A whole turn is nothing at all. The engine reaches the same conclusion by
    // a different road — History::_step cancels as the eleventh unit lands, so
    // right(11) leaves an empty history — but History::operator*= is only ever
    // handed elements that are already reduced, so it has no such guard. Doing
    // it here keeps the two roads agreeing whichever way a word is built.
    // Runs only: a swap is 0 and a macro is 'A'..'E', neither of which may be
    // reduced modulo the ring (65 mod 11 would silently become a rotation).
    if (!isSwapElement(e) && !isMacroElement(e)) {
      e = e.remainder(kBalls - 1);
      if (e == 0) return;
    }
    if (elements.isEmpty) {
      elements.add(e);
      return;
    }
    final back = elements.last;
    if (isRunElement(back)) {
      if (!isRunElement(e)) {
        elements.add(e);
        return;
      }
      var merged = back + e;
      if (merged == -(kBalls - 1) || merged == 0 || merged == kBalls - 1) {
        elements.removeLast();
        return;
      }
      if (merged < -(kBalls - 1)) {
        merged += kBalls - 1;
      } else if (merged > kBalls - 1) {
        merged -= kBalls - 1;
      }
      elements[elements.length - 1] = merged;
      return;
    }
    // back is a swap or a macro
    if (isRunElement(e)) {
      elements.add(e);
    } else if (-e == back) {
      elements.removeLast();
    } else {
      elements.add(e);
    }
  }

  /// this · other.
  Word times(Word other) {
    final w = Word.of(elements);
    for (final e in other.elements) {
      w.push(e);
    }
    return w;
  }

  /// this · other⁻¹.
  Word dividedBy(Word other) => times(other.inverted());

  /// Reverse the word and negate every element (History::invert, m.h:377-393).
  Word inverted() => Word.of(elements.reversed.map((e) => -e));

  /// The group element this word applies, given the generators.
  ///
  /// [macros] resolves macro letters; an unresolved letter is skipped rather
  /// than throwing, so a stale library entry can still be displayed.
  List<int> permutation({
    required List<int> swap,
    List<int> right = kRight,
    Map<int, Word>? macros,
  }) {
    final rightInv = inversePerm(right);
    var p = identityPerm(right.length);
    for (final e in elements) {
      if (isRunElement(e)) {
        final g = e > 0 ? right : rightInv;
        for (var i = 0; i < e.abs(); i++) {
          p = compose(p, g);
        }
      } else if (isSwapElement(e)) {
        p = compose(p, swap);
      } else {
        final m = macros?[e.abs()];
        if (m == null) continue;
        final mp = m.permutation(swap: swap, right: right, macros: macros);
        p = compose(p, e > 0 ? mp : inversePerm(mp));
      }
    }
    return p;
  }

  /// Expand macro letters into their primitive runs and swaps.
  ///
  /// An unresolved letter is dropped, matching [permutation] and
  /// [primitiveSteps]; [depth] guards against a cyclic definition the same way.
  Word expanded(Map<int, Word> macros, {int depth = 0}) {
    final out = Word.empty();
    for (final e in elements) {
      if (isMacroElement(e)) {
        final m = depth >= _maxMacroDepth ? null : macros[e.abs()];
        if (m == null) continue;
        final inner = m.expanded(macros, depth: depth + 1);
        final body = e > 0 ? inner : inner.inverted();
        for (final x in body.elements) {
          out.push(x);
        }
      } else {
        out.push(e);
      }
    }
    return out;
  }

  /// One primitive move per entry: L, R and S only, runs unrolled in the
  /// direction the word actually names. This is what the step-through replay
  /// and every "play this word" path drive the engine with, so replaying a word
  /// reproduces that word in the engine's history, letter for letter.
  ///
  /// Note this can be longer than [steps]: the engine charges a run the short
  /// way round (R8 costs 3, m.h:470-490) while the word still says R8, and
  /// replaying it as three lefts would be a different thing to watch. Words
  /// from the table never contain a run longer than 5 either way.
  ///
  /// A macro letter is expanded through [macros] into the moves it stands for.
  /// An unresolved letter contributes NOTHING, exactly as [permutation] treats
  /// it — the two must agree, or a word would analyse as one element and play
  /// as another.
  ///
  /// It must never fall through to the raw element. A macro code is 65..69 and
  /// every caller feeds a positive element to `right(e)`, where the engine
  /// reduces it modulo the ring: `right(65)` is R10. A booklet QR of `#word=A`
  /// used to spin the ring ten wedges and call it a macro.
  List<int> primitiveSteps({Map<int, Word>? macros, int depth = 0}) {
    final out = <int>[];
    for (final e in elements) {
      if (isRunElement(e)) {
        final unit = e < 0 ? -1 : 1;
        for (var i = 0; i < e.abs(); i++) {
          out.add(unit);
        }
      } else if (isSwapElement(e)) {
        out.add(e);
      } else {
        // Depth guard: the engine expands self-references when a macro is
        // defined, so a cycle should be unreachable — but this runs on the UI
        // thread from a deep link, and a hand-edited prefs file is not the
        // engine. Bail rather than hang.
        final m = depth >= _maxMacroDepth ? null : macros?[e.abs()];
        if (m == null) continue;
        final body = e > 0 ? m : m.inverted();
        out.addAll(body.primitiveSteps(macros: macros, depth: depth + 1));
      }
    }
    return out;
  }

  /// The engine's own notation: "R S R S ", "L2 S R3 A ".
  /// Inverse macros are lowercase, exactly as mathieu_history_str writes them.
  String get engineNotation {
    final sb = StringBuffer();
    for (final e in elements) {
      if (isSwapElement(e)) {
        sb.write('S');
      } else if (isRunElement(e)) {
        sb.write(e < 0 ? 'L' : 'R');
        final n = e.abs();
        if (n > 1) sb.write(n);
      } else if (e < 0) {
        sb.writeCharCode(-e + 0x20); // A..E -> a..e
      } else {
        sb.writeCharCode(e);
      }
      sb.write(' ');
    }
    return sb.toString();
  }

  /// Compact, no trailing space — what the library stores and the UI shows.
  String get compact => engineNotation.trim().replaceAll(' ', '');

  /// Display form: inverse macros as A⁻¹ rather than a lowercase letter.
  String get display {
    if (isEmpty) return '(nothing)';
    final sb = StringBuffer();
    for (final e in elements) {
      if (sb.isNotEmpty) sb.write(' ');
      if (isSwapElement(e)) {
        sb.write('S');
      } else if (isRunElement(e)) {
        sb.write(e < 0 ? 'L' : 'R');
        final n = e.abs();
        if (n > 1) sb.write(n);
      } else {
        sb.writeCharCode(e.abs());
        if (e < 0) sb.write('⁻¹');
      }
    }
    return sb.toString();
  }

  /// Parse the engine's notation or a bare word: "R S R S", "RSRS", "L2SR3A",
  /// "a" or "A^-1" / "A⁻¹" for an inverse macro. Unrecognised characters are
  /// skipped — a deep link or a hand-typed word must never throw.
  static Word parse(String? source) {
    final w = Word.empty();
    if (source == null) return w;
    final s = source.replaceAll('⁻¹', '^-1');
    var i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (ch == ' ' || ch == '\t' || ch == ',') {
        i++;
        continue;
      }
      final up = ch.toUpperCase();
      if (up == 'S') {
        w.push(kSwapElement);
        i++;
        continue;
      }
      if (up == 'L' || up == 'R') {
        i++;
        var n = 0;
        while (i < s.length && _isDigit(s[i])) {
          n = n * 10 + int.parse(s[i]);
          i++;
        }
        if (n == 0) n = 1;
        // A run longer than the ring is reduced by push()'s own rules.
        final sign = up == 'L' ? -1 : 1;
        for (var k = 0; k < n; k++) {
          w.push(sign);
        }
        continue;
      }
      final code = up.codeUnitAt(0);
      if (code >= kMacroA && code <= kMacroE) {
        final lower = ch != up; // lowercase spelled the inverse
        i++;
        var inv = lower;
        if (!inv && s.startsWith('^-1', i)) {
          inv = true;
          i += 3;
        }
        w.push(inv ? -code : code);
        continue;
      }
      i++; // skip anything else
    }
    return w;
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

  @override
  String toString() => compact;
}
