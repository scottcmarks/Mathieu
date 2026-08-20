// Shared furniture for the tutorial pages.
//
// These live on the "back of the game" — the light, iOS-ish side reached by the
// flip, matching _SettingsPage rather than the black board.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../m12/analysis.dart';
import '../m12/perm.dart';
import '../m12/word.dart';

const Color kBackLabel = Colors.black87;
const Color kBackSubtle = Colors.black54;
const Color kBackFaint = Colors.black38;
const Color kBackBar = Color(0xFFF2F2F7);

const TextStyle kLabelStyle = TextStyle(color: kBackLabel, fontSize: 17);
const TextStyle kSubtleStyle = TextStyle(color: kBackSubtle, fontSize: 13);
const TextStyle kMonoStyle =
    TextStyle(color: kBackLabel, fontFamily: 'monospace', fontSize: 15);

/// The standard "back of the game" page.
class BackPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottom;
  const BackPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: kBackBar,
          foregroundColor: Colors.blue,
          title: Text(title, style: const TextStyle(color: Colors.black)),
          actions: actions,
        ),
        body: body,
        bottomNavigationBar: bottom,
      );
}

/// A scrolling page body with the settings page's own padding.
class BackList extends StatelessWidget {
  final List<Widget> children;
  const BackList({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: children,
      );
}

/// A titled block with a hairline above it.
class Section extends StatelessWidget {
  final String title;
  final Widget child;
  final String? note;
  const Section({super.key, required this.title, required this.child, this.note});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          if (title.isNotEmpty)
            Text(title, style: kLabelStyle.copyWith(fontWeight: FontWeight.w600)),
          if (note != null) ...[
            if (title.isNotEmpty) const SizedBox(height: 4),
            Text(note!, style: kSubtleStyle),
          ],
          if (title.isNotEmpty || note != null) const SizedBox(height: 10),
          child,
        ],
      );
}

/// A word, shown the way the app writes words everywhere else.
class WordChip extends StatelessWidget {
  final Word word;
  final Color? color;
  const WordChip(this.word, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (color ?? Colors.black).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(word.display,
            style: kMonoStyle.copyWith(color: color ?? kBackLabel)),
      );
}

/// How a seat is being shown on a [SeatRing].
enum SeatRole {
  /// Untouched by whatever is being illustrated.
  plain,

  /// Moved by the element on display.
  moved,

  /// Deliberately left alone by it.
  fixed,

  /// Picked by the user (the conjugation target).
  chosen,
}

/// A small ring of the twelve seats, laid out by the same BoardMetrics the
/// board uses — so it is the same ring, not a second drawing of one.
///
/// Optionally tappable, which is how the conjugation screen asks "which seats?".
class SeatRing extends StatelessWidget {
  final Map<int, SeatRole> roles;
  final void Function(int seat)? onTapSeat;
  final double size;

  /// Draw an arrow from each moved seat to where its piece goes.
  final List<int>? arrows;

  const SeatRing({
    super.key,
    this.roles = const {},
    this.onTapSeat,
    this.size = 200,
    this.arrows,
  });

  /// Roles derived from an element: its support is "moved", the rest "fixed".
  factory SeatRing.forPerm(List<int> perm,
          {double size = 200, bool withArrows = true, Set<int> chosen = const {}}) =>
      SeatRing(
        size: size,
        arrows: withArrows ? perm : null,
        roles: {
          for (var i = 0; i < perm.length; i++)
            i: chosen.contains(i)
                ? SeatRole.chosen
                : (perm[i] == i ? SeatRole.fixed : SeatRole.moved),
        },
      );

  @override
  Widget build(BuildContext context) {
    final h = size * 1.05;
    final painter = _SeatRingPainter(roles: roles, arrows: arrows);
    final art = CustomPaint(size: Size(size, h), painter: painter);
    if (onTapSeat == null) return art;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        final hit = painter.seatAt(Size(size, h), d.localPosition);
        if (hit != null) onTapSeat!(hit);
      },
      child: art,
    );
  }
}

class _SeatRingPainter extends CustomPainter {
  final Map<int, SeatRole> roles;
  final List<int>? arrows;
  _SeatRingPainter({required this.roles, this.arrows});

  static const _n = kBalls;

  // Layout mirrors BoardMetrics.preview: same ratios, drawn small.
  _Geo _geo(Size size) {
    final halfW = size.width / 2;
    final pieceR = 0.1375 * halfW;
    final ringR = halfW - 2 * pieceR;
    final center = Offset(size.width / 2, ringR + 2.5 * pieceR + pieceR);
    return _Geo(center, ringR, pieceR);
  }

  Offset _seat(_Geo g, int i) {
    if (i == 0) return Offset(g.center.dx, g.center.dy - (g.ringR + 2.5 * g.pieceR));
    final a = 2 * math.pi / (_n - 1) * (i - 1) - math.pi / 2;
    return Offset(g.center.dx + g.ringR * math.cos(a), g.center.dy + g.ringR * math.sin(a));
  }

  int? seatAt(Size size, Offset p) {
    final g = _geo(size);
    for (var i = 0; i < _n; i++) {
      if ((p - _seat(g, i)).distance <= g.pieceR * 1.5) return i;
    }
    return null;
  }

  static const _colors = {
    SeatRole.plain: Color(0xFFE4E4EA),
    SeatRole.moved: Color(0xFFFFB74D),
    SeatRole.fixed: Color(0xFFB9E4B9),
    SeatRole.chosen: Color(0xFF64B5F6),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final g = _geo(size);

    // the ring the seats sit on
    canvas.drawCircle(
        g.center,
        g.ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x22000000));

    // where each moved piece is headed
    final a = arrows;
    if (a != null) {
      final pen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x55000000);
      for (var i = 0; i < a.length && i < _n; i++) {
        if (a[i] == i) continue;
        final from = _seat(g, i);
        final to = _seat(g, a[i]);
        final d = to - from;
        final len = d.distance;
        if (len < 1) continue;
        final u = d / len;
        final p0 = from + u * (g.pieceR + 1);
        final p1 = to - u * (g.pieceR + 4);
        canvas.drawLine(p0, p1, pen);
        // arrow head
        final n = Offset(-u.dy, u.dx);
        final tip = p1 + u * 3;
        canvas.drawPath(
            Path()
              ..moveTo(tip.dx, tip.dy)
              ..lineTo(p1.dx + n.dx * 2.4, p1.dy + n.dy * 2.4)
              ..lineTo(p1.dx - n.dx * 2.4, p1.dy - n.dy * 2.4)
              ..close(),
            Paint()..color = const Color(0x55000000));
      }
    }

    for (var i = 0; i < _n; i++) {
      final c = _seat(g, i);
      final role = roles[i] ?? SeatRole.plain;
      canvas.drawCircle(c, g.pieceR, Paint()..color = _colors[role]!);
      canvas.drawCircle(
          c,
          g.pieceR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = role == SeatRole.chosen ? 2 : 1
            ..color = const Color(0x33000000));
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: Colors.black87,
            fontSize: g.pieceR * 0.95,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_SeatRingPainter old) => true;
}

class _Geo {
  final Offset center;
  final double ringR;
  final double pieceR;
  const _Geo(this.center, this.ringR, this.pieceR);
}

/// The full read-out for one element: what a mechanical toy cannot tell you.
class AnalysisCard extends StatelessWidget {
  final MacroAnalysis analysis;
  final bool showRing;
  const AnalysisCard(this.analysis, {super.key, this.showRing = true});

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    final rows = <List<String>>[
      if (a.word != null) ['Word', a.word!.display],
      if (a.word != null)
        ['Cost', '${a.word!.moves} move${a.word!.moves == 1 ? '' : 's'}, '
            '${a.steps} step${a.steps == 1 ? '' : 's'}'],
      ['Cycles', a.cycleNotation],
      ['Shape', a.typeLabel],
      ['Disturbs', '${a.support.length} seats'],
      ['Leaves alone', a.fixed.isEmpty ? 'nothing' : a.fixed.join(', ')],
      ['Order', '${a.order}'],
      if (a.distance != null) ['Distance from home', '${a.distance} moves'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showRing)
          Center(child: SeatRing.forPerm(a.perm, size: 190)),
        if (showRing) const SizedBox(height: 8),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 150,
                    child: Text(r[0], style: kSubtleStyle)),
                Expanded(child: Text(r[1], style: kMonoStyle)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(a.plainEnglish, style: kLabelStyle.copyWith(fontSize: 15)),
        ),
        if (a.isTripleThreeCycle) ...[
          const SizedBox(height: 8),
          Text(
            'Three 3-cycles is as close as M₁₂ gets to a plain 3-cycle: the '
            'group has none. This is the shape to aim at seats you care about.',
            style: kSubtleStyle,
          ),
        ],
      ],
    );
  }
}

/// A "working…" block, used while the table or a search is being computed.
class Working extends StatelessWidget {
  final String what;
  const Working(this.what, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(what, style: kSubtleStyle),
          ],
        ),
      );
}
