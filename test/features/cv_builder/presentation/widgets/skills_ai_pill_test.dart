import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';

void main() {
  testWidgets('the Skills page has "Suggest with AI", which opens AI Improve '
      'on skill suggestions', (tester) async {
    final container = await pumpBuilderApp(
      tester,
      repository: FakeCvRepository([
        CvProfile.empty().copyWith(id: 'cv-1', title: 'CV'),
      ]),
      loadDraftId: 'cv-1',
    );
    await tester.ensureVisible(find.text(AppStrings.builderChipSkills));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.builderChipSkills));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.builderSuggestWithAi));
    await tester.pumpAndSettle();

    expect(find.text(aiImprovePlaceholder), findsOneWidget);
    expect(
      container.read(aiImproveControllerProvider).improvementType,
      AiImproveType.skillsSuggestion,
    );
  });
}
