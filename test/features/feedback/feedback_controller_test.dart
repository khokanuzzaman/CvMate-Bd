import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/feedback/data/feedback_diagnostics.dart';
import 'package:careermatebd/features/feedback/data/feedback_repository.dart';
import 'package:careermatebd/features/feedback/presentation/controllers/feedback_controller.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/analytics/analytics_params.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/core_flow_harness.dart';

class _FakeFeedbackRepository implements FeedbackRepository {
  final List<Map<String, Object>> sent = [];
  Object? error;

  @override
  Future<void> send(FeedbackSubmission submission) async {
    if (error case final error?) {
      throw error;
    }
    sent.add(submission.toJson());
  }
}

const _diagnostics = FeedbackDiagnostics(
  appVersion: '1.0.0',
  buildNumber: '7',
  platform: 'ios',
  osVersion: '26.1',
  deviceModel: 'iPhone17,3',
  recentEvents: ['app_open', 'export_result'],
);

void main() {
  late _FakeFeedbackRepository repository;
  late RecordingAnalytics analytics;

  ProviderContainer container({AuthUser? user}) {
    final container = ProviderContainer(
      overrides: [
        feedbackRepositoryProvider.overrideWithValue(repository),
        analyticsServiceProvider.overrideWithValue(analytics),
        currentAuthUserProvider.overrideWithValue(user),
        feedbackDiagnosticsReaderProvider.overrideWithValue(
          () async => _diagnostics,
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(feedbackControllerProvider, (_, _) {});
    return container;
  }

  setUp(() {
    repository = _FakeFeedbackRepository();
    analytics = RecordingAnalytics();
  });

  test('sends category and message; no email flag and no diagnostics '
      'unless the user ticks them', () async {
    final app = container(
      user: const AuthUser(uid: 'u1', email: 'rahim@example.com'),
    );
    final controller = app.read(feedbackControllerProvider.notifier);

    controller
      ..selectCategory(FeedbackCategory.aiResult)
      ..updateMessage('  The tailored CV dropped my last job.  ');
    await controller.send();

    expect(repository.sent.single, {
      'category': 'ai_result',
      'message': 'The tailored CV dropped my last job.',
      'allowReply': false,
    });
    expect(app.read(feedbackControllerProvider).phase, FeedbackPhase.sent);
    expect(analytics.events.map((event) => event.$1), [
      'feedback_open',
      'feedback_sent',
    ]);
    expect(analytics.paramsFor('feedback_sent').single, {
      'category': 'ai_result',
      'diagnostics': 'no',
    });
  });

  test('reply and diagnostics only when ticked; guests can never opt into '
      'a reply', () async {
    final signedIn = container(
      user: const AuthUser(uid: 'u1', email: 'rahim@example.com'),
    );
    signedIn.read(feedbackControllerProvider.notifier)
      ..selectCategory(FeedbackCategory.bug)
      ..updateMessage('Crash on export')
      ..setAttachDiagnostics(true)
      ..setAllowReply(true);
    await signedIn.read(feedbackControllerProvider.notifier).send();

    final sent = repository.sent.single;
    expect(sent['allowReply'], isTrue);
    expect(sent['diagnostics'], _diagnostics.toJson());
    expect(sent.toString(), isNot(contains('rahim@example.com')));

    final guest = container(
      user: const AuthUser(uid: 'g1', email: '', isAnonymous: true),
    );
    expect(guest.read(feedbackCanReplyProvider), isFalse);
    guest.read(feedbackControllerProvider.notifier)
      ..selectCategory(FeedbackCategory.other)
      ..updateMessage('Hello')
      ..setAllowReply(true);
    await guest.read(feedbackControllerProvider.notifier).send();
    expect(repository.sent.last['allowReply'], isFalse);
  });

  test('a failed send keeps the message and shows the error', () async {
    repository.error = const AppException(
      'Too many messages.',
      code: AiFailureCodes.rateLimited,
    );
    final app = container();
    app.read(feedbackControllerProvider.notifier)
      ..selectCategory(FeedbackCategory.payment)
      ..updateMessage('Charged twice');
    await app.read(feedbackControllerProvider.notifier).send();

    final state = app.read(feedbackControllerProvider);
    expect(state.phase, FeedbackPhase.editing);
    expect(state.message, 'Charged twice');
    expect(state.errorMessage, 'Too many messages.');
    expect(analytics.paramsFor('feedback_sent'), isEmpty);
  });
}
