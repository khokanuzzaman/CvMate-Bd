class DateFormatter {
  const DateFormatter._();

  static String shortDate(DateTime value) {
    final local = value.toLocal();
    final month = _monthName(local.month);
    return '${local.day} $month ${local.year}';
  }

  static String shortDateTime(DateTime value) {
    final local = value.toLocal();
    final month = _monthName(local.month);
    return '${local.day} $month ${local.year}, ${shortTime(local)}';
  }

  static String shortTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}
