import 'package:careermatebd/core/config/env_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvConfig.aiConfigurationProblem', () {
    test('a release build that asks for the mock AI is refused', () {
      final problem = EnvConfig.aiConfigurationProblem(
        isRelease: true,
        mockAi: true,
      );

      expect(problem, isNotNull);
      expect(problem, contains('USE_MOCK_AI'));
    });

    test('a release build without an HTTPS AI server is refused', () {
      for (final url in ['', 'http://api.khokan.me', 'not a url']) {
        expect(
          EnvConfig.aiConfigurationProblem(
            isRelease: true,
            baseUrl: url,
            mockAi: false,
          ),
          contains('AI_API_BASE_URL'),
          reason: url,
        );
      }
    });

    test('a release build on the AI server is fine', () {
      expect(
        EnvConfig.aiConfigurationProblem(
          isRelease: true,
          baseUrl: 'https://api.khokan.me',
          mockAi: false,
        ),
        isNull,
      );
    });

    test('debug and profile builds may use the mock', () {
      expect(
        EnvConfig.aiConfigurationProblem(isRelease: false, mockAi: true),
        isNull,
      );
    });
  });

  group('EnvConfig.billingConfigurationProblem', () {
    test('a release iOS build without the RevenueCat key is refused', () {
      final problem = EnvConfig.billingConfigurationProblem(
        isRelease: true,
        platform: TargetPlatform.iOS,
        iosApiKey: ' ',
        fakeBilling: false,
      );
      expect(problem, contains('REVENUECAT_IOS_API_KEY'));
    });

    test('a release build with the fake purchase service is refused; debug '
        'and Android without a key are fine', () {
      expect(
        EnvConfig.billingConfigurationProblem(
          isRelease: true,
          platform: TargetPlatform.iOS,
          iosApiKey: 'appl_public',
          fakeBilling: true,
        ),
        contains('USE_FAKE_BILLING'),
      );
      expect(
        EnvConfig.billingConfigurationProblem(
          isRelease: true,
          platform: TargetPlatform.android,
          iosApiKey: '',
          fakeBilling: false,
        ),
        isNull,
      );
      expect(
        EnvConfig.billingConfigurationProblem(
          isRelease: false,
          platform: TargetPlatform.iOS,
          iosApiKey: '',
        ),
        isNull,
      );
    });
  });
}
