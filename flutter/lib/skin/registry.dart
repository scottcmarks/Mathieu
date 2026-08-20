import 'package:flutter/foundation.dart';
import 'skin.dart';

typedef SkinBuilder = Skin Function();

/// The pack table. `registerBuiltinSkins()` in registry_packs.g.dart fills it at
/// startup: 'default' first and unconditionally, then any private pack that is
/// both present in the tree and enabled by its build-time flag.
class SkinRegistry {
  SkinRegistry._();

  static const defaultId = 'default';

  static final Map<String, SkinBuilder> _packs = <String, SkinBuilder>{};

  static void register(String id, SkinBuilder build) => _packs[id] = build;

  @visibleForTesting
  static void debugReset() => _packs.clear();

  static bool has(String id) => _packs.containsKey(id);

  /// Registration order: 'default' is always first.
  static List<String> get ids => List<String>.unmodifiable(_packs.keys);

  /// An unknown or unregistered id falls back to the default pack *silently* —
  /// a booklet QR printed for a gated pack must neither error nor reveal that
  /// the pack exists. That is part of the gate, not just politeness.
  static Skin get(String? id) => (_packs[id] ?? _packs[defaultId]!)();

  /// Disclosure belt #3: in a build with no pack gate set, nothing sensitive may
  /// have made it into the table. Debug-only; the real belts are the compile-time
  /// flag (tree-shaking) and tool/check_no_device_skins.sh.
  static void debugAssertNothingSensitive() {
    assert(() {
      for (final id in ids) {
        if (get(id).sensitive) {
          throw FlutterError(
              'Skin pack "$id" is device-derived (sensitive) but was registered '
              'in a build with no pack gate set. See lib/skin/README.md.');
        }
      }
      return true;
    }());
  }
}
