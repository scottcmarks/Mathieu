// The app's persisted state: the chosen skin, the macro library and which
// library entries are bound to the five engine keys. Everything else — sound,
// confirmation, animation speed, the swap selection — still resets on launch,
// as it always has.
//
// Every access is guarded: a missing plugin or a corrupt store must degrade to
// "no preference", never keep the app from starting.

import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  Prefs._();

  static const _skinKey = 'skin_id';
  static const libraryKey = 'macro_library_v1';
  static const bindingsKey = 'macro_bindings_v1';

  static SharedPreferences? _p;

  static Future<void> init() async {
    try {
      _p = await SharedPreferences.getInstance();
    } catch (_) {
      _p = null;
    }
  }

  static String? get skinId {
    try {
      return _p?.getString(_skinKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setSkinId(String id) async => setString(_skinKey, id);

  static String? getString(String key) {
    try {
      return _p?.getString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setString(String key, String value) async {
    try {
      await _p?.setString(key, value);
    } catch (_) {
      // remembering the choice is a nicety; failing to is not an error
    }
  }

  static Future<void> remove(String key) async {
    try {
      await _p?.remove(key);
    } catch (_) {
      // ignore
    }
  }
}
