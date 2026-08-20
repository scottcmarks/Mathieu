// Pixel guard for the settings-page swap preview. Captured from the pre-skin
// system painter; the preview must keep rendering identically under the default
// skin (it is a second, smaller copy of the ring and easy to leave behind).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/skin/packs/default_pack.dart';
import 'package:mathieu/swap_preview.dart';

const _colorOfBall = <int>[0, 0, 1, 2, 2, 3, 3, 4, 4, 1, 5, 5];

void main() {
  testWidgets('swap preview', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: SwapPreview(DefaultSkin(), _colorOfBall)),
      ),
    ));
    await expectLater(
        find.byType(SwapPreview), matchesGoldenFile('goldens/swap_preview.png'));
  });
}
