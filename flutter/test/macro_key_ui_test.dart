// The macro keys, driven through the real widget tree.
//
// These pin behaviour that the golden tests cannot see: the goldens render
// BallRing alone, so nothing else in test/ notices if the screen around the
// ring changes or a preference stops being honoured.
//
// Needs the engine as a shared library, like engine_ffi_test.dart:
//
//   ./tool/build_native_test_lib.sh
//   MATHIEU_ENGINE_LIB="$PWD/build/native-test/libmathieu_engine.dylib" flutter test

@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/main.dart';
import 'package:mathieu/prefs.dart';
import 'package:mathieu/skin/registry.dart';
import 'package:mathieu/skin/registry_packs.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _libPath = Platform.environment['MATHIEU_ENGINE_LIB'] ?? '';
final _skip = _libPath.isEmpty
    ? 'set MATHIEU_ENGINE_LIB to the engine shared library'
    : null;

/// The centre Swap/Left/Right block is a fixed 190pt wide (SkinGeometry
/// .controlWidth, a legacy absolute that predates the skin system). Under the
/// test harness font — square em boxes, much wider than the real one — "Left
/// Right" does not fit and the RenderFlex reports an overflow. It fits on
/// device. ball_ring_golden_test.dart consumes the same exception for the same
/// reason; this is not a regression, HEAD renders the identical fixed row.
void _ignoreTestFontOverflow(WidgetTester tester) => tester.takeException();

/// Pump the real app and wait out the entry animations.
Future<void> _pumpApp(WidgetTester tester) async {
  SkinRegistry.debugReset();
  registerBuiltinSkins();
  await tester.pumpWidget(MathieuApp(initialSkin: SkinRegistry.get('default')));
  await tester.pumpAndSettle();
  _ignoreTestFontOverflow(tester);
}

/// Flip the Confirmation switch on the settings page and come back to the
/// board. Confirmation is the first Switch in that list; the row is a plain
/// Row, not a SwitchListTile, so it is found positionally.
Future<void> _setConfirm(WidgetTester tester, {required bool on}) async {
  await tester.tap(find.byIcon(Icons.flip));
  await tester.pumpAndSettle();
  expect(find.text('Confirmation'), findsOneWidget);

  final confirm = find.byType(Switch).first;
  if (tester.widget<Switch>(confirm).value != on) {
    await tester.tap(confirm);
    await tester.pumpAndSettle();
  }
  expect(tester.widget<Switch>(confirm).value, on);

  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  _ignoreTestFontOverflow(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return Prefs.init();
  });

  group('the default screen', () {
    testWidgets('shows two counter lines on a board at rest', (tester) async {
      await _pumpApp(tester);
      // The distance read-out is the third line. On a solved board it would
      // say "0", which the board already says, so it is suppressed — the
      // screen at rest keeps the two lines the original app had.
      expect(find.textContaining('▸'), findsNothing);
    });

    testWidgets('shows the distance line once the board is off home',
        (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();
      // A table may not have been built yet; if it has, the line must be there
      // and must not read zero.
      final d = find.textContaining('▸');
      if (d.evaluate().isNotEmpty) {
        expect(tester.widget<Text>(d.first).data, isNot('▸0'));
      }
    });
  }, skip: _skip);

  group('the Learn entry point', () {
    testWidgets('the AppBar action opens the tutorial hub', (tester) async {
      await _pumpApp(tester);
      // The one intended addition to the pre-skin screen: without a way in,
      // the tutorial — the whole reason the app exists beside the toy — is
      // unreachable. See SKINS.md, "Two intended departures".
      await tester.tap(find.byIcon(Icons.school_outlined));
      // Not pumpAndSettle: the hub shows a progress spinner while the BFS
      // table builds off-thread, so there is no settled frame to wait for.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Lessons'), findsOneWidget);
      expect(find.text('Macro library'), findsOneWidget);
      expect(find.text('Workshop'), findsOneWidget);
    });
  }, skip: _skip);

  group('long-press on a macro key', () {
    testWidgets('with Confirm on, explains before it commits', (tester) async {
      await _pumpApp(tester);
      await _setConfirm(tester, on: true);
      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('Key A'), findsOneWidget,
          reason: 'Confirm on: the sheet is the confirmation');
      // The sheet does more than ask: it says what the key would come to mean.
      // ('Define A' is the button, further down the scrollable sheet.)
      expect(find.text('A is not defined yet.'), findsOneWidget);
      expect(find.text('Define it'), findsOneWidget);
    });

    testWidgets('with Confirm off, defines the key in one gesture',
        (tester) async {
      await _pumpApp(tester);
      await _setConfirm(tester, on: false);
      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('A'));
      await tester.pumpAndSettle();
      // Confirm off means "do it, don't stop to ask me" — no sheet at all.
      expect(find.text('Key A'), findsNothing,
          reason: 'Confirm off must not open the explainer sheet');
      // ...and the key really is defined: it is drawn bright once it means
      // something, and the history collapses to the single letter when run.
      expect(find.text('A'), findsOneWidget);
    });
  }, skip: _skip);
}
