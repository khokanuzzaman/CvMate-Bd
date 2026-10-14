import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';

CvProfile _cv({List<CustomSection> customs = const []}) {
  return CvProfile.empty().copyWith(
    id: 'cv-1',
    title: 'My CV',
    personalInfo: const PersonalInfo(
      fullName: 'Ayesha Rahman',
      email: 'ayesha@email.com',
    ),
    professionalSummary: 'Frontend developer.',
    customSections: customs,
    sectionLayout: customs.isEmpty
        ? null
        : [
            ...CvSectionLayout.defaultFor(CvProfile.empty().template),
            for (final c in customs) SectionConfig.custom(c.id),
          ],
  );
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  CvProfile? profile,
  String location = RouteNames.cvSectionsPath,
}) {
  return pumpBuilderApp(
    tester,
    repository: FakeCvRepository([profile ?? _cv()]),
    initialLocation: location,
    loadDraftId: 'cv-1',
  );
}

CvProfile _draft(ProviderContainer c) =>
    c.read(cvBuilderControllerProvider).draft;

List<String> _ids(ProviderContainer c) => [
  for (final s in _draft(c).sections) s.id,
];

Finder _row(String title) => find.text(title);

void main() {
  testWidgets('Sections screen: drag a handle to reorder, switch to hide', (
    tester,
  ) async {
    final c = await _open(tester);
    expect(_ids(c).take(3), ['summary', 'objective', 'education']);

    // Drag Summary's handle past the Education row.
    final distance =
        tester.getCenter(_row(AppStrings.previewEducation)).dy -
        tester.getCenter(_row(AppStrings.previewSummary)).dy +
        24;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_indicator_rounded).first),
    );
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(Offset(0, distance / 8));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_ids(c).take(3), ['objective', 'education', 'summary']);

    // The first row is now Career Objective; hide it.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(_draft(c).isSectionVisible(CvSectionKind.objective), isFalse);
    expect(find.text(AppStrings.sectionsHiddenTag), findsOneWidget);

    // Let the autosave timer fire so nothing outlives the test.
    await tester.pump(const Duration(seconds: 1));
  });
}
