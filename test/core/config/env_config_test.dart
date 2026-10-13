import 'package:careermatebd/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvConfig.aiConfigurationProblem', () {
    test('a release build on the default config (mock AI) is refused', () {
      final problem = EnvConfig.aiConfigurationProblem(
        isRelease: true,
        firebaseAi: false,
      );

      expect(problem, isNotNull);
      expect(problem, contains('USE_FIREBASE_AI=true'));
    });

    test('a release build with the Firebase AI proxy is fine', () {
      expect(
        EnvConfig.aiConfigurationProblem(isRelease: true, firebaseAi: true),
        isNull,
      );
    });

    test('debug and profile builds may use the mock', () {
      expect(
        EnvConfig.aiConfigurationProblem(isRelease: false, firebaseAi: false),
        isNull,
      );
    });

    test('the tests themselves run with the mock allowed', () {
      // flutter test is not a release build.
      expect(EnvConfig.aiConfigurationProblem(), isNull);
    });
  });
}
