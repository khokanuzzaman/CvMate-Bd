import 'dart:io';

import 'package:careermatebd/core/theme/cv_mate_theme.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_preview_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/screenshot_harness.dart';
import '../../../../helpers/template_fixtures.dart';

/// Every template's preview with the three QA fixtures (docs/qa/templates/):
/// no overflow, every value shown, no empty section titles. Goldens for the
/// full and minimal CVs use the real app fonts; they are compared on macOS
/// only, since text rasterises slightly differently on the Linux CI runners.
void main() {
  setUpAll(loadTestFonts);

  final boundary = GlobalKey();

  Future<String> pumpPreview(WidgetTester tester, FixtureCv cv) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    Widget app() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CvMateTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: boundary,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CvPreviewContent(profile: cv.profile),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    // Grow the surface to the whole sheet so the golden shows all of it.
    final height = tester.getSize(find.byKey(boundary)).height;
    tester.view.physicalSize = Size(390, height);
    await tester.pumpAndSettle();

    return [
      for (final text in tester.widgetList<RichText>(find.byType(RichText)))
        text.text.toPlainText(),
    ].join('\n').toLowerCase();
  }

  // Regression: the preview left out two things the PDF prints.
  testWidgets('shows an experience location and a skill level', (
    tester,
  ) async {
    final shown = await pumpPreview(tester, fullCv(CvTemplate.classic));

    expect(shown, contains('chattogram'));
    expect(shown, contains('react · advanced'));
  });

  for (final template in CvTemplate.values) {
    for (final fixture in TemplateFixture.values) {
      testWidgets('${template.name} preview, ${fixture.name} CV', (
        tester,
      ) async {
        final cv = fixtureCv(fixture, template);
        final shown = await pumpPreview(tester, cv);

        // A RenderFlex overflow or any other layout error lands here.
        expect(tester.takeException(), isNull);
        for (final value in cv.expected) {
          expect(shown, contains(value.toLowerCase()), reason: value);
        }
        for (final title in cv.absentTitles) {
          expect(shown, isNot(contains(title.toLowerCase())), reason: title);
        }

        if (fixture != TemplateFixture.nonAscii && Platform.isMacOS) {
          await expectLater(
            find.byKey(boundary),
            matchesGoldenFile('goldens/${template.name}_${fixture.name}.png'),
          );
        }
      });
    }
  }
}
