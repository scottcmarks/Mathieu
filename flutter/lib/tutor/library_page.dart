// The macro library: name, save, bind, rename, delete, re-derive.
//
// The engine has five macro slots and no more (m.h's History encoding reserves
// exactly 'A'..'E'). Rather than pretend otherwise, the library is unbounded
// here in Dart and A..E are treated as five registers you bind entries into.

import 'package:flutter/material.dart';

import '../m12/analysis.dart';
import '../m12/library.dart';
import '../m12/perm.dart';
import '../m12/word.dart';
import 'actions.dart';
import 'widgets.dart';

class LibraryPage extends StatefulWidget {
  final TutorActions actions;
  const LibraryPage({super.key, required this.actions});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  TutorActions get a => widget.actions;

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

  @override
  Widget build(BuildContext context) {
    final brain = a.brain;
    final lib = brain.library;
    final entries = lib.sortedFor(brain.swapIndex);
    final swap = brain.swap;

    return BackPage(
      title: 'Macro Library',
      actions: [
        TextButton(
          onPressed: _saveCurrent,
          child: const Text('Record'),
        ),
      ],
      body: BackList(children: [
        Text(
          'Five registers, A to E, are all the engine has. The library below is '
          'unbounded — bind whichever entries you want to the keys.',
          style: kSubtleStyle,
        ),
        const SizedBox(height: 14),
        _registers(entries),
        Section(
          title: 'Saved macros',
          note: entries.isEmpty
              ? null
              : 'Entries written under another swap are greyed out — a macro is '
                  'a different element under a different swap.',
          child: entries.isEmpty
              ? Text(
                  'Nothing saved yet. Play some moves on the board, then tap '
                  'Record — or build something in the Workshop.',
                  style: kSubtleStyle)
              : Column(
                  children: [
                    for (final e in entries) _entryTile(e, swap),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _registers(List<MacroEntry> entries) {
    final lib = a.brain.library;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final slot in kMacroSlots)
          _RegisterChip(
            label: slotLabel(slot),
            entry: lib.boundTo(slot),
            onTap: () => _pickForSlot(slot, entries),
            onClear: lib.boundTo(slot) == null
                ? null
                : () async {
                    await a.unbindSlot(slot);
                    if (mounted) setState(() {});
                  },
          ),
      ],
    );
  }

  Widget _entryTile(MacroEntry e, List<int> swap) {
    final here = e.swapIndex == a.brain.swapIndex;
    final perm = e.word.permutation(swap: swap);
    final slot = a.brain.library.slotOf(e.id);
    final analysis = MacroAnalysis.of(perm, word: e.word, table: a.brain.table);
    return Opacity(
      opacity: here ? 1 : 0.45,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Row(children: [
          Flexible(child: Text(e.name, style: kLabelStyle)),
          if (slot != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC23D),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(slotLabel(slot),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.word.display, style: kMonoStyle.copyWith(fontSize: 13)),
            Text(
              here
                  ? '${analysis.typeLabel} · ${analysis.support.length} seats · '
                      'order ${analysis.order}'
                  : 'written under swap #${e.swapIndex + 1}',
              style: kSubtleStyle,
            ),
            if (e.origin.isNotEmpty)
              Text(e.origin, style: kSubtleStyle.copyWith(fontSize: 11)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: () => _openEntry(e),
      ),
    );
  }

  Future<void> _pickForSlot(int slot, List<MacroEntry> entries) async {
    final usable = entries.where((e) => e.swapIndex == a.brain.swapIndex).toList();
    if (usable.isEmpty) {
      _toast('Nothing saved under this swap yet.');
      return;
    }
    final chosen = await showModalBottomSheet<MacroEntry>(
      context: context,
      backgroundColor: Colors.white,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
                title: Text('Bind to ${slotLabel(slot)}',
                    style: kLabelStyle.copyWith(fontWeight: FontWeight.w600))),
            for (final e in usable)
              ListTile(
                title: Text(e.name, style: kLabelStyle),
                subtitle: Text(e.word.display, style: kMonoStyle.copyWith(fontSize: 13)),
                onTap: () => Navigator.pop(c, e),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await a.bindSlot(slot, chosen);
    if (mounted) setState(() {});
  }

  Future<void> _saveCurrent() async {
    final w = a.currentWord;
    if (w.isEmpty) {
      _toast('Play some moves on the board first, then Record.');
      return;
    }
    await _saveWord(w, suggested: 'Macro', origin: 'recorded from play');
  }

  Future<void> _saveWord(Word w,
      {required String suggested, String origin = ''}) async {
    final name = await promptForName(context, suggested);
    if (name == null) return;
    await a.brain.save(name: name, word: w, origin: origin);
    if (mounted) setState(() {});
  }

  Future<void> _openEntry(MacroEntry e) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MacroDetailPage(actions: a, entryId: e.id),
    ));
    if (mounted) setState(() {});
  }

  void _toast(String s) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(s), duration: const Duration(seconds: 2)));
}

class _RegisterChip extends StatelessWidget {
  final String label;
  final MacroEntry? entry;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _RegisterChip(
      {required this.label, required this.entry, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    final bound = entry != null;
    return InkWell(
      onTap: onTap,
      onLongPress: onClear,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bound ? const Color(0xFFFFF3D6) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry?.name ?? 'empty',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bound ? kSubtleStyle.copyWith(color: Colors.black87) : kSubtleStyle,
            ),
          ),
          if (onClear != null)
            const Icon(Icons.close, size: 14, color: Colors.black38),
        ]),
      ),
    );
  }
}

/// One saved macro, in full: what it is, and everything you can do with it.
class MacroDetailPage extends StatefulWidget {
  final TutorActions actions;
  final String entryId;
  const MacroDetailPage({super.key, required this.actions, required this.entryId});

  @override
  State<MacroDetailPage> createState() => _MacroDetailPageState();
}

class _MacroDetailPageState extends State<MacroDetailPage> {
  TutorActions get a => widget.actions;

  @override
  Widget build(BuildContext context) {
    final brain = a.brain;
    final e = brain.library.byId(widget.entryId);
    if (e == null) return const BackPage(title: 'Macro', body: SizedBox());

    final swap = brain.swap;
    final here = e.swapIndex == brain.swapIndex;
    final perm = e.word.permutation(swap: swap);
    final analysis = MacroAnalysis.of(perm, word: e.word, table: brain.table);
    final slot = brain.library.slotOf(e.id);

    return BackPage(
      title: e.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () async {
            final n = await promptForName(context, e.name, title: 'Rename');
            if (n == null) return;
            await brain.rename(e, n);
            if (mounted) setState(() {});
          },
        ),
      ],
      body: BackList(children: [
        if (!here)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'This was written under swap #${e.swapIndex + 1}. Under the swap '
                'now in force (#${brain.swapNumber}) the same word is a different '
                'element — the analysis below is for what it does HERE.',
                style: kSubtleStyle,
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _rederive,
                child: const Text('Re-derive under this swap'),
              ),
            ]),
          ),
        AnalysisCard(analysis),
        Section(
          title: 'Use it',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(
              onPressed: () => a.playWord(e.word,
                  label: e.name, highlight: supportOf(perm).toSet()),
              child: const Text('Run on the board'),
            ),
            OutlinedButton(
              onPressed: () => a.playWord(e.word,
                  label: e.name,
                  highlight: supportOf(perm).toSet(),
                  stepped: true),
              child: const Text('Step through it'),
            ),
            OutlinedButton(
              onPressed: () => a.playWord(e.word.inverted(),
                  label: '${e.name} undone',
                  highlight: supportOf(perm).toSet()),
              child: const Text('Run the inverse'),
            ),
          ]),
        ),
        Section(
          title: 'The inverse',
          note: 'Reverse the word and negate every letter — that is all an '
              'inverse is (History::invert). The Alt key already runs it; here '
              'is what it actually spells.',
          child: Row(children: [
            Expanded(child: WordChip(e.word.inverted())),
          ]),
        ),
        Section(
          title: 'Bind to a key',
          child: Wrap(spacing: 8, children: [
            for (final s in kMacroSlots)
              ChoiceChip(
                label: Text(slotLabel(s)),
                selected: slot == s,
                onSelected: here
                    ? (v) async {
                        if (v) {
                          await a.bindSlot(s, e);
                        } else {
                          await a.unbindSlot(s);
                        }
                        if (mounted) setState(() {});
                      }
                    : null,
              ),
          ]),
        ),
        Section(
          title: '',
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await a.brain.delete(a.game, e);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete this macro'),
          ),
        ),
      ]),
    );
  }

  Future<void> _rederive() async {
    final brain = a.brain;
    final t = await brain.ensureTable();
    final e = brain.library.byId(widget.entryId);
    if (t == null || e == null) return;
    // The old word's element has to be read under the swap it was written for.
    final oldSwap = brain.swapPermAt(e.swapIndex);
    final made = brain.library.rederive(e, t, oldSwap);
    if (!mounted) return;
    if (made == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No element of that shape acts on those seats here.')));
      return;
    }
    await brain.save(name: made.name, word: made.word, origin: made.origin);
    if (mounted) setState(() {});
  }
}

/// A one-field name prompt, shared by save and rename.
///
/// The app's ThemeData is dark, because the board is black. These pages are the
/// light back of the game, so the dialog is given a light theme of its own —
/// otherwise a black dialog lands on a white page.
Future<String?> promptForName(BuildContext context, String initial,
    {String title = 'Name this macro'}) async {
  final ctrl = TextEditingController(text: initial);
  final out = await showDialog<String>(
    context: context,
    builder: (c) => Theme(
      data: ThemeData(brightness: Brightness.light, useMaterial3: true),
      child: AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Triple Twist'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Save')),
        ],
      ),
    ),
  );
  ctrl.dispose();
  final s = out?.trim();
  return (s == null || s.isEmpty) ? null : s;
}
