import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/builder_harness.dart' show FakeEntitlementStore;
import '../../test/helpers/printing_mock.dart';
import '../../test/helpers/template_fixtures.dart';
import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

/// Template QA on a simulator (docs/qa/templates/compare/): for the full and
/// the Bangla fixture, switch through every template in the picker and keep,
/// per template, a screenshot of the preview, the preview's PDF and its pages as
/// the device rendered them, and the exported PDF. `tool/template_compare.dart` then
/// compares them on the Mac.
void registerTemplateCompareFlow() {
  for (final fixture in [TemplateFixture.full, TemplateFixture.nonAscii]) {
    qaTest(
      'templates: ${fixture.name} CV, every template, preview vs export',
      timeout: const Timeout(Duration(minutes: 10)),
      (tester) async {
        final shares = mockSharePlugin(tester);
        // Enough free exports for one export per template.
        await launchSignedIn(
          tester,
          overrides: [
            entitlementServiceProvider.overrideWithValue(
              EntitlementService(FakeEntitlementStore(), freeExportLimit: 100),
            ),
          ],
        );
        final title = 'QA ${fixture.name} CV';
        final cv = fixtureCv(
          fixture,
          CvTemplate.classic,
        ).profile.copyWith(title: title, updatedAt: DateTime.now());
        await seedCv(tester, cv);

        await tapText(tester, title);
        await waitFor(tester, find.text(AppStrings.previewExport));

        Map<String, dynamic> data(CvProfile p) => CvProfileDto(p).toMap()
          ..remove('template')
          ..remove('updatedAt');
        final original = data(cv);
        var current = CvTemplate.classic;

        for (final template in [...CvTemplate.values, CvTemplate.classic]) {
          if (template != current) {
            await tapText(tester, current.label);
            await waitFor(tester, find.text(AppStrings.templateTitle));
            await tapOn(tester, find.text(template.label).last);
            await tapText(tester, AppStrings.templateUse(template.label));
            await waitFor(tester, find.text(AppStrings.previewExport));
            current = template;
          }
          final preview = await waitForPreviewPdf(tester);
          expect(preview.profile.template, template);
          expect(
            data(appContainer(tester).read(cvBuilderControllerProvider).draft),
            original,
            reason: 'no data lost switching to ${template.name}',
          );
          if (template == CvTemplate.classic && shares.isNotEmpty) {
            break; // back at the start: switching done, files already saved
          }

          final name = '${fixture.name}-${template.name}';
          await shot(tester, 'templates', '$name-preview');
          await saveHostFile('templates/$name-preview.pdf', preview.pdf);
          for (var i = 0; i < preview.pages.length; i++) {
            await saveHostFile(
              'templates/$name-preview-p${i + 1}.png',
              preview.pages[i],
            );
          }

          final before = shares.length;
          await tapText(
            tester,
            AppStrings.previewExport,
            settle: const Duration(seconds: 3),
          );
          expect(shares.length, before + 1, reason: 'export of $name');
          final doc = shares.last.arguments['doc'];
          if (doc is List<int>) {
            await saveHostFile('templates/$name-export.pdf', doc);
          }
        }
      },
    );
  }
}
