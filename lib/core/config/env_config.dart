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
