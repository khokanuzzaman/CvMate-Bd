/// Central catalogue of analytics event + parameter names.
///
/// Keep every event name here (snake_case, <= 40 chars, GA4-safe) so the core
/// funnel is defined in one place and never spelled inconsistently at call sites.
abstract final class AnalyticsEvents {
  // Core funnel.
  static const String appOpen = 'app_open';
  static const String cvCreated = 'cv_created';
  static const String cvExported = 'cv_exported';
  static const String tailoringStarted = 'tailoring_started';
  static const String tailoringCompleted = 'tailoring_completed';
  static const String aiActionUsed = 'ai_action_used';
  static const String paywallViewed = 'paywall_viewed';

  // Common parameter keys.
  static const String paramSource = 'source';
  static const String paramType = 'type';
  static const String paramAction = 'action';
}
