import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_details.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';

void main() {
  testWidgets('CV style: pick Gulf + Letter; defaults flip, data is kept', (
    tester,
  ) async {
    final cv = CvProfile.empty().copyWith(
      id: 'cv-1',
      details: const PersonalDetails(passportNumber: 'A01234567'),
    );
    final container = await pumpBuilderApp(
      tester,
      repository: FakeCvRepository([cv]),
      initialLocation: RouteNames.cvStylePath,
      loadDraftId: 'cv-1',
    );

    // The pinned button is a button, not a full-screen slab.
    final button = find.widgetWithText(
      PrimaryButton,
      AppStrings.styleUse(AppStrings.styleShortInternational),
    );
    expect(tester.getSize(button).height, lessThan(80));

    await tester.tap(find.text(AppStrings.styleGulf));
    await tester.tap(find.text(AppStrings.paperLetter));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        PrimaryButton,
        AppStrings.styleUse(AppStrings.styleShortGulf),
      ),
    );
    await tester.pumpAndSettle();

    final draft = container.read(cvBuilderControllerProvider).draft;
    expect(draft.style, CvStyle.gulf);
    expect(draft.paperSize, PaperSize.letter);
    expect(draft.shownFields, CvStyle.gulf.defaultFields);
    expect(draft.details.passportNumber, 'A01234567');

    // Back to International hides the fields but never deletes the data.
    container
        .read(cvBuilderControllerProvider.notifier)
        .applyStyle(CvStyle.international);
    final after = container.read(cvBuilderControllerProvider).draft;
    expect(after.shownFields, isEmpty);
    expect(after.details.passportNumber, 'A01234567');

    await tester.pump(const Duration(seconds: 1));
  });
}
