import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/presentation/controllers/app_preferences_controller.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/analytics/telemetry_bootstrap.dart';
import 'package:careermatebd/shared/services/crash/crash_reporter.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:careermatebd/shared/services/review/review_prompt_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/core_flow_harness.dart';
import '../../../helpers/fake_settings_repository.dart';

class _NullCrashSink implements CrashSink {
  final List<bool> collection = [];

  @override
  Future<void> record(
    ScrubbedError error,
    StackTrace stack, {
    required bool fatal,
  }) async {}

  @override
  Future<void> setUserId(String id) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      collection.add(enabled);

  @override
  Future<void> deleteUnsent() async {}
}

class _NoEntitlement extends AiEntitlementController {
  @override
  Future<AiEntitlement?> build() async => null;
}

void main() {
  Future<(ProviderContainer, RecordingAnalyticsSink, _NullCrashSink)> boot({
    required bool allowedInBuild,
  }) async {
    final sink = RecordingAnalyticsSink();
    final crashSink = _NullCrashSink();
    final container = ProviderContainer(
      overrides: [
        telemetryAllowedInBuildProvider.overrideWithValue(allowedInBuild),
        analyticsServiceProvider.overrideWithValue(
          AnalyticsService(sink: sink),
        ),
        crashReporterProvider.overrideWithValue(CrashReporter(sink: crashSink)),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        currentAuthUserProvider.overrideWithValue(null),
        aiEntitlementProvider.overrideWith(_NoEntitlement.new),
        reviewPromptStoreProvider.overrideWithValue(MemoryReviewPromptStore()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(telemetryBootstrapProvider, (_, _) {});
    await container.read(appPreferencesControllerProvider.future);
    await pumpEventQueue();
    return (container, sink, crashSink);
  }

  test('debug builds send nothing, even with the switch on', () async {
    final (container, sink, crashSink) = await boot(allowedInBuild: false);

    await container.read(analyticsServiceProvider).log(AnalyticsEvent.logout);

    expect(sink.events, isEmpty);
    expect(sink.collection, [false]);
    expect(crashSink.collection, [false]);
  });

  test('turning "Share usage analytics" off stops analytics and crash '
      'reports at once', () async {
    final (container, sink, crashSink) = await boot(allowedInBuild: true);
    expect(sink.events.single.$1, 'app_open');

    await container
        .read(appPreferencesControllerProvider.notifier)
        .updateShareUsageAnalytics(enabled: false);
    await pumpEventQueue();
    await container.read(analyticsServiceProvider).log(AnalyticsEvent.logout);

    expect(sink.events.map((event) => event.$1), ['app_open']);
    expect(sink.collection, [true, false]);
    expect(crashSink.collection, [true, false]);
    expect(container.read(crashReporterProvider).enabled, isFalse);
  });
}
