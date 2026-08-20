// The tutorial's brain: owns the BFS table, the macro library, and the bridge
// between a Dart word and one of the engine's five macro registers.
//
// Everything here is keyed by the swap permutation in force. A macro is a
// different element under a different swap, the diameter is different, the
// cheapest words are different — so changing the swap invalidates the table,
// the discovery scan and (in meaning, though not in storage) the library.

import 'package:flutter/foundation.dart';

import '../m12/library.dart';
import '../m12/perm.dart';
import '../m12/search.dart';
import '../m12/table.dart';
import '../m12/word.dart';
import '../mathieu_ffi.dart';

class M12Brain extends ChangeNotifier {
  final MacroLibrary library = MacroLibrary();

  M12Table? _table;
  Future<M12Table?>? _tableJob;
  bool _buildingTable = false;
  Object? _tableError;

  Discovery? _discovery;
  Future<Discovery?>? _discoveryJob;
  bool _discovering = false;

  /// The swap permutation currently in force, as the engine reports it.
  List<int> get swap => MathieuEngine.swapPermutation(kBalls);
  int get swapIndex => MathieuEngine.swapIndex;

  /// Human-facing swap number, 1-based like the selector shows it.
  int get swapNumber => swapIndex + 1;

  /// Any of the 341 swap permutations, without changing the selection — how a
  /// library entry written under another swap is read back.
  List<int> swapPermAt(int index) => MathieuEngine.swapPermutationAt(index, kBalls);

  M12Table? get table => _table;
  bool get isBuildingTable => _buildingTable;
  Object? get tableError => _tableError;

  Discovery? get discovery => _discovery;
  bool get isDiscovering => _discovering;

  void load() {
    library.load();
    notifyListeners();
  }

  /// Drop everything derived from the old swap. Called when the selector changes.
  void onSwapChanged() {
    _table = null;
    _discovery = null;
    _tableJob = null;
    _discoveryJob = null;
    _tableError = null;
    notifyListeners();
  }

  /// Build (or return) the table for the swap in force.
  ///
  /// On native this runs in an isolate. On web `compute` has no isolate to run
  /// in and executes inline, which is exactly why every caller shows a "working"
  /// state around it instead of assuming it is free.
  /// A second caller arriving mid-build waits for the build in flight rather
  /// than being told "not yet" — otherwise a lesson button tapped while the map
  /// is still going up would do nothing at all.
  Future<M12Table?> ensureTable() {
    final want = swapIndex;
    final t = _table;
    if (t != null && t.swapIndex == want) return Future.value(t);
    return _tableJob ??= _buildTable(want);
  }

  Future<M12Table?> _buildTable(int want) async {
    _buildingTable = true;
    _tableError = null;
    notifyListeners();
    try {
      final built = await M12Table.build(want, swap);
      // A swap change while we were away makes the result stale; drop it.
      if (swapIndex == want) _table = built;
    } catch (e) {
      _tableError = e;
    } finally {
      _buildingTable = false;
      _tableJob = null;
      notifyListeners();
    }
    return _table;
  }

  /// Scan the group for the cheapest word in each (support, cycle type) class.
  Future<Discovery?> ensureDiscovery() {
    final d = _discovery;
    if (d != null) return Future.value(d);
    return _discoveryJob ??= _runDiscovery();
  }

  Future<Discovery?> _runDiscovery() async {
    try {
      final t = await ensureTable();
      if (t == null) return null;
      _discovering = true;
      notifyListeners();
      _discovery = await discover(t);
    } finally {
      _discovering = false;
      _discoveryJob = null;
      notifyListeners();
    }
    return _discovery;
  }

  // --- library ↔ engine -----------------------------------------------------

  /// Bind [word] to engine register [slot] on [game].
  ///
  /// The word is replayed on a throwaway handle and handed over with
  /// mathieu_set_macro_from, so the live game's own history is untouched — you
  /// can bind a macro mid-solve without it looking like you played anything.
  ///
  /// [word] is expected to be letter-free: the library stores what currentWord
  /// produced, and that is already expanded, so an entry never names a key
  /// whose meaning could have changed underneath it. A letter that turns up
  /// anyway — a hand-edited or corrupt prefs file — is dropped, not replayed as
  /// a rotation. Passing no macro map is what makes that happen.
  void bindWordToSlot(MathieuEngine game, int slot, Word word) {
    final scratch = MathieuEngine();
    try {
      for (final e in word.primitiveSteps()) {
        if (e == 0) {
          scratch.swap();
        } else if (e > 0) {
          scratch.right(e);
        } else {
          scratch.left(-e);
        }
      }
      game.setMacroFrom(slot, scratch);
    } finally {
      scratch.dispose();
    }
  }

  /// Bind a library entry, recording the binding so it survives a relaunch.
  Future<void> bind(MathieuEngine game, int slot, MacroEntry entry) async {
    bindWordToSlot(game, slot, entry.word);
    library.bind(slot, entry.id);
    await library.save();
    notifyListeners();
  }

  Future<void> unbind(MathieuEngine game, int slot) async {
    game.eraseMacro(slot);
    library.unbind(slot);
    await library.save();
    notifyListeners();
  }

  /// Re-apply the saved bindings to a freshly created engine. Entries written
  /// under another swap are skipped rather than bound to the wrong element.
  void restoreBindings(MathieuEngine game) {
    final here = swapIndex;
    for (final slot in List<int>.of(library.bindings.keys)) {
      final e = library.boundTo(slot);
      if (e == null || e.swapIndex != here) {
        library.unbind(slot);
        continue;
      }
      bindWordToSlot(game, slot, e.word);
    }
  }

  Future<MacroEntry> save({
    required String name,
    required Word word,
    String origin = '',
  }) async {
    final e = library.add(
        name: name, word: word, swapIndex: swapIndex, origin: origin);
    await library.save();
    notifyListeners();
    return e;
  }

  Future<void> rename(MacroEntry e, String name) async {
    library.replace(e.copyWith(name: name.trim().isEmpty ? e.name : name.trim()));
    await library.save();
    notifyListeners();
  }

  Future<void> delete(MathieuEngine game, MacroEntry e) async {
    final slot = library.slotOf(e.id);
    if (slot != null) game.eraseMacro(slot);
    library.remove(e.id);
    await library.save();
    notifyListeners();
  }
}
