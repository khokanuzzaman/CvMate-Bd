import 'package:careermatebd/features/cv_builder/data/dtos/cv_profile_dto.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/template_fixtures.dart';

/// Everything stored for [profile] except what a template switch may change.
Map<String, dynamic> _data(CvProfile profile) => CvProfileDto(profile).toMap()
  ..remove('template')
  ..remove('updatedAt');

void main() {
  for (final fixture in TemplateFixture.values) {
    test(
      'switching through every template keeps the ${fixture.name} CV',
      () async {
        // A custom order with a hidden section, to show it survives too.
        final original = fixtureCv(fixture, CvTemplate.classic).profile
            .copyWith(
              sectionLayout: [
                SectionConfig.builtIn(
                  CvSectionKind.skills,
                  titleOverride: 'Tools',
                ),
                SectionConfig.builtIn(CvSectionKind.objective, visible: false),
              ],
            );
        final repository = FakeCvRepository([original]);
        final container = ProviderContainer(
          overrides: [cvRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);
        final controller = container.read(cvBuilderControllerProvider.notifier);
        await controller.loadDraft(original.id);

        // Through every template, then back: the path the template picker uses.
        for (final template in [...CvTemplate.values, CvTemplate.classic]) {
          controller.selectTemplate(template);
          await controller.flushAutosave();

          final saved = repository.saved(original.id)!;
          expect(saved.template, template);
          expect(_data(saved), _data(original), reason: template.name);
        }
      },
    );
  }
}
