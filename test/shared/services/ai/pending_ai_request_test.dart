import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/shared/services/ai/ai_response_parser.dart';
import 'package:careermatebd/shared/services/ai/ai_result_text.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/ai/pending_ai_request.dart';
import 'package:careermatebd/shared/services/ai/server_ai_career_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_ai_server.dart';

CvProfile _cv() => CvProfile.empty().copyWith(
  personalInfo: const PersonalInfo(
    fullName: 'Nusrat Jahan',
    desiredRole: 'Flutter Developer',
  ),
  professionalSummary: 'Builds Flutter apps.',
);

const _summary = {
  'title': 'Summary',
  'originalText': '',
  'suggestedText': 'Flutter developer who ships.',
  'guidancePoints': ['Lead with impact.'],
  'language': 'english',
};

void main() {
  late InMemoryPendingAiRequestStore store;
  late DateTime now;
  late String? uid;

  ServerAiCareerService serviceFor(FakeAiServer server) {
    return ServerAiCareerService(
      client: AiServerClient(
        dio: server.dio(),
        retryDelays: const [Duration.zero, Duration.zero, Duration.zero],
        readIdToken: ({bool forceRefresh = false}) async => 'token',
      ),
      responseParser: const AiResponseParser(),
      pendingStore: store,
      readUid: () => uid,
      clock: () => now,
    );
  }

  String? keyOf(FakeAiServer server, int index) =>
      server.requests[index].headers['Idempotency-Key'] as String?;

  setUp(() {
    store = InMemoryPendingAiRequestStore();
    now = DateTime.utc(2026, 11, 18, 9);
    uid = 'user-1';
  });

  test('kill and relaunch: the answer is fetched with the same key and a '
      'retry of the same request is not sent again', () async {
    // The connection never answers, then the app is killed.
    final first = FakeAiServer([const FakeAiReply.offline()]);
    final failed = await serviceFor(
      first,
    ).generateProfessionalSummary(profile: _cv());
    expect(failed, isA<FailureResult<Object?>>());
    final sentKey = keyOf(first, 0);
    expect(store.entry?.key, sentKey, reason: 'the key survives the kill');

    // Relaunch: a new service with the same store fetches the answer.
    now = now.add(const Duration(minutes: 2));
    final relaunched = FakeAiServer([
      FakeAiReply(200, aiSuccessBody('generateProfessionalSummary', _summary)),
    ]);
    final service = serviceFor(relaunched);
    final ready = await service.recoverPending();

    expect(keyOf(relaunched, 0), sentKey);
    expect(ready?.action, 'generateProfessionalSummary');
    expect(ready?.response?['content'], _summary);

    // Generating the same thing again uses the fetched answer: no request.
    final again = await service.generateProfessionalSummary(profile: _cv());
    expect(again, isA<Success<Object?>>());
    expect(relaunched.requests, hasLength(1));
    expect(store.entry, isNull, reason: 'cleared once used');
  });

  test('the key is reused only for the same request by the same user, and '
      'cleared after an answer', () async {
    final offline = FakeAiServer([const FakeAiReply.offline()]);
    await serviceFor(offline).generateProfessionalSummary(profile: _cv());
    final pendingKey = store.entry!.key;

    final server = FakeAiServer([
      FakeAiReply(200, aiSuccessBody('generateProfessionalSummary', _summary)),
    ]);
    final service = serviceFor(server);
    await service.generateProfessionalSummary(profile: _cv());
    expect(keyOf(server, 0), pendingKey, reason: 'same request: same key');
    expect(store.entry, isNull, reason: 'answered: cleared');

    await service.generateProfessionalSummary(profile: _cv());
    expect(keyOf(server, 1), isNot(pendingKey), reason: 'a new generation');

    final bad = FakeAiServer([FakeAiReply(400, aiErrorBody('invalid_input'))]);
    await serviceFor(bad).generateProfessionalSummary(profile: _cv());
    expect(store.entry, isNull, reason: 'an HTTP answer leaves nothing');
  });

  test(
    'an expired entry or another user\'s entry is dropped, not sent',
    () async {
      final offline = FakeAiServer([const FakeAiReply.offline()]);
      await serviceFor(offline).generateProfessionalSummary(profile: _cv());

      uid = 'user-2';
      final server = FakeAiServer([
        FakeAiReply(
          200,
          aiSuccessBody('generateProfessionalSummary', _summary),
        ),
      ]);
      expect(await serviceFor(server).recoverPending(), isNull);
      expect(server.requests, isEmpty);
      expect(store.entry, isNull);

      uid = 'user-1';
      await serviceFor(offline).generateProfessionalSummary(profile: _cv());
      now = now.add(PendingAiRequest.ttl);
      expect(await serviceFor(server).recoverPending(), isNull);
      expect(server.requests, isEmpty);
    },
  );

  test('a recovered result reads as plain text without input echoes', () {
    expect(
      AiResultText.fromContent(_summary),
      'Summary\nFlutter developer who ships.\n\nGuidance points\n'
      '• Lead with impact.',
    );
    expect(
      AiResultText.actionLabel('generateLinkedInMessage'),
      'LinkedIn message',
    );
  });
}
