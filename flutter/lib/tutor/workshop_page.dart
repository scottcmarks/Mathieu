// The workshop: build new macros out of old ones.
//
// Four constructions, and one search:
//
//   inverse      reverse the word, negate every letter
//   composition  concatenate, with the engine's own cancellation applied
//   commutator   [A,B] = A B A⁻¹ B⁻¹
//   conjugation  X M X⁻¹ — aim a macro at seats you choose
//   discovery    scan all 95,040 elements for the least-disturbing ones
//
// Two honest findings are shown rather than papered over:
//
//  * There are no 3-cycles in M12. The floor is eight seats. See analysis.dart.
//  * The commutator is NOT the cheap route it is on a Rubik's cube. Measured
//    under swap #1: the best support-8 element reachable as a commutator of
//    short words costs 6 moves, while a direct table search finds one in 4.
//    The commutator is worth teaching as the reason small-support elements
//    exist, not as the way to build them — and the page says so, computing
//    the comparison live rather than quoting it.

import 'package:flutter/material.dart';

import '../m12/analysis.dart';
import '../m12/library.dart';
import '../m12/perm.dart';
import '../m12/search.dart';
import '../m12/word.dart';
import 'actions.dart';
import 'library_page.dart';
import 'widgets.dart';

class WorkshopPage extends StatefulWidget {
  final TutorActions actions;
  const WorkshopPage({super.key, required this.actions});

  @override
  State<WorkshopPage> createState() => _WorkshopPageState();
}

class _WorkshopPageState extends State<WorkshopPage> {
  TutorActions get a => widget.actions;

  MacroEntry? _first;
  MacroEntry? _second;

  @override
  void initState() {
    super.initState();
    a.brain.addListener(_onBrain);
    a.brain.ensureTable();
  }

  @override
  void dispose() {
    a.brain.removeListener(_onBrain);
    super.dispose();
  }

  void _onBrain() {
    if (mounted) setState(() {});
  }

  List<MacroEntry> get _usable => a.brain.library.entries
      .where((e) => e.swapIndex == a.brain.swapIndex)
      .toList();

  @override
  Widget build(BuildContext context) {
    final brain = a.brain;
    final usable = _usable;
    // Keep the two pickers pointing at entries that still exist.
    if (_first != null && !usable.any((e) => e.id == _first!.id)) _first = null;
    if (_second != null && !usable.any((e) => e.id == _second!.id)) _second = null;
    _first ??= usable.isNotEmpty ? usable.first : null;
    _second ??= usable.length > 1 ? usable[1] : _first;

    return BackPage(
      title: 'Workshop',
      body: BackList(children: [
        if (usable.isEmpty)
          Text(
            'The workshop builds new macros out of saved ones. Record a macro '
            'first — play some moves on the board, then Record in the Library.',
            style: kSubtleStyle,
          )
        else ...[
          _picker('First', _first, (e) => setState(() => _first = e)),
          const SizedBox(height: 8),
          _picker('Second', _second, (e) => setState(() => _second = e)),
          _inverseSection(),
          _composeSection(),
          _commutatorSection(),
          _conjugateSection(),
        ],
        _discoverySection(),
        if (brain.table != null) _factsSection(),
      ]),
    );
  }

  Widget _picker(String label, MacroEntry? value, ValueChanged<MacroEntry> onPick) =>
      Row(children: [
        SizedBox(width: 70, child: Text(label, style: kSubtleStyle)),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value?.id,
            items: [
              for (final e in _usable)
                DropdownMenuItem(
                  value: e.id,
                  child: Text('${e.name}   ${e.word.display}',
                      overflow: TextOverflow.ellipsis, style: kMonoStyle),
                ),
            ],
            onChanged: (id) {
              final e = _usable.firstWhere((x) => x.id == id);
              onPick(e);
            },
          ),
        ),
      ]);

  // --- the four constructions ------------------------------------------------

  Widget _inverseSection() {
    final e = _first;
    if (e == null) return const SizedBox();
    return Section(
      title: 'Inverse',
      note: 'Reverse the word and negate every letter. The Alt key already runs '
          'it; this shows what it spells and lets you save it as its own entry.',
      child: _result(
        word: e.word.inverted(),
        origin: 'inverse of "${e.name}"',
        suggested: '${e.name} undone',
      ),
    );
  }

  Widget _composeSection() {
    final x = _first, y = _second;
    if (x == null || y == null) return const SizedBox();
    final joined = x.word.times(y.word);
    final saved = x.word.moves + y.word.moves - joined.moves;
    return Section(
      title: 'Composition',
      note: 'Do the first, then the second. Adjacent runs merge and round trips '
          'vanish — the same reduction the engine performs on your history.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: WordChip(x.word)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6), child: Text('then')),
          Flexible(child: WordChip(y.word)),
        ]),
        const SizedBox(height: 8),
        if (saved > 0)
          Text(
            'Writing them together saves $saved move${saved == 1 ? '' : 's'} — '
            'the join cancelled.',
            style: kSubtleStyle.copyWith(color: Colors.green.shade800),
          ),
        const SizedBox(height: 4),
        _result(
          word: joined,
          origin: '"${x.name}" then "${y.name}"',
          suggested: '${x.name}+${y.name}',
        ),
      ]),
    );
  }

  Widget _commutatorSection() {
    final x = _first, y = _second;
    if (x == null || y == null) return const SizedBox();
    final swap = a.brain.swap;
    final w = x.word.times(y.word).times(x.word.inverted()).times(y.word.inverted());
    final perm = w.permutation(swap: swap);
    final t = a.brain.table;
    final supp = supportOf(perm).length;

    // The honest comparison, computed rather than quoted: what does a direct
    // table search cost for the same amount of disturbance?
    String? verdict;
    if (t != null && supp > 0) {
      final d = a.brain.discovery;
      if (d != null) {
        final direct = d.entries
            .where((e) => e.supportSize <= supp && e.moves > 0)
            .fold<int?>(null, (best, e) => best == null || e.moves < best ? e.moves : best);
        if (direct != null) {
          verdict = direct < w.moves
              ? 'The commutator costs ${w.moves} moves and disturbs $supp seats. '
                  'A direct search of the group finds a disturbance of $supp seats '
                  'or fewer in $direct. In M₁₂ the commutator explains why small '
                  'moves exist — it is not the cheap way to build them, unlike on '
                  'a Rubik’s cube.'
              : 'The commutator costs ${w.moves} moves for $supp seats; the best '
                  'direct search manages $direct. Here the commutator holds its own.';
        }
      }
    }

    return Section(
      title: 'Commutator  [A, B]',
      note: 'Do A, do B, undo A, undo B. Whatever the two moves agree about '
          'cancels; what is left is only where they disagree.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('[${x.name}, ${y.name}]', style: kLabelStyle),
        const SizedBox(height: 6),
        if (isIdentityPerm(perm))
          Text('These two commute — the bracket is nothing at all.',
              style: kSubtleStyle)
        else
          Text('Disturbs $supp seats (${cycleTypeString(perm)}), '
              'down from ${supportOf(x.word.permutation(swap: swap)).length} '
              'and ${supportOf(y.word.permutation(swap: swap)).length}.',
              style: kSubtleStyle),
        if (verdict != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(verdict, style: kSubtleStyle),
          ),
        ],
        const SizedBox(height: 8),
        _result(
          word: w,
          origin: 'commutator of "${x.name}" and "${y.name}"',
          suggested: '[${x.name},${y.name}]',
        ),
      ]),
    );
  }

  Widget _conjugateSection() {
    final e = _first;
    if (e == null) return const SizedBox();
    return Section(
      title: 'Aim it — conjugation',
      note: 'X M X⁻¹: set the board up, run the macro, put the setup back. The '
          'macro then acts on the seats you chose. M₁₂ is 5-transitive, so a '
          'setup word always exists — there is no "not found" here.',
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConjugatePage(actions: a, entryId: e.id),
        )),
        child: Text('Aim "${e.name}" at chosen seats'),
      ),
    );
  }

  // --- discovery -------------------------------------------------------------

  Widget _discoverySection() {
    final brain = a.brain;
    final d = brain.discovery;
    return Section(
      title: 'What is the least you can disturb?',
      note: 'Every one of the 95,040 elements, sorted by how many seats it '
          'moves. Computed here and now, for swap #${brain.swapNumber} — these '
          'are not constants.',
      child: d == null
          ? (brain.isDiscovering || brain.isBuildingTable
              ? const Working('Searching the whole group…')
              : Center(
                  child: FilledButton(
                    onPressed: () => brain.ensureDiscovery(),
                    child: const Text('Search the group'),
                  ),
                ))
          : _discoveryResults(d),
    );
  }

  Widget _discoveryResults(Discovery d) {
    final brain = a.brain;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF4FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(kNoSmallSupportHeadline, style: kLabelStyle.copyWith(fontSize: 15)),
      ),
      const SizedBox(height: 10),
      Text('How many elements move exactly n seats:', style: kSubtleStyle),
      const SizedBox(height: 4),
      for (final e in d.supportCensus.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(children: [
            SizedBox(
                width: 70,
                child: Text('${e.key} seats', style: kSubtleStyle)),
            Expanded(child: Text('${e.value}', style: kMonoStyle)),
          ]),
        ),
      const SizedBox(height: 12),
      Text('Cheapest word for each shape, at or near the floor:',
          style: kSubtleStyle),
      const SizedBox(height: 6),
      for (final e in d.shortlist)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('${e.supportSize} seats · ${e.typeLabel}', style: kLabelStyle),
          subtitle: Text(
              '${e.word.display}   (${e.moves} moves, ${e.population} such elements)',
              style: kMonoStyle.copyWith(fontSize: 13)),
          trailing: TextButton(
            onPressed: () => _save(
              e.word,
              suggested: '${e.typeLabel} (${e.supportSize} seats)',
              origin: 'found by searching swap #${brain.swapNumber}',
            ),
            child: const Text('Save'),
          ),
          onTap: () => a.playWord(e.word,
              label: e.typeLabel, highlight: supportOf(e.perm).toSet()),
        ),
      const SizedBox(height: 6),
      Text('Search took ${d.searchTime.inMilliseconds} ms.',
          style: kSubtleStyle.copyWith(fontSize: 11)),
    ]);
  }

  Widget _factsSection() {
    final t = a.brain.table!;
    return Section(
      title: 'This board, measured',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Positions reachable: 95,040', style: kMonoStyle),
        Text('Furthest from home: ${t.diameter} moves', style: kMonoStyle),
        Text('Swap in force: #${a.brain.swapNumber}', style: kMonoStyle),
        const SizedBox(height: 6),
        Text(
          'The diameter is a property of the swap, not of M₁₂: it is 11 under '
          'swap #2 and 12 under #22. Built in ${t.buildTime.inMilliseconds} ms.',
          style: kSubtleStyle,
        ),
      ]),
    );
  }

  // --- shared result row -----------------------------------------------------

  Widget _result({
    required Word word,
    required String origin,
    required String suggested,
  }) {
    final swap = a.brain.swap;
    final perm = word.permutation(swap: swap);
    final analysis = MacroAnalysis.of(perm, word: word, table: a.brain.table);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      WordChip(word),
      const SizedBox(height: 4),
      Text(
        isIdentityPerm(perm)
            ? 'This comes to nothing — it is the home position.'
            : '${analysis.typeLabel} · ${analysis.support.length} seats · '
                'order ${analysis.order}'
                '${analysis.distance != null ? ' · ${analysis.distance} from home' : ''}',
        style: kSubtleStyle,
      ),
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        TextButton(
          onPressed: word.isEmpty
              ? null
              : () => a.playWord(word,
                  label: suggested, highlight: supportOf(perm).toSet()),
          child: const Text('Run it'),
        ),
        TextButton(
          onPressed: word.isEmpty
              ? null
              : () => _save(word, suggested: suggested, origin: origin),
          child: const Text('Save to library'),
        ),
      ]),
    ]);
  }

  Future<void> _save(Word w,
      {required String suggested, required String origin}) async {
    final name = await promptForName(context, suggested);
    if (name == null) return;
    await a.brain.save(name: name, word: w, origin: origin);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Saved "$name".')));
  }
}

/// Pick the seats a macro should act on; the app finds the setup word.
class ConjugatePage extends StatefulWidget {
  final TutorActions actions;
  final String entryId;
  const ConjugatePage({super.key, required this.actions, required this.entryId});

  @override
  State<ConjugatePage> createState() => _ConjugatePageState();
}

class _ConjugatePageState extends State<ConjugatePage> {
  TutorActions get a => widget.actions;
  final Set<int> _chosen = <int>{};
  Conjugation? _result;
  bool _searching = false;

  MacroEntry? get _entry => a.brain.library.byId(widget.entryId);

  List<int> get _macroPerm => _entry!.word.permutation(swap: a.brain.swap);

  /// The user picks the seats to LEAVE ALONE when the macro fixes few enough of
  /// them to make that the natural question (a 3+3+3 fixes three); otherwise
  /// they pick the seats to disturb.
  bool get _pickFixed => fixedOf(_macroPerm).length <= supportOf(_macroPerm).length;

  int get _needed =>
      _pickFixed ? fixedOf(_macroPerm).length : supportOf(_macroPerm).length;

  @override
  void initState() {
    super.initState();
    a.brain.ensureTable().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = _entry;
    if (e == null) return const BackPage(title: 'Aim', body: SizedBox());
    final t = a.brain.table;
    final perm = _macroPerm;

    return BackPage(
      title: 'Aim "${e.name}"',
      body: BackList(children: [
        Text(
          _pickFixed
              ? 'This macro leaves $_needed seats alone '
                  '(${fixedOf(perm).join(', ')}). Tap the $_needed seats you '
                  'want it to leave alone instead.'
              : 'This macro disturbs $_needed seats. Tap the $_needed seats you '
                  'want it to disturb instead.',
          style: kSubtleStyle,
        ),
        const SizedBox(height: 12),
        Center(
          child: SeatRing(
            size: 220,
            roles: {
              for (var i = 0; i < kBalls; i++)
                i: _chosen.contains(i)
                    ? SeatRole.chosen
                    : (perm[i] == i ? SeatRole.fixed : SeatRole.moved),
            },
            onTapSeat: (i) => setState(() {
              if (!_chosen.remove(i)) {
                if (_chosen.length < _needed) _chosen.add(i);
              }
              _result = null;
            }),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('${_chosen.length} of $_needed chosen', style: kSubtleStyle),
        ),
        const SizedBox(height: 12),
        if (t == null)
          const Working('Mapping the group…')
        else
          Center(
            child: FilledButton(
              onPressed: _chosen.length == _needed && !_searching ? _search : null,
              child: Text(_searching ? 'Searching…' : 'Find the setup word'),
            ),
          ),
        if (_result != null) _resultBlock(_result!),
      ]),
    );
  }

  Future<void> _search() async {
    final t = a.brain.table;
    final e = _entry;
    if (t == null || e == null) return;
    setState(() => _searching = true);
    // The target is the set of seats the conjugate must DISTURB.
    final target = _pickFixed
        ? {for (var i = 0; i < kBalls; i++) if (!_chosen.contains(i)) i}
        : Set<int>.of(_chosen);
    final r = await findConjugation(t, _macroPerm, target, macroWord: e.word);
    if (!mounted) return;
    setState(() {
      _result = r;
      _searching = false;
    });
  }

  Widget _resultBlock(Conjugation c) {
    final e = _entry!;
    final analysis =
        MacroAnalysis.of(c.resultPerm, word: c.fullWord, table: a.brain.table);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Section(
        title: 'The setup',
        note: 'Found by checking all 95,040 elements, so it is the cheapest '
            'there is — not a good guess.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: 70, child: Text('setup X', style: kSubtleStyle)),
            Flexible(child: WordChip(c.setup, color: Colors.blue.shade700)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            SizedBox(width: 70, child: Text('macro M', style: kSubtleStyle)),
            Flexible(child: WordChip(e.word, color: Colors.orange.shade900)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            SizedBox(width: 70, child: Text('undo X', style: kSubtleStyle)),
            Flexible(child: WordChip(c.setup.inverted(), color: Colors.blue.shade700)),
          ]),
          const SizedBox(height: 8),
          Text(
            c.movesSavedByJoining > 0
                ? '${c.totalMoves} moves as three pieces — but ${c.joinedMoves} '
                    'once you write them as one word, because the seam '
                    'cancels ${c.movesSavedByJoining} of them.'
                : '${c.totalMoves} moves in all.',
            style: kSubtleStyle,
          ),
        ]),
      ),
      Section(title: 'What it does', child: AnalysisCard(analysis)),
      Section(
        title: '',
        child: Wrap(spacing: 8, children: [
          FilledButton(
            onPressed: () => a.playWord(c.fullWord,
                label: 'aimed ${e.name}',
                highlight: supportOf(c.resultPerm).toSet(),
                stepped: true),
            child: const Text('Step through it'),
          ),
          OutlinedButton(
            onPressed: () => a.playWord(c.fullWord,
                label: 'aimed ${e.name}',
                highlight: supportOf(c.resultPerm).toSet()),
            child: const Text('Run it'),
          ),
          OutlinedButton(
            onPressed: () async {
              final name = await promptForName(
                  context, '${e.name} on ${supportOf(c.resultPerm).take(3).join("/")}…');
              if (name == null) return;
              await a.brain.save(
                name: name,
                word: c.fullWord,
                origin: '"${e.name}" aimed by conjugation',
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Saved "$name".')));
            },
            child: const Text('Save to library'),
          ),
        ]),
      ),
    ]);
  }
}
