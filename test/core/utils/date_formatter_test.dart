import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekdayShort names the day', () {
    // 12 Oct 2026 is a Monday.
    final monday = DateTime(2026, 10, 12);
    final names = [
      for (var i = 0; i < 7; i++)
        DateFormatter.weekdayShort(monday.add(Duration(days: i))),
    ];

    expect(names, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
  });
}
