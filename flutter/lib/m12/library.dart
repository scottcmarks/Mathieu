// The macro library.
//
// The engine has exactly five macro slots, A..E, baked into the History
// encoding (m.h:204). That is a hard limit and not worth fighting. So the model
// here is:
//
//     the LIBRARY is unbounded and lives in Dart;
//     A..E are five BOUND REGISTERS.
//
// "Bind to B" means: replay the entry's word on a scratch engine handle, then
// hand that handle to mathieu_set_macro_from. Unbinding is mathieu_erase_macro.
//
// Every entry records the swap index it was built under, because a macro is
// simply a different element under a different swap — TODO.txt already worried
// "Keep 341 sets of macros around for each swap? It would be hard to remember
// what they are for!". The answer is: keep one library, stamp each entry, grey
// out the ones from another swap, and offer to re-derive them.

import 'dart:convert';

import '../prefs.dart';
import 'perm.dart';
import 'table.dart';
import 'word.dart';

/// The five engine slots, as history-element codes.
const List<int> kMacroSlots = [kMacroA, kMacroA + 1, kMacroA + 2, kMacroA + 3, kMacroE];

String slotLabel(int code) => String.fromCharCode(code);

/// One saved macro.
class MacroEntry {
  final String id;
  final String name;

  /// The canonical word. This — not the permutation — is the truth, because a
  /// word is what you can replay, bind and teach.
  final Word word;

  /// Which swap permutation the word was written under.
  final int swapIndex;

  /// A short note on where it came from ("commutator of Alpha and Beta").
  final String origin;

  final DateTime created;

  MacroEntry({
    required this.id,
    required this.name,
    required this.word,
    required this.swapIndex,
    this.origin = '',
    DateTime? created,
  }) : created = created ?? DateTime.now();

  MacroEntry copyWith({String? name, Word? word, String? origin}) => MacroEntry(
        id: id,
        name: name ?? this.name,
        word: word ?? this.word,
        swapIndex: swapIndex,
        origin: origin ?? this.origin,
        created: created,
      );

  /// The element this word applies under [swap].
  List<int> permutationUnder(List<int> swap) => word.permutation(swap: swap);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'word': word.compact,
        'swap': swapIndex,
        'origin': origin,
        'created': created.toIso8601String(),
      };

  /// Tolerant of anything: a corrupt entry is dropped, never thrown.
  static MacroEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    final name = j['name'];
    final w = j['word'];
    final s = j['swap'];
    if (id is! String || name is! String || w is! String || s is! int) return null;
    return MacroEntry(
      id: id,
      name: name,
      word: Word.parse(w),
      swapIndex: s,
      origin: j['origin'] is String ? j['origin'] as String : '',
      created: DateTime.tryParse('${j['created']}') ?? DateTime.now(),
    );
  }
}

/// The library plus the five bindings, persisted together.
class MacroLibrary {
  final List<MacroEntry> entries = <MacroEntry>[];

  /// slot code (65..69) -> entry id, for whatever is currently bound.
  final Map<int, String> bindings = <int, String>{};

  var _seq = 0;

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  MacroEntry? byId(String? id) {
    if (id == null) return null;
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  MacroEntry? boundTo(int slot) => byId(bindings[slot]);

  int? slotOf(String id) {
    for (final e in bindings.entries) {
      if (e.value == id) return e.key;
    }
    return null;
  }

  /// Entries written under [swapIndex] first, then the rest.
  List<MacroEntry> sortedFor(int swapIndex) {
    final mine = entries.where((e) => e.swapIndex == swapIndex).toList();
    final other = entries.where((e) => e.swapIndex != swapIndex).toList();
    int byDate(MacroEntry a, MacroEntry b) => b.created.compareTo(a.created);
    mine.sort(byDate);
    other.sort(byDate);
    return [...mine, ...other];
  }

  /// A name that is not already taken, e.g. "Triple" / "Triple 2".
  String uniqueName(String base) {
    final taken = entries.map((e) => e.name).toSet();
    if (!taken.contains(base)) return base;
    for (var i = 2;; i++) {
      final n = '$base $i';
      if (!taken.contains(n)) return n;
    }
  }

  MacroEntry add({
    required String name,
    required Word word,
    required int swapIndex,
    String origin = '',
  }) {
    final e = MacroEntry(
      id: _newId(),
      name: uniqueName(name.trim().isEmpty ? 'Untitled' : name.trim()),
      word: word,
      swapIndex: swapIndex,
      origin: origin,
    );
    entries.insert(0, e);
    return e;
  }

  void replace(MacroEntry e) {
    final i = entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) entries[i] = e;
  }

  void remove(String id) {
    entries.removeWhere((e) => e.id == id);
    bindings.removeWhere((_, v) => v == id);
  }

  void bind(int slot, String id) {
    bindings.removeWhere((_, v) => v == id); // an entry occupies one slot
    bindings[slot] = id;
  }

  void unbind(int slot) => bindings.remove(slot);

  /// Re-derive [e] under [table]'s swap: find the cheapest word for an element
  /// of the same cycle type acting on the same seats. Returns null if there is
  /// no such element (there always is, but the caller must not assume).
  MacroEntry? rederive(MacroEntry e, M12Table table, List<int> oldSwap) {
    final oldPerm = e.word.permutation(swap: oldSwap);
    if (isIdentityPerm(oldPerm)) return null;
    final wantType = cycleType(oldPerm);
    final wantSupport = supportOf(oldPerm).toSet();

    var bestRank = -1;
    var bestDist = 1 << 30;
    for (var r = 0; r < table.dist.length; r++) {
      final d = table.dist[r];
      if (d >= bestDist || d == 0) continue;
      final base = r * kBalls;
      var supp = 0;
      var ok = true;
      for (var i = 0; i < kBalls; i++) {
        final moved = table.perms[base + i] != i;
        if (moved) supp++;
        if (moved != wantSupport.contains(i)) {
          ok = false;
          break;
        }
      }
      if (!ok || supp != wantSupport.length) continue;
      final p = table.permAt(r);
      if (!_sameType(cycleType(p), wantType)) continue;
      bestDist = d;
      bestRank = r;
    }
    if (bestRank < 0) return null;
    return MacroEntry(
      id: _newId(),
      name: uniqueName('${e.name} (swap ${table.swapIndex + 1})'),
      word: table.wordTo(bestRank),
      swapIndex: table.swapIndex,
      origin: 're-derived from "${e.name}" under swap #${table.swapIndex + 1}',
    );
  }

  static bool _sameType(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // --- persistence ----------------------------------------------------------

  String encode() => jsonEncode({
        'entries': entries.map((e) => e.toJson()).toList(),
        'bindings': bindings.map((k, v) => MapEntry('$k', v)),
      });

  /// Every failure path here degrades to an empty library. A corrupt store must
  /// never keep the app from starting.
  void decode(String? source) {
    entries.clear();
    bindings.clear();
    if (source == null || source.isEmpty) return;
    Object? j;
    try {
      j = jsonDecode(source);
    } catch (_) {
      return;
    }
    if (j is! Map) return;
    final es = j['entries'];
    if (es is List) {
      for (final raw in es) {
        final e = MacroEntry.fromJson(raw);
        if (e != null) entries.add(e);
      }
    }
    final bs = j['bindings'];
    if (bs is Map) {
      bs.forEach((k, v) {
        final slot = int.tryParse('$k');
        if (slot != null && v is String && byId(v) != null) bindings[slot] = v;
      });
    }
  }

  Future<void> save() => Prefs.setString(Prefs.libraryKey, encode());

  void load() => decode(Prefs.getString(Prefs.libraryKey));
}
