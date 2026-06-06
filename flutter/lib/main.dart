import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'mathieu_ffi.dart';
import 'sounds.dart';
import 'build_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMathieu(); // load the WASM engine on web; no-op on other platforms
  // Portrait only, like the original (it never rotated to landscape).
  SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  Sfx.init();
  runApp(const MathieuApp());
}

// The game plays on black, like the 2.0.6 app.
const _bg = Color(0xFF000000);

// Beta "build tell": show the version/rev/time stamp on the running app so a
// specific installed beta build is identifiable at a glance. Hidden in store
// (release) builds unless --dart-define=BETA=true is passed (e.g. TestFlight).
const bool _showBuildTell =
    !kReleaseMode || bool.fromEnvironment('BETA', defaultValue: false);
const String _buildTell = '$kBuildVersion · $kBuildRev · $kBuildTime';

class MathieuApp extends StatelessWidget {
  const MathieuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sporadic M12',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
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
const _dRotate = 170, _dSwap = 460, _dMacro = 460, _dUndo = 220, _dBig = 460;

// Map ball value -> palette index from a swap permutation: each disjoint 2-cycle
// gets the next colour, so a swapped pair shares a colour.
List<int> colorIndicesFor(List<int> swapPerm) {
  final n = swapPerm.length;
  final c = List<int>.filled(n, -1);
  var next = 0;
  for (var i = 0; i < n; i++) {
    if (c[i] == -1) {
      c[i] = next;
      c[swapPerm[i]] = next;
      next++;
    }
  }
  return c;
}

// The 2.0.6 marble: dark (0.6x) rim brightening to a highlight 1/4 from the top.
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

  bool _notedSuccess = true; // legacy haveNotedSuccess; cleared only by a shake
  bool _sound = true;
  bool _confirm = true;
  bool _solving = false;
  bool _alt = false;
  bool _arc = false; // current tween: rotations spin labels along the arc
  double _animSpeed = 1.0; // 1.0 = base durations; higher = faster

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
    _colorOfBall = colorIndicesFor(MathieuEngine.swapPermutation(_n));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _game.dispose();
    super.dispose();
  }

  // Apply an engine action and tween the balls from the old to the new layout.
  // [success] true for "play" moves that can solve the puzzle (rotate/swap/macro/undo).
  void _animatedMove(void Function() act, String? sound, int durationMs,
      {bool success = false, bool arc = false}) {
    setState(() {
      if (sound != null) Sfx.play(sound);
      _arc = arc;
      _prevArr = _currArr;
      act();
      _currArr = _game.arrangement();
      _alt = false;
      if (success) _checkSuccess();
    });
    _ctrl.duration = Duration(milliseconds: (durationMs / _animSpeed).round().clamp(1, 4000));
    _ctrl.forward(from: 0);
  }

  // Refresh layout with no tween (drag steps, macro-set expansions, selector).
  void _instant(void Function() act, {String? sound, bool success = false}) {
    setState(() {
      if (sound != null) Sfx.play(sound);
      act();
      _currArr = _game.arrangement();
      _prevArr = List<int>.of(_currArr);
      _ctrl.value = 1;
      if (success) _checkSuccess();
    });
  }

  // Applause only the first time a *scrambled* puzzle is brought home. The flag
  // clears only on a new shake, so reaching home by Home/reset, or undoing back
  // to solved after you've already solved it, does not (re-)applaud.
  void _checkSuccess() {
    if (_solving && _game.isSolved && !_notedSuccess) {
      Sfx.play('applause');
      _notedSuccess = true;
    }
  }

  // --- button / gesture moves (success: can solve the puzzle) ---
  void _left() => _animatedMove(_game.left, 'left', _dRotate, success: true, arc: true);
  void _right() => _animatedMove(_game.right, 'right', _dRotate, success: true, arc: true);
  void _swap() => _animatedMove(_game.swap, 'swap', _dSwap, success: true);
  void _rotateDrag(bool right) => _instant(right ? _game.right : _game.left,
      sound: right ? 'right' : 'left', success: true);

  void _macroTap(int c) {
    if (!_game.macroDefined(c)) return;
    _animatedMove(() => _game.runMacro(c, inverted: _alt), 'combo', _dMacro, success: true);
  }

  Future<void> _macroSet(int c) async {
    final letter = String.fromCharCode(c);
    if (_confirm && _game.macroDefined(c) && !_game.historyIsSingleMacro(c)) {
      final verb = _game.historyLength == 0 ? 'erase' : 'change';
      if (!await _ask('Combo Set!', 'This will $verb the meaning of $letter.')) return;
    }
    _instant(() => _game.setMacro(c), sound: 'combo_set');
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
    _notedSuccess = false; // a fresh puzzle can be applauded once
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

  void _undo() => _animatedMove(() => _game.undo(move: !_alt), null, _dUndo, success: true);

  void _selectSwap(int i) {
    MathieuEngine.swapIndex = i;
    _instant(() {
      _game.reset();
      _game.eraseAllMacros();
      _recomputeColors();
      _solving = false;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(_flipRoute(_SettingsPage(
      confirm: _confirm,
      sound: _sound,
      animSpeed: _animSpeed,
      n: _n,
      onConfirm: (v) => setState(() => _confirm = v),
      onSound: (v) => setState(() {
        _sound = v;
        Sfx.enabled = v;
      }),
      onAnimSpeed: (v) => setState(() => _animSpeed = v),
      onSwapSelected: _selectSwap,
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
            tooltip: 'Settings',
            icon: const Icon(Icons.flip),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
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
                arc: _arc,
                colorOfBall: _colorOfBall,
                onLeft: _left,
                onRight: _right,
                onSwap: _swap,
                onRotateDrag: _rotateDrag,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_game.moves}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      Text('${_game.steps}',
                          style: const TextStyle(fontSize: 12, color: Colors.white38)),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    _game.historyStr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white54, fontFamily: 'monospace', fontSize: 14),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _undo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(_alt ? 'Step' : 'Undo',
                        style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final c in const [65, 66, 67, 68, 69])
                  _MacroKey(
                    label: String.fromCharCode(c),
                    bright: _game.macroDefined(c),
                    onTap: () => _macroTap(c),
                    onLongPress: () => _macroSet(c),
                  ),
                const SizedBox(width: 12),
                _MacroKey(label: 'Alt', bright: true, armed: _alt, onTap: _toggleAlt),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Image.asset('assets/images/sporadic_games_logo.png', height: 22),
          ),
        ],
          ),
          if (_showBuildTell)
            Positioned(
              top: 2,
              right: 8,
              child: IgnorePointer(
                child: Text(
                  _buildTell,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: Colors.amber.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
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
  final bool arc; // rotations spin labels along the arc; else straight lines
  final List<int> colorOfBall;
  final VoidCallback onLeft, onRight, onSwap;
  final void Function(bool right) onRotateDrag;
  const _BallRing({
    required this.prevArrangement,
    required this.arrangement,
    required this.t,
    required this.arc,
    required this.colorOfBall,
    required this.onLeft,
    required this.onRight,
    required this.onSwap,
    required this.onRotateDrag,
  });

  @override
  State<_BallRing> createState() => _BallRingState();
}

class _BallRingState extends State<_BallRing> with TickerProviderStateMixin {
  static const _ballRadiusRatio = 0.1375; // MBallRadiusRatio
  static const _flickThreshold = 3.0; // rad/s to trigger momentum
  static const _stopThreshold = 0.5; // rad/s below which momentum settles
  static const _decayPerSec = 0.12; // fraction of angular speed kept per second

  late Offset _center;
  late double _circleR, _ballR;
  late Offset _apex;

  bool _swapMode = false, _swapFired = false;
  double _lastAngle = 0;
  double _spin = 0; // live rotation offset (radians) during/after a drag
  double _settleFrom = 0;
  late final AnimationController _settle;

  // flick / momentum
  Ticker? _momentum;
  double _omega = 0; // rad/s
  Duration _lastTick = Duration.zero;

  int get _n => widget.arrangement.length;
  double get _step => 2 * math.pi / (_n - 1);

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _settle.addListener(() => setState(() => _spin = _settleFrom * (1 - _settle.value)));
    _momentum = createTicker(_onMomentumTick);
  }

  @override
  void dispose() {
    _momentum?.dispose();
    _settle.dispose();
    super.dispose();
  }

  // Commit engine steps for any whole wedges currently in _spin (keeps render
  // continuous across each commit).
  void _commitWedges() {
    while (_spin >= _step) {
      _spin -= _step;
      widget.onRotateDrag(true);
    }
    while (_spin <= -_step) {
      _spin += _step;
      widget.onRotateDrag(false);
    }
  }

  void _snapAndSettle() {
    if (_spin > _step / 2) {
      _spin -= _step;
      widget.onRotateDrag(true);
    } else if (_spin < -_step / 2) {
      _spin += _step;
      widget.onRotateDrag(false);
    }
    _settleFrom = _spin;
    _settle.forward(from: 0);
  }

  void _onMomentumTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 0.016
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _spin += _omega * dt;
    _omega *= math.pow(_decayPerSec, dt).toDouble();
    _commitWedges();
    setState(() {});
    if (_omega.abs() < _stopThreshold) {
      _momentum?.stop();
      _snapAndSettle();
    }
  }

  double _angle(int slot) => (2 * math.pi / (_n - 1)) * (slot - 1) - math.pi / 2;

  Offset _slot(int i) {
    if (i == 0) return _apex;
    final a = _angle(i);
    return Offset(_center.dx + _circleR * math.cos(a), _center.dy + _circleR * math.sin(a));
  }

  // Current slot of ball v, with the live drag spin applied to ring balls.
  Offset _spunSlot(int cs) {
    if (cs == 0 || _spin == 0) return _slot(cs);
    final a = _angle(cs) + _spin; // rotations don't move the apex (slot 0)
    return Offset(_center.dx + _circleR * math.cos(a), _center.dy + _circleR * math.sin(a));
  }

  // Position of the number label for value v. The coloured spheres stay put; the
  // labels move: rotations spin them along the arc, swaps/others go straight.
  Offset _labelPos(int v, double t) {
    final ps = widget.prevArrangement.indexOf(v);
    final cs = widget.arrangement.indexOf(v);
    if (ps == cs || t >= 1.0) return _spunSlot(cs);
    if (widget.arc && ps >= 1 && cs >= 1) {
      final a0 = _angle(ps);
      var da = _angle(cs) - a0;
      while (da > math.pi) da -= 2 * math.pi;
      while (da < -math.pi) da += 2 * math.pi;
      final a = a0 + da * t;
      return Offset(_center.dx + _circleR * math.cos(a), _center.dy + _circleR * math.sin(a));
    }
    return Offset.lerp(_slot(ps), _slot(cs), t)!; // straight line
  }

  void _onStart(DragStartDetails d) {
    final p = d.localPosition;
    if ((p - _apex).distance <= _ballR * 1.6) {
      _swapMode = true;
      _swapFired = false;
    } else {
      _swapMode = false;
      _lastAngle = (p - _center).direction;
      _momentum?.stop(); // grabbing mid-spin continues from here
      _settle.stop();
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
    _lastAngle = ang;
    // The ring follows the finger continuously; commit one engine step per wedge.
    _spin += delta;
    _commitWedges();
    setState(() {});
  }

  void _onEnd(DragEndDetails d) {
    if (_swapMode) {
      _swapMode = false;
      return;
    }
    final v = d.velocity.pixelsPerSecond;
    // angular velocity at the release point = tangential speed / radius
    final omega = (-v.dx * math.sin(_lastAngle) + v.dy * math.cos(_lastAngle)) / _circleR;
    if (omega.abs() > _flickThreshold) {
      _omega = omega;
      _lastTick = Duration.zero;
      _momentum?.start(); // spin and decelerate, then snap+settle
    } else {
      _snapAndSettle();
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
              style: TextStyle(color: Colors.white38, fontSize: tagFont)),
        ));
      }

      // fixed coloured spheres (no numbers): colour shows each position's swap pair
      for (var slot = 0; slot < _n; slot++) {
        final ctr = _slot(slot);
        final color = _palette[widget.colorOfBall[slot] % _palette.length];
        children.add(Positioned(
          left: ctr.dx - _ballR,
          top: ctr.dy - _ballR,
          child: _Sphere(color: color, r: _ballR),
        ));
      }

      // moving number labels: spheres stay, labels exchange (swap) / spin (rotate)
      for (var v = 0; v < _n; v++) {
        final ctr = _labelPos(v, widget.t);
        children.add(Positioned(
          left: ctr.dx - _ballR,
          top: ctr.dy - _ballR,
          width: _ballR * 2,
          height: _ballR * 2,
          child: Center(
            child: Text('$v',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: _ballR * 0.8,
                    fontWeight: FontWeight.bold)),
          ),
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
        onPanEnd: _onEnd,
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
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 17)),
        ),
      );
}

class _TopButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TopButton(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 17)),
        ),
      );
}

class _MacroKey extends StatelessWidget {
  final String label;
  final bool bright; // defined (A-E) or enabled
  final bool armed; // Alt armed -> gold
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _MacroKey({
    required this.label,
    required this.bright,
    this.armed = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = armed
        ? const Color(0xFFFFC23D)
        : (bright ? Colors.white : Colors.white30);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 18)),
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

/// The "back of the game": settings (white), reached by a flip. Shows the
/// current swap permutation (cycle notation) with an info button to the full
/// selector, plus Confirmation, Sound Effects and Animation Speed.
class _SettingsPage extends StatefulWidget {
  final bool confirm, sound;
  final double animSpeed;
  final int n;
  final ValueChanged<bool> onConfirm, onSound;
  final ValueChanged<double> onAnimSpeed;
  final ValueChanged<int> onSwapSelected;
  const _SettingsPage({
    required this.confirm,
    required this.sound,
    required this.animSpeed,
    required this.n,
    required this.onConfirm,
    required this.onSound,
    required this.onAnimSpeed,
    required this.onSwapSelected,
  });
  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  late bool _confirm = widget.confirm;
  late bool _sound = widget.sound;
  late double _animSpeed = widget.animSpeed;
  late int _swapIndex = MathieuEngine.swapIndex;

  @override
  Widget build(BuildContext context) {
    final cycles = _SwapSelectorPage.cycles(MathieuEngine.swapPermutationAt(_swapIndex, widget.n));
    const labelStyle = TextStyle(color: Colors.black87, fontSize: 17);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        foregroundColor: Colors.blue,
        centerTitle: true,
        title: const Text('M₁₂', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          const Center(child: Text('Current Swap Permutation', style: labelStyle)),
          const SizedBox(height: 10),
          // preview: the home ring coloured by this swap permutation
          Center(
            child: _SwapPreview(
                colorIndicesFor(MathieuEngine.swapPermutationAt(_swapIndex, widget.n))),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: cycleLabel(cycles)),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _SwapSelectorPage(
                      current: _swapIndex,
                      n: widget.n,
                      onSelected: (i) {
                        setState(() => _swapIndex = i);
                        widget.onSwapSelected(i);
                      },
                    ),
                  ));
                },
              ),
            ],
          ),
          const Divider(height: 36),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirmation', style: labelStyle),
                    SizedBox(height: 4),
                    Text(
                      'When solving, confirm Shake, Restart and Home. '
                      'Confirm combo set or erase of a previously-set combo.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _confirm,
                onChanged: (v) {
                  setState(() => _confirm = v);
                  widget.onConfirm(v);
                },
              ),
            ],
          ),
          const Divider(height: 36),
          Row(
            children: [
              const Expanded(child: Text('Sound Effects', style: labelStyle)),
              Switch(
                value: _sound,
                onChanged: (v) {
                  setState(() => _sound = v);
                  widget.onSound(v);
                },
              ),
            ],
          ),
          const Divider(height: 36),
          const Text('Animation Speed', style: labelStyle),
          Slider(
            value: _animSpeed,
            min: 0.3,
            max: 2.5,
            onChanged: (v) {
              setState(() => _animSpeed = v);
              widget.onAnimSpeed(v);
            },
          ),
          const SizedBox(height: 24),
          const Text('Sporadic M12 2.1.0',
              style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}

/// The "back of the game": the swap-permutation selector.
class _SwapSelectorPage extends StatelessWidget {
  final int current;
  final int n;
  final ValueChanged<int> onSelected;
  const _SwapSelectorPage(
      {required this.current, required this.n, required this.onSelected});

  static String cycles(List<int> perm) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        foregroundColor: Colors.black,
        title: const Text('Swap Permutation'),
      ),
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
              title: Text('#${i + 1}    ${cycles(perm)}',
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
// A fixed coloured sphere (no number) — numbers are a separate moving layer.
class _Sphere extends StatelessWidget {
  final Color color;
  final double r;
  const _Sphere({required this.color, required this.r});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: r * 2,
        height: r * 2,
        child: CustomPaint(painter: _MarblePainter(color)),
      );
}

class _MarblePainter extends CustomPainter {
  final Color color;
  _MarblePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..shader = marbleShader(color, c, r));
  }

  @override
  bool shouldRepaint(_MarblePainter old) => old.color != color;
}

// Cycle notation with smaller parentheses, e.g. ((0 1) (2 3) ...).
Widget cycleLabel(String s) {
  final spans = <TextSpan>[];
  for (final ch in s.split('')) {
    final paren = ch == '(' || ch == ')';
    spans.add(TextSpan(
      text: ch,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w500,
        fontSize: paren ? 13 : 19,
      ),
    ));
  }
  return RichText(textAlign: TextAlign.center, text: TextSpan(children: spans));
}

/// Small preview of the home ring drawn with just the coloured balls, reusing
/// the same marble rendering as the main ring (the "swap permutation preview").
class _SwapPreview extends StatelessWidget {
  final List<int> colorOfBall;
  const _SwapPreview(this.colorOfBall);
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 132,
        height: 138,
        child: CustomPaint(painter: _RingPreviewPainter(colorOfBall)),
      );
}

class _RingPreviewPainter extends CustomPainter {
  final List<int> colorOfBall;
  _RingPreviewPainter(this.colorOfBall);

  @override
  void paint(Canvas canvas, Size size) {
    final n = colorOfBall.length;
    final halfW = size.width / 2;
    final ballR = 0.1375 * halfW;
    final circleR = halfW - 2 * ballR;
    final center = Offset(size.width / 2, circleR + 2.5 * ballR + ballR);

    Offset slot(int i) {
      if (i == 0) return center - Offset(0, circleR + 2.5 * ballR);
      final a = (2 * math.pi / (n - 1)) * (i - 1) - math.pi / 2;
      return center + Offset(circleR * math.cos(a), circleR * math.sin(a));
    }

    for (var v = 0; v < n; v++) {
      final c = slot(v); // home position: ball v at slot v
      final color = _palette[colorOfBall[v] % _palette.length];
      canvas.drawCircle(c, ballR, Paint()..shader = marbleShader(color, c, ballR));
      final tp = TextPainter(
        text: TextSpan(
          text: '$v',
          style: TextStyle(color: Colors.black, fontSize: ballR * 0.85, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RingPreviewPainter old) => !listEquals(old.colorOfBall, colorOfBall);
}
