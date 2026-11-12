import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  /// The AI server (repo `cvmate-api`). Every AI call and the AI quota go
  /// through it; the app never holds a model API key.
  static const String aiApiBaseUrl = String.fromEnvironment(
    'AI_API_BASE_URL',
    defaultValue: 'https://api.khokan.me',
  );

  /// `X-App-Id` the AI server uses to pick this app's Firebase project,
  /// quota rules and provider key.
  static const String aiAppId = 'cvmate';

  /// Debug builds only: `USE_MOCK_AI=true` in `.env` answers every AI feature
  /// with canned output instead of calling the server (the `.env.example`
  /// default; also when the key is missing, e.g. in unit and widget tests).
  /// Set it to false to use the AI server in a debug build.
  static bool get useMockAi => _readBool('USE_MOCK_AI', defaultValue: true);

  /// Whether this build answers AI features with the mock. Never in release:
  /// a release build always uses the AI server.
  static bool get isMockAiActive => !kReleaseMode && useMockAi;

  /// Why this build must not start, or null when its AI setup is acceptable.
  ///
  /// A **release** build must call the real AI server over HTTPS and must
  /// never ship the canned mock answers (fake tailoring, cover letters and
  /// interview questions) to users.
  static String? aiConfigurationProblem({
    bool isRelease = kReleaseMode,
    String baseUrl = aiApiBaseUrl,
    bool? mockAi,
  }) {
    if (!isRelease) {
      return null;
    }
    // Only an explicit USE_MOCK_AI=true is refused; a missing key is fine
    // because release never uses the mock.
    if (mockAi ?? _readBool('USE_MOCK_AI', defaultValue: false)) {
      return 'This release build would use the mock AI. Remove '
          'USE_MOCK_AI=true from .env so AI features use the AI server.';
    }
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'This release build has no HTTPS AI server. Build it with '
          '--dart-define=AI_API_BASE_URL=https://api.khokan.me.';
    }
    return null;
  }

  /// RevenueCat **public** SDK keys (app-specific `appl_…` / `goog_…` keys,
  /// made to ship in the client; not secrets). Read from
  /// `--dart-define=REVENUECAT_IOS_API_KEY=…` first, else from `.env`. Never
  /// hard-coded.
  static String get revenueCatIosApiKey => _defineOrEnv(
    const String.fromEnvironment('REVENUECAT_IOS_API_KEY'),
    'REVENUECAT_IOS_API_KEY',
  );

  /// Android slot; may stay empty until Google Play billing is set up.
  static String get revenueCatAndroidApiKey => _defineOrEnv(
    const String.fromEnvironment('REVENUECAT_ANDROID_API_KEY'),
    'REVENUECAT_ANDROID_API_KEY',
  );

  /// The RevenueCat key for [platform], or '' when there is none.
  static String revenueCatApiKeyFor(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.iOS => revenueCatIosApiKey,
        TargetPlatform.android => revenueCatAndroidApiKey,
        _ => '',
      };

  /// Debug builds only: `USE_FAKE_BILLING=true` in `.env` (the default, also
  /// when the key is missing, e.g. in tests) sells canned packages without a
  /// store. Purchases made with it never reach the server, so they never make
  /// anyone Pro. Set it to false to use RevenueCat in a debug build.
  static bool get useFakeBilling =>
      _readBool('USE_FAKE_BILLING', defaultValue: true);

  /// Whether this build uses the fake purchase service. Never in release.
  static bool get isFakeBillingActive => !kReleaseMode && useFakeBilling;

  /// Why this build must not start, or null when its billing setup is
  /// acceptable. A **release** iOS build needs the RevenueCat iOS key, and no
  /// release build may ship the fake purchase service.
  static String? billingConfigurationProblem({
    bool isRelease = kReleaseMode,
    TargetPlatform? platform,
    String? iosApiKey,
    bool? fakeBilling,
  }) {
    if (!isRelease) {
      return null;
    }
    if (fakeBilling ?? _readBool('USE_FAKE_BILLING', defaultValue: false)) {
      return 'This release build would use the fake purchase service. Remove '
          'USE_FAKE_BILLING=true from .env.';
    }
    final target = platform ?? defaultTargetPlatform;
    if (target == TargetPlatform.iOS &&
        (iosApiKey ?? revenueCatIosApiKey).trim().isEmpty) {
      return 'This release build has no RevenueCat iOS key. Build it with '
          '--dart-define=REVENUECAT_IOS_API_KEY=<public key> (or set '
          'REVENUECAT_IOS_API_KEY in .env).';
    }
    return null;
  }

  static String _defineOrEnv(String defined, String envKey) {
    final value = defined.trim();
    return value.isNotEmpty ? value : _readEnvValue(envKey, fallback: '');
  }

  static bool _readBool(String key, {required bool defaultValue}) {
    final rawValue = _readEnvValue(key, fallback: '').toLowerCase();
    if (rawValue.isEmpty) {
      return defaultValue;
    }

    if (rawValue == 'true' || rawValue == '1' || rawValue == 'yes') {
      return true;
    }

    if (rawValue == 'false' || rawValue == '0' || rawValue == 'no') {
      return false;
    }

    return defaultValue;
  }

  static String _readEnvValue(String key, {required String fallback}) {
    if (!dotenv.isInitialized) {
      return fallback;
    }

    return dotenv.maybeGet(key, fallback: fallback)?.trim() ?? fallback;
  }
}
