// Numeric half of the default-fidelity guarantee (the pixel half is
// ball_ring_golden_test.dart). Every expectation below re-implements the
// pre-skin main.dart expression *verbatim* and demands exact equality — not
// closeTo — because the legacy arithmetic, including the roundToDouble() on the
// piece radius and the association order in the preview's centre, is what the
// goldens were captured from.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/main.dart' show colorIndicesFor;
import 'package:mathieu/skin/packs/default_pack.dart';
import 'package:mathieu/skin/skin.dart';

const _skin = DefaultSkin();
const _n = 12;

void main() {
  group('board geometry reproduces BallRingView.mm', () {
    for (final size in const [Size(360, 640), Size(320, 480), Size(414, 736), Size(1024, 768)]) {
      test('$size', () {
        // --- legacy main.dart:614-618, copied as-is ---
        final w = size.width, h = size.height;
        final halfW = w / 2;
        final ballR = (0.1375 * halfW).roundToDouble();
        final circleR = halfW - 2 * ballR;
        final tagFont = ballR * 0.55;
        final center = Offset(w / 2, h / 2 + 0.5 * ballR + tagFont);
        final apex = Offset(center.dx, center.dy - (circleR + 2.5 * ballR));
        double angle(int slot) => (2 * math.pi / (_n - 1)) * (slot - 1) - math.pi / 2;
        Offset slot(int i) => i == 0
            ? apex
            : Offset(center.dx + circleR * math.cos(angle(i)),
                center.dy + circleR * math.sin(angle(i)));

        final m = BoardMetrics.board(_skin.geometry, n: _n, size: size);

        expect(m.pieceR, ballR);
        expect(m.ringR, circleR);
        expect(m.tagFont, tagFont);
        expect(m.center, center);
        expect(m.apex, apex);
        expect(m.numeralFont, ballR * 0.8); // legacy main.dart:664

        for (var i = 0; i < _n; i++) {
          expect(m.seat(i), slot(i), reason: 'seat $i');
          if (i > 0) expect(m.angle(i), angle(i), reason: 'angle $i');
        }

        // seat tags: legacy main.dart:624-630
        for (var i = 0; i < _n; i++) {
          final want = i == 0
              ? Offset(center.dx, apex.dy - 1.5 * ballR)
              : Offset(center.dx + (circleR - 1.5 * ballR) * math.cos(angle(i)),
                  center.dy + (circleR - 1.5 * ballR) * math.sin(angle(i)));
          expect(m.tagPos(i), want, reason: 'tag $i');
        }

        // centre control block: legacy main.dart:672-674 (-95 / -44 / 190)
        final g = m.geometry;
        expect(m.center.dx - g.controlWidth / 2, center.dx - 95);
        expect(m.center.dy + g.controlTopOffset, center.dy - 44);
        expect(g.controlWidth, 190);
      });
    }
  });

  test('preview geometry reproduces _RingPreviewPainter', () {
    const size = Size(132, 138); // legacy _SwapPreview box
    // --- legacy main.dart:1060-1070, copied as-is ---
    final halfW = size.width / 2;
    final ballR = 0.1375 * halfW; // deliberately NOT rounded
    final circleR = halfW - 2 * ballR;
    final center = Offset(size.width / 2, circleR + 2.5 * ballR + ballR);
    Offset slot(int i) {
      if (i == 0) return center - Offset(0, circleR + 2.5 * ballR);
      final a = (2 * math.pi / (_n - 1)) * (i - 1) - math.pi / 2;
      return center + Offset(circleR * math.cos(a), circleR * math.sin(a));
    }

    final m = BoardMetrics.preview(_skin.geometry, n: _n, size: size);
    expect(m.pieceR, ballR);
    expect(m.ringR, circleR);
    expect(m.center, center);
    expect(m.numeralFont, ballR * 0.85); // legacy main.dart:1079
    for (var i = 0; i < _n; i++) {
      expect(m.seat(i), slot(i), reason: 'preview seat $i');
    }
  });

  test('spin moves the ring seats and never the outboard one', () {
    final m = BoardMetrics.board(_skin.geometry, n: _n, size: const Size(360, 640), spin: 0.3);
    expect(m.spunSeat(0), m.apex);
    for (var i = 1; i < _n; i++) {
      expect(m.spunSeat(i), m.onRing(m.angle(i) + 0.3), reason: 'spun seat $i');
    }
  });

  group('default motion reproduces _labelPos', () {
    final m = BoardMetrics.board(_skin.geometry, n: _n, size: const Size(360, 640));
    final motion = _skin.motion;

    Offset legacy(int ps, int cs, double t, bool arc) {
      if (ps == cs || t >= 1.0) return m.seat(cs); // spin is 0 here
      if (arc && ps >= 1 && cs >= 1) {
        final a0 = m.angle(ps);
        var da = m.angle(cs) - a0;
        while (da > math.pi) {
          da -= 2 * math.pi;
        }
        while (da < -math.pi) {
          da += 2 * math.pi;
        }
        final a = a0 + da * t;
        return Offset(m.center.dx + m.ringR * math.cos(a), m.center.dy + m.ringR * math.sin(a));
      }
      return Offset.lerp(m.seat(ps), m.seat(cs), t)!;
    }

    test('straight and arc paths, every seat pair', () {
      for (final t in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
        for (var ps = 0; ps < _n; ps++) {
          for (var cs = 0; cs < _n; cs++) {
            for (final arc in const [false, true]) {
              expect(motion.markPath(m, ps, cs, t, arc: arc), legacy(ps, cs, t, arc),
                  reason: '$ps->$cs t=$t arc=$arc');
            }
          }
        }
      }
    });

    test('the shorter way round: seat 11 -> seat 1 goes forwards, not 10 wedges back', () {
      // The raw difference is -10 wedges (about -5.7 rad); normalisation must
      // turn it into +1 wedge so a single spin looks like a single step.
      final a0 = m.angle(11);
      final da = m.angle(1) - a0;
      expect(da, lessThan(-math.pi)); // the un-normalised difference
      expect(motion.markPath(m, 11, 1, 0.5, arc: true),
          m.onRing(a0 + (da + 2 * math.pi) * 0.5));
    });
  });

  test('default pack keeps every legacy appearance constant', () {
    expect(_skin.id, 'default');
    expect(_skin.sensitive, isFalse);

    // Ball palette, iOS BALL_COLORS order (legacy main.dart:47-54).
    expect(_skin.palette.pieces, const [
      Color(0xFFFFFFFF),
      Color(0xFF77AAFF),
      Color(0xFFFF9933),
      Color(0xFFFFFF00),
      Color(0xFF00CC00),
      Color(0xFFFF0000),
    ]);
    expect(_skin.palette.pieceColor(7), const Color(0xFF77AAFF)); // wraps mod 6
    expect(_skin.palette.board, const Color(0xFF000000));
    expect(_skin.palette.numeral, Colors.black);
    expect(_skin.palette.seatTag, Colors.white38);
    expect(_skin.palette.chrome, Colors.white);
    expect(_skin.palette.chromeDim, Colors.white30);
    expect(_skin.palette.accent, const Color(0xFFFFC23D));
    expect(_skin.palette.deckBase, isNull); // no board furniture

    // Durations (legacy main.dart:57) and curve (legacy main.dart:121).
    expect(_skin.motion.durationMs(MoveKind.rotate), 170);
    expect(_skin.motion.durationMs(MoveKind.swap), 460);
    expect(_skin.motion.durationMs(MoveKind.macro), 460);
    expect(_skin.motion.durationMs(MoveKind.undo), 220);
    expect(_skin.motion.durationMs(MoveKind.big), 460);
    for (final k in MoveKind.values) {
      expect(_skin.motion.curve(k), Curves.easeInOut);
    }

    // The coloured pieces are static furniture; only the numerals travel.
    expect(_skin.motion.piecesTravel, isFalse);

    // Control labels.
    expect(_skin.vocab.swapVerb, 'Swap');
    expect(_skin.vocab.spinLeft, 'Left');
    expect(_skin.vocab.spinRight, 'Right');

    // Sounds are the shared set, unmapped.
    for (final n in const ['left', 'right', 'swap', 'combo', 'applause']) {
      expect(_skin.sound.resolve(n), n);
    }

    final m = BoardMetrics.board(_skin.geometry, n: _n, size: const Size(360, 640));
    final numeral = _skin.painter.numeralStyle(m, _skin.palette);
    expect(numeral.color, Colors.black);
    expect(numeral.fontSize, m.pieceR * 0.8);
    expect(numeral.fontWeight, FontWeight.bold);
    final tag = _skin.painter.seatTagStyle(m, _skin.palette);
    expect(tag.color, Colors.white38);
    expect(tag.fontSize, m.pieceR * 0.55);
  });

  test('colorIndicesFor gives each swap pair one colour', () {
    // s = (0 1)(2 9)(3 4)(5 6)(7 8)(10 11) — the brief's swap.
    const perm = [1, 0, 9, 4, 3, 6, 5, 8, 7, 2, 11, 10];
    expect(colorIndicesFor(perm), const [0, 0, 1, 2, 2, 3, 3, 4, 4, 1, 5, 5]);
  });
}
