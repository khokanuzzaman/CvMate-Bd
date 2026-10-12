import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';

CvProfile _profile(CvTemplate template) {
  return CvProfile.empty().copyWith(
    id: 'cv-1',
    template: template,
    personalInfo: const PersonalInfo(fullName: 'Ayesha Rahman'),
  );
}

void main() {
  Future<dynamic> openPicker(
    WidgetTester tester,
    FakeCvRepository repository,
  ) async {
    final container = await pumpBuilderApp(
      tester,
      repository: repository,
      initialLocation: RouteNames.cvPreviewPath,
      loadDraftId: 'cv-1',
    );
    await tester.tap(
      find.widgetWithText(SecondaryButton, AppStrings.previewTemplate),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('lists every template with an ATS badge, current one selected', (
    tester,
  ) async {
    await openPicker(tester, FakeCvRepository([_profile(CvTemplate.modern)]));

    for (final template in CvTemplate.values) {
      expect(find.text(template.label), findsWidgets, reason: template.label);
    }
    expect(find.text(AppStrings.templateAtsBadge), findsNWidgets(5));
    expect(find.text('Use Modern template'), findsOneWidget);
  });

  testWidgets('choosing a template and confirming applies it', (tester) async {
    final container = await openPicker(
      tester,
      FakeCvRepository([_profile(CvTemplate.modern)]),
    );

    await tester.tap(find.text('Minimal'));
    await tester.pumpAndSettle();
    expect(find.text('Use Minimal template'), findsOneWidget);
    // Nothing is applied until the user confirms.
    expect(
      container.read(cvBuilderControllerProvider).draft.template,
      CvTemplate.modern,
    );

    await tester.tap(find.text('Use Minimal template'));
    await tester.pumpAndSettle();

    expect(
      container.read(cvBuilderControllerProvider).draft.template,
      CvTemplate.minimal,
    );
    // Back on the preview, whose pill now shows the new template.
    expect(find.text(AppStrings.previewTitle), findsOneWidget);
    expect(find.text('Minimal'), findsOneWidget);
  });

  testWidgets('going back without confirming leaves the template alone', (
    tester,
  ) async {
    final container = await openPicker(
      tester,
      FakeCvRepository([_profile(CvTemplate.classic)]),
    );

    await tester.tap(find.text('Fresher'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    expect(
      container.read(cvBuilderControllerProvider).draft.template,
      CvTemplate.classic,
    );
  });
}
