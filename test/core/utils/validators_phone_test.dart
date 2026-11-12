import 'package:careermatebd/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone numbers from any country pass; garbage does not', () {
    for (final number in [
      '+971 50 123 4567', // UAE
      '+966 55 123 4567', // Saudi
      '+966-55-123-4567',
      '+974 3312 3456', // Qatar
      '+880 1712-345678', // Bangladesh, international
      '01712345678', // Bangladesh, local
      '(0171) 234 5678',
    ]) {
      expect(Validators.phone(number), isNull, reason: number);
    }

    for (final garbage in ['', 'abc', '12345', 'call me', '++971501234567']) {
      expect(Validators.phone(garbage), isNotNull, reason: garbage);
    }
    expect(
      Validators.phone('+1234567890123456'),
      isNotNull,
      reason: '16 digits',
    );
  });
}
