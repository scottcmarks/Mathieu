// What the app can say about one group element that a mechanical toy cannot.
//
// The one fact the tutorial is built around, and which this file states rather
// than hides: M12 has NO element that disturbs fewer than eight seats. The
// support census over all 95,040 elements is
//
//     8 seats: 3465    9: 1760    10: 21384    11: 33120    12: 35310
//
// so there are no 3-cycles at all. The Rubik's-cube pedagogy of "build a
// 3-cycle and conjugate it around" has no analogue here; the nearest thing is a
// 3+3+3 on nine seats, or a 4+4 / 2+2+2+2 on eight. That absence is a lesson
// beat, not a missing feature — see kNoSmallSupportHeadline.

import 'perm.dart';
import 'table.dart';
import 'word.dart';

/// The smallest number of seats any non-identity element of M12 can disturb.
const int kMinimumSupport = 8;

const String kNoSmallSupportHeadline =
    'M₁₂ has no element that disturbs fewer than 8 seats — in particular there '
    'are no 3-cycles. The least you can stir is 8 seats (as 4+4 or 2+2+2+2), '
    'or 9 seats as 3+3+3.';

/// Everything the app knows about one element.
class MacroAnalysis {
  /// The group element itself: perm[seat] = the piece that ends up there.
  final List<int> perm;

  /// The word that produces it, if one is known.
  final Word? word;

  /// Shortest word length from home, from the table. Null if no table yet.
  final int? distance;

  /// What each macro key stands for, when [word] might name one. A macro key's
  /// stored word may itself contain a letter — you can define B while A was in
  /// play — and without this the cost read-out charges that letter one step
  /// instead of the however-many it really costs.
  final Map<int, Word>? macros;

  const MacroAnalysis({
    required this.perm,
    this.word,
    this.distance,
    this.macros,
  });

  factory MacroAnalysis.of(List<int> perm,
          {Word? word, M12Table? table, Map<int, Word>? macros}) =>
      MacroAnalysis(
        perm: perm,
        word: word,
        distance: table?.distanceOf(perm),
        macros: macros,
      );

  /// The word's cost in primitive moves, with macro letters charged what they
  /// actually cost. Null when there is no word to price.
  int? get steps => word?.steps(macros: macros);

  bool get isIdentity => isIdentityPerm(perm);
  List<List<int>> get cycles => cyclesOf(perm);
  List<int> get type => cycleType(perm);
  List<int> get support => supportOf(perm);
  List<int> get fixed => fixedOf(perm);
  int get order => orderOf(perm);
  String get cycleNotation => cyclesString(perm);
  String get typeLabel => cycleTypeString(perm);

  /// True for the shape the tutorial cares most about: three 3-cycles, nine
  /// seats moved, three left alone. The closest thing M12 has to a 3-cycle.
  bool get isTripleThreeCycle => type.length == 3 && type.every((l) => l == 3);

  /// A 4+4 or a 2+2+2+2 — the two minimum-support shapes, eight seats each.
  bool get isMinimumSupport => support.length == kMinimumSupport;

  /// One plain-English sentence about the element. No fake precision: every
  /// number in it is computed, and the distance clause is omitted when no table
  /// has been built.
  String get plainEnglish {
    if (isIdentity) {
      return 'This does nothing at all — every $_seat ends up where it started.';
    }
    final parts = <String>[];
    parts.add(_shapeSentence());
    final f = fixed;
    if (f.isEmpty) {
      parts.add('It touches all ${perm.length} seats.');
    } else {
      parts.add('It touches ${support.length} seats and leaves '
          '${_list(f)} alone.');
    }
    parts.add('Repeat it $order time${order == 1 ? '' : 's'} and you are back '
        'where you started.');
    if (distance != null) {
      parts.add(distance == 0
          ? 'It is the home position.'
          : 'The shortest way to reach it from home is $distance '
              'move${distance == 1 ? '' : 's'}.');
    }
    return parts.join(' ');
  }

  static const String _seat = 'piece';

  String _shapeSentence() {
    final t = type;
    if (t.length == 1) {
      return 'A single ${t.first}-cycle: $cycleNotation.';
    }
    final distinct = t.toSet();
    if (distinct.length == 1) {
      return '${_count(t.length)} ${t.first}-cycles at once: $cycleNotation.';
    }
    return 'Cycle shape ${t.join('+')}: $cycleNotation.';
  }

  static String _count(int n) => const {
        2: 'Two',
        3: 'Three',
        4: 'Four',
        5: 'Five',
        6: 'Six',
      }[n] ??
      '$n';

  static String _list(List<int> xs) {
    if (xs.length == 1) return 'seat ${xs.first}';
    if (xs.length == 2) return 'seats ${xs[0]} and ${xs[1]}';
    return 'seats ${xs.sublist(0, xs.length - 1).join(', ')} and ${xs.last}';
  }
}
