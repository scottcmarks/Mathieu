import 'package:flutter_test/flutter_test.dart';
import 'package:mathieu/deeplink.dart';

void main() {
  test('web fragment', () {
    final r = DeepLinkRequest.parse('#skin=flatpack&lesson=6&swap=21&word=RSRS');
    expect(r.skinId, 'flatpack');
    expect(r.lesson, 6);
    expect(r.swapIndex, 21);
    expect(r.word, 'RSRS');
  });

  test('custom scheme carries the same grammar', () {
    final r = DeepLinkRequest.parse('m12://open?skin=marbles&lesson=1');
    expect(r.skinId, 'marbles');
    expect(r.lesson, 1);
    expect(r.swapIndex, isNull);
    expect(r.word, isNull);
  });

  test('bare key=value, and a lowercase word is normalised', () {
    final r = DeepLinkRequest.parse('skin=default&word=r3sl2s');
    expect(r.skinId, 'default');
    expect(r.word, 'R3SL2S');
  });

  test('nothing to act on', () {
    expect(DeepLinkRequest.parse(null).isEmpty, isTrue);
    expect(DeepLinkRequest.parse('').isEmpty, isTrue);
    expect(DeepLinkRequest.parse('#').isEmpty, isTrue);
    expect(DeepLinkRequest.parse('/index.html').isEmpty, isTrue);
  });

  test('junk is dropped, never thrown', () {
    final r = DeepLinkRequest.parse('#skin=&lesson=abc&swap=&word=hello%20there');
    expect(r.skinId, isNull);
    expect(r.lesson, isNull);
    expect(r.swapIndex, isNull);
    expect(r.word, isNull); // not a word in the generators
  });

  test('an unknown skin id parses fine — the registry is what falls back', () {
    // A booklet printed for a gated pack must not error; resolution happens in
    // SkinRegistry.get, which returns the default for any unregistered id.
    expect(DeepLinkRequest.parse('#skin=no-such-pack').skinId, 'no-such-pack');
  });

  test('a lesson-only link, which is what most booklet QRs will be', () {
    final r = DeepLinkRequest.parse('#lesson=5');
    expect(r.lesson, 5);
    expect(r.skinId, isNull);
    expect(r.isEmpty, isFalse);
  });

  test('an out-of-range lesson still parses — LessonPage clamps it', () {
    // Clamping belongs where the lesson list is known, not in the grammar: a
    // booklet printed against a build with L0 gated off must still open.
    expect(DeepLinkRequest.parse('#lesson=99').lesson, 99);
    expect(DeepLinkRequest.parse('#lesson=-3').lesson, -3);
  });

  test('a word deep link accepts every notation the app writes', () {
    expect(DeepLinkRequest.parse('#word=RSRS').word, 'RSRS');
    expect(DeepLinkRequest.parse('#word=L2SR3').word, 'L2SR3');
    expect(DeepLinkRequest.parse('#word=A').word, 'A');
  });
}
