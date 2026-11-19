import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_ai_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/shared/services/ai/ai_consent_guard.dart';
import 'package:careermatebd/shared/services/ai/ai_telemetry.dart';
import 'package:careermatebd/shared/services/ai/guarded_ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_ai_career_service.dart';
import '../../../../helpers/fake_cv_repository.dart';

class _NoopPort implements AiInteractionPort {
  @override
  Future<bool> requestAiConsent() async => true;

  @override
  void openPaywall(String source) {}
}

void main() {
  test('the ATS sheet logs its AI as ats_summary / ats_objective; the '
      'builder still logs professional_summary', () async {
    final analytics = RecordingAnalytics();
    final container = ProviderContainer(
      overrides: [
        cvRepositoryProvider.overrideWithValue(FakeCvRepository([designCv()])),
        analyticsServiceProvider.overrideWithValue(analytics),
        aiCareerServiceProvider.overrideWith(
          (ref) => GuardedAiCareerService(
            inner: FakeAiCareerService(),
            consentGuard: null,
            port: _NoopPort(),
            telemetry: ref.watch(aiTelemetryProvider),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final ats = container.read(atsCheckerControllerProvider.notifier);
    await ats.initialize();

    await ats.generateAiSuggestion();
    ats.selectAiTarget(AtsAiTarget.careerObjective);
    await ats.generateAiSuggestion();
    await container
        .read(aiCareerServiceProvider)
        .generateProfessionalSummary(profile: designCv());
    await Future<void>.delayed(Duration.zero);

    expect(analytics.paramsFor('ai_action_result').map((p) => p['action']), [
      'ats_summary',
      'ats_objective',
      'professional_summary',
    ]);
  });
}
