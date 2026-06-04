import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'mathieu_ffi.dart';

void main() => runApp(const MathieuApp());

class MathieuApp extends StatelessWidget {
  const MathieuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mathieu M12',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const GamePage(),
      );
}

// Ball palette, matching the iOS app's BALL_COLORS order.
const _palette = <Color>[
  Color(0xFFFFFFFF), // white
  Color(0xFF77AAFF), // light azure blue
  Color(0xFFFF9933), // light hard orange
  Color(0xFFFFFF00), // yellow
  Color(0xFF00CC00), // dark hard green
  Color(0xFFFF0000), // red
];

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final MathieuEngine _game;
  late int _n;
  late List<int> _colorOfBall;

  @override
  void initState() {
    super.initState();
    _game = MathieuEngine();
    _n = _game.n;
    _recomputeColors();
    debugPrint('[M12] engine ready: balls=${MathieuEngine.ballCount} '
        'swaps=${MathieuEngine.swapCount} arrangement=${_game.arrangement()}');
  }

  void _recomputeColors() {
    final sp = MathieuEngine.swapPermutation(_n);
    final c = List<int>.filled(_n, -1);
    var next = 0;
    for (var i = 0; i < _n; i++) {
      if (c[i] == -1) {
        c[i] = next;
        c[sp[i]] = next;
        next++;
      }
    }
    _colorOfBall = c;
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  void _do(void Function() action) => setState(action);

  @override
  Widget build(BuildContext context) {
    final solved = _game.isSolved;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mathieu M12'),
        backgroundColor: Colors.transparent,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('moves: ${_game.historyLength}',
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _BallRing(
              arrangement: _game.arrangement(),
              colorOfBall: _colorOfBall,
              onLeft: () => _do(_game.left),
              onRight: () => _do(_game.right),
              onSwap: () => _do(_game.swap),
            ),
          ),
          if (solved)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Solved!',
                  style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF00CC00),
                      fontWeight: FontWeight.bold)),
            ),
          _Controls(
            onLeft: () => _do(() => _game.left()),
            onRight: () => _do(() => _game.right()),
            onSwap: () => _do(() => _game.swap()),
            onUndo: () => _do(() => _game.undo()),
            onRandom: () => _do(() => _game.random()),
            onReset: () => _do(() => _game.reset()),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// The ring of balls, with finger gestures:
///   * drag around the ring -> rotate (left / right)
///   * pull the apex (position-0) ball downward -> swap
class _BallRing extends StatefulWidget {
  final List<int> arrangement;
  final List<int> colorOfBall;
  final VoidCallback onLeft, onRight, onSwap;
  const _BallRing({
    required this.arrangement,
    required this.colorOfBall,
    required this.onLeft,
    required this.onRight,
    required this.onSwap,
  });

  @override
  State<_BallRing> createState() => _BallRingState();
}

class _BallRingState extends State<_BallRing> {
  // geometry of the most recent layout (set in build)
  late Offset _center;
  late double _radius;
  late double _ballR;
  late Offset _apex;

  // gesture tracking
  bool _swapMode = false;
  bool _swapFired = false;
  double _lastAngle = 0;
  double _accum = 0;

  int get _n => widget.arrangement.length;

  Offset _slotCenter(int slot) {
    if (slot == 0) return _apex;
    final theta = -math.pi / 2 + (slot - 1) * (2 * math.pi / (_n - 1));
    return Offset(
        _center.dx + _radius * math.cos(theta), _center.dy + _radius * math.sin(theta));
  }

  void _onStart(DragStartDetails d) {
    final p = d.localPosition;
    if ((p - _apex).distance <= _ballR * 1.6) {
      _swapMode = true;
      _swapFired = false;
    } else {
      _swapMode = false;
      _lastAngle = (p - _center).direction;
      _accum = 0;
    }
  }

  void _onUpdate(DragUpdateDetails d) {
    final p = d.localPosition;
    if (_swapMode) {
      if (!_swapFired && (p.dy - _apex.dy) > _ballR * 1.1) {
        _swapFired = true;
        widget.onSwap();
      }
      return;
    }
    final ang = (p - _center).direction;
    var delta = ang - _lastAngle;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    _accum += delta;
    _lastAngle = ang;
    final step = 2 * math.pi / (_n - 1);
    while (_accum >= step) {
      _accum -= step;
      widget.onRight();
    }
    while (_accum <= -step) {
      _accum += step;
      widget.onLeft();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      _center = Offset(w / 2, h / 2 + h * 0.05);
      _radius = math.min(w, h) * 0.38;
      _ballR = _radius * 0.19; // smaller marbles
      _apex = Offset(_center.dx, _center.dy - _radius - _ballR * 2.0);

      final children = <Widget>[];
      for (var slot = 0; slot < _n; slot++) {
        final ctr = _slotCenter(slot);
        final ballValue = widget.arrangement[slot];
        final color = _palette[widget.colorOfBall[ballValue] % _palette.length];
        children.add(Positioned(
          left: ctr.dx + _ballR * 0.85,
          top: ctr.dy - _ballR * 1.35,
          child: Text('$slot',
              style: TextStyle(color: Colors.grey.shade600, fontSize: _ballR * 0.55)),
        ));
        children.add(Positioned(
          left: ctr.dx - _ballR,
          top: ctr.dy - _ballR,
          child: _Marble(value: ballValue, color: color, r: _ballR),
        ));
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onStart,
        onPanUpdate: _onUpdate,
        child: Stack(children: children),
      );
    });
  }
}

/// The original iOS marble, ported faithfully from BallView.mm's
/// CGContextDrawRadialGradient: a "sphere cap lit from above" — dark (0.6x) at
/// the rim, brightening to full colour at a highlight 1/8 from the top, with a
/// transparent anti-aliased edge.
class _Marble extends StatelessWidget {
  final int value;
  final Color color;
  final double r;
  const _Marble({required this.value, required this.color, required this.r});

  @override
  Widget build(BuildContext context) {
    final textColor = color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
    return SizedBox(
      width: r * 2,
      height: r * 2,
      child: CustomPaint(
        painter: _MarblePainter(color),
        child: Center(
          child: Text('$value',
              style: TextStyle(
                  color: textColor,
                  fontSize: r * 0.85,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _MarblePainter extends CustomPainter {
  final Color color;
  _MarblePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final r = d / 2;
    final dark = Color.lerp(color, Colors.black, 0.4)!; // 0.6x brightness
    // CG draws outer->highlight (stop 0 -> 1); Flutter's radial goes
    // focal -> outer, so we reverse: bright highlight at stop 0, dark rim near 1.
    final shader = ui.Gradient.radial(
      Offset(r, r), // outer circle centre
      r, // outer radius = width/2
      [color, dark, dark.withValues(alpha: 0)],
      [0.0, 0.95, 1.0],
      TileMode.clamp,
      null,
      Offset(r, r / 4), // highlight focal point (midY/4 from BallView.mm)
      0.0,
    );
    canvas.drawCircle(Offset(r, r), r, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_MarblePainter old) => old.color != color;
}

class _Controls extends StatelessWidget {
  final VoidCallback onLeft, onRight, onSwap, onUndo, onRandom, onReset;
  const _Controls({
    required this.onLeft,
    required this.onRight,
    required this.onSwap,
    required this.onUndo,
    required this.onRandom,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(onPressed: onLeft, child: const Text('Left')),
        FilledButton(onPressed: onRight, child: const Text('Right')),
        FilledButton(onPressed: onSwap, child: const Text('Swap')),
        OutlinedButton(onPressed: onUndo, child: const Text('Undo')),
        OutlinedButton(onPressed: onRandom, child: const Text('Scramble')),
        OutlinedButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}
