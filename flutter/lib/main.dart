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

// Move durations (ms), echoing the legacy SMALL/LARGE_MOVE_DURATION feel.
const _dRotate = 170, _dSwap = 280, _dMacro = 340, _dUndo = 220, _dBig = 340;

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late final MathieuEngine _game;
  late int _n;
  late List<int> _colorOfBall;
  late List<int> _prevArr, _currArr;
  late final AnimationController _ctrl;
  late final Animation<double> _t;

  bool _wasSolved = true;
  bool _sound = true;
  bool _confirm = true;
  bool _solving = false;
  bool _alt = false;

  @override
  void initState() {
    super.initState();
    _game = MathieuEngine();
    _n = _game.n;
    _recomputeColors();
    _currArr = _game.arrangement();
    _prevArr = List<int>.of(_currArr);
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: _dRotate));
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.value = 1;
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
    _ctrl.dispose();
    _game.dispose();
    super.dispose();
  }

  // Apply an engine action and tween the balls from the old to the new layout.
  void _animatedMove(void Function() act, String? sound, int durationMs) {
    setState(() {
      if (sound != null) Sfx.play(sound);
      _prevArr = _currArr;
      act();
      _currArr = _game.arrangement();
      _alt = false;
      final solved = _game.isSolved;
      if (solved && !_wasSolved) Sfx.play('applause');
      _wasSolved = solved;
    });
    _ctrl.duration = Duration(milliseconds: durationMs);
    _ctrl.forward(from: 0);
  }

  // Refresh layout with no tween (drag steps, macro-set expansions, selector).
  void _instant(void Function() act, [String? sound]) {
    setState(() {
      if (sound != null) Sfx.play(sound);
      act();
      _currArr = _game.arrangement();
      _prevArr = List<int>.of(_currArr);
      _ctrl.value = 1;
      _wasSolved = _game.isSolved;
    });
  }

  // --- button / gesture moves ---
  void _left() => _animatedMove(_game.left, 'left', _dRotate);
  void _right() => _animatedMove(_game.right, 'right', _dRotate);
  void _swap() => _animatedMove(_game.swap, 'swap', _dSwap);
  void _rotateDrag(bool right) =>
      _instant(right ? _game.right : _game.left, right ? 'right' : 'left');

  void _macroTap(int c) {
    if (!_game.macroDefined(c)) return;
    _animatedMove(() => _game.runMacro(c, inverted: _alt), 'combo', _dMacro);
  }

  Future<void> _macroSet(int c) async {
    final letter = String.fromCharCode(c);
    if (_confirm && _game.macroDefined(c) && !_game.historyIsSingleMacro(c)) {
      final verb = _game.historyLength == 0 ? 'erase' : 'change';
      if (!await _ask('Combo Set!', 'This will $verb the meaning of $letter.')) return;
    }
    _instant(() => _game.setMacro(c), 'combo_set');
  }

  void _toggleAlt() => setState(() => _alt = !_alt);

  Future<bool> _ask(String title, String msg) async {
    if (!_confirm) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('OK')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _shake() async {
    Sfx.play('shake');
    if (_confirm && _solving &&
        !await _ask('Shake!', 'This will create a new Sporadic M12 puzzle.')) return;
    _animatedMove(_game.random, null, _dBig);
    _solving = true;
  }

  Future<void> _home() async {
    Sfx.play('home');
    if (_confirm && _solving &&
        !await _ask('Home!', 'This will reset Sporadic M12 to the home position.')) return;
    _animatedMove(_game.reset, null, _dBig);
    _solving = false;
  }

  Future<void> _restart() async {
    Sfx.play('restart');
    if (_confirm && _solving &&
        !await _ask('Restart!', 'This will restart solving this puzzle.')) return;
    _animatedMove(_game.revert, null, _dBig);
  }

  void _shakeOrRestart() {
    if (_alt) {
      _restart();
    } else {
      _shake();
    }
  }

  void _undo() => _animatedMove(() => _game.undo(move: !_alt), null, _dUndo);

  Future<void> _openSelector() async {
    await Navigator.of(context).push(_flipRoute(_SwapSelectorPage(
      current: MathieuEngine.swapIndex,
      n: _n,
      onSelected: (i) {
        MathieuEngine.swapIndex = i;
        _instant(() {
          _game.reset();
          _game.eraseAllMacros();
          _recomputeColors();
          _solving = false;
        });
      },
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Sporadic M12'),
        actions: [
          IconButton(
            tooltip: 'Swap permutation',
            icon: const Icon(Icons.flip),
            onPressed: _openSelector,
          ),
          IconButton(
            tooltip: 'Sound',
            icon: Icon(_sound ? Icons.volume_up : Icons.volume_off),
            onPressed: () => setState(() {
              _sound = !_sound;
              Sfx.enabled = _sound;
            }),
          ),
          IconButton(
            tooltip: _confirm ? 'Confirmations on' : 'Confirmations off',
            icon: Icon(_confirm ? Icons.help : Icons.help_outline),
            onPressed: () => setState(() => _confirm = !_confirm),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TopButton(_alt ? 'Restart' : 'Shake', _shakeOrRestart),
                _TopButton('Home', _home),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, _) => _BallRing(
                prevArrangement: _prevArr,
                arrangement: _currArr,
                t: _t.value,
                colorOfBall: _colorOfBall,
                onLeft: _left,
                onRight: _right,
                onSwap: _swap,
                onRotateDrag: _rotateDrag,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_game.moves}',
                          style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      Text('${_game.steps}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C3A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _game.historyStr().isEmpty ? '—' : _game.historyStr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF7DFF7D),
                          fontFamily: 'monospace',
                          fontSize: 15,
                          letterSpacing: 1.0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _undo, child: Text(_alt ? 'Step' : 'Undo')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in const [65, 66, 67, 68, 69])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _MacroKey(
                      label: String.fromCharCode(c),
                      highlighted: _game.macroDefined(c),
                      onTap: () => _macroTap(c),
                      onLongPress: () => _macroSet(c),
                    ),
                  ),
                const SizedBox(width: 8),
                _MacroKey(label: 'Alt', highlighted: _alt, onTap: _toggleAlt),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// The ring of balls. Balls tween between their previous and current ring
/// positions (arc paths) by [t]. Finger gestures: drag around to rotate
/// (instant per wedge), pull the apex ball down to swap. Geometry ported from
/// BallRingView.mm.
class _BallRing extends StatefulWidget {
  final List<int> prevArrangement;
  final List<int> arrangement;
  final double t;
  final List<int> colorOfBall;
  final VoidCallback onLeft, onRight, onSwap;
  final void Function(bool right) onRotateDrag;
  const _BallRing({
    required this.prevArrangement,
    required this.arrangement,
    required this.t,
    required this.colorOfBall,
    required this.onLeft,
    required this.onRight,
    required this.onSwap,
    required this.onRotateDrag,
  });

  @override
  State<_BallRing> createState() => _BallRingState();
}

class _BallRingState extends State<_BallRing> {
  static const _ballRadiusRatio = 0.1375; // MBallRadiusRatio

  late Offset _center;
  late double _circleR, _ballR;
  late Offset _apex;

  bool _swapMode = false, _swapFired = false;
  double _lastAngle = 0, _accum = 0;

  int get _n => widget.arrangement.length;

  double _angle(int slot) => (2 * math.pi / (_n - 1)) * (slot - 1) - math.pi / 2;

  Offset _slot(int i) {
    if (i == 0) return _apex;
    final a = _angle(i);
    return Offset(_center.dx + _circleR * math.cos(a), _center.dy + _circleR * math.sin(a));
  }

  // Position of ball value v, interpolated from its previous to its current slot.
  Offset _ballPos(int v, double t) {
    final ps = widget.prevArrangement.indexOf(v);
    final cs = widget.arrangement.indexOf(v);
    if (ps == cs || t >= 1.0) return _slot(cs);
    if (ps >= 1 && cs >= 1) {
      final a0 = _angle(ps);
      var da = _angle(cs) - a0;
      while (da > math.pi) da -= 2 * math.pi;
      while (da < -math.pi) da += 2 * math.pi;
      final a = a0 + da * t;
      return Offset(_center.dx + _circleR * math.cos(a), _center.dy + _circleR * math.sin(a));
    }
    return Offset.lerp(_slot(ps), _slot(cs), t)!;
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
      widget.onRotateDrag(true);
    }
    while (_accum <= -step) {
      _accum += step;
      widget.onRotateDrag(false);
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

      // tags (fixed gray "home" position numbers)
      for (var i = 0; i < _n; i++) {
        final tagPos = i == 0
            ? Offset(_center.dx, _apex.dy - 1.5 * _ballR)
            : () {
                final a = _angle(i);
                final rr = _circleR - 1.5 * _ballR;
                return Offset(_center.dx + rr * math.cos(a), _center.dy + rr * math.sin(a));
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

      // balls, by value, at their interpolated positions
      for (var v = 0; v < _n; v++) {
        final ctr = _ballPos(v, widget.t);
        final color = _palette[widget.colorOfBall[v] % _palette.length];
        children.add(Positioned(
          left: ctr.dx - _ballR,
          top: ctr.dy - _ballR,
          child: _Marble(value: v, color: color, r: _ballR),
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

class _TopButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TopButton(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6A6A86),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        ),
        onPressed: onTap,
        child: Text(label),
      );
}

class _MacroKey extends StatelessWidget {
  final String label;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _MacroKey({
    required this.label,
    required this.highlighted,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 46,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFFFC23D) : const Color(0xFF6A6A86),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
        child: Text(label,
            style: TextStyle(
                color: highlighted ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }
}

// A horizontal-flip page transition, evoking the original "flip to the back".
Route<T> _flipRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (context, animation, secondary) => page,
    transitionsBuilder: (context, anim, secondary, child) {
      final rotate =
          Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut));
      return AnimatedBuilder(
        animation: rotate,
        builder: (context, _) {
          final t = rotate.value;
          final showFront = t > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(t * math.pi),
            child: showFront
                ? const ColoredBox(color: _bg, child: SizedBox.expand())
                : child,
          );
        },
      );
    },
  );
}

/// The "back of the game": the swap-permutation selector.
class _SwapSelectorPage extends StatelessWidget {
  final int current;
  final int n;
  final ValueChanged<int> onSelected;
  const _SwapSelectorPage(
      {required this.current, required this.n, required this.onSelected});

  static String _cycles(List<int> perm) {
    final seen = List<bool>.filled(perm.length, false);
    final parts = <String>[];
    for (var i = 0; i < perm.length; i++) {
      if (seen[i] || perm[i] == i) {
        seen[i] = true;
        continue;
      }
      final cyc = <int>[];
      var j = i;
      while (!seen[j]) {
        seen[j] = true;
        cyc.add(j);
        j = perm[j];
      }
      if (cyc.length > 1) parts.add('(${cyc.join(" ")})');
    }
    return parts.isEmpty ? '(identity)' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final count = MathieuEngine.swapCount;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(backgroundColor: _bg, title: const Text('Swap Permutation')),
      body: Scrollbar(
        child: ListView.builder(
          itemCount: count,
          itemBuilder: (context, i) {
            final perm = MathieuEngine.swapPermutationAt(i, n);
            final diff = MathieuEngine.swapDifficulty(i);
            final sel = i == current;
            return ListTile(
              dense: true,
              selected: sel,
              selectedTileColor: const Color(0x33000000),
              leading: sel
                  ? const Icon(Icons.check, color: Colors.black87)
                  : const SizedBox(width: 24),
              title: Text('#${i + 1}    ${_cycles(perm)}',
                  style: const TextStyle(color: Colors.black87, fontFamily: 'monospace')),
              subtitle: Text('difficulty $diff',
                  style: const TextStyle(color: Colors.black54)),
              onTap: () {
                onSelected(i);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}

/// The original iOS marble, ported from BallView.mm's CGContextDrawRadialGradient.
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
              style: TextStyle(color: textColor, fontSize: r * 0.85, fontWeight: FontWeight.bold)),
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
    final dark = Color.lerp(color, Colors.black, 0.4)!;
    final shader = ui.Gradient.radial(
      Offset(r, r),
      r,
      [color, dark, dark.withValues(alpha: 0)],
      [0.0, 0.95, 1.0],
      TileMode.clamp,
      null,
      Offset(r, r / 4),
      0.0,
    );
    canvas.drawCircle(Offset(r, r), r, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_MarblePainter old) => old.color != color;
}
