import 'package:firebase_analytics/firebase_analytics.dart';

/// Where analytics go. [FirebaseAnalyticsSink] in the app; tests record.
abstract class AnalyticsSink {
  Future<void> logEvent(String name, Map<String, Object> params);

  Future<void> logScreenView(String screenName);

  Future<void> setUserProperty(String name, String? value);

  /// Turns collection on or off now (the Settings toggle).
  Future<void> setCollectionEnabled(bool enabled);

  /// Clears the analytics instance id and stored data (account deletion).
  Future<void> reset();
}

/// Firebase Analytics. Never asks for ad storage, ad user data or ad
/// personalisation: CvMate does not advertise or track across apps.
class FirebaseAnalyticsSink implements AnalyticsSink {
  const FirebaseAnalyticsSink();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  @override
  Future<void> logEvent(String name, Map<String, Object> params) =>
      _analytics.logEvent(name: name, parameters: params);

  @override
  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName, screenClass: screenName);

  @override
  Future<void> setUserProperty(String name, String? value) =>
      _analytics.setUserProperty(name: name, value: value);

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    await _analytics.setConsent(
      analyticsStorageConsentGranted: enabled,
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> reset() => _analytics.resetAnalyticsData();
}
