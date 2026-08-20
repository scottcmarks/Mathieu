import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/skin/registry.dart';
import 'package:mathieu/skin/registry_packs.g.dart';
import 'package:mathieu/skin/skin.dart';

class _FakeSensitiveSkin extends Skin {
  const _FakeSensitiveSkin();
  @override
  String get id => 'fake-device';
  @override
  String get displayName => 'Fake Device';
  @override
  bool get sensitive => true;
  @override
  SkinVocabulary get vocab => const SkinVocabulary();
  @override
  SkinPalette get palette => throw UnimplementedError();
  @override
  SkinGeometry get geometry => const SkinGeometry();
  @override
  SkinPainter get painter => throw UnimplementedError();
  @override
  SkinMotion get motion => throw UnimplementedError();
  @override
  SkinSound get sound => const SkinSound();
}

void main() {
  setUp(() {
    SkinRegistry.debugReset();
    registerBuiltinSkins();
  });

  test('the default pack always ships, and is registered first', () {
    expect(SkinRegistry.has('default'), isTrue);
    expect(SkinRegistry.ids.first, 'default');
  });

  test('a clean tree has no device packs', () {
    // packs_private/ is gitignored here; the packs live in a wapex-only repo.
    for (final id in SkinRegistry.ids) {
      expect(SkinRegistry.get(id).sensitive, isFalse, reason: id);
    }
  });

  test('an unknown or null id falls back to default, silently', () {
    expect(SkinRegistry.get('flatpack').id, 'default');
    expect(SkinRegistry.get(null).id, 'default');
    expect(SkinRegistry.get('').id, 'default');
  });

  test('debug assert catches a sensitive pack in an un-gated build', () {
    SkinRegistry.register('fake-device', _FakeSensitiveSkin.new);
    expect(SkinRegistry.debugAssertNothingSensitive, throwsA(isA<Error>()));
  });
}
