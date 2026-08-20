// Pixel guard for the default skin.
//
// These goldens were captured from the pre-skin-system BallRing (the verbatim
// port of BallRingView.mm) and MUST keep matching after any skin refactor:
// with the default skin selected the board has to render exactly as it did.
// Regenerate ONLY when a change to the default look is intended:
//   flutter test --update-goldens test/ball_ring_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/ball_ring.dart';
import 'package:mathieu/skin/packs/default_pack.dart';

// colorIndicesFor((0 1)(2 9)(3 4)(5 6)(7 8)(10 11)) — a swap pair shares a colour.
const _colorOfBall = <int>[0, 0, 1, 2, 2, 3, 3, 4, 4, 1, 5, 5];
const _home = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

// One swap: the apex (seat 0) exchanges with seat 1.
const _swapped = <int>[1, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

// One right rotation of the 11 ring seats (the apex is fixed).
const _rotated = <int>[0, 11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

Widget _harness(Size size, {required Widget child}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(child: SizedBox.fromSize(size: size, child: child)),
      ),
    );

Widget _ring({
  required List<int> prev,
  required List<int> curr,
  required double t,
  required bool arc,
}) =>
    BallRing(
      skin: const DefaultSkin(),
      prevArrangement: prev,
      arrangement: curr,
      t: t,
      arc: arc,
      colorOfBall: _colorOfBall,
      onLeft: _noop,
      onRight: _noop,
      onSwap: _noop,
      onRotateDrag: _noopDrag,
    );

void _noop() {}
void _noopDrag(bool right) {}

// The centre Swap/Left/Right block is a fixed 190pt wide (a legacy absolute, see
// SkinGeometry.controlWidth). Under the test harness font — square em boxes,
// much wider than the real one — "Left  Right" does not fit and the RenderFlex
// reports an overflow. It fits on device; consume it so the golden still
// captures. The striped indicator is baked into the golden either way, so the
// before/after comparison remains exact.
void _ignoreTestFontOverflow(WidgetTester tester) => tester.takeException();

void main() {
  for (final size in const [Size(360, 640), Size(320, 480), Size(414, 736)]) {
    final tag = '${size.width.round()}x${size.height.round()}';

    testWidgets('ring at home $tag', (tester) async {
      await tester.pumpWidget(_harness(size,
          child: _ring(prev: _home, curr: _home, t: 1, arc: false)));
      _ignoreTestFontOverflow(tester);
      await expectLater(find.byType(BallRing),
          matchesGoldenFile('goldens/ring_home_$tag.png'));
    });

    testWidgets('ring mid-swap $tag', (tester) async {
      await tester.pumpWidget(_harness(size,
          child: _ring(prev: _home, curr: _swapped, t: 0.5, arc: false)));
      _ignoreTestFontOverflow(tester);
      await expectLater(find.byType(BallRing),
          matchesGoldenFile('goldens/ring_swap_$tag.png'));
    });

    testWidgets('ring mid-rotation $tag', (tester) async {
      await tester.pumpWidget(_harness(size,
          child: _ring(prev: _home, curr: _rotated, t: 0.35, arc: true)));
      _ignoreTestFontOverflow(tester);
      await expectLater(find.byType(BallRing),
          matchesGoldenFile('goldens/ring_rotate_$tag.png'));
    });
  }
}
