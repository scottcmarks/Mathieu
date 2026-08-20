// The skin interface: what a pack may change about the way the M12 puzzle looks
// and feels. Six small facets, so a pack author overrides only what differs and
// "look" never drags in "feel".
//
// HARD RULE: a skin supplies appearance, never mechanism. However elaborate a
// device skin's swap animation looks, the engine still executes one atomic
// mathieu_swap(); the path is cosmetic.
//
// See README.md in this directory for pack authoring and the disclosure gate.

import 'package:flutter/widgets.dart';
import 'board_metrics.dart';

export 'board_metrics.dart';

/// The five timings the game distinguishes (legacy _dRotate/_dSwap/... ).
enum MoveKind { rotate, swap, macro, undo, big }

/// The move currently being tweened, for [SkinPainter.paintOverlay].
@immutable
class MoveAnim {
  /// arrangement[i] = piece value at seat i, before and after the move.
  final List<int> from;
  final List<int> to;

  /// 0 at the start of the tween, 1 when it has landed.
  final double t;

  /// True while a rotation is running (marks travel along the ring arc).
  final bool arc;

  /// Seats the tutorial wants called out — during a step-through replay these
  /// are the seats the whole macro will end up disturbing, held for the run so
  /// the point ("watch: only these nine move") is visible throughout. Empty in
  /// ordinary play. The default pack draws a halo; a device pack would light
  /// the lane, pipe or rotor instead.
  final Set<int> highlight;

  const MoveAnim({
    required this.from,
    required this.to,
    required this.t,
    required this.arc,
    this.highlight = const <int>{},
  });

  bool get isMoving => t < 1.0;
}

/// What this machine calls its parts. Consumed by the on-board controls today;
/// the tutorial work (goal B) is the main consumer of the nouns.
@immutable
class SkinVocabulary {
  /// A single playing piece / the plural. ('ball', 'tile', 'marble')
  final String piece;
  final String pieces;

  /// A ring position, and the 12th one that never spins.
  /// ('seat' / 'apex', 'outboard seat', 'pocket')
  final String seat;
  final String outboardSeat;

  /// The board as a whole. ('ring', 'deck', 'necklace')
  final String boardName;

  /// The three on-board control labels.
  final String spinLeft;
  final String spinRight;
  final String swapVerb;

  const SkinVocabulary({
    this.piece = 'ball',
    this.pieces = 'balls',
    this.seat = 'seat',
    this.outboardSeat = 'apex',
    this.boardName = 'ring',
    this.spinLeft = 'Left',
    this.spinRight = 'Right',
    this.swapVerb = 'Swap',
  });
}

/// Every colour the board is painted with.
@immutable
class SkinPalette {
  /// The field the game plays on.
  final Color board;

  /// Piece colours, indexed modulo the list length: each disjoint 2-cycle of the
  /// swap takes the next entry, so a swap pair shares a colour.
  final List<Color> pieces;

  /// The numeral painted on a piece, and an optional outline behind it.
  final Color numeral;
  final Color? numeralOutline;

  /// The fixed "home position" tag beside each seat.
  final Color seatTag;

  /// On-board text: live, dimmed, and armed (the Alt gold).
  final Color chrome;
  final Color chromeDim;
  final Color accent;

  /// Base colour of any board furniture (deck, lanes, pipe). Null = none.
  final Color? deckBase;

  const SkinPalette({
    required this.board,
    required this.pieces,
    required this.numeral,
    this.numeralOutline,
    required this.seatTag,
    required this.chrome,
    required this.chromeDim,
    required this.accent,
    this.deckBase,
  });

  Color pieceColor(int i) => pieces[i % pieces.length];
}

/// The drawing. [paintBoard] and [paintOverlay] are new layers — today's app has
/// no board furniture at all — and default to nothing, so the default skin is
/// unaffected by their existence.
abstract class SkinPainter {
  const SkinPainter();

  /// Furniture beneath everything: deck, lanes, chord pipe, rotor hub.
  void paintBoard(Canvas canvas, BoardMetrics m, SkinPalette p) {}

  /// One playing piece. [center] is in the canvas's own frame; the ring gives
  /// each piece its own 2r box, the preview paints them all on one canvas.
  void paintPiece(Canvas canvas, Offset center, double r, Color color, int seat);

  /// Above the pieces: rotor arms, shutters, step-through highlights.
  void paintOverlay(Canvas canvas, BoardMetrics m, SkinPalette p, MoveAnim anim) {}

  TextStyle numeralStyle(BoardMetrics m, SkinPalette p);
  TextStyle seatTagStyle(BoardMetrics m, SkinPalette p);
}

/// Timing and travel. This is where the four skins genuinely diverge: a marble
/// rolling a chord is not a tile sliding a lane.
abstract class SkinMotion {
  const SkinMotion();

  int get rotateMs;
  int get swapMs;
  int get macroMs;
  int get undoMs;
  int get bigMs;

  int durationMs(MoveKind kind) => switch (kind) {
        MoveKind.rotate => rotateMs,
        MoveKind.swap => swapMs,
        MoveKind.macro => macroMs,
        MoveKind.undo => undoMs,
        MoveKind.big => bigMs,
      };

  Curve curve(MoveKind kind);

  /// False (the default look): the coloured pieces are static furniture and only
  /// the numerals travel. True: the pieces themselves carry their numerals.
  bool get piecesTravel;

  /// Where a piece's travelling mark sits at time [t] on its way from seat
  /// [from] to seat [to]. Cosmetic only — the engine has already made the move.
  Offset markPath(BoardMetrics m, int from, int to, double t, {required bool arc});
}

/// Sound naming. A pack may only remap onto the shared sound set: gated packs
/// must stay asset-free, because pubspec.yaml declares assets/ by directory glob
/// and anything dropped there ships in every build, gate or no gate.
@immutable
class SkinSound {
  final Map<String, String> nameMap;
  const SkinSound({this.nameMap = const {}});
  String resolve(String name) => nameMap[name] ?? name;
}

/// One pack.
abstract class Skin {
  const Skin();

  /// Stable id: the persistence key and the deep-link `#skin=` value.
  String get id;
  String get displayName;

  /// True for the device-derived packs (Flat-Pack, Marbles, Transfer Ring).
  /// Those mechanisms are patent-sensitive and must never ship un-gated;
  /// a debug assert enforces that no sensitive pack is registered in an
  /// un-gated build. See README.md.
  bool get sensitive;

  SkinVocabulary get vocab;
  SkinPalette get palette;
  SkinGeometry get geometry;
  SkinPainter get painter;
  SkinMotion get motion;
  SkinSound get sound;
}
