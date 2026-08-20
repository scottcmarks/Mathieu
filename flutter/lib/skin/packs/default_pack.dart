// The default skin: today's appearance, unchanged. This pack ships in every
// build, unconditionally, and is the fallback for any unknown skin id.
//
// Every number here was lifted verbatim from the pre-skin main.dart (itself a
// port of Apple/DeviceIndependent's BallRingView.mm / BallView.mm). Changing
// one changes the shipped look; test/ball_ring_golden_test.dart holds the
// pre-refactor pixels and will fail if any of them drift.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../skin.dart';

/// Ball palette, matching the iOS app's BALL_COLORS order.
const kDefaultPieceColors = <Color>[
  Color(0xFFFFFFFF), // white
  Color(0xFF77AAFF), // light azure blue
  Color(0xFFFF9933), // light hard orange
  Color(0xFFFFFF00), // yellow
  Color(0xFF00CC00), // dark hard green
  Color(0xFFFF0000), // red
];

/// The 2.0.6 marble: dark (0.6x) rim brightening to a highlight 1/4 from the top.
ui.Gradient marbleShader(Color color, Offset center, double r) {
  final dark = Color.lerp(color, Colors.black, 0.4)!;
  return ui.Gradient.radial(
    center,
    r,
    [color, dark, dark.withValues(alpha: 0)],
    [0.0, 0.95, 1.0],
    TileMode.clamp,
    null,
    Offset(center.dx, center.dy - 0.75 * r),
    0.0,
  );
}

class _DefaultPainter extends SkinPainter {
  const _DefaultPainter();

  // The original iOS marble, ported from BallView.mm's CGContextDrawRadialGradient.
  @override
  void paintPiece(Canvas canvas, Offset center, double r, Color color, int seat) {
    canvas.drawCircle(center, r, Paint()..shader = marbleShader(color, center, r));
  }

  // A halo round the seats a replayed macro will disturb. Ordinary play never
  // sets anim.highlight, so this paints nothing and the shipped look is
  // untouched — which is what the goldens check.
  @override
  void paintOverlay(Canvas canvas, BoardMetrics m, SkinPalette p, MoveAnim anim) {
    if (anim.highlight.isEmpty) return;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, m.pieceR * 0.14)
      ..color = p.accent.withValues(alpha: 0.85);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, m.pieceR * 0.30)
      ..color = p.accent.withValues(alpha: 0.18);
    for (final seat in anim.highlight) {
      if (seat < 0 || seat >= m.n) continue;
      final c = m.spunSeat(seat);
      canvas.drawCircle(c, m.pieceR * 1.22, glow);
      canvas.drawCircle(c, m.pieceR * 1.22, ring);
    }
  }

  @override
  TextStyle numeralStyle(BoardMetrics m, SkinPalette p) => TextStyle(
        color: p.numeral,
        fontSize: m.numeralFont,
        fontWeight: FontWeight.bold,
      );

  @override
  TextStyle seatTagStyle(BoardMetrics m, SkinPalette p) =>
      TextStyle(color: p.seatTag, fontSize: m.tagFont);
}

class _DefaultMotion extends SkinMotion {
  const _DefaultMotion();

  // Move durations (ms), echoing the legacy SMALL/LARGE_MOVE_DURATION feel.
  @override
  int get rotateMs => 170;
  @override
  int get swapMs => 460;
  @override
  int get macroMs => 460;
  @override
  int get undoMs => 220;
  @override
  int get bigMs => 460;

  @override
  Curve curve(MoveKind kind) => Curves.easeInOut;

  /// The coloured spheres are static furniture; the numbers are what animate.
  @override
  bool get piecesTravel => false;

  @override
  Offset markPath(BoardMetrics m, int from, int to, double t, {required bool arc}) {
    if (from == to || t >= 1.0) return m.spunSeat(to);
    if (arc && from >= 1 && to >= 1) {
      // rotations spin the marks along the ring, by the shorter way round
      final a0 = m.angle(from);
      var da = m.angle(to) - a0;
      while (da > math.pi) {
        da -= 2 * math.pi;
      }
      while (da < -math.pi) {
        da += 2 * math.pi;
      }
      return m.onRing(a0 + da * t);
    }
    return Offset.lerp(m.seat(from), m.seat(to), t)!; // straight line
  }
}

class DefaultSkin extends Skin {
  const DefaultSkin();

  @override
  String get id => 'default';
  @override
  String get displayName => 'Classic';
  @override
  bool get sensitive => false;

  @override
  SkinVocabulary get vocab => const SkinVocabulary();

  @override
  SkinPalette get palette => const SkinPalette(
        // The game plays on black, like the 2.0.6 app.
        board: Color(0xFF000000),
        pieces: kDefaultPieceColors,
        numeral: Colors.black,
        seatTag: Colors.white38,
        chrome: Colors.white,
        chromeDim: Colors.white30,
        accent: Color(0xFFFFC23D),
      );

  @override
  SkinGeometry get geometry => const SkinGeometry();

  @override
  SkinPainter get painter => const _DefaultPainter();

  @override
  SkinMotion get motion => const _DefaultMotion();

  @override
  SkinSound get sound => const SkinSound();
}

/// Every pack file exposes this one entry point; the generated registry calls it.
Skin buildSkin() => const DefaultSkin();
