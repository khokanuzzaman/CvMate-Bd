import 'dart:io';
import 'dart:typed_data';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_preview_pages_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/poppler.dart';
import '../../../../helpers/preview_pages.dart';
import '../../../../helpers/printing_mock.dart';
import '../../../../helpers/screenshot_harness.dart';
import '../../../../helpers/template_fixtures.dart';
import '../../../../helpers/template_look.dart';

/// Template QA on the real preview screen (docs/qa/templates/IDENTITY.md):
/// 1. each template's preview looks like that template (and no other),
/// 2. switching templates in the picker updates the preview and keeps the CV,
/// 3. the preview's pages are the exported PDF's pages.
/// The preview's pages come from poppler here (the platform renderer does not
/// exist in widget tests); the simulator run in docs/qa/templates/compare/
/// checks the iOS renderer.
void main() {
  // Skipped without poppler (`brew install poppler`).
  final skip = !Poppler.canRaster;
  late Directory tmp;

  setUpAll(() async {
    await loadTestFonts();
    tmp = Directory.systemTemp.createTempSync('cv_preview_qa');
  });
  tearDownAll(() => tmp.deleteSync(recursive: true));

  File save(Uint8List pdf, String name) =>
      File('${tmp.path}/$name.pdf')..writeAsBytesSync(pdf);

  Future<(ProviderContainer, CvPreviewPages)> openPreview(
    WidgetTester tester,
    CvProfile profile,
  ) async {
    final container = await pumpBuilderApp(
      tester,
      repository: FakeCvRepository([profile]),
      initialLocation: RouteNames.cvPreviewPath,
      loadDraftId: profile.id,
    );
    return (container, await waitForPreviewPages(tester, container));
  }

  TemplateLook look(Uint8List png, CvPreviewPages preview) =>
      lookOf(png, pageWidthPt: preview.pageFormat.width);

  group('1. template identity, read from the preview', () {
    for (final fixture in TemplateFixture.values) {
      for (final template in CvTemplate.values) {
        testWidgets('${template.name} / ${fixture.name}', skip: skip, (
          tester,
        ) async {
          final cv = fixtureCv(fixture, template);
          final (_, preview) = await openPreview(tester, cv.profile);
          final shown = shownPreviewPages(tester);
          final page1 = look(shown.first, preview);

          expect(
            page1.template,
            template,
            reason: 'page 1 should look like ${template.name}: $page1',
          );
          expect(
            page1.hasPhoto,
            cv.profile.photoToShow != null,
            reason: 'photo top right only when the CV has one',
          );

          final pdf = save(preview.pdf, '${template.name}_${fixture.name}');
          expect(shown.length, Poppler.info(pdf).pages, reason: 'page count');
          if (fixture == TemplateFixture.full) {
            expect(shown.length, 2, reason: 'fixture (a) is a 2-page CV');
          }

          // Section titles: capitals everywhere except Modern.
          final text = Poppler.text(pdf);
          final title = template == CvTemplate.modern
              ? 'Professional Summary'
              : 'PROFESSIONAL SUMMARY';
          expect(text, contains(title));

          // Fonts: Helvetica, plus Noto Sans Bengali for Bangla text.
          final fonts = {for (final f in Poppler.fonts(pdf)) f.name};
          expect(
            fonts.difference({
              'Helvetica',
              'Helvetica-Bold',
              'NotoSansBengali-Regular',
            }),
            isEmpty,
            reason: '$fonts',
          );
          if (fixture == TemplateFixture.nonAscii) {
            expect(fonts, contains('NotoSansBengali-Regular'));
          }
        });
      }
    }
  });

  group('2. switching templates in the picker', () {
    testWidgets(
      'every ordered pair of templates, the preview follows, the CV is kept',
      skip: skip,
      (tester) async {
        final cv = fixtureCv(TemplateFixture.full, CvTemplate.classic);
        final (container, first) = await openPreview(tester, cv.profile);
        expect(
          look(shownPreviewPages(tester).first, first).template,
          CvTemplate.classic,
        );

        Map<String, dynamic> data(CvProfile p) => CvProfileDto(p).toMap()
          ..remove('template')
          ..remove('updatedAt');
        final original = data(cv.profile);

        final path = everyOrderedPair(CvTemplate.values);
        expect(path.length, 21, reason: '20 switches, back to the start');
        for (final template in path.skip(1)) {
          await tester.tap(
            find.text(
              container.read(cvBuilderControllerProvider).draft.template.label,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(template.label).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text(AppStrings.templateUse(template.label)));
          await tester.pumpAndSettle();

          final preview = await waitForPreviewPages(tester, container);
          final shown = shownPreviewPages(tester);
          expect(preview.profile.template, template);
          expect(
            look(shown.first, preview).template,
            template,
            reason: 'preview after switching to ${template.name}',
          );
          expect(find.text(template.label), findsOneWidget, reason: 'pill');
          expect(
            data(container.read(cvBuilderControllerProvider).draft),
            original,
            reason: 'no data lost switching to ${template.name}',
          );
        }

        // And everything still prints.
        final preview = container.read(cvPreviewPagesProvider).requireValue;
        final text = Poppler.text(
          save(preview.pdf, 'after_switching'),
        ).replaceAll(RegExp(r'Page \d+ of \d+'), ' ').toLowerCase();
        for (final value in cv.expected) {
          expect(text, contains(value.toLowerCase()), reason: value);
        }
      },
    );
  });

  group('3. preview pages = exported PDF pages', () {
    for (final fixture in TemplateFixture.values) {
      for (final template in CvTemplate.values) {
        testWidgets('${template.name} / ${fixture.name}', skip: skip, (
          tester,
        ) async {
          final shares = mockSharePlugin(tester);
          final cv = fixtureCv(fixture, template);
          final (_, preview) = await openPreview(tester, cv.profile);
          final shown = shownPreviewPages(tester);

          await tester.tap(
            find.widgetWithText(PrimaryButton, AppStrings.previewExport),
          );
          for (var i = 0; i < 50 && shares.isEmpty; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await tester.pump();
          }
          final call = shares.singleWhere((c) => c.method == 'sharePdf');
          // Not byte-identical: the pdf package stamps the creation time.
          final exported = save(
            (call.arguments as Map)['doc'] as Uint8List,
            'export_${template.name}_${fixture.name}',
          );
          final previewPdf = save(
            preview.pdf,
            'preview_${template.name}_${fixture.name}',
          );
          final exportedPages = Poppler.raster(exported, dpi: cvPreviewDpi);

          // Same page breaks.
          expect(shown.length, exportedPages.length, reason: 'page count');
          for (var p = 0; p < shown.length; p++) {
            expect(
              Poppler.pageText(previewPdf, p + 1),
              Poppler.pageText(exported, p + 1),
              reason: 'text of page ${p + 1}',
            );
            final a = look(shown[p], preview);
            final b = look(exportedPages[p], preview);
            expect('$a', '$b', reason: 'layout of page ${p + 1}');
            expect(
              differingPixels(shown[p], exportedPages[p]),
              lessThan(0.005),
              reason: 'pixels of page ${p + 1}',
            );
          }

          // Nothing cut off: every value of the CV is in the export.
          final text = Poppler.collapse(
            Poppler.text(exported).replaceAll(RegExp(r'Page \d+ of \d+'), ' '),
          ).toLowerCase();
          for (final value in cv.expected) {
            // No emoji font in the PDF (a known FAIL, see the README).
            final printable = value.replaceAll('🚀', '').trim().toLowerCase();
            expect(text, contains(printable), reason: printable);
          }
        });
      }
    }
  });
}

/// A walk through [items] that takes every ordered pair (a to b, for every
/// a != b) exactly once and ends where it started: an Euler circuit of the
/// complete directed graph.
List<T> everyOrderedPair<T>(List<T> items) {
  final next = {
    for (final a in items)
      a: [
        for (final b in items)
          if (b != a) b,
      ],
  };
  final stack = [items.first];
  final path = <T>[];
  while (stack.isNotEmpty) {
    final top = stack.last;
    if (next[top]!.isNotEmpty) {
      stack.add(next[top]!.removeAt(0));
    } else {
      path.add(stack.removeLast());
    }
  }
  return path.reversed.toList();
}
