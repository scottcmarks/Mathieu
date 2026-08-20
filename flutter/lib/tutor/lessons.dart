// The curriculum.
//
// Each lesson is one thing the app can do that the physical toy cannot. That is
// the whole point of the booklet's "there is an app that looks like this toy":
// the toy can be spun and swapped, but it cannot count its own states, search
// its own move space, remember what you just did, or tell you whether you are
// getting closer.
//
// HARD RULE: no lesson may hard-code a word, a distance, a diameter or a
// census. Every number below is read out of the runtime table for the swap in
// force, because all of them change with the swap: the diameter is 11 under
// swap #2 and 12 under #22; RSRS is a 3+3+3 under #2 and a 2+2+2+2 under #22;
// the cheapest 4+4 costs four moves under #2 and two under #22.

import 'package:flutter/material.dart';

import '../m12/analysis.dart';
import '../m12/perm.dart';
import '../m12/search.dart';
import '../m12/table.dart';
import '../m12/word.dart';
import 'actions.dart';
import 'library_page.dart';
import 'widgets.dart';
import 'workshop_page.dart';

/// What a lesson body is handed.
class LessonContext {
  final TutorActions actions;
  final M12Table? table;
  final Discovery? discovery;
  final BuildContext context;
  const LessonContext({
    required this.actions,
    required this.table,
    required this.discovery,
    required this.context,
  });

  List<int> get swap => actions.brain.swap;
  int get swapNumber => actions.brain.swapNumber;

  void openLibrary() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => LibraryPage(actions: actions)));

  void openWorkshop() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => WorkshopPage(actions: actions)));
}

class Lesson {
  final int number;
  final String title;
  final String tagline;

  /// The line that says why this needs an app.
  final String toyCant;

  /// Needs the BFS table before it can say anything.
  final bool needsTable;

  /// Needs the group-wide search too.
  final bool needsDiscovery;

  /// Shown only when a device skin is active; ships and hides with its pack.
  final bool skinGated;

  final List<Widget> Function(LessonContext) body;

  const Lesson({
    required this.number,
    required this.title,
    required this.tagline,
    required this.toyCant,
    required this.body,
    this.needsTable = false,
    this.needsDiscovery = false,
    this.skinGated = false,
  });
}

Widget _p(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(s, style: kLabelStyle.copyWith(fontSize: 15, height: 1.35)),
    );

Widget _fact(String s) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(s, style: kLabelStyle.copyWith(fontSize: 15)),
    );

Widget _do(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(onPressed: onTap, child: Text(label)),
      ),
    );

Widget _go(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(onPressed: onTap, child: Text(label)),
      ),
    );

/// Cheapest representative of a cycle shape under the swap in force, or null.
DiscoveryEntry? _cheapest(Discovery? d, List<int> type) {
  if (d == null) return null;
  final key = type.join(',');
  for (final e in d.entries) {
    if (e.type.join(',') == key) return e;
  }
  return null;
}

final List<Lesson> kLessons = [
  // ---------------------------------------------------------------- L0
  Lesson(
    number: 0,
    title: 'Meet the machine',
    tagline: 'What the mechanism is really doing.',
    toyCant: 'The toy can show you the mechanism, but not that it is one move.',
    skinGated: true,
    body: (c) {
      final v = c.actions.skin.vocab;
      return [
        _p('You are looking at a ${v.boardName} of twelve ${v.pieces}. '
            'Eleven of them sit on the ${v.boardName}; the twelfth waits at the '
            '${v.outboardSeat}.'),
        _p('However elaborate the ${v.swapVerb.toLowerCase()} looks — pieces '
            'sliding down lanes, rolling along a chord, riding a rotor — it is '
            'ONE move. The machine is a way of performing a single permutation '
            'with your hands; the app performs the same permutation with one tap.'),
        _fact('Everything in this tutorial is true of the mechanism and of the '
            'plain ring alike. The skin changes what it looks like, never what '
            'it does.'),
      ];
    },
  ),

  // ---------------------------------------------------------------- L1
  Lesson(
    number: 1,
    title: 'The two moves',
    tagline: 'Spin and swap — that is the entire machine.',
    toyCant: 'A toy cannot annotate itself.',
    body: (c) {
      final v = c.actions.skin.vocab;
      final r = kRight;
      return [
        _p('There are exactly two things you can do.'),
        _p('SPIN turns the ${v.boardName} by one seat. It is an 11-cycle: eleven '
            'seats go round, and the ${v.outboardSeat} — seat 0 — never moves. '
            'Spin eleven times and you are back where you started.'),
        Center(child: SeatRing.forPerm(r, size: 190)),
        const SizedBox(height: 12),
        _p('SWAP exchanges six pairs at once. Which pairs depends on which of '
            'the 341 swap permutations is selected; right now it is '
            '#${c.swapNumber}:'),
        Center(child: SeatRing.forPerm(c.swap, size: 190)),
        const SizedBox(height: 12),
        _p(cyclesString(c.swap)),
        const SizedBox(height: 6),
        _fact('Those two moves, and nothing else, generate the whole puzzle. '
            'Every position you will ever see is some sequence of spins and '
            'swaps.'),
        _do('Try them on the board', () => c.actions.goHome()),
      ];
    },
  ),

  // ---------------------------------------------------------------- L2
  Lesson(
    number: 2,
    title: 'Two moves, 95,040 positions',
    tagline: 'How big is this thing, and how far can you get?',
    toyCant: 'A toy cannot count its own states or know how far from home it is.',
    needsTable: true,
    body: (c) {
      final t = c.table!;
      final hist = t.distanceHistogram;
      return [
        _p('Twelve pieces could in principle be arranged 479,001,600 ways. Spin '
            'and swap do not reach anywhere near all of them.'),
        _fact('Exactly 95,040 positions are reachable. The app just built the '
            'whole map, in ${t.buildTime.inMilliseconds} ms, by walking outward '
            'from home one move at a time.'),
        _p('That set is the sporadic simple group M₁₂ — one of twenty-six finite '
            'groups that belong to no infinite family. This toy is a handle on '
            'one of them.'),
        _p('The furthest any position can be from home, under swap '
            '#${c.swapNumber}, is ${t.diameter} moves:'),
        for (var d = 0; d < hist.length; d++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(children: [
              SizedBox(width: 80, child: Text('$d move${d == 1 ? '' : 's'}', style: kSubtleStyle)),
              Expanded(child: Text('${hist[d]}', style: kMonoStyle)),
            ]),
          ),
        const SizedBox(height: 10),
        _fact('That number belongs to the swap, not to the group: change the '
            'swap permutation in Settings and this whole page recomputes. It is '
            '11 under swap #2 and 12 under #22.'),
      ];
    },
  ),

  // ---------------------------------------------------------------- L3
  Lesson(
    number: 3,
    title: 'Undo, and inverse',
    tagline: 'Every move has an opposite, and so does every sequence.',
    toyCant: 'A toy cannot spell out the opposite of what you just did.',
    body: (c) => [
      _p('Spinning left undoes spinning right. Swapping twice undoes itself — '
          'the swap is its own opposite.'),
      _p('A whole sequence has an opposite too, and it is mechanical to write '
          'down: reverse the order, and flip each move. To undo "spin right, '
          'swap, spin right twice" you spin left twice, swap, spin left.'),
      Center(child: Column(children: [
        WordChip(Word.parse('RSR2')),
        const SizedBox(height: 6),
        const Text('becomes', style: kSubtleStyle),
        const SizedBox(height: 6),
        WordChip(Word.parse('RSR2').inverted()),
      ])),
      const SizedBox(height: 14),
      _fact('This is why a macro costs nothing extra to run backwards. Once you '
          'have A you have A⁻¹ — the Alt key runs it.'),
      _p('It is also why the app can always get you out of trouble: whatever '
          'you played, the opposite of it is right there.'),
    ],
  ),

  // ---------------------------------------------------------------- L4
  Lesson(
    number: 4,
    title: 'Record your own macro',
    tagline: 'The thing a mechanical toy simply cannot do.',
    toyCant: 'A toy has no memory of what you did with it.',
    needsTable: true,
    body: (c) {
      final a = c.actions;
      final w = a.currentWord;
      final t = c.table;
      return [
        _p('Play any sequence of moves on the board, then hold down one of the '
            'keys A to E. The app remembers it as a single move you can replay '
            'with one tap — and, unlike the toy, it can tell you exactly what '
            'you just invented.'),
        if (w.isEmpty)
          _fact('You have not played anything yet. Go to the board, make a few '
              'moves, and come back — this page will analyse them.')
        else ...[
          _p('Here is what you have played so far:'),
          AnalysisCard(MacroAnalysis.of(
            w.permutation(swap: c.swap),
            word: w,
            table: t,
          )),
        ],
        const SizedBox(height: 12),
        _go('Open the macro library', c.openLibrary),
        _fact('A macro records the moves you played, not the position you '
            'played them from. Record one half-way through a scramble and it '
            'still means just those moves — which is why the analysis above is '
            'about your sequence and not about the mess it started in.'),
      ];
    },
  ),

  // ---------------------------------------------------------------- L5
  Lesson(
    number: 5,
    title: 'How little can you disturb?',
    tagline: 'Searching the whole group for the gentlest move.',
    toyCant: 'A toy cannot search its own move space.',
    needsTable: true,
    needsDiscovery: true,
    body: (c) {
      final d = c.discovery!;
      final three = _cheapest(d, [3, 3, 3]);
      final four = _cheapest(d, [4, 4]);
      final twos = _cheapest(d, [2, 2, 2, 2]);
      return [
        _p('On a Rubik\'s cube the endgame tool is a 3-cycle: a move that '
            'disturbs three pieces and nothing else. The natural question here '
            'is what the equivalent is.'),
        _fact(kNoSmallSupportHeadline),
        _p('That is not a limitation of the toy or of the app — it is a fact '
            'about M₁₂, and the app just verified it by looking at all 95,040 '
            'elements in ${d.searchTime.inMilliseconds} ms:'),
        for (final e in d.supportCensus.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(children: [
              SizedBox(width: 90, child: Text('${e.key} seats', style: kSubtleStyle)),
              Expanded(
                  child: Text('${e.value} element${e.value == 1 ? '' : 's'}',
                      style: kMonoStyle)),
            ]),
          ),
        const SizedBox(height: 12),
        _p('The cheapest ways to reach the floor, under swap #${c.swapNumber}:'),
        for (final e in [three, four, twos].whereType<DiscoveryEntry>())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(
                  width: 90,
                  child: Text(e.typeLabel, style: kSubtleStyle)),
              Expanded(
                child: Text('${e.word.display}  — ${e.moves} moves, '
                    '${e.supportSize} seats',
                    style: kMonoStyle),
              ),
            ]),
          ),
        const SizedBox(height: 10),
        if (three != null)
          _do('Run the 3+3+3 and watch', () => c.actions.playWord(three.word,
              label: 'the triple',
              highlight: supportOf(three.perm).toSet(),
              stepped: true)),
        _fact('Change the swap in Settings and these words change completely. '
            'Under swap #2 the cheapest 4+4 costs four moves; under #22 it '
            'costs two. Nothing in this list is a constant.'),
      ];
    },
  ),

  // ---------------------------------------------------------------- L6
  Lesson(
    number: 6,
    title: 'Aim it — conjugation',
    tagline: 'Set up, act, put the setup back.',
    toyCant: 'A toy cannot find the setup word for you.',
    needsTable: true,
    needsDiscovery: true,
    body: (c) {
      final three = _cheapest(c.discovery, [3, 3, 3]);
      return [
        _p('A 3+3+3 leaves three seats alone — but not necessarily the three you '
            'care about. The fix is the oldest trick in puzzle solving: move the '
            'board so the macro lands where you want, run it, then put the board '
            'back.'),
        _p('Written down: X, then M, then X undone. The result disturbs exactly '
            'the seats X sends the macro\'s seats to.'),
        if (three != null) ...[
          _p('Here is the cheapest 3+3+3 under swap #${c.swapNumber}, which '
              'leaves ${fixedOf(three.perm).join(', ')} alone:'),
          Center(child: SeatRing.forPerm(three.perm, size: 190)),
          const SizedBox(height: 12),
        ],
        _fact('There is never a "no setup found". M₁₂ is 5-transitive, which '
            'means it can carry any five seats to any other five — so it can '
            'certainly carry three to three. Checked exhaustively over all 220 '
            'triples: a setup always exists, and it costs at most six moves.'),
        _go('Aim a macro yourself', c.openWorkshop),
        _p('The Workshop\'s conjugation screen searches all 95,040 elements for '
            'the cheapest setup, so what it gives you is the shortest there is, '
            'not a decent guess.'),
      ];
    },
  ),

  // ---------------------------------------------------------------- L7
  Lesson(
    number: 7,
    title: 'Commutators',
    tagline: 'Where two moves disagree.',
    toyCant: 'A toy cannot compare its own constructions.',
    needsTable: true,
    needsDiscovery: true,
    body: (c) {
      final d = c.discovery!;
      final floor = d.entries
          .where((e) => e.supportSize == d.minimumSupport && e.moves > 0)
          .fold<int?>(null, (b, e) => b == null || e.moves < b ? e.moves : b);
      return [
        _p('Do A, do B, undo A, undo B. If A and B were interchangeable you '
            'would end up home; you do not, and what is left over is precisely '
            'where the two moves disagree. That leftover is usually much gentler '
            'than either move on its own.'),
        _p('That is the reason gentle moves exist at all in a group like this — '
            'and it is the standard way to build them on a Rubik\'s cube.'),
        _fact('But be honest about M₁₂: the commutator is a good explanation and '
            'a poor tool. Under swap #${c.swapNumber} a direct search finds a '
            '${d.minimumSupport}-seat move in $floor moves. Commutators of short '
            'words do not get near that. Use them to understand the group; use '
            'the search to build with.'),
        _go('Build a commutator in the Workshop', c.openWorkshop),
      ];
    },
  ),

  // ---------------------------------------------------------------- L8
  Lesson(
    number: 8,
    title: 'A working tool',
    tagline: 'Put the last three lessons together.',
    toyCant: 'A toy cannot hand you a tool kit.',
    needsTable: true,
    needsDiscovery: true,
    body: (c) {
      final three = _cheapest(c.discovery, [3, 3, 3]);
      return [
        _p('You now have everything an endgame needs:'),
        _p('1. A gentle move — the 3+3+3, nine seats, three left alone.\n'
            '2. A way to aim it anywhere — conjugation.\n'
            '3. A way to undo it — its inverse, free.'),
        if (three != null) ...[
          _p('The tool itself, for swap #${c.swapNumber}:'),
          Center(child: WordChip(three.word)),
          const SizedBox(height: 10),
          _do('Save it to the library', () async {
            await c.actions.brain.save(
              name: 'The triple',
              word: three.word,
              origin: 'from lesson 8',
            );
          }),
        ],
        _fact('This is the M₁₂ analogue of "learn one 3-cycle and conjugate it '
            'everywhere". The shape is nine seats rather than three, because '
            'the group has nothing smaller with three cycles — but the method '
            'is identical.'),
      ];
    },
  ),

  // ---------------------------------------------------------------- L9
  Lesson(
    number: 9,
    title: 'Finish a real scramble',
    tagline: 'With the distance showing after every move.',
    toyCant: 'A toy cannot tell you whether you are getting closer.',
    needsTable: true,
    body: (c) {
      final t = c.table!;
      final target = t.diameter >= 9 ? 9 : t.diameter;
      return [
        _p('Ordinary Shake drops you somewhere random. This puts you at a known '
            'distance from home — and then the board shows the exact number of '
            'moves you have left, recomputed after every single move.'),
        _fact('The counter is not an estimate. The app knows the shortest '
            'solution from every one of the 95,040 positions, so "$target moves '
            'left" means exactly that.'),
        _do('Scramble to exactly $target moves from home',
            () => c.actions.scrambleToDistance(target)),
        const SizedBox(height: 4),
        _p('Watch the distance while you play. A move that does not reduce it '
            'was a detour — the toy would never have told you.'),
        _go('Back to the board', () => c.actions.goHome()),
      ];
    },
  ),

  // ---------------------------------------------------------------- L10
  Lesson(
    number: 10,
    title: 'Your library',
    tagline: 'Five keys, unlimited macros, 341 swaps.',
    toyCant: 'A toy cannot keep your notes for you.',
    body: (c) {
      final brain = c.actions.brain;
      final mine =
          brain.library.entries.where((e) => e.swapIndex == brain.swapIndex).length;
      final other = brain.library.entries.length - mine;
      return [
        _p('The engine has exactly five macro keys, A to E. The library here has '
            'no limit — the keys are registers you bind entries into, and you '
            'can rebind them whenever you like.'),
        _p('You have $mine macro${mine == 1 ? '' : 's'} for the swap in force'
            '${other > 0 ? ', and $other written under other swaps' : ''}.'),
        _fact('A macro belongs to a swap. The same word is a different element '
            'under a different swap permutation — so entries from elsewhere are '
            'greyed out rather than silently wrong, and the library offers to '
            're-derive them: it searches this swap for the cheapest word of the '
            'same shape acting on the same seats.'),
        _go('Open the library', c.openLibrary),
        _p('That is the whole tour. Two moves, 95,040 positions, no 3-cycles, '
            'and a tool kit you built yourself.'),
      ];
    },
  ),
];

Lesson? lessonNumber(int n) {
  for (final l in kLessons) {
    if (l.number == n) return l;
  }
  return null;
}
