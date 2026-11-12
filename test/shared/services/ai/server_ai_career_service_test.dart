import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/shared/services/ai/ai_response_parser.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/ai/server_ai_career_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_ai_server.dart';

CvProfile _cv() => CvProfile.empty().copyWith(
  personalInfo: const PersonalInfo(
    fullName: 'Nusrat Jahan',
    desiredRole: 'Flutter Developer',
    email: 'nusrat@example.com',
    phone: '01700000000',
  ),
  experiences: const [
    ExperienceInfo(
      id: 'exp-1',
      companyName: 'Tech Studio BD',
      jobTitle: 'Flutter Intern',
      highlights: ['Built a Flutter app.'],
    ),
  ],
);

const _summary = {
  'title': 'Summary',
  'originalText': '',
  'suggestedText': 'Flutter developer who ships.',
  'guidancePoints': <String>[],
  'language': 'english',
};

void main() {
  late List<bool> tokenRefreshes;
  late List<int> remaining;

  ServerAiCareerService serviceFor(FakeAiServer server) {
    return ServerAiCareerService(
      client: AiServerClient(
        dio: server.dio(),
        readIdToken: ({bool forceRefresh = false}) async {
          tokenRefreshes.add(forceRefresh);
          return forceRefresh ? 'fresh-token' : 'old-token';
        },
      ),
      responseParser: const AiResponseParser(),
      onRemainingActions: remaining.add,
    );
  }

  setUp(() {
    tokenRefreshes = [];
    remaining = [];
  });

  test('sends the payload with the experience id, app id and token', () async {
    final server = FakeAiServer([
      FakeAiReply(
        200,
        aiSuccessBody('tailorCvForJob', {
          'tailoredSummary': 'Tailored.',
          'emphasizedSkills': ['Flutter'],
          'rewrittenBullets': [
            {
              'experienceId': 'exp-1',
              'original': 'Built a Flutter app.',
              'suggested': 'Built and shipped a Flutter app.',
            },
          ],
        }, remainingActions: 2),
      ),
    ]);

    final result = await serviceFor(server).tailorCvForJob(
      profile: _cv(),
      jobPostText: 'Flutter developer wanted.',
      jobTitle: 'Flutter Developer',
    );

    expect(result, isA<Success<Object?>>());
    final request = server.requests.single;
    expect(request.path, '/v1/ai/generate');
    expect(request.method, 'POST');
    expect(request.headers['X-App-Id'], 'cvmate');
    expect(request.headers['Authorization'], 'Bearer old-token');

    final body = server.sentBodies.single;
    expect(body['action'], 'tailorCvForJob');
    expect(body['jobPost'], 'Flutter developer wanted.');
    expect(body['metadata'], containsPair('jobTitle', 'Flutter Developer'));
    final experiences = (body['cvData'] as Map)['experiences'] as List;
    expect((experiences.single as Map)['id'], 'exp-1');
    expect(remaining, [2]);
  });

  test('on 401 it refreshes the token and retries exactly once', () async {
    final server = FakeAiServer([
      FakeAiReply(401, aiErrorBody('unauthenticated')),
      FakeAiReply(200, aiSuccessBody('generateProfessionalSummary', _summary)),
    ]);

    final result = await serviceFor(
      server,
    ).generateProfessionalSummary(profile: _cv());

    expect(result, isA<Success<Object?>>());
    expect(tokenRefreshes, [false, true]);
    expect(server.requests.last.headers['Authorization'], 'Bearer fresh-token');

    final stillDenied = FakeAiServer([
      FakeAiReply(401, aiErrorBody('unauthenticated')),
    ]);
    final denied = await serviceFor(
      stillDenied,
    ).generateProfessionalSummary(profile: _cv());

    expect(stillDenied.requests, hasLength(2), reason: 'one retry only');
    expect(_code(denied), AiFailureCodes.authRequired);
  });

  test('maps 402, 429, 503 and network errors to app failure codes', () async {
    final cases = {
      FakeAiReply(402, aiErrorBody('ai_quota')): AiFailureCodes.quotaExceeded,
      FakeAiReply(429, aiErrorBody('rate_limit')): AiFailureCodes.rateLimited,
      FakeAiReply(503, aiErrorBody('budget_exceeded')):
          AiFailureCodes.unavailable,
      const FakeAiReply.offline(): AiFailureCodes.unavailable,
      FakeAiReply(413, aiErrorBody('payload_too_large')): AiFailureCodes.tooLong,
    };

    for (final entry in cases.entries) {
      final result = await serviceFor(
        FakeAiServer([entry.key]),
      ).generateProfessionalSummary(profile: _cv());
      expect(_code(result), entry.value, reason: '${entry.key.status}');
    }
    expect(
      _message(
        await serviceFor(
          FakeAiServer([const FakeAiReply.offline()]),
        ).generateProfessionalSummary(profile: _cv()),
      ),
      AiFailureMessages.busy,
    );
    expect(remaining, [0], reason: 'a 402 sets the counter to zero');
  });
}

String? _code(Result<Object?> result) =>
    result.when(success: (_) => 'success', failure: (failure) => failure.code);

String _message(Result<Object?> result) =>
    result.when(success: (_) => 'success', failure: (failure) => failure.message);
