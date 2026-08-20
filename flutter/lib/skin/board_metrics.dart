import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// A skin's board layout, expressed as pure ratios against half the board's
/// width so one layout routine serves every screen size *and* every pack.
///
/// The defaults are the numbers BallRingView.mm has always used; the derivation
/// in [BoardMetrics.board] reproduces them expression-for-expression, including
/// the `roundToDouble()` on the piece radius (that rounding is load-bearing —
/// dropping it moves every seat by a fraction of a pixel).
///
/// Every pack so far lands in a narrow band around the default's
/// pieceR/ringR = 0.1375/0.725 = 0.190 with an outboard gap of 2.5 pieces,
/// which is why one layout routine serves them all. A pack states its own
/// ratios in its own file; the measurements a device-derived pack is drawn
/// from are not repeated here — see SKINS.md on the disclosure gate.
@immutable
class SkinGeometry {
  /// Piece radius as a fraction of half the board width (legacy MBallRadiusRatio).
  final double pieceRadiusRatio;

  /// Ring radius = halfWidth - ringInsetPieces * pieceRadius.
  final double ringInsetPieces;

  /// Outboard (apex/pocket) seat sits this many piece-radii beyond the ring.
  final double outboardGapPieces;

  /// Home-position seat tags sit this many piece-radii inside the ring.
  final double seatTagInsetPieces;

  /// The board centre is pushed below the box centre by this many piece-radii
  /// (plus one tag font), leaving room for the outboard seat and its tag.
  final double centerYBiasPieces;

  /// Seat-tag and numeral font sizes, as fractions of the piece radius.
  final double tagFontRatio;
  final double numeralFontRatio;

  /// The settings-page preview has always drawn its numerals slightly larger
  /// than the board does. Kept as its own ratio rather than silently unified,
  /// because unifying them would change today's pixels.
  final double previewNumeralFontRatio;

  /// Seat 1 sits at [startAngle]; seats advance by [direction] * one wedge.
  final double startAngle;
  final double direction;

  /// The centred Swap / Left+Right block. These two are absolute logical pixels,
  /// not piece-radius multiples, because that is what the app has always used
  /// (main.dart's -95 / -44 / 190). Expressing them as ratios changes the layout,
  /// so it is a deliberate follow-up, not something a "pixel-faithful" refactor
  /// can smuggle in. A pack that rescales the ring will want to override them.
  final double controlWidth;
  final double controlTopOffset;

  const SkinGeometry({
    this.pieceRadiusRatio = 0.1375,
    this.ringInsetPieces = 2.0,
    this.outboardGapPieces = 2.5,
    this.seatTagInsetPieces = 1.5,
    this.centerYBiasPieces = 0.5,
    this.tagFontRatio = 0.55,
    this.numeralFontRatio = 0.8,
    this.previewNumeralFontRatio = 0.85,
    this.startAngle = -math.pi / 2,
    this.direction = 1.0,
    this.controlWidth = 190.0,
    this.controlTopOffset = -44.0,
  });
}

/// Everything the board's painters and layout need, computed once per build and
/// shared by the ring and the settings-page preview. Routing both through this
/// is what stops the preview from silently keeping the default look forever.
@immutable
class BoardMetrics {
  final SkinGeometry geometry;
  final int n;
  final Size size;
  final Offset center;
  final Offset apex;
  final double ringR;
  final double pieceR;
  final double tagFont;
  final double numeralFont;

  /// Live drag offset (radians) applied to the ring seats. The outboard seat is
  /// never spun — `r` is an 11-cycle that fixes it.
  final double spin;

  const BoardMetrics._({
    required this.geometry,
    required this.n,
    required this.size,
    required this.center,
    required this.apex,
    required this.ringR,
    required this.pieceR,
    required this.tagFont,
    required this.numeralFont,
    required this.spin,
  });

  /// The playing board, laid out inside [size] exactly as BallRingView.mm did.
  factory BoardMetrics.board(
    SkinGeometry g, {
    required int n,
    required Size size,
    double spin = 0,
  }) {
    final halfW = size.width / 2;
    final pieceR = (g.pieceRadiusRatio * halfW).roundToDouble();
    final ringR = halfW - g.ringInsetPieces * pieceR;
    final tagFont = g.tagFontRatio * pieceR;
    final center =
        Offset(size.width / 2, size.height / 2 + g.centerYBiasPieces * pieceR + tagFont);
    return BoardMetrics._(
      geometry: g,
      n: n,
      size: size,
      center: center,
      apex: Offset(center.dx, center.dy - (ringR + g.outboardGapPieces * pieceR)),
      ringR: ringR,
      pieceR: pieceR,
      tagFont: tagFont,
      numeralFont: g.numeralFontRatio * pieceR,
      spin: spin,
    );
  }

  /// The small settings-page preview: same ring, hung from the top of its box
  /// (the outboard seat one piece-radius down) and — unlike the board — with an
  /// unrounded piece radius. Both are legacy behaviour, preserved deliberately.
  factory BoardMetrics.preview(
    SkinGeometry g, {
    required int n,
    required Size size,
  }) {
    final halfW = size.width / 2;
    final pieceR = g.pieceRadiusRatio * halfW;
    final ringR = halfW - g.ringInsetPieces * pieceR;
    // Written in the legacy association order so the arithmetic is bit-identical
    // to the painter this replaced: the outboard seat lands one piece-radius
    // below the top of the box.
    final center =
        Offset(size.width / 2, ringR + g.outboardGapPieces * pieceR + pieceR);
    return BoardMetrics._(
      geometry: g,
      n: n,
      size: size,
      center: center,
      apex: Offset(center.dx, center.dy - (ringR + g.outboardGapPieces * pieceR)),
      ringR: ringR,
      pieceR: pieceR,
      tagFont: g.tagFontRatio * pieceR,
      numeralFont: g.previewNumeralFontRatio * pieceR,
      spin: 0,
    );
  }

  /// One seat's worth of rotation.
  double get wedge => 2 * math.pi / (n - 1);

  /// Home angle of ring seat [seat] (seat 0, the outboard one, has no angle).
  double angle(int seat) => geometry.direction * wedge * (seat - 1) + geometry.startAngle;

  Offset onRing(double a) =>
      Offset(center.dx + ringR * math.cos(a), center.dy + ringR * math.sin(a));

  /// Resting centre of seat [i].
  Offset seat(int i) => i == 0 ? apex : onRing(angle(i));

  /// Seat [i] with the live drag [spin] applied (the outboard seat never spins).
  Offset spunSeat(int i) => (i == 0 || spin == 0) ? seat(i) : onRing(angle(i) + spin);

  /// Where seat [i]'s fixed "home position" tag is drawn.
  Offset tagPos(int i) {
    if (i == 0) {
      return Offset(center.dx, apex.dy - geometry.seatTagInsetPieces * pieceR);
    }
    final a = angle(i);
    final rr = ringR - geometry.seatTagInsetPieces * pieceR;
    return Offset(center.dx + rr * math.cos(a), center.dy + rr * math.sin(a));
  }

  BoardMetrics withSpin(double s) => BoardMetrics._(
        geometry: geometry,
        n: n,
        size: size,
        center: center,
        apex: apex,
        ringR: ringR,
        pieceR: pieceR,
        tagFont: tagFont,
        numeralFont: numeralFont,
        spin: s,
      );
}
