import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ball_ring.dart';
import 'deeplink.dart';
import 'm12/analysis.dart';
import 'm12/library.dart';
import 'm12/perm.dart';
import 'm12/table.dart' show moveElement;
import 'm12/word.dart';
import 'prefs.dart';
import 'skin/registry.dart';
import 'skin/registry_packs.g.dart';
import 'skin/skin.dart';
import 'swap_preview.dart';
import 'mathieu_ffi.dart';
import 'sounds.dart';
import 'build_info.dart';
import 'tutor/actions.dart';
import 'tutor/brain.dart';
import 'tutor/hub_page.dart';
import 'tutor/lesson_page.dart';
import 'tutor/library_page.dart';
import 'tutor/widgets.dart';

void main() => runMathieu();

/// Start the app.
///
/// [registerExtraSkins] runs immediately after the built-in packs and before
/// anything reads the pack table. It is the seam a private pack bundle plugs
/// into: `lib/skin/packs_private/` is gitignored, so no committed file may
/// name — or import — a pack that lives there, and a build that wants one runs
/// against the generated entry point in that directory instead of this one:
///
///   flutter build web -t lib/skin/packs_private/main_private.dart \
///                     --dart-define=SKIN_FLATPACK=true
///
/// That keeps the default entry point compiling in a clone that has no
/// packs_private/ at all, which is every clone but the one holding the private
/// repo. See SKINS.md.
Future<void> runMathieu({void Function()? registerExtraSkins}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMathieu(); // load the WASM engine on web; no-op on other platforms
  await Prefs.init();
  registerBuiltinSkins();
  registerExtraSkins?.call();
  // Portrait only, like the original (it never rotated to landscape).
  SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  Sfx.init();

  // A booklet link may name a skin and a swap. An unknown or un-enabled skin id
  // falls back to the default silently — see SkinRegistry.get. The link's choice
  // is not written to Prefs; only the settings picker changes what is remembered.
  final link = DeepLinkRequest.fromCurrentUrl();
  if (link.swapIndex != null) {
    final i = link.swapIndex!;
    if (i >= 0 && i < MathieuEngine.swapCount) MathieuEngine.swapIndex = i;
  }
  runApp(MathieuApp(
    initialSkin: SkinRegistry.get(link.skinId ?? Prefs.skinId),
    link: link,
  ));
}

// Beta "build tell": show the version/rev/time stamp on the running app so a
// specific installed beta build is identifiable at a glance. Hidden in store
// (release) builds unless --dart-define=BETA=true is passed (e.g. TestFlight).
const bool _showBuildTell =
    !kReleaseMode || bool.fromEnvironment('BETA', defaultValue: false);
const String _buildTell = '$kBuildVersion · $kBuildRev · $kBuildTime';

/// Owns the chosen skin: the theme's background comes from it, so a skin change
/// has to rebuild from above the MaterialApp.
class MathieuApp extends StatefulWidget {
  final Skin initialSkin;
  final DeepLinkRequest link;
  const MathieuApp({
    super.key,
    required this.initialSkin,
    this.link = DeepLinkRequest.empty,
  });
  @override
  State<MathieuApp> createState() => _MathieuAppState();
}

class _MathieuAppState extends State<MathieuApp> {
  late Skin _skin = widget.initialSkin;

  void _selectSkin(String id) {
    if (id == _skin.id) return;
    setState(() => _skin = SkinRegistry.get(id));
    Prefs.setSkinId(_skin.id);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sporadic M12',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _skin.palette.board,
          useMaterial3: true,
        ),
        home: GamePage(
            skin: _skin, onSkinSelected: _selectSkin, link: widget.link),
      );
}

// Map ball value -> palette index from a swap permutation: each disjoint 2-cycle
// gets the next colour, so a swapped pair shares a colour.
List<int> colorIndicesFor(List<int> swapPerm) {
  final n = swapPerm.length;
  final c = List<int>.filled(n, -1);
  var next = 0;
  for (var i = 0; i < n; i++) {
    if (c[i] == -1) {
      c[i] = next;
      c[swapPerm[i]] = next;
      next++;
    }
  }
  return c;
}


class GamePage extends StatefulWidget {
  final Skin skin;
  final ValueChanged<String> onSkinSelected;
  final DeepLinkRequest link;
  const GamePage({
    super.key,
    required this.skin,
    required this.onSkinSelected,
    this.link = DeepLinkRequest.empty,
  });
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin
    implements TutorActions {
  late final MathieuEngine _game;
  late int _n;
  late List<int> _colorOfBall;
  late List<int> _prevArr, _currArr;
  late final AnimationController _ctrl;
  late final CurvedAnimation _t;

  final M12Brain _brain = M12Brain();

  Skin get _skin => widget.skin;

  bool _notedSuccess = true; // legacy haveNotedSuccess; cleared only by a shake
  bool _sound = true;
  bool _confirm = true;
  bool _solving = false;
  bool _alt = false;
  bool _arc = false; // current tween: rotations spin labels along the arc
  double _animSpeed = 1.0; // 1.0 = base durations; higher = faster

  // step-through replay
  List<int>? _replaySteps;
  int _replayAt = 0;
  bool _replayPlaying = false;
  String _replayLabel = '';
  Set<int> _highlight = const <int>{};

  @override
  void initState() {
    super.initState();
    _game = MathieuEngine();
    _n = _game.n;
    _recomputeColors();
    _currArr = _game.arrangement();
    _prevArr = List<int>.of(_currArr);
    final motion = widget.skin.motion;
    _ctrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: motion.durationMs(MoveKind.rotate)));
    // The curve is re-set per move; a pack may time a swap differently from a spin.
    _t = CurvedAnimation(parent: _ctrl, curve: motion.curve(MoveKind.rotate));
    _ctrl.value = 1;

    _brain.load();
    _brain.restoreBindings(_game);
    _brain.addListener(_onBrain);
    // The map is what the distance read-out and every lesson depend on; start
    // it now so the first visit to Learn is not a wait.
    _brain.ensureTable();

    WidgetsBinding.instance.addPostFrameCallback((_) => _applyLink());
  }

  void _onBrain() {
    if (mounted) setState(() {});
  }

  void _recomputeColors() {
    _colorOfBall = colorIndicesFor(MathieuEngine.swapPermutation(_n));
  }

  /// The booklet's QR code, once the board exists. `skin` and `swap` were
  /// already applied in main(); `word` and `lesson` need a live game.
  Future<void> _applyLink() async {
    final link = widget.link;
    final w = Word.parse(link.word);
    if (w.isNotEmpty) {
      _instant(() {
        for (final e in w.primitiveSteps(macros: _macroWords)) {
          if (e == 0) {
            _game.swap();
          } else if (e > 0) {
            _game.right(e);
          } else {
            _game.left(-e);
          }
        }
        _solving = true;
      });
    }
    if (link.lesson != null && mounted) {
      await openLesson(context, this, link.lesson!);
    }
  }

  @override
  void dispose() {
    _brain.removeListener(_onBrain);
    _brain.dispose();
    _t.dispose();
    _ctrl.dispose();
    _game.dispose();
    super.dispose();
  }

  // Play a sound through the skin's name map. A pack may only remap onto the
  // shared sound set (gated packs ship no assets), so an unknown mapping falls
  // back to the default pack's sound rather than throwing on a missing asset.
  void _sfx(String name) {
    final mapped = _skin.sound.resolve(name);
    Sfx.play(Sfx.has(mapped) ? mapped : name);
  }

  // Apply an engine action and tween the balls from the old to the new layout.
  // [success] true for "play" moves that can solve the puzzle (rotate/swap/macro/undo).
  void _animatedMove(void Function() act, String? sound, MoveKind kind,
      {bool success = false, bool arc = false}) {
    setState(() {
      if (sound != null) _sfx(sound);
      _arc = arc;
      _prevArr = _currArr;
      act();
      _currArr = _game.arrangement();
      _alt = false;
      if (success) _checkSuccess();
    });
    final motion = _skin.motion;
    _t.curve = motion.curve(kind);
    _ctrl.duration = Duration(
        milliseconds: (motion.durationMs(kind) / _animSpeed).round().clamp(1, 4000));
    _ctrl.forward(from: 0);
  }

  // Refresh layout with no tween (drag steps, macro-set expansions, selector).
  void _instant(void Function() act, {String? sound, bool success = false}) {
    setState(() {
      if (sound != null) _sfx(sound);
      act();
      _currArr = _game.arrangement();
      _prevArr = List<int>.of(_currArr);
      _ctrl.value = 1;
      if (success) _checkSuccess();
    });
  }

  // Applause only the first time a *scrambled* puzzle is brought home. The flag
  // clears only on a new shake, so reaching home by Home/reset, or undoing back
  // to solved after you've already solved it, does not (re-)applaud.
  void _checkSuccess() {
    if (_solving && _game.isSolved && !_notedSuccess) {
      _sfx('applause');
      _notedSuccess = true;
    }
  }

  // --- button / gesture moves (success: can solve the puzzle) ---
  void _left() => _animatedMove(_game.left, 'left', MoveKind.rotate, success: true, arc: true);
  void _right() => _animatedMove(_game.right, 'right', MoveKind.rotate, success: true, arc: true);
  void _swap() => _animatedMove(_game.swap, 'swap', MoveKind.swap, success: true);
  void _rotateDrag(bool right) => _instant(right ? _game.right : _game.left,
      sound: right ? 'right' : 'left', success: true);

  void _macroTap(int c) {
    if (!_game.macroDefined(c)) return;
    _animatedMove(() => _game.runMacro(c, inverted: _alt), 'combo', MoveKind.macro, success: true);
  }

  /// What each defined macro key currently stands for. Anything that plays,
  /// measures or expands a word has to be handed this, or a macro letter in
  /// that word has no meaning to resolve — see Word.primitiveSteps.
  Map<int, Word> get _macroWords {
    final macros = <int, Word>{};
    for (final s in kMacroSlots) {
      if (_game.macroDefined(s)) macros[s] = Word.parse(_game.macroWord(s));
    }
    return macros;
  }

  /// The word the user has played since this solve began, with any macro
  /// letters expanded to the moves they stand for — so a saved library entry
  /// keeps its meaning after the key is rebound.
  @override
  Word get currentWord =>
      Word.parse(_game.historyStr()).expanded(_macroWords);

  /// The element played since the solve began: start⁻¹ · current. This is
  /// exactly what mathieu_set_macro would store, so what the sheet shows and
  /// what the key will do cannot disagree.
  List<int> get _playedElement => compose(inversePerm(_game.start()), _currArr);

  /// Set key [c] to the word just played — or, on an empty history, erase it —
  /// and drop any library binding the key carried, since it no longer holds
  /// that entry.
  Future<void> _commitMacroSet(int c, {String? sound}) async {
    _instant(() => _game.setMacro(c), sound: sound);
    _brain.library.unbind(c);
    await _brain.library.save();
    if (mounted) setState(() {});
  }

  /// Long-press on a macro key. Replaces the old bare confirm dialog: it shows
  /// what the key means (or would come to mean) before you commit to it.
  Future<void> _macroSet(int c) async {
    final letter = String.fromCharCode(c);
    final defined = _game.macroDefined(c);
    final playedNothing = _game.historyLength == 0;

    // The Confirm preference means "do it, don't stop to ask me". The sheet is
    // a stop — a more useful one than the yes/no dialog it replaced, but a stop
    // all the same. With Confirm off a long-press still defines the key in one
    // gesture, which is exactly what that switch has always bought.
    if (!_confirm) {
      await _commitMacroSet(c, sound: playedNothing ? null : 'combo_set');
      return;
    }

    // A key's stored word may name another key, so the analysis needs the map
    // to price it. currentWord is already expanded, so `pending` does not.
    final existing = defined
        ? MacroAnalysis.of(_game.macroPermutation(c) ?? identityPerm(),
            word: Word.parse(_game.macroWord(c)),
            table: _brain.table,
            macros: _macroWords)
        : null;
    final pending = playedNothing
        ? null
        : MacroAnalysis.of(_playedElement,
            word: currentWord, table: _brain.table);

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Key $letter',
                style: const TextStyle(
                    color: Colors.black, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              defined
                  ? 'What $letter means right now:'
                  : '$letter is not defined yet.',
              style: kSubtleStyle,
            ),
            const SizedBox(height: 12),
            if (existing != null) AnalysisCard(existing),
            if (existing != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 8, children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, 'step'),
                    child: const Text('Step through it'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, 'save'),
                    child: const Text('Save to library'),
                  ),
                ]),
              ),
            if (pending != null) ...[
              Section(
                title: defined ? 'Redefine it as what you just played' : 'Define it',
                note: 'A macro records the moves, not the position you played '
                    'them from — so this is your sequence, not the scramble.',
                child: AnalysisCard(pending, showRing: existing == null),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, 'set'),
                child: Text(defined ? 'Redefine $letter' : 'Define $letter'),
              ),
            ] else if (defined) ...[
              const Divider(height: 32),
              Text(
                'Play some moves on the board and long-press $letter again to '
                'redefine it.',
                style: kSubtleStyle,
              ),
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(sheetContext, 'erase'),
                child: Text('Erase $letter'),
              ),
            ],
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;
    switch (choice) {
      case 'set':
        await _commitMacroSet(c, sound: 'combo_set');
        break;
      case 'erase':
        await _commitMacroSet(c); // empty history => erase
        break;
      case 'step':
        await playWord(Word.parse(_game.macroWord(c)),
            label: 'Key $letter',
            highlight: supportOf(_game.macroPermutation(c) ?? identityPerm()).toSet(),
            stepped: true);
        break;
      case 'save':
        final w = Word.parse(_game.macroWord(c));
        if (!mounted) return;
        final name = await promptForName(context, 'Key $letter');
        if (name == null) return;
        final e = await _brain.save(
            name: name, word: w, origin: 'from key $letter');
        _brain.library.bind(c, e.id);
        await _brain.library.save();
        break;
    }
    if (mounted) setState(() {});
  }

  void _toggleAlt() => setState(() => _alt = !_alt);

  // History display: the engine writes an inverse macro as a lowercase letter
  // (a..e); show it as A⁻¹..E⁻¹ (capital + superscript), like the buttons.
  String _histDisplay() {
    final raw = _game.historyStr();
    final sb = StringBuffer();
    for (final unit in raw.codeUnits) {
      if (unit >= 0x61 && unit <= 0x65) {
        sb.write(String.fromCharCode(unit - 0x20)); // a..e -> A..E
        sb.write('⁻¹'); // ⁻¹
      } else {
        sb.writeCharCode(unit);
      }
    }
    return sb.toString();
  }

  Future<bool> _ask(String title, String msg) async {
    if (!_confirm) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('OK')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _shake() async {
    _sfx('shake');
    if (_confirm && _solving &&
        !await _ask('Shake!', 'This will create a new Sporadic M12 puzzle.')) return;
    _animatedMove(_game.random, null, MoveKind.big);
    _solving = true;
    _notedSuccess = false; // a fresh puzzle can be applauded once
  }

  Future<void> _home() async {
    _sfx('home');
    if (_confirm && _solving &&
        !await _ask('Home!', 'This will reset Sporadic M12 to the home position.')) return;
    _animatedMove(_game.reset, null, MoveKind.big);
    _solving = false;
  }

  Future<void> _restart() async {
    _sfx('restart');
    if (_confirm && _solving &&
        !await _ask('Restart!', 'This will restart solving this puzzle.')) return;
    _animatedMove(_game.revert, null, MoveKind.big);
  }

  void _shakeOrRestart() {
    if (_alt) {
      _restart();
    } else {
      _shake();
    }
  }

  void _undo() => _animatedMove(() => _game.undo(move: !_alt), null, MoveKind.undo, success: true);

  void _selectSwap(int i) {
    MathieuEngine.swapIndex = i;
    _stopReplay();
    _instant(() {
      _game.reset();
      _game.eraseAllMacros();
      _recomputeColors();
      _solving = false;
    });
    // Distances, diameters and cheapest words all belong to the swap; none of
    // what we computed for the old one is true any more.
    _brain.library.bindings.clear();
    _brain.library.save();
    _brain.onSwapChanged();
    _brain.ensureTable();
  }

  // --- step-through replay --------------------------------------------------

  /// Play one history element — a swap, or a run of [e] wedges — as one move.
  void _playElement(int e) {
    if (e == 0) {
      _animatedMove(_game.swap, 'swap', MoveKind.swap, success: true);
    } else if (e > 0) {
      _animatedMove(() => _game.right(e), 'right', MoveKind.rotate,
          success: true, arc: true);
    } else {
      _animatedMove(() => _game.left(-e), 'left', MoveKind.rotate,
          success: true, arc: true);
    }
  }

  int _stepDurationMs(int e) {
    final kind = e == 0 ? MoveKind.swap : MoveKind.rotate;
    return (_skin.motion.durationMs(kind) / _animSpeed).round().clamp(1, 4000);
  }

  void _beginReplay(Word w, {required String label, required Set<int> highlight}) {
    setState(() {
      _replaySteps = w.primitiveSteps(macros: _macroWords);
      _replayAt = 0;
      _replayLabel = label;
      _highlight = highlight;
      _replayPlaying = false;
    });
  }

  void _stopReplay() {
    if (_replaySteps == null) return;
    setState(() {
      _replaySteps = null;
      _replayAt = 0;
      _replayPlaying = false;
      _highlight = const <int>{};
    });
  }

  Future<void> _replayOneStep() async {
    final steps = _replaySteps;
    if (steps == null || _replayAt >= steps.length) return;
    final e = steps[_replayAt];
    _playElement(e);
    setState(() => _replayAt++);
    await Future<void>.delayed(Duration(milliseconds: _stepDurationMs(e) + 90));
  }

  Future<void> _replayRun() async {
    if (_replayPlaying) {
      setState(() => _replayPlaying = false);
      return;
    }
    setState(() => _replayPlaying = true);
    while (mounted && _replayPlaying) {
      final steps = _replaySteps;
      if (steps == null || _replayAt >= steps.length) break;
      await _replayOneStep();
    }
    if (mounted) setState(() => _replayPlaying = false);
  }

  // --- hint / solve ---------------------------------------------------------

  /// Exact distance home, or null until the map is built.
  int? get _distanceHome => _brain.table?.distanceOf(_currArr);

  void _hint() {
    final t = _brain.table;
    if (t == null) return;
    final mi = t.nextMoveHome(_currArr);
    if (mi == null) return;
    _playElement(moveElement(mi));
  }

  Future<void> _solve() async {
    final t = _brain.table;
    if (t == null) return;
    _beginReplay(t.solutionFrom(_currArr),
        label: 'Solution', highlight: const <int>{});
    await _replayRun();
    if (mounted) _stopReplay();
  }

  Future<void> _openDistanceMenu() async {
    if (_brain.table == null) return;
    final pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text('${_distanceHome ?? 0} moves from home', style: kLabelStyle),
            subtitle: Text(
                'Exact, from the map of all 95,040 positions.', style: kSubtleStyle),
          ),
          const Divider(height: 1),
          ListTile(
              title: const Text('Show me one move'),
              onTap: () => Navigator.pop(c, 'hint')),
          ListTile(
              title: const Text('Solve it for me'),
              onTap: () => Navigator.pop(c, 'solve')),
        ]),
      ),
    );
    if (pick == 'hint') _hint();
    if (pick == 'solve') await _solve();
  }

  // --- TutorActions ---------------------------------------------------------

  @override
  MathieuEngine get game => _game;
  @override
  M12Brain get brain => _brain;
  @override
  Skin get skin => _skin;
  @override
  List<int> get arrangement => _currArr;
  @override
  bool get isSolving => _solving;

  @override
  Future<void> playWord(
    Word word, {
    String label = '',
    Set<int> highlight = const <int>{},
    bool stepped = false,
  }) async {
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (word.isEmpty) return;
    if (stepped) {
      _beginReplay(word, label: label, highlight: highlight);
      await _replayRun();
      return;
    }
    setState(() => _highlight = highlight);
    _animatedMove(() {
      for (final e in word.primitiveSteps(macros: _macroWords)) {
        if (e == 0) {
          _game.swap();
        } else if (e > 0) {
          _game.right(e);
        } else {
          _game.left(-e);
        }
      }
    }, 'combo', MoveKind.macro, success: true);
    // Hold the call-out just long enough to see what moved, then clear it.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _highlight = const <int>{});
  }

  @override
  Future<void> runSlot(int slot, {bool inverted = false}) async {
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (!_game.macroDefined(slot)) return;
    _animatedMove(() => _game.runMacro(slot, inverted: inverted), 'combo',
        MoveKind.macro,
        success: true);
  }

  @override
  Future<void> bindSlot(int slot, MacroEntry entry) => _brain.bind(_game, slot, entry);

  @override
  Future<void> unbindSlot(int slot) => _brain.unbind(_game, slot);

  @override
  Future<void> goHome() async {
    Navigator.of(context).popUntil((r) => r.isFirst);
    _stopReplay();
    _animatedMove(_game.reset, null, MoveKind.big);
    _solving = false;
  }

  @override
  Future<void> scrambleToDistance(int moves) async {
    final t = await _brain.ensureTable();
    if (t == null || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    final want = moves.clamp(0, t.diameter);
    // Pick uniformly among the positions at exactly that distance.
    final candidates = <int>[];
    for (var r = 0; r < t.dist.length; r++) {
      if (t.dist[r] == want) candidates.add(r);
    }
    if (candidates.isEmpty) return;
    final rank = candidates[math.Random().nextInt(candidates.length)];
    _stopReplay();
    _animatedMove(() => _game.setPosition(t.permAt(rank)), 'shake', MoveKind.big);
    _solving = true;
    _notedSuccess = false;
  }

  /// The transport that appears while a macro is being walked through.
  Widget _replayBar() {
    final steps = _replaySteps!;
    final done = _replayAt >= steps.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _skin.palette.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Expanded(
          child: Text(
            '${_replayLabel.isEmpty ? 'Replay' : _replayLabel}  '
            '$_replayAt/${steps.length}',
            style: TextStyle(color: _skin.palette.accent, fontSize: 13),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(_replayPlaying ? Icons.pause : Icons.play_arrow,
              color: _skin.palette.chrome),
          onPressed: done ? null : _replayRun,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.skip_next, color: _skin.palette.chrome),
          onPressed: done || _replayPlaying ? null : _replayOneStep,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close, color: _skin.palette.chromeDim),
          onPressed: _stopReplay,
        ),
      ]),
    );
  }

  Future<void> _openTutor() async {
    await Navigator.of(context).push(_flipRoute(
        _skin.palette.board, TutorHubPage(actions: this)));
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(_flipRoute(_skin.palette.board, _SettingsPage(
      skin: _skin,
      onSkinSelected: widget.onSkinSelected,
      confirm: _confirm,
      sound: _sound,
      animSpeed: _animSpeed,
      n: _n,
      onConfirm: (v) => setState(() => _confirm = v),
      onSound: (v) => setState(() {
        _sound = v;
        Sfx.enabled = v;
      }),
      onAnimSpeed: (v) => setState(() => _animSpeed = v),
      onSwapSelected: _selectSwap,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _skin.palette.board,
        elevation: 0,
        title: const Text('Sporadic M12'),
        actions: [
          IconButton(
            tooltip: 'Learn',
            icon: const Icon(Icons.school_outlined),
            onPressed: _openTutor,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.flip),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TopButton(_alt ? 'Restart' : 'Shake', _shakeOrRestart, _skin.palette.chrome),
                _TopButton('Home', _home, _skin.palette.chrome),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, _) => BallRing(
                skin: _skin,
                prevArrangement: _prevArr,
                arrangement: _currArr,
                t: _t.value,
                arc: _arc,
                colorOfBall: _colorOfBall,
                highlight: _highlight,
                onLeft: _left,
                onRight: _right,
                onSwap: _swap,
                onRotateDrag: _rotateDrag,
              ),
            ),
          ),
          if (_replaySteps != null) _replayBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // moves / steps, and — once the group map exists — the exact
                // distance home. Tapping it offers a hint or a full solve.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openDistanceMenu,
                  child: SizedBox(
                    width: 36,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_game.moves}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        Text('${_game.steps}',
                            style: const TextStyle(fontSize: 12, color: Colors.white38)),
                        // Distance from home, once a table exists. Suppressed
                        // at zero: on a solved board it would read "▸0", which
                        // says nothing the board is not already saying, and it
                        // would put a third line of chrome on the default
                        // screen at rest where the original app had two.
                        if ((_distanceHome ?? 0) > 0)
                          Text('▸$_distanceHome',
                              style: TextStyle(
                                  fontSize: 12, color: _skin.palette.accent)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _histDisplay(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                        fontSize: 14,
                        letterSpacing: -0.5),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _undo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(_alt ? 'Step' : 'Undo',
                        style: TextStyle(color: _skin.palette.chrome, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in const [65, 66, 67, 68, 69])
                  _MacroKey(
                    palette: _skin.palette,
                    label: String.fromCharCode(c),
                    bright: _game.macroDefined(c),
                    onTap: () => _macroTap(c),
                    onLongPress: () => _macroSet(c),
                  ),
                const SizedBox(width: 12),
                _MacroKey(
                    palette: _skin.palette,
                    label: 'Alt',
                    bright: true,
                    armed: _alt,
                    onTap: _toggleAlt),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Image.asset('assets/images/sporadic_games_logo.png', height: 22),
          ),
        ],
          ),
          if (_showBuildTell)
            Positioned(
              top: 2,
              right: 8,
              child: IgnorePointer(
                child: Text(
                  _buildTell,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: Colors.amber.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}



class _TopButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _TopButton(this.label, this.onTap, this.color);
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, style: TextStyle(color: color, fontSize: 17)),
        ),
      );
}

class _MacroKey extends StatelessWidget {
  final SkinPalette palette;
  final String label;
  final bool bright; // defined (A-E) or enabled
  final bool armed; // Alt armed -> gold
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _MacroKey({
    required this.palette,
    required this.label,
    required this.bright,
    this.armed = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = armed
        ? palette.accent
        : (bright ? palette.chrome : palette.chromeDim);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
    );
  }
}

// A horizontal-flip page transition, evoking the original "flip to the back".
// [board] is the skin's board colour, painted on the front face mid-flip.
Route<T> _flipRoute<T>(Color board, Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (context, animation, secondary) => page,
    transitionsBuilder: (context, anim, secondary, child) {
      final rotate =
          Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut));
      return AnimatedBuilder(
        animation: rotate,
        builder: (context, _) {
          final t = rotate.value;
          final showFront = t > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(t * math.pi),
            child: showFront
                ? ColoredBox(color: board, child: const SizedBox.expand())
                : child,
          );
        },
      );
    },
  );
}

/// The "back of the game": settings (white), reached by a flip. Shows the
/// current swap permutation (cycle notation) with an info button to the full
/// selector, plus Confirmation, Sound Effects and Animation Speed.
class _SettingsPage extends StatefulWidget {
  final Skin skin;
  final ValueChanged<String> onSkinSelected;
  final bool confirm, sound;
  final double animSpeed;
  final int n;
  final ValueChanged<bool> onConfirm, onSound;
  final ValueChanged<double> onAnimSpeed;
  final ValueChanged<int> onSwapSelected;
  const _SettingsPage({
    required this.skin,
    required this.onSkinSelected,
    required this.confirm,
    required this.sound,
    required this.animSpeed,
    required this.n,
    required this.onConfirm,
    required this.onSound,
    required this.onAnimSpeed,
    required this.onSwapSelected,
  });
  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  late bool _confirm = widget.confirm;
  late bool _sound = widget.sound;
  late double _animSpeed = widget.animSpeed;
  late int _swapIndex = MathieuEngine.swapIndex;
  late String _skinId = widget.skin.id;

  // The page was pushed with one skin; picking another must redraw the preview
  // here and now, not only after a flip back and forth.
  Skin get _skin => SkinRegistry.get(_skinId);

  @override
  Widget build(BuildContext context) {
    final cycles = _SwapSelectorPage.cycles(MathieuEngine.swapPermutationAt(_swapIndex, widget.n));
    const labelStyle = TextStyle(color: Colors.black87, fontSize: 17);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        foregroundColor: Colors.blue,
        centerTitle: true,
        title: const Text('M₁₂', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          const Center(child: Text('Current Swap Permutation', style: labelStyle)),
          const SizedBox(height: 10),
          // preview: the home ring coloured by this swap permutation
          Center(
            child: SwapPreview(_skin,
                colorIndicesFor(MathieuEngine.swapPermutationAt(_swapIndex, widget.n))),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: cycleLabel(cycles)),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _SwapSelectorPage(
                      current: _swapIndex,
                      n: widget.n,
                      onSelected: (i) {
                        setState(() => _swapIndex = i);
                        widget.onSwapSelected(i);
                      },
                    ),
                  ));
                },
              ),
            ],
          ),
          const Divider(height: 36),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirmation', style: labelStyle),
                    SizedBox(height: 4),
                    Text(
                      'When solving, confirm Shake, Restart and Home. '
                      'Confirm combo set or erase of a previously-set combo.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _confirm,
                onChanged: (v) {
                  setState(() => _confirm = v);
                  widget.onConfirm(v);
                },
              ),
            ],
          ),
          const Divider(height: 36),
          Row(
            children: [
              const Expanded(child: Text('Sound Effects', style: labelStyle)),
              Switch(
                value: _sound,
                onChanged: (v) {
                  setState(() => _sound = v);
                  widget.onSound(v);
                },
              ),
            ],
          ),
          // Skin picker. Only registered packs are listed, so a build with no
          // device packs enabled shows just the default — and cannot hint that
          // any other exists.
          if (SkinRegistry.ids.length > 1) ...[
            const Divider(height: 36),
            const Text('Skin', style: labelStyle),
            for (final id in SkinRegistry.ids)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                selected: id == _skinId,
                leading: id == _skinId
                    ? const Icon(Icons.check, color: Colors.black87)
                    : const SizedBox(width: 24),
                title: Text(SkinRegistry.get(id).displayName, style: labelStyle),
                onTap: () {
                  setState(() => _skinId = id);
                  widget.onSkinSelected(id);
                },
              ),
          ],
          const Divider(height: 36),
          const Text('Animation Speed', style: labelStyle),
          Slider(
            value: _animSpeed,
            min: 0.3,
            max: 2.5,
            onChanged: (v) {
              setState(() => _animSpeed = v);
              widget.onAnimSpeed(v);
            },
          ),
          const SizedBox(height: 24),
          const Text('Sporadic M12 2.1.0',
              style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}

/// The "back of the game": the swap-permutation selector.
class _SwapSelectorPage extends StatelessWidget {
  final int current;
  final int n;
  final ValueChanged<int> onSelected;
  const _SwapSelectorPage(
      {required this.current, required this.n, required this.onSelected});

  static String cycles(List<int> perm) {
    final seen = List<bool>.filled(perm.length, false);
    final parts = <String>[];
    for (var i = 0; i < perm.length; i++) {
      if (seen[i] || perm[i] == i) {
        seen[i] = true;
        continue;
      }
      final cyc = <int>[];
      var j = i;
      while (!seen[j]) {
        seen[j] = true;
        cyc.add(j);
        j = perm[j];
      }
      if (cyc.length > 1) parts.add('(${cyc.join(" ")})');
    }
    return parts.isEmpty ? '(identity)' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final count = MathieuEngine.swapCount;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        foregroundColor: Colors.black,
        title: const Text('Swap Permutation'),
      ),
      body: Scrollbar(
        child: ListView.builder(
          itemCount: count,
          itemBuilder: (context, i) {
            final perm = MathieuEngine.swapPermutationAt(i, n);
            final diff = MathieuEngine.swapDifficulty(i);
            final sel = i == current;
            return ListTile(
              dense: true,
              selected: sel,
              selectedTileColor: const Color(0x33000000),
              leading: sel
                  ? const Icon(Icons.check, color: Colors.black87)
                  : const SizedBox(width: 24),
              title: Text('#${i + 1}    ${cycles(perm)}',
                  style: const TextStyle(color: Colors.black87, fontFamily: 'monospace')),
              subtitle: Text('difficulty $diff',
                  style: const TextStyle(color: Colors.black54)),
              onTap: () {
                onSelected(i);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}


// Cycle notation with smaller parentheses, e.g. ((0 1) (2 3) ...).
Widget cycleLabel(String s) {
  final spans = <TextSpan>[];
  for (final ch in s.split('')) {
    final paren = ch == '(' || ch == ')';
    spans.add(TextSpan(
      text: ch,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w500,
        fontSize: paren ? 13 : 19,
      ),
    ));
  }
  return RichText(textAlign: TextAlign.center, text: TextSpan(children: spans));
}

