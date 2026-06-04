import 'dart:math' as math;
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
  late List<int> _colorOfBall; // ball value -> palette index (from swap perm)

  @override
  void initState() {
    super.initState();
    _game = MathieuEngine();
    _n = _game.n;
    _recomputeColors();
    // Startup probe (non-mutating); confirms the FFI engine loaded, and is
    // visible in the console on platforms where screenshots aren't available.
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
            child: LayoutBuilder(builder: (context, c) {
              return _BallRing(
                arrangement: _game.arrangement(),
                colorOfBall: _colorOfBall,
                size: Size(c.maxWidth, c.maxHeight),
              );
            }),
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

class _BallRing extends StatelessWidget {
  final List<int> arrangement;
  final List<int> colorOfBall;
  final Size size;
  const _BallRing({
    required this.arrangement,
    required this.colorOfBall,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final n = arrangement.length; // 12
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2 + h * 0.04;
    final radius = math.min(w, h) * 0.36;
    final ballR = radius * 0.26;

    Offset slotCenter(int slot) {
      if (slot == 0) {
        return Offset(cx, cy - radius - ballR * 1.4); // apex above the ring
      }
      // slots 1..11 around the circle, slot 1 at top going clockwise
      final theta = -math.pi / 2 + (slot - 1) * (2 * math.pi / (n - 1));
      return Offset(cx + radius * math.cos(theta), cy + radius * math.sin(theta));
    }

    final children = <Widget>[];
    for (var slot = 0; slot < n; slot++) {
      final center = slotCenter(slot);
      final ballValue = arrangement[slot];
      final color = _palette[colorOfBall[ballValue] % _palette.length];
      // gray "home" tag for this slot
      children.add(Positioned(
        left: center.dx + ballR * 0.7,
        top: center.dy + ballR * 0.7,
        child: Text('$slot',
            style: TextStyle(color: Colors.grey.shade600, fontSize: ballR * 0.5)),
      ));
      // the ball
      children.add(Positioned(
        left: center.dx - ballR,
        top: center.dy - ballR,
        child: _Ball(value: ballValue, color: color, r: ballR),
      ));
    }
    return Stack(children: children);
  }
}

class _Ball extends StatelessWidget {
  final int value;
  final Color color;
  final double r;
  const _Ball({required this.value, required this.color, required this.r});

  @override
  Widget build(BuildContext context) {
    final lum = color.computeLuminance();
    final textColor = lum > 0.5 ? Colors.black : Colors.white;
    return Container(
      width: r * 2,
      height: r * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.4)!],
          stops: const [0.55, 1.0],
        ),
        border: Border.all(color: Colors.black26, width: 1),
      ),
      alignment: Alignment.center,
      child: Text('$value',
          style: TextStyle(
              color: textColor,
              fontSize: r * 0.9,
              fontWeight: FontWeight.bold)),
    );
  }
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
