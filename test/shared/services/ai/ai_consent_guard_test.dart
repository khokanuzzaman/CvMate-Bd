import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/router_ai_interaction_port.dart';
import 'package:careermatebd/core/utils/result.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../helpers/fake_ai_server.dart';
import '../../../helpers/fake_settings_repository.dart';

const _summary = {
  'title': 'Summary',
  'originalText': '',
  'suggestedText': 'Flutter developer who ships.',
  'guidancePoints': <String>[],
  'language': 'english',
};

class _Harness {
  _Harness(this.server, this.settings, this.pushed, this.ref);

  final FakeAiServer server;
  final FakeSettingsRepository settings;
  final List<String> pushed;
  final WidgetRef ref;

  Future<Result<AiTextSuggestion>> improveSummary() => ref
      .read(aiCareerServiceProvider)
      .generateProfessionalSummary(profile: CvProfile.empty());
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required List<FakeAiReply> replies,
  bool consent = false,
}) async {
  final server = FakeAiServer(replies);
  final settings = FakeSettingsRepository(
    const AppPreferences.defaults().copyWith(aiConsent: consent),
  );
  final pushed = <String>[];
  final navigatorKey = GlobalKey<NavigatorState>();
  late WidgetRef capturedRef;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiServerDioProvider.overrideWithValue(server.dio()),
        idTokenReaderProvider.overrideWithValue(
          ({bool forceRefresh = false}) async => 'token',
        ),
        settingsRepositoryProvider.overrideWithValue(settings),
        aiInteractionPortProvider.overrideWithValue(
          NavigatorAiInteractionPort(
            context: () => navigatorKey.currentContext,
            push: pushed.add,
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const Scaffold();
          },
        ),
      ),
    ),
  );
  return _Harness(server, settings, pushed, capturedRef);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Use the AI server path (not the mock) in these tests.
    dotenv.loadFromString(envString: 'USE_MOCK_AI=false');
  });

  testWidgets('without consent the sheet shows and "Not now" sends nothing', (
    tester,
  ) async {
    final app = await _pump(
      tester,
      replies: [FakeAiReply(200, aiSuccessBody('x', _summary))],
    );

    final pending = app.improveSummary();
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.aiConsentTitle), findsOneWidget);
    expect(find.text(AppStrings.aiConsentBody), findsOneWidget);

    await tester.tap(find.text(AppStrings.aiConsentNotNow));
    await tester.pumpAndSettle();
    final result = await pending;

    expect(
      result.when(success: (_) => null, failure: (f) => f.code),
      AiFailureCodes.consentRequired,
    );
    expect(app.server.requests, isEmpty);
    expect(app.settings.preferences.aiConsent, isFalse);
  });

  testWidgets('"Allow AI" is remembered, and an empty quota opens the paywall', (
    tester,
  ) async {
    final app = await _pump(
      tester,
      replies: [
        FakeAiReply(200, aiSuccessBody('x', _summary)),
        FakeAiReply(402, aiErrorBody('ai_quota')),
      ],
    );

    final first = app.improveSummary();
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.aiConsentAllow));
    await tester.pumpAndSettle();
    expect((await first).isSuccess, isTrue);
    expect(app.settings.preferences.aiConsent, isTrue);
    expect(app.server.requests, hasLength(1));

    // Consent is stored: no sheet the second time.
    final second = app.improveSummary();
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.aiConsentTitle), findsNothing);
    final quota = await second;

    expect(
      quota.when(success: (_) => null, failure: (f) => f.code),
      AiFailureCodes.quotaExceeded,
    );
    expect(app.pushed, ['/paywall?source=ai_quota']);
  });
}
