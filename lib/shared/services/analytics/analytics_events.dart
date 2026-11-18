import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';
import 'package:careermatebd/shared/services/analytics/analytics_params.dart';
import 'package:flutter/foundation.dart';

export 'package:careermatebd/shared/services/analytics/analytics_params.dart';

/// One analytics event: a fixed name and enum-only parameters.
///
/// Build events only through the factories below; each one is listed in
/// [AnalyticsSchema] and in docs/ANALYTICS_EVENTS.md.
class AnalyticsEvent {
  const AnalyticsEvent._(this.name, [this.params = const {}]);

  final String name;

  /// Values are enum wire strings or small ints, never free text.
  final Map<String, Object> params;

  /// Any name and parameters, for tests of [AnalyticsSchema] only.
  @visibleForTesting
  const AnalyticsEvent.raw(this.name, this.params);

  static const appOpen = AnalyticsEvent._('app_open');

  factory AnalyticsEvent.onboardingStep(int step) =>
      AnalyticsEvent._('onboarding_step', {'step': step});

  factory AnalyticsEvent.onboardingComplete(OnboardingChoice choice) =>
      AnalyticsEvent._('onboarding_complete', {'choice': choice.wire});

  factory AnalyticsEvent.signUp(AuthMethod method) =>
      AnalyticsEvent._('sign_up', {'method': method.wire});

  factory AnalyticsEvent.login(AuthMethod method) =>
      AnalyticsEvent._('login', {'method': method.wire});

  static const logout = AnalyticsEvent._('logout');

  factory AnalyticsEvent.cvCreated(CvStyle style) =>
      AnalyticsEvent._('cv_created', {'style': _snake(style.name)});

  factory AnalyticsEvent.cvSectionCompleted(CvBuilderStep section) =>
      AnalyticsEvent._('cv_section_completed', {
        'section': _snake(section.name),
      });

  factory AnalyticsEvent.templateSelected(CvTemplate template) =>
      AnalyticsEvent._('template_selected', {
        'template_id': _snake(template.name),
      });

  factory AnalyticsEvent.atsCheckRun(AtsCheckKind kind, int score) =>
      AnalyticsEvent._('ats_check_run', {
        'kind': kind.wire,
        'score_bucket': ScoreBucket.of(score).wire,
      });

  static const aiConsentShown = AnalyticsEvent._('ai_consent_shown');

  factory AnalyticsEvent.aiConsentResult(ConsentResult result) =>
      AnalyticsEvent._('ai_consent_result', {'result': result.wire});

  factory AnalyticsEvent.aiActionStart(AiAction action) =>
      AnalyticsEvent._('ai_action_start', {'action': action.wire});

  factory AnalyticsEvent.aiActionResult(
    AiAction action,
    AiResult result,
    Duration latency,
  ) => AnalyticsEvent._('ai_action_result', {
    'action': action.wire,
    'result': result.wire,
    'latency_bucket': LatencyBucket.of(latency).wire,
  });

  factory AnalyticsEvent.quotaExhausted(AiAction action) =>
      AnalyticsEvent._('quota_exhausted', {'action': action.wire});

  factory AnalyticsEvent.paywallView(PaywallSource source) =>
      AnalyticsEvent._('paywall_view', {'source': source.wire});

  factory AnalyticsEvent.purchaseStart(PurchasePackage package) =>
      AnalyticsEvent._('purchase_start', {'package': package.wire});

  factory AnalyticsEvent.purchaseResult(
    PurchaseResult result,
    PurchasePackage package,
  ) => AnalyticsEvent._('purchase_result', {
    'result': result.wire,
    'package': package.wire,
  });

  factory AnalyticsEvent.restoreResult(RestoreResult result) =>
      AnalyticsEvent._('restore_result', {'result': result.wire});

  factory AnalyticsEvent.exportStart(
    ExportSource source,
    ExportFormat format,
  ) => AnalyticsEvent._('export_start', {
    'source': source.wire,
    'format': format.wire,
  });

  /// [gate] only when [result] is [ExportResult.ok].
  factory AnalyticsEvent.exportResult(
    ExportSource source,
    ExportFormat format,
    ExportResult result, {
    ExportGate? gate,
  }) => AnalyticsEvent._('export_result', {
    'source': source.wire,
    'format': format.wire,
    'result': result.wire,
    'gate': ?gate?.wire,
  });

  factory AnalyticsEvent.reviewPromptRequested(ReviewTrigger trigger) =>
      AnalyticsEvent._('review_prompt_requested', {'trigger': trigger.wire});

  static const feedbackOpen = AnalyticsEvent._('feedback_open');

  factory AnalyticsEvent.feedbackSent(
    FeedbackCategory category, {
    required bool diagnostics,
  }) => AnalyticsEvent._('feedback_sent', {
    'category': category.wire,
    'diagnostics': YesNo.of(diagnostics).wire,
  });

  factory AnalyticsEvent.accountDeleteStart(AccountKind account) =>
      AnalyticsEvent._('account_delete_start', {'account': account.wire});

  factory AnalyticsEvent.accountDeleteResult(
    AccountKind account,
    DeleteResult result,
  ) => AnalyticsEvent._('account_delete_result', {
    'account': account.wire,
    'result': result.wire,
  });

  @override
  String toString() => 'AnalyticsEvent($name, $params)';
}

/// The allowed parameters and values of every event. [AnalyticsService]
/// refuses anything else (an assert in debug and tests, dropped in release).
abstract final class AnalyticsSchema {
  static Set<String> _wires(List<AnalyticsValue> values) => {
    for (final value in values) value.wire,
  };

  static Set<String> _names(List<Enum> values) => {
    for (final value in values) _snake(value.name),
  };

  /// Allowed values per parameter: a set of strings, or an inclusive int
  /// range as `(min, max)`.
  static final Map<String, Map<String, Object>> events = {
    'app_open': {},
    'onboarding_step': {'step': (1, 3)},
    'onboarding_complete': {'choice': _wires(OnboardingChoice.values)},
    'sign_up': {'method': _wires(AuthMethod.values)},
    'login': {'method': _wires(AuthMethod.values)},
    'logout': {},
    'cv_created': {'style': _names(CvStyle.values)},
    'cv_section_completed': {'section': _names(CvBuilderStep.values)},
    'template_selected': {'template_id': _names(CvTemplate.values)},
    'ats_check_run': {
      'kind': _wires(AtsCheckKind.values),
      'score_bucket': _wires(ScoreBucket.values),
    },
    'ai_consent_shown': {},
    'ai_consent_result': {'result': _wires(ConsentResult.values)},
    'ai_action_start': {'action': _wires(AiAction.values)},
    'ai_action_result': {
      'action': _wires(AiAction.values),
      'result': _wires(AiResult.values),
      'latency_bucket': _wires(LatencyBucket.values),
    },
    'quota_exhausted': {'action': _wires(AiAction.values)},
    'paywall_view': {'source': _wires(PaywallSource.values)},
    'purchase_start': {'package': _wires(PurchasePackage.values)},
    'purchase_result': {
      'result': _wires(PurchaseResult.values),
      'package': _wires(PurchasePackage.values),
    },
    'restore_result': {'result': _wires(RestoreResult.values)},
    'export_start': {
      'source': _wires(ExportSource.values),
      'format': _wires(ExportFormat.values),
    },
    'export_result': {
      'source': _wires(ExportSource.values),
      'format': _wires(ExportFormat.values),
      'result': _wires(ExportResult.values),
      'gate': _wires(ExportGate.values),
    },
    'review_prompt_requested': {'trigger': _wires(ReviewTrigger.values)},
    'feedback_open': {},
    'feedback_sent': {
      'category': _wires(FeedbackCategory.values),
      'diagnostics': _wires(YesNo.values),
    },
    'account_delete_start': {'account': _wires(AccountKind.values)},
    'account_delete_result': {
      'account': _wires(AccountKind.values),
      'result': _wires(DeleteResult.values),
    },
  };

  /// Screen names logged as `screen_view` (GoRoute names).
  static final RegExp screenName = RegExp(r'^[a-z][a-z0-9-]{1,39}$');

  /// What is wrong with [event], or an empty list when it is allowed.
  static List<String> violations(AnalyticsEvent event) {
    final rules = events[event.name];
    if (rules == null) {
      return ['unknown event ${event.name}'];
    }
    return [
      for (final MapEntry(:key, :value) in event.params.entries)
        if (_problem(rules[key], value) case final problem?)
          '${event.name}.$key: $problem',
    ];
  }

  static String? _problem(Object? rule, Object value) {
    return switch (rule) {
      null => 'parameter not allowed',
      final Set<String> allowed when value is String =>
        allowed.contains(value) ? null : 'value not in the allowed set',
      (final int min, final int max) when value is int =>
        value >= min && value <= max ? null : 'number out of range',
      _ => 'wrong value type',
    };
  }
}

String _snake(String name) => name.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '_${match[0]!.toLowerCase()}',
);
