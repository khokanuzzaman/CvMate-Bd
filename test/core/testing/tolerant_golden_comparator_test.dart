import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../helpers/tolerant_golden_comparator.dart';

/// A 100×100 white PNG with the first [changed] pixels painted black.
List<int> _png(int changed) {
  final image = img.Image(width: 100, height: 100)
    ..clear(img.ColorRgb8(255, 255, 255));
  for (var i = 0; i < changed; i++) {
    image.setPixelRgb(i % 100, i ~/ 100, 0, 0, 0);
  }
  return img.encodePng(image);
}

void main() {
  testWidgets('a diff of at most 1% of pixels passes; more than 1% fails', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('golden_tolerance');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/golden.png').writeAsBytesSync(_png(0));
    final comparator = TolerantGoldenComparator(
      Uri.file('${dir.path}/test.dart'),
    );
    final golden = Uri.parse('golden.png');

    await tester.runAsync(() async {
      // 100 of 10,000 pixels = 1%.
      expect(
        await comparator.compare(Uint8List.fromList(_png(100)), golden),
        isTrue,
      );
      // 200 of 10,000 pixels = 2%.
      await expectLater(
        comparator.compare(Uint8List.fromList(_png(200)), golden),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
