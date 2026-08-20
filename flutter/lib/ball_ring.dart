import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'skin/skin.dart';

/// The ring of pieces. Marks tween between their previous and current seats by
/// [t]. Finger gestures: drag around to rotate (instant per wedge), pull the
/// outboard piece down to swap. Geometry ported from BallRingView.mm and now
/// supplied by [skin] — with the default pack it is that port, unchanged.
///
/// Layers, bottom to top: board furniture, seat tags, pieces, numerals, overlay,
/// centre controls. The two painter layers are new; the default skin draws
/// nothing in either.
class BallRing extends StatefulWidget {
  final Skin skin;
  final List<int> prevArrangement;
  final List<int> arrangement;
  final double t;
  final bool arc; // rotations spin marks along the arc; else straight lines
  final List<int> colorOfBall;

  /// Seats to call out while a macro is being replayed step by step. Empty in
  /// ordinary play, so the shipped look is unchanged.
  final Set<int> highlight;

  final VoidCallback onLeft, onRight, onSwap;
  final void Function(bool right) onRotateDrag;
  const BallRing({
    super.key,
    required this.skin,
    required this.prevArrangement,
    required this.arrangement,
    required this.t,
    required this.arc,
    required this.colorOfBall,
    this.highlight = const <int>{},
    required this.onLeft,
    required this.onRight,
    required this.onSwap,
    required this.onRotateDrag,
  });

  @override
  State<BallRing> createState() => _BallRingState();
}

class _BallRingState extends State<BallRing> with TickerProviderStateMixin {
  static const _flickThreshold = 3.0; // rad/s to trigger momentum
  static const _stopThreshold = 0.5; // rad/s below which momentum settles
  static const _decayPerSec = 0.12; // fraction of angular speed kept per second

  late BoardMetrics _m;

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

  // Position of the mark for value v. With the default skin the coloured pieces
  // stay put and only the numerals move; a pack whose motion sets piecesTravel
  // moves the piece along the same path.
  Offset _markPos(int v, double t) {
    final ps = widget.prevArrangement.indexOf(v);
    final cs = widget.arrangement.indexOf(v);
    return widget.skin.motion.markPath(_m, ps, cs, t, arc: widget.arc);
  }

  void _onStart(DragStartDetails d) {
    final p = d.localPosition;
    if ((p - _m.apex).distance <= _m.pieceR * 1.6) {
      _swapMode = true;
      _swapFired = false;
    } else {
      _swapMode = false;
      _lastAngle = (p - _m.center).direction;
      _momentum?.stop(); // grabbing mid-spin continues from here
      _settle.stop();
    }
  }

  void _onUpdate(DragUpdateDetails d) {
    final p = d.localPosition;
    if (_swapMode) {
      if (!_swapFired && (p.dy - _m.apex.dy) > _m.pieceR * 1.1) {
        _swapFired = true;
        widget.onSwap();
      }
      return;
    }
    final ang = (p - _m.center).direction;
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
    final omega = (-v.dx * math.sin(_lastAngle) + v.dy * math.cos(_lastAngle)) / _m.ringR;
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
    final skin = widget.skin;
    final pal = skin.palette;
    return LayoutBuilder(builder: (context, c) {
      _m = BoardMetrics.board(skin.geometry,
          n: _n, size: Size(c.maxWidth, c.maxHeight), spin: _spin);
      final m = _m;
      final anim = MoveAnim(
        from: widget.prevArrangement,
        to: widget.arrangement,
        t: widget.t,
        arc: widget.arc,
        highlight: widget.highlight,
      );

      final children = <Widget>[];

      // board furniture (lanes, deck, pipe, rotor hub) — nothing in the default skin
      children.add(Positioned.fill(
        child: CustomPaint(painter: _BoardLayer(skin, m, anim, overlay: false)),
      ));

      // tags (fixed gray "home" position numbers)
      final tagStyle = skin.painter.seatTagStyle(m, pal);
      for (var i = 0; i < _n; i++) {
        final tagPos = m.tagPos(i);
        children.add(Positioned(
          left: tagPos.dx - m.pieceR,
          top: tagPos.dy - m.tagFont / 2,
          width: m.pieceR * 2,
          child: Text('$i', textAlign: TextAlign.center, style: tagStyle),
        ));
      }

      // the pieces. Default rule: they are static furniture and their colour
      // shows each seat's swap pair. A pack with piecesTravel moves them, and
      // then the colour belongs to the piece (its home seat's pair) instead.
      final travel = skin.motion.piecesTravel;
      for (var i = 0; i < _n; i++) {
        final ctr = travel ? _markPos(i, widget.t) : m.seat(i);
        children.add(Positioned(
          left: ctr.dx - m.pieceR,
          top: ctr.dy - m.pieceR,
          child: _Piece(
            skin: skin,
            color: pal.pieceColor(widget.colorOfBall[i]),
            r: m.pieceR,
            seat: i,
          ),
        ));
      }

      // moving numerals: pieces stay, numbers exchange (swap) / spin (rotate)
      final numeralStyle = skin.painter.numeralStyle(m, pal);
      for (var v = 0; v < _n; v++) {
        final ctr = _markPos(v, widget.t);
        children.add(Positioned(
          left: ctr.dx - m.pieceR,
          top: ctr.dy - m.pieceR,
          width: m.pieceR * 2,
          height: m.pieceR * 2,
          child: Center(child: Text('$v', style: numeralStyle)),
        ));
      }

      // overlay (rotor arms, shutters, step-through highlight) — nothing by default
      children.add(Positioned.fill(
        child: CustomPaint(painter: _BoardLayer(skin, m, anim, overlay: true)),
      ));

      // centred Swap / Left+Right controls
      children.add(Positioned(
        left: m.center.dx - m.geometry.controlWidth / 2,
        top: m.center.dy + m.geometry.controlTopOffset,
        width: m.geometry.controlWidth,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _CtlButton(skin.vocab.swapVerb, widget.onSwap, pal.chrome),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _CtlButton(skin.vocab.spinLeft, widget.onLeft, pal.chrome),
            const SizedBox(width: 10),
            _CtlButton(skin.vocab.spinRight, widget.onRight, pal.chrome),
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

/// The two full-board painter layers: furniture below, overlay above.
class _BoardLayer extends CustomPainter {
  final Skin skin;
  final BoardMetrics m;
  final MoveAnim anim;
  final bool overlay;
  _BoardLayer(this.skin, this.m, this.anim, {required this.overlay});

  @override
  void paint(Canvas canvas, Size size) {
    if (overlay) {
      skin.painter.paintOverlay(canvas, m, skin.palette, anim);
    } else {
      skin.painter.paintBoard(canvas, m, skin.palette);
    }
  }

  // Metrics and anim are rebuilt every frame anyway, and an animated overlay
  // wants every frame; the default skin's layers paint nothing either way.
  @override
  bool shouldRepaint(_BoardLayer old) => true;
}

class _Piece extends StatelessWidget {
  final Skin skin;
  final Color color;
  final double r;
  final int seat;
  const _Piece({required this.skin, required this.color, required this.r, required this.seat});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: r * 2,
        height: r * 2,
        child: CustomPaint(painter: _PiecePainter(skin, color, seat)),
      );
}

class _PiecePainter extends CustomPainter {
  final Skin skin;
  final Color color;
  final int seat;
  _PiecePainter(this.skin, this.color, this.seat);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    skin.painter.paintPiece(canvas, Offset(r, r), r, color, seat);
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.color != color || old.seat != seat || old.skin != skin;
}

class _CtlButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _CtlButton(this.label, this.onTap, this.color);
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(label, style: TextStyle(color: color, fontSize: 17)),
        ),
      );
}
