import 'dart:async';

import 'package:careermatebd/core/errors/failure.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/crash/crash_reporter.dart';
import 'package:careermatebd/shared/services/review/review_prompter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiTelemetryProvider = Provider<AiTelemetry>((ref) {
  return AiTelemetry(
    analytics: ref.watch(analyticsServiceProvider),
    crash: ref.watch(crashReporterProvider),
    review: ref.watch(reviewPrompterProvider),
  );
});

/// What one AI request reports: `ai_action_start` / `ai_action_result`,
/// `quota_exhausted`, a non-fatal with the error code for real failures, and
/// the rating rules (a success after tailoring, a setback after an error).
/// Never the prompt, the CV or the answer.
class AiTelemetry {
  const AiTelemetry({
    required this.analytics,
    required this.crash,
    required this.review,
  });

  final AnalyticsService analytics;
  final CrashReporter crash;
  final ReviewPrompter review;

  /// Codes that are normal states, not failures worth a crash report.
  static const Set<String> _expected = {
    AiFailureCodes.quotaExceeded,
    AiFailureCodes.rateLimited,
    AiFailureCodes.offline,
    AiFailureCodes.consentRequired,
    AiFailureCodes.authRequired,
  };

  void started(AiAction action) {
    unawaited(analytics.log(AnalyticsEvent.aiActionStart(action)));
  }

  void finished(AiAction action, Failure? failure, Duration elapsed) {
    final result = resultFor(failure?.code, failed: failure != null);
    unawaited(
      analytics.log(AnalyticsEvent.aiActionResult(action, result, elapsed)),
    );
    if (failure == null) {
      if (action == AiAction.tailorCv) {
        unawaited(review.onTailoringSucceeded());
      }
      return;
    }
    review.recordSetback();
    if (result == AiResult.quota) {
      unawaited(analytics.log(AnalyticsEvent.quotaExhausted(action)));
    }
    final code = failure.code ?? AiFailureCodes.failed;
    if (!_expected.contains(code)) {
      unawaited(crash.recordNonFatal(CrashArea.ai, code));
    }
  }

  static AiResult resultFor(String? code, {required bool failed}) {
    if (!failed) {
      return AiResult.ok;
    }
    return switch (code) {
      AiFailureCodes.quotaExceeded => AiResult.quota,
      AiFailureCodes.rateLimited => AiResult.rateLimited,
      AiFailureCodes.unavailable => AiResult.unavailable,
      AiFailureCodes.tooLong => AiResult.tooLong,
      AiFailureCodes.offline => AiResult.offline,
      _ => AiResult.error,
    };
  }
}
