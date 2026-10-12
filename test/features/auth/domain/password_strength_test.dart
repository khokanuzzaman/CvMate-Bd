import 'package:careermatebd/features/auth/domain/password_strength.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordStrength.evaluate', () {
    test('empty input is empty with no segments filled', () {
      final strength = PasswordStrength.evaluate('');
      expect(strength, PasswordStrength.empty);
      expect(strength.score, 0);
    });

    test('anything under 8 characters is weak', () {
      expect(PasswordStrength.evaluate('a'), PasswordStrength.weak);
      expect(PasswordStrength.evaluate('Abc123!'), PasswordStrength.weak);
      expect(PasswordStrength.weak.score, 1);
    });

    test('8+ characters without mixed character classes is fair', () {
      expect(PasswordStrength.evaluate('abcdefgh'), PasswordStrength.fair);
      expect(PasswordStrength.evaluate('rahim123'), PasswordStrength.fair);
      expect(PasswordStrength.fair.score, 2);
    });

    test('8+ characters with letter, digit and uppercase/symbol is strong', () {
      expect(PasswordStrength.evaluate('Rahim123'), PasswordStrength.strong);
      expect(PasswordStrength.evaluate('rahim123!'), PasswordStrength.strong);
      expect(PasswordStrength.strong.score, 3);
    });

    test('score grows with strength', () {
      final scores = [
        PasswordStrength.evaluate(''),
        PasswordStrength.evaluate('abc'),
        PasswordStrength.evaluate('abcdefgh'),
        PasswordStrength.evaluate('Abcdefg1'),
      ].map((strength) => strength.score).toList();

      expect(scores, [0, 1, 2, 3]);
    });
  });
}
