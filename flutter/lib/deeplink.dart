// One deep-link grammar, two carriers, one parser — so a printed booklet QR can
// never drift from what the app accepts.
//
//   web:     https://magnolia-heights.com/sporadicgames/m12/#skin=<id>&lesson=<n>&swap=<i>&word=<w>
//   mobile:  m12://open?skin=<id>&lesson=<n>&swap=<i>&word=<w>
//
// The web form uses the fragment rather than the query so the static host needs
// no rewrite rules and web/app stays a plain static deploy.
//
// CAVEAT, found the hard way: Flutter web's default hash URL strategy owns the
// fragment and clears it before Dart's main() runs, so `#skin=…` never reaches
// here on its own. web/index.html moves the fragment into the query string with
// history.replaceState before flutter_bootstrap.js loads; the router leaves the
// query alone and a static host still ignores it. That is why fromCurrentUrl()
// accepts either carrier — the printed `#…` URL keeps working.
//
// All four keys are acted on: main() applies `skin` and `swap` before the app
// starts (both are needed before the first frame), and GamePage applies `word`
// and `lesson` on the first frame, once there is a game to replay into and a
// navigator to push a lesson onto.
//
// Resolution is deliberately forgiving, because a printed QR code cannot be
// recalled: an unknown or gated skin degrades SILENTLY to the default (it must
// not reveal that the pack exists), an out-of-range lesson clamps, a swap
// outside 0..340 is ignored, and an unparseable word is dropped.

import 'package:flutter/foundation.dart';

@immutable
class DeepLinkRequest {
  final String? skinId;
  final int? lesson;
  final int? swapIndex;

  /// A word in the generators, e.g. "R3SL2S" — replayed into the game so a
  /// booklet can hand the reader a specific position.
  final String? word;

  const DeepLinkRequest({this.skinId, this.lesson, this.swapIndex, this.word});

  static const empty = DeepLinkRequest();

  bool get isEmpty =>
      skinId == null && lesson == null && swapIndex == null && word == null;

  /// The URL the app was opened with. On the web this is the browser location;
  /// elsewhere Uri.base is the working directory and yields [empty].
  static DeepLinkRequest fromCurrentUrl() {
    try {
      final u = Uri.base;
      return parse(u.fragment.isNotEmpty ? u.fragment : u.query);
    } catch (_) {
      return empty; // a malformed URL must never keep the app from starting
    }
  }

  /// Parses either carrier: a bare `k=v&k=v` string, a `#…`/`?…` fragment, or a
  /// whole `m12://open?…` URI. Unparseable values are dropped, not raised.
  static DeepLinkRequest parse(String? source) {
    if (source == null || source.isEmpty) return empty;
    var s = source;
    if (s.startsWith('m12:')) {
      try {
        final u = Uri.parse(s);
        s = u.query.isNotEmpty ? u.query : u.fragment;
      } catch (_) {
        return empty;
      }
    }
    while (s.startsWith('#') || s.startsWith('?') || s.startsWith('/')) {
      s = s.substring(1);
    }
    if (s.isEmpty) return empty;

    Map<String, String> q;
    try {
      q = Uri.splitQueryString(s);
    } catch (_) {
      return empty;
    }

    final skin = q['skin']?.trim();
    final word = q['word']?.trim().toUpperCase();
    return DeepLinkRequest(
      skinId: (skin == null || skin.isEmpty) ? null : skin,
      lesson: _int(q['lesson']),
      swapIndex: _int(q['swap']),
      word: (word == null || word.isEmpty || !_wordish.hasMatch(word)) ? null : word,
    );
  }

  // L, R, S and the five macro letters, with optional repeat counts.
  static final RegExp _wordish = RegExp(r'^[LRSA-E0-9]+$');

  static int? _int(String? v) => v == null ? null : int.tryParse(v.trim());

  @override
  String toString() =>
      'DeepLinkRequest(skin: $skinId, lesson: $lesson, swap: $swapIndex, word: $word)';
}
