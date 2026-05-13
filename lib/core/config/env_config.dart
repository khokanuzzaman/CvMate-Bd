import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  static const String openAiProxyUrl = String.fromEnvironment(
    'OPENAI_PROXY_URL',
    defaultValue: '',
  );

  static const bool useFirebaseAi = bool.fromEnvironment(
    'USE_FIREBASE_AI',
    defaultValue: false,
  );

  static const String firebaseFunctionsRegion = String.fromEnvironment(
    'FIREBASE_FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );

  static String get openAiApiKey =>
      _readEnvValue('OPENAI_API_KEY', fallback: '');

  static String get directOpenAiModel {
    final value = _readEnvValue('OPENAI_MODEL', fallback: 'gpt-4o-mini');
    return value.isEmpty ? 'gpt-4o-mini' : value;
  }

  static bool get useMockAi => _readBool('USE_MOCK_AI', defaultValue: true);
  static bool get wantsDirectOpenAi => !useMockAi;
  static bool get canUseDirectOpenAiInThisBuild => !kReleaseMode;
  static bool get shouldUseDirectOpenAiService =>
      wantsDirectOpenAi && canUseDirectOpenAiInThisBuild;
  static bool get isDirectOpenAiClientActive =>
      shouldUseDirectOpenAiService && hasOpenAiApiKey;
  static bool get isDirectOpenAiBlockedForRelease =>
      wantsDirectOpenAi && !canUseDirectOpenAiInThisBuild;

  static bool get hasOpenAiApiKey => openAiApiKey.isNotEmpty;
  static bool get hasOpenAiProxy => openAiProxyUrl.isNotEmpty;

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
