/// Labels shown only in debug builds that answer AI features with the mock
/// ([EnvConfig.isMockAiActive]); a release build never shows them. This is
/// the only file in lib/ allowed to say "mock" to the screen
/// (test/app/no_mock_text_test.dart).
abstract final class DevLabels {
  static const String mockAiBanner = 'MOCK AI';
  static const String mockAiTitle = 'Mock AI';
  static const String mockAiSubtitle =
      'Debug build with USE_MOCK_AI=true: canned answers, no server.';
}
