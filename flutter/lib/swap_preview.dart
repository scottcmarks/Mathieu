import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'skin/skin.dart';

/// Small preview of the home ring drawn with just the coloured pieces (the
/// "swap permutation preview" on the settings page). It goes through the same
/// [BoardMetrics] and [SkinPainter] as the board, so a skin cannot be applied to
/// the game and silently leave the preview looking like the default.
class SwapPreview extends StatelessWidget {
  final Skin skin;
  final List<int> colorOfBall;
  const SwapPreview(this.skin, this.colorOfBall, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 132,
        height: 138,
        child: CustomPaint(painter: _RingPreviewPainter(skin, colorOfBall)),
      );
}

class _RingPreviewPainter extends CustomPainter {
  final Skin skin;
  final List<int> colorOfBall;
  _RingPreviewPainter(this.skin, this.colorOfBall);

  @override
  void paint(Canvas canvas, Size size) {
    final pal = skin.palette;
    final m = BoardMetrics.preview(skin.geometry, n: colorOfBall.length, size: size);
    skin.painter.paintBoard(canvas, m, pal);
    final style = skin.painter.numeralStyle(m, pal);

    for (var v = 0; v < m.n; v++) {
      final c = m.seat(v); // home position: piece v at seat v
      skin.painter.paintPiece(canvas, c, m.pieceR, pal.pieceColor(colorOfBall[v]), v);
      final tp = TextPainter(
        text: TextSpan(text: '$v', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RingPreviewPainter old) =>
      old.skin != skin || !listEquals(old.colorOfBall, colorOfBall);
}
