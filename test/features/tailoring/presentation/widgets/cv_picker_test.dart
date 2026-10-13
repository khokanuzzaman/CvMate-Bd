import 'package:careermatebd/features/tailoring/presentation/widgets/cv_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/design_cv.dart';

Future<void> _pump(WidgetTester tester, CvPickerCard card) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));
}

void main() {
  testWidgets('shows the CV and its template by default', (tester) async {
    await _pump(tester, CvPickerCard(cv: designCv(), onTap: () {}));

    expect(find.text('Frontend Developer CV'), findsOneWidget);
    expect(find.text('Modern template'), findsOneWidget);
  });

  testWidgets('a subtitle replaces the template line', (tester) async {
    await _pump(
      tester,
      CvPickerCard(cv: designCv(), onTap: () {}, subtitle: 'Checked just now'),
    );

    expect(find.text('Checked just now'), findsOneWidget);
    expect(find.text('Modern template'), findsNothing);
  });

  testWidgets('with no CV it shows the empty label', (tester) async {
    await _pump(
      tester,
      CvPickerCard(cv: null, onTap: () {}, emptyLabel: 'No CV selected'),
    );

    expect(find.text('No CV selected'), findsOneWidget);
  });

  testWidgets('is not tappable while busy', (tester) async {
    var taps = 0;
    await _pump(tester, CvPickerCard(cv: designCv(), onTap: () => taps++));
    await tester.tap(find.byType(CvPickerCard));
    expect(taps, 1);

    await _pump(tester, CvPickerCard(cv: designCv(), onTap: null));
    await tester.tap(find.byType(CvPickerCard));
    expect(taps, 1);
  });
}
