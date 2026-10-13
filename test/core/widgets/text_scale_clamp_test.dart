import 'package:careermatebd/core/widgets/text_scale_clamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// What a 10pt font scales to under the clamp, at a given system text scale.
  Future<double> scaledTen(WidgetTester tester, double systemScale) async {
    tester.platformDispatcher.textScaleFactorTestValue = systemScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    late double scaled;
    await tester.pumpWidget(
      MaterialApp(
        home: TextScaleClamp(
          child: Builder(
            builder: (context) {
              scaled = MediaQuery.textScalerOf(context).scale(10);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return scaled;
  }

  testWidgets('caps the text scale at 1.5x', (tester) async {
    expect(await scaledTen(tester, 2.0), closeTo(15, 0.001));
    expect(await scaledTen(tester, 3.0), closeTo(15, 0.001));
  });

  testWidgets('leaves sizes up to 1.5x untouched', (tester) async {
    expect(await scaledTen(tester, 1.0), closeTo(10, 0.001));
    expect(await scaledTen(tester, 1.3), closeTo(13, 0.001));
    expect(await scaledTen(tester, 1.5), closeTo(15, 0.001));
  });

  testWidgets('isLargeText turns on above 1.3x', (tester) async {
    Future<bool> large(double scale) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = isLargeText(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    expect(await large(1.0), isFalse);
    expect(await large(1.3), isFalse);
    expect(await large(1.4), isTrue);
    expect(await large(1.5), isTrue);
  });
}
