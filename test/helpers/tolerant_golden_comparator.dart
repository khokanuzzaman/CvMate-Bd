import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A golden comparator that passes when at most [maxDiffRate] of the pixels
/// differ (default 1%), so a macOS update that shifts text anti-aliasing a
/// little does not fail the goldens. A real layout change moves far more.
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.maxDiffRate = 0.01});

  final double maxDiffRate;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= maxDiffRate) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
