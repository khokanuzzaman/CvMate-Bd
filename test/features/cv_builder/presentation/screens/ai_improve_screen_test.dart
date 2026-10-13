import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/ai_improve_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

void main() {
  const longTitle =
      'Senior Registered Nurse and Clinical Coordinator Curriculum Vitae 2026';

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('dropdowns do not overflow at text scale $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpRoutedScreen(
        tester,
        path: RouteNames.aiImprovePath,
        screen: const AiImproveScreen(),
        overrides: [
          cvRepositoryProvider.overrideWithValue(
            FakeCvRepository([designCv(title: longTitle)]),
          ),
        ],
      );

      expect(find.text('Improvement type'), findsOneWidget);
      // A RenderFlex overflow is reported as an exception.
      expect(tester.takeException(), isNull);
    });
  }
}
