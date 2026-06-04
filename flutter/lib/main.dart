import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'mathieu_ffi.dart';
import 'sounds.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Sfx.init();
  runApp(const MathieuApp());
}

// Background lavender-grey, matching the original App Store screenshots.
const _bg = Color(0xFF9C9CB0);

class MathieuApp extends StatelessWidget {
  const MathieuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mathieu M12',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: _bg,
          useMaterial3: true,
        ),
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
  bool _wasSolved = true;
  bool _sound = true;

  @override
  void initState() {
    super.initState();
    _game = MathieuEngine();
    _n = _game.n;
    _recomputeColors();
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

  // A move (left/right/swap): play its sound, then applaud on a fresh solve.
  void _move(void Function() act, String sound) {
    setState(() {
      Sfx.play(sound);
      act();
      final solved = _game.isSolved;
      if (solved && !_wasSolved) Sfx.play('applause');
      _wasSolved = solved;
    });
  }

  void _scramble() => setState(() {
        Sfx.play('shake');
        _game.random();
        _wasSolved = _game.isSolved;
      });

  void _reset() => setState(() {
        Sfx.play('restart');
        _game.reset();
        _wasSolved = true;
      });

  void _undo() => setState(() {
        _game.undo();
        _wasSolved = _game.isSolved;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Sporadic M12'),
        actions: [
          IconButton(
            tooltip: 'Sound',
            icon: Icon(_sound ? Icons.volume_up : Icons.volume_off),
            onPressed: () => setState(() {
              _sound = !_sound;
              Sfx.enabled = _sound;
            }),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('moves ${_game.historyLength}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87)),
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
              onLeft: () => _move(_game.left, 'left'),
              onRight: () => _move(_game.right, 'right'),
              onSwap: () => _move(_game.swap, 'swap'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                OutlinedButton(onPressed: _undo, child: const Text('Undo')),
                OutlinedButton(onPressed: _scramble, child: const Text('Scramble')),
                OutlinedButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The ring of balls, with finger gestures (drag to rotate; pull apex ball
/// down to swap) and the Swap/Left/Right controls centred inside the ring,
/// matching the original layout. Geometry ported from BallRingView.mm.
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
  static const _ballRadiusRatio = 0.1375; // MBallRadiusRatio from M12Constants.h

  late Offset _center;
  late double _circleR;
  late double _ballR;
  late Offset _apex;

  bool _swapMode = false, _swapFired = false;
  double _lastAngle = 0, _accum = 0;

  int get _n => widget.arrangement.length;

  Offset _slot(int i) {
    if (i == 0) return _apex;
    final theta = (2 * math.pi / (_n - 1)) * (i - 1) - math.pi / 2;
    return Offset(_center.dx + _circleR * math.cos(theta),
        _center.dy + _circleR * math.sin(theta));
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
      final halfW = w / 2;
      _ballR = (_ballRadiusRatio * halfW).roundToDouble();
      _circleR = halfW - 2 * _ballR;
      final tagFont = _ballR * 0.55;
      _center = Offset(w / 2, h / 2 + 0.5 * _ballR + tagFont);
      _apex = Offset(_center.dx, _center.dy - (_circleR + 2.5 * _ballR));

      final children = <Widget>[];

      // tags (gray "home" position numbers)
      for (var i = 0; i < _n; i++) {
        final tagPos = i == 0
            ? Offset(_center.dx, _apex.dy - 1.5 * _ballR)
            : () {
                final theta = (2 * math.pi / (_n - 1)) * (i - 1) - math.pi / 2;
                final rr = _circleR - 1.5 * _ballR;
                return Offset(_center.dx + rr * math.cos(theta),
                    _center.dy + rr * math.sin(theta));
              }();
        children.add(Positioned(
          left: tagPos.dx - _ballR,
          top: tagPos.dy - tagFont / 2,
          width: _ballR * 2,
          child: Text('$i',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38, fontSize: tagFont)),
        ));
      }

      // balls
      for (var slot = 0; slot < _n; slot++) {
        final ctr = _slot(slot);
        final ballValue = widget.arrangement[slot];
        final color = _palette[widget.colorOfBall[ballValue] % _palette.length];
        children.add(Positioned(
          left: ctr.dx - _ballR,
          top: ctr.dy - _ballR,
          child: _Marble(value: ballValue, color: color, r: _ballR),
        ));
      }

      // centred Swap / Left+Right controls
      children.add(Positioned(
        left: _center.dx - 95,
        top: _center.dy - 44,
        width: 190,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _CtlButton('Swap', widget.onSwap),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _CtlButton('Left', widget.onLeft),
            const SizedBox(width: 10),
            _CtlButton('Right', widget.onRight),
          ]),
        ]),
      ));

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onStart,
        onPanUpdate: _onUpdate,
        child: Stack(children: children),
      );
    });
  }
}

class _CtlButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CtlButton(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6A6A86),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(64, 36),
        ),
        onPressed: onTap,
        child: Text(label),
      );
}

/// The original iOS marble, ported from BallView.mm's CGContextDrawRadialGradient:
/// a "sphere cap lit from above" — dark (0.6x) rim, brightening to full colour
/// at a highlight 1/8 from the top, with a transparent anti-aliased edge.
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
    final r = size.width / 2;
    final dark = Color.lerp(color, Colors.black, 0.4)!; // 0.6x brightness
    final shader = ui.Gradient.radial(
      Offset(r, r), // outer circle centre
      r, // outer radius = width/2
      [color, dark, dark.withValues(alpha: 0)],
      [0.0, 0.95, 1.0],
      TileMode.clamp,
      null,
      Offset(r, r / 4), // highlight focal point (midY/4 in BallView.mm)
      0.0,
    );
    canvas.drawCircle(Offset(r, r), r, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_MarblePainter old) => old.color != color;
}
