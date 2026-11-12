import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/fake_ai_server.dart';
import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

const _tailoredSummary = 'Server-tailored ICU nurse summary.';

/// The real AI path (consent guard → ServerAiCareerService → Dio) against a
/// fake AI server: consent sheet on the first AI action, tailoring with the
/// server's answer, and "AI actions left" dropping from 3 to 2.
void registerAiServerFlow() {
  qaTest(
    'ai server: consent → tailor against a mocked server → actions left 3 → 2',
    (tester) async {
      var actionsLeft = 3;
      final server = FakeAiServer.handler((request) {
        if (request.path == '/v1/me/entitlement') {
          return FakeAiReply(200, {
            'plan': 'free',
            'proExpiresAt': null,
            'actionsLeft': actionsLeft,
            'resetsAt': null,
          });
        }
        final cvData = (request.data as Map)['cvData'] as Map;
        final experience = (cvData['experiences'] as List).first as Map;
        actionsLeft--;
        return FakeAiReply(
          200,
          aiSuccessBody('tailorCvForJob', {
            'tailoredSummary': _tailoredSummary,
            'emphasizedSkills': ['Patient care'],
            'rewrittenBullets': [
              {
                'experienceId': experience['id'],
                'original': (experience['highlights'] as List).first,
                'suggested': 'Monitored vital signs for 12 ICU patients a shift.',
              },
            ],
            'language': 'english',
          }, remainingActions: actionsLeft),
        );
      });

      await launchSignedIn(
        tester,
        overrides: [
          aiServerDioProvider.overrideWithValue(server.dio()),
          idTokenReaderProvider.overrideWithValue(
            ({bool forceRefresh = false}) async => 'qa-token',
          ),
          aiCareerServiceProvider.overrideWith(guardedServerAiCareerService),
        ],
      );
      await seedCv(tester, nurseCv());

      await tapText(tester, 'Tailor');
      await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
      final fields = find.byType(TextField);
      await typeInto(tester, fields.at(0), nurseJobPost);
      await typeInto(tester, fields.at(1), 'Registered Nurse');
      await typeInto(tester, fields.at(2), 'Square Hospital');
      await tapText(
        tester,
        AppStrings.tailorAnalyze,
        settle: const Duration(seconds: 2),
      );
      await waitFor(tester, find.text(AppStrings.tailorStepPill(2)));
      await waitFor(tester, find.text(AppStrings.aiActionsLeft(3)));
      await shot(tester, 'ai-server', 'match-actions-left-3');

      await tapText(tester, AppStrings.tailorTailorMyCv);
      await waitFor(tester, find.text(AppStrings.aiConsentTitle));
      expect(
        server.requests.where((r) => r.path == '/v1/ai/generate'),
        isEmpty,
        reason: 'nothing is sent before consent',
      );
      await shot(tester, 'ai-server', 'consent-sheet');
      await tapText(
        tester,
        AppStrings.aiConsentAllow,
        settle: const Duration(seconds: 2),
      );

      await waitFor(tester, find.text(AppStrings.tailorStepPill(3)));
      expect(find.text(_tailoredSummary), findsWidgets);
      await shot(tester, 'ai-server', 'tailored-by-server');

      final generate = server.requests
          .where((r) => r.path == '/v1/ai/generate')
          .single;
      expect(generate.headers['X-App-Id'], 'cvmate');
      expect(generate.headers['Authorization'], 'Bearer qa-token');
      final body = generate.data as Map;
      expect(body['action'], 'tailorCvForJob');
      final experiences = (body['cvData'] as Map)['experiences'] as List;
      expect((experiences.first as Map)['id'], 'ex1');

      await goBack(tester);
      await waitFor(tester, find.text(AppStrings.aiActionsLeft(2)));
      await shot(tester, 'ai-server', 'match-actions-left-2');
    },
  );
}
