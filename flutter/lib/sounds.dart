import 'package:audioplayers/audioplayers.dart';

/// Preloaded sound effects, ported from the iOS app's SoundEffect set.
/// WAV masters (universal) live in assets/sounds/.
class Sfx {
  static final Map<String, AudioPlayer> _players = {};
  static bool enabled = true;

  static const names = [
    'left', 'right', 'swap', 'shake', 'applause', 'restart', 'combo', 'combo_set'
  ];

  static Future<void> init() async {
    for (final n in names) {
      try {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource('sounds/$n.wav'));
        _players[n] = p;
      } catch (_) {
        // a missing/unsupported sound shouldn't break the game
      }
    }
  }

  static void play(String name) {
    if (!enabled) return;
    final p = _players[name];
    if (p == null) return;
    p.seek(Duration.zero);
    p.resume();
  }
}
