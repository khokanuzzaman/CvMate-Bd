import 'dart:io';

import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/shared/services/pdf/cv_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/poppler.dart';
import '../../../helpers/template_fixtures.dart';

/// Exports every template with the three QA fixtures on A4 and Letter and reads
/// the result back with poppler, as a viewer or an ATS would. See
/// docs/qa/templates/README.md for what is checked and the known failures.
///
/// Set CVMATE_QA_PDF_DIR to also save each template's full A4 export there.
void main() {
  // Lets the service load the bundled Bengali fallback font from assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  final skip = Poppler.available ? false : 'poppler (pdftotext) not installed';
  final saveDir = Platform.environment['CVMATE_QA_PDF_DIR'];
  late Directory tmp;

  setUpAll(() => tmp = Directory.systemTemp.createTempSync('cv_pdf_qa'));
  tearDownAll(() => tmp.deleteSync(recursive: true));

  Future<File> export(FixtureCv cv, PaperSize paper, String name) async {
    final bytes = await const CvPdfService().generateCvPdf(
      profile: cv.profile,
      pageFormat: CvPdfService.pageFormatFor(paper),
      exportDate: DateTime(2026, 11, 17),
    );
    return File('${tmp.path}/$name.pdf')..writeAsBytesSync(bytes);
  }

  /// The text without the "Page 1 of 3" footers, so a bullet that continues
  /// on the next page still reads as one sentence.
  String bodyText(File pdf) => Poppler.collapse(
    Poppler.text(pdf).replaceAll(RegExp(r'Page \d+ of \d+'), ' '),
  );

  const standard14 = ['Helvetica', 'Times', 'Courier', 'Symbol', 'Zapf'];

  for (final template in CvTemplate.values) {
    for (final fixture in TemplateFixture.values) {
      for (final paper in PaperSize.values) {
        final name = '${template.name}_${fixture.name}_${paper.name}';
        test(name, skip: skip, () async {
          final cv = fixtureCv(fixture, template);
          final pdf = await export(cv, paper, name);

          // Some templates print section titles in capitals.
          final text = bodyText(pdf).toLowerCase();
          for (final value in cv.expected) {
            // There is no emoji font in the PDF: the emoji is dropped and the
            // rest of the bullet kept (a known FAIL, see the README).
            final printable = value.replaceAll('🚀', '').trim().toLowerCase();
            expect(text, contains(printable), reason: printable);
          }
          for (final title in cv.absentTitles) {
            expect(text, isNot(contains(title.toLowerCase())), reason: title);
          }

          for (final font in Poppler.fonts(pdf)) {
            if (standard14.any(font.name.startsWith)) {
              continue; // Base-14 fonts are never embedded (known FAIL).
            }
            expect(font.embedded, isTrue, reason: '${font.name} embedded');
          }

          final info = Poppler.info(pdf);
          expect(
            info.size.toLowerCase(),
            paper == PaperSize.a4 ? 'a4' : 'letter',
          );
          expect(
            info.pages,
            fixture == TemplateFixture.full ? greaterThan(1) : 1,
            reason: 'page count',
          );

          if (saveDir != null &&
              fixture == TemplateFixture.full &&
              paper == PaperSize.a4) {
            pdf.copySync('$saveDir/${template.name}.pdf');
          }
        });
      }
    }
  }

  test(
    'an experience taller than a page flows on without losing a bullet',
    skip: skip,
    () async {
      final bullets = [
        for (var i = 1; i <= 60; i++)
          'Point $i of a very long role description pasted from a job post.',
      ];
      for (final template in CvTemplate.values) {
        final base = minimalCv(template);
        final cv = FixtureCv(
          base.profile.copyWith(
            experiences: [
              ExperienceInfo(
                id: 'long',
                jobTitle: 'Operations Lead',
                highlights: bullets,
              ),
            ],
          ),
          bullets,
        );
        final pdf = await export(cv, PaperSize.a4, 'long_${template.name}');
        final text = bodyText(pdf);
        for (final bullet in bullets) {
          expect(text, contains(bullet), reason: '${template.name}: $bullet');
        }
        expect(Poppler.info(pdf).pages, greaterThan(1));
      }
    },
  );
}
