import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, ScoreRing ring) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: ring)),
    ),
  );
}

RenderBox _paintBox(WidgetTester tester) => tester.renderObject<RenderBox>(
  find
      .descendant(
        of: find.byType(ScoreRing),
        matching: find.byType(CustomPaint),
      )
      .first,
);

void main() {
  testWidgets('shows the percent sign by default', (tester) async {
    await _pump(tester, const ScoreRing(percent: 78));

    expect(find.text('78%'), findsOneWidget);
  });

  testWidgets('can show the bare number', (tester) async {
    await _pump(tester, const ScoreRing(percent: 78, showPercentSign: false));

    expect(find.text('78'), findsOneWidget);
    expect(find.text('78%'), findsNothing);
  });

  testWidgets('clamps the value to 0–100', (tester) async {
    await _pump(tester, const ScoreRing(percent: 140));

    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('the arc is amber unless another colour is given', (
    tester,
  ) async {
    await _pump(tester, const ScoreRing(percent: 50));
    expect(_paintBox(tester), paints..arc(color: AppColors.accent));

    await _pump(tester, const ScoreRing(percent: 50, color: AppColors.success));
    expect(_paintBox(tester), paints..arc(color: AppColors.success));
  });

  testWidgets('a zero score draws only the track', (tester) async {
    await _pump(tester, const ScoreRing(percent: 0));

    expect(_paintBox(tester), isNot(paints..arc()));
  });
}
